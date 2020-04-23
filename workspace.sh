source config.sh

# init report file
echo -e "Initiating report file..."
echo -e "Zone\tDivision\tAccount\tRegion\tWorkspaceID\tComputerName\tType\tMode\tHoursUsed" > "$REPORT_PATH/workspace.txt"

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
done
