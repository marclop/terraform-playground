#!!/bin/bash

CONSUL_NODES=${CONSUL_NODES:-3}
DOCKER_ENGINE_HOST="${DOCKER_ENGINE_HOST:-localhost}"

pre_run(){
    docker-compose up --x-smart-recreate -d > /dev/null 2>&1
    docker-compose scale consulSlave=$((CONSUL_NODES - 1)) > /dev/null 2>&1
}

terraform() {
  pre_run
  local IMAGE_NAME="uzyexe/terraform"
  local CONTAINER_NAME="terraform_consul_1"

  docker run --rm --name terraform --link "${CONTAINER_NAME}":consul -v "$(pwd)/data:/data" "${IMAGE_NAME}" $*
}

terraform_cleanup() {
  docker-compose kill
  docker-compose rm -f
}

terraform_config() {
  pre_run
  terraform remote config --backend consul -backend-config="address=consul:8500" -backend-config="path=tf"
}

vault() {
  pre_run
  local CONTAINER_NAME="terraform_vault_1"

  docker exec "${CONTAINER_NAME}" vault $*
}

consul() {
  pre_run
  local CONTAINER_NAME="terraform_consul_1"

  docker exec "${CONTAINER_NAME}" consul $*
}

register_service() {
  pre_run
  local SVC="$1"
  local FILE="consul/services/${SVC}.json"
  local SVC_IP=$(docker exec terraform_${SVC}_1 sh -c 'grep "$(hostname)" /etc/hosts | awk "{print \$1}"')

  cp -f ${FILE}.dist ${FILE};
  sed -i "s/SVC_IP/${SVC_IP}/" ${FILE}

  local RETURN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT -d @${FILE} http://${DOCKER_ENGINE_HOST}:8500/v1/agent/service/register)

  echo "Status: ${RETURN_STATUS}"
  cat ${FILE}
  rm -f ${FILE}
}

query_service() {
  pre_run
  local SVC="$1"
  local ADDR="${DOCKER_ENGINE_HOST}"
  local SVC_RECORD="${SVC}.service.consul"
  local PORT=8600
  local TYPE="${2:-A}"

  dig ${TYPE} +short @${ADDR} -p ${PORT} ${SVC_RECORD}
}
