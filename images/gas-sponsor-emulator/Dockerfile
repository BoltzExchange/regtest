FROM boltz/foundry:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends python3 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY batch-executor /batch-executor
RUN cd /batch-executor && forge build && \
    cp out/BatchExecutor.sol/BatchExecutor.json /batch-executor.json

COPY server.py /server.py

ENTRYPOINT ["python3", "/server.py"]
