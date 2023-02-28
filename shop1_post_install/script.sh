#!/bin/bash

set -ex

export DOWNLOADS="/tmp/Downloads"
export SHOP_DIR="/var/www/html"

# Common https download. Downloads a file if not existing already in $DOWNLOADS
#
# dl <url> <localfile> <sha256sum>
#
dl() {
  mkdir -p $DOWNLOADS
  local file="$DOWNLOADS/$2"
  local mirrorpath="$(echo "$1" | sed -r -e 's#^https?://##')"
  test -f "$file" || {
    # TODO: have a download mirror
    # curl -s -L -f "http://dump.headissue.net/dump/mirror/${mirrorpath}" -o "$file" || \
    curl -s -L -f -b "oraclelicense=accept-securebackup-cookie" "$1" -o "$file" || {
      rm -f "$file"
      echo "Download failed" 1>&2
      return 1
    }
  }
  sum=$(sha256sum <$file | awk '{print $1;}')
  if [ "$3" = 'todo' ]; then
    echo $(basename "$file") $sum
    return
  fi
  sum=$(sha256sum <$file | awk '{print $1;}')
  if [ "$3" != "$sum" ]; then
    echo "sha256sum does not match for $1" 1>&2
    rm -f "$file"
    return 1
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
  export file="$fn"
}


#
# Replaces existing directory drops cruft files from theme like MACOS...
#
_unpack_project() {
  local dir=unpack-$$-$project
  mkdir -p $dir
  unzip -q $DOWNLOADS/"$file" -d $dir
  test -d $dir/$project || {
    echo "$file: directory with $project expected in zip"
    exit 1
  }
  if test -d $project; then
    mv $project $project.backup
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
    cd $SHOP_DIR/modules
    _unpack_project
  )
}

# Install module zip from $DOWNLOADS folder
# Takes argument from $file
#
install_theme_zip() {
  (
    cd $SHOP_DIR/themes
    _unpack_project
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

function enable_falcon_theme() {
  php $SHOP_DIR/bin/console prestashop:theme:enable falcon
}

install_falcon_theme
enable_falcon_theme
