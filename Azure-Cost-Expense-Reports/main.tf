- name: Check Azure Cost Expense
  hosts: jumpserver  # Run the task on the Ansible control node
  gather_facts: no  # We don't need facts for this task
  vars_files:
    - vault.yaml
  tasks:
    - name: Clone Private Git Repo
      git:
        repo: "https://oauth2:{{ svc_token }}@mygitaddress.com/repo/Script.git"
        dest: "/opt/repos"
        update: yes
        force: yes
        clone: yes
      no_log: true
    
    - name: Set Executable Mode for azure_cost_expense_reports.sh
      become: true
      file:
        path: "/opt/repos/Azure_Cost_Expense_Reports/azure_cost_expense_reports.sh"
        mode: "a+x"

    - name: Run Azure Cost Expense
      shell: |
        sed -i -e 's/\r$//' /opt/repos/Azure_Cost_Expense_Reports/azure_cost_expense_reports.sh
        "/opt/repos/Azure_Cost_Expense_Reports/azure_cost_expense_reports.sh"
      environment:
        username : "{{ username }}"
        password : "{{  password }}"
        tenant : "{{ tenant }}"
      no_log: true
