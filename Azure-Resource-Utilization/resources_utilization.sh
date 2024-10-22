#!/bin/bash

###############################################################
##  Name:  Oktay SAVDI
##  Date:  15.04.2024
##  Call:  ./resources_utilization.sh
##  Call:  ./resources_utilization.sh "<subscription_id>"
###############################################################

#set -x
#set -e

# Main function to call other functions based on the resource type
subscription_id=$1

# Array to track processed storage accounts for each subscription
declare -A processed_accounts
declare -A processed_subscriptions

# Set the output file
email_subject="Orphaned Resources Report in Azure"
owner_email="mymail@mydomain.com"
BODY=$(cat <<EOF
Hello Team,

Please find the attached report for Azure Automation resource utilization. This report provides insights into the current usage and performance of our Azure Automation resources.

The report includes details such as:
  - Orphan Resources
  - Snapshots older than 7 days
  - VMs Performance (Last 3 Months)
  - Storage Account and Container Registry Consumptions
  - Databases Idle (for over 30 days) and Idle SQL Pool
  - Backup and Synapse Workspaces Idle Item

Please review the report and let people know if they have the resources above. 

Thank you,
EOF
)

az login --service-principal --username $username --password $password --tenant $tenant

# Set the output file
out_file="/opt/Azure_Resources_utilization/Azure_Resources_Utilization.txt"

# the title of the report
echo "*****************************************************************" > $out_file
echo "********************* General Resources Report ******************" >> $out_file
echo "*********************  $(date +'%d-%m-%Y')   *****************************" >> $out_file
echo "*****************************************************************" >> $out_file

# Function to check if a resource is exempted
is_resource_exempted() {
    local orphaned_resource=$1
    local exempted_file="/opt/Azure_Resources_utilization/exempted_resources.txt"

    # Check if the resource_id is in the exempted resources list
    if grep -qFx "$orphaned_resource" "$exempted_file"; then
        return 0  # Resource is exempted
    else
        return 1  # Resource is not exempted
    fi
}

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
            if ! is_resource_exempted "$(echo $orphaned_resource | awk -F'/' '{print $(NF)}')"; then
                echo "[warning] $orphaned_resource" >> $out_file
            fi            
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
            if ! is_resource_exempted "$(echo $orphaned_resource | awk -F'/' '{print $(NF)}')"; then
                  echo "[warning] $orphaned_resource" >> $out_file
            fi            
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
                    if ! is_resource_exempted "$(echo $subnet | awk -F'/' '{print $(NF)}')"; then
                       echo "[warning] $subnet" >> $out_file
                    fi                     
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
            if ! is_resource_exempted "$orphan_rg"; then
               echo "[warning] $orphan_rg" >> $out_file
            fi              
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

        if ! is_resource_exempted "$(echo $vmId | awk -F'/' '{print $(NF)}')"; then

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
                echo -e "[warning] $vmId" >> $out_file
            fi
        fi
    done
    echo "*****************************************************************" >> $out_file
}

