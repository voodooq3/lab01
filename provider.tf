


provider "aws" {
  # region                  = "eu-central-1"
  region                  = "${var.region}"
  # shared_credentials_file = "./key/cred.txt"
  shared_credentials_file = "${var.shared_credentials_file_path}"
  profile                 = "cred01"
}


