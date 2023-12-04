#!/bin/bash

# Main function to call other functions based on the resource type
subscription_id=$1

# Set the output file
out_file="/opt/HCE/HCE_Azure_Resources_utilization/Azure_Resources_Utilization.txt"
echo "" > $out_file

# Function to find orphaned resources for a given resource type
find_orphaned_resources() {
    local resource_type=$1
    local query_expression=$2
    local subscription_id=$3

    # Find Subscription name
    local subscription=$(az account list --query "[?id=='$subscription_id'].name" --output tsv)

    local orphaned_resources=($(az $resource_type list --subscription $subscription_id --query "$query_expression" --output tsv))

    if [ ${#orphaned_resources[@]} -gt 0 ]; then
        echo "[$subscription][Orphaned $resource_type:]" >> $out_file
        for orphaned_resource in "${orphaned_resources[@]}"; do
            echo "$orphaned_resource" >> $out_file
        done
    fi
}

# Function to find orphaned Subnets
find_orphaned_subnets() {
    local subscription_id=$1

    # Get a list of Subnets in the subscription
    local vnets=$(az network vnet list --subscription $subscription_id --query "[].{Name:name, ResourceGroup:resourceGroup}" --output json)

    # Find Subscription name
    local subscription=$(az account list --query "[?id=='$subscription_id'].name" --output tsv)

    # Loop through each  Subnets
    for vnet in $(echo "$vnets" | jq -c '.[]'); do
        vnet_name=$(echo $vnet | jq -r '.Name')
        resource_group=$(echo $vnet | jq -r '.ResourceGroup')

        local orphaned_subnets=($(az network vnet subnet list --subscription $subscription_id --vnet-name $vnet_name --resource-group $resource_group --query '[?ipConfigurations[0]==`null`].id' --output tsv))

        if [ ${#orphaned_subnets[@]} -gt 0 ]; then
            echo "[$subscription][Orphaned Subnets:]" >> $out_file
            for subnet in "${orphaned_subnets[@]}"; do
                if [ -n "$subnet" ]; then
                    echo "$subnet" >> $out_file
                fi
            done
        fi
    done
}

# Function to find orphaned Resource Groups
find_orphaned_resource_groups() {
    local subscription_id=$1

    # Find Subscription name
    local subscription=$(az account list --query "[?id=='$subscription_id'].name" --output tsv)

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
        echo "[$subscription][Orphaned Resource Groups:]" >> $out_file
        for orphan_rg in "${orphans_rg[@]}"; do
            echo "/subscriptions/$subscription_id/resourceGroups/$orphan_rg" >> $out_file
        done
    fi
}

check_vm_utilization() {
    local subscription_id=$1

    az account set --subscription=$subscription_id

    # Find Subscription name
    local subscription=$(az account list --query "[?id=='$subscription_id'].name" --output tsv)

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
            echo -e "[$subscription][Percentage CPU:] $cpuUtilization% and [Percentage Memory:] $memoryUtilization%"
            echo -e "$vmId"
        fi
    done
}

if [ -z "$subscription_id" ]; then
    # If subscription ID is not provided, get all subscription IDs
    for subscription_id in $(az account list --query '[].id' --output tsv); do
        # Call individual functions for each resource type
        find_orphaned_resources "appservice plan" "[?numberOfSites == \`0\`].id" $subscription_id
        find_orphaned_resources "vm availability-set" "[?length(virtualMachines) == \`0\`].id" $subscription_id
        find_orphaned_resources "disk" '[?managedBy==`null`].[id]' $subscription_id
        find_orphaned_resources "network public-ip" "[?ipConfiguration==null].id" $subscription_id
        find_orphaned_resources "network nic" "[?virtualMachine==null && privateEndpoint==null && networkSecurityGroup==null].id" $subscription_id
        find_orphaned_resources "network nsg" "[?subnets==null && networkInterfaces==null].id" $subscription_id
        find_orphaned_resources "network route-table" '[?subnets==`null`].[id]' $subscription_id
        find_orphaned_resources "network lb" '[?backendAddressPools[0]==`null`].id' $subscription_id
        find_orphaned_resources "network vnet" '[?subnets[0].ipConfigurations[0]==`null`].id' $subscription_id
        find_orphaned_subnets $subscription_id
        find_orphaned_resources "network nat gateway" '[?subnets==`null`].id' $subscription_id
        find_orphaned_resources "network application-gateway" "[?backendAddressPools==null && frontendIpConfigurations==null].id" $subscription_id
        find_orphaned_resource_groups $subscription_id
                check_vm_utilization $subscription_id
    done
else
    # Call individual functions for each resource type
        find_orphaned_resources "appservice plan" "[?numberOfSites == \`0\`].id" $subscription_id
        find_orphaned_resources "vm availability-set" "[?length(virtualMachines) == \`0\`].id" $subscription_id
        find_orphaned_resources "disk" '[?managedBy==`null`].[id]' $subscription_id
        find_orphaned_resources "network public-ip" "[?ipConfiguration==null].id" $subscription_id
        find_orphaned_resources "network nic" "[?virtualMachine==null && privateEndpoint==null && networkSecurityGroup==null].id" $subscription_id
        find_orphaned_resources "network nsg" "[?subnets==null && networkInterfaces==null].id" $subscription_id
        find_orphaned_resources "network route-table" '[?subnets==`null`].[id]' $subscription_id
        find_orphaned_resources "network lb" '[?backendAddressPools[0]==`null`].id' $subscription_id
        find_orphaned_resources "network vnet" '[?subnets[0].ipConfigurations[0]==`null`].id' $subscription_id
        find_orphaned_subnets $subscription_id
        find_orphaned_resources "network nat gateway" '[?subnets==`null`].id' $subscription_id
        find_orphaned_resources "network application-gateway" "[?backendAddressPools==null && frontendIpConfigurations==null].id" $subscription_id
        find_orphaned_resource_groups $subscription_id
                check_vm_utilization $subscription_id
fi

echo "Orphaned resources check completed. Check $out_file for details."
