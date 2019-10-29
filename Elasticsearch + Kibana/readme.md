
# Ansible Elasticsearch Cluster  + Kibana

-   Ansible 2.8.5
-   Compatible with most versions of RHEL 7.6
  
![elasticsearch cluster](https://user-images.githubusercontent.com/3519706/66912891-31658c80-f01c-11e9-8f78-f9d6d086c94d.png)

**Structure of automation**

![elasticsearch tophology](https://user-images.githubusercontent.com/3519706/66905959-7b944100-f00f-11e9-8bfb-4d697a46f88a.png)


## Installation

I use a **nexus server** because my computer cannot access the **internet**. 
you may not use nexus so install the version you want to download **.rpm** 
files and put them to the address below.

Download: [Elaticsearch](https://www.elastic.co/downloads/elasticsearch)

Download: [Kibana](https://www.elastic.co/products/kibana)

> elasticsearch*.rpm

> kibana*.rpm

    roles/elk_install/files

and change this field

    roles/elk_install/vars/main.yml

>    **es_rpm**: elasticsearch-7.4.0-x86_64.rpm

>    **kibana_rpm**: kibana-7.4.0-x86_64.rpm
>    
if you have an internet-connected machine, do the following

change this field

    #copy Elasticsearch rpm file
        - name: Copy Elasticsearch RPM to /root
	      copy:
	        src: "{{ es_rpm }}"
	        dest: "{{ es_rpm }}"
          
    #install Elasticsearch on Nexus
       - name: install Elasticsearch
         yum:
	       name: "{{ es_rpm }}"
	       state: present

as follows

    #install RabbitMQ on Nexus
        - name: install RabbitMQ
          yum:
	        name: "{{ item }}"
	        state: present
         with_items:
	       - "http://(elastic rpm URL)/elastic*.rpm"
	       - "http://(kibana rpm URL)/kibana*.rpm"



**Check Syntax**

    ansible-playbook playbook.yml -i inventor.txt --syntax-check

**Run Playbook**

    ansible-playbook playbook.yml -i inventor.txt

## Check Elasticsearch + Cluster + Kibana

Control Nodes

    curl 10.10.10.10:9200/_cat/nodes?v
Control Cluster

    curl -X GET "10.10.10.10:9200/_cluster/health?pretty"

Control Kibana

    curl  http://10.10.10.10:5601/app/kibana

## Service Status

    systemctl status elasticsearch
    systemctl status kibana
