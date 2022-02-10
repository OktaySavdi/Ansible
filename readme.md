
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

## GIT
```
.gitignore
git init
git config --list --show-origin

git config --global user.name "cloud.user"
git config --global user.email "cloud@email.com"
git config --global push.default simple

git config --global credential.helper cache
git config --global credential.helper 'cache --timeout=3600'

git config --system --list
git config --list
cat ~/.gitconfig

git clone username@host:/path/to/repository

git status
git log

git rm myfiles.txt --cache

git diff
git merge development #birleştirme işlemi yapar
git revert --no-edit HEAD #değişikliği geri alır

git init
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/OktaySavdi/deneme.git
git push -u origin main

git add README.md
git commit -a

git branch lab
git checkout lab
git checkout -b lab2
git push origin lab
git push --set-upstream origin lab
```
## Inventory
```
[server01]
server01 ansible_host=10.10.10.10 ansible_ssh_pass=xxx ansible_ssh_user=user
10.10.10.11 ansible_ssh_pass=xxx ansible_ssh_user=user

server2 ansible_ssh_host=192.168.1.10
```
  

### Special Inventory Variables

There are a number of variables that you can use to change how Ansible will connect to a host
listed in the inventory. Some of these are most useful as host-specific variables, but others might
be relevant to all hosts in a group or in the inventory.
```
ansible_connection
ansible_host
ansible_port
ansible_user
ansible_become_user
ansible_python_interpreter
```
### Identifying the Current Host Using Variables

When a play is running, there are a number of variables and facts that can be used to identify the name of the current managed host executing a task
``` 
inventory_hostname
ansible_host
ansible_facts['hostname']
ansible_facts['fqdn']
```
### Nested Group
```
[webserver]
k8s-infra01

[k8s-infra01]
bastion-k8s

[k8s-all:children]
bastion
webserver

[k8s-all:vars]
smtp_relay: smtp.lab.example.com
```
### Yaml
```yaml
lb_servers:
  hosts:
    servera.lab.example.com:
web_servers:
  hosts:
    serverb.lab.example.com:
    serverc.lab.example.com:
backend_server_pool:
  hosts:
    server[b:f].lab.example.com:
```
```yaml
all:
  hosts:
    bastion-k8s:
      ansible_host: 10.10.10.10
    k8s-infra01:
      ansible_host: 10.10.10.11
  vars:
    smtp_relay: smtp.lab.example.com
  children:
    bastion:
      hosts:
        bastion-k8s
      vars:
        my_value: my_responce
    webserver:
       hosts:
         k8s-infra01
         k8s-worker01
    k8s-all:
      children:
        bastion:
        webserver:
```
```yaml
dev:
  hosts:
    bastion-k8s:
      ansible_host: 10.175.10.98
    vars:
      http_port=80
      proxy=proxy.webserver.com
    k8s-infra01:
      ansible_host: 10.175.10.97
    vars:
      http_port=80
      proxy=proxy.webserver.com
  children:
    bastion:
      hosts:
        bastion-k8s
    webserver:
       hosts:
         k8s-infra01
         k8s-worker01
    k8s-all:
      children:
        bastion:
        webserver:
```
```yaml
dev:
  hosts:
    bastion-k8s:
      ansible_host: 10.175.10.98
      usr: 'myuser1'
      passwd: "{{ project_password }}"
      ocp_cluster_name: mycluster1
    k8s-infra01:
      ansible_host: 10.175.10.97
      usr: 'myuser2'
      passwd: "{{ project_password }}"
      ocp_cluster_name: mycluster2
  vars:
     http_port=80
     proxy=proxy.webserver.com
     prj_action: create
     new_quota: ml
```
### Converting from INI to YAML
```
ansible-inventory --yaml -i origin_inventory --list --output destination_inventory.yml
```
## Managing Task Execution

### Privilege Escalation by Configuration
| Configuration or Playbook Directive | Connection Variable |
|--|--|
| become | ansible_become |
| become_method | ansible_become_method |
| become_user | ansible_become_user |
| become_password | ansible_become_pass |

### Privilege Escalation in Tasks
```yaml
- name: Play with two tasks, one uses privilege escalation
  hosts: all
  become: false #
  tasks:
    - name: This task needs privileges
      yum:
        name: perl
        state: installed
      become: true #
```
### Privilege Escalation in Blocks
```yaml
- block:
  - name: Ensure httpd is installed
    yum:
      name: httpd
      state: installed
  - name: Start and enable webserver
    service:
      name: httpd
      state: started
      enabled: yes
  become: true 
```
### Privilege Escalation in Roles
```yaml
- name: Example play with one role
  hosts: localhost
   roles:
     - role: role-name
       become: true
```
```yaml
```
```yaml
```
```yaml
```
