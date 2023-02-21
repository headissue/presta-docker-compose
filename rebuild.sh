#!/bin/bash

set -x

function stop_services() {
  docker-compose down
}

function cd_to_project_dir() {
  cd "$(dirname "$0")" || exit 1
}

function clean_volumes() {
  cd_to_project_dir
  cd mariadb_data || exit 1
  sudo git clean -Xdf
  cd ../shop1_data || exit 1
  sudo git clean -Xdf
}

function get_from_github_release_zip() {
  url=$1
  vendor=$2
  version=$3
  if test ! -d vendor/$vendor-$version; then
    mkdir -p vendor/$vendor
    wget $url -O vendor/$vendor/$version.zip
    unzip vendor/$vendor/$version.zip -d vendor/$vendor-$version
  fi
}

function get_dependencies() {
  get_from_github_release_zip \
    "https://github.com/Oksydan/falcon/releases/download/v3.0.1/falcon.zip" \
    "Oksydan/falcon" \
    "3.0.1"

  get_from_github_release_zip \
    "https://github.com/Oksydan/is_themecore/releases/download/v3.0.1/is_themecore.zip" \
    "Oksydan/is_themecore" \
    "3.0.1"

  get_from_github_release_zip \
    "https://github.com/Oksydan/is_imageslider/releases/download/v2.0.1/is_imageslider.zip" \
    "Oksydan/is_imageslider" \
    "2.0.1"

  get_from_github_release_zip \
    "https://github.com/Oksydan/is_searchbar/releases/download/v2.0.0/is_searchbar.zip" \
    "Oksydan/is_searchbar" \
    "2.0.0"

  get_from_github_release_zip \
    "https://github.com/Oksydan/is_shoppingcart/releases/download/v2.0.0/is_shoppingcart.zip" \
    "Oksydan/is_shoppingcart" \
    "2.0.0"
}

function start_services() {
  docker-compose up -d --build &
  url="http://localhost:8881"
  http_status=""
  while [[ "$http_status" != "200" ]]; do
    wget_output=$(wget --spider --server-response "$url" 2>&1)
    http_status=$(echo "$wget_output" | awk '/HTTP\/1.1/{print $2}')
    sleep 1
  done
}

function set_permissions() {
  cd_to_project_dir
  sudo chmod -R a+w ./shop1_data
}

function copy_modules() {
  cp -r custom_modules/* shop1_data/html/modules
  cp -r vendor/Oksydan/is_*/is_* shop1_data/html/modules
  sudo chown -R www-data:www-data shop1_data/html/modules
}

function enable_theme() {
  cp -r vendor/Oksydan/falcon-3.0.2 shop1_data/html/themes/falcon
  sudo chown -R www-data:www-data shop1_data/html/themes
  docker exec -it shop1 \
    runuser -u www-data php bin/console prestashop:theme:enable falcon
}

stop_services
clean_volumes
start_services
set_permissions
get_dependencies
copy_modules
enable_theme
