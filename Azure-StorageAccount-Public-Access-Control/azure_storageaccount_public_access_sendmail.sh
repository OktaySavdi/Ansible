#!/bin/bash

###############################################################
##  Name:  Oktay SAVDI
##  Date:  15.04.2024
##  Call:  ./azure_storageaccount_public_access_sendmail.sh
###############################################################

# Set the output file
output_dir="/opt/repos/Azure-StorageAccount-Public-Access-Control"
email_subject="[ Warning ] Azure Storage Account Public Access Alert"
BODY=$(cat <<EOF
Hi,

We have identified Azure Storage Accounts in your subscription with public access enabled. This poses a security risk and should be addressed immediately. 
Please take the necessary steps to restrict public access and ensure the protection of your data.

If you need assistance or have any questions, please reach out to the Azure support team for guidance on securing your resources.

Thank you for your attention to this important issue.

Best Regards,
My Team
EOF
)

# Login Azure via SP
#az login --service-principal --username {{ username }} --password {{ password }} --tenant {{ tenant }}

# Define an array to store subscription IDs and owner email addresses
subscriptions=(
            "SUBSCRIPTION_NAME_1:team1@mydomain.com,team2@mydomain.comm"
            "SUBSCRIPTION_NAME_2:team1@mydomain.com,team2@mydomain.comm"
            "SUBSCRIPTION_NAME_3:team1@mydomain.com,team2@mydomain.comm"
            #"SUBSCRIPTION_NAME_3:owner3@example.com"
        )

# Function to check if a resource is exempted
is_resource_exempted() {
    local resource_id=$1
    local exempted_file="/opt/repos/Azure-StorageAccount-Public-Access-Control/exempted_resources.txt"

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

# Function to create a report file for a subscription
create_report_file() {
    local subscription_id=$1
    local owner_email=$2

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    # Get a list of all storage accounts
    storage_accounts=$(az storage account list --subscription $subscription_name --query "[].{Name:name, ResourceGroup:resourceGroup}" --output json)
    
    local report_file="$output_dir/${subscription_name}_storage_accounts.txt"
    echo "*****************************  $(date +'%d-%m-%Y') Azure Storage Accounts with Public Access Enabled  *****************************" > $report_file
    
    # Loop through each VM and check resource utilization
    for storage_account in $(echo "$storage_accounts" | jq -c '.[]'); do
        name=$(echo "$storage_account" | jq -r '.Name')
        resource_group=$(echo "$storage_account" | jq -r '.ResourceGroup')
        
        # Check for public access and send an email to the owner if found
        if is_publicly_accessible "$name" "$resource_group" "$subscription_id"; then
           # Check name if it's in exemption list
           if ! is_resource_exempted "$name"; then
              echo "[WARNING] Subscription: $subscription_name | SA: $name | RG: $resource_group | Public Network: Allow" >> $report_file
           fi
        fi
    done  
    # Send email notification if report file is not empty
    send_email "$owner_email" "$report_file"

    # Remove report file after sending email
    rm -rf "$report_file"
}

# Function to send an email with the report attached
send_email() {
    local recipient=$1
    local report_file=$2
 
    # Check if the report file is empty
    if grep -q "\[WARNING\]" "$report_file"; then
        # Send email with attachment using mail command
        echo -e "$BODY" | mail -s "$email_subject" -a "$report_file" "$recipient"
    fi
}

# Create the output directory
mkdir -p "$output_dir"

# If subscription ID is not provided, get all subscription IDs
for subscription_info in "${subscriptions[@]}"; do
    subscription_name="${subscription_info%%:*}"  # Extract the subscription ID
    owner_email="${subscription_info#*:}"       # Extract the owner email

    # Create a report file for the current subscription
    create_report_file "$subscription_name" "$owner_email"
done
