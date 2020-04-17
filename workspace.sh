source config.sh

# init report file
echo -e "Initiating report file..."
echo -e "Zone\tDivision\tAccount\tRegion\tWorkspaceID\tComputerName\tType\tMode" > "$REPORT_PATH/workspace.txt"

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
        # workspaces IS NOT GA
        if [ "$region" != "eu-north-1" ] && [ "$region" != "ap-south-1" ] && [ "$region" != "eu-west-3" ] && [ "$region" != "us-east-2" ] && [ "$region" != "us-west-1" ]
        then
            # retrieve workspaces
            echo -e "'${account_profiles[$id]}' in '$region' : listing workspaces..."
            aws workspaces describe-workspaces \
                --query "Workspaces[*].[\`${account_zones[$id]}\`, \`${account_divisions[$id]}\`, \`${account_names[$id]}\`, \`$region\`, WorkspaceId, ComputerName, WorkspaceProperties.ComputeTypeName, WorkspaceProperties.RunningMode]" \
                --profile ${account_profiles[$id]} \
                --region $region \
                --output text >> "$REPORT_PATH/workspace.txt"
        fi
    done
done
