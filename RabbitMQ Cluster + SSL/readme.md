
# Ansible Redis Cluster + Stunnel

-   Ansible 2.8.5
-   Compatible with most versions of RHEL 7.6
-   RabbitMQ Cluster and SSL configuration
  
![image](https://user-images.githubusercontent.com/3519706/66912983-61149480-f01c-11e9-98e4-ace7fd7c3aba.png)


**Structure of automation**

![2019-10-15 13_02_59-2019_10_15_12_59_18_02_Redis_Cluster_Kur _BookStack png - Paint](https://user-images.githubusercontent.com/3519706/66905959-7b944100-f00f-11e9-8bfb-4d697a46f88a.png)

## Getting started

Below are a few example playbooks and configurations for deploying a variety of RabbitMQ architectures.
This role expects to be run as root

## Optional RabbitMQ SSL Activation

change value (**true/false**) on **inventory.txt**

    ssl_active=false
   
   ## Certificate
   
Create certs : [URL](https://docs.sensu.io/sensu-core/1.7/reference/ssl/)

**3 types of ssl configuration**

 1. amqp/ssl
 2. inter cluster
 3. rabbitmq console (https)

## Installation

I use a **nexus server** because my computer cannot access the **internet**. 
you may not use nexus so install the version you want to download **.rpm** 
files and put them to the address below.

> erlang*.rpm
>  rabbit*.rpm

    roles/rbtmq_install/files

and change this field

    roles/rbtmq_install/vars/main.yml

> **rbmq_rpm:** rabbitmq-server-3.8.0-1.el7.noarch.rpm 
> **earlang_rpm:** erlang-22.1.3-1.el7.x86_64.rpm

if you have an internet-connected machine, do the following

change this field

    #copy RabbitMQ rpm file
    - name: Copy RPM File to Root
      copy: src={{ item.src }} dest={{ item.dest }}
      with_items:
        - { src: "{{ earlang_rpm }}", dest: "{{ earlang_rpm }}" }
        - { src: "{{ rbmq_rpm }}", dest: "{{ rbmq_rpm }}" }
    
    #install RabbitMQ on Nexus
    - name: install RabbitMQ
      yum:
        name: "{{ item }}"
        state: present
      with_items:
        - "{{ earlang_rpm }}"
        - "{{ rbmq_rpm }}"

as follows

    #install RabbitMQ on Nexus
    - name: install RabbitMQ
      yum:
        name: "{{ item }}"
        state: present
      with_items:
        - "https://www.rabbitmq.com/install-rpm.html#downloads/*.rpm"
        - "https://github.com/rabbitmq/erlang-rpm/releases/*.rpm"

**Check Syntax**

    ansible-playbook playbook.yml -i inventor.txt --syntax-check

**Run Playbook**

    ansible-playbook playbook.yml -i inventor.txt

## Check RabbitMQ Cluster

  with SSL

    http://10.10.10.10:15672
    
![image](https://user-images.githubusercontent.com/3519706/67088580-2c384700-f1ae-11e9-84f8-5114f3da6052.png)

without SSL

    https://10.10.10.10:15671
   
   ![image](https://user-images.githubusercontent.com/3519706/67088837-d1531f80-f1ae-11e9-8531-29c876fadadc.png)

## Service Status

    systemctl status rabbitmq-server
