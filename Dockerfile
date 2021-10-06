FROM steamcmd/steamcmd:latest

RUN apt-get update \
 && apt-get install -y --no-install-recommends --no-install-suggests \
      curl \
      net-tools \
      tini \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 1000 csgo \
 && useradd -u 1000 -g 1000 csgo
USER csgo

EXPOSE 27015/tcp 27015/udp 27020/udp

ARG METAMOD_VERSION
ENV METAMOD_VERSION="${METAMOD_VERSION}"
ARG SOURCEMOD_VERSION
ENV SOURCEMOD_VERSION="${SOURCEMOD_VERSION}"

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
