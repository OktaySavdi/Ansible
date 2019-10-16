# Ansible Elasticserach Cluster  + Kibana

-   Ansible 2.8.5
-   Compatible with most versions of RHEL 7.6
  
![image](https://user-images.githubusercontent.com/3519706/66905789-340db500-f00f-11e9-9cad-050a1f37e110.png)

**Structure of automation**

![2019-10-15 13_02_59-2019_10_15_12_59_18_02_Redis_Cluster_Kur _BookStack png - Paint](https://user-images.githubusercontent.com/3519706/66905959-7b944100-f00f-11e9-8bfb-4d697a46f88a.png)


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

Check Syntax

    ansible-playbook playbook.yml -i inventor.txt --syntax-check

Run Playbook

    ansible-playbook playbook.yml -i inventor.txt

## Check Elasticsearch + kibana

Control Nodes

    curl 10.10.10.10:9200/_cat/nodes?v
Control Cluster

    curl -X GET "10.10.10.10:9200/_cluster/health?pretty"

## Service Status

    systemctl status elasticsearch
    systemctl status kibana
