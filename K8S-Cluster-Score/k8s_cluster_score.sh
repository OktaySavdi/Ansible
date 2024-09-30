#!/bin/bash

###############################################################
##  Name:  Oktay SAVDI
##  Date:  01.10.2024
##  Call:  ./k8s_cluster_score.sh
###############################################################

# Set the output file
output_dir="/opt/repos/K8S_Cluster_Score"
email_subject="Action Required for Kubernetes Cluster Configuration"
BODY=$(cat <<EOF
Dear Team,

We hope this message finds you well.

Our recent automation checks have evaluated the configurations of the Kubernetes cluster(s) associated with your services. 
We have identified that the average score of the cluster has fallen below the acceptable threshold of 95%.

This indicates that there are missing or incorrect configurations that need immediate attention to ensure that the cluster meets production standards.

Action Required: Please review the attached document detailing the identified issues and take the necessary steps to rectify them at your earliest convenience. 
If you have any questions or need assistance in resolving these issues, feel free to reach out to us.

Ensuring that your Kubernetes cluster operates efficiently and securely is critical for the success of our production environment.
Thank you for your prompt attention to this matter.

Best regards,
Engineering Team
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

       local report_file="$output_dir/${cluster_name}_cluster_score.txt"

        # Run the command to get AKS admin credentials
        # Redirect stdout and stderr to a temporary file
        az aks get-credentials --resource-group "$resourceGroupName" --name "$cluster_name" --overwrite-existing --admin
        
        # Check the exit code of the command
        exit_code=$?
    
        # Check score of cluster
        score=$(kubectl api-resources --verbs=list --namespaced -o name \
             | grep -v cronjobs.batch \
             | xargs -n1 -I{} bash -c "kubectl get {} --all-namespaces -oyaml && echo ---" \
             | /usr/local/bin/polaris audit --config /opt/repos/K8S_Cluster_Score/custom_check.yaml  --format score 2>/dev/null)
        
        if [[ "$score" -lt 95 ]]; then
           echo -e "\nYour Cluster Score : $score\n" > $report_file
   
           kubectl api-resources --verbs=list --namespaced -o name \
             | grep -v cronjobs.batch \
             | xargs -n1 -I{} bash -c "kubectl get {} --all-namespaces --field-selector metadata.namespace!=kube-system,metadata.namespace!=kube-public,metadata.namespace!=default,metadata.namespace!=kube-node-lease,metadata.namespace!=argocd,metadata.namespace!=tanzu-package-repo-global,metadata.namespace!=tanzu-system,metadata.namespace!=vmware-system-auth,metadata.namespace!=vmware-system-cloud-provider,metadata.namespace!=vmware-system-csi,metadata.namespace!=vmware-system-tmc,metadata.namespace!=kubernetes-dashboard,metadata.namespace!=velero,metadata.namespace!=gatekeeper-system,metadata.namespace!=flux-system,metadata.namespace!=nginx-ingress,metadata.namespace!=monitoring -oyaml && echo ---" \
             | kube-score score --output-format ci - | grep -v [OK] >> $report_file
   
           echo -e "\nProcedure : https://confluence/pages/Kubernetes+Security+Best+Practices+Part+1" >> $report_file
   
           # Send email notification
           send_email "$owner_email" "$report_file"
           rm -rf $report_file
        fi
    done
}


# Function to send an email with the report attached
send_email() {
    local recipient=$1
    local report_file=$2
    
    # Check if the report file is empty
    if [[ -n "$report_file" ]]; then
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
