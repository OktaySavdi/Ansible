### Openshift project creations

### Python PIP dependencies: 

 - openshift
 - pyyaml
 - kubernetes
 - kubernetes-validate

### installation for requirements
```bash
yum install python36  
python3 -m pip openshift pyyaml kubernetes kubernetes-validate
```

**Check Syntax**

    ansible-playbook ocp_create_project_tasks.yml -i inventory/inventory.yaml --syntax-check

**Run Playbook**

    ansible-playbook ocp_create_project_tasks.yml -i inventory/inventory.yaml --extra-vars "prj_action=create prj_name=oktay prj_owner=bank" -vvv
