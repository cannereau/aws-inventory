source config.sh

# init report file
echo -e "Initiating report file..."
echo -e "Zone\tDivision\tAccount\tRegion\tCluster\tContainers\tTasks\tServices" > "$REPORT_PATH/ecs.txt"

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
        # retrieve ecs clusters
        echo -e "'${account_profiles[$id]}' in '$region' : listing ecs clusters ..."
        for cluster in `aws ecs list-clusters \
                            --query "clusterArns[*]" \
                            --profile ${account_profiles[$id]} \
                            --region $region \
                            --output text`
        do
            # retrieve details
            echo "... $cluster"
            aws ecs describe-clusters \
                --cluster $cluster \
                --query "clusters[0].[\`${account_zones[$id]}\`, \`${account_divisions[$id]}\`, \`${account_names[$id]}\`, \`$region\`, clusterName, registeredContainerInstancesCount, runningTasksCount, activeServicesCount]" \
                --profile ${account_profiles[$id]} \
                --region $region \
                --output text >> "$REPORT_PATH/ecs.txt"
        done
    done
done
