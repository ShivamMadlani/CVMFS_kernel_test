#!/bin/bash
set -eu

RED='\033[0;31m'
GREEN='\033[0;32m'
BGREEN='\033[1;92m'
YELLOW='\033[0;33m'
RESET='\033[0m'

log() {
  echo -e "${GREEN}[INFO]${RESET} $*"
}

warn() {
  echo -e "${YELLOW}[WARN]${RESET} $*"
}

error() {
  echo -e "${RED}[ERROR]${RESET} $*" >&2
}

success() {
  echo -e "${BGREEN}[SUCCESS]${RESET} $*"
}