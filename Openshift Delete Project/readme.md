**Check Syntax**
```
ansible-playbook -i inventory.yaml delete_project.yaml --syntax-check
```
**Run Playbook**
```
ansible-playbook -i inventory.yaml delete_project.yaml --extra-vars "cluster=ocp-cluster1 namespace=oktay" -vvv
```
