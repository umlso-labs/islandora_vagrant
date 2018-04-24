#!/bin/bash 

echo "Copy UMLTS data to vm"

SHARED_DIR=$1
if [ -f "$SHARED_DIR/configs/variables" ]; then
  . "$SHARED_DIR"/configs/variables
fi

if [ -f "$SHARED_DIR/configs/umlts-variables" ]; then
  . "$SHARED_DIR"/configs/umlts-variables
fi

if [ ! -d "$SHARED_DIR/islandora_vagrant_db_sync" ]; then 
  echo "Missing islandora_vagrant_db_sync"
  exit
fi

# Make /mnt/storage if dne 
if [ ! -d "$UMLTS_DEST_DIR" ]; then 
  mkdir -pm 770 "$UMLTS_DEST_DIR"
fi

# Copy public files to VM 
if [ -d "$UMLTS_SOURCE_FILES" ]; then 
  cp -R "$UMLTS_SOURCE_FILES" "$UMLTS_DEST_DIR/files"
fi

# Copy private files to VM  
if [ -d "$UMLTS_SOURCE_PRIVATE" ]; then 
  cp -R "$UMLTS_SOURCE_PRIVATE" "$UMLTS_DEST_DIR/private"
fi
