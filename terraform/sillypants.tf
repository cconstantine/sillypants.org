
resource "aws_route53_record" "sillypants_org" {
   zone_id = "ZU7CFKBZNQZFU"
   name = "sillypants.org"
   type = "A"
   ttl = "1"
   records = ["${split(",", module.control.instance_public_ips)}"]
}

resource "aws_route53_record" "wildcard_sillypants_org" {
   zone_id = "ZU7CFKBZNQZFU"
   name = "*.sillypants.org"
   type = "CNAME"
   ttl = "1"
   records = ["sillypants.org"]
}

provider "aws" {
    region = "us-west-2"
}

resource "aws_iam_instance_profile" "control_instance_profile" {
    name = "control_profile"
    roles = ["${aws_iam_role.s3_access_role.name}"]
}

resource "aws_route53_record" "etcd_instance_sillycluster_net" {
   zone_id = "ZPYZBFHONNSZM"
   name = "_etcd-server._tcp"
   type = "SRV"
   ttl = "1"
   
   records = [["${formatlist("0 0 2380 %s", split(",", module.control.instance_private_ips))}"]
}

module "control" {
  source = "./squad"

	etcd2_cluster_state = "new"
  region = "us-west-2"
  instance_name = "control"
  keypair = "${aws_key_pair.thunk-cconstantine.id}"
	instance_profile =       "${aws_iam_instance_profile.control_instance_profile.name}"
  vpc_security_group_ids = "sg-4ad7fc2e,${aws_security_group.allow_all_ssh.id},${aws_security_group.allow_all_web.id}"
  discovery_srv =          "sillycluster.net"
}

resource "aws_key_pair" "thunk-cconstantine" {
  key_name = "thunk-cconstantine" 
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDYAV4ex4s5vQpJTVJfvy9J8kVdV0iJ/cRBQvoUMguJjkja9oiaEJqMOM9mQA8onM51IOoKdbicaRSpvp0GPkUo/0doGmRqMJBeT/jXfhrY3oHjhVkbjzdmf3MVKBSfyz8P4r7lWk6ydNDOJpCS/C4iVbb4zkttY/4lijfGDhTasVt9Qk/I2jdc3GFrD14Q8ahv8+M/QeUrYpIEfUlAP48+/i33aEZU3YGJ9ya7SFGSkmHANSKt498go3FBaou/nXNo1NZpGrM35uRlk0qdX03CF9kl2KHKtz/5H0xKtzNczCjFlEul5tu7NmXVjzAyxr0ceCJ3FcUqSba+5lkC1ui3 cconstantine@thunk"
} 

module "backend" {
  source = "./squad"

  keypair = "${aws_key_pair.thunk-cconstantine.id}"
  etcd2_cluster_state = "new"
  region = "us-west-2"
  instance_name = "backend"
  instance_profile =       "${aws_iam_instance_profile.control_instance_profile.name}"
  vpc_security_group_ids = "sg-4ad7fc2e,${aws_security_group.allow_all_ssh.id}"
  discovery_srv =          "sillycluster.net"
}