for mount in $mounts; do
    source=$(echo "$mount" | jq -r '.Source')
    destination=$(echo "$mount" | jq -r '.Destination')
    echo " - Volume $source:$destination"
    echo $container_mounts_borg_prefix$destination
    echo $(find $source | wc -l)
#    borg create ::$(echo $container_mounts_borg_prefix$destination | sed 's/:/::/g' | sed 's/\//:/g'):$(date -Iseconds) /host$source
done
