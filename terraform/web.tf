resource "aws_instance" "web" {
  ami = "ami-e54f5f84"
  instance_type = "t1.micro"
	key_name = "${aws_key_pair.thunk-cconstantine.id}"
  tags {
    Name = "web"
  }

 vpc_security_group_ids = ["sg-4ad7fc2e", "${aws_security_group.allow_all_ssh.id}", "${aws_security_group.allow_all_web.id}"]
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

resource "aws_ebs_volume" "web_home" {
    availability_zone = "${aws_instance.web.availability_zone}"
    size = 40
    tags {
        Name = "Web Homedir"
    }
}

resource "aws_volume_attachment" "web_home_att" {
  device_name = "/dev/sdh"
  volume_id = "${aws_ebs_volume.web_home.id}"
  instance_id = "${aws_instance.web.id}"
}