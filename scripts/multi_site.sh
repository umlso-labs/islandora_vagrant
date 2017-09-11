#!/bin/bash

SHARED_DIR=$1
if [ -f "$SHARED_DIR/configs/variables" ]; then
  . "$SHARED_DIR"/configs/variables
fi

# Install new drupal filter before enabling umkc features modules
if [ -f "$SHARED_DIR/configs/filter-drupal.xml" ]; then
	sudo service tomcat7 stop
	sudo cp "$SHARED_DIR/configs/filter-drupal.xml" "$FEDORA_HOME/server/config/filter-drupal.xml"
	sudo chown -hR tomcat7:tomcat7 "$FEDORA_HOME"
	sudo service tomcat7 start
fi

echo "Installing Drupal themes" 
cd "$DRUPAL_HOME"/sites/all
if [ ! -d themes ]; then
  mkdir themes
fi

cd "$DRUPAL_HOME"/sites/all/themes || exit
git clone https://github.com/umlts/dl-theme.git dl-theme 
git clone https://github.com/umlts/lso-theme.git lso-theme 
git clone https://github.com/umlts/merlin-theme.git merlin-theme 
git clone https://github.com/umlts/mu-theme.git mu-theme 
# This branch is for most recent zen version (7.x-6.4) w/ Islandora 1.8 changes
git clone -b zen-6.4 https://github.com/umlts/umkc-theme.git umkc-theme 
git clone https://github.com/umlts/umsl-theme.git umsl-theme 

# Create ctools/css and set permissions
cd "$DRUPAL_HOME"/sites/all
mkdir -p files/ctools/css 
chmod 777 files/ctools/css

# Increase php memory_limit (It gets exceeded when clearing drupal cache) 
sed -i 's/128M/256M/g' /etc/php5/apache2/php.ini 
service apache2 restart 

# Suppress apache2 error about ServerName 
sudo echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Setup multi-site 
sites_arr=( lso merlin mu umkc umkclaw umkcscholar umsl ) 
for i in "${sites_arr[@]}"
do
	cd "${DRUPAL_HOME}"
	SITE_USER="${i}dba" 
	SITE_PASS="${i}_pass"
	# --db-su and --db-su-pass specify the /mysql user/ that has permission to create new mysql databases. 
	drush si -y --db-url=mysql://"${SITE_USER}:${SITE_PASS}@localhost/${i}" --sites-subdir="$i" --site-name="localhost/${i}" --db-su="root" --db-su-pw="islandora"
	# Symlink inside docroot 
	ln -s . "$i"
	# Symlink inside sites dir
	cd "$DRUPAL_HOME"/sites
	ln -s "$i" localhost."$i" 
	cd $DRUPAL_HOME/sites/"$i" 
	# Set password & create ctools/css for each site
	drush user-password admin --password=islandora
	mkdir -pm 777 files/ctools/css 
done

# Enable modules for all sites	
cd "$DRUPAL_HOME/sites/all/modules" || exit
sudo drush @sites -y -u 1 en php_lib islandora objective_forms
sudo drush @sites -y -u 1 en islandora_solr islandora_solr_metadata islandora_solr_facet_pages islandora_solr_views
sudo drush @sites -y -u 1 en islandora_basic_collection islandora_pdf islandora_audio islandora_book islandora_compound_object islandora_disk_image islandora_entities islandora_entities_csv_import islandora_basic_image islandora_large_image islandora_newspaper islandora_video islandora_web_archive
sudo drush @sites -y -u 1 en islandora_premis islandora_checksum islandora_checksum_checker
sudo drush @sites -y -u 1 en islandora_book_batch islandora_pathauto islandora_pdfjs islandora_videojs islandora_jwplayer
sudo drush @sites -y -u 1 en xml_forms xml_form_builder xml_schema_api xml_form_elements xml_form_api jquery_update zip_importer islandora_basic_image islandora_bibliography islandora_compound_object islandora_google_scholar islandora_scholar_embargo islandora_solr_config citation_exporter doi_importer endnotexml_importer pmid_importer ris_importer
sudo drush @sites -y -u 1 en islandora_fits islandora_ocr islandora_oai islandora_marcxml islandora_simple_workflow islandora_xacml_api islandora_xacml_editor islandora_xmlsitemap colorbox islandora_internet_archive_bookreader islandora_bagit islandora_batch_report islandora_usage_stats islandora_form_fieldpanel islandora_altmetrics islandora_populator islandora_newspaper_batch 

sudo drush @sites -y -u 1 en admin_menu

# Disable modules that are problematic in the VM environment 
sudo drush @sites -u 1 -y dis toolbar overlay securelogin ldap_servers 

# Enable umkc specific modules 
cd "$DRUPAL_HOME"/sites/umkc
sudo drush -u 1 -y en umkcdora umkc_feature_types topics_and_types umkc_content_types umkc_browse

# Enable themes for all sites 
cd "$DRUPAL_HOME"/sites/all/themes 
# Download zen theme (required by umkc_theme) 
drush -y dl zen-7.x-6.4
drush @sites -y -u 1 en dl_theme lso_theme merlin_theme mu_theme umkc_theme umsl_theme zen

# Set themes and fix default home page (umkc_feature_types changes home page from /node to /home)
# Default site 
cd "$DRUPAL_HOME"/sites/default
drush vset theme_default dl_theme
drush vset admin_theme default 
drush vset site_frontpage node 
# All other sites get their own theme 
sites_arr=( lso merlin mu umkc umsl ) 
for i in "${sites_arr[@]}"
do
	cd "$DRUPAL_HOME"/sites/"$i" 
	drush vset theme_default "$i"_theme 
	drush vset admin_theme default
	drush vset site_frontpage node 
done 

# Disable email notifications for development
# http://drupal.stackexchange.com/a/97834
# Disable update module -> disable notifications about updates
cd "$DRUPAL_HOME"
#drush @sites -y -u 1 pm-disable update
drush @sites -y -u 1 en devel

# Let DevelMailLog intercept all mail 
# Add to settings.php for each site
sites_arr=( default lso merlin mu umkc umkclaw umkcscholar umsl ) 
MAIL_CFG_TXT="
\$conf['mail_system'] = array(
  'default-system' => 'DevelMailLog',
);
\$conf['devel_debug_mail_directory'] = '/tmp';
"
for i in "${sites_arr[@]}"; do
	echo "$MAIL_CFG_TXT" >> "$DRUPAL_HOME/sites/$i/settings.php"
done

# Symlink tesseract binary
sudo ln -sf /usr/bin/tesseract /usr/local/bin/tesseract

# Create root collection pids in fedora
cd "$DRUPAL_HOME"/sites/all/modules || exit
git clone https://github.com/umlts-labs/islandora_vagrant_fedora_objects.git
drush -y -u 1 en islandora_vagrant_fedora_objects

# Enable general query log so that we can see if the fcrepo-security-jaas module is working.
# /var/lib/mysql/islandora.log
mysql -uroot -pislandora -t<<EOF
SET GLOBAL general_log = 1;
EOF
