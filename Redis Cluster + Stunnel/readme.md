# Ansible Redis Cluster

-   Ansible 2.8.5
-   Compatible with most versions of RHEL 7.6
-   redis cluster and stunnel configuration
  
![2019-10-15 12_56_33-Redis - oktaysavdi@gmail com - Evernote](https://user-images.githubusercontent.com/3519706/66821660-75d52780-ef4b-11e9-8366-d5b37ebfdce6.png)

**Structure of automation**

![2019-10-15 13_02_59-2019_10_15_12_59_18_02_Redis_Cluster_Kur _BookStack png - Paint](https://user-images.githubusercontent.com/3519706/66822082-32c78400-ef4c-11e9-845b-cd3e0062968a.png)


**Stunnel for installation**

if installation with stunnel

    /roles/redis_install/vars/

change value (true/false)

    stunnel_install: 'true'

## Installation

Check Syntax

    ansible-playbook playbook.yml -i inventor.txt --syntax-check

Run Playbook

    ansible-playbook playbook.yml -i inventor.txt

## Check Redis Cluster

    redis-cli -h (server-ip) -p 6101 -a (auth password) cluster nodes

with Stunnel

    redis-cli -h 127.0.0.1 -p 6101 -a wzBdwbRz3nK5AUiw6xL553dorhbGsYpfH7sgf5MT cluster nodes

without Stunnel

    redis-cli -h 10.10.10.10 -p 6101 -a wzBdwbRz3nK5AUiw6xL553dorhbGsYpfH7sgf5MT cluster nodes

## Service Status

    systemctl status stunnel
    systemctl status redis_6101
    systemctl status redis_6102
