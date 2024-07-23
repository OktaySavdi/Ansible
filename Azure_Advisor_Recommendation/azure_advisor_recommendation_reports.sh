#!/bin/bash

###############################################################
##  Name:  Oktay SAVDI
##  Date:  10.06.2024
##  Call:  ./azure_advisor_recommendation_reports.sh
###############################################################

# Set the output file
output_dir="/home/repos/Azure_Advisor_Recommendation"
exemption_file="/home/repos/Azure_Advisor_Recommendation/exemptions.json"
email_subject="Azure Advisor Suggestion for Your Subscription"
BODY=$(cat <<EOF
Dear Team,

We wanted to bring to your attention a recent recommendation from Azure Advisor regarding our Azure resources. 
Azure Advisor has suggested an optimization opportunity that could improve our resource utilization and/or enhance our security posture.

Please review the attached file and recommendations and take the appropriate actions needed to optimize your Azure resources.

If you have any questions or need further clarification, please feel free to reach out to us.
Thank you for your attention to this matter.

Best regards,
EOF
)

# Login Azure via SP
az login --service-principal --username $username --password $password --tenant $tenant

# Define an array to store subscription IDs and owner email addresses
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

    # create log file
    local report_file="$output_dir/${subscription_name}_advisor_report.txt"
    # the title of the report
    echo "************************************************ General Advisor Report ********************************************" > $report_file
    echo "**************************************************  $(date +'%d-%m-%Y')   ***************************************************" >> $report_file
     
    ## List Azure Advisor recommendations excluding HighAvailability category
    #az advisor recommendation list \
    #  --query "[?category != 'HighAvailability'].{category: category, impact: impact, impactedField: impactedField, resourceId: resourceMetadata.resourceId, resourceGroup: resourceGroup, problem: shortDescription.problem}" \
    #  --output json | \
    #jq -r '.[] | "Category     : \(.category)\nImpact       : \(.impact)\nImpactedField: \(.impactedField)\nResourceGroup: \(.resourceGroup)\nProblem      : \(.problem)\nResourceId   : \(.resourceId)\n"' >> $report_file

       
    # List Azure Advisor recommendations excluding HighAvailability category
    az advisor recommendation list \
          --query "[?category != 'HighAvailability'].{category: category, impact: impact, impactedField: impactedField, resourceId: resourceMetadata.resourceId, resourceGroup: resourceGroup, problem: shortDescription.problem}" \
          --output json | \
    jq -r --argfile exemptions "$exemption_file" '
    .[] as $recommendation |
    select( any( $exemptions[]; .problem == $recommendation.problem ) | not ) |
    "Category     : \($recommendation.category)\nImpact       : \($recommendation.impact)\nImpactedField: \($recommendation.impactedField)\nResourceGroup: \($recommendation.resourceGroup)\nProblem      : \($recommendation.problem)\nResourceId   : \($recommendation.resourceId)\n"' >> $report_file

    # Send email notification
    send_email "$owner_email" "$report_file"
}

# Function to send an email with the report attached
send_email() {
    local recipient=$1
    local report_file=$2
    
    # Check if the report file is empty
    if grep -q "Category" "$report_file"; then
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
