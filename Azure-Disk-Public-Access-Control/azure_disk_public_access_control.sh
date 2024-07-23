#!/bin/bash

###############################################################
##  Name:  Oktay SAVDI
##  Date:  30.05.2024
##  Call:  ./azure_disk_public_access_control.sh
###############################################################

# List of subscriptions to exclude from processing
exclude_lists=("Sandbox" "Subscription2")
owner_email="myteam@mydomain.com"
report_file="/home/Azure_Disks/disks_publicly_enabled.log"
email_subject="[ Warning ] Azure Disk Public Access Alert"
BODY=$(cat <<EOF
Hi,

We have identified Azure disks in your subscription with public access enabled. This poses a security risk and should be addressed immediately. 
Please take the necessary steps to restrict public access and ensure the protection of your data.

If you need assistance or have any questions, please reach out to the Cloud team for guidance on securing your resources.

Thank you for your prompt attention to this matter..

Best Regards,
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
    local subscription=$1
    local exempted_file="/home/Azure_Disks/exempted_resources.txt"

    # Check if the resource_id is in the exempted resources list
    if grep -qFx "$subscription" "$exempted_file"; then
        return 0  # Resource is exempted
    else
        return 1  # Resource is not exempted
    fi
}

log_message "*****************************  $(date +'%d-%m-%Y') Azure Disks with Public Access Enabled  *****************************"

# Function to create a report file for a subscription
create_report_file() {
    local subscription_id=$1
    local owner_email=$2

    # Get the subscription by ID
    local sub=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    for rg in $(az group list --subscription $sub --query '[].name' -o tsv); do
        for disk in $(az disk list --resource-group $rg --subscription $sub --query '[].name' -o tsv); do
            if ! is_resource_exempted "$sub"; then
              if [[ $(az disk show --name $disk --resource-group $rg --subscription $sub --query 'publicNetworkAccess' -o tsv | grep "Enabled") == "Enabled"  ]]; then
                 log_message "Subscription: $sub | RG: $rg | Disk: $disk | Disk Public Access: Enabled"
              fi
            fi
        done
    done 2> /dev/null
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
if grep -q "Subscription:" "$report_file"; then
    # Send email to the specific owner_email
    send_email "$owner_email" "$report_file"
fi
