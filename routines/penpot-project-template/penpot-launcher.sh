#!/bin/bash

source /usr/lib/helper-func.sh

function show_help() {
    echo '#'
    echo "# Usage: $0 {run|stop|restart|update|export|import <path>|help|-h}"
    echo '#'
    echo '# Commands:'
    echo '#   run         - Start the penpot containers using Docker Compose'
    echo '#   stop        - Stop and remove the penpot containers'
    echo '#   restart     - Restart the penpot containers'
    echo '#   update      - Pull the latest image for the penpot containers'
    echo '#   export      - Copy all assets to host machine, create DB dump and add everything to a tarball in project dir.'
    echo '#   import <*-penpot.backup.tar>'     
    echo '                - Specify the local tarball file created by the "export" command and recreate that state.'
    echo '#   help, -h    - Display this help message'
    echo '#'
    echo '    Note: For import/export, Containers must be running'
    echo '#'
}

function validate_environment() {
    local _DEV_ENV=dev
    local _TEST_ENV=test
    local OK_ENV_PATTERN="${_DEV_ENV}|${_TEST_ENV}"
    if [ -z $PENPOT_ENV ]; then
        echo "info: Empty runtime envvar \$PENPOT_ENV -> fallback to default environment 'dev'"
        PENPOT_ENV=dev
    elif echo "$PENPOT_ENV" | grep --silent -v -E "^($OK_ENV_PATTERN)$"; then
        throw "error: no support for configured environment '$PENPOT_ENV' (PENPOT_ENV failed pattern test /$OK_ENV_PATTERN/)."
    fi
    CONF=".env.$PENPOT_ENV"
    [ ! -f $CONF ] && throw "error: config '$CONF' not found in project directory."
}

function get_conf_val_by_key() {
    printf "$(cat $CONF | grep $1 | cut -d'=' -f2-)"
}

function get_container_id_by_img_label() {
    image_id=$(get_conf_val_by_key $1)
    echo $(docker ps -q --filter "ancestor=$image_id" 2>/dev/null)
}

function export_data() {
    local host_artifacts_dir=$(get_conf_val_by_key 'ARTIFACTS_DIR')
    local backup_date=$(date +%H%M_%y%m%d)
    local backup_dir=$host_artifacts_dir/$backup_date-penpot.backup
    mkdir -p $backup_dir
    
    # frontend and backend containers share data volume, 
    local conf_key='BACKEND_IMG'
    local container_id=$(get_container_id_by_img_label $conf_key)
    [ -z $container_id ] && throw "error: couldn't find running container id for image $conf_key"

    local remote_assets_dir=$(get_conf_val_by_key 'ASSETS_DIR')
    [ -z $remote_assets_dir ] && throw "missing ASSETS_DIR key=value pair in $CONF."
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
    #
    # ^TODO: validate retrieved aparms
    #
    docker exec -e PGPASSWORD=$db_pass "$container_id" /usr/bin/bash -c "pg_dump -U $db_user -h $container_id penpot > /tmp/$backup_file"
    docker cp "$container_id:/tmp/$backup_file" "$backup_dir/"
    echo "Exported data in $container_id from image $conf_key to $backup_dir/$backup_file."

    # create a tarball of all exported files before deleting the created backup dir
    tar cf $backup_dir.tar -C "$backup_dir" .
    rm -rf "$backup_dir"

}

function import_data() {
    local ARCHIVE=$1

    [ ! -f "$ARCHIVE" ] && throw "error: given archive path $ARCHIVE not a file"
    echo "$ARCHIVE" | grep -q ".*-penpot.backup.tar$" || throw "error: given archive path $ARCHIVE not a valid backup"

    local conf_key='BACKEND_IMG'
    local container_id=$(get_container_id_by_img_label $conf_key)
    [ -z $container_id ] && throw "error: couldn't find running container id for image $conf_key"
    
    

    # it first extracts thetarball before uploading the content to the respective containers
    # for a later step, esp. when compression is applied, either copy the tarball to the container and extract there
    # or use rsync
    local output_dir=$(realpath "$(dirname $ARCHIVE)/$(basename $ARCHIVE .tar).extracted")
    mkdir -p $output_dir
    tar -xf $ARCHIVE -C "$output_dir/"
    
    local remote_assets_dir=$(get_conf_val_by_key 'ASSETS_DIR')

    # cleaning state, deletes all assets first
    docker exec "$container_id" /usr/bin/bash -c "rm -rf $remote_assets_dir/"
    docker cp $output_dir/assets/. $container_id:$remote_assets_dir/
    # fixing ownership, breaks e.g. thumbnails if not done here
    docker exec -u root $container_id /usr/bin/bash -c "chown -R penpot:penpot $remote_assets_dir/"

    #
    # db import
    local conf_key='POSTGRES_IMG'
    local container_id=$(get_container_id_by_img_label $conf_key)
    local db_user=$(get_conf_val_by_key 'POSTGRES_USER')
    local db_name=$(get_conf_val_by_key 'POSTGRES_DB')
    local remote_assets_dir=$(get_conf_val_by_key 'ASSETS_DIR')
    #
    # ^TODO: validate retrieved aparms
    #

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
    echo "import done."

}

validate_environment
case "$1" in
    run)
        echo "Starting penpot containers..."
        docker compose -p penpot --env-file "$CONF" -f docker-compose.yaml up -d
        ;;
    stop)
        echo "Stopping penpot containers..."
        docker compose -p penpot --env-file "$CONF" -f docker-compose.yaml down
        ;;
    restart)
        echo "Restarting penpot containers..."
        docker compose restart penpot
        ;;
    update)
        echo "Updating penpot containers..."
        docker compose -f docker-compose.yaml pull
        ;;
    export)
        export_data
        ;;
    import)
        import_data "$2"
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo "Error: Invalid argument."
        show_help
        exit 1
        ;;
esac
