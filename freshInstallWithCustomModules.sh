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

function set_permissions_and_copy_our_modules() {
  cd_to_project_dir
  sudo chmod -R a+w ./shop1_data
  cp -r custom_modules/* shop1_data/html/modules
  sudo chown -R www-data:www-data shop1_data/html/modules
}

stop_services
clean_volumes
start_services
set_permissions_and_copy_our_modules