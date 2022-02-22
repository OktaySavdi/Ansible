### Help commands 
```
ansible-doc yum | grep -i example -A 20
ansible-doc -l | grep ntp
ansible-doc -t callback -l
ansible-doc -t -l lookup 
ansible-doc -t lookup k8s

--sytax-check   -> does playbook validation
--check         -> dry-run (but no certainty. tells not to use)
ansible-lint    -> gives information about the format
```
### CLI 
```
ansible-playbook --syntax-check
ansible -m ping -i inventory.yml all
ansible servers --list-hosts
ansible ungrouped --list-hosts
ansible localhost --list-hosts
ansible all --list-hosts
```
### SSH
```
ssh-keygen
ssh-copy-id -i ~/.ssh/id_rsa.pub $host; 
```
### Parse
```
debug: msg="{{ hostvars[groups['bastion'][0]].ip }}"
debug: msg="{{ groups['master'][0] }}"
loop: "{{ groups['lbservers'] }}"
```
### Vault
```
ansible-vault encrypt vars/myvar1.yaml
ansible-vault view vars.yaml
ansible-playbook playbok.yaml --ask-vault-pass
ansible-playbook play1.yaml --vault-id ali@promp --vault-id veli@promp
```
### Backup - Restore
```
./setup.sh -b
./setup.sh -r # restore latest backup
./setup.sh -r /tmp/tower-backup-2022-05-10-18:04:19.tar.gz # restore specific backup
```
### Galaxy
```
ansible-galaxy init kubernetes
ansible-galaxy list
ansible-galaxy search --help
ansible-galaxy install (we can call the role)
```
### Ansible Config
```
./ansible.cfg
~/ansible.cfg
/etc/ansible/ansible.cfg
export ANSIBLE_CONFIG=myfile
```
### Run order of Ansible jobs
```
pre_tasks
roles
tasks
post_tasks
handlers
```
### Inventory Vars
```
- hosts: bastion
  gather_facts: false
  vars:
    dns: 10.10.10.10
  vars_files:
  - /path/external_vars.yml #change
  tasks:
    - name: "{{ lab }}"
      vars:
        lab: myvar
```
### Info 
```
lookup      -> can be used to view files
delegate_to -> used if the place where the action needs to be done is elsewhere
hostvars    -> used to get host's variable
serial      -> allows you to process batches in batches (25%,50%,100%)
run_once    -> used if it is desired to run once in each batch
script      -> Allows a local script to be run on the server you want to run. It has a parameter called Creates. This makes the script idempotent.

# All three are not idempotent and therefore not recommended.
command -> module is running job on sub system. via python. pipe or special commands like shell won't work (wants it to be python)
shell   -> shell specific
raw     -> used to run ssh with raw, if there is no python, it bypasses the ansible module subsystem.

Tower   -> If you don't assign it to the credential organization, it will be private. System admin just used

Import_role  -> If there is a syntax error, it will be seen from the beginning
include_role -> syntax error when it is executed and when it reaches that stage.

Fork   -> does each task a certain number of times, how many servers should I connect to at the same time. The purpose of the fork is performance.
Serial -> runs the complete playbook on so many servers. it can also be given as a percentage. To test the playbook a certain number of times by dividing it into serial sets, to progress in a controlled manner.
```
### Import and Include
```yaml
include_tasks: bootstrap-redhat.yml
include_vars: "{{ item }}"
import_tasks: 0020-verify-settings.yml
import_playbook: deploy_apache.yml

# Import Role
import_role:
  name: etcdctl

# Include Role
include_role:
  name: myrole
    
# Import Playbook
- name: Deploy Web App
  import_playbook: deploy_webapp.yml
```
## #Ansible API

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

