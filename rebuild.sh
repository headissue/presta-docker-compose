#!/bin/bash

set -xe

cd "$(dirname "$0")"
export DOWNLOADS="`pwd`/Downloads"
export SHOP_DIR="`pwd`/shop1_data/html"
export STARTUP_TIMEOUT=1000;
export BINDADDRESS=localhost;
export PORT=8881;

function stop_services() {
  docker-compose down
}

function clean_volumes() {
  ( cd mariadb_data; sudo git clean -Xdf )
  ( cd shop1_data; sudo git clean -Xdf )
}

# Common https download. Downloads a file if not existing already in $DOWNLOADS
#
# dl <url> <localfile> <sha256sum>
#
dl() {
mkdir -p $DOWNLOADS
local file="$DOWNLOADS/$2"
local mirrorpath="`echo "$1" | sed -r -e 's#^https?://##'`"
test -f "$file" || {
  # TODO: have a download mirror
  # curl -s -L -f "http://dump.headissue.net/dump/mirror/${mirrorpath}" -o "$file" || \
  curl -s -L -f -b "oraclelicense=accept-securebackup-cookie" "$1" -o "$file" || {
    rm -f "$file"
    echo "Download failed" 1>&2;
    return 1;
  }
}
sum=`sha256sum < $file | awk '{print $1;}'`;
if [ "$3" = 'todo' ]; then
  echo `basename "$file"` $sum;
  return;
fi  
sum=`sha256sum < $file | awk '{print $1;}'`;
if [ "$3" != "$sum" ]; then
  echo "sha256sum does not match for $1" 1>&2
  rm -f "$file"
  return 1;
fi
}

#
# <vendor> <project> <version> <sha256sum>
#
fetch_githup_release_zip() {
  vendor=$1
  export project=$2
  version=$3
  sha256sum=$4
  local fn=$1-$2-$3.zip
  dl https://github.com/$vendor/$project/releases/download/v$version/$project.zip $fn $sha256sum
  export file="$fn";
}

#
# Replaces existing directory drops cruft files from theme like MACOS...
#
_unpack_project() {
local dir=unpack-$$-$project;
    mkdir -p $dir;
    unzip -q $DOWNLOADS/"$file" -d $dir;
    test -d $dir/$project || {
      echo "$file: directory with $project expected in zip";
      exit 1;
    }
    if test -d $project; then
      mv $project $project.backup;
    fi  
    mv $dir/$project $project
    rm -rf $project.backup
    rm -rf $dir
}

# Install module zip from $DOWNLOADS folder
# Takes argument from $file
#
install_module_zip() {
  (  
    cd $SHOP_DIR/modules;
    _unpack_project;
  )
}

# Install module zip from $DOWNLOADS folder
# Takes argument from $file
#
install_theme_zip() {
  (  
    cd $SHOP_DIR/themes;
    _unpack_project;
  )
}

install_falcon_theme() {
fetch_githup_release_zip Oksydan is_themecore 3.0.1 todo
install_module_zip
fetch_githup_release_zip Oksydan is_imageslider 2.0.1 todo
install_module_zip
fetch_githup_release_zip Oksydan is_searchbar 2.0.0 todo
install_module_zip
fetch_githup_release_zip Oksydan is_shoppingcart 2.0.0 todo
install_module_zip
fetch_githup_release_zip Oksydan falcon 3.0.1 todo
install_theme_zip
}

function enable_falcon-theme() {
  docker exec -it shop1 \
    runuser -u www-data php bin/console prestashop:theme:enable falcon
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
  test -z "$PORT" && return;
  local starttime=`date +%s`;
  local maxtime=$(( $starttime + $STARTUP_TIMEOUT ));
  local rc;
  while [ `date +%s` -lt $maxtime ]; do
    rc=0;
    msg=`curl --max-time 5 http://$BINDADDRESS:$PORT -o /dev/null 2>&1` || rc=$?;
    case $rc in
      # we got an ansewer, tomcat is up
      0) return;;
      # empty reply from server
      52) sleep 3; continue;;
      # connection reset by peer
      56) sleep 3; continue;;
      # could not connect (nobody listens on port)
      7) sleep 3; continue;;
      # timeout
      28)continue;;
      *) echo "$msg" 1>&2;
         return 1;;
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
install_falcon_theme
set_permissions
enable_falcon-theme
}

# "$@"

all
