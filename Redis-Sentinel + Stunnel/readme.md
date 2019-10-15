# Ansible Redis-Sentinel  + Stunnel

-   Ansible 2.8.5
-   Compatible with most versions of RHEL 7.6
-   Redis-Sentinel and Stunnel configuration

![2019-10-15 13_12_04-Redis - oktaysavdi@gmail com - Evernote](https://user-images.githubusercontent.com/3519706/66822732-8090bc00-ef4d-11e9-8e82-a5d1ee3cca01.png)

**Structure of automation**

![2019-10-15 13_16_33-2019_10_15_12_59_18_02_Redis_Cluster_Kur _BookStack png - Paint](https://user-images.githubusercontent.com/3519706/66823067-204e4a00-ef4e-11e9-9327-f753be68981d.png)


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

## Check Redis-Sentinel

    redis-cli -h (server-ip) -p 26101 -a (auth password) sentinel info

with Stunnel

    redis-cli -h 127.0.0.1 -p 26101 -a wzBdwbRz3nK5AUiw6xL553dorhbGsYpfH7sgf5MT sentinel info

without Stunnel

    redis-cli -h 10.10.10.10 -p 6101 -a wzBdwbRz3nK5AUiw6xL553dorhbGsYpfH7sgf5MT sentinel info

## Service Status

    systemctl status stunnel
    systemctl status redis_6101
    systemctl status redis_26101
