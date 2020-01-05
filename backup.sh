#!/usr/bin/env bash

set -e

DATE=`date +'%F_%H:%M'`

BACKUP_ROOTS=()

config_check() {
    echo -n "Running config check ... "
    
    if [[ ! ${BACKUP_ROOT+defined} = defined ]]; then
        echo "[Backup] Mandatory BACKUP_ROOT not set" >&2
        exit 1
    fi

    if [[ ! ${BACKUP_PROJECT+defined} = defined ]]; then
        echo "[Backup] Mandatory BACKUP_PROJECT not set" >&2
        exit 1
    fi

    IFS=":"; declare -a potential_backup_roots=($BACKUP_ROOT); unset IFS

    for root in "${potential_backup_roots[@]}"; do
        if [ -d "$root" ]; then
            BACKUP_ROOTS+=($root)
        fi
    done
    
    if [ "${#BACKUP_ROOTS[@]}" -lt "1" ]; then
        echo "[Backup] No existing BACKUP_ROOT set" >&2
        exit 1
    fi
    
    echo "OK"
}

run() {
    for root in "${BACKUP_ROOTS[@]}"; do
        echo -n "Running backup to ${root} ... "

        PROJECT_ROOT="$root/$BACKUP_PROJECT"

        CURRENT_SUBVOL="$PROJECT_ROOT/current"

        SNAPSHOT_SUBVOL="$PROJECT_ROOT/$DATE"

        check
   
        init

        run_backup_modules
    
        snapshot

        cleanup    
        
        echo "OK"
    done
}

check() {
    if [ -d "$CURRENT_SUBVOL" ]; then
        if [ `stat --format=%i "$CURRENT_SUBVOL"` != 256 ]; then
            echo "[Backup] Directory '$CURRENT_SUBVOL' needs to be a BTRFS subvolume" >&2
            exit 1
        fi
    fi

    if [ -d "$SNAPSHOT_SUBVOL" ]; then
        echo "[Backup] Snapshot of this minute already exists" >&2
        exit 1
    fi
}

init() {
    if [ ! -d "$PROJECT_ROOT" ]; then
        mkdir -p "$PROJECT_ROOT"
    fi

    if [ ! -d "$CURRENT_SUBVOL" ]; then
        btrfs subvolume create "$CURRENT_SUBVOL" >/dev/null
    fi
}

run_backup_modules() {
    DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

    for file in $DIR/backup.d/*; do
        if [ -f "$file" ]; then
            . "$file"
        fi
    done
}

snapshot() {
    if [ "$(ls -A $CURRENT_SUBVOL)" ]; then
        btrfs subvolume snapshot -r "$CURRENT_SUBVOL" "$SNAPSHOT_SUBVOL" >/dev/null
    else
        echo "[Backup] Warning: Nothing to backup ... configuration wrong?" >&2
    fi
}

cleanup() {

    all_snapshots_raw=(`btrfs subvolume list $BACKUP_ROOT | grep "$BACKUP_PROJECT/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9]\{2\}:[0-9]\{2\}$" | cut -d "/" -f 2`)

    all_snapshots_asc=($(printf '%s\n' "${all_snapshots_raw[@]##*/}" | sort))
    all_snapshots=($(printf '%s\n' "${all_snapshots_raw[@]##*/}" | sort -r))

    snapshots_to_keep=()

    # Keep 12 latest snapshots

    snapshots_to_keep+=(${all_snapshots[@]:0:12})

    # Keep 12 latest daily snapshots

    for i in {0..11}; do
        date=`date --date="now -$i days" +'%F_'`

        for snapshot in ${all_snapshots_asc[@]}; do
            if [[ "$snapshot" == "$date"* ]]; then
                snapshots_to_keep+=($snapshot)
                break
            fi
        done
    done

    # Keep 12 latest monthly snapshots

    for i in {0..11}; do
        date=`date --date="now -$i month" +'%Y-%m'`

        for snapshot in ${all_snapshots_asc[@]}; do
            if [[ "$snapshot" == "$date"* ]]; then
                snapshots_to_keep+=($snapshot)
                break
            fi
        done
    done

    # Keep all yearly snapshots

    last_year=0

    for snapshot in ${all_snapshots_asc[@]}; do
        current_year=${snapshot:0:4}
        if [ "$current_year" -gt "$last_year" ]; then
            snapshots_to_keep+=($snapshot)
            last_year=$current_year
        fi
    done

    snapshots_to_keep=($(printf '%s\n' "${snapshots_to_keep[@]}" | uniq))

    snapshots_to_delete=()

    for snapshot in ${all_snapshots[@]}; do

        keep=false

        for keep_snapshot in ${snapshots_to_keep[@]}; do
            if [ "$snapshot" = "$keep_snapshot" ]; then
                keep=true
                break
            fi
        done

        if ! $keep; then
            snapshots_to_delete+=($snapshot)
        fi
    done

    for snapshot in ${snapshots_to_delete[@]}; do
        btrfs subvolume delete "$PROJECT_ROOT/$snapshot" >/dev/null
    done
}

config_check

run
