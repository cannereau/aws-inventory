source config.sh

# init report file
echo -e "Initiating report file..."
echo -e "Zone\tDivision\tAccount\tRegion\tTable\tBytes\tReadCapacity\tWriteCapacity" > "$REPORT_PATH/dynamodb.txt"

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
        # retrieve dynamodb tables
        echo -e "'${account_profiles[$id]}' in '$region' : listing tables..."
        for db in `aws dynamodb list-tables \
                            --query 'TableNames[]' \
                            --profile ${account_profiles[$id]} \
                            --region $region \
                            --output text`
        do
            table=$(tr -dc '[[:print:]]' <<< "$db")
            echo -e "... $table"
            aws dynamodb describe-table \
                --table-name=$table \
                --query "[\`${account_zones[$id]}\`, \`${account_divisions[$id]}\`, \`${account_names[$id]}\`, \`$region\`, \`$table\`, Table.TableSizeBytes, Table.ProvisionedThroughput.[ReadCapacityUnits] | [0], Table.ProvisionedThroughput.[WriteCapacityUnits] | [0]]" \
                --profile ${account_profiles[$id]} \
                --region $region \
                --output text >> "$REPORT_PATH/dynamodb.txt"
        done
    done
done
