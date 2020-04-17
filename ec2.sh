source config.sh

# init report files
echo -e "Initiating report files..."
echo -e "Zone\tDivision\tAccount\tRegion\tInstanceID\tType\tState\tName\tPlatform\tApplication\tEnvironment" > "$REPORT_PATH/ec2_instance.txt"
echo -e "Zone\tDivision\tAccount\tRegion\tReservedID\tType\tCount\tOffering\tFixedPrice\tRecurringCharges\tEnd" > "$REPORT_PATH/ec2_ri.txt"

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
        # retrieve VM instances
        echo -e "'${account_profiles[$id]}' in '$region' : listing ec2 instances..."
        aws ec2 describe-instances \
            --query "Reservations[*].Instances[*].[\`${account_zones[$id]}\`, \`${account_divisions[$id]}\`, \`${account_names[$id]}\`, \`$region\`, InstanceId, InstanceType, State.Name, KeyName, Platform, Tags[?Key==\`Application\`].Value | [0], Tags[?Key==\`Environment\`].Value | [0]]" \
            --profile ${account_profiles[$id]} \
            --region $region \
            --output text >> "$REPORT_PATH/ec2_instance.txt"

        # retrieve reserved instances
        echo -e "'${account_profiles[$id]}' in '$region' : listing ec2 reservations..."
        aws ec2 describe-reserved-instances \
            --filters Name=state,Values=active \
            --query "ReservedInstances[*].[\`${account_zones[$id]}\`, \`${account_divisions[$id]}\`, \`${account_names[$id]}\`, \`$region\`, ReservedInstancesId, InstanceType, InstanceCount, OfferingType, FixedPrice, RecurringCharges[0].Amount, End]" \
            --profile ${account_profiles[$id]} \
            --region $region \
            --output text >> "$REPORT_PATH/ec2_ri.txt"
    done
done
