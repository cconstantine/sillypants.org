resource "aws_instance" "web" {
  ami = "ami-e54f5f84" #ami-534d5d32"
  instance_type = "t1.micro"
	key_name = "${aws_key_pair.thunk-cconstantine.id}"
  tags {
    Name = "web"
  }
	iam_instance_profile = "${aws_iam_instance_profile.s3_profile.name}"
  vpc_security_group_ids = [
    "sg-4ad7fc2e",
    "${aws_security_group.allow_all_ssh.id}",
    "${aws_security_group.allow_all_web.id}"]
}

resource "aws_eip" "lb" {
    instance = "${aws_instance.web.id}"
    vpc = true
}

resource "aws_route53_record" "sillypants_org" {
   zone_id = "ZU7CFKBZNQZFU"
   name = "sillypants.org"
   type = "A"
   ttl = "1"
   records = ["${aws_eip.lb.public_ip}"]
}

resource "aws_route53_record" "wildcard_sillypants_org" {
   zone_id = "ZU7CFKBZNQZFU"
   name = "*.sillypants.org"
   type = "CNAME"
   ttl = "1"
   records = ["sillypants.org"]
}

resource "aws_iam_instance_profile" "s3_profile" {
    name = "s3_profile"
    roles = ["${aws_iam_role.s3_access_role.name}"]
}

resource "aws_iam_role" "s3_access_role" {
  name = "s3_access_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "s3_policy" {
    name = "s3_policy"
		role = "${aws_iam_role.s3_access_role.id}"
    policy = <<EOF
{
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
						"Resource": "*"
        }
    ]
}
EOF
}