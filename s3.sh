source config.sh

# init report file
echo -e "Initiating report file..."
echo -e "Zone\tDivision\tAccount\tRegion\tBucket\tStandardFA\tStandardIA\tIntelligentFA\tIntelligentIA\tOneZoneIA\tRRS\tGlacier\tDeepArchive" > "$REPORT_PATH/s3.txt"

# loop through accounts
echo -e "Retrieving data..."
for id in "${!account_names[@]}"
do
    # retrieve buckets
    echo -e "'${account_profiles[$id]}' : listing buckets..."
    for storage in `aws s3api list-buckets \
                        --query "Buckets[*].[Name]" \
                        --profile ${account_profiles[$id]} \
                        --output text`
    do
        bucket=$(tr -dc '[[:print:]]' <<< "$storage")

        # retrieve region
        echo "... $bucket"
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
