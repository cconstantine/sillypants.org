resource "aws_security_group" "allow_all_ssh" {
  name = "allow_all_ssh"
  description = "Allow all inbound ssh traffic"
	vpc_id = "vpc-4a92a62f"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_all_web" {
  name = "allow_all_web"
  description = "Allow all inbound web traffic"
	vpc_id = "vpc-4a92a62f"

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

}