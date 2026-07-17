// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BatchExecutor {
    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    function execute(Call[] calldata calls) external payable {
        for (uint256 i = 0; i < calls.length; ++i) {
            Call calldata call = calls[i];
            (bool success, bytes memory result) = call.target.call{
                value: call.value
            }(call.data);
            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }
        }
    }
}
