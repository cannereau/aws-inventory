source constant.sh

# init profiles arrays
declare -A account_names
declare -A account_zones
declare -A account_profiles
declare -A account_divisions

# init config file
echo -e "Initiating config file..."
echo -e "[profile $ROOT_PROFILE]" > ~/.aws/config.tmp
echo -e "region = eu-west-1" >> ~/.aws/config.tmp

# retrieve account list
account_json=$(aws organizations list-accounts \
                    --query "Accounts[*].[Id, Name, Status]" \
                    --profile $ROOT_PROFILE \
                    --output json)
account_nb=$(echo $account_json | jq -r '. | length')

# retrieve account tags
echo -e "Browsing accounts..."
for (( i=0; i<account_nb; i++ ))
do
    id=$(echo $account_json | jq -r --argjson i $i '.[$i][0]')
    status=$(echo $account_json | jq -r --argjson i $i '.[$i][2]')
    if [ "$status" == "ACTIVE" ] && [ "$id" != "128985509146" ]
    then
        account_tags=$(aws organizations list-tags-for-resource \
                            --resource-id $id \
                            --profile $ROOT_PROFILE \
                            --output json)
        account_names[$id]=$(echo $account_json | jq -r --argjson i $i '.[$i][1]')
        account_zones[$id]=$(echo $account_tags | jq -r '.Tags[] | select(.Key == "RegionBU") | .Value')
        account_profiles[$id]=$(echo $account_tags | jq -r '.Tags[] | select(.Key == "Profile") | .Value')
        account_divisions[$id]=$(echo $account_tags | jq -r '.Tags[] | select(.Key == "Division") | .Value')
        if [ ${account_profiles[$id]} != $ROOT_PROFILE ]
        then
            printf "...%3d : $id : ${account_names[$id]}\n" $i
            echo -e "[profile ${account_profiles[$id]}]" >> ~/.aws/config.tmp
            echo -e "source_profile = $ROOT_PROFILE" >> ~/.aws/config.tmp
            echo -e "role_arn = arn:aws:iam::$id:role/$ORG_ROLE" >> ~/.aws/config.tmp
        fi
    fi
done

# update config file
echo -e "Updating config file..."
bkp_file=$(date -r ~/.aws/config "+config_%Y%m%d.bkp")
mv ~/.aws/config ~/.aws/$bkp_file
mv ~/.aws/config.tmp ~/.aws/config
