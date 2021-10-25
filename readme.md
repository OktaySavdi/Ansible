
# Ansible Installation Automation

-   Ansible 2.8.5
-   Compatible with most versions of RHEL 7.6

# Ansible API

Ansible Tower API Example - https://docs.ansible.com/ansible-tower/latest/html/towerapi/api_ref.html

Curl Command Example - https://docs.ansible.com/ansible-tower/3.2.5/html/administration/tipsandtricks.html#launching-jobs-with-curl 

### Action Job
```bash
curl -f -k -H 'Content-Type: application/json' -XPOST \
-d '{"extra_vars": "{\"user\": \"oktay\", \"lastname\": \"savdi\", \"country\": \"tr\" }"}' \
--user myuser:mypassword https://myansible-srv/api/v2/job_templates/{{template_id}}/launch/

curl -f -k -H 'Content-Type: application/json' -XPOST \
-d '{"extra_vars": "{\"user\": \"oktay\", \"lastname\": \"savdi\", \"country\": \"tr\" }"}' \
--user myuser:mypassword https://myansible-srv/api/v2/job_templates/93/launch/
```
### Job Output
```ruby
curl --user myuser:mypassword https://myansible-srv/api/v2/jobs/{{job_id}}/stdout/?format=txt
curl --user myuser:mypassword https://myansible-srv/api/v2/jobs/122/stdout/?format=txt
curl --user myuser:mypassword https://myansible-srv/api/v2/jobs/122/stdout/?format=json
```