check_resource_size() {
    local subscription_id=$1
    local resource_type=$2
    local output_added=false

    # Get the current date
    current_date=$(date -u +"%Y-%m-%d")

    # Calculate the previous working day (assuming Mon-Fri are working days)
    prev_working_day=$(date -u -d "yesterday" +"%Y-%m-%d")

    # Set the subscription for Azure CLI commands
    az account set --subscription $subscription_id

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    if [ "$resource_type" == "storage_account" ]; then
        resources=$(az storage account list --query "[].id" -o tsv)
        metric="UsedCapacity"
    elif [ "$resource_type" == "container_registry" ]; then
        resources=$(az acr list --query "[].id" -o tsv)
        metric="StorageUsed"
    else
        echo "Invalid resource type"
        return 1
    fi

    # Loop through each resource
    for resource in $resources; do

       if ! is_resource_exempted "$(echo $resource | awk -F'/' '{print $(NF)}')"; then

            # Get the metric data for the resource
            metric_data=$(az monitor metrics list --resource $resource --metric $metric --interval PT1H --start-time $prev_working_day"T00:00:00Z" --end-time $current_date"T00:00:00Z" --output json)
    
            # Extract the first non-empty "Average" value
            first_value=$(echo $metric_data | jq -r '.value[0].timeseries[0].data[0].average')
            
            # Check if the value is empty, and if so, find the next non-empty value
            while [ -z "$first_value" ]; do
                metric_data=$(echo $metric_data | jq '.value[0].timeseries[0].data[1:]')
                first_value=$(echo $metric_data | jq -r '.[0].average')
            done
    
            resource_name=$(echo $resource | awk -F'/' '{print $(NF)}')
    
            # Convert the value from bytes to gigabytes and terabytes
            gigabytes=$(echo "scale=2; $first_value / 1073741824" | bc)
            terabytes=$(echo "scale=2; $first_value / 1099511627776" | bc)
      
            # Check if the value is over 100 GB or 0 GB
            if (( $(echo "$gigabytes > 100 || $gigabytes == 0" | bc -l) )); then
               # Check if the subscription header has been printed
               if [ "$output_added" = false ]; then
                   echo -e "[$subscription_name] - $resource_type Consumption:" >> "$out_file"
                   output_added=true
                fi
    
                echo -e "[warning] $resource_name" >> "$out_file"
                echo -e "\t\t- Total GB: $gigabytes" >> "$out_file"
    
                # Check if the value is over 1 TB
                if (( $(echo "$terabytes > 1" | bc -l) )); then
                    echo -e "\t\t- Total TB: $terabytes" >> "$out_file"
                fi
            fi
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
        account_key=$(timeout 30 az storage account keys list --account-name $storage_account --query '[0].value' --output tsv)
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
    containers=$(timeout 30 az storage container list --account-name $storage_account --account-key $account_key --query '[].name' --output tsv)

    for container in $containers; do
        total_size=$(timeout 30 az storage blob list --account-name $storage_account --container-name $container --account-key $account_key --query "[].properties.contentLength" --output tsv | paste -sd+ - | bc)
        total_size_gb=$(echo "scale=2; $total_size / (1024*1024*1024)" | bc)
        check_and_print $storage_account $container $total_size_gb "Blob" $subscription_id
    done

    # Get the list of file shares in the storage account
    fileShares=$(timeout 30 az storage share list --account-name $storage_account --account-key $account_key --query '[].name' --output tsv)

    for share in $fileShares; do
        usedCapacity=$(timeout 30 az storage share stats --account-name $storage_account --account-key $account_key --name $share --query 'usageStats[0].usageInBytes' --output tsv)
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

# Function to find idle databases (no activity for over 30 days)
find_idle_sql_databases() {
    local resource_type=$1
    local query_expression=$2
    local subscription_id=$3

    local current_date=$(date +%s)
    local threshold_days=30
    local seconds_in_day=86400
    local output_added=false

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    # List all SQL servers in the subscription
    local sql_servers=($(az sql server list --subscription $subscription_id --query "[].{name:name, resourceGroup:resourceGroup}" --output tsv))

    for ((i=0; i<${#sql_servers[@]}; i+=2)); do
        local server_name=${sql_servers[i]}
        local resource_group=${sql_servers[i+1]}

        # List all databases on the server
        local databases_json=$(az $resource_type --server $server_name --resource-group $resource_group --subscription $subscription_id --query "$query_expression")

        # Loop through each database and check for idle state based on last backup date
        echo "$databases_json" | jq -r '.[] | [.id, .earliestRestoreDate] | @tsv' | while read -r db_id last_backup_date; do
            if [[ -z "$last_backup_date" ]]; then
                continue  # Skip databases without a backup date
            fi

            # Convert last backup date to seconds since epoch
            last_backup_date_seconds=$(date -d "$last_backup_date" +%s)

            # Calculate the difference in days
            days_since_last_backup=$(( ($current_date - $last_backup_date_seconds) / $seconds_in_day ))

            if [ "$days_since_last_backup" -ge "$threshold_days" ]; then
                if [ "$output_added" = false ]; then
                  echo "************************** Idle SQL Database (over 30 days) ************************" >> $out_file
                  output_added=true
                fi
                # This database is idle for over 30 days
                if ! is_resource_exempted "$(echo $db_id | awk -F'/' '{print $(NF)}')"; then
                    echo "[warning] $db_id" >> $out_file
                fi
            fi
        done
        echo "*****************************************************************" >> $out_file
    done
}

find_idle_elastic_pools() {
    local resource_type=$1
    local subscription_id=$2

    local output_added=false

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    # List all SQL servers in the subscription
    local sql_servers=($(az sql server list --subscription $subscription_id --query "[].{name:name, resourceGroup:resourceGroup}" --output tsv))

    for ((i=0; i<${#sql_servers[@]}; i+=2)); do
        local server_name=${sql_servers[i]}
        local resource_group=${sql_servers[i+1]}

        # List all elastic pools on the server
        local elastic_pools_json=$(az $resource_type --server $server_name --resource-group $resource_group --subscription $subscription_id)

        # Loop through each elastic pool and check for idle state
        echo "$elastic_pools_json" | jq -r '.[] | [.id, .name] | @tsv' | while read -r pool_id pool_name; do
            # Check the number of databases in the elastic pool
            local db_count=$(az sql db list --elastic-pool $pool_name --server $server_name --resource-group $resource_group --subscription $subscription_id --query "length([])" --output tsv)

            if [ "$db_count" -eq 0 ]; then
                if [ "$output_added" = false ]; then
                  echo "************************** Idle SQL Elastic Pool (no databases) ************************" >> $out_file
                  output_added=true
                fi
                # If the elastic pool has no databases, it's idle
                if ! is_resource_exempted "$(echo $pool_id | awk -F'/' '{print $(NF)}')"; then
                    echo "[$subscription_name] - $pool_id" >> $out_file
                fi
                echo "*****************************************************************" >> $out_file
            fi
        done
    done
}

# Function to find unused Synapse Workspaces
find_unused_synapse_workspaces() {
    local resource_type=$1
    local subscription_id=$2
    local threshold_date=$(date -d "-$threshold_days days" --utc +%Y-%m-%dT%H:%M:%SZ)

    local output_added=false

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    # List all Synapse Workspaces in the subscription
    local synapse_workspaces_json=$(az synapse workspace list --subscription $subscription_id)

    # Loop through each Synapse workspace and check for idle state
    echo "$synapse_workspaces_json" | jq -r '.[] | [.id, .name, .resourceGroup] | @tsv' | while read -r workspace_id workspace_name resource_group; do
        # Check for SQL pools in the workspace (dedicated and serverless)
        local sql_pools_json=$(az $resource_type --workspace-name $workspace_name --resource-group $resource_group --subscription $subscription_id)

        if [[ $(echo "$sql_pools_json" | jq -r '. | length') -eq 0 ]]; then
            if [ "$output_added" = false ]; then
                echo "[$subscription_name] - Unused Synapse Workspace (no SQL pools)" >> $out_file
                output_added=true
            fi

            # If the Synapse workspace has no SQL pools, it is considered unused
            if ! is_resource_exempted "$(echo $workspace_id | awk -F'/' '{print $(NF)}')"; then
                echo "[warning] $workspace_id" >> $out_file
            fi
            echo "*****************************************************************" >> $out_file
        else
            # Loop through each SQL pool and check for query activity
            echo "$sql_pools_json" | jq -r '.[] | [.id, .name, .status] | @tsv' | while read -r pool_id pool_name pool_status; do
                # Fetch query activity for the SQL pool (you would need to implement custom logging or use Azure Monitor metrics for actual query activity)
                # This is a placeholder to check for recent query activity
                local recent_activity=$(az synapse sql pool show --workspace-name $workspace_name --name $pool_name --query "properties.createDate" --output tsv)

                if [[ "$recent_activity" < "$threshold_date" ]]; then
                    if [ "$output_added" = false ]; then
                       echo "[$subscription_name] - Unused Synapse SQL Pool (no recent query activity)" >> $out_file
                       output_added=true
                    fi
                    
                    if ! is_resource_exempted "$(echo $pool_id | awk -F'/' '{print $(NF)}')"; then
                        echo "[warning] $pool_id" >> $out_file
                    fi
                fi
            done
            echo "*****************************************************************" >> $out_file
        fi
    done
}

# Function to find idle Private DNS Zones
find_idle_private_dns_zones() {
    local subscription_id=$1
    
    local output_added=false

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    # List all Private DNS Zones in the subscription
    local dns_zones_json=$(az network private-dns zone list --subscription $subscription_id)

    # Loop through each DNS zone and check for idle state
    echo "$dns_zones_json" | jq -r '.[] | [.id, .name, .resourceGroup] | @tsv' | while read -r zone_id zone_name resource_group; do
        # Check for linked virtual networks
        local vnet_links=$(az network private-dns link vnet list --zone-name $zone_name --resource-group $resource_group --subscription $subscription_id --query "length([])" --output tsv)

        if [ "$vnet_links" -eq 0 ]; then
            if [ "$output_added" = false ]; then
                echo "************************** [$subscription_name] Idle Private DNS Zone (no linked VNETs) ************************" >> $out_file
                output_added=true
            fi

            # If the Private DNS Zone has no linked virtual networks, it's considered idle
            if ! is_resource_exempted "$(echo $zone_id | awk -F'/' '{print $(NF)}')"; then
                echo "[warning] $zone_id" >> $out_file
            fi
        else
            # Check if the DNS zone has any DNS records (excluding SOA and NS records)
            local dns_records=$(az network private-dns record-set list --zone-name $zone_name --resource-group $resource_group --subscription $subscription_id --query "[?type!='Microsoft.Network/privateDnsZones/SOA' && type!='Microsoft.Network/privateDnsZones/NS'].id" --output tsv)

            if [[ -z "$dns_records" ]]; then
                if [ "$output_added" = false ]; then
                echo "************************** [$subscription_name] Idle Private DNS Zone (no DNS records) ************************" >> $out_file
                output_added=true
                fi

                # If the DNS zone has no records, it's also considered idle
                if ! is_resource_exempted "$(echo $zone_id | awk -F'/' '{print $(NF)}')"; then
                    echo "[warning] $zone_id" >> $out_file
                fi
                echo "*****************************************************************" >> $out_file
            fi
        fi
    done
}

# Function to find idle Virtual Network Gateways
find_idle_vnet_gateways() {
    local subscription_id=$1

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    # List all resource groups in the subscription
    local resource_groups=($(az group list --subscription $subscription_id --query "[].name" --output tsv))

    # Loop through each resource group to find VNet gateways
    for resource_group in "${resource_groups[@]}"; do
        # List all Virtual Network Gateways in the resource group
        local vnet_gateways_json=$(az network vnet-gateway list --resource-group $resource_group --subscription $subscription_id)

        # Loop through each VNet gateway and check for idle state
        echo "$vnet_gateways_json" | jq -r '.[] | [.id, .name] | @tsv' | while read -r gateway_id gateway_name; do
            # Check if the gateway has any connections
            local connections=$(az network vpn-connection list --resource-group $resource_group --subscription $subscription_id --query "[?virtualNetworkGateway1.id=='$gateway_id']" --output tsv)

            if [[ -z "$connections" ]]; then
                # If the Virtual Network Gateway has no connections, it's considered idle
                echo "[$subscription_name] - Idle Virtual Network Gateway (no connections)" >> $out_file
                if ! is_resource_exempted "$(echo $gateway_id | awk -F'/' '{print $(NF)}')"; then
                    echo "[warning] $gateway_id" >> $out_file
                fi
                echo "*****************************************************************" >> $out_file
            fi
        done
    done
}

# Function to find idle backups
find_idle_backups() {
    local resource_type=$1
    local subscription_id=$2
    local threshold_days=30
    local threshold_date=$(date -d "-$threshold_days days" --utc +%Y-%m-%dT%H:%M:%SZ)

    local output_added=false

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    # List all backup vaults in the subscription
    local backup_vaults_json=$(az backup vault list --subscription $subscription_id)

    # Loop through each backup vault and check for idle state
    echo "$backup_vaults_json" | jq -r '.[] | [.id, .name, .resourceGroup] | @tsv' | while read -r vault_id vault_name resource_group; do
        # List backup items in the vault
        local backup_items_json=$(az $resource_type --vault-name "$vault_name" --resource-group $resource_group --subscription $subscription_id)

        # Check if there are no backup items
        if [[ $(echo "$backup_items_json" | jq -r '. | length') -eq 0 ]]; then
            if [ "$output_added" = false ]; then
                echo "[$subscription_name] - Idle Backup Vault (no backup items)" >> $out_file
                output_added=true
            fi

            if ! is_resource_exempted "$(echo $vault_id | awk -F'/' '{print $(NF)}')"; then
                echo "[warning] $vault_id" >> $out_file
            fi
            echo "*****************************************************************" >> $out_file
        else
            # Loop through each backup item to check for last backup date
            echo "$backup_items_json" | jq -r '.[] | [.id, .name, .properties.backupManagementType, .properties.lastBackupStatus, .properties.lastBackupTime] | @tsv' | while read -r item_id item_name backup_management_type last_backup_status last_backup_time; do
                # Check if the last backup time exceeds the threshold
                if [[ "$last_backup_time" < "$threshold_date" ]]; then
                    if [ "$output_added" = false ]; then
                       echo "[$subscription_name] - Idle Backup Item (no recent backup)" >> $out_file
                       output_added=true
                    fi
                    
                    if ! is_resource_exempted "$(echo $item_id | awk -F'/' '{print $(NF)}')"; then
                        echo "[warning] $item_id" >> $out_file
                    fi
                fi
            done
            echo "*****************************************************************" >> $out_file
        fi
    done
}

# Function to find idle Private Endpoints with connection status = Disconnected
find_disconnected_private_endpoints() {
    local resource_type=$1
    local subscription_id=$2

    local output_added=false

    # Get the subscription by ID
    local subscription_name=$(az account show --subscription $subscription_id --query "{Name:name}" --output tsv)

    # List all Private Endpoints in the subscription
    local private_endpoints_json=$(az $resource_type --subscription $subscription_id)

    # Loop through each private endpoint and check for Disconnected status
    echo "$private_endpoints_json" | jq -r '.[] | [.id, .name, .resourceGroup, .privateLinkServiceConnections[].privateLinkServiceConnectionState.status, .privateLinkServiceConnections[].privateLinkServiceId] | @tsv' | while read -r endpoint_id endpoint_name resource_group connection_status resource_id; do
        if [[ "$connection_status" == "Disconnected" ]]; then
            # If the private endpoint connection is Disconnected
            if [ "$output_added" = false ]; then
                echo "[$subscription_name] - Disconnected Private Endpoint" >> $out_file
                output_added=true
            fi
            
            if ! is_resource_exempted "$(echo $endpoint_id | awk -F'/' '{print $(NF)}')"; then
                echo "[warning] $endpoint_id" >> $out_file
            fi
        fi
    done
    echo "*****************************************************************" >> $out_file
}

# Function to send an email with the report attached
send_email() {
    local recipient=$1
    local attachment=$2

    # Use mail command to send the email with the attachment
    echo -e "$BODY" | mail -s "$email_subject" -a "$attachment" "$recipient" 
}

if [ -z "$subscription_id" ]; then
    # If subscription ID is not provided, get all subscription IDs
    for subscription_id in $(az account list --query '[].id' --output tsv); do
        ## Call individual functions for each resource type
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
        #check_vm_utilization $subscription_id
        #check_storage_accounts $subscription_id
        check_resource_size $subscription_id "storage_account"
        check_resource_size $subscription_id "container_registry"
        find_idle_sql_databases "sql db list" "[?status=='Online']" $subscription_id
        find_idle_elastic_pools "sql elastic-pool list" $subscription_id
        find_idle_private_dns_zones $subscription_id
        find_idle_vnet_gateways $subscription_id
        find_idle_backups "backup item list" $subscription_id
        find_unused_synapse_workspaces "synapse sql pool list" $subscription_id
        find_disconnected_private_endpoints "network private-endpoint list" $subscription_id
    done
else
        ## Call individual functions for each resource type
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
        #check_vm_utilization $subscription_id
        #check_storage_accounts $subscription_id
        check_resource_size $subscription_id "storage_account"
        check_resource_size $subscription_id "container_registry"
        find_idle_sql_databases "sql db list" "[?status=='Online']" $subscription_id
        find_idle_elastic_pools "sql elastic-pool list" $subscription_id
        find_idle_private_dns_zones $subscription_id
        find_idle_vnet_gateways $subscription_id
        find_idle_backups "backup item list" $subscription_id
        find_unused_synapse_workspaces "synapse sql pool list" $subscription_id
        find_disconnected_private_endpoints "network private-endpoint list" $subscription_id
fi

# Check if the report file is empty
if grep -q "\[warning\]" "$out_file"; then
        # Send email to the specific owner_email
        send_email "$owner_email" "$out_file"
        echo "Orphaned resources check completed"
fi

echo "Orphaned resources check completed. Check $out_file for details."
