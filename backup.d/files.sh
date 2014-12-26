#!/usr/bin/env bash

FILES_DESTINATION="$CURRENT_SUBVOL/files"

if [[ ${BACKUP_FILES_PATHS+defined} = defined ]]; then
    if [ ! -d "$FILES_DESTINATION" ]; then
        mkdir -p "$FILES_DESTINATION"
    fi

    includes=""

    orig_IFS=$IFS
    IFS=:
    for path in $BACKUP_FILES_PATHS; do
        if [[ "$path" = /* ]]; then
            if [ -d "$path" ]; then
                includes="--include='${path/%\//}/***' $includes"

                subpath="${path/%\//}"

                while [ -d "$subpath" ]; do
                    includes="--include='${subpath}/' $includes"
                    subpath="${subpath%/*}"
                done

            else
                echo "[Backup - Files] Given path '$path' is not known" >&2
                exit 1
            fi
        else
            echo "[Backup - Files] Path '$path' is not absolute" >&2
            exit 1
        fi
    done
    IFS=$orig_IFS

    eval "rsync --archive --numeric-ids --inplace --relative --delete --delete-excluded $includes --exclude='*' / $FILES_DESTINATION"
else
    rm -rf "$FILES_DESTINATION"
fi
