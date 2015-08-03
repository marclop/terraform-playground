#!!/bin/bash

pre_run(){

  docker-compose up --x-smart-recreate -d > /dev/null
  docker-compose scale consulSlave=2
  
}

terraform() {

  pre_run
  ## Link with consul
  local IMAGE_NAME="uzyexe/terraform"

  docker run --rm --name terraform --link terraform_consul_1:consul -v ~/repos/terraform/data:/data "${IMAGE_NAME}" $*

}

terraform_cleanup() {

  docker-compose kill
  docker-compose rm -f

}
