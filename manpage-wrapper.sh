#!/usr/bin/env bash

# Bash strict mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o nounset   # Using an undefined variable is fatal
# set -o errexit   # A sub-process/shell returning non-zero is fatal
# set -o pipefail  # If a pipeline step fails, the pipelines RC is the RC of the failed step
# set -o xtrace    # Output a complete trace of all bash actions; uncomment for debugging

# IFS=$'\n\t'  # Only split strings on newlines & tabs, not spaces.

function init() {
  readonly script_path="${BASH_SOURCE[0]:-$0}"
  readonly script_dir="$(dirname "$script_path")"
  readonly script_name="$(basename "$script_path")"

  setup_colors
  parse_params "$@"
}

function usage() {
  cat <<EOF

Wraps both tldr & man. If there's a tldr page, it'll use your tldr client to display it, if not it'll offer to try man instead.

${bld}USAGE${off}
  $script_name [options] QUERY

${bld}OPTIONS${off}
  -h, --help       show this help

${bld}ARGUMENTS${off}
  QUERY   The thing to lookup in tldr or man

${bld}EXAMPLES${off}
  ${gry}# Query tldr/man for "tar"${off}
  $ $script_name tar
EOF
  exit
}

function setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    # Control sequences for fancy colours
    readonly red="$(tput setaf 1 2> /dev/null || true)"
    readonly grn="$(tput setaf 2 2> /dev/null || true)"
    readonly ylw="$(tput setaf 3 2> /dev/null || true)"
    readonly wht="$(tput setaf 7 2> /dev/null || true)"
    readonly gry="$(tput setaf 240 2> /dev/null || true)"
    readonly bld="$(tput bold 2> /dev/null || true)"
    readonly off="$(tput sgr0 2> /dev/null || true)"
  else
    readonly red='' readonly grn='' readonly ylw='' readonly wht='' readonly gry='' readonly bld='' readonly off=''
  fi
}

function msg() {
  echo >&2 -e "${1:-}"
}

function die() {
  local msg=$1
  local code=${2:-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

function parse_params() {
  local param
  while [[ $# -gt 0 ]]; do
    param="$1"
    shift
    case $param in
      -h | --help | help)
        usage
        ;;
    esac
  done
}

init "$@"

# Check dependencies
if ! command -v tldr &> /dev/null
then
  die "a tldr command could not be found\n\
    $script_name requires some kind of tldr client, eg tealdear:\n\
    See: https://github.com/dbrgn/tealdeer" 127
fi


if [[ $# == 0 ]]; then
  msg "Missing parameter: query."
  usage
fi


# 
# Implement the script here
# 
tldr "$@"
readonly rc="$?"
if [ "$rc" -gt 0 ]; then
  read -n 1 -p "Show manpage (y/n)?" choice
  case "$choice" in 
    y|Y ) man "$@";;
  esac
fi
