source config.sh

# init report file
echo -e "Initiating report file..."
echo -e "Zone\tDivision\tAccount\tRegion\tSnapshotID\tDate\tVolumeID\tSize" > "$REPORT_PATH/snapshot.txt"

# loop through accounts
echo -e "Retrieving data..."
for id in "${!account_names[@]}"
do
    # loop through regions
    for region in `aws ec2 describe-regions \
                        --query 'Regions[].RegionName' \
                        --profile $ROOT_PROFILE \
                        --output text`
    do
        # retrieve snapshots
        echo -e "'${account_profiles[$id]}' in '$region' : listing snapshots older than $SNAP_LIMIT..."
        aws ec2 describe-snapshots \
            --owner-ids $id \
            --query "Snapshots[?StartTime<'$SNAP_LIMIT'].[\`${account_zones[$id]}\`, \`${account_divisions[$id]}\`, \`${account_names[$id]}\`, \`$region\`, SnapshotId, StartTime, VolumeId, VolumeSize]" \
            --profile ${account_profiles[$id]} \
            --region $region \
            --output text >> "$REPORT_PATH/snapshot.txt"
    done
done
