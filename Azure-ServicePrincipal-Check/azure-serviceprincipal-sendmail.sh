#!/bin/bash
###############################################################
##  Name:  Oktay SAVDI
##  Date:  01.05.2024
##  Call:  ./azure-serviceprincipal-sendmail.sh
###############################################################

# Email configuration
email_subject="[ Warning ] - Service Principal Security Compliance"
cc_recipient="mymail@gmail.com"
BODY=$(cat <<EOF
Dear Team,

We are writing to you about our Azure service principals and their compliance with our company's security standards. 
We have found that client secrets that have been identified for over a year do not meet company standards.

Azure service principals play a crucial role in securing our cloud infrastructure, and ensuring that they meet our security standards is of paramount importance. 
This ensures the safety of our data and resources and mitigates potential security risks.

Action Required:
  - Immediate Review: We request that you initiate an immediate review of all Azure service principals associated with client secrets that are not in compliance with our standards.
  - Remediation: Any non-compliant service principals must be brought into compliance as soon as possible. This includes updating client secrets, following best practices for secret management, and addressing any other security gaps.

Please provide an update on the actions taken and the progress of the remediation efforts within 14 days. 
If you require assistance or additional resources, please do not hesitate to reach out to our security/compliance teams.

Your cooperation in addressing this matter is critical, and we appreciate your prompt attention to this issue. 

Thank you,
<My Team>
EOF
)
        
az login --service-principal --username $username --password $password --tenant $tenant

# Set the output file
out_file="/opt/repos/Azure_ServicePrincipal/incompatible-serviceprincipals.log"

# Function to check if a resource is exempted
is_resource_exempted() {
    local exempted_resource=$1
    local exempted_file="/opt/repos/Azure_ServicePrincipal/exempted_resources.txt"

    # Check if the resource_id is in the exempted resources list
    if grep -qFx "$exempted_resource" "$exempted_file"; then
        return 0  # Resource is exempted
    else
        return 1  # Resource is not exempted
    fi
}

check_sp_sendmail() {        
          
    # Get the list of all Azure AD Applications and store the output in a variable
    for app_id in $(az ad app list --query "[].{AppId: appId}" --output tsv); do
    
        # Get the Azure AD Application details and store the output in a variable
        app_details=$(az ad app show --id $app_id --output json)
        # Extract the DisplayName using jq
        display_name=$(echo "$app_details" | jq -r '.displayName')
       
        #find the mail addres of owners
        receivers=$(az ad app owner list --id $app_id --query "[].userPrincipalName" -o json)    
    
        # Extract and concatenate the email addresses into a single line with comma separation
        recipient=$(echo "$receivers" | jq -r '. | join(",")')
        if [ "$receivers" == "[]" ]; then
           recipient=$cc_recipient
        fi 
       
        # Get the client secrets for the current App Registration
        client_secrets=$(az ad app credential list --id $app_id --query "[].{startDateTime: startDateTime, endDateTime: endDateTime}" -o tsv)
        
        # Loop through the client secrets
        while read -r start_date end_date; do
            # Check if both start and end dates exist
            if [ "$start_date" != "null" ] && [ "$end_date" != "null" ]; then
                # Convert dates to Unix timestamps
                start_timestamp=$(date -u -d "$start_date" +%s)
                end_timestamp=$(date -u -d "$end_date" +%s)

                # Format dates to desired format
                formatted_start_date=$(date -u -d "$start_date" '+%d-%m-%Y')
                formatted_end_date=$(date -u -d "$end_date" '+%d-%m-%Y')

                # Calculate the difference in seconds (1 year = 31536000 seconds)
                one_year_in_seconds=31536000
                difference=$((end_timestamp - start_timestamp))

                expiry_days="$(( ($end_timestamp - $start_timestamp) / (3600 * 24) ))"
                
                # Check if the difference is greater than 1 year
                if [ $difference -gt $one_year_in_seconds ]; then
                    if ! is_resource_exempted "$display_name"; then

                        # the title of the report
                        echo "****************************************** General Service Principals Report ***************************************" > $out_file
                        echo "**************************************************  $(date +'%d-%m-%Y')   ***************************************************" >> $out_file
                        echo "========================================================================================================================" >> $out_file
                        echo "Status     |       DisplayName      |       Total_Date      |       Start Date      |       End Date" >> $out_file
                        echo "========================================================================================================================" >> $out_file

                        echo "[Warning] | $display_name | $expiry_days | $formatted_start_date | $formatted_end_date" >> $out_file                   
                        # Check if the report file is empty
                        if grep -q "\[Warning\]" "$out_file"; then
                            # Send email to the specific owner_email
                            send_email "$recipient" "$out_file" "$cc_recipient"
                        fi
                    fi                    
                fi
            fi
        done <<< "$client_secrets"
    done
}

# Function to send an email with the report attached
send_email() {
    local recipient=$1
    local attachment=$2
    local cc_recipient=$3

    # Use mail command to send the email with the attachment
    echo -e "$BODY" | mail -s "$email_subject" -c "$cc_recipient" -a "$attachment" "$recipient" 
}

# Call the function to list service principals
check_sp_sendmail
