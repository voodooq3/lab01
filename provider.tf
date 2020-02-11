provider "aws" {
  region = "${var.region}"
  shared_credentials_file = "${var.shared_credentials_file_path}"
  profile                 = "cred01"
}


