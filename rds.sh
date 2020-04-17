source config.sh

# init report files
echo -e "Initiating report files..."
echo -e "Zone\tDivision\tAccount\tRegion\tInstanceID\tType\tState\tEngine\tMultiAZ\tStorage\tSize\tIops\tApplication\tEnvironnement" > "$REPORT_PATH/rds_instance.txt"
echo -e "Zone\tDivision\tAccount\tRegion\tInstanceID\tType\tMultiAZ\tOffering\tFixedPrice\tStartTime\tDuration\tRecurringCharges" > "$REPORT_PATH/rds_ri.txt"

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
        # retrieve rds list
        echo -e "'${account_profiles[$id]}' in '$region' : listing rds instances..."
        rds_json=$(aws rds describe-db-instances \
                        --query "DBInstances[*].[DBInstanceIdentifier, DBInstanceClass, DBInstanceStatus, Engine, MultiAZ, StorageType, AllocatedStorage, Iops]" \
                        --profile ${account_profiles[$id]} \
                        --region $region \
                        --output json)
        rds_nb=$(echo $rds_json | jq -r '. | length')

        # retrieve rds tags
        for (( i=0; i<rds_nb; i++ ))
        do
            dbid=$(echo $rds_json | jq -r --argjson i $i '.[$i][0]')
            class=$(echo $rds_json | jq -r --argjson i $i '.[$i][1]')
            status=$(echo $rds_json | jq -r --argjson i $i '.[$i][2]')
            engine=$(echo $rds_json | jq -r --argjson i $i '.[$i][3]')
            az=$(echo $rds_json | jq -r --argjson i $i '.[$i][4]')
            stype=$(echo $rds_json | jq -r --argjson i $i '.[$i][5]')
            alloc=$(echo $rds_json | jq -r --argjson i $i '.[$i][6]')
            iops=$(echo $rds_json | jq -r --argjson i $i '.[$i][7]')

            arn="arn:aws:rds:$region:$id:db:$dbid"
            tags_json=$(aws rds list-tags-for-resource \
                            --resource-name "$arn" \
                            --profile ${account_profiles[$id]} \
                            --region $region \
                            --output json)

            application=$(echo $tags_json | jq -r '.TagList[] | select(.Key == "Application") | .Value')
            environment=$(echo $tags_json | jq -r '.TagList[] | select(.Key == "Environment") | .Value')

            echo -e "${account_zones[$id]}\t${account_divisions[$id]}\t${account_names[$id]}\t$region\t$dbid\t$class\t$status\t$engine\t$az\t$stype\t$alloc\t$iops\t$application\t$environment" >> "$REPORT_PATH/rds_instance.txt"
        done

        # retrieve reserved rds instances
        echo -e "'${account_profiles[$id]}' in '$region' : listing rds reservations..."
        aws rds describe-reserved-db-instances \
            --query "ReservedDBInstances[*].[\`${account_zones[$id]}\`, \`${account_divisions[$id]}\`, \`${account_names[$id]}\`, \`$region\`, ReservedDBInstanceId, DBInstanceClass, MultiAZ, OfferingType, FixedPrice, StartTime, Duration, RecurringCharges[0].RecurringChargeAmount]" \
            --profile ${account_profiles[$id]} \
            --region $region \
            --output text >> "$REPORT_PATH/rds_ri.txt"

    done
done
