#!/bin/bash

#set -x
#set -e

# Main function to call other functions based on the resource type
subscription_id=$1

# Array to track processed storage accounts for each subscription
declare -A processed_accounts
declare -A processed_subscriptions

az login --service-principal --username {{ username }} --password {{ password }} --tenant {{ tenant }}

# Set the output file
out_file="/opt/HCE/HCE_Azure_Resources_utilization/Azure_Resources_Utilization.txt"

# the title of the report
echo "*****************************************************************" > $out_file
echo "********************* General Resources Report ******************" >> $out_file
echo "*********************  $(date +'%d-%m-%Y')   *****************************" >> $out_file
echo "*****************************************************************" >> $out_file


# Function to find orphaned resources for a given resource type
find_orphaned_resources() {
    local resource_type=$1
    local query_expression=$2
    local subscription_id=$3

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    local orphaned_resources=($(az $resource_type list --subscription $subscription_id --query "$query_expression" --output tsv))

    if [ ${#orphaned_resources[@]} -gt 0 ]; then
        echo "[$subscription_name] - Orphaned $resource_type" >> $out_file
        for orphaned_resource in "${orphaned_resources[@]}"; do
            echo "$orphaned_resource" >> $out_file
        done
        echo "*****************************************************************" >> $out_file
    fi
}

# Function to find orphaned resources for a given resource type
find_orphaned_snapshot() {
    local resource_type=$1
    local query_expression=$2
    local subscription_id=$3
    local output_added=false

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    local orphaned_resources=($(az $resource_type list --subscription $subscription_id --query "$query_expression" --output tsv))

    if [ ${#orphaned_resources[@]} -gt 0 ]; then
        if [ "$output_added" = false ]; then
                echo "************************** Snapshots older than 7 days ************************" >> $out_file
                output_added=true
        fi
        echo "[$subscription_name] - Orphaned $resource_type" >> $out_file

        for orphaned_resource in "${orphaned_resources[@]}"; do
            echo "$orphaned_resource" >> $out_file
        done
        echo "*****************************************************************" >> $out_file
    fi
}

# Function to find orphaned Subnets
find_orphaned_subnets() {
    local subscription_id=$1
    local output_added=false

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    # Get a list of Subnets in the subscription
    local vnets=$(az network vnet list --subscription $subscription_id --query "[].{Name:name, ResourceGroup:resourceGroup}" --output json)

    # Loop through each  Subnets
    for vnet in $(echo "$vnets" | jq -c '.[]'); do
        vnet_name=$(echo $vnet | jq -r '.Name')
        resource_group=$(echo $vnet | jq -r '.ResourceGroup')

        local orphaned_subnets=($(az network vnet subnet list --subscription $subscription_id --vnet-name $vnet_name --resource-group $resource_group --query '[?ipConfigurations[0]==`null`].id' --output tsv))

        if [ ${#orphaned_subnets[@]} -gt 0 ]; then
           if [ "$output_added" = false ]; then
                echo "[$subscription_name] - Orphaned Subnets:" >> $out_file
                output_added=true
            fi            
            for subnet in "${orphaned_subnets[@]}"; do
                if [ -n "$subnet" ]; then
                    echo "$subnet" >> $out_file
                fi
            done
        fi
    done
    echo "*****************************************************************" >> $out_file
}

# Function to find orphaned Resource Groups
find_orphaned_resource_groups() {
    local subscription_id=$1

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    # Check each resource group for the presence of resources
    orphans_rg=()
    for rg in $(az group list --subscription $subscription_id --query "[].name" -o tsv); do
        resource_count=$(az resource list --resource-group $rg --subscription $subscription_id --query "length([])")
        if [ "$resource_count" -eq 0 ]; then
            orphans_rg+=("$rg")
        fi
    done

    if [ "${#orphans_rg[@]}" -gt 0 ]; then
        # Print orphaned resource groups
        echo "[$subscription_name] - Orphaned Resource Groups:" >> $out_file
        for orphan_rg in "${orphans_rg[@]}"; do
            echo "$orphan_rg" >> $out_file
        done
        echo "*****************************************************************" >> $out_file
    fi
}

check_vm_utilization() {
    local subscription_id=$1
    local output_added=false

    az account set --subscription=$subscription_id

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    # Get a list of all VMs in the subscription
    vms=$(az vm list --query "[].{Id:id, ResourceGroup:resourceGroup}" --output json)

    # Loop through each VM and check resource utilization
    for vm in $(echo "$vms" | jq -c '.[]'); do
        vmId=$(echo "$vm" | jq -r '.Id')
        resourceGroupName=$(echo "$vm" | jq -r '.ResourceGroup')

        # Get current date in UTC
        endDate=$(date -u +"%Y-%m-%dT%H:%MZ")

        # Calculate the start date as three months ago from the current date
        startDate=$(date -u -d '3 months ago' +"%Y-%m-%dT%H:%MZ")

        # Get CPU utilization for the last three months
        cpuUtilization=$(az monitor metrics list --resource "$vmId" --resource-group "$resourceGroupName" --start-time "$startDate" --end-time "$endDate" --interval 1d --metric "Percentage CPU" --query "value[].timeseries[].data[].average" --output tsv | awk '{s+=$1} END {print s/NR}')

        # Get memory utilization for the last three months
        memoryUtilization=$(az monitor metrics list --resource "$vmId" --resource-group "$resourceGroupName" --start-time "$startDate" --end-time "$endDate" --interval 1d --metric "Available Memory Bytes" --query "value[].timeseries[].data[].average" --output tsv | awk '{s+=$1} END {print s/NR}')

        # Check if the difference is over 40%
        if (( $(echo "$cpuUtilization < 30" | bc -l) )) || (( $(echo "$memoryUtilization < 40" | bc -l) )); then
           if [ "$output_added" = false ]; then
                echo "************************** VMs Performance (Last 3 Months) ************************" >> $out_file
                output_added=true
            fi
            echo -e "[$subscription_name] - [Percentage CPU] $cpuUtilization% and [Percentage Memory] $memoryUtilization%" >> $out_file
            echo -e "$vmId" >> $out_file
        fi
    done
    echo "*****************************************************************" >> $out_file
}

check_storage_accounts() {
    local subscription_id=$1
    az account set --subscription=$subscription_id

    # Get a list of storage accounts in the subscription
    storage_accounts=$(az storage account list --query '[].name' --output tsv)

    for storage_account in $storage_accounts; do
        account_key=$(timeout 60 az storage account keys list --account-name $storage_account --query '[0].value' --output tsv)
        check_storage_account $storage_account $account_key $subscription_id
    done
    echo "*****************************************************************" >> $out_file
}

check_storage_account() {
    local storage_account=$1
    local account_key=$2
    local subscription_id=$3

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    # Get a list of containers in the storage account
    containers=$(timeout 60 az storage container list --account-name $storage_account --account-key $account_key --query '[].name' --output tsv)

    for container in $containers; do
        total_size=$(timeout 60 az storage blob list --account-name $storage_account --container-name $container --account-key $account_key --query "[].properties.contentLength" --output tsv | paste -sd+ - | bc)
        total_size_gb=$(echo "scale=2; $total_size / (1024*1024*1024)" | bc)
        check_and_print $storage_account $container $total_size_gb "Blob" $subscription_id
    done

    # Get the list of file shares in the storage account
    fileShares=$(timeout 60 az storage share list --account-name $storage_account --account-key $account_key --query '[].name' --output tsv)

    for share in $fileShares; do
        usedCapacity=$(timeout 60 az storage share stats --account-name $storage_account --account-key $account_key --name $share --query 'usageStats[0].usageInBytes' --output tsv)
        used_capacity_gb=$(echo "scale=2; $usedCapacity / (1024*1024*1024)" | bc)
        check_and_print $storage_account $share $used_capacity_gb "FileShare" $subscription_id
    done
}

check_and_print() {
    local storage_account=$1
    local container_or_share=$2
    local total_size_gb=$3
    local type=$4
    local subscription_id=$5

    # Get the subscription name by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    if (( $(echo "$total_size_gb > 100 || $total_size_gb == 0" | bc -l) )); then
        # Check if the subscription header has been printed
        if [[ "${processed_subscriptions["$subscription_name"]}" != "true" ]]; then
            echo -e "[$subscription_name] - Storage Account Consumption:" >> "$out_file"
            processed_subscriptions["$subscription_name"]="true"
        fi
        # Check if the storage account has been processed for this subscription
        if [[ "${processed_accounts["$storage_account"]}" != "true" ]]; then
            echo -e $storage_account >> $out_file
            # Mark the storage account as processed for this subscription
            processed_accounts["$storage_account"]="true"
        fi

        echo -e "\t- $type: $container_or_share  Used Capacity: ${total_size_gb} GB" >> "$out_file"
    fi
}

if [ -z "$subscription_id" ]; then
    # If subscription ID is not provided, get all subscription IDs
    for subscription_id in $(az account list --query '[].id' --output tsv); do
        # Call individual functions for each resource type
        find_orphaned_resources "appservice plan" "[?numberOfSites == \`0\`].id" $subscription_id
        find_orphaned_resources "vm availability-set" "[?length(virtualMachines) == \`0\`].id" $subscription_id
        find_orphaned_resources "disk" '[?managedBy==`null`].[id]' $subscription_id
        find_orphaned_resources "network public-ip" "[?ipConfiguration==null && natGateway==null].id" $subscription_id
        find_orphaned_resources "network nic" "[?virtualMachine==null && privateEndpoint==null && networkSecurityGroup==null].id" $subscription_id
        find_orphaned_resources "network nsg" "[?subnets==null && networkInterfaces==null].id" $subscription_id
        find_orphaned_resources "network route-table" '[?subnets==`null`].[id]' $subscription_id
        find_orphaned_resources "network lb" '[?backendAddressPools[0]==`null`].id' $subscription_id
        find_orphaned_resources "network vnet" '[?subnets[0]==null].id' $subscription_id
        find_orphaned_subnets $subscription_id
        find_orphaned_resources "network nat gateway" '[?subnets==`null`].id' $subscription_id
        find_orphaned_resources "network application-gateway" "[?backendAddressPools==null && frontendIpConfigurations==null].id" $subscription_id
        find_orphaned_snapshot "snapshot" "[?timeCreated<='$(date -u -d '7 days ago' +'%Y-%m-%dT%H:%MZ')'].id" $subscription_id
        find_orphaned_resource_groups $subscription_id
        check_vm_utilization $subscription_id
        check_storage_accounts $subscription_id
    done
else
        # Call individual functions for each resource type
        find_orphaned_resources "appservice plan" "[?numberOfSites == \`0\`].id" $subscription_id
        find_orphaned_resources "vm availability-set" "[?length(virtualMachines) == \`0\`].id" $subscription_id
        find_orphaned_resources "disk" '[?managedBy==`null`].[id]' $subscription_id
        find_orphaned_resources "network public-ip" "[?ipConfiguration==null && natGateway==null].id" $subscription_id
        find_orphaned_resources "network nic" "[?virtualMachine==null && privateEndpoint==null && networkSecurityGroup==null].id" $subscription_id
        find_orphaned_resources "network nsg" "[?subnets==null && networkInterfaces==null].id" $subscription_id
        find_orphaned_resources "network route-table" '[?subnets==`null`].[id]' $subscription_id
        find_orphaned_resources "network lb" '[?backendAddressPools[0]==`null`].id' $subscription_id
        find_orphaned_resources "network vnet" '[?subnets[0]==null].id' $subscription_id
        find_orphaned_subnets $subscription_id
        find_orphaned_resources "network nat gateway" '[?subnets==`null`].id' $subscription_id
        find_orphaned_resources "network application-gateway" "[?backendAddressPools==null && frontendIpConfigurations==null].id" $subscription_id
        find_orphaned_snapshot "snapshot" "[?timeCreated<='$(date -u -d '7 days ago' +'%Y-%m-%dT%H:%MZ')'].id" $subscription_id
        find_orphaned_resource_groups $subscription_id
        check_vm_utilization $subscription_id
        check_storage_accounts $subscription_id
fi

echo "Orphaned resources check completed. Check $out_file for details."
