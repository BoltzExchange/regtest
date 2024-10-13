ARG VERSION=latest

FROM boltz/c-lightning:${VERSION} AS builder

RUN apt-get update && apt-get install -y git pkg-config wget

RUN pip install poetry

RUN git clone --depth 1 https://github.com/BoltzExchange/boltz-backend.git

WORKDIR /boltz-backend/tools
RUN poetry config virtualenvs.in-project true && poetry install --no-dev

WORKDIR /hold

# TODO: download arm artifacts
RUN wget https://github.com/BoltzExchange/hold/releases/download/v0.1.0/hold-linux-amd64.tar.gz
RUN tar -xvf hold-linux-amd64.tar.gz

WORKDIR /clnurl

RUN wget https://github.com/michael1011/clnurl/releases/download/v0.1.0/clnurl.tar.gz
RUN tar -xvf clnurl.tar.gz

FROM boltz/c-lightning:${VERSION}

COPY --from=builder /boltz-backend/tools /tools
COPY --from=builder /boltz-backend/tools/.venv /tools/.venv
COPY --from=builder /hold/build/hold-linux-amd64 /root/hold
COPY --from=builder /clnurl/clnurl /root/clnurl

ENV PATH="/tools/.venv/bin:$PATH"

RUN echo 'cd /tools && PYTHONPATH="/tools" python3 plugins/mpay/mpay.py' >> /root/mpay.sh \
    && chmod +x /root/mpay.sh

ENTRYPOINT ["lightningd"]
