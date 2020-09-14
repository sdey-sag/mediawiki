# mediaWiki
 Objective
The document describes the installation and configuration of mediaWiki.
Solution
The solution is implemented using Terraform (IaC) and Ansible (Configuration management tool). The mediaWiki application is hosted on AWS EC2 instance and configured with the mysql database.

The source code is available in the gitHub repository: https://github.com/sdey-sag/mediawiki.git for download

Following are the steps that need to be performed for setting up the mediaWiki
Prequesite
The setup requires a Terraform Controller Node (TCN). The following components need to be installed in the TCN server, before running the terraform scripts.

1.	GIT client		(sudo yum install git)
2.	Terraform binary 	(Download from the Terraform website and place the binary in the path)
3.	Python3 and PIP3 	(sudo yum install python3-pip -y)
4.	Ansible		(pip3 install ansible –user)
5.	AWS CLI 		(pip3 install awscli –user)
6.	Boto3			(pip3 install boto3 –user) - For using ansible dynamic inventory plugin for AWS EC2

In this demo the TCN is provisioned as an AWS EC2 t2.micro instance with CentOS 7.

mediaWiki Installation and Setup
Execute the command aws configure on the TCN server to configure the AWS user account access id and secret key and the default region (us-east-1) and output (JSON).

Login to the AWS console and create a custom policy with the below access privileges.





{
	"Version": "2012-10-17",
	"Statement": [{
		"Sid": "CustomPolicyForAWSTerraform",
		"Action": [
			"ec2:*",
			"ssm:Describe*",
			"ssm:Get*",
			"s3:*"
		],
		"Effect": "Allow",
		"Resource": "*"
	}]
}


Create a Role and attach the above policy to the Role and then attach the Role to the TCN EC2 instance.

The terraform commands that will be executed on this TCN instance will make use of the attached privileges to provision AWS resources.

Login to the TCN server. Change to the home directory /home/centos

Download the source code from the gitHub by executing https://github.com/sdey-sag/mediawiki.git

Generate the SSH key pair locally in the TCN server which will be used for the SSH from the TCN to the mediaWiki node. The same key will be configured in the AWS key pair as MyKeyPair. Execute the below command to generate the key pair.

ssh-keygen -t rsa 

The above command will generate the id_rsa and id_rsa.pub under /home/centos/.ssh

Execute the aws create bucket command to create the S3 bucket where the terraform state file will be stored.

aws s3api create-bucket --bucket <s3-bucket-name> --region us-east-1

Now open the backend.tf file under /home/centos/mediawiki and update the S3 bucket name with the above bucket name.

Now the pre configuration steps are done and the scripts are ready for execution.

Go to the directory ~/mediawiki and execute terraform init. This will initialize the Terraform backend with the S3 bucket and download the AWS providr plugins 

 

Same directory execute terraform validate if you want to validate the terraform scripts

 

Now execute terraform plan that will give the details about of the AWS resources that will be provisioned.

 

 

Execute now time terraform apply --auto-approve to start provisioning the AWS resources: VPC, Public Subnet, IGW, Route Table, Security Groups, Key Pair and EC2

 

Once the Terraform scripts are executed, it will then trigger the Ansible playbook install-mediawiki.yml for the installation and configuration of the mediaWiki node.

The playbook will also configure the mysql database that will be later required later to configure on the mediaWiki page.

Note: In the below screen shot the MediaWiki-Host-PublicIP will output the Public IP of the mediaWiki node and the same will be used to access the mediaWiki page on the browser.

http://<MediaWiki-Host-PublicIP>/mediawiki

 

 

Access the URL: http://<MediaWiki-Host-PublicIP>/mediawiki on the browser. Click on the link to start the mediawiki setup. Click on Continue and proceed

 
Select the DB as the MySQL

 

Give the Database details as shown in the screen shot below and Database Password: manage

 

Enter the User name and password. Remember the details as they will be required later to login to your mediawiki page.



Select „I‘ m already bored“ and continue and let the installaiton continue.
 

 

Download the LocalSettings.php file and copy it in the /var/www/html/mediawiki-1.34.2
 

Restart the application (httpd) in the mediawiki node

Access the URL again and Login with the earlier credentials that you have cnfigured.
 


Now the mediaWiki is all set to host your content.

 

Solution Flaws and Recommendations
This solution apparently has many flaws in terms of Scalibility, High Avalability and Security.

The current solution is implemented on a single node EC2 instance and the Database is configured in the same local host. The instance is also configured on the Public Subnet and the TCP ports are open to the whole world.

The recommendation for the ideal architecture aolution would be the followings.

1.	Create the database using the AWS RDS preferrably MySQL or MariaDB with multi-AZ.
2.	Provision an ALB, create an ASG for the mediaWiki nodes and attach the ASG to the ALB. Configure the ASG lauch template with minimum two EC2 instances spread over multiple AZ. Place the EC2 instances in the Private Subnet.
3.	Enable data encryption at rest for both Database and EBS volume attached to EC2 instances.
4.	Configure the ACM for enabling the https protocol rather then http and attach to the ALB.
5.	Create a public hosted zone on Route53 and configure the ALB records in the Route53. The Route53 will provide static DNS frontended on the ALB.
6.	Enable the Health checks for the EC2 instances on the ALB.


 
