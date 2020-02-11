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
  
  connection {
    type     = "ssh"
    user     = "centos"
    private_key = "${file(var.private_key_path)}"
    host       = "${self.public_ip}"
     }

   user_data = <<-EOF
              #!/bin/bash
              sudo yum install -y mc
              chmod 0600 /home/centos/.ssh/id_rsa
   EOF

  root_block_device {
    delete_on_termination = true
  }
  tags = {
    Name    = "Bastion"
  }
}


#------- RDS -------#
resource "aws_db_instance" "mySQLDataBase" {
  allocated_storage    = 5
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "wordpress"
  username             = "sqluser"
  password             = "userpass"
  parameter_group_name = "default.mysql5.7"
  vpc_security_group_ids = ["${aws_security_group.DB_Security_Group.id}"]
  db_subnet_group_name   = "${aws_db_subnet_group.RDS_subnet_group.name}"
  skip_final_snapshot  = true
}


/*********************************************************
######### The End #########
*********************************************************/


