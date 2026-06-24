#!/usr/bin/env python3

import json
import os
import secrets
import subprocess
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


ARBITRUM_RPC_URL = os.environ.get("ARBITRUM_RPC_URL", "http://anvil-arb:8545")
PORT = int(os.environ.get("GAS_SPONSOR_EMULATOR_PORT", "18547"))
SPONSORED_CALL_GAS_LIMIT = int(
    os.environ.get("GAS_SPONSOR_EMULATOR_CALL_GAS_LIMIT", "25000000")
)

PREPARED_CALL_MAX_FEE_PER_GAS = 2_000_000_000
PREPARED_CALL_MAX_PRIORITY_FEE_PER_GAS = 1_000_000_000

prepared_calls = {}
receipts = {}
execution_errors = {}
_state_lock = threading.Lock()


def rpc(method: str, params=None):
    data = json.dumps(
        {"id": 1, "jsonrpc": "2.0", "method": method, "params": params or []}
    ).encode()
    request = urllib.request.Request(
        ARBITRUM_RPC_URL,
        data=data,
        headers={"content-type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        body = json.loads(response.read())
    if "error" in body:
        raise RuntimeError(body["error"])
    return body["result"]


def wait_for_rpc():
    deadline = time.time() + 60
    while time.time() < deadline:
        try:
            rpc("eth_chainId")
            return
        except Exception:
            time.sleep(0.5)
    raise RuntimeError(f"timed out waiting for RPC {ARBITRUM_RPC_URL}")


def wait_for_receipt(tx_hash: str):
    deadline = time.time() + 120
    while time.time() < deadline:
        receipt = rpc("eth_getTransactionReceipt", [tx_hash])
        if receipt is not None:
            return receipt
        rpc("anvil_mine", ["0x1"])
        time.sleep(0.5)
    raise RuntimeError(f"timed out waiting for receipt {tx_hash}")


def require_hex(value, name: str, expected_len=None):
    if not isinstance(value, str) or not value.startswith("0x"):
        raise ValueError(f"{name} must be a 0x-prefixed hex string")
    digits = value[2:]
    if not digits or any(c not in "0123456789abcdefABCDEF" for c in digits):
        raise ValueError(f"{name} must contain only hex characters after 0x")
    if expected_len is not None and len(digits) != expected_len:
        raise ValueError(f"{name} must be 0x followed by {expected_len} hex characters")


def verify_signature(address: str, raw: str, signature: str, no_hash=False):
    require_hex(address, "address", expected_len=40)
    require_hex(raw, "raw")
    require_hex(signature, "signature")
    command = ["cast", "wallet", "verify", "--address", address]
    if no_hash:
        command.append("--no-hash")
    subprocess.check_call(
        [*command, raw, signature],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def hex_quantity(value) -> str:
    return hex(int(str(value or "0"), 0))


def send_prepared_call(sender: str, call) -> str:
    rpc("anvil_setBalance", [sender, hex(100 * 10**18)])
    rpc("anvil_impersonateAccount", [sender])

    try:
        return rpc(
            "eth_sendTransaction",
            [
                {
                    "from": sender,
                    "to": call["to"],
                    "value": hex_quantity(call.get("value")),
                    "data": call.get("data", "0x"),
                    "gas": hex(SPONSORED_CALL_GAS_LIMIT),
                    "maxFeePerGas": hex(PREPARED_CALL_MAX_FEE_PER_GAS),
                    "maxPriorityFeePerGas": hex(
                        PREPARED_CALL_MAX_PRIORITY_FEE_PER_GAS
                    ),
                }
            ],
        )
    finally:
        rpc("anvil_stopImpersonatingAccount", [sender])


def execute_prepared_calls(call_id: str):
    with _state_lock:
        entry = prepared_calls[call_id]
    sender = entry["from"]
    if sender is None:
        raise RuntimeError(f"prepared call {call_id} is missing sender")

    stored_receipts = []
    for call in entry["calls"]:
        tx_hash = send_prepared_call(sender, call)
        receipt = wait_for_receipt(tx_hash)
        if receipt["status"] != "0x1":
            raise RuntimeError(f"prepared call {call_id} reverted: {tx_hash}")
        stored_receipts.append(
            {
                "transactionHash": tx_hash,
                "status": "0x1",
                "blockHash": receipt["blockHash"],
                "blockNumber": receipt["blockNumber"],
                "gasUsed": receipt["gasUsed"],
            }
        )

    with _state_lock:
        receipts[call_id] = stored_receipts


def run_prepared_calls(call_id: str):
    try:
        execute_prepared_calls(call_id)
    except Exception as error:
        with _state_lock:
            execution_errors[call_id] = str(error)


def handle_alchemy(body):
    method = body.get("method")

    if method == "wallet_prepareCalls":
        params = (body.get("params") or [{}])[0]
        call_id = "0x" + secrets.token_hex(16)
        auth_raw = "0x" + secrets.token_hex(32)
        user_operation_raw = "0x" + secrets.token_hex(32)
        chain_id = params.get("chainId", "0xa4b1")
        with _state_lock:
            prepared_calls[call_id] = {
                "from": params.get("from"),
                "calls": params.get("calls", []),
                "authorizationRaw": auth_raw,
                "userOperationRaw": user_operation_raw,
            }
        return {
            "type": "array",
            "data": [
                {
                    "type": "eip-7702-authorization",
                    "data": {"callId": call_id},
                    "chainId": chain_id,
                    "signatureRequest": {"rawPayload": auth_raw},
                },
                {
                    "type": "user-operation-v070",
                    "data": {"callId": call_id},
                    "chainId": chain_id,
                    "signatureRequest": {"data": {"raw": user_operation_raw}},
                },
            ],
        }

    if method == "wallet_sendPreparedCalls":
        signed = (body.get("params") or [{}])[0]
        if signed.get("type") == "array":
            entries = signed.get("data", [])
            if len(entries) < 2:
                raise RuntimeError("signed prepared call array is incomplete")
            authorization = entries[0]
            signed = entries[1]
        else:
            authorization = None

        call_id = signed.get("data", {}).get("callId")
        with _state_lock:
            entry = prepared_calls.get(call_id)
        if entry is None:
            raise RuntimeError(f"unknown prepared call {call_id}")
        if authorization is not None:
            verify_signature(
                entry["from"],
                entry["authorizationRaw"],
                authorization.get("signature", {}).get("data", ""),
                no_hash=True,
            )
        verify_signature(
            entry["from"],
            entry["userOperationRaw"],
            signed.get("signature", {}).get("data", ""),
        )

        threading.Thread(target=run_prepared_calls, args=(call_id,), daemon=True).start()
        return {"preparedCallIds": [call_id]}

    if method == "wallet_getCallsStatus":
        call_id = (body.get("params") or [None])[0]
        with _state_lock:
            error = execution_errors.get(call_id)
            stored_receipts = receipts.get(call_id)
        if error is not None:
            raise RuntimeError(error)
        return (
            {"status": 100}
            if stored_receipts is None
            else {"status": 200, "receipts": stored_receipts}
        )

    raise RuntimeError(f"unsupported Alchemy method {method}")


class GasSponsorHandler(BaseHTTPRequestHandler):
    def cors(self):
        self.send_header("access-control-allow-origin", "*")
        self.send_header("access-control-allow-methods", "GET,POST,OPTIONS")
        self.send_header("access-control-allow-headers", "content-type")

    def send_json(self, status: int, body):
        encoded = json.dumps(body).encode()
        self.send_response(status)
        self.cors()
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def do_OPTIONS(self):
        self.send_response(204)
        self.cors()
        self.end_headers()

    def do_GET(self):
        if self.path == "/health":
            self.send_json(200, {"status": "ok"})
            return

        self.send_json(404, {"error": "not found"})

    def do_POST(self):
        try:
            path = self.path.split("?", 1)[0]
            length = int(self.headers.get("content-length", "0"))
            body = self.rfile.read(length).decode()

            if path == "/alchemy":
                request = json.loads(body)
                self.send_json(
                    200,
                    {
                        "id": request.get("id", 1),
                        "jsonrpc": "2.0",
                        "result": handle_alchemy(request),
                    },
                )
                return

            self.send_json(404, {"error": "not found"})
        except Exception as error:
            self.send_json(500, {"error": str(error)})

    def log_message(self, fmt, *args):
        print("%s - %s" % (self.address_string(), fmt % args), flush=True)


if __name__ == "__main__":
    wait_for_rpc()
    print(f"gas sponsor emulator listening on 0.0.0.0:{PORT}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), GasSponsorHandler).serve_forever()
