
variable "coreos_count" {
  default = "3"
}

resource "aws_route53_zone" "coreos_zone" {
  name = "coreos.sillycluster.net"
}


resource "aws_route53_record" "coreos_ns" {
    zone_id = "ZPYZBFHONNSZM"
    name = "coreos.sillycluster.net"
    type = "NS"
    ttl = "30"
    records = [
        "${aws_route53_zone.coreos_zone.name_servers.0}",
        "${aws_route53_zone.coreos_zone.name_servers.1}",
        "${aws_route53_zone.coreos_zone.name_servers.2}",
        "${aws_route53_zone.coreos_zone.name_servers.3}"
    ]
}
resource "aws_route53_record" "coreos_sillycluster_net" {
   zone_id = "${aws_route53_zone.coreos_zone.zone_id}"
   name = "n${count.index}"
   type = "CNAME"
   ttl = "1"
   count = "${var.coreos_count}"

   records = ["${element(aws_instance.coreos.*.public_dns, count.index)}"]
}

resource "aws_route53_record" "wildcard_coreos" {
   zone_id = "${aws_route53_zone.coreos_zone.zone_id}"

   name = "coreos.sillycluster.net"
   type = "A"
   ttl = "1"
   records = ["${aws_instance.coreos.*.public_ip}"]
}



resource "aws_route53_record" "etcd_coreos_sillycluster_net" {
   zone_id = "${aws_route53_zone.coreos_zone.zone_id}"
   name = "_etcd-server._tcp"
   type = "SRV"
   ttl = "1"
   count = "${var.coreos_count}"

   records = [["${formatlist("0 0 2380 %s", aws_instance.coreos.*.private_ip)}"]
}

resource "aws_instance" "coreos" {
#  ami = "ami-fbc3d19a" #Coreos beta
#  ami = "ami-29667a48" #Coreos alpha
  ami = "ami-13607c72" #Coreos alpha HVM
  instance_type = "t2.micro"
	key_name = "${aws_key_pair.thunk-cconstantine.id}"
  count = "${var.coreos_count}"

	availability_zone = "${lookup(var.availabillity_zones, count.index % 3)}"

  tags {
    Name = "coreos-${count.index}"
  }

  vpc_security_group_ids = [
    "sg-4ad7fc2e",
    "${aws_security_group.allow_all_ssh.id}",
    "${aws_security_group.allow_all_web.id}"]

  user_data = <<EOF
#cloud-config

hostname: "n${count.index}.coreos.sillycluster.net"

write_files:
  - path: "/etc/systemd/resolved.conf"
    owner: "root"
    permissions: "0644"
    content: |
      [Resolve]
      DNS=$private_ipv4
  - path: "/etc/nginx/nginx.conf"
    owner: "root"
    permissions: "0644"
    content: |
      worker_processes 4;
      events {
        worker_connections 768;
        # multi_accept on;
      }
      http {
        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 65;
        types_hash_max_size 2048;
        gzip on;
        gzip_disable "msie6";
        server {
          server_name ~^(?<app>.+)\.sillypants\.org$;
          location / {
            resolver $private_ipv4;
            proxy_pass http://$app.skydns.local:5000/;
          }
        }
      }


coreos:
  update:
    reboot-strategy: best-effort
  fleet:
    metadata: "region=us-west-2,network=dmz"
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
    - name: "nginx.service"
      command: "start"
      content: |
        [Unit]
        Description=Nginx proxy
        After=docker.service

        [Service]
        Restart=always
        ExecStart=/usr/bin/docker run --rm --name=nginx -v /etc/nginx/nginx.conf:/etc/nginx/nginx.conf:ro -p 80:80 nginx
        ExecStop=/usr/bin/docker kill nginx

        [X-Fleet]
        Global=true

    - name: "fleet.service"
      command: "start"
    - name: "systemd-resolved.service"
      command: "restart"
    - name: "registrator.service"
      command: "start"
      content: |
        [Unit]
        Description=Docker service registrator
        After=docker.service
        After=etcd2.service

        [Service]
        Restart=always
        ExecStart=/usr/bin/docker run --rm --name=registrator -v /var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:latest -internal=true skydns2://n${count.index}.coreos.sillycluster.net:2379/local/skydns
        ExecStop=/usr/bin/docker kill registrator 						

    - name: "skydns.service"
      command: "start"
      content: |
        [Unit]
        Description=SkyDNS etcd based resolver
        After=etcd2.service

        [Service]
        Restart=always
        ExecStart=/usr/bin/docker run -e SKYDNS_ADDR=0.0.0.0:53 -e ETCD_MACHINES=http://n${count.index}.coreos.sillycluster.net:2379 --net host --rm --name skydns skynetservices/skydns:latest
        ExecStop=/usr/bin/docker kill skydns

  etcd2:
    name: "coreos-${count.index}"
    discovery-srv: "coreos.sillycluster.net"
    advertise-client-urls: "http://n${count.index}.coreos.sillycluster.net:2379"
    initial-advertise-peer-urls: "http://n${count.index}.coreos.sillycluster.net:2380"
    listen-client-urls: "http://0.0.0.0:2379"
    listen-peer-urls: "http://n${count.index}.coreos.sillycluster.net:2380"
    initial-cluster-state: new
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



