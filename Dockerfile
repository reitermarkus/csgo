FROM cm2network/steamcmd:root

ENV CONFIG_DIR=/config
ENV SERVER_DIR=/server
RUN apt-get update \
 && apt-get install -y net-tools \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p "${CONFIG_DIR}" "${SERVER_DIR}" \
 && chown -R "${USER}:${USER}" "${CONFIG_DIR}" "${SERVER_DIR}"

USER "${USER}"

ARG METAMOD_VERSION
ENV METAMOD_VERSION="${METAMOD_VERSION}"
ARG SOURCEMOD_VERSION
ENV SOURCEMOD_VERSION="${SOURCEMOD_VERSION}"

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
