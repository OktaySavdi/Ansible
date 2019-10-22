
# Ansible Redis Cluster + Stunnel

-   Ansible 2.8.5
-   Compatible with most versions of RHEL 7.6
-   Redis cluster and Stunnel configuration
  
![2019-10-15 12_56_33-Redis - oktaysavdi@gmail com - Evernote](https://user-images.githubusercontent.com/3519706/66821660-75d52780-ef4b-11e9-8366-d5b37ebfdce6.png)

**Structure of automation**

![2019-10-15 13_02_59-2019_10_15_12_59_18_02_Redis_Cluster_Kur _BookStack png - Paint](https://user-images.githubusercontent.com/3519706/66822082-32c78400-ef4c-11e9-845b-cd3e0062968a.png)


## Getting started

Below are a few example playbooks and configurations for deploying a variety of Redis architectures.
This role expects to be run as root

## Optional Stunnel for installation

change value (**true/false**) on **inventory.txt**

    stunnel_install= "false"

## Certificate

    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/stunnel/redis-server.key -out /etc/stunnel/redis-server.crt

|redis-server.key  |private key  |
|--|--|
| **redis-server.crt** | **public certificate** |


## Installation

I use a **nexus server** because my computer cannot access the **internet**. 
you may not use nexus so install the version you want to download **.rpm** 
files and put them to the address below.

> redis*.rpm

    roles/redis_install/files

and change this field

    roles/redis_install/vars/main.yml

>    **redis_rmp:** redis-5.0.5-1.el7.remi.x86_64.rpm

if you have an internet-connected machine, do the following

change this field

    #copy redis rpm file
    - name: Copy redis RPM to /opt
      copy:
        src: "{{ redis_rmp }}"
        dest: "{{ redis_rmp }}"
    
    #install Redis on Nexus
    - name: install Redis
      yum:
        name: "{{ redis_rmp }}"
        state: present
as follows

    #install Redis on Nexus
    - name: install Redis
      yum:
        name: "http://(redis rpm URL)/redis*.rpm"
        state: present

**Check Syntax**

    ansible-playbook playbook.yml -i inventor.txt --syntax-check

**Run Playbook**

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
