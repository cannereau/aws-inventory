source config.sh

# init report file
echo -e "Initiating report file..."
echo -e "Zone\tDivision\tAccount\tRegion\tFunction\tRuntime\tCodeSize" > "$REPORT_PATH/lambda.txt"

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
        # retrieve lambdas
        echo -e "'${account_profiles[$id]}' in '$region' : listing lambdas..."
        aws lambda list-functions \
            --query "Functions[*].[\`${account_zones[$id]}\`, \`${account_divisions[$id]}\`, \`${account_names[$id]}\`, \`$region\`, FunctionName, Runtime, CodeSize]" \
            --profile ${account_profiles[$id]} \
            --region $region \
            --output text >> "$REPORT_PATH/lambda.txt"
    done
done
