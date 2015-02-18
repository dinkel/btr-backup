#!/usr/bin/env bash

MYSQL_DESTINATION="$CURRENT_SUBVOL/mysql"

BACKUP_MYSQL_USER=${BACKUP_MYSQL_USER:-root}

BACKUP_MYSQL_PASSWORD=${BACKUP_MYSQL_PASSWORD:-}

if [[ ${BACKUP_MYSQL_HOST+defined} = defined ]]; then
    if [ ! -d "$MYSQL_DESTINATION" ]; then
        mkdir -p "$MYSQL_DESTINATION"
    fi

    eval "mysqldump --host='$BACKUP_MYSQL_HOST' --user='$BACKUP_MYSQL_USER' --password='$BACKUP_MYSQL_PASSWORD' --all-databases --events --single-transaction > $MYSQL_DESTINATION/all.sql"

else
    rm -rf "$MYSQL_DESTINATION"
fi
