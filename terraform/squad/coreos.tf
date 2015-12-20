
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
variable "discovery_srv" { }
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
  ami = "ami-13607c72" #Coreos alpha HVM
  instance_type = "t2.micro"
	key_name = "${var.keypair}"
  count = "${var.instance_count}"

	availability_zone = "${var.region}${lookup(var.availabillity_zones, count.index % 3)}"
	iam_instance_profile = "${var.instance_profile}"

  tags {
    Name = "${var.instance_name}-${count.index}"
  }

  vpc_security_group_ids = ["${split(",", var.vpc_security_group_ids)}"]

  user_data = <<EOF
#cloud-config

hostname: "n${count.index}.${var.instance_name}.${var.domain_suffix}"

write_files:
  - path: "/etc/systemd/resolved.conf"
    owner: "root"
    permissions: "0644"
    content: |
      [Resolve]
      DNS=$private_ipv4

coreos:
  update:
    reboot-strategy: best-effort
  fleet:
    metadata: "region=us-west-2,type=${var.instance_name}"
  units:
    - name: "etcd2.service"
      command: "start"
    - name: flanneld.service
      drop-ins:
        - name: 50-network-config.conf
          content: |
            [Service]
            ExecStartPre=/usr/bin/etcdctl set /coreos.com/network/config '{ "Network": "10.1.0.0/16" }'
      command: start
    - name: docker.service
      drop-ins:
        - name: 50-flannel.conf
          content: |
            [Unit]
            Requires=flanneld.service
            After=flanneld.service
      command: start
    - name: "consul.service"
      command: "start"
      content: |
        [Unit]
        Description=Consul
        After=docker.service

        [Service]
        Restart=always
        ExecStart=/usr/bin/docker run --rm --name=n${count.index}.${var.instance_name} -e GOMAXPROCS=2 --net host cconstantine/consul-server:0.6 --bootstrap-expect ${var.instance_count} -advertise $private_ipv4 -retry-join n${count.index + 1 % var.instance_count}.${var.instance_name}.${var.domain_suffix} -ui-dir /ui
        ExecStop=/usr/bin/docker kill n${count.index}.coreos

    - name: "fleet.service"
      command: "start"
    - name: "systemd-resolved.service"
      command: "restart"


  etcd2:
    name: "${var.instance_name}-${count.index}"
    discovery-srv: "${var.discovery_srv}"
    advertise-client-urls: "http://n${count.index}.${var.instance_name}.${var.domain_suffix}:2379"
    initial-advertise-peer-urls: "http://n${count.index}.${var.instance_name}.${var.domain_suffix}:2380"
    listen-client-urls: "http://0.0.0.0:2379"
    listen-peer-urls: "http://$private_ipv4:2380"
    initial-cluster-state: "${var.etcd2_cluster_state}"
    initial-cluster-token: "sillycluster_net"

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
}



