PROJ_NAME = eggshell

.PHONY: create-server
create-server:
	doctl compute droplet create ${PROJ_NAME}-server --size 1gb --image ubuntu-18-04-x64 --region nyc1 --ssh-keys ${DOFP} -t ${DOAT} --tag-names ${PROJ_NAME},${PROJ_NAME}-server

.PHONY: delete-server
delete-server:
	doctl compute droplet delete ${PROJ_NAME}-server -t ${DOAT}


SERVER_IP = ${shell doctl compute droplet list --tag-name ${PROJ_NAME}-server --format "PublicIPv4" -t ${DOAT} | tail -n +2}

.PHONY: server-ip
server-ip:
	@echo ${SERVER_IP}

.PHONY: delete-old
delete-old: stop-old
	docker rm ${PROJ_NAME}

.PHONY: build-prod-webpack
build-prod-webpack:
	rm -rf build/* && yarn build

.PHONY: build-prod-docker
build-prod-docker: 
	docker build . -t ${PROJ_NAME}

.PHONY: build-prod
build-prod: build-prod-webpack build-prod-docker

.PHONY: stop-old
stop-old:
	docker kill ${PROJ_NAME}

.PHONY: deploy
deploy: build-prod
	docker run --name ${PROJ_NAME} -p 3500:3000 -d ${PROJ_NAME} 

.PHONY: kill-and-deploy
kill-and-deploy: delete-old build-prod


.PHONY: create-machine
create-machine:
	docker-machine create --driver generic --generic-ip-address=${SERVER_IP} --generic-ssh-user root --generic-ssh-key ${HOME}/secrets/do_id_rsa ${PROJ_NAME}

.PHONY: remove-machine
remove-machine:
	docker-machine rm ${PROJ_NAME}
