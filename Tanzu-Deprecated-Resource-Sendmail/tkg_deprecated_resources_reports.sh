#!/bin/bash

###############################################################
##  Name:  Oktay SAVDI
##  Date:  10.06.2024
##  Call:  ./deprecated_resources_reports.sh
###############################################################

# Set the output file
output_dir="/opt/repos/Depracated_Resources_K8S/Reports_Folder"
email_subject="Deprecated Kubernetes APIs Found in Tanzu Kubernetes Cluster"
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

Clusters=(
            #env:supervisor_namespace:cluster_name:owner3@example.com
            #"prod:supervisor_namespace1:cluster_name1:myteam2@mymail.com,myteam2@mymail.com"
            #"test:supervisor_namespace2:cluster_name2:myteam2@mymail.com,myteam2@mymail.com"
            #"prod:supervisor_namespace3:cluster_name3:myteam2@mymail.com,myteam2@mymail.com"
            #"test:supervisor_namespace4:cluster_name4:myteam2@mymail.com,myteam2@mymail.com"
            #"prod:supervisor_namespace5:cluster_name5:myteam2@mymail.com,myteam2@mymail.com"
            #"prod:supervisor_namespace6:cluster_name6:myteam2@mymail.com,myteam2@mymail.com"
        )

# Function to create a report file for a subscription
create_report_file() {
    local env=$1
    local supervisor_namespace=$2
    local cluster_name=$3
    local owner_email=$4
    local report_file="$output_dir/${cluster_name}_deprecated_resources.txt"

    case "${env}" in
        test)
            export KUBECTL_VSPHERE_PASSWORD=$tkc_stg_pass
            kubectl-vsphere login --server=$tkc_stg_server --vsphere-username=$tkc_stg_username --tanzu-kubernetes-cluster-namespace=$supervisor_namespace --tanzu-kubernetes-cluster-name=$cluster_name --insecure-skip-tls-verify > /dev/null 2>&1
            kubectx $cluster_name
            
            # Check if the output contains more than just the header
            if [ $(kubent | grep -vE "vmware*|PodSecurityPolicy" | wc -l) -gt 4 ]
            then
                kubent | grep -vE "vmware*|PodSecurityPolicy" > $report_file

                # Send email notification
                send_email "$owner_email" "$report_file"
                rm -rf $report_file
            fi
        ;;
        prod)
            export KUBECTL_VSPHERE_PASSWORD=$tkc_prod_pass
            kubectl-vsphere login --server=$tkc_prod_server --vsphere-username=$tkc_prod_username --tanzu-kubernetes-cluster-namespace=$supervisor_namespace --tanzu-kubernetes-cluster-name=$cluster_name --insecure-skip-tls-verify > /dev/null 2>&1
            kubectx $cluster_name

             # Check if the output contains more than just the header
            if [ $(kubent | grep -vE "vmware*|PodSecurityPolicy" | wc -l) -gt 4 ]
            then
                kubent | grep -vE "vmware*|PodSecurityPolicy" > $report_file
             
                # Send email notification
                send_email "$owner_email" "$report_file"
                rm -rf $report_file
            fi
        ;;
        *)
            echo "default (none of above)"
        ;;
    esac
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

# Iterate through each cluster
for cluster in "${Clusters[@]}"
  do
      # Split the cluster string into individual parameters
      IFS=':' read -r -a cluster_params <<< "$cluster"
  
      # Extract parameters
      env="${cluster_params[0]}"
      supervisor_namespace="${cluster_params[1]}"
      cluster_name="${cluster_params[2]}"
      owner="${cluster_params[3]}"
  
  
      # Create a report file for the current subscription
      create_report_file "$env" "$supervisor_namespace" "$cluster_name" "$owner"
done
