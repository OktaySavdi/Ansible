#!/bin/bash

# Usage examples:
# To find orphaned resources in a specific subscription:
# find_orphaned_resources <subscription_id>

# To find orphaned resources in all subscriptions:
# find_orphaned_resources

# Main function to call other functions based on the resource type
subscription_id=$1

out_file="Azure_Resources_Utilization.txt"

echo "" > $out_file

# Function to find orphaned App Service Plans
find_orphaned_app_service_plans() {
    local subscription_id=$1
  
    # Get a list of all app service plans
    local app_service_plans=$(az appservice plan list --subscription $subscription_id --query "[?numberOfSites == \`0\`].id" --output tsv)

    if [ -n "$app_service_plans" ]; then
        # Print orphaned app service plans
        echo "[$subscription_id] - Orphaned App Service Plans:" >> $out_file
        echo "$app_service_plans" >> $out_file
    fi
}

# Function to find orphaned Availability Sets
find_orphaned_availability_sets() {
    local subscription_id=$1

    # Get a list of all availability sets
    local availability_sets=$(az vm availability-set list --subscription $subscription_id --query "[?length(virtualMachines) == \`0\`].id" --output tsv)

    if [ -n "$availability_sets" ]; then
        # Print orphaned availability sets
        echo "[$subscription_id] - Orphaned Availability Sets:" >> $out_file
        echo "$availability_sets" >> $out_file
    fi  
}

# Function to find orphaned Disks
find_orphaned_disks() {
    local subscription_id=$1

    # Get a list of all Disks
    local orphaned_disks=($(az disk list --subscription $subscription_id --query '[?managedBy==`null`].[id]' --output tsv))

    if [ -n "$orphaned_disks" ]; then
        # Print orphaned Disks
        echo "[$subscription_id] - Orphaned Disks:" >> $out_file
        echo "$orphaned_disks" >> $out_file
    fi
}

# Function to find orphaned Public IPs
find_orphaned_public_ips() {
    local subscription_id=$1

    # Get a list of all Public IPs
    local orphaned_public_ips=($(az network public-ip list --subscription $subscription_id --query "[?ipConfiguration==null].id" --output tsv))

    if [ -n "$orphaned_public_ips" ]; then
        # Print orphaned public IPs
        echo "[$subscription_id] - Orphaned Public IPs:" >> $out_file
        echo "$orphaned_public_ips" >> $out_file
    fi
}

# Function to find orphaned Network Interfaces
find_orphaned_network_interfaces() {
    local subscription_id=$1

    # Get a list of all Network Interfaces
    local orphaned_nics=($(az network nic list --subscription $subscription_id --query "[?virtualMachine==null && privateEndpoint==null && networkSecurityGroup==null].id" --output tsv))

    if [ -n "$orphaned_nics" ]; then
        # Print orphaned Network Interfaces
        echo "[$subscription_id] - Orphaned Network Interfaces:" >> $out_file
        echo "$orphaned_nics" >> $out_file
    fi
}

# Function to find orphaned Network Security Groups
find_orphaned_network_security_groups() {
    local subscription_id=$1

    # Get a list of all NSGs
    local orphaned_nsgs=$(az network nsg list --subscription $subscription_id --query "[?subnets==null && networkInterfaces==null].id" --output tsv)
    
    if [ -n "$orphaned_nsgs" ]; then
        # Print orphaned NSGs
        echo "[$subscription_id] - Orphaned Network Security Groups:" >> $out_file
        echo "$orphaned_nsgs" >> $out_file
    fi
}

# Function to find orphaned Route Tables
find_orphaned_route_tables() {
    local subscription_id=$1

    # Get a list of all Route Tables
    local orphaned_tables=($(az network route-table list --subscription $subscription_id --query '[?subnets==`null`].[id]' --output tsv))

    if [ -n "$orphaned_tables" ]; then
        # Print orphaned Route Tables
        echo "[$subscription_id] - Orphaned Route Tables:" >> $out_file
        echo "$orphaned_tables" >> $out_file
    fi
}

# Function to find orphaned Load Balancers
find_orphaned_load_balancers() {
    local subscription_id=$1

    # Get a list of all Load Balancers  
    local orphaned_loadBalancers=$(az network lb list --subscription $subscription_id --query '[?backendAddressPools[0]==`null`].id' --output tsv)

    if [ -n "$orphaned_loadBalancers" ]; then
        # Print orphaned Load Balancers
        echo "[$subscription_id] - Orphaned Load Balancers:" >> $out_file
        echo "$orphaned_loadBalancers" >> $out_file
    fi
}

