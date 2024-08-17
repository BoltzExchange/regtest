ARG VERSION=latest

FROM boltz/c-lightning:${VERSION} AS builder

RUN apt-get update && apt-get install -y git pkg-config

RUN pip install poetry

RUN git clone --depth 1 https://github.com/BoltzExchange/boltz-backend.git

WORKDIR /boltz-backend/tools
RUN poetry config virtualenvs.in-project true && poetry install --no-dev

FROM boltz/c-lightning:${VERSION}

COPY --from=builder /boltz-backend/tools /tools
COPY --from=builder /boltz-backend/tools/.venv /tools/.venv

ENV PATH="/tools/.venv/bin:$PATH"

RUN echo 'cd /tools && PYTHONPATH="/tools" python3 plugins/hold/plugin.py' >> /root/hold.sh \
    && echo 'cd /tools && PYTHONPATH="/tools" python3 plugins/mpay/mpay.py' >> /root/mpay.sh \
    && chmod +x /root/hold.sh /root/mpay.sh

ENTRYPOINT ["lightningd"]
