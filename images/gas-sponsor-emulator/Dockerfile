FROM boltz/foundry:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends python3 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY server.py /server.py

ENTRYPOINT ["python3", "/server.py"]
