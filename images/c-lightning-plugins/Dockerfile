ARG VERSION

FROM boltz/c-lightning:${VERSION}

RUN apt-get update && apt-get -y install git pkg-config
RUN git clone https://github.com/BoltzExchange/boltz-backend.git

# Plugins
RUN cp -R /boltz-backend/tools / && rm -Rf /boltz-backend
RUN pip install poetry
RUN cd /tools && poetry install
RUN echo "cd /tools && /usr/local/bin/poetry run python3 plugins/hold/plugin.py" > /root/hold.sh
RUN chmod +x /root/hold.sh
RUN echo "cd /tools && /usr/local/bin/poetry run python3 plugins/mpay/mpay.py" > /root/mpay.sh
RUN chmod +x /root/mpay.sh

ENTRYPOINT ["lightningd"]
