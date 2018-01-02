#!/bin/bash

SHARED_DIR=$1
if [ -f "$SHARED_DIR/configs/variables" ]; then
  . "$SHARED_DIR"/configs/variables
fi

# Install features to enforce djatoka url setting, among other things
cd "$DRUPAL_HOME"/sites/all/modules || exit
git clone https://github.com/umlts-labs/islandora_vagrant_features.git -b blazegraph-7.x-1.10
drush @sites -y -u 1 en islandora_vagrant_features features
drush @sites -y -u 1 fr islandora_vagrant_features

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

# Setup a user for Tomcat Manager
sed -i '$i<role rolename="admin-gui"/>' /etc/tomcat7/tomcat-users.xml
sed -i '$i<user username="islandora" password="islandora" roles="manager-gui,admin-gui"/>' /etc/tomcat7/tomcat-users.xml
service tomcat7 restart

# Set correct permissions on sites/default/files
chmod -R 775 /var/www/drupal/sites/default/files

# Update Drupal and friends to something recent

drush --root=/var/www/drupal -v -y pm-update

# Allow anonymous & authenticated users to view repository objects
drush --root=/var/www/drupal role-add-perm "anonymous user" "view fedora repository objects"
drush --root=/var/www/drupal role-add-perm "authenticated user" "view fedora repository objects"
drush --root=/var/www/drupal cc all

# Lets brand this a bit
cat <<'EOT' >> /home/vagrant/.bashrc
echo '   __________   ___   _  _____  ____  ___  ___     '
echo '  /  _/ __/ /  / _ | / |/ / _ \/ __ \/ _ \/ _ |    '
echo ' _/ /_\ \/ /__/ __ |/    / // / /_/ / , _/ __ |    '
echo '/___/___/____/_/ |_/_/|_/____/\____/_/|_/_/ |_| '
echo ''
echo ' ____              ___      ______ '
echo '/_  /__ __  ____  <  /     <  / _ \'
echo ' / _ \ \ / /___/  / / _    / / // /'
echo '/_(_/_\_\        /_/ (_)  /_/\___/ '
echo ''
echo '                                               `,,:;..+.+:;+                                        '
echo '                                            ;+.+.#.#+++#@#+.+.                                      '
echo '                                        .;++...++....+++++###.++:                                   '
echo '                                   `++++##++######++.+.+++.+++####+.                                '
echo '                                 :++++#@;:.:;..+.####+#++++++++++#+++++.+#+##+#+..`                 '
echo '                              +++++.+.;++##@@@+..;+;..+.+++++#.++..+++.+###########++               '
echo '                          ``.+....+;++++++++###++@@.;+..+.+...+.#.......+++++#######++#+.           '
echo '                         .++++.+:;#.;..;+++#####;:.@@#++;......+++..;........++++#####+#@##         '
echo '                       ,;+#.....+.;;;.+++#+###@###@#@###..;;.+.+++#++#++.....++++++@#########.      '
echo '                      :++.....++.#;+.;;;;...++++##++##+++++.++++...+++##+....++++#+++#########:     '
echo '                    .++......++.+#.+;;;;...;;...+++++.;;;;...+++..+.++##+..+++++++#++#+######+      '
echo '                  .#+#+....++....#.@;;;:;;;.;....##..;;;..++++.++++......++++++##+####+#@+:,;:      '
echo '               `,+++...;.;.;+++++#++;;;;;:;;;....;;;;;.............++++++++#++###+#+#.;`,,,,:       '
echo '             ,++#+.....++;...@+##+.;;;;;;;;.;;;;;;;................+.+++++++++@@;;:,`,,;,::         '
echo '        ..##+++....++..+....;+###+;;:;;;;;.;;;;;.;..++++##@.;@.@@@+:.:, `;;,.; ,,.,: .:..           '
echo ',:;+##########++...;......;...;.+.;;;;;;;;;;;;;...++@##@.@@#@;@@@@;`,`   :,`,.; `;                  '
echo '#########+++.+....+;;.+++..;..;;+..+..;;;;;.....+#@#+++++@@@@+#@@@+                                 '
echo '++#+++##++...;.;.+#.;;.#+....+.;++++;....+.+++##@+++++++#@@@@@+@@@@:                                '
echo '++++++++++..;;;;;;.@.;;.#+.;..+..+@+#..;.;...+#++++++++++@@@#@+#@@@@@@#+,                           '
echo '++.+++++++.;;;;;;;.+++;;.#.;..++.+#@+#...;;;....+####+##++###@#+##++.++##+;                         '
echo '....++++++.;;;;;;;.+++;;.++..#+##+##@+......;...;.;;;;;....#@@.:###++...+#++.:;                     '
echo '....+++++#.;;;;;;;.#+++.;.#+.#++@.:;.##++++..........;;;;........+###+++.+#++..;,: :                '
echo '......+++#.+..;;;...++#..+++++##.+:@.;.@#+++..+.+..+....;...........++++#+++#+##...,;`              '
echo '.......++#++..;;.;;..+#+#++@##++.;...#.;.+++++........................+#::;#++....#..;:.,,`         '
echo '......++++#+...;....+##+#+#.+..+;;;..;..+.+++++..+......................+#.;@,@:++####+.,.,::       '
echo '.......++.++....+++++..++.+.;;..;;:;..;....;@##+++....+...........++......++#..#,;@,@:@:@;#,#.      '
echo '+.......+++++.......++++;+;;;:;.:.;;.+.+..+++;,#+++++..++++..+.+.++++..........+#+++++.+.+#@##`     '
echo '++........+++......++++.;;.;;::..:.;..#.++;      ,@##+############++#+####+++++++++#########@#,     '
echo '............+.+...++++++.;;+;::..;;+++++@+;          `.::,,:;::,...,:.+##+...###++######@@##@.      '
echo '...+++.............+++#.:::.+.;:+;;.+++##;                                      ;@######@#+.        '
echo '......+.............+++@.;;:.+#.:+...+@#                                                            '
echo '......+..............++.;+##+.++..+++#;                                                             '
echo '+.....+..;;;;;...+...:;..;;...+...##.                                                               '
echo '+..+..+.+...;;...++.::::;;;+.++;+##                                                                 '
echo '++.;;;;;;+.;;;..+.#+.+;::+....#;++.                                                                 '
echo ':::;;:;.+.;;...+##+#++...;;;.;+;#+,                                                                 '
echo ';;::;.#.++..++###++#.++..;;.....+.                                                                  '
echo '...+#.....+++###+...;+.;.;;.++.+#                                                                   '
echo '.+#.....+#+#@#+......;.+..+.+++                                                                     '
echo '++..+++#+@#++.+++...++++.+##@##,                                                                    '
echo '.+#+;..:,.#++.++++++++@@: `#@++++#.`                                                                '
echo '++++@..+.,.###++++###`       ;+#;@+.                                                                '
echo '+++++##..#..#@####.           :.#`                                                                  '
echo '########@..#++`               .++;                                                                  '
echo '...;::,.` ;+.+++#:             #.                                                                   '
echo '           `;+@#+++++.+#                                                                            '
echo '               ,#+#.`                                                                               '
echo '                 :@+....+,                                                                          '
EOT

