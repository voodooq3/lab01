#--- data ---#
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

#------- resource -------#
resource "aws_instance" "lab01" {
  ami                    = "${data.aws_ami.centos.id}"
  instance_type          = "t2.micro"
  key_name               = "voodoo.key"
  root_block_device {
  delete_on_termination = true 
  }
  vpc_security_group_ids = ["${aws_security_group.lab01SecurityGroup.id}"]
  
  # user_data = file("update.sh")

#--- provisioner ---#
connection {
    type     = "ssh"
    user     = "centos"
    private_key = "${file("voodookey.pem")}"
    # host     = "${aws_instance.lab01.public_ip}"
    # host     =  self.public_ip
    host       = "${self.public_ip}"
    }
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y"
    ]
  }
  
  tags = {
    Name    = "Lab01Name"
    Project = "Lab01Project"
  }
}
#--- security_group ---#
resource "aws_security_group" "lab01SecurityGroup" {
  name = "lab01 security group"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Lab01 Security Group"
  }
}