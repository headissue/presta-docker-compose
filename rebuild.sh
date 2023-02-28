#!/bin/bash

set -xe

cd "$(dirname "$0")"
export STARTUP_TIMEOUT=1000
export BINDADDRESS=localhost
export PORT=8881

function stop_services() {
  docker-compose down
}

function clean_volumes() {
  (
    cd mariadb_data
    sudo git clean -Xdf
  )
  (
    cd shop1_data
    sudo git clean -Xdf
  )
}

# Wait until application has started
#
# Variables:
# TIMEOUT: don't wait long than TIMEOUT seconds
# PORT: http port tomcat listens to
#
# Return value:
# 0: started successful
# 1: error detected
#
waitForStartup() {
  test -z "$PORT" && return
  local starttime=$(date +%s)
  local maxtime=$(($starttime + $STARTUP_TIMEOUT))
  local rc
  while [ $(date +%s) -lt $maxtime ]; do
    rc=0
    msg=$(curl --max-time 5 http://$BINDADDRESS:$PORT -o /dev/null 2>&1) || rc=$?
    case $rc in
    # we got an ansewer, tomcat is up
    0) return ;;
    # empty reply from server
    52)
      sleep 3
      continue
      ;;
    # connection reset by peer
    56)
      sleep 3
      continue
      ;;
    # could not connect (nobody listens on port)
    7)
      sleep 3
      continue
      ;;
    # timeout
    28) continue ;;
    *)
      echo "$msg" 1>&2
      return 1
      ;;
    esac
  done
}

function start_services() {
  docker-compose up -d --build &
  waitForStartup
}

function set_permissions() {
  sudo chmod -R a+w ./shop1_data
}

all() {
  stop_services
  clean_volumes
  start_services
  set_permissions
}

# "$@"

all
