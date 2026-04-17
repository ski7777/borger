# break lock if env var BORGER_BREAK_LOCK has any value
if [ -n "$BORGER_BREAK_LOCK" ]; then
    borg break-lock
fi

function backup_job_cmd() {
    local container_id=$1
    local image_flavour=$2
    echo docker run \
        --volumes-from $container_id:ro \
        --mount type=bind,src=$BORGER_SSH_DIR,dst=/root/.ssh,ro \
        --mount type=bind,src=$BORGER_CACHE_DIR,dst=/root/.cache/borg \
        --mount type=bind,src=$BORGER_PASSPHRASE_FILE,dst=/root/borg-passphrase.txt,ro \
        --env BORG_REPO=$BORG_REPO \
        --env BORG_PASSCOMMAND=\"cat /root/borg-passphrase.txt\" \
        --env mounts=$(echo $mounts| base64 -w 0) \
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
    $(backup_job_cmd $container_id volumes) \
        --env mounts=$mounts \
        --env container_mounts_borg_prefix=$container_mounts_borg_prefix \
        $(backup_job_image volumes)
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

    echo "---------------------------------------------"
done

# show borg info unless BORGER_SUPPRESS_INFO has any value
if [ -z "$BORGER_SUPPRESS_INFO" ]; then
    borg info
fi
