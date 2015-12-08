resource "aws_s3_bucket" "docker_registry" {
    bucket = "registry.docker.sillypants.org"

    tags {
        Name = "Docker Registry"
    }
}

resource "aws_s3_bucket" "vault_storage" {
    bucket = "vault.sillypants.org"

    tags {
        Name = "vault storage"
    }
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