## #GIT
Documents
```
https://marklodato.github.io/visual-git-guide/index-en.html
https://www.youtube.com/watch?v=FyAAIHHClqI
https://www.youtube.com/watch?v=Gg4bLk8cGNo
```
```
alias graph='git log --all --decorate --oneline --graph'

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
## #Inventory
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
      ansible_become: true
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
    ansible_become: true
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
### Defining Smart Host Filters
```
ansible_facts.ansible_distribution:RedHat
ansible_facts.ansible_pkg_mgr:yum
```
## #Managing Task Execution

### Privilege Escalation by Configuration
| Configuration or Playbook Directive | Connection Variable |
|--|--|
| become | ansible_become |
| become_method | ansible_become_method |
| become_user | ansible_become_user |
| become_password | ansible_become_pass |

```
vi ansible.cfg
[defaults]
inventory=inventory.yml
remote_user=devops

[privilege_escalation]
become=true
become_method=sudo
become_user=root
become_ask_pass=false
```

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
### Controlling Task Execution
```yaml
- name: operator Upgrade
  hosts: localhost
  connection: local
  gather_facts: false
  become: true
  roles:
      - operator_upgrade
---
- name: Executing a role as a task
  hosts: remote.example.com
  tasks:
    - name: A normal task
      debug:
        msg: 'first task'
    - name: A task to include role2 here
      include_role:
        name: role2
```
### Listening to Handlers
```yaml
- name: Testing the listen directive
  hosts: localhost
  gather_facts: no
  become: no
  tasks:
    - debug:
        msg: Trigerring the handlers
      notify: My handlers
      changed_when: true
  handlers:
  # As an example, this handler is also triggered because
  # its name matches the notification, but no two handlers
  # can have the same name.
  - name: My handlers
    debug:
      msg: Second handler was notified
```
### Controlling Order of Host Execution
```yaml
- name: Testing host order
  hosts: web_servers
  order: sorted
  tasks:
```
```
inventory
  The inventory order. This is the default value.

reverse_inventory
  The reverse of the inventory order.

sorted
  The hosts in alphabetical order. Numbers sort before letters.

reverse_sorted
  The hosts in reverse alphabetical order.

shuffle
  Random order every time you run the play.
```
### Tags
```yaml
roles:
  - { role: databases, tags: ['csh', 'httpd'] }

ansible-playbook tags-exam.yml --list-tags
ansible-playbook -i inventory.yml tags_exam.yml --tags httpd,csh
ansible-playbook -i inventory.yml tags_exam.yml --tags=httpd --limit=httpd
```
```yaml
- name: Setup web services
  hosts: webservers
  tags:
    - setup
```
```yaml
- hosts: bastion
  become: yes
  gather_facts: false
  tasks:
    - name: Install packages
      shell: "echo deneme1"
      tags: csh

    - name: Install packages
      shell: "echo deneme2"
      tags: httpd
    
    - name: Install packages
      shell: "echo deneme3"
      tags: never           # If you assign the never tag to a task or play, Ansible will skip that task or play unless you specifically request it (--tags never).

    - name: Install packages
      shell: "echo deneme4"
      tags: always           # If you assign the always tag to a task or play, Ansible will always run that task or play, unless you specifically skip it (--skip-tags always).
```
### #Optimizing Execution for Speed
```
time ansible-playbook speed_facts.yml
```
**Disabling Fact Gathering**
```
- hosts: lab
  gather_facts: no
```
**Increasing Parallelism**

By increasing the forks value, Ansible runs each task simultaneously on more hosts at a time,
and the playbook usually completes in less time. For example, if you set forks to 100, Ansible
can attempt to open connections to all 100 hosts in the previous example simultaneously. This will
place more load on the control node, which still needs enough time to communicate with each of
the hosts.
```
[user@demo ~]$ cat ansible.cfg
[defaults]
inventory=inventory
remote_user=devops
forks=100 
```
**Avoiding Loops with the Package Manager Modules**

Some modules accept a list of items to work on and do not require the use of a loop. This approach
can increase efficiency, since the module will be called once rather than multiple times.
```yaml
tasks:
- name: Ensure the packages are installed
  yum:
    name: "{{ item }}"
    state: present
  loop:
    - httpd
    - mod_ssl
    - httpd-tools
    - mariadb-server
    - mariadb
    - php
    - php-mysqlnd
