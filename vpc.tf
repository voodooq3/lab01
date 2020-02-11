######### Let's Roll #########
#------- VPC -------#
resource "aws_vpc" "VPC_Lab01" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_support               = "true"
  enable_dns_hostnames             = "true"
  assign_generated_ipv6_cidr_block = "false"
  tags = {
    Name = "VPC Lab01"
  }
}

#------- Internet Gateway -------#
resource "aws_internet_gateway" "Gateway_Lab01" {
  vpc_id = "${aws_vpc.VPC_Lab01.id}"
  tags = {
    Name = "Gateway Lan01"
  }
}

#-----------------------------#
#------- Load Balancer -------#
#-----------------------------#
resource "aws_lb" "Lab01ALB" {  
  name            = "Lab01ALB"
  load_balancer_type = "application"
  subnets         = ["${aws_subnet.Public_Subnet_a.id}","${aws_subnet.Public_Subnet_b.id}"]
  security_groups = ["${aws_security_group.LB_Security_Group.id}"]
  internal        = false 
}

#------- Target Group -------#
resource "aws_lb_target_group" "Lab01_Target_Group" {  
  name     = "Lab01-Target-Group"
  port     = "80"  
  protocol = "HTTP"  
  target_type = "instance"
  vpc_id   = "${aws_vpc.VPC_Lab01.id}"

  health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200-299"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener" "Lab01_LB_listener" {
    load_balancer_arn = "${aws_lb.Lab01ALB.arn}"
    port = "80"
    protocol = "HTTP"

   default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.Lab01_Target_Group.arn}"
  }
}

#------- Attachment -------#
resource "aws_autoscaling_attachment" "Lab01_autoscale_attachment" {
  alb_target_group_arn   = "${aws_lb_target_group.Lab01_Target_Group.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.Lab01_autoscale_group.id}"
}

#------- Autoscale Launch -------#
resource "aws_launch_configuration" "Lab01_autoscale_launch" {
  name            = "Lab01 autoscale configuration"
  image_id = "ami-04cf43aca3e6f3de3"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.ASG_Security_Group.id}"]
  key_name = "voodoo.key"
  lifecycle {
    create_before_destroy = true
  }
  root_block_device {
    delete_on_termination = true
  }
}

#------- Autoscale Group -------#
resource "aws_autoscaling_group" "Lab01_autoscale_group" {
  name = "Lab01 autoscale group"
  launch_configuration = "${aws_launch_configuration.Lab01_autoscale_launch.id}"
  vpc_zone_identifier = ["${aws_subnet.Private_Subnet_a.id}","${aws_subnet.Private_Subnet_b.id}"]
  min_size = 1
  max_size = 3
  tag {
    key = "Name"
    value = "Lab01_autoscale_group"
    propagate_at_launch = true
  }
}
#-----------------------------#
#-----------------------------#
#-----------------------------#

#------- Elastic IP for NAT GW -------#
resource "aws_eip" "EIP_Lab01" {
  vpc        = true
  tags = {
    Name = "EIP Lab01"
  }
}

#------- NAT gateway -------#
resource "aws_nat_gateway" "Nat_Gateway_Lab01" {
  allocation_id = "${aws_eip.EIP_Lab01.id}"
  subnet_id     =  "${aws_subnet.Public_Subnet_a.id}"

  tags = {
    Name = "Nat Gateway Lan01"
  }

}

#------- Public and Private Subnets -------#
resource "aws_subnet" "Public_Subnet_a" {
  vpc_id            = "${aws_vpc.VPC_Lab01.id}"
  cidr_block        = "${var.vpc_cidr_public_a}"
  availability_zone = "${var.region}a"
  # map_public_ip_on_launch = "true"
  tags = {
    Name = "Lab01 Public subnet A"
  }
}

resource "aws_subnet" "Public_Subnet_b" {
  vpc_id            = "${aws_vpc.VPC_Lab01.id}"
  cidr_block        = "${var.vpc_cidr_public_b}"
  availability_zone = "${var.region}b"
  tags = {
    Name = "Lab01 Public subnet B"
  }
}

resource "aws_subnet" "Private_Subnet_a" {
  vpc_id            = "${aws_vpc.VPC_Lab01.id}"
  cidr_block        = "${var.vpc_cidr_private_a}"
  availability_zone = "${var.region}a"
  tags = {
    Name = "Lab01 Private subnet A"
  }
}

resource "aws_subnet" "Private_Subnet_b" {
  vpc_id            = "${aws_vpc.VPC_Lab01.id}"
  cidr_block        = "${var.vpc_cidr_private_b}"
  availability_zone = "${var.region}b"
  tags = {
    Name = "Lab01 Private subnet B"
  }
}

#------- Routing table -------#
resource "aws_route_table" "Public_Route_Table" {
  vpc_id = "${aws_vpc.VPC_Lab01.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.Gateway_Lab01.id}"
  }
  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table" "Private_Route_Table" {
  vpc_id = "${aws_vpc.VPC_Lab01.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.Nat_Gateway_Lab01.id}"
   }
  tags = {
    Name = "Private Route Table"
  }
}


#------- Default route to Internet -------#
resource "aws_route" "Public_Route" {
  route_table_id         = "${aws_route_table.Public_Route_Table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.Gateway_Lab01.id}"
}

#------- Route tables associations -------#
resource "aws_route_table_association" "Public_Subnet_Association_a" {
  subnet_id      = "${aws_subnet.Public_Subnet_a.id}"
  route_table_id = "${aws_route_table.Public_Route_Table.id}"
}
resource "aws_route_table_association" "Public_Subnet_Association_b" {
  subnet_id      = "${aws_subnet.Public_Subnet_b.id}"
  route_table_id = "${aws_route_table.Public_Route_Table.id}"
}
resource "aws_route_table_association" "Private_Subnet_Association_a" {
  subnet_id      = "${aws_subnet.Private_Subnet_a.id}"
  route_table_id = "${aws_route_table.Private_Route_Table.id}"
}
resource "aws_route_table_association" "Private_Subnet_Association_b" {
  subnet_id      = "${aws_subnet.Private_Subnet_b.id}"
  route_table_id = "${aws_route_table.Private_Route_Table.id}"
}

#------- Security Groups -------#
resource "aws_security_group" "LB_Security_Group" {
  name   = "Lab01 LB security group"
  vpc_id = "${aws_vpc.VPC_Lab01.id}"
  
    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Lab01 Load Balance Security Group"
  }
}

resource "aws_security_group" "ASG_Security_Group" {
  name = "Lab01 Autoscaling security group"
  vpc_id = "${aws_vpc.VPC_Lab01.id}"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr_public_a}"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr_public_b}"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "Lab01 Autoscaling security grou"
  }
}


resource "aws_security_group" "Bastion_Security_Group" {
  name   = "Lab01 Public security group"
  vpc_id = "${aws_vpc.VPC_Lab01.id}"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Lab01 Bastion Security Group"
  }
}

resource "aws_security_group" "DB_Security_Group" {
  name   = "Lab01 DB security group"
  vpc_id = "${aws_vpc.VPC_Lab01.id}"
   
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr_private_a}"]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr_private_b}"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Lab01 Private Security Group"
  }
}

#------- RDS subnet group -------#

resource "aws_db_subnet_group" "RDS_subnet_group" {
  name       = "rds subnet group"
  subnet_ids = ["${aws_subnet.Private_Subnet_a.id}", "${aws_subnet.Private_Subnet_b.id}"]

  tags = {
    Name = "Lab01_RDS_subnet_group"
  }
}


######### The End #########