source constant.sh

# init report file
echo -e "Initiating report file..."
echo -e "Zone\tDivision\tAccount Name\tAccount ID\tEmail\tStatus\tCountry\tProject\tApplication\tOwner\tCostCenter\tEnvironment\tBrand\tProfile\tDate" > "$REPORT_PATH/account.txt"

# retrieve account list
account_json=$(aws organizations list-accounts \
                    --query "Accounts[*].[Id, Name, Email, Status, JoinedTimestamp]" \
                    --profile $ROOT_PROFILE \
                    --output json)
account_nb=$(echo $account_json | jq -r '. | length')

# retrieve account tags
echo -e "Browsing accounts..."
for (( i=0; i<account_nb; i++ ))
do
    id=$(echo $account_json | jq -r --argjson i $i '.[$i][0]')
    name=$(echo $account_json | jq -r --argjson i $i '.[$i][1]')
    email=$(echo $account_json | jq -r --argjson i $i '.[$i][2]')
    status=$(echo $account_json | jq -r --argjson i $i '.[$i][3]')
    created=$(echo $account_json | jq -r --argjson i $i '.[$i][4]' | cut -c1-10)

    echo "... $id : $name"
    tags_json=$(aws organizations list-tags-for-resource \
                    --resource-id $id \
                    --profile $ROOT_PROFILE \
                    --output json)

    application=$(echo $tags_json | jq -r '.Tags[] | select(.Key == "Application") | .Value')
    owner=$(echo $tags_json | jq -r '.Tags[] | select(.Key == "AppOwner") | .Value')
    brand=$(echo $tags_json | jq -r '.Tags[] | select(.Key == "Brand") | .Value')
    cost=$(echo $tags_json | jq -r '.Tags[] | select(.Key == "CostCenter") | .Value')
    country=$(echo $tags_json | jq -r '.Tags[] | select(.Key == "Country") | .Value')
    division=$(echo $tags_json | jq -r '.Tags[] | select(.Key == "Division") | .Value')
    environ=$(echo $tags_json | jq -r '.Tags[] | select(.Key == "Environment") | .Value')
    prof=$(echo $tags_json | jq -r '.Tags[] | select(.Key == "Profile") | .Value')
    project=$(echo $tags_json | jq -r '.Tags[] | select(.Key == "Project") | .Value')
    zone=$(echo $tags_json | jq -r '.Tags[] | select(.Key == "RegionBU") | .Value')

    echo -e "$zone\t$division\t$name\t$id\t$email\t$status\t$country\t$project\t$application\t$owner\t$cost\t$environ\t$brand\t$prof\t$created" >> "$REPORT_PATH/account.txt"
done
