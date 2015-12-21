
variable "instance_count" {
  default = "3"
}


variable "domain_suffix" {
  default = "sillycluster.net"
}


variable "etcd2_cluster_state" {
  default = "existing"
}

variable "instance_name" { }

variable "instance_profile" { }
variable "vpc_security_group_ids" {}
variable "keypair" {}

output "instance_cnames" {
  value = "${join(",", aws_route53_record.instance_CNAME.*.fqdn)}"
}

output "instance_public_ips" {
  value = "${join(",", aws_instance.instance.*.public_ip)}"
}

output "instance_private_ips" {
  value = "${join(",", aws_instance.instance.*.private_ip)}"
}

output "instances" {
  value = "${instance_count}"
}

resource "aws_route53_zone" "instance_zone" {
  name = "${var.instance_name}.${var.domain_suffix}"
}

resource "aws_route53_record" "instance_ns" {
    zone_id = "ZPYZBFHONNSZM"
    name = "${var.instance_name}.${var.domain_suffix}"
    type = "NS"
    ttl = "30"
    records = [
        "${aws_route53_zone.instance_zone.name_servers.0}",
        "${aws_route53_zone.instance_zone.name_servers.1}",
        "${aws_route53_zone.instance_zone.name_servers.2}",
        "${aws_route53_zone.instance_zone.name_servers.3}"
    ]
}
resource "aws_route53_record" "instance_CNAME" {
   zone_id = "${aws_route53_zone.instance_zone.zone_id}"
   name = "n${count.index}"
   type = "CNAME"
   ttl = "1"
   count = "${var.instance_count}"

   records = ["${element(aws_instance.instance.*.public_dns, count.index)}"]
}

resource "aws_instance" "instance" {
#  ami = "ami-13607c72" #Coreos alpha HVM
#  ami = "ami-c87769a9" # ubuntu 15_10 hvm
  ami = "ami-818eb7b1" # debian jessie hvm
  instance_type = "t2.micro"
	key_name = "${var.keypair}"
  count = "${var.instance_count}"

	availability_zone = "${var.region}${lookup(var.availabillity_zones, count.index % 3)}"
	iam_instance_profile = "${var.instance_profile}"

  tags {
    Name = "${var.instance_name}-${count.index}"
  }

  vpc_security_group_ids = ["${split(",", var.vpc_security_group_ids)}"]

}


