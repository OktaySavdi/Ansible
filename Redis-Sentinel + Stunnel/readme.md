
# Ansible Redis-Sentinel  + Stunnel

-   Ansible 2.8.5
-   Compatible with most versions of RHEL 7.6
-   Redis-Sentinel and Stunnel configuration

![redis sentinel ssl stunnel](https://user-images.githubusercontent.com/3519706/66822732-8090bc00-ef4d-11e9-8e82-a5d1ee3cca01.png)

**Structure of automation**

![redis sentinel tophology](https://user-images.githubusercontent.com/3519706/66823067-204e4a00-ef4e-11e9-9327-f753be68981d.png)


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

## Check Redis-Sentinel

    redis-cli -h (server-ip) -p 26101 -a (auth password) sentinel info

with Stunnel

    redis-cli -h 127.0.0.1 -p 26101 -a wzBdwbRz3nK5AUiw6xL553dorhbGsYpfH7sgf5MT info

without Stunnel

    redis-cli -h 10.10.10.10 -p 6101 -a wzBdwbRz3nK5AUiw6xL553dorhbGsYpfH7sgf5MT info

## Service Status

    systemctl status stunnel
    systemctl status redis_6101
    systemctl status redis_26101
