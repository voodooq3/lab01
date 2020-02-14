
output "instance_ips" {
  description = "The public IP address of Bastion."
  value = ["${aws_instance.Bastion.public_ip}"]
}

output "lb_address" {
  description = "The public IP address of Bastion."
  value = ["${aws_lb.Lab01ALB.dns_name}"]
}

