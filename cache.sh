source config.sh

# init report file
echo -e "Initiating report file..."
echo -e "Zone\tDivision\tAccount\tRegion\tCluster\tType\tEngine\tNodes" > "$REPORT_PATH/cache.txt"

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
        # retrieve elasticaches
        echo -e "'${account_profiles[$id]}' in '$region' : listing elasticaches..."
        aws elasticache describe-cache-clusters \
            --query "CacheClusters[*].[\`${account_zones[$id]}\`, \`${account_divisions[$id]}\`, \`${account_names[$id]}\`, \`$region\`, CacheClusterId, CacheNodeType, Engine, NumCacheNodes]" \
            --profile ${account_profiles[$id]} \
            --region $region \
            --output text >> "$REPORT_PATH/cache.txt"
    done
done
