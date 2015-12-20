variable "region" { }

provider "aws" {
    region = "${var.region}"
}

variable "availabillity_zones" {
    default = {
	    "0" = "a"
      "1" = "b"
      "2" = "c"
    }
}

