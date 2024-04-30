#!/bin/bash

###############################################################
##  Name:  Oktay SAVDI
##  Date:  10.06.2024
##  Call:  ./tkg_orphan_resources_reports.sh
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
Hybrid Cloud Engineering Team
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
    local report_file="$output_dir/${cluster_name}_unused_resources.txt"


    case "${env}" in
        test)
            export KUBECTL_VSPHERE_PASSWORD=$tkc_stg_pass
            kubectl-vsphere login --server=$tkc_stg_server --vsphere-username=$tkc_stg_username --tanzu-kubernetes-cluster-namespace=$supervisor_namespace --tanzu-kubernetes-cluster-name=$cluster_name --insecure-skip-tls-verify > /dev/null 2>&1
            kubectx $cluster_name

            # Check if the output contains more than just the header
            kor daemonset,deployment,horizontalpodautoscaler,ingress,job,persistentvolume,persistentvolumeclaim,pod,poddisruptionbudget,service,serviceaccount,statefulset --exclude-namespaces kube-node-lease,kube-public,kube-system,tanzu-package-repo-global,tanzu-system,tkg-system,vmware-system-auth,vmware-system-cloud-provider,vmware-system-csi,vmware-system-tkg,vmware-system-tmc,vmware-system-antrea,istio-system,istio-system-infra,istio-operator --exclude-labels istio.io/config=true | tail -n +8 > $report_file

            # Send email notification
            send_email "$owner_email" "$report_file"
            rm -rf $report_file
        ;;
        prod)
            export KUBECTL_VSPHERE_PASSWORD=$tkc_prod_pass
            kubectl-vsphere login --server=$tkc_prod_server --vsphere-username=$tkc_prod_username --tanzu-kubernetes-cluster-namespace=$supervisor_namespace --tanzu-kubernetes-cluster-name=$cluster_name --insecure-skip-tls-verify > /dev/null 2>&1
            kubectx $cluster_name

            # Check if the output contains more than just the header
            kor daemonset,deployment,horizontalpodautoscaler,ingress,job,persistentvolume,persistentvolumeclaim,pod,poddisruptionbudget,service,serviceaccount,statefulset --exclude-namespaces kube-node-lease,kube-public,kube-system,tanzu-package-repo-global,tanzu-system,tkg-system,vmware-system-auth,vmware-system-cloud-provider,vmware-system-csi,vmware-system-tkg,vmware-system-tmc,vmware-system-antrea,istio-system,istio-system-infra,istio-operator --exclude-labels istio.io/config=true | tail -n +8 > $report_file

            # Send email notification
            send_email "$owner_email" "$report_file"
            rm -rf $report_file
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
    
    # Check if the report file is empty
    if grep -q "Unused" "$report_file"; then
        # Send email with attachment using mail command
        echo -e "$BODY" | mail -s "$email_subject" -a "$report_file" "$recipient"
    fi
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
