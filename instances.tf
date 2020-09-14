#Get Linux AMI ID using SSM Parameter endpoint in us-east-1
data "aws_ssm_parameter" "linuxAmi" {
  provider = aws.mediawiki-node
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

#Please note that this code expects SSH key pair to exist in default dir under 
#users home directory, otherwise it will fail

#Create key-pair for logging into EC2 in us-east-1
resource "aws_key_pair" "master-key" {
  provider   = aws.mediawiki-node
  key_name   = "MyKeyPair"
  public_key = file("~/.ssh/id_rsa.pub")
}

#Create and bootstrap EC2 in us-east-1
resource "aws_instance" "mediawiki" {
  provider                    = aws.mediawiki-node
  ami                         = data.aws_ssm_parameter.linuxAmi.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.master-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.mediawiki-sg.id]
  subnet_id                   = aws_subnet.subnet_1.id

  tags = {
    Name = "mediawiki_node_tf"
  }

  depends_on = [aws_main_route_table_association.set-master-default-rt-assoc]
  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.mediawiki-node} --instance-ids ${self.id}
ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/install-mediawiki.yml
EOF
  }
}

