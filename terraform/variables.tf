variable "region" {
  default = "us-east-1" # Change to your preferred region
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ami" {
  # Ubuntu 22.04 LTS in us-east-1 (update if region changes)
  default = "ami-05ec1e5f7cfe5ef59"
}
