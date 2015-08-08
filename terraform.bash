#!!/bin/bash

pre_run(){
    docker-compose up --x-smart-recreate -d > /dev/null 2>&1
    docker-compose scale consulSlave=2 > /dev/null 2>&1
}

terraform() {
  pre_run
  ## Link with consul
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
  local SVC="$1"
  local FILE="consul/services/${SVC}.json"
  local SVC_IP=$(docker exec terraform_${SVC}_1 sh -c 'grep "$(hostname)" /etc/hosts | awk "{print \$1}"')

  cp -f ${FILE}.dist ${FILE}
  sed -i "s/SVC_IP/${SVC_IP}/" ${FILE}
  local RETURN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT -d @${FILE} http://localhost:8500/v1/agent/service/register)
  echo "Status: ${RETURN_STATUS}"
  cat ${FILE}
  rm -f ${FILE}
}
