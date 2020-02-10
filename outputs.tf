
output "instance_ips" {
  description = "The public IP address of Bastion."
  value = ["${aws_instance.Bastion.public_ip}"]
}
