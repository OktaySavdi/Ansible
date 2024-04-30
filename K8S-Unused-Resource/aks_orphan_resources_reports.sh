#!/bin/bash

###############################################################
##  Name:  Oktay SAVDI
##  Date:  10.06.2024
##  Call:  ./aks_orphan_resources_reports.sh
###############################################################

# Set the output file
output_dir="/opt/repos/Unused_Resources_K8S"
email_subject="Unused Resources Detected in Kubernetes Clusters"
BODY=$(cat <<EOF
Dear Team,

We are writing to inform you that our automated monitoring system has detected unused resources in our Kubernetes clusters. 
Unused resources are those that are provisioned but have remained idle or inactive for an extended period, potentially indicating inefficiencies in resource allocation.

We kindly request your assistance in reviewing your configurations and identifying any resources that are no longer needed. 
Your cooperation will help us ensure efficient resource management across our Kubernetes clusters.

We will provide further updates as we progress with the optimization efforts. 
Should you have any questions or require assistance, please feel free to reach out to us.

Thank you for your attention to this matter.

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
        )

# Function to create a report file for a subscription
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

       local report_file="$output_dir/${cluster_name}_unused_resources.txt"

        # Run the command to get AKS admin credentials
        # Redirect stdout and stderr to a temporary file
        az aks get-credentials --resource-group "$resourceGroupName" --name "$cluster_name" --overwrite-existing --admin
        
        # Check the exit code of the command
        exit_code=$?
     
        # Check if the output contains more than just the header
        kor daemonset,deployment,horizontalpodautoscaler,ingress,job,persistentvolume,persistentvolumeclaim,pod,poddisruptionbudget,service,serviceaccount,statefulset --exclude-namespaces kube-node-lease,kube-public,kube-system,tanzu-package-repo-global,tanzu-system,tkg-system,vmware-system-auth,vmware-system-cloud-provider,vmware-system-csi,vmware-system-tkg,vmware-system-tmc,vmware-system-antrea,istio-system,istio-system-infra,istio-operator --exclude-labels istio.io/config=true | tail -n +8 > $report_file

        # Send email notification
        send_email "$owner_email" "$report_file"
        rm -rf $report_file
    done
}

# Function to send an email with the report attached
send_email() {
    local recipient=$1
    local report_file=$2
    
    # Check if the report file is empty
    if grep -q "Unused" "$report_file"; then
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
