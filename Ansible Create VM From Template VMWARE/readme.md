

# Ansible Create VM From Template VMWARE

**Description**
Playbook and role to deploy multiple vSphere virtual machines from a template using Ansible

**Requirements**

 - Python (python27) 
 - Ansible (≥ 2.8.5)
 - PyVmomi
 
 ![Ansible-vmware](https://user-images.githubusercontent.com/3519706/67880393-9b6b4f00-fb4f-11e9-9275-3694f6f8b525.png)

**Configuration**

The required files are:

![image](https://user-images.githubusercontent.com/3519706/67881469-9effd580-fb51-11e9-9592-dd2f456c5223.png)

Edit the main.yml file to define the servers of virtual machines you want to deploy, as well as their names, datastore, IP and notes.

    roles\servers\vars\main.yml

Edit the main.yml file to define the vcenter info

    roles\vcenter\vars\main.yml

## Install PreRequest For VmWare

    yum install -y python27-python-pip
    scl enable python27 bash
    which pip
    pip -V
    pip install pyvmomi

## Execution

    ansible-playbook vm.yml

if it gets error

    ansible-playbook vm.yml -e 'ansible_python_interpreter=/opt/rh/python27/root/usr/bin/python2'

## Result
![image](https://user-images.githubusercontent.com/3519706/67881283-4597a680-fb51-11e9-891b-3f068edc06b0.png)
