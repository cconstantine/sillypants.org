
variable "coreos_count" {
  default = "3"
}

resource "aws_instance" "coreos" {
#  ami = "ami-fbc3d19a" #Coreos beta
  ami = "ami-29667a48" #Coreos alpha
  instance_type = "t1.micro"
	key_name = "${aws_key_pair.thunk-cconstantine.id}"
  count = "${var.coreos_count}"

  tags {
    Name = "coreos-${count.index}"
  }
  user_data = <<EOF
#cloud-config

hostname: "coreos-${count.index}"
coreos:
  units:
    - name: "etcd2.service"
      command: "start"
    - name: "fleet.service"
      command: "start"
  etcd2:
    name: "coreos-${count.index}"
    discovery-srv: "sillypants.org"
    advertise-client-urls: "http://coreos-${count.index}.sillypants.org:2379"
    initial-advertise-peer-urls: "http://coreos-${count.index}.sillypants.org:2380"
    listen-client-urls: "http://0.0.0.0:2379"
    listen-peer-urls: "http://coreos-${count.index}.sillypants.org:2380"
    initial-cluster-state: new
    initial-cluster-token: "sillypants-org"

users:
  - name: "cconstantine"
    groups:
      - "sudo"
      - "docker"
    ssh-authorized-keys:
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDYAV4ex4s5vQpJTVJfvy9J8kVdV0iJ/cRBQvoUMguJjkja9oiaEJqMOM9mQA8onM51IOoKdbicaRSpvp0GPkUo/0doGmRqMJBeT/jXfhrY3oHjhVkbjzdmf3MVKBSfyz8P4r7lWk6ydNDOJpCS/C4iVbb4zkttY/4lijfGDhTasVt9Qk/I2jdc3GFrD14Q8ahv8+M/QeUrYpIEfUlAP48+/i33aEZU3YGJ9ya7SFGSkmHANSKt498go3FBaou/nXNo1NZpGrM35uRlk0qdX03CF9kl2KHKtz/5H0xKtzNczCjFlEul5tu7NmXVjzAyxr0ceCJ3FcUqSba+5lkC1ui3 cconstantine@thunk"
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpEL7Gy6uWwQ7fEzn2U7vc9XTvsjZhrVz/lzNhJYVsR09IUGOJRcEj4DjzqCZDPNzRYG8dxasWbOpow2NaLM/iaBhWA+gT3gaDD26EwwxhtBDsk84gTo9RwVsZoo29a1IUsgUWyzGoAoRE8IDwvz1afkTwzydyEU00U9ns9gxgMKkOjmVTdQAxihNZElBvXJ4rKqqnInNZlYs7S+FNi+A4zFTBZ4rndh/cI9kRVx7/WKdxfgso6KgSisCuV+2rcpbeV6Y+7JPlvbefcqux7Q8aXeTCP2HGJV6/aAr3yNleMC8DT0FuBo5l84QVJhgXfYDlTkTAAS62/7O2vav4TcGd cconstantine@fig.local"
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCym7EuaOFC1MGPko2z+1LgXDrI9MdnAhYx2CrohIKyPXdQ/8LYl4c0cXUymmHEw5emt/WWoyl4PnBhhpQypNt6w5ebdZvXkt2c5hlY79gC+R8lPTEMl0UvhhQwLTFuhC8ZjyPhTj4DENicLNccmHoWTLaSOkvePagfmDmOGuuJRL280+ddPv25NdtwsYn/hgxk0JStoteVRKFcORjkYcwWrxqwU8gIVzmWiViZdjNkldgCiebzMUfm0uFelt6CiT2oeGb4elPwkt+1O6cATSJmyP1CbxsLLzCHsbfX/kQVdqpJZO+7BexJFYqT1WJ/kQnDWounktWEqs/o5YgQbcpj cconstantine@think"
EOF

	iam_instance_profile = "${aws_iam_instance_profile.s3_profile.name}"
  vpc_security_group_ids = [
    "sg-4ad7fc2e",
    "${aws_security_group.allow_all_ssh.id}",
    "${aws_security_group.allow_all_web.id}"]
}


resource "aws_route53_record" "coreos_sillypants_org" {
   zone_id = "ZU7CFKBZNQZFU"
   name = "coreos-${count.index}"
   type = "CNAME"
   ttl = "1"
   count = "${var.coreos_count}"

   records = ["${element(aws_instance.coreos.*.public_dns, count.index)}"]
}


resource "aws_route53_record" "etcd_coreos_sillypants_org" {
   zone_id = "ZU7CFKBZNQZFU"
   name = "_etcd-server._tcp"
   type = "SRV"
   ttl = "1"
  count = "${var.coreos_count}"

   records = [["${formatlist("0 0 2380 %s.sillypants.org.", aws_route53_record.coreos_sillypants_org.*.name)}"]

}
