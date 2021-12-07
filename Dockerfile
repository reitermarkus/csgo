FROM cm2network/steamcmd:root

RUN apt-get install -y net-tools

ENV CONFIG_DIR=/config
ENV SERVER_DIR=/server
RUN mkdir -p "${CONFIG_DIR}" "${SERVER_DIR}" \
 && chown -R "${USER}:${USER}" "${CONFIG_DIR}" "${SERVER_DIR}"

USER "${USER}"

ARG METAMOD_VERSION
ENV METAMOD_VERSION="${METAMOD_VERSION}"
ARG SOURCEMOD_VERSION
ENV SOURCEMOD_VERSION="${SOURCEMOD_VERSION}"

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
