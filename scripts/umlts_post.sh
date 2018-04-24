#!/bin/bash

SHARED_DIR=$1
if [ -f "$SHARED_DIR/configs/variables" ]; then
  . "$SHARED_DIR"/configs/variables
fi

if [ -f "$SHARED_DIR/configs/umlts-variables" ]; then
  . "$SHARED_DIR"/configs/umlts-variables
fi

# Disable and enable various modules
# Disable modules that cause issues with VMs
cd "$DRUPAL_HOME" || exit
drush @sites vset --yes maintenance_mode 1 
drush @sites -y -u 1 dis toolbar overlay securelogin ldap_servers

# Install UMLTS features and fedora objects, install DGI repo connection config
cd "$DRUPAL_HOME"/sites/all/modules || exit
git clone https://github.com/umlts-labs/islandora_vagrant_features.git -b 7.x-1.10
git clone https://github.com/umlts-labs/islandora_vagrant_fedora_objects.git
git clone https://github.com/discoverygarden/islandora_repository_connection_config

drush @sites -y -u 1 en islandora_vagrant_features features islandora_repository_connection_config schema
drush @sites -y -u 1 fr islandora_vagrant_features
drush -y -u 1 en islandora_vagrant_fedora_objects
drush -u 1 ispiro --module=islandora
drush -u 1 ispiro --module=islandora_audio
drush -u 1 ispiro --module=islandora_basic_collection
drush -u 1 ispiro --module=islandora_basic_image
drush -u 1 ispiro --module=islandora_book
drush -u 1 ispiro --module=islandora_compound_object
drush -u 1 ispiro --module=islandora_large_image
drush -u 1 ispiro --module=islandora_newspaper
drush -u 1 ispiro --module=islandora_pdf
drush -u 1 ispiro --module=islandora_scholar
drush -u 1 ispiro --module=islandora_video

#cd "${DRUPAL_HOME}"/sites/all/modules || exit

for i in "${UMLTS_SITES_ARR[@]}"
do
	cd "$DRUPAL_HOME/sites/${i}" || exit
	drush eval "variable_set("islandora_repository_connection_config", array("cookies" => TRUE, "verifyHost" => TRUE, "verifyPeer" => TRUE, "timeout" => NULL, "connectTimeout" => "5", "userAgent" => "${i}_key", "reuseConnection" => TRUE, "debug" => FALSE))" 
  drush eval "variable_set('islandora_lame_url', '/usr/bin/lame')"
done

drush @sites -y -u 1 updatedb 
drush @sites vset --yes maintenance_mode 0

#Fix drupal permissions
#https://www.drupal.org/node/244924
cd "$DRUPAL_HOME" || exit
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

	for i in "${UMLTS_SITES_ARR[@]}"
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
	for i in "${UMLTS_SITES_ARR[@]}"
	do
		chmod 770 /mnt/storage/private/"$i"
		for d in /mnt/storage/private/"$i"
		do
			find $d -type d -print0 -exec chmod ug=rwx,o= '{}' \;
			find $d -type f -print0 -exec chmod ug=rw,o= '{}' \;
		done
	done
fi

# Install fcrepo3-security-jaas -- filter-drupal.xml installed earlier in provisioning
cp -v -- "${SHARED_DIR}/configs/fcrepo3-security-jaas/jaas.conf" /usr/local/fedora/server/config/jaas.conf
cp -v -- "${SHARED_DIR}/configs/fcrepo3-security-jaas/security.xml" /usr/local/fedora/server/config/spring/web/security.xml
cp -v -- "${SHARED_DIR}/configs/fcrepo3-security-jaas/fcrepo3-security-jaas-0.0.3-fcrepo3.8.1.jar" /var/lib/tomcat7/webapps/fedora/WEB-INF/lib/.

# Install configuration for multithread fedoragsearch updaters. 
cp -v -- "${SHARED_DIR}/configs/multithread_config/fedora.fcfg" /usr/local/fedora/server/config/fedora.fcfg
cp -v -- "${SHARED_DIR}/configs/multithread_config/fedoragsearch.properties" /var/lib/tomcat7/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/fedoragsearch.properties
rm -rf /var/lib/tomcat7/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/updater && \
	cp -Rv "${SHARED_DIR}/configs/multithread_config/updater" /var/lib/tomcat7/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/.

chown -R tomcat7:tomcat7 "/var/lib/tomcat7"
chown -R tomcat7:tomcat7 "/usr/local/fedora/server"
service tomcat7 restart
