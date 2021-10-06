#!/usr/bin/env bash

set -x
set -euo pipefail

CONFIG_DIR=/config
mkdir -p "${CONFIG_DIR}"

SERVER_DIR=/server
mkdir -p "${SERVER_DIR}"
pushd "${SERVER_DIR}"

mkdir -p csgo
pushd csgo

ln -sfn "${CONFIG_DIR}" cfg

install_mod() {
  local mod_name="${1}"
  local mod_dir="addons/$(echo "${mod_name}" | tr '[:upper:]' '[:lower:]')"
  local mod_id="${2}"
  local mod_version_file="${mod_dir}/version.txt"
  local mod_version="${3}"
  local mod_url_prefix="${4}"

  if [[ -n "${mod_version}" ]]; then
    file_name="$(curl -sSfL "${mod_url_prefix}/${mod_version}/${mod_id}-latest-linux")"

    if [[ -f "${mod_version_file}" ]]; then
      if [[ "$(cat "${version_file}")" == "${file_name}" ]]; then
        echo "${mod_name} ${mod_version} already up-to-date."
        return
      fi

      echo "Updating ${mod_name} ${mod_version}."
    else
      echo "Installing ${mod_name} ${mod_version}."
    fi

    rm -rf "${mod_dir}"*
    curl -sSfL "${mod_url_prefix}/${mod_version}/${file_name}" | tar -L -xvz
    echo "${file_name}" > "${mod_version_file}"
  else
    rm -rf "${mod_dir}"*
  fi
}

install_mod MetaMod mmsource \
  "${METAMOD_VERSION-}" "https://mms.alliedmods.net/mmsdrop"

install_mod SourceMod sourcemod \
  "${SOURCEMOD_VERSION-}" "https://sm.alliedmods.net/smdrop"

popd

UPDATE_SCRIPT="${SERVER_DIR}/csgo_update.txt"

cat <<EOF > "${UPDATE_SCRIPT}"
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
login anonymous
force_install_dir "${SERVER_DIR}"
app_update 740 validate
quit
EOF

if ! [[ -f srcds_run ]]; then
  steamcmd +runscript "${UPDATE_SCRIPT}"
fi

touch "${CONFIG_DIR}/server.cfg"
touch "${CONFIG_DIR}/gamemode_competitive_server.cfg"
touch "${CONFIG_DIR}/gamemode_casual_server.cfg"

# There is no `steam.sh`, so create a wrapper
# and point `-steam_dir` to it.
cat <<'EOF' > "${SERVER_DIR}/steam.sh"
#!/usr/bin/env bash
exec "${STEAMEXE}" "${@}"
EOF
chmod +x "${SERVER_DIR}/steam.sh"

export LD_LIBRARY_PATH="${SERVER_DIR}:${SERVER_DIR}/bin${LD_LIBRARY_PATH+:${LD_LIBRARY_PATH}}"

exit_code=0
"${SERVER_DIR}/srcds_linux" \
  -game csgo \
  -console \
  -autoupdate \
  -norestart \
  -steamerr \
  -steam_dir "${SERVER_DIR}" \
  -steamcmd_script "${UPDATE_SCRIPT}" \
  -usercon \
  \
  ${GAME_TYPE++game_type "${GAME_TYPE}"} \
  ${GAME_MODE++game_mode "${GAME_MODE}"} \
  ${MAP_GROUP++mapgroup "${MAP_GROUP}"} \
  ${MAP++map "${MAP}"} \
  \
  ${WORKSHOP_AUTH_KEY+-authkey "${WORKSHOP_AUTH_KEY}"} \
  ${WORKSHOP_COLLECTION++host_workshop_collection "${WORKSHOP_COLLECTION}"} \
  ${WORKSHOP_START_MAP++workshop_start_map "${WORKSHOP_START_MAP}"} \
  \
  +log on \
  +sv_logfile 0 \
  \
  ${GSLT++sv_setsteamaccount "${GSLT}"} \
  \
  ${FPS_MAX++fps_max "${FPS_MAX}"} \
  ${TICK_RATE+-tickrate "${TICK_RATE:-128}"} \
  \
  ${PORT+-port "${PORT}"} \
  ${TV_PORT++tv_port "${TV_PORT}"} \
  ${CLIENT_PORT++clientport "${CLIENT_PORT}"} \
  ${MAX_PLAYERS+-maxplayers_override "${MAX_PLAYERS}"} \
  \
  ${RCON_PASSWORD++rcon_password "${RCON_PASSWORD}"} \
  ${PASSWORD++sv_password "${PASSWORD}"} \
  ${REGION++sv_region "${REGION}"} \
  ${SERVER_NAME++hostname "\"${SERVER_NAME}\""} \
  &
server_pid=$!

wait_for_server() {
  wait "${server_pid}" || exit_code=$?
  exit "${exit_code}"
}

graceful_shutdown() {
  signal="${1}"
  echo "Received ${signal}, shutting down."
  # `SIGTERM` results in an immediate shutdown,
  # `SIGINT` does a graceful shutdown.
  kill -INT "${server_pid}"
  wait_for_server
}

trap 'graceful_shutdown SIGINT' INT
trap 'graceful_shutdown SIGTERM' TERM

wait_for_server
