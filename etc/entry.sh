#!/usr/bin/env bash

set -x
set -euo pipefail

pushd "${STEAMAPPDIR}"

mkdir -p csgo
pushd csgo

install_mod() {
  local mod_name="${1}"
  local mod_dir="addons/$(echo "${mod_name}" | tr '[[:upper:]]' '[[:lower:]]')"
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
    curl -sSfL "${mod_url_prefix}/${mod_version}/${file_name}" | tar -xvz
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

cat <<EOF > "${STEAMAPPDIR}/csgo_update.txt"
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
login anonymous
force_install_dir "${STEAMAPPDIR}"
app_update 740 validate
quit
EOF

steamcmd +runscript "${STEAMAPPDIR}/csgo_update.txt"

if [[ "${1:-}" = --no-start ]]; then
  exit 0
fi

"${STEAMAPPDIR}/srcds_run" \
  -game csgo \
  -console \
  -autoupdate \
  -steam_dir "${STEAMCMDDIR}" \
  -steamcmd_script "${STEAMAPPDIR}/csgo_update.txt" \
  -usercon \
  +fps_max "${SRCDS_FPSMAX:-300}" \
  -tickrate "${SRCDS_TICKRATE:-128}" \
  -port "${SRCDS_PORT:-27015}" \
  +tv_port "${SRCDS_TV_PORT:-27020}" \
  +clientport "${SRCDS_CLIENT_PORT:-27005}" \
  -maxplayers_override "${SRCDS_MAXPLAYERS:-14}" \
  +game_type "${SRCDS_GAMETYPE:-0}" \
  +game_mode "${SRCDS_GAMEMODE:-1}" \
  +mapgroup "${SRCDS_MAPGROUP:-mg_active}" \
  +map "${SRCDS_STARTMAP:-de_dust2}" \
  +sv_setsteamaccount "${SRCDS_TOKEN}" \
  +rcon_password "${SRCDS_RCONPW:-changeme}" \
  +sv_password "${SRCDS_PW:-changeme}" \
  +sv_region "${SRCDS_REGION:-3}"
