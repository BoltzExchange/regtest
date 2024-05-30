FROM ubuntu:24.04 as builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y curl git && \
    curl -L https://foundry.paradigm.xyz | bash && \
    ~/.foundry/bin/foundryup

FROM ubuntu:24.04

ENV PATH="/root/.foundry/bin:$PATH"

RUN apt update && apt install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /root/.foundry /root/.foundry

CMD ["anvil", "--host=0.0.0.0"]
