#!/bin/bash

###############################################################
##  Name:  Oktay SAVDI
##  Date:  15.04.2024
##  Call:  ./azure_storageaccount_public_access_control.sh
###############################################################

# List of subscriptions to exclude from processing
exclude_lists=("subscrinption_1" "subscrinption_2" "subscrinption_3")
owner_email="mymail@gmail.com"
report_file="/opt/repos/Azure_StorageAccount/disk_access_changes.log"
email_subject="[ Warning ] Azure Storage Account Public Access Alert"
BODY=$(cat <<EOF
Hi,

We have identified Azure Storage Accounts in your subscription with public access enabled. This poses a security risk and should be addressed immediately. 
Please take the necessary steps to restrict public access and ensure the protection of your data.

If you need assistance or have any questions, please reach out to the Azure support team for guidance on securing your resources.

Thank you for your attention to this important issue.

Best Regards,
<My Team>
EOF
)

# Login Azure via SP
az login --service-principal --username $username --password $password --tenant $tenant

# Create an empty file with timestamp
echo -n "" > $report_file

# Function to log message with timestamp
log_message() {
  message="$1"
  timestamp=$(date +%Y-%m-%dT%H:%M:%S)
  echo "$message" >> $report_file
}

# Function to check if a resource is exempted
is_resource_exempted() {
    local resource_id=$1
    local exempted_file="/opt/repos/Azure_StorageAccount/exempted_resources.txt"

    # Check if the resource_id is in the exempted resources list
    if grep -qFx "$resource_id" "$exempted_file"; then
        return 0  # Resource is exempted
    else
        return 1  # Resource is not exempted
    fi
}

# Function to check if a storage account has public access enabled
is_publicly_accessible() {
    local account_name=$1
    local resource_group=$2
    local subscription_id=$3

    # Check if the storage account has public access enabled
    local public_access=$(az storage account show \
        --name "$account_name" \
        --subscription "$subscription_id" \
        --resource-group "$resource_group" \
        --query "networkRuleSet.defaultAction" \
        --output tsv)

    if [ "$public_access" == "Allow" ]; then
        return 0  # Public access is enabled
    else
        return 1  # Public access is not enabled
    fi
}

log_message "*****************************  $(date +'%d-%m-%Y') Azure Storage Accounts with Public Access Enabled  *****************************"

# Function to create a report file for a subscription
create_report_file() {
    local subscription_id=$1
    local owner_email=$2

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    # Get a list of all storage accounts
    storage_accounts=$(az storage account list --subscription $subscription_name --query "[].{Name:name, ResourceGroup:resourceGroup}" --output json)
        
    # Loop through each VM and check resource utilization
    for storage_account in $(echo "$storage_accounts" | jq -c '.[]'); do
        name=$(echo "$storage_account" | jq -r '.Name')
        resource_group=$(echo "$storage_account" | jq -r '.ResourceGroup')
        
        # Check for public access and send an email to the owner if found
        if is_publicly_accessible "$name" "$resource_group" "$subscription_id"; then
           # Check name if it's in exemption list
           if ! is_resource_exempted "$name"; then
              log_message "[WARNING] Subscription: $subscription_name | SA: $name | RG: $resource_group | Public Network: Allow"
           fi
        fi
    done  
}

# Function to send an email with the report attached
send_email() {
    local owner_email=$1
    local report_file=$2
 
    # Send email with attachment using mail command
    echo -e "$BODY" | mail -s "$email_subject" -a "$report_file" "$owner_email"
}

# Get all subscription IDs
subscription_ids=$(az account list --all --query '[].id' -o tsv)
for subscription_id in $subscription_ids; do
   # Get the name of the subscription
   subscription_name=$(az account list --query "[?id=='$subscription_id'].name" -o tsv)
   skip_subscription=false
   # Check if the subscription should be skipped based on exclude_lists
   for exclude_list in "${exclude_lists[@]}"; do
      if [[ "$subscription_name" == *"$exclude_list"* ]]; then
         skip_subscription=true
         break
      fi
   done
   # Process the subscription if it should not be skipped
   if [ "$skip_subscription" = false ]; then
      # Call the function to list public enabled disks for the subscription
      create_report_file $subscription_id
   fi
done

# Check if the report file is empty
if grep -q "\[WARNING\]" "$report_file"; then
    # Send email to the specific owner_email
    send_email "$owner_email" "$report_file"
fi
