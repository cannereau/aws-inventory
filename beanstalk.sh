source config.sh

# init report file
echo -e "Initiating report file..."
echo -e "Zone\tDivision\tAccount\tRegion\tApplication\tEnvironment" > "$REPORT_PATH/beanstalk.txt"

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
        # retrieve beanstalk environment
        echo -e "'${account_profiles[$id]}' in '$region' : listing beanstalk environments..."
        aws elasticbeanstalk describe-environments \
            --query "Environments[*].[\`${account_zones[$id]}\`, \`${account_divisions[$id]}\`, \`${account_names[$id]}\`, \`$region\`, ApplicationName, EnvironmentName]" \
            --profile ${account_profiles[$id]} \
            --region $region \
            --output text >> "$REPORT_PATH/beanstalk.txt"
    done
done
