**Check Syntax**
```
ansible-playbook -i inventory.yaml playbook.yml --syntax-check
```
**Run Playbook**
```
ansible-playbook -i inventory.yaml playbook.yml --extra-vars "cluster=Lab namespace=oktay-prod" -vvv
```
