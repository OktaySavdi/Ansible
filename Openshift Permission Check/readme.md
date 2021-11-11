**Required**
```
kubectl-who-can - > https://github.com/aquasecurity/kubectl-who-can/releases
```

**Check Syntax**
```
ansible-playbook -i inventory.yaml delete_project.yaml --syntax-check
```
**Run Playbook**
```
ansible-playbook -i inventory.yaml all.yaml --extra-vars
```
