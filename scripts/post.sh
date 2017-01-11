#!/bin/bash

SHARED_DIR=$1
if [ -f "$SHARED_DIR/configs/variables" ]; then
  . "$SHARED_DIR"/configs/variables
fi

# Install features to enforce djatoka url setting, among other things
cd "$DRUPAL_HOME"/sites/all/modules || exit
drush @sites -y -u 1 en features
git clone https://github.com/nihilanth41/islandora_vagrant_features.git
cd "$DRUPAL_HOME"/sites/mu || exit
drush -y -u 1 en islandora_vagrant_features
drush -y fr islandora_vagrant_features
cd "$DRUPAL_HOME"/sites/umkc || exit
drush -y -u 1 en islandora_vagrant_features
drush -y fr islandora_vagrant_features
cd "$DRUPAL_HOME"/sites/umsl || exit
drush -y -u 1 en islandora_vagrant_features
drush -y fr islandora_vagrant_features

# Setup a user for Tomcat Manager
sed -i '$i<role rolename="admin-gui"/>' /etc/tomcat7/tomcat-users.xml
sed -i '$i<user username="islandora" password="islandora" roles="manager-gui,admin-gui"/>' /etc/tomcat7/tomcat-users.xml
service tomcat7 restart

# Set correct permissions on sites/default/files
chmod -R 775 /var/www/drupal/sites/default/files

# Fix drupal permissions
# https://www.drupal.org/node/244924
cd "$DRUPAL_HOME"
chown -R vagrant:www-data .
# chmod 750 for all *directories* in drupal root (recursive) 
find . -type d -exec chmod u=rwx,g=rx,o= '{}' \;
# chmod 640 for all *files* in drupal root (recursive)
find . -type f -exec chmod u=rw,g=r,o= '{}' \;

if [ -d /mnt/storage ]; then 
	#/mnt/storage
	chown -R vagrant:www-data /mnt/storage
	chmod 770 /mnt/storage 

	#files dir 
	chown -R vagrant:www-data /mnt/storage/files
	chmod 770 /mnt/storage/files 
	sites_arr=( default lso merlin mu umkc umkclaw umkcscholar umsl ) 
	for i in "${sites_arr[@]}"
	do
		chmod 770 /mnt/storage/files/"$i"
		for d in /mnt/storage/files/"$i"
		do
			find $d -type d -print0 -exec chmod ug=rwx,o= '{}' \;
			find $d -type f -print0 -exec chmod ug=rw,o= '{}' \;
		done
	done

	#private dir 
	chown -R vagrant:www-data /mnt/storage/private
	chmod 770 /mnt/storage/private
	sites_array=( default lso merlin mu umkc umkcscholar umsl ) 
	for i in "${sites_array[@]}"
	do
		chmod 770 /mnt/storage/private/"$i"
		for d in /mnt/storage/private/"$i"
		do
			find $d -type d -print0 -exec chmod ug=rwx,o= '{}' \;
			find $d -type f -print0 -exec chmod ug=rw,o= '{}' \;
		done
	done
fi
