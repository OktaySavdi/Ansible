#!/bin/bash

###############################################################
##  Name:  Oktay SAVDI
##  Date:  10.06.2024
##  Call:  ./aks_deprecated_resources_reports.sh
###############################################################

# Set the output file
output_dir="/opt/repos/Depracated_Resources_K8S"
email_subject="Deprecated Kubernetes APIs Found in Tanzu Kubernetes Cluster"
BODY=$(cat <<EOF
BODY=$(cat <<EOF
Hi,

We are writing to bring to your attention an important issue regarding the Kubernetes cluster under your responsibility.

Our automated system has detected the presence of deprecated APIs within the cluster. 
It is crucial to address these deprecated APIs promptly as they can lead to maintenance and upgrade failures, potentially causing disruptions to your services.

Attached to this email, you will find a detailed report outlining the deprecated APIs found and their respective recommendations for remediation. 
We kindly request that you review this report at your earliest convenience and take the necessary steps to update the affected resources.

If you require any assistance or further clarification on the identified issues, please do not hesitate to reach out to us. 
Ensuring the stability and security of our Kubernetes clusters is a top priority, and your swift action in this matter would be greatly appreciated.

Thank you for your attention to this important issue.

Best regards,
<My Team>
EOF
)

# Login Azure via SP
az login --service-principal --username $username --password $password --tenant $tenant

subscriptions=(
    "SUBSCRIPTION_NAME_1:team1@mydomain.com,team2@mydomain.comm"
    "SUBSCRIPTION_NAME_2:team1@mydomain.com,team2@mydomain.comm"
    "SUBSCRIPTION_NAME_3:team1@mydomain.com,team2@mydomain.comm"
    #"SUBSCRIPTION_NAME_3:owner3@example.com"
    #"SUBSCRIPTION_ID_3:owner3@example.com"
)

 Function to create a report file for a subscription
create_report_file() {
    local subscription_name=$1
    local owner_email=$2

    az account set --subscription $subscription_name

    #Disable the proxy
    unset https_proxy http_proxy no_proxy
    
    # Get the clusters by name and rg
    local clusters=$( az aks list --query "[].{name:name, ResourceGroup:resourceGroup}" --output json)

    # Loop through each Cluster and check resources
    for cluster in $(echo "$clusters" | jq -c '.[]'); do
       cluster_name=$(echo "$cluster" | jq -r '.name')
       resourceGroupName=$(echo "$cluster" | jq -r '.ResourceGroup')

        # Run the command to get AKS admin credentials
        # Redirect stdout and stderr to a temporary file
        az aks get-credentials --resource-group "$resourceGroupName" --name "$cluster_name" --overwrite-existing --admin
        
        # Check the exit code of the command
        exit_code=$?

        # If exit code is 0, credentials were obtained successfully
        if [ $exit_code -eq 0 ]; then            
            # Check if the output contains more than just the header
            if [ $(kubent | wc -l) -gt 4 ]
            then
                local report_file="$output_dir/${cluster_name}_deprecated_resources.txt"
     
                kubent > $report_file
                # Send email notification
                send_email "$owner_email" "$report_file"
                rm -rf $report_file
            fi
        fi
    done
}

# Function to send an email with the report attached
send_email() {
    local recipient=$1
    local report_file=$2

    # Send email with attachment using mail command
    echo -e "$BODY" | mail -s "$email_subject" -a "$report_file" "$recipient"
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
