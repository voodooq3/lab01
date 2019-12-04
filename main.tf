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

  /* 
 #--- example of using user_data ---#
 # user_data = file("./files/update.sh")

 #--- example of using file provisioner  ---#
 provisioner "file" {
    source      = "./files/test.config"
    destination = "~/test.config"
  }
  */

#--- example of using file content  ---#
 provisioner "file" {
    content = "${templatefile("./files/nginx.conf.tpl", {server_name = "${self.public_ip}"})}"
    destination  =  "~/jenkins.conf"
  }

#--- provisioner ---#
connection {
    type     = "ssh"
    user     = "centos"
    # private_key = "${file("./key/voodookey.pem")}"
    private_key = "${file(var.private_key_path)}"
    # host     = "${aws_instance.lab01.public_ip}"
    host       = "${self.public_ip}"
     }
  provisioner "remote-exec" {
    inline = [
      "sudo setenforce 0",
      "sudo yum repolist",
      
      "echo _______________________installing_nginx_______________________",
      "echo '${file("./files/nginx.repo")}' > ~/nginx.repo",
      "sudo cp ~/nginx.repo /etc/yum.repos.d/nginx.repo",
      "sudo yum install nginx -y",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx",

      "echo _______________________installing_jenkins_______________________",
      "sudo yum install java-1.8.0-openjdk.x86_64 -y",
      "curl --silent --location http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo | sudo tee /etc/yum.repos.d/jenkins.repo",
      "sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key",
      "sudo yum install jenkins -y",
      "sudo systemctl start jenkins",
      "sudo systemctl enable jenkins",

      # "yum install wget -y",
      # "wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      # "yum install jenkins -y",
      # "yum install java-1.8.0-openjdk.x86_64",

      "echo _______________________changing_nginx_settings_______________________",
      #--- example of copying files in inline ---#
      # "echo '${file("nginx.conf.tpl")}' > ~/nginx.conf.tpl",
      "rm -f /etc/nginx/conf.d/default.conf",
      "sudo cp ~/jenkins.conf /etc/nginx/conf.d/jenkins.conf",
      "sudo service nginx restart",
      "echo _______________________HAPPY_END_______________________"
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
    ingress {
    from_port   = 80
    to_port     = 80
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