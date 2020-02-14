
variable region {
  description = "Region"
  # type = string
  default = "eu-central-1"
}

variable shared_credentials_file_path {
  description = "Shared Credentials File Path"
  # type = "string"
  default = "./key/cred.txt"
}

variable private_key_path {
  description = "Pivate Key"
  # type = "string"
  default = "./key/voodookey.pem"
}
#------- VPC -------#
variable "vpc_cidr" {
  description = "LAB01 CIDR for the whole VPC"
  default     = "10.10.0.0/16"
}

variable "vpc_cidr_public_a" {
  description = "LAB01 CIDR for the Public subnet"
  default     = "10.10.1.0/24"
}

variable "vpc_cidr_public_b" {
  description = "LAB01 CIDR for the Public subnet"
  default     = "10.10.2.0/24"
}

variable "vpc_cidr_private_a" {
  description = "LAB01 CIDR for the Private subnet"
  default     = "10.10.201.0/24"
}

variable "vpc_cidr_private_b" {
  description = "LAB01 CIDR for the Private subnet"
  default     = "10.10.202.0/24"
}

