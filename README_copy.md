README.md: deploy public php server on AWS with terraform and ansible. 

Infra:
* security groups
* ELB/ALB. 
* key-pair
* VPC
* PHP server
* IGW

--------------------------------------------------------------------------------

### TODO
* seperate out key pair to vault, either tf vault/ansible vault, pass that through to tf.
* delete everything
* We're going to launch into the same subnet as our ELB. In a production environment it's more common to have a separate private subnet for backend instances.
* split into multiple tasks/pipelines
* entire stack monitoring. either via cloudtrial (who makes changes to the servers, etc) or cloudwatch
* Route53
* other REST-API connections
* rollback 
* termination protection
* Autoscaling
* remove ssh access from anywhere. 
* http instead of https
* Integrate other APIs.
* Separate into several ansible tasks.
* Instead, generate a private key file outside of Terraform and distribute it securely to the system where Terraform will be run. {ansible vault, etc}. Or use a seperate ansible task to connect via ssh to ec2 instance.
* vars.tf, output.tf, split up the tf deployments



Flux7 How would you change things if you had time:

* ALB, autoscaling if necessary. 
* Integrate other APIs.
* Separate into several ansible tasks. (I can actually do that now).but how do you pass that out and back into TF
* ansible vault of ssh key storage. 


