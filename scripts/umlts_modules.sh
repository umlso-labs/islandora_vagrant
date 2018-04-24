#!/bin/bash

echo "Installing all UMLTS modules, themes, and libraries"

SHARED_DIR=$1

if [ -f "$SHARED_DIR/configs/variables" ]; then
  # shellcheck source=/dev/null
  . "$SHARED_DIR"/configs/variables
fi

if [ -f "$SHARED_DIR/configs/umlts-variables" ]; then
  # shellcheck source=/dev/null
  . "$SHARED_DIR"/configs/umlts-variables
fi

# Clone UMLTS modules 7.x-1.11 branch
cd "$DRUPAL_HOME"/sites/all/modules || exit
while read -r LINE; do
  git clone -b 7.x-1.11 "$LINE"
done < "$SHARED_DIR"/configs/umlts-module-list.txt

# Clone UMLTS other modules default branch
cd "$DRUPAL_HOME"/sites/all/modules || exit
while read -r LINE; do
  git clone "$LINE"
done < "$SHARED_DIR"/configs/umlts-other-module-list.txt

# Clone UMLTS themes 7.x-1.11 branch
cd "$DRUPAL_HOME"/sites/all/themes|| exit
while read -r LINE; do
  git clone -b 7.x-1.11 "$LINE"
done < "$SHARED_DIR"/configs/umlts-theme-list.txt

# Download zen theme (required by umkc_theme) 
#drush -y dl zen-7.x-6.4
drush -y dl zen-7.x-5.6

# TODO: DO WE NEED THIS
cd "$DRUPAL_HOME"/sites/all/libraries || exit
git clone https://github.com/umlts/galleria
#git clone https://github.com/umlts/jodconverter-2.2.2
git clone https://github.com/umlts/jquery.cycle

# Put all contrib modules in contrib folder
mkdir -pm 775 "$DRUPAL_HOME"/sites/all/modules/contrib
cd "$DRUPAL_HOME"/sites/all/modules || exit
while read -r LINE; do
  mv "$LINE" contrib
done < "$SHARED_DIR"/configs/contrib-module-list-existing.txt
drush cc all

# Download other contrib modules
cd "$DRUPAL_HOME"/sites/all/modules/contrib || exit
while read -r LINE; do
  drush -y -u 1 dl "$LINE"
done < "$SHARED_DIR"/configs/contrib-module-list-new.txt

# Install plupload library v1 and glip 1.1
cd "$DRUPAL_HOME"/sites/all/libraries || exit
curl -L -sS -o plupload.zip https://github.com/moxiecode/plupload/archive/v1.5.8.zip
unzip -qq plupload.zip 
rm plupload.zip 
mv plupload-* plupload 
rm -rf plupload/examples
git clone git://github.com/halstead/glip.git
cd glip && git checkout 1.1
sudo chown -R vagrant:www-data "$DRUPAL_HOME"/sites/all/libraries

# Install fits-0.6.2
cd /tmp || exit
curl -sS -o fits.zip http://projects.iq.harvard.edu/files/fits/files/fits-0.6.2.zip
cd /opt || exit
sudo unzip -qq "/tmp/fits.zip"
sudo chown -R vagrant:www-data /opt/fits-0.6.2
sudo chmod ug+x /opt/fits-0.6.2/fits.sh
