#!/usr/bin/env bash

set -x
set -euo pipefail

pushd "${STEAMAPPDIR}"

mkdir -p csgo
pushd csgo

install_mod() {
  local mod_name="${1}"
  local mod_dir="${2}"
  local mod_version_file="${mod_dir}/version.txt"
  local mod_version="${3}"
  local mod_url="${4}"

  if [[ -n "${mod_version}" ]] && [[ -f "${mod_version_file}" ]] && [[ "$(cat "${version_file}")" == "${mod_version}" ]]; then
    echo "${mod_name} ${mod_version} already installed."
  else
    rm -rf "${mod_dir}"*

    if [[ -n "${mod_version}" ]]; then
      echo "Installing ${mod_name} ${mod_version}."
      curl -sSfL "${mod_url}" | tar -xvz
      echo "${mod_version}" > "${mod_version_file}"
    fi
  fi
}

install_mod MetaMod addons/metamod \
  "${METAMOD_VERSION-}" \
  "https://mms.alliedmods.net/mmsdrop/${METAMOD_VERSION%.*}/mmsource-${METAMOD_VERSION}-linux.tar.gz"

install_mod SourceMod addons/sourcemod \
  "${SOURCEMOD_VERSION-}" \
  "https://sm.alliedmods.net/smdrop/${SOURCEMOD_VERSION%.*}/sourcemod-${SOURCEMOD_VERSION}-linux.tar.gz"

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
