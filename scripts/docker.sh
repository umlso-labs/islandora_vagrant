#!/bin/bash

SHARED_DIR=$1
if [ -f "$SHARED_DIR/configs/variables" ]; then
  . "$SHARED_DIR"/configs/variables
fi

# Install docker dependencies
# https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/#uninstall-old-versions
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
   
apt-get update
apt-get install -y \
    linux-image-extra-$(uname -r) \
    linux-image-extra-virtual \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    docker-ce
	
if [ -d "$SHARED_DIR/islandora_vagrant_blazegraph" ]; then
	cp -Rv -- "$SHARED_DIR/islandora_vagrant_blazegraph" "$HOME_DIR"
	
	# Needed for when we rebuild fedora  (fedora-rebuild.sh)
	echo 'export FEDORA_HOME="/usr/local/fedora"' >> "$HOME_DIR"/.bash_profile
	echo 'export CATALINA_HOME="/var/lib/tomcat7"' >> "$HOME_DIR"/.bash_profile
	
	cd "$HOME_DIR"/islandora_vagrant_blazegraph/docker-blazegraph || exit
	docker build -t blazecat . 	
	docker run -d --restart=always -p 8081:8080 --name blaze1 -i -t blazecat
	
	bash -c "$HOME_DIR"/islandora_vagrant_blazegraph/islandora-blazegraph/install.sh
fi
