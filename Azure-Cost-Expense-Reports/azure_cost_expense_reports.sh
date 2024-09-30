#!/bin/bash

###############################################################
##  Name:  Oktay SAVDI
##  Date:  01.09.2024
##  Call:  ./azure_cost_expense_reports.sh
###############################################################

# Set the output file
output_dir="/opt/repos/Azure_Cost_Expense_Reports"
email_subject="Monthly Azure Expense Report - Review Your Resource Usage"
BODY=$(cat <<EOF
Dear Team,

We are sending you the attached monthly report detailing the costs associated with the Azure resources utilized over the past month.

Please review this report carefully to identify any unnecessary expenditures or underutilized resources. 
We encourage you to take prompt action where necessary, such as optimizing or decommissioning resources, to manage your budget more efficiently.

Should you have any questions or require assistance in managing your Azure resources, please do not hesitate to reach out to us.

Thank you for your attention to this matter.

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

    # Get the subscription by ID
    local subscription_id=$(az account show --subscription $subscription_name --query "id" --output tsv)


    # Set the start and end dates in YYYY-MM-DD format
    startDate=$(date -d "$(date +%m/01/%Y) -1 month" +%m/01/%Y)
    endDate=$(date -d "$(date +%m/01/%Y)" +%m/01/%Y)

    #Disable the proxy
    unset https_proxy http_proxy no_proxy

    # create log file
    local report_file="$output_dir/${subscription_name}_cost_expense_report.txt"    

    azure-cost accumulatedCost -s $subscription_id -t custom --from $startDate --to $endDate -o Text > $report_file

    # Send email notification
    send_email "$owner_email" "$report_file"
}

# Function to send an email with the report attached
send_email() {
    local recipient=$1
    local report_file=$2
    
    echo -e "$BODY" | mail -s "$email_subject" -a "$report_file" "$recipient"
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
