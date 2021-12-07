#!/usr/bin/env bash

set -x
set -euo pipefail

VERSION_FILE="${SERVER_DIR}/version.txt"
pushd "${SERVER_DIR}"

mkdir -p csgo
pushd csgo

ln -sfn "${CONFIG_DIR}" cfg

app_id=740

steamcmd() {
  "${STEAMCMDDIR}/steamcmd.sh" \
    +@ShutdownOnFailedCommand 1 \
    +@NoPromptForPassword 1 \
    +login anonymous \
    "${@}"
}

fetch_build_id() {
  steamcmd \
    +app_info_update 1 \
    +app_info_print "${app_id}" \
    +quit | \
      sed '1,/"branches"/d' | \
      sed '1,/"public"/d' | \
      sed '/\}/q' | \
      sed -n -E 's/.*"buildid"\s+"([0-9]+)".*/\1/p'
}

update() {
  steamcmd \
    +force_install_dir "${SERVER_DIR}" \
    +app_update "${app_id}" -validate \
    +quit

  echo "${1}" > "${VERSION_FILE}"
}

update_if_needed() {
  latest_version="$(fetch_build_id)"

  if installed_version="$(cat "${VERSION_FILE}" 2>/dev/null)"; then
    if [[ "${installed_version}" -eq "${latest_version}" ]]; then
      echo "Server version ${installed_version} is up-to-date."
      return
    fi

    echo "Updating server from version ${installed_version} to ${latest_version}."
  else
    echo "Installing server version ${latest_version} …"
  fi

  update "${latest_version}"
}

update_if_needed

install_mod() {
  local mod_name="${1}"
  local mod_dir
  mod_dir="addons/$(echo "${mod_name}" | tr '[:upper:]' '[:lower:]')"
  local mod_id="${2}"
  local mod_version_file="${mod_dir}/version.txt"
  local mod_version="${3}"
  local mod_url_prefix="${4}"

  if [[ -n "${mod_version}" ]]; then
    file_name="$(curl -sSfL "${mod_url_prefix}/${mod_version}/${mod_id}-latest-linux")"

    if [[ -f "${mod_version_file}" ]]; then
      if [[ "$(cat "${mod_version_file}")" == "${file_name}" ]]; then
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

touch "${CONFIG_DIR}/server.cfg"
touch "${CONFIG_DIR}/gamemode_competitive_server.cfg"
touch "${CONFIG_DIR}/gamemode_casual_server.cfg"

exit_code=0
"${SERVER_DIR}/srcds_run" \
  -game csgo \
  -console \
  -norestart \
  -steamerr \
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
  trap - INT
  trap - TERM
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
