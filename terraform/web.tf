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

variable "swarm_count" {
  default = "3"
}

resource "aws_instance" "swarm" {
#  ami = "ami-e54f5f84"
  ami = "ami-a9435ec8"
  instance_type = "t1.micro"
	key_name = "${aws_key_pair.thunk-cconstantine.id}"
  count = "${var.swarm_count}"

  tags {
    Name = "swarm-${count.index}"
  }
	iam_instance_profile = "${aws_iam_instance_profile.s3_profile.name}"
  vpc_security_group_ids = [
    "sg-4ad7fc2e",
    "${aws_security_group.allow_all_ssh.id}",
    "${aws_security_group.allow_all_web.id}"]
}

resource "aws_route53_record" "swarm_sillypants_org" {
   zone_id = "ZU7CFKBZNQZFU"
   name = "swarm-${count.index}"
   type = "CNAME"
   ttl = "1"
   count = "${var.swarm_count}"

   records = ["${element(aws_instance.swarm.*.public_dns, count.index)}"]
}