---
tasks:
- name: Ensure the packages are installed
  yum:
    state: present
    name: 
      - httpd
      - mod_ssl
      - httpd-tools
      - mariadb-server
      - mariadb
      - php
      - php-mysqlnd
```
**Efficiently Copy Files to Managed Hosts**

it is generally more efficient to use the synchronize module to copy large numbers of
files to managed hosts. This module uses rsync in the background and is faster than the copy
module in most cases.
```yaml
- name: Deploy the web content on the web servers
  hosts: web_servers
  become: True
  gather_facts: False
  tasks:
    - name: Ensure web content is updated
      synchronize:
        src: web_content/
        dest: /var/www/html
```
**Using Templates**
```yaml
- name: Configure the Apache HTTP Server
  hosts: web_servers
  become: True
  gather_facts: False
  tasks:
    - name: Ensure proper configuration of the Apache HTTP Server
      template:
        src: httpd.conf.j2
        dest: /etc/httpd/conf/httpd.conf
```
**Optimizing SSH connections**

Establishing an SSH connection can be a slow process. When a play has many tasks and targets a
large set of nodes, the overall time Ansible spends establishing these connections can significantly
increase the global execution time of your playbook.
```
[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```
**Profiling Playbook Execution with Callback plug-ins**
```
cgcreate -a user:user -t user:user -g cpuacct,memory,pids:ansible_profile
cgexec -g cpuacct,memory,pids:ansible_profile ansible-playbook myhandler.yml
```
```
[user@demo ~]$ cat ansible.cfg
[defaults]
inventory=inventory
remote_user=devops
callback_whitelist=timer, profile_tasks, cgroup_perf_recap

[callback_cgroup_perf_recap]
control_group=ansible_profile
```
## #Processing Variables Using Filters

### Processing Data with Filters
```
{{ myname | capitalize }}
{{ mynumber | string }}
{{ variable | mandatory }} -> The default behavior from ansible and ansible.cfg is to fail if variables are undefined, but you can turn this off.
{{ ( ansible_facts['date_time']['hour'] | int ) + 1 }}
# => "11"
```
### Manipulating Lists
```
{{ [2, 4, 6, 8, 10, 12] | sum }}
# => "42"
{{ [ 2, 4, 6, 8, 10, 12 ] | random }}
# => "4"
{{ [ 2, 4, 6, 8, 10, 12 ] | length }}
# => "6"
{{ [ 2, 4, 6, 8, 10, 12 ] | first }}
# => "2"
{{ [ 2, 4, 6, 8, 10, 12 ] | last }}
# => "12"
```
### Modifying the order of list elements
```
{{ [2, 4, 6, 8, 10, 12] | sort }}
# => "2, 4, 6, 8, 10, 12"
{{ [2, 4, 6, 8, 10, 12] | reverse }}
# => "12,10,8,6,4,2"
```
### Merging lists
```
{{ [ 2, [4, [6, 8]], 10 ] | flatten }}
# => "2,4,6,8,10"
```
### Operating on lists as sets
```
{{ [ 1, 1, 2, 2, 2, 3, 4, 4 ] | unique | list }}
# => "1,2,3,4"
{{ [ 2, 4, 6, 8, 10 ] | difference([2, 4, 6, 16]) }}
# => "8,10"
{{ [ 2, 4, 6, 8, 10 ] | intersect([2, 4, 6, 16]) }}
# => "2,4,6"
{{ [ 2, 4, 6, 8, 10 ] | union([2, 4, 6, 16]) }}
# => "2,4,6,8,10,16"
```
### Manipulating Dictionaries
```
{{ {'A':1,'B':2} | combine({'B':4,'C':5}) }}
# => "A:1,B:4,C:5"
```
### Hashing, Encoding, and Manipulating Strings
```
{{ 'oktay' | hash('sha1') }}
# => "22771aca22f13b0e26b3011542bde186a5c47690"
{{ 'secret_password' | password_hash('sha512') }}
# => "$6$.NrPwkvUvIgPLtov$L4MUNQVBAv0e9lojupUQBUKfRGJuR5jPZCbAYzCQAogwmeclpWr3lNGg4ltsXe2usT.4J/fKbDjQs1NxYUJbV/"
{{ 'âÉïôú' | b64encode }}
# => "w6LDicOvw7TDug=="
{{ 'w6LDicOvw7TDug==' | b64decode }}
# => "âÉïôú"
```
### Formatting Text
```
{{ 'OKTAY' | lower }}
# => "oktay"
{{ 'oktay' | upper }}
# => "OKTAY"
{{ 'oktay' | capitalize }}
# => "Oktay"
```
### Replacing text
```
{{ 'oktay, savdi' | replace('a','**') }}
# => "okt**y, s**vdi"
```
### Manipulating JSON Data
```
{{ hosts | json_query('[*].name') }}
# => "bastion, classroom"
{{ hosts | to_json }}
# => "[{\"name\": \"bastion\", \"ip\": [\"172.25.250.254\", \"172.25.252.1\"]}"
```
### Templating External Data using Lookups
```
{{ lookup('file', '/etc/hosts') }}
# => "127.0.0.1   localhost"
{{ lookup('template', 'roles/deneme/templates/my.template.j2') }}
# => "oktay"
{{ lookup('env','HOSTNAME') }}
# => "bastion-k8s"
{{ lookup('url', 'https://my.site.com/my.file') }}
{{ lookup('file', 'my.file', errors='warn') | default("Default file content") }}
# => "Default file content"
{ query('lines','cat users.txt') }}
# => "deneme"
{{ query('file', '/etc/hosts')}}
# => "127.0.0.1   localhost"
{{ query('fileglob', '~/.bash*') }}
# => "/root/.bash_logout,/root/.bashrc,/root/.bash_history"
```
### Working with Network Addresses Using Filters

| Fact name | Description |
|--|--|
| ansible_facts['dns']['nameservers'] | The DNS nameservers used for name resolution by the managed host.|
|ansible_facts['domain']|The domain for the managed host.|
|ansible_facts['all_ipv4_addresses']| All the IPv4 addresses configured on the managed host.|
|ansible_facts['all_ipv6_addresses']| All the IPv6 addresses configured on the managed host.|
|ansible_facts['fqdn']|The fully-qualified domain name (DNS name) for the managed host.|
|ansible_facts['hostname']|The unqualified hostname, the string in the FQDN before the first period.|
```
{{ my_hosts_list | ipaddr }}
# => "10.10.10.10,10.10.10.11,10.10.10.12"
{{ my_hosts_list | ipaddr('netmask') }}
# => "255.255.192.0,255.255.254.0"
```
The **ipaddr** filter accepts the following options:

**address** : Validates input values are valid IP addresses. If the input includes network prefix, it is stripped
out.

**net** : Validates input values are network ranges and return them in CIDR format.

**host**: Ensures IP addresses conform to the equivalent CIDR prefix format.

**prefix** :  Validates that the input host satisfies the host/prefix or CIDR format, and returns its prefix (size of the network's mask in bits)

**host/prefix** : Validates the input value is in host/prefix format. That is, the host part is a usable IP address on the network and the prefix is a valid CIDR prefix.

**network/prefix** : Validates the input value is in network/prefix format. That is, the network part is the network address (lowest IP address on the network), and the prefix is a valid CIDR prefix.

**public or private** : Validates input IP addresses or network ranges are in ranges that are reserved by IANA to be public or private, respectively.

**size** : Transform the input network range to the number of IP addresses in that range.

**Any integer number (n).** : Transform a network range to the n-th element in that range. Negative numbers return the nth element from last.

**network, netmask, and broadcast** : Validates that the input host satisfies the host/prefix or CIDR format, and transforms it into the network address (applies the netmask to the host), netmask, or broadcast address,respectively.

**subnet** : Validates that the input host satisfies the host/prefix or CIDR format, and returns the subnet containing that host.

**ipv4 and ipv6** : Validates input are valid network ranges and transform them into IPv4 and IPv6 formats,respectively.
```
{{ lookup('dig', 'example.com') }}
{{ lookup('dig', 'example.com', 'qtype=MX') }}
{{ lookup('dig', 'example.com/MX') }}
{{ lookup('dig', 'example.com', '@4.4.8.8,4.4.4.4') }}
{{ query('dig', 'example.com/MX') }}
{{ lookup('dnstxt', ['test.example.com']) }}
```
# #Coordinating Rolling Updates

### Host Delegation 

delegate_to: localhost
```yaml
- hosts: webservers
  serial: 5
  tasks:
    - name: Take out of load balancer pool
      ansible.builtin.command: /usr/bin/take_out_of_pool {{ inventory_hostname }}
      delegate_to: 127.0.0.1 # localhost