# Install fcrepo3-security-jaas -- filter-drupal.xml installed earlier in provisioning
cp -v -- "${SHARED_DIR}/configs/fcrepo3-security-jaas/jaas.conf" /usr/local/fedora/server/config/jaas.conf
cp -v -- "${SHARED_DIR}/configs/fcrepo3-security-jaas/security.xml" /usr/local/fedora/server/config/spring/web/security.xml
cp -v -- "${SHARED_DIR}/configs/fcrepo3-security-jaas/fcrepo3-security-jaas-0.0.3-fcrepo3.8.1.jar" /var/lib/tomcat7/webapps/fedora/WEB-INF/lib/.
cd "${DRUPAL_HOME}"/sites/all/modules || exit
git clone https://github.com/discoverygarden/islandora_repository_connection_config
drush @sites -y -u 1 en islandora_repository_connection_config
sites_arr=( default lso merlin mu umkc umkclaw umkcscholar umsl ) 
for i in "${sites_arr[@]}"
do
	cd "$DRUPAL_HOME/sites/${i}"
	drush eval "variable_set("islandora_repository_connection_config", array("cookies" => TRUE, "verifyHost" => TRUE, "verifyPeer" => TRUE, "timeout" => NULL, "connectTimeout" => "5", "userAgent" => "${i}_key", "reuseConnection" => TRUE, "debug" => FALSE))" 
done

# Install configuration for multithread fedoragsearch updaters. 
cp -v -- "${SHARED_DIR}/configs/multithread_config/fedora.fcfg" /usr/local/fedora/server/config/fedora.fcfg
cp -v -- "${SHARED_DIR}/configs/multithread_config/fedoragsearch.properties" /var/lib/tomcat7/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/fedoragsearch.properties
rm -rf /var/lib/tomcat7/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/updater && \
	cp -Rv "${SHARED_DIR}/configs/multithread_config/updater" /var/lib/tomcat7/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/.

chown -R tomcat7:tomcat7 "/var/lib/tomcat7"
chown -R tomcat7:tomcat7 "/usr/local/fedora/server"
service tomcat7 restart
