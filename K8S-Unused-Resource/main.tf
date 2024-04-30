- name: Check TKG Unused resources
  hosts: jumpserver  # Run the task on the Ansible control node
  gather_facts: no  # We don't need facts for this task
  vars_files:
    - vault.yaml
  tasks:
     - name: Clone Private Git Repo
       git:
         repo: "https://oauth2:{{ svc_token }}@myrepo.com/Script.git"
         dest: "/opt/repos"
         update: yes
         force: yes
         clone: yes
       no_log: true
    
     - name: Set Executable Mode for script
       become: true
       file:
         path: "/opt/repos/K8S_Orphan_Resource/tkg_orphan_resources_reports.sh"
         mode: "a+x"

     - name: Run TKG Unused Automation
       shell: "/opt/repos/K8S_Orphan_Resource/tkg_orphan_resources_reports.sh"
       environment:
         tkc_stg_pass : "{{ tkc_stg_pass }}"
         tkc_stg_server : "{{  tkc_stg_server }}"
         tkc_stg_username : "{{ tkc_stg_username }}"
         tkc_prod_pass : "{{ tkc_prod_pass }}"
         tkc_prod_server : "{{ tkc_prod_server }}"
         tkc_prod_username : "{{ tkc_prod_username }}"
       no_log: true
