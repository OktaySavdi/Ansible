#!/bin/sh

###############################################################
##  Name:  Oktay SAVDI
##  Date:  01.04.2024
##  Call:  ./disk_access_changes.sh
###############################################################

# List of subscriptions to exclude from processing
exclude_lists=("subscription_name1" "subscription_name2" "subscription_name2")

# Create or overwrite the log file with a header
echo "********************* Public Disk General Report - $(date +'%Y-%m-%d') ******************" > "disk_access_changes.log"

az login --service-principal --username $username --password $password --tenant $tenant

# Function to log message with timestamp
log_message() {
  message="$1"
  timestamp=$(date +%Y-%m-%dT%H:%M:%S)
  echo "[$timestamp] $message" >> "/opt/mydir/disk_access_changes.log"
}

# Function to list public enabled disks for a given subscription
function list_public_enabled_disk() {
   local subscription_id=$1

   # Set the Azure subscription
   az account set --subscription=$subscription_id

   # List all disks with public access enabled for the subscription
   az disk list --subscription $subscription_id --query '[].{Name:name, ResourceGroup:resourceGroup, PublicAccess:publicNetworkAccess}' --output json | jq -r '.[] | select(.PublicAccess == "Enabled") | [.Name, .ResourceGroup] | @tsv' | while IFS=$'\t' read -r disk_name resource_group; do
      #convert a string to lower case in Bash
      disk_name=$(echo $disk_name | tr '[:upper:]' '[:lower:]')
      resource_group=$(echo $resource_group | tr '[:upper:]' '[:lower:]')
      disk_changes $disk_name $resource_group $subscription_id
   done
}

# Function to handle changes for a disk
function disk_changes () {
   local disk_name=$1
   local resource_group=$2
   local subscription_id=$3
   
   # Get the name of the subscription
   subscription_name=$(az account list --query "[?id=='$subscription_id'].name" -o tsv)

   # Get the 'managed by' information of the disk
   disk_managed_by=$(az disk show --name $disk_name -g $resource_group --query managedBy -o tsv)

   # Check if the disk is managed by a node pool, MC_ (Managed Cluster), or aks (Azure Kubernetes Service)
   if [[ $disk_managed_by == *"nodepool"*  || $disk_managed_by == *"MC_"* || $disk_managed_by == *"aks"* ]]; then
      # Extract VMSS name from the managed by field
      vmss_name=$(echo "$disk_managed_by" | sed 's/_[^_]*$//' | awk -F'/' '{print $NF}')
     
      # Get the subnet and vnet ID of the VMSS
      vnet_resource_group=$(az vmss show -g $resource_group -n $vmss_name --query 'virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].subnet.id' -o json | awk -F'/' '{print $(NF-6)}')
      
      # Log that public access is enabled for the disk
      log_message "[INFO] [$subscription_name] Public access enabled for disk: $disk_name" 
      
      # Check if the variable is not empty
      if [[ -n $vnet_resource_group ]]; then
         disk_id=$(az disk-access list -g $vnet_resource_group --query [].id -o tsv)
         
         # Disable public access for the disk
         az disk update --name $disk_name --resource-group $resource_group --network-access-policy AllowPrivate --disk-access $disk_id --public-network-access Disabled > /dev/null 2>&1

         # Log that public access is enabled for the disk
         log_message "[UPDATED] [$subscription_name] Public access disabled for disk: $disk_name disk-access: $(echo $disk_id | awk -F'/' '{print $NF}')"
      else
        # Log that public access is enabled for the disk
        log_message "[WARNING] [$subscription_name] Disk State is Unattached disk: $disk_name"     
      fi
   else      
      # If disk is managed by a VM, get the VM name and NIC ID
      vm_name=$(echo $disk_managed_by | awk -F'/' '{print $(NF)}')
      nic_id=$(az vm nic list -g $resource_group --vm-name $(echo $disk_managed_by | awk -F'/' '{print $(NF)}') --query [].id -o tsv)
      vnet_resource_group=$(az network nic show --ids $nic_id --query 'ipConfigurations[0].subnet.id' -o json | awk -F'/' '{print $(NF-6)}')
      
      log_message "[INFO] [$subscription_name] Public access enabled for disk: $disk_name"
      # Check if the variable is not empty
      if [[ -n $vnet_resource_group ]]; then
         disk_id=$(az disk-access list -g $vnet_resource_group --query [].id -o tsv)
         
         # Disable public access for the disk
         az disk update --name $disk_name --resource-group $resource_group --network-access-policy AllowPrivate --disk-access $disk_id --public-network-access Disabled > /dev/null 2>&1

         # Log that public access is enabled for the disk
         log_message "[UPDATED] [$subscription_name] Public access disabled for disk: $disk_name disk-access: $(echo $disk_id | awk -F'/' '{print $NF}')"
      else
        # Log that public access is enabled for the disk
        log_message "[WARNING] [$subscription_name] Disk State is Unattached disk: $disk_name"     
      fi    
   fi
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
      list_public_enabled_disk $subscription_id
   fi
done
