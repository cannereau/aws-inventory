source config.sh

# init report files
echo -e "Initiating report files..."
echo -e "Zone\tDivision\tAccount\tRegion\tTable\tBytes\tReadCapacity\tWriteCapacity" > "$REPORT_PATH/dynamodb.txt"
echo -e "Zone\tDivision\tAccount\tRegion\tVolumeID\tType\tState\tSize\tIops" > "$REPORT_PATH/ebs.txt"
echo -e "Zone\tDivision\tAccount\tRegion\tInstanceID\tType\tState\tName\tPlatform\tApplication\tEnvironment" > "$REPORT_PATH/ec2_instance.txt"
echo -e "Zone\tDivision\tAccount\tRegion\tReservedID\tType\tCount\tOffering\tFixedPrice\tRecurringCharges\tEnd" > "$REPORT_PATH/ec2_ri.txt"
echo -e "Zone\tDivision\tAccount\tRegion\tInstanceID\tType\tState\tEngine\tMultiAZ\tStorage\tSize\tIops\tApplication\tEnvironnement" > "$REPORT_PATH/rds_instance.txt"
echo -e "Zone\tDivision\tAccount\tRegion\tInstanceID\tType\tMultiAZ\tOffering\tFixedPrice\tStartTime\tDuration\tRecurringCharges" > "$REPORT_PATH/rds_ri.txt"
echo -e "Zone\tDivision\tAccount\tRegion\tBucket\tStandardFA\tStandardIA\tIntelligentFA\tIntelligentIA\tOneZoneIA\tRRS\tGlacier\tDeepArchive" > "$REPORT_PATH/s3.txt"
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

        # retrieve volumes
        echo -e "'${account_profiles[$id]}' in '$region' : listing volumes..."
        aws ec2 describe-volumes \
            --query "Volumes[*].[\`${account_zones[$id]}\`, \`${account_divisions[$id]}\`, \`${account_names[$id]}\`, \`$region\`, VolumeId, VolumeType, State, Size, Iops]" \
            --profile ${account_profiles[$id]} \
            --region $region \
            --output text >> "$REPORT_PATH/ebs.txt"

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

            echo -e "... $dbid"
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

        # retrieve snapshots
        echo -e "'${account_profiles[$id]}' in '$region' : listing snapshots older than $SNAP_LIMIT..."
        aws ec2 describe-snapshots \
            --owner-ids $id \
            --query "Snapshots[?StartTime<'$SNAP_LIMIT'].[\`${account_zones[$id]}\`, \`${account_divisions[$id]}\`, \`${account_names[$id]}\`, \`$region\`, SnapshotId, StartTime, VolumeId, VolumeSize]" \
            --profile ${account_profiles[$id]} \
            --region $region \
            --output text >> "$REPORT_PATH/snapshot.txt"

        # workspaces IS NOT GA
        if [ "$region" != "eu-north-1" ] && [ "$region" != "eu-west-3" ] && [ "$region" != "ap-south-1" ] && [ "$region" != "ap-east-1" ] \
            && [ "$region" != "us-east-2" ] && [ "$region" != "us-west-1" ] && [ "$region" != "me-south-1" ]
        then

            # retrieve workspaces list
            echo -e "'${account_profiles[$id]}' in '$region' : listing workspaces..."
            ws_json=$(aws workspaces describe-workspaces \
                            --profile ${account_profiles[$id]} \
                            --region $region \
                            --output json)
            ws_nb=$(echo $ws_json | jq -r '.Workspaces | length')

            # retrieve workspaces usage
            for (( i=0; i<ws_nb; i++ ))
            do
                wsid=$(echo $ws_json | jq -r --argjson i $i '.Workspaces[$i].WorkspaceId')
                name=$(echo $ws_json | jq -r --argjson i $i '.Workspaces[$i].ComputerName')
                type=$(echo $ws_json | jq -r --argjson i $i '.Workspaces[$i].WorkspaceProperties.ComputeTypeName')
                mode=$(echo $ws_json | jq -r --argjson i $i '.Workspaces[$i].WorkspaceProperties.RunningMode')

                hours=0
                if [ "$mode" == "AUTO_STOP" ]
                then
                    for metric in `aws cloudwatch get-metric-statistics \
                                        --namespace AWS/WorkSpaces \
                                        --metric-name Stopped \
                                        --start-time $DATE_BEGIN \
                                        --end-time $DATE_END \
                                        --period 3600 \
                                        --statistics Minimum \
                                        --dimensions "Name=WorkspaceId,Value=$wsid" \
                                        --query "Datapoints[*].[Minimum]" \
                                        --profile ${account_profiles[$id]} \
                                        --region $region \
                                        --output text`
                    do
                        if [ ${metric%?} == "0.0" ]
                        then
                            (( hours++ ))
                        fi
                    done
                elif [ "$mode" == "ALWAYS_ON" ]
                then
                    for metric in `aws cloudwatch get-metric-statistics \
                                        --namespace AWS/WorkSpaces \
                                        --metric-name UserConnected \
                                        --start-time $DATE_BEGIN \
                                        --end-time $DATE_END \
                                        --period 3600 \
                                        --statistics Maximum \
                                        --dimensions "Name=WorkspaceId,Value=$wsid" \
                                        --query "Datapoints[*].[Maximum]" \
                                        --profile ${account_profiles[$id]} \
                                        --region $region \
                                        --output text`
                    do
                        if [ ${metric%?} == "1.0" ]
                        then
                            (( hours++ ))
                        fi
                    done
                fi

                echo -e "... $wsid"
                echo -e "${account_zones[$id]}\t${account_divisions[$id]}\t${account_names[$id]}\t$region\t$wsid\t$name\t$type\t$mode\t$hours" >> "$REPORT_PATH/workspace.txt"

            done

        fi
    done

    # retrieve buckets
    echo -e "'${account_profiles[$id]}' : listing buckets..."
    for storage in `aws s3api list-buckets \
                        --query "Buckets[*].[Name]" \
                        --profile ${account_profiles[$id]} \
                        --output text`
    do
        bucket=$(tr -dc '[[:print:]]' <<< "$storage")

        # retrieve region
        echo -e "... $bucket"
        location=$(aws s3api get-bucket-location \
                        --bucket "$bucket" \
                        --profile ${account_profiles[$id]} \
                        --output text)
        if [ -z "$location" ] || [ "$location" == "None" ]
        then
            location="us-east-1"
        fi

        # retrieve metrics
        sed "s/#S3#/$bucket/g" s3ref.json > s3.json
        sc_json=$(aws cloudwatch get-metric-data \
                        --cli-input-json file://s3.json \
                        --start-time $DATE_BEGIN \
                        --end-time $DATE_END \
                        --profile ${account_profiles[$id]} \
                        --region $location \
                        --output json)
        
        standardFA=$(echo $sc_json | jq -r '.MetricDataResults[] | select(.Id == "standardFA") | .Values[0]')
        standardIA=$(echo $sc_json | jq -r '.MetricDataResults[] | select(.Id == "standardIA") | .Values[0]')
        intelligentFA=$(echo $sc_json | jq -r '.MetricDataResults[] | select(.Id == "intelligentFA") | .Values[0]')
        intelligentIA=$(echo $sc_json | jq -r '.MetricDataResults[] | select(.Id == "intelligentIA") | .Values[0]')
        onezoneIA=$(echo $sc_json | jq -r '.MetricDataResults[] | select(.Id == "onezoneIA") | .Values[0]')
        rrs=$(echo $sc_json | jq -r '.MetricDataResults[] | select(.Id == "rrs") | .Values[0]')
        glacier=$(echo $sc_json | jq -r '.MetricDataResults[] | select(.Id == "glacier") | .Values[0]')
        deeparchive=$(echo $sc_json | jq -r '.MetricDataResults[] | select(.Id == "deeparchive") | .Values[0]')

        # build output
        echo -e "${account_zones[$id]}\t${account_divisions[$id]}\t${account_names[$id]}\t$location\t$bucket\t$standardFA\t$standardIA\t$intelligentFA\t$intelligentIA\t$onezoneIA\t$rrs\t$glacier\t$deeparchive"  >> "$REPORT_PATH/s3.txt"
    done

done
