#!/bin/bash

source /usr/lib/helper-func.sh

function show_help() {
    echo '#'
    echo "# Usage: $0 {start|stop|restart|update|backup|restore-backup <path>|help|-h}"
    echo '#'
    echo '# Commands:'
    echo '#   start             - Start the penpot containers using Docker Compose'
    echo '#   stop              - Stop and remove the penpot containers'
    echo '#   restart           - Restart the penpot containers'
    echo '#   update            - Pull the latest image for the penpot containers'
    echo '#   backup            - Copy all assets to host machine, create DB dump and add everything to a tarball in project dir.'
    echo '#   restore-backup </path/to/*-penpot.backup.tar>'     
    echo '                      - Specify the local tarball file created by the "export" command and recreate that state.'
    echo '#   help, -h          - Display this help message'
    echo '#'
    echo '    Note: For (restoring) backup, containers must be running'
    echo '#'
}

function validate_environment() {
    local dev_env='dev'
    local test_env='test'
    local ok_env_pattern="${dev_env}|${test_env}"
    if [ -z $PENPOT_ENV ]; then
        echo $(colorify "info: Empty runtime envvar \$PENPOT_ENV -> fallback to default environment 'dev'" ly)
        PENPOT_ENV=$dev_env
    elif echo "$PENPOT_ENV" | grep --silent -v -E "^($ok_env_pattern)$"; then
        throw "error: no support for configured environment '$PENPOT_ENV' (PENPOT_ENV failed pattern test /$ok_env_pattern/)."
    fi
    CONF_DIR="$(get_dir_of "$0")"
    CONF="$CONF_DIR/.env.$PENPOT_ENV"
    [ ! -f $CONF ] && throw "error: config '$CONF' not found in project directory."
}

function get_conf_val_by_key() {
    cat $CONF | grep $1 | cut -d'=' -f2- || throw "error: getting value of '$1' in '$CONF' failed."
}

function get_container_id_by_img_label() {
    image_id=$(get_conf_val_by_key $1)
    docker ps -q --filter "ancestor=$image_id" 2>/dev/null
}

function _backup_assets() {
    local host_artifacts_dir=$(get_conf_val_by_key 'ARTIFACTS_DIR')
    local backup_date="$(date +%H%M_%y%m%d)"
    local backup_dir="${CONF_DIR}/${host_artifacts_dir}/${backup_date}-penpot.backup"
    mkdir -p $backup_dir
    
    # frontend and backend containers share data volume, 
    local conf_key='BACKEND_IMG'
    local container_id=$(get_container_id_by_img_label $conf_key)
    [ -z $container_id ] && throw "error: couldn't find running container id for image $conf_key."

    local remote_assets_dir=$(get_conf_val_by_key 'ASSETS_DIR')
    [ -z $remote_assets_dir ] && throw "error: missing ASSETS_DIR key=value pair in $CONF."
    docker cp "$container_id:$remote_assets_dir" "$backup_dir"
    echo "Exported $container_id:$remote_assets_dir from image $conf_key to $backup_dir."

    #
    # db export
    #
    conf_key=POSTGRES_IMG
    container_id=$(get_container_id_by_img_label $conf_key)
    local db_user=$(get_conf_val_by_key 'POSTGRES_USER')
    local db_pass=$(get_conf_val_by_key 'POSTGRES_PASSWORD')
    local backup_file="${backup_date}_${conf_key}.sql"

    docker exec -e PGPASSWORD=$db_pass "$container_id" /usr/bin/bash -c "pg_dump -U $db_user -h $container_id penpot > /tmp/$backup_file"
    docker cp "$container_id:/tmp/$backup_file" "$backup_dir/"
    echo "Exported data in $container_id from image $conf_key to $backup_dir/$backup_file."

    # create a tarball of all exported files before deleting the created backup dir
    tar cf $backup_dir.tar -C $backup_dir .
    rm -rf "$backup_dir"

    echo $(colorify "Created backup at $backup_dir.tar" green)
}

function _restore_assets() {
    local tarball="$1"

    [ ! -f "$tarball" ] && throw "error: given archive path $tarball not a file."
    echo "$tarball" | grep -q ".*-penpot.backup.tar$" || throw "error: given archive path $tarball not a valid backup."

    local conf_key='BACKEND_IMG'
    local container_id=$(get_container_id_by_img_label $conf_key)
    [ -z $container_id ] && throw "error: couldn't find running container id for image $conf_key."

    # it first extracts the tarball before uploading the content to the respective containers
    # for a later step, esp. when compression is applied, either copy the tarball to the container and extract there
    # or use rsync
    local output_dir=$(realpath "$(dirname "$tarball")/$(basename "$tarball" .tar).extracted")
    tar -xf $tarball -C "$output_dir/"
    
    local remote_assets_dir=$(get_conf_val_by_key 'ASSETS_DIR')

    # cleaning state, deletes all assets first
    docker exec "$container_id" /usr/bin/bash -c "rm -rf $remote_assets_dir/"
    docker cp $output_dir/assets/. $container_id:$remote_assets_dir/
    # fixing ownership, breaks e.g. thumbnails otherwise
    docker exec -u root $container_id /usr/bin/bash -c "chown -R penpot:penpot $remote_assets_dir/"

    #
    # db import
    conf_key='POSTGRES_IMG'
    container_id=$(get_container_id_by_img_label $conf_key)
    local db_user=$(get_conf_val_by_key 'POSTGRES_USER')
    local db_name=$(get_conf_val_by_key 'POSTGRES_DB')
    remote_assets_dir=$(get_conf_val_by_key 'ASSETS_DIR')

    docker cp $output_dir/*_${conf_key}.sql $container_id:/tmp/imported_db.sql

    # kill all db connections
    docker exec "$container_id" /usr/bin/bash -c "psql -U $db_user -d postgres -c \"SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$db_name' AND pid <> pg_backend_pid();\""
    # setup fresh db
    docker exec "$container_id" /usr/bin/bash -c "psql -U $db_user -d postgres -c \"DROP DATABASE $db_name;\""
    docker exec "$container_id" /usr/bin/bash -c "psql -U $db_user -d postgres -c \"CREATE DATABASE $db_name;\""
    # restore data from file and delete dump
    docker exec "$container_id" /usr/bin/bash -c "psql --single-transaction -U $db_user $db_name < /tmp/imported_db.sql"
    docker exec "$container_id" /usr/bin/bash -c "rm -f /tmp/imported_db.sql"

    rm -rf $output_dir
    echo $(colorify "Backup restored." green)

}

function _start() {
    echo "Starting penpot containers..."
    docker compose -p penpot --env-file "$CONF" -f "$CONF_DIR/docker-compose.yaml" up -d
}

function _stop() {
    echo "Stopping penpot containers..."
    docker compose -p penpot --env-file "$CONF" -f "$CONF_DIR/docker-compose.yaml" down
}

function _update() {
    echo "Updating penpot containers..."
    docker compose --env-file "$CONF" -f "$CONF_DIR/docker-compose.yaml" pull
}

validate_environment
case "$1" in
    start)  _start                          ;;
    stop)   _stop                           ;;
    restart)
        _stop
        _start
        ;;
    update) _update                         ;;
    backup) _backup_assets                  ;;
    restore-backup)
        backup_tarball="$2"
        _restore_assets "$backup_tarball"
        ;;
    help|-h|--help) show_help               ;;
    *)  throw "error: Invalid argument."    ;;
esac
