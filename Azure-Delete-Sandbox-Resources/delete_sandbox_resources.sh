#!/bin/bash

# Login to Azure (this step can be skipped if already logged in)
az login --service-principal --username $username --password $password --tenant $tenant

# Log file for deletions
LOG_FILE="/opt/Deleted_Resources/resource_deletion_$(date +"%Y-%m-%d").log"

# Set the subscription you want to work with
az account set --subscription $SUBSCRIPTION_ID

# Read excluded resource groups from the file
EXCLUDED_RESOURCE_GROUPS=()
while IFS= read -r line; do
    EXCLUDED_RESOURCE_GROUPS+=("$line")
done < exempted_resources.txt

# Get the current date in seconds since epoch
current_date=$(date +%s)

# Define the number of seconds in 30 days
seconds_in_30_days=$((30 * 24 * 60 * 60))

# Find and delete resources older than 30 days
resources=$(az resource list --query "[?createdTime != null].{id:id, createdTime:createdTime, resourceGroup:resourceGroup}" -o json)

# Loop through each resource
for resource in $(echo "$resources" | jq -c '.[]'); do
    resource_id=$(echo "$resource" | jq -r '.id')
    resource_created_time=$(echo "$resource" | jq -r '.createdTime')
    resource_group=$(echo "$resource" | jq -r '.resourceGroup')

    # Flag to determine if resource should be deleted
    delete_resource=true

    # Check if resource group is excluded
    for excluded_group in "${EXCLUDED_RESOURCE_GROUPS[@]}"; do
        if [[ "$resource_group" == "$excluded_group" ]]; then
            delete_resource=false
            break
        fi
    done

    # If resource should not be deleted, continue to next resource
    if [ "$delete_resource" = false ]; then
        continue
    fi

    # Convert resource created time to seconds since epoch
    resource_created_date=$(date -d "$resource_created_time" +%s)

    # Calculate the age of the resource
    resource_age=$((current_date - resource_created_date))

    # Check if the resource is older than 30 days
    if [ $resource_age -gt $seconds_in_30_days ]; then
        # Log the deletion to the log file
        echo "Deleting resource: $resource_id" >> "$LOG_FILE"
        az resource delete --ids $resource_id
    fi
done

# Clean up old log files (older than 30 days)
cleanup_log_files() {
    echo "Performing log file cleanup..."
    find /opt/Deleted_Resources/* -type f -mtime +30 -exec rm -f {} \;
    echo "Log file cleanup complete."
}

# Call cleanup_log_files function to remove old logs
cleanup_log_files
