#!/bin/bash

echo "Setup UMLTS multisite, and restore backup data"

SHARED_DIR=$1
if [ -f "$SHARED_DIR/configs/variables" ]; then
  . "$SHARED_DIR"/configs/variables
fi

if [ -f "$SHARED_DIR/configs/umlts-variables" ]; then
  . "$SHARED_DIR"/configs/umlts-variables
fi

# Install umlts drupal filter
if [ -f "$SHARED_DIR/configs/filter-drupal.xml" ]; then
  sudo cp "$SHARED_DIR/configs/filter-drupal.xml" "$FEDORA_HOME/server/config/filter-drupal.xml"
  sudo chown -hR tomcat7:tomcat7 "$FEDORA_HOME"
fi

# Install site for each multisite, including sites folder, settings, files, and account credentials
# See: https://drushcommands.com/drush-6x/core/site-install/
function umlts_install_multisite() {
  local -n ARR
  ARR=$1
  cd "$DRUPAL_HOME" || exit
  for site in ${ARR[@]}; do
    user="${site}dba" 
    password="${site}_pass"
    # Default site is different
    if [ "$site" == "default" ]; then
      drush sql-drop -y
      drush site-install -y standard install_configure_form.update_status_module='array(FALSE,FALSE)' --db-url=mysql://"${user}:${password}@localhost/drupal7" --sites-subdir="default" --site-name="localhost/${site}" --db-su="root" --db-su-pw="islandora" --account-pass="islandora"
    # Now do other sites
    else
      drush site-install -y standard install_configure_form.update_status_module='array(FALSE,FALSE)' --db-url=mysql://"${user}:${password}@localhost/${site}" --sites-subdir="$site" --site-name="localhost/${site}" --db-su="root" --db-su-pw="islandora" --account-pass="islandora"
    fi
  done
}

# Create symlink inside docroot, required for multisite with subdomain to work properly
function umlts_create_symlink_subdomain() {
  local -n ARR
  ARR=$1
  cd "$DRUPAL_HOME" || exit
  for site in ${ARR[@]}; do
    ln -s . "$site"
  done
}

# Create symlink inside sites directory
function umlts_create_symlink_site() {
  local -n ARR
  ARR=$1
  cd "$DRUPAL_HOME"/sites || exit
  for site in ${ARR[@]}; do
    ln -s "$site" localhost."$site"
  done
}

# Restore db backup, symlink files
function umlts_restore_multisite_data() {
  local -n ARR
  ARR=$1
  cd "$DRUPAL_HOME"/sites || exit
  for site in ${ARR[@]}; do

    # Delete files directory if it already exists 
    FILES_DIR="$DRUPAL_HOME/sites/$site/files"
    if [ -d "$FILES_DIR" ]; then 
      rm -rf "$FILES_DIR"
    fi

    # Create symlink to new files directory 
    ln -sf "$UMLTS_DEST_DIR/files/$site" "$FILES_DIR"
    chown -R www-data:www-data "$FILES_DIR" 

    # Set private filesystem path 
    cd "$DRUPAL_HOME/sites/$site"
    drush vset --yes file_private_path "$UMLTS_DEST_DIR/private/$site" 

    # Run backup_migrate restore   
    drush -y bam-restore db manual dldev-"$site".mysql

    # Set default admin login 
    drush user-password admin --password=islandora 

    # Set temporary files path 
    drush vset --yes file_temporary_path /tmp 
    
    # Set public files path 
    drush vset --yes file_public_path sites/"$site"/files
  done
}

umlts_install_multisite UMLTS_SITES_ARR
umlts_create_symlink_subdomain UMLTS_SITES_ARR_SANS_DEFAULT
umlts_create_symlink_site UMLTS_SITES_ARR

# Enable backup_migrate for all sites 
cd "$DRUPAL_HOME"
drush @sites -y -u 1 en backup_migrate 
#drush @sites cc all

# Suppress error when disabling ldap
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get -y install php5-mcrypt -q
cd /etc/php5/cli/conf.d
sudo ln -s ../../mods-available/mcrypt.ini 20-mcrypt.ini
sudo php5enmod mcrypt

umlts_restore_multisite_data UMLTS_SITES_ARR
