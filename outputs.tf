
output "instance_ips" {
  description = "The public IP address of the main server instance."
  value = ["${aws_instance.lab01.*.public_ip}"]
}
