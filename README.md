# IaaS-assignment

Contents of this github repository are inteded to be used with terraform to deploy a cloud infrastructure in AWS.

To use this script you will need to install [terraform cli](https://developer.hashicorp.com/terraform/downloads).

First, you will need to use terraform login to login into terraform cloud with your credentials. In terraform cloud you will need to create a workspace and an organization. You will also need to link AWS and terraform cloud by AWS key credentials to terraform environment variables from AWS console. Then you will have to change the name of the workspace and organization in the main.tf file to the one you created. If you don't want to utilize terraform cloud, set up the AWS provider with your AWS key credentials in main.tf file.

First run **terraform init** command to initialize terraform and its modules. Then run **terraform plan** command to preview the changes to the cloud infrastructure. To apply these changes run **terraform apply** commad. Then log into AWS console to see the resulting cloud infrastructure.

The main.tf script instructs terraform to create 2 EC2 Ubuntu virtual maschine (hereinafter **'VM'**) instances under an Auto-Scaling-Group. These instances are configured to run apache2 web server. You can modify the existing virtual maschine configuration by editing the userDataScript.sh file. This group will be scaled down to one instance from 18:00 PM CET until 08:00 AM CET (Mon-Fri) using an auto scaling schedule. All requests intended for instances will go thourgh a load balancer configured to listen on port 80. The script will output the URL of the load balancer, which can be used to request the default HTTP page hosted on VMs.

I chose terraform to use build the cloud infrastructure because it relatively easy to use and can communicate with many platforms, not just AWS.
