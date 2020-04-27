# AWS Inventory

This project is a list of Bash script files to build AWS inventories through an accounts' organization

## Prerequisites
These scripts need 2 tools :
- [AWS CLI](https://docs.aws.amazon.com/fr_fr/cli/latest/userguide/cli-chap-welcome.html)
- [jq](https://stedolan.github.io/jq/)

An AWS CLI profile for the master account of the AWS organization must be registered using the command :

    aws configure --profile master

## Configuration
In the *constant.sh* file, several values must be configured :
- **ROOT_PROFILE** = name of the AWS CLI profile defined in prerequisites for the master account
- **ORG_ROLE** = name of the role assumed by the **ROOT_PROFILE** to discover each AWS account
- **REPORT_PATH** = folder path to store report files for each type of resource
- **DATE_BEGIN** and **DATE_END** = period used for CloudWatch metrics (eg S3 capacity)
- **SNAP_LIMIT** = date before which snapshots are considered as too old

## Usage
Each script can be run independently to retrieve a type of resource through the AWS organization

The script *_inv_finops.sh* aggregate some elementary scripts to FinOps purposes
The script *_inv_resources.sh* aggregate all elementary scripts to inventory purposes
