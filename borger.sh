# break lock if env var BORGER_BREAK_LOCK has any value
if [ -n "$BORGER_BREAK_LOCK" ]; then
    borg break-lock
fi

function backup_job_cmd() {
    echo docker run \
        --mount type=bind,src=$BORGER_SSH_DIR,dst=/root/.ssh,ro \
        --mount type=bind,src=$BORGER_CACHE_DIR,dst=/root/.cache/borg \
        --mount type=bind,src=$BORGER_PASSPHRASE_FILE,dst=/root/borg-passphrase.txt,ro \
        --env BORG_REPO=$BORG_REPO \
        --env BORG_PASSCOMMAND=\"cat /root/borg-passphrase.txt\" \
        --rm
}

function backup_job_image(){
    local image_flavour=$1
    echo "ghcr.io/ski7777/borger:latest-$image_flavour"
}

function run_backup_job_volumes(){
    local container_id=$1
    local mounts=$2
    local container_mounts_borg_prefix=$3
    local cmd=$(echo $(backup_job_cmd) \
        --volumes-from $container_id:ro \
        --env mounts=$mounts \
        --env container_mounts_borg_prefix=$container_mounts_borg_prefix \
        $(backup_job_image volumes) \
    )
    eval "$cmd"
}

container_ids=$(docker ps -a --filter "label=$BORGER_LABEL_NAMESPACE.enable" --format "{{.ID}}")
for container_id in $container_ids; do
    container_name=$(docker inspect -f '{{.Name}}' "$container_id" | sed 's/^\///')
    container_borg_prefix=/container/$container_name
    echo "Backing-up container: $container_name ($container_id)"

    if docker inspect --format '{{ json .Config.Labels }}' "$container_name" | jq -e "has(\"$BORGER_LABEL_NAMESPACE.volumes.omit\")" >/dev/null; then
        echo " - Ommiting volumes"
    else
        # Retrieve mounts
        mounts=$(docker inspect -f '{{json .Mounts}}' "$container_id" | base64 -w 0)
        container_mounts_borg_prefix=$container_borg_prefix/mounts
        run_backup_job_volumes $container_id $mounts $container_mounts_borg_prefix
    fi
    
    pg_dbs=$(docker inspect -f '{{index .Config.Labels "$BORGER_LABEL_NAMESPACE.postgres.databases"}}' "$container_id"| sed "s/,/ /g")
    pg_dbs_borg_prefix=$container_borg_prefix/postgres
    pg_user=$(docker exec -t "$container_id" bash -c 'echo "$POSTGRES_USER"')
    for db in $pg_dbs; do
        echo " - Postgres database $db"
        echo $pg_dbs_borg_prefix/$db
        docker exec -t $container_id pg_dump -c -U $pg_user $db | borg create ::$(echo $pg_dbs_borg_prefix/$db | sed 's/:/::/g' | sed 's/\//:/g'):$(date -Iseconds) -
    done

    echo "---------------------------------------------"
done

# show borg info unless BORGER_SUPPRESS_INFO has any value
if [ -z "$BORGER_SUPPRESS_INFO" ]; then
    $(backup_job_cmd) $(backup_job_image base) borg info
fi
