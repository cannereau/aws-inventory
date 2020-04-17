source config.sh

# init report file
echo -e "Initiating report file..."
echo -e "Zone\tDivision\tAccount\tRegion\tVolumeID\tType\tState\tSize\tIops" > "$REPORT_PATH/ebs.txt"

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
        # retrieve volumes
        echo -e "'${account_profiles[$id]}' in '$region' : listing volumes..."
        aws ec2 describe-volumes \
            --query "Volumes[*].[\`${account_zones[$id]}\`, \`${account_divisions[$id]}\`, \`${account_names[$id]}\`, \`$region\`, VolumeId, VolumeType, State, Size, Iops]" \
            --profile ${account_profiles[$id]} \
            --region $region \
            --output text >> "$REPORT_PATH/ebs.txt"
    done
done