```
### Managing Rolling Updates
```
- name: Update Webservers
  hosts: web_servers
  serial: 2

- name: Update Webservers
  hosts: web_servers
  serial: 25%

- name: Update Webservers
  hosts: web_servers
  serial:
    - 1
    - 10%
    - 25%

The first batch contains one host, while the second batch contains 10 hosts (10% of 100). The third
batch processes 25 hosts (25% of 100), leaving 64 unprocessed hosts (1 + 10 + 25 processed).
Ansible continues executing the play in batch sizes of 25 hosts (25% of 100), until there are fewer
than 25 unprocessed hosts remaining. In this example, the remaining 14 hosts are processed in the
final batch (1 + 10 + 25 + 25 + 25 + 14 = 100).
```
### Specifying Failure Tolerance
```
- name: Update Webservers
  hosts: web_servers
  max_fail_percentage: 30%
  serial:
    - 2
    - 10%
    - 100%
```
### Running a Task Once
```
- name: Reactivate Hosts
  shell: /sbin/activate.sh {{ active_hosts_string }}
  run_once: yes
```
# #Tower 
```
cat ~/.tower_cli.cfg
[general]
host = tower.lab.example.com
username = admin
password = redhat 
verify_ssl = false
```
### Tower CLI
```
tower-cli job_template list 
tower-cli job launch --job-template=12
tower-cli job monior 32
tower-cli job launch --job-template=12 --monitor
tower-cli job launch --job-template=12 --monitor --extra-vars="my: value"
tower-cli job lunch -J 'Demo Job Template'