# Function to find orphaned Virtual Networks
find_orphaned_virtual_networks() {
    local subscription_id=$1

    # Get a list of all Virtual Networks
    local orphaned_networks=($(az network vnet list --subscription $subscription_id --query '[?subnets[0].ipConfigurations[0]==`null`].id' --output tsv))

    if [ -n "$orphaned_networks" ]; then
        # Print orphaned Virtual Networks
        echo "[$subscription_id] - Orphaned Virtual Networks:" >> $out_file
        echo "$orphaned_networks" >> $out_file
    fi
}

# Function to find orphaned Subnets
find_orphaned_subnets() {
    local subscription_id=$1

    # Get a list of Subnets in the subscription
    local vnets=$(az network vnet list --subscription $subscription_id --query "[].{Name:name, ResourceGroup:resourceGroup}" --output json)

    # Loop through each  Subnets
    for vnet in $(echo "$vnets" | jq -c '.[]'); do
        vnet_name=$(echo $vnet | jq -r '.Name')
        resource_group=$(echo $vnet | jq -r '.ResourceGroup')

        local orphaned_subnets=($(az network vnet subnet list --subscription $subscription_id --vnet-name $vnet_name --resource-group $resource_group --query '[?ipConfigurations[0]==`null`].id' --output tsv))

        if [ ${#orphaned_subnets[@]} -gt 0 ]; then
            for subnet in "${orphaned_subnets[@]}"; do
                if [ -n "$subnet" ]; then
                    echo "[$subscription_id] - Orphaned  Subnets:" >> $out_file
                    echo "$subnet" >> $out_file
                fi
            done
        fi
    done
}

# Function to find orphaned NAT Gateways
find_orphaned_nat_gateways() {
    local subscription_id=$1

    # Get a list of all NAT Gateways
    local orphaned_nat_gateways=($(az network nat gateway list --subscription $subscription_id --query '[?subnets==`null`].id' --output tsv))

    if [ -n "$orphaned_nat_gateways" ]; then
        # Print orphaned NAT Gateways
        echo "[$subscription_id] - Orphaned NAT Gateways:" >> $out_file
        echo "$orphaned_nat_gateways" >> $out_file
    fi
}

# Function to find orphaned APP Gateways
find_orphaned_app_gateways() {
    local subscription_id=$1

    # Get a list of all NAT Gateways
    local orphaned_app_gateways=($(az network application-gateway list --subscription $subscription_id --query "[?frontendIPConfigurations == null].id" -o tsv))

    if [ -n "$orphaned_app_gateways" ]; then
        # Print orphaned APP Gateways
        echo "[$subscription_id] - Orphaned APP Gateways:" >> $out_file
        echo "$orphaned_app_gateways" >> $out_file
    fi
}

# Function to find orphaned Resource Groups
find_orphaned_resource_groups() {
    local subscription_id=$1

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
        echo "[$subscription_id] - Orphaned Resource Groups:" >> $out_file
        for orphan_rg in "${orphans_rg[@]}"; do
            echo "$orphan_rg" >> $out_file
        done
    fi
}

if [ -z "$subscription_id" ]; then
    # If subscription ID is not provided, get all subscription IDs
    subscription_ids=($(az account list --query '[].name' --output tsv))
    for subscription_id in $subscription_ids; do
        # Call individual functions for each resource type
        find_orphaned_availability_sets $subscription_id
        find_orphaned_disks $subscription_id
        find_orphaned_public_ips $subscription_id
        find_orphaned_network_interfaces $subscription_id
        find_orphaned_network_security_groups $subscription_id
        find_orphaned_route_tables $subscription_id
        find_orphaned_load_balancers $subscription_id
        find_orphaned_virtual_networks $subscription_id
        find_orphaned_subnets $subscription_id
        find_orphaned_nat_gateways $subscription_id
        find_orphaned_app_gateways $subscription_id
        find_orphaned_resource_groups $subscription_id
    done   
else
    # Call individual functions for each resource type
    find_orphaned_availability_sets $subscription_id
    find_orphaned_disks $subscription_id
    find_orphaned_public_ips $subscription_id
    find_orphaned_network_interfaces $subscription_id
    find_orphaned_network_security_groups $subscription_id
    find_orphaned_route_tables $subscription_id
    find_orphaned_load_balancers $subscription_id
    find_orphaned_virtual_networks $subscription_id
    find_orphaned_subnets $subscription_id
    find_orphaned_nat_gateways $subscription_id
    ind_orphaned_app_gateways $subscription_id
    find_orphaned_resource_groups $subscription_id
fi 
