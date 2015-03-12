#!/usr/bin/env bash

OPENLDAP_DESTINATION="$CURRENT_SUBVOL/openldap"

BACKUP_OPENLDAP_USER=${BACKUP_OPENLDAP_USER:-admin}
BACKUP_OPENLDAP_PASSWORD=${BACKUP_OPENLDAP_PASSWORD:-}

BACKUP_OPENLDAP_CONFIG_USER=${BACKUP_OPENLDAP_CONFIG_USER:-admin}
BACKUP_OPENLDAP_CONFIG_PASSWORD=${BACKUP_OPENLDAP_CONFIG_PASSWORD:-}

if [[ ${BACKUP_OPENLDAP_HOST+defined} = defined ]]; then
    if [ ! -d "$OPENLDAP_DESTINATION" ]; then
        mkdir -p "$OPENLDAP_DESTINATION"
    fi

    if [[ ${BACKUP_OPENLDAP_DOMAIN+defined} = defined ]]; then
        orig_IFS=$IFS

        IFS="."
        declare -a dc_parts=($BACKUP_OPENLDAP_DOMAIN)

        IFS=$orig_IFS

        dc_string=""

        for dc_part in "${dc_parts[@]}"; do
            dc_string="$dc_string,dc=$dc_part"
        done

        basedn_string="${dc_string:1}"

        user_string="cn=$BACKUP_OPENLDAP_USER,$basedn_string"

        eval "ldapsearch -LLL -z none -l none -h $BACKUP_OPENLDAP_HOST -b '$basedn_string' -D '$user_string' -w '$BACKUP_OPENLDAP_PASSWORD' > $OPENLDAP_DESTINATION/data.ldif"
    fi

    if [[ ${BACKUP_OPENLDAP_CONFIG+defined} = defined ]]; then
        config_user_string="cn=$BACKUP_OPENLDAP_CONFIG_USER,cn=config"

        eval "ldapsearch -LLL -z none -l none -h $BACKUP_OPENLDAP_HOST -b 'cn=config' -D '$config_user_string' -w '$BACKUP_OPENLDAP_CONFIG_PASSWORD' > $OPENLDAP_DESTINATION/config.ldif"
    fi
else
    rm -rf "$OPENLDAP_DESTINATION"
fi
