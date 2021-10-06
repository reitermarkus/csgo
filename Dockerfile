FROM steamcmd/steamcmd:latest

ENV STEAMAPPDIR /home/steam/csgo-dedicated

COPY etc/entry.sh /
ADD etc/cfg.tar.gz "${STEAMAPPDIR}/csgo/"

WORKDIR "${STEAMAPPDIR}"

RUN apt-get update \
 && apt-get install -y --no-install-recommends --no-install-suggests \
      curl \
 && rm -rf /var/lib/apt/lists/*

VOLUME "${STEAMAPPDIR}"

ENTRYPOINT /entry.sh

# Expose ports
EXPOSE 27015/tcp 27015/udp 27020/udp

ARG METAMOD_VERSION
ENV METAMOD_VERSION="${METAMOD_VERSION}"
ARG SOURCEMOD_VERSION
ENV SOURCEMOD_VERSION="${SOURCEMOD_VERSION}"