tower-cli job_template create -n API_Create_Users -d "Using API to create users" --project "My Project" --playbook create_users.yml --ask-variable-on-launch TRUE -i PRODUCTION --credential oktaysavdi
```
### Setting Team Roles
```
tower-cli role grant --user 'joe' --target-team 'Operators' --type 'admin'
tower-cli role grant --user 'jennifer' --target-team 'Architects' --type 'read'
```
### Uploading a Static Inventory
```
awx-manage inventory_import --source=inventory/ --inventory-name="My Tower Inventory"
awx-manage inventory_import --source=./my_inventory_file --inventory-name="My Tower Inventory"
awx-manage inventory_import --source=inventory/ --inventory-name="My Tower Inventory" --overwrite
```

### Starting, Stopping, and Restarting Ansible Tower
```
ansible-tower-service
ansible-tower-service status
ansible-tower-service restart
supervisorctl status
```
### Changing the Ansible Tower Admin Password
```
awx-manage changepassword admin

#create a new Ansible Tower superuser, with administrative privileges if needed.
awx-manage createsuperuser
```
### Configuring TLS/SSL for Ansible Tower
The TLS configuration for the Nginx web server is defined in the /etc/nginx/nginx.conf
Nginx configuration file. The server block, which listens for SSL connections on port 443,
contains the relevant configuration directives. In particular, this shows that the TLS certificate is /
etc/tower/tower.cert and the matching private key is /etc/tower/tower.key:
```
server {
    listen 443 default_server ssl;
    listen 127.0.0.1:80 default_server;
    listen [::1]:80 default_server;
    # If you have a domain name, this is where to add it
    server_name _;
    keepalive_timeout 65;
    ssl_certificate /etc/tower/tower.cert; #####change
    ssl_certificate_key /etc/tower/tower.key; #####change
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 1d;
```
```
[root@tower tower]# ls -l /etc/tower/tower.*
-rw-------. 1 awx awx 1281 Mar 31 23:32 tower.cert
-rw-------. 1 awx awx 1704 Mar 31 23:32 tower.key
```
Use the ansible-tower-service restart command to restart Ansible Tower.

### Backing Up and Restoring Ansible Tower
As the root user, locate the Ansible Tower installation directory and change into that directory.

### Backup
```
[root@tower ~]# find / -name ansible*
/root/ansible-tower-setup-bundle-3.3.1-1.el7
[root@tower ansible-tower-setup-bundle-3.3.1-1.el7]# ./setup.sh -b
...output omitted...
RUNNING HANDLER [backup : Remove the backup tarball.] **************************
changed: [localhost] => {"changed": true, "path": "/var/backups/tower/towerbackup-
2017-03-29-08:34:43.tar.gz", "state": "absent"}
PLAY RECAP *********************************************************************
localhost : ok=24 changed=16 unreachable=0 failed=0
```
### Restore
```
[root@tower ansible-tower-setup-bundle-3.3.1-1.el7]# ./setup.sh -r
...output omitted...
00ms", "Result": "success", "RootDirectoryStartOnly": "no",
"RuntimeDirectoryMode": "0755", "SameProcessGroup": "no", "SecureBits":
PLAY RECAP *********************************************************************
localhost : ok=26 changed=18 unreachable=0 failed=0
The setup process completed successfully.
Setup log saved to /var/log/tower/setup-2017-03-30-04:19:05.log
```
or
```
./setup.sh -r # restore latest backup
./setup.sh -r /tmp/tower-backup-2022-05-10-18:04:19.tar.gz # restore specific backup
```
### Ansible Tower Configuration and Log Files
```
The main configuration files for Ansible Tower are kept in the /etc/tower directory.

Perhaps the most important of these files for the Ansible Tower application is the /etc/tower/
settings.py file, which specifies the locations for job output, project storage, and other
directories.

A number of other key files for Ansible Tower are kept in the /var/lib/awx directory. This directory includes:
• /var/lib/awx/public/static: for static root directory (this is the location of your Django based application files).
• /var/lib/awx/projects: projects root directory (in the subdirectories of this directory Ansible Tower will store project based files - for example git repository files).
• /var/lib/awx/job_status: Job status output from playbooks is stored in this file. 

The Ansible Tower application log files are stored in one of two centralized locations:
• /var/log/tower/
• /var/log/supervisor/

Ansible Tower server errors are logged in the /var/log/tower/ directory. Some key files in the /var/log/tower/ directory include:
• /var/log/tower/tower.log, the main log for the Ansible Tower application.
• /var/log/tower/setup*.log, which are logs of runs of the setup.sh script to install, backup, or restore the Ansible Tower server.
• /var/log/tower/task_system.log, which logs various system housekeeping tasks (suchas the removal of the record of old job runs).

The /var/log/supervisor/ directory stores log files for services, daemons, and applications managed by supervisord. 
The supervisord.log file in this directory is the main log file for the service that controls all of these daemons. The other files contain log information about the activity of those daemons.
```
