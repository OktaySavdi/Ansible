#!/bin/bash

###############################################################
##  Name:  Oktay SAVDI
##  Date:  30.07.2024
##  Call:  ./azure_disks_public_access_sendmail.sh
###############################################################

# Set the output file
output_dir="/home/repos/Azure_Disks/"
email_subject="[ Warning ] Azure Disk Public Access Alert"
cc_recipient="TEAM_Security@mydomain.com"
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

# Define an array to store subscription IDs and owner email addresses
subscriptions=(
            "SUBSCRIPTION_NAME_1:team1@mydomain.com,team2@mydomain.comm"
            "SUBSCRIPTION_NAME_2:team1@mydomain.com,team2@mydomain.comm"
            "SUBSCRIPTION_NAME_3:team1@mydomain.com,team2@mydomain.comm"
            #"SUBSCRIPTION_NAME_3:owner3@example.com"
        )

# Function to create a report file for a subscription
create_report_file() {
    local subscription_id=$1
    local owner_email=$2

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    local report_file="$output_dir/${subscription_name}_publicly_disks_enabled.txt"
    
    # Query for Azure Disk Public Access
    disk_access_query=$(az disk list --subscription "$subscription_id" --query '[].{Name:name, ResourceGroup:resourceGroup, PublicAccess:publicNetworkAccess}' --output json)
    
    # Filter the query result for disks with Public Access enabled
    filtered_disks=$(echo "$disk_access_query" | jq -c '.[] | select(.PublicAccess == "Enabled")')
    
    echo "*****************************  $(date +'%d-%m-%Y') Azure Disks with Public Access Enabled  *****************************" > $report_file

    # Loop through each resource
    echo "$filtered_disks" | while IFS= read -r resource; do          
          name=$(echo "$resource" | jq -r '.Name')
          ResourceGroup=$(echo "$resource" | jq -r '.ResourceGroup')
      
          echo "[WARNING] Subscription: $subscription_name | RG: $ResourceGroup | Disk: $name | Disk Public Access: Enabled" >> $report_file
    done
        
    # Send email notification if report file is not empty
    send_email "$owner_email" "$report_file"

    # Remove report file after sending email
    # rm -rf "$report_file"
}

# Function to send an email with the report attached
send_email() {
    local recipient=$1
    local report_file=$2
 
    # Check if the report file is empty
    if grep -q "\[WARNING\]" "$report_file"; then
       # Send email with attachment using mail command
       echo -e "$BODY" | mail -s "$email_subject" -c "$cc_recipient" -a "$report_file" "$recipient"
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
