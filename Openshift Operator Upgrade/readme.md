

# Ansible Openshift Application Dump

-   Ansible 2.8.5
-   Openshift cluster 4.x
  
## Getting started

**Check Syntax**

    ansible-playbook playbook.yml -i inventor.ini --syntax-check

**Run Playbook**

    ansible-playbook playbook.yml -i inventor.ini --extra-vars "actions=get cluster=<clustername> namespace=<namespace> InstallPlan=< InstallPlan version> mail=<e-mail>"
    
    ansible-playbook playbook.yml -i inventor.ini --extra-vars "actions=update cluster=<clustername> namespace=<namespace> InstallPlan=< InstallPlan version> mail=<e-mail>"
