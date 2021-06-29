
# Ansible Installation Automation

-   Ansible 2.8.5
-   Compatible with most versions of RHEL 7.6


**We did 6 installation on Ansible**
1. Ansible Create VM From Template VMWARE

2. Ansible Elasticsearch Cluster + Kibana

3. Ansible Kafka Cluster

4. Ansible RabbitMQ Cluster + SSL

5. Ansible Redis Cluster + Stunnel

6. Ansible Redis-Sentinel + Stunnel

7. Ansible Jboss EAP Domain Controller

8. Openshift Application Dump

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
