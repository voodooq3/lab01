######### Let's Roll #########
#--- ami ---#
data "aws_ami" "centos" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["679593333241"]
}

#------- Instance -------#
resource "aws_instance" "Bastion" {
  ami           = "${data.aws_ami.centos.id}"
  instance_type = "t2.micro"
  key_name      = "voodoo.key"
  subnet_id = "${aws_subnet.Public_Subnet_a.id}"
  vpc_security_group_ids = ["${aws_security_group.Bastion_Security_Group.id}"]
  associate_public_ip_address = true
  
  root_block_device {
    delete_on_termination = true
  }
  tags = {
    Name    = "Bastion"
  }
}

#------- export templates -------#
data  "template_file" "bastion_ip" {
    template = "${file("./files/bastion_ip.tpl")}"
    vars = {
        bastion_ip_adr = "${aws_instance.Bastion.public_ip}"
    }
}
resource "local_file" "export_bastion_ip" {
  content  = "${data.template_file.bastion_ip.rendered}"
  filename = "../ansible/group_vars/all" 
}

data  "template_file" "wp_config_php" {
    template = "${file("./files/wp_config_php.tpl")}"
    vars = {
        rds_endpoint = "${"${aws_db_instance.mySQLDataBase.endpoint}"}" 
    }
}
resource "local_file" "export_wp_config_php" {
  content  = "${data.template_file.wp_config_php.rendered}"
  filename = "../ansible/files/wp-config.php.j2" 
}

#▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼#
#------- RDS -------#
resource "aws_db_instance" "mySQLDataBase" {
  allocated_storage    = 5
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "wordpress"
  username             = "sqluser"
  password             = "g0fDh5fg0Hhk"
  parameter_group_name = "default.mysql5.7"
  vpc_security_group_ids = ["${aws_security_group.DB_Security_Group.id}"]
  db_subnet_group_name   = "${aws_db_subnet_group.RDS_subnet_group.name}"
  skip_final_snapshot  = true
}
#▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲#

resource "aws_route53_record" "voodoo_link" {
  zone_id = "Z11V57WO0ZUEM3"
  name    = "wp.voodoo.link."
  type    = "CNAME"
  ttl     = "5"
  records = ["${aws_lb.Lab01ALB.dns_name}"]
}

resource "null_resource" "ansible-deploy" {
  provisioner "local-exec" {
    command = <<EOT
    cd ../ansible
    sleep 240
    ansible-playbook -i ec2.py -l tag_Name_Lab01_autoscale_group play_workpress.yml
    EOT
  }
}

# #▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼#
# ######################## The End ########################
# #▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲#