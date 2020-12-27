

# Ansible Openshift Application Dump

-   Ansible 2.8.5
-   Openshift cluster 4.x
  
![image](https://user-images.githubusercontent.com/3519706/103170772-0568ac80-4858-11eb-89b7-79bd89796506.png)

## Getting started

With this automation, all cpu, memory, top and gc dump operations will be taken automatically.


**Check Syntax**

    ansible-playbook playbook.yml -i inventor.ini --syntax-check

**Run Playbook**

    ansible-playbook playbook.yml -i inventor.ini --extra-vars "pod_name=<pod_name> choose=memory cluster=<clustername>"

