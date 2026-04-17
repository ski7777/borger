# iterate over the mounts and create a borg backup for each of them
for mount in $(echo $mounts | base64 -d | jq -c '.[]'); do
    source=$(echo "$mount" | jq -r '.Source')
    destination=$(echo "$mount" | jq -r '.Destination')
    echo " - Volume $source:$destination"
    echo $container_mounts_borg_prefix$destination
    borg create ::$(echo $container_mounts_borg_prefix$destination | sed 's/:/::/g' | sed 's/\//:/g'):$(date -Iseconds) $destination
done
