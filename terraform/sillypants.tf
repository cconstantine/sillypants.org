
resource "aws_route53_record" "sillypants_org" {
   zone_id = "ZU7CFKBZNQZFU"
   name = "sillypants.org"
   type = "A"
   ttl = "1"
   records = ["${aws_instance.coreos.0.public_ip}"]
}

resource "aws_route53_record" "wildcard_sillypants_org" {
   zone_id = "ZU7CFKBZNQZFU"
   name = "*.sillypants.org"
   type = "CNAME"
   ttl = "1"
   records = ["sillypants.org"]
}

