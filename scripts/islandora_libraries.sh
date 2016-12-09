#!/bin/bash

echo "Installing all Islandora Foundation module's required libraries"

SHARED_DIR=$1

if [ -f "$SHARED_DIR/configs/variables" ]; then
  # shellcheck source=/dev/null
  . "$SHARED_DIR"/configs/variables
fi

cd "$DRUPAL_HOME"/sites/all/modules || exit

sudo drush cache-clear drush
sudo drush -v videojs-plugin
sudo drush -v pdfjs-plugin
sudo drush -v iabookreader-plugin
sudo drush -v colorbox-plugin
sudo drush -v openseadragon-plugin
sudo drush -v -y en islandora_openseadragon

# After last drush call from root user, change cache permissions
sudo chown -R vagrant:vagrant "$HOME_DIR"/.drush

# Install plupload library v1 
cd "$DRUPAL_HOME"/sites/all/libraries || exit
curl -L -sS -o plupload.zip https://github.com/moxiecode/plupload/archive/v1.5.8.zip
unzip plupload.zip 
rm plupload.zip 
mv plupload-* plupload 
sudo chown -R vagrant:www-data "$DRUPAL_HOME"/sites/all/libraries

# Install fits-0.6.2
cd /tmp || exit
curl -sS -o fits.zip http://projects.iq.harvard.edu/files/fits/files/fits-0.6.2.zip
cd /opt || exit
sudo unzip "/tmp/fits.zip"
sudo chown -R vagrant:www-data /opt/fits-0.6.2
