
# Ansible Jboss EAP 7 Domain Controller

-   Ansible 2.8.5
-   Compatible with most versions of RHEL 7.6
-   Jboss Cluster 
  
![image](https://user-images.githubusercontent.com/3519706/82335152-9db0d000-99f1-11ea-85d3-a9cefbf5def4.png)


**Structure of automation**

![image](https://user-images.githubusercontent.com/3519706/66905959-7b944100-f00f-11e9-8bfb-4d697a46f88a.png)

## Getting started

Below are a few example playbooks and configurations for deploying a variety of Jboss architectures.
This role expects to be run as root

**Check Syntax**
```ruby
ansible-playbook playbook.yml -i inventor.ini--syntax-check
```
**Run Playbook**

    ansible-playbook playbook.yml -i inventor.ini

## Check Jboss Cluster
```ruby
http://10.10.10.10:9990/console/index.html
```  
![image](https://user-images.githubusercontent.com/3519706/82335751-71498380-99f2-11ea-9d2f-dd3032e36077.png)

## Service Status

    systemctl status jboss-eap-rhel
