source constant.sh

# init profiles arrays
declare -A account_names
declare -A account_zones
declare -A account_profiles
declare -A account_divisions

# init report file
echo -e "Initiating report file..."
echo -e "Zone\tDivision\tAccount\tRegion\tCluster\tContainers\tTasks\tServices" > "$REPORT_PATH/ecs.txt"

id="903887953052"
region="us-east-1"
account_names[$id]="L'Oreal AMERICAS - AWS"
account_zones[$id]="AMER"
account_profiles[$id]="legacy_amer"
account_divisions[$id]="AMERICAS"

# loop through accounts
echo -e "Retrieving data..."

        # retrieve clusters
        echo -e "'${account_profiles[$id]}' in '$region' : listing clusters ecs..."
        for cluster in `aws ecs list-clusters \
                            --query "clusterArns[*]" \
                            --profile ${account_profiles[$id]} \
                            --region $region \
                            --output text`
        do
            # retrieve details
            #echo "+++$cluster###"
            #ecs=$(tr -dc '[[:print:]]' <<< "$cluster")
            ecs=${cluster}
            echo "... $ecs"
            aws ecs describe-clusters \
                --cluster $ecs \
                --query "clusters[0].[\`${account_zones[$id]}\`, \`${account_divisions[$id]}\`, \`${account_names[$id]}\`, \`$region\`, clusterName, registeredContainerInstancesCount, runningTasksCount, activeServicesCount]" \
                --profile ${account_profiles[$id]} \
                --region $region \
                --output text >> "$REPORT_PATH/ecs.txt"
        done
