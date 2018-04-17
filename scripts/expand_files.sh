#!/bin/bash 
# Copy subdirectories of the files/ dir on dldev into the proper sites folders 

SHARED_DIR=$1
if [ -f "$SHARED_DIR/configs/variables" ]; then
  . "$SHARED_DIR"/configs/variables
fi

if [ -d "$SHARED_DIR/islandora_db_sync" ]; then 
	SOURCE_FILES="$SHARED_DIR/islandora_db_sync/files"
	SOURCE_PRIVATE="$SHARED_DIR/islandora_db_sync/private"
	DEST_DIR="/mnt/storage"
	
	# Make /mnt/storage if dne 
	if [ ! -d "$DEST_DIR" ]; then 
		mkdir -pm 770 "$DEST_DIR"
	fi
	
	# Copy public files to VM 
	if [ -d "$SOURCE_FILES" ]; then 
		cp -R "$SOURCE_FILES" "$DEST_DIR/files"
	fi
	
	# Copy private files to VM  
	if [ -d "$SOURCE_PRIVATE" ]; then 
		cp -R "$SOURCE_PRIVATE" "$DEST_DIR/private"
	fi
	
	# Enable backup_migrate for all sites 
	cd "$DRUPAL_HOME"
	drush @sites -y -u 1 en backup_migrate 

	sites_arr=( default lso merlin mu umkc umkcscholar umsl )
	for i in "${sites_arr[@]}" 
	do
		# Delete files directory if it already exists 
		FILES_DIR="$DRUPAL_HOME/sites/$i/files"
		if [ -d "$FILES_DIR" ]; then 
			rm -rf "$FILES_DIR"
		fi
		
		# Create symlink to new files directory 
		ln -sf "$DEST_DIR/files/$i" "$FILES_DIR"
		chown -R www-data:www-data "$FILES_DIR" 
				
		# Set private filesystem path 
		cd "$DRUPAL_HOME/sites/$i"
		drush vset --yes file_private_path "$DEST_DIR/private/$i" 
		
		# Run backup_migrate restore 	
		drush -y bam-restore db manual dldev-"$i".mysql
		
		# Set default admin login 
		drush user-password admin --password=islandora 
		
		# Set temporary files path 
		drush vset --yes file_temporary_path /tmp 
		
		# Set public files path 
		drush vset --yes file_public_path sites/"$i"/files
	done

	# Disable (ldap_servers, securelogin) for all sites 
	cd "$DRUPAL_HOME"
	drush @sites -y -u 1 dis ldap_servers securelogin 
	
	# Run updatedb on all sites 
	drush @sites vset --yes maintenance_mode 1 
	drush @sites -y -u 1 updatedb 
	drush @sites vset --yes maintenance_mode 0
fi

