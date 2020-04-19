## Flux7 Trial Project - Aditya Muralidhar

Steps:
aws configure
source ansible/bin/activate
pip3 install -r requirements.txt --no-cache #if new one venv.
terraform init
ansible-playbook -i hosts *.yml

Requirements:
aws configure
terraform bash. 

In scope:
* Linux EC2 instance is running on AWS and is publicly accessible (internet, static IP, linux php server via ansible playbook). 
* Instance is configured with an Ansible playbook.
* The playbook installs a PHP web server and a landing page that says "Welcome to Flux7!"


Present implementation:
* The playbook code is stored in a publicly accessible Git repository.
* Submit your repo link the day before the interview/meeting

Out of scope:
* Security/IAM/AWS Cognito
* Monitoring
* Website configuration
* Route 53
* No EC2 Systems Manager integration. No direct CI/CD integration. 
* ansible vault / hashicorp vault
* associated DBs
* snapshots


Steps: 

config management - Ansible
Orchistration of architecture - Terraform. Pass info back to config layer. 
internal config of ec2 instance - Ansible (instance config, php server + landing page)


TODO:
variables setup.
pip freeze > requirements.txt
make sure the venv doesnt get uploaded to git.
code for ending/shutting down.