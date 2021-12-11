# Usage: docker run --restart=always -v /var/data/blockchain-xmr:/root/.bitmonero -p 18080:18080 -p 18081:18081 --name=monerod -td kannix/monero-full-node
FROM ubuntu:18.04 AS build

ENV MONERO_VERSION=0.17.3.0 MONERO_SHA256=ac18ce3d1189410a5c175984827d5d601974733303411f6142296d647f6582ce

RUN apt-get update && apt-get install -y curl bzip2

WORKDIR /root

RUN curl https://downloads.getmonero.org/cli/monero-linux-x64-v$MONERO_VERSION.tar.bz2 -O &&\
  echo "$MONERO_SHA256  monero-linux-x64-v$MONERO_VERSION.tar.bz2" | sha256sum -c - &&\
  tar -xvf monero-linux-x64-v$MONERO_VERSION.tar.bz2 &&\
  rm monero-linux-x64-v$MONERO_VERSION.tar.bz2 &&\
  cp ./monero-x86_64-linux-gnu-v$MONERO_VERSION/monerod . && cp ./monero-x86_64-linux-gnu-v$MONERO_VERSION/monero-wallet-rpc . &&\
  rm -r monero-x86_64-linux-gnu*
  
FROM ubuntu:18.04

RUN apt-get update -qq && apt-get install -yqq --no-install-recommends \
        torsocks \
        tor > /dev/null \
    && apt-get autoremove --purge -yqq > /dev/null \
    && apt-get clean > /dev/null \
    && rm -rf /var/tmp/* /tmp/* /var/lib/apt/* > /dev/null

COPY ./monerod/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY ./monerod/inputrc /etc/inputrc
# Copy Tor configuration files after installing Tor apps
# otherwise configuration might be replaced, build might stop
COPY ./monerod/torsocks.conf /etc/tor/torsocks.conf
COPY ./monerod/torrc /etc/tor/torrc


RUN useradd -ms /bin/bash monero && mkdir -p /home/monero/.bitmonero && chown -R monero:monero /home/monero/.bitmonero
USER monero
WORKDIR /home/monero

COPY --chown=monero:monero --from=build /root/monerod /home/monero/monerod
COPY --chown=monero:monero --from=build /root/monero-wallet-rpc /home/monero/monero-wallet-rpc
#COPY ./monerod/monerod.conf /home/monero/.bitmonero/monerod.conf

# blockchain loaction
#VOLUME /home/monero/.bitmonero/


EXPOSE 18080 18081

#ENTRYPOINT ["./monerod"]
#CMD ["--tx-proxy "tor,127.0.0.1:9050,10,disable_noise"", "--config-file /home/monero/.bitmonero/monerod.conf"]
