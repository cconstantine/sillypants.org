provider "aws" {
    region = "us-west-2"
}

resource "aws_key_pair" "thunk-cconstantine" {
  key_name = "thunk-cconstantine" 
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDYAV4ex4s5vQpJTVJfvy9J8kVdV0iJ/cRBQvoUMguJjkja9oiaEJqMOM9mQA8onM51IOoKdbicaRSpvp0GPkUo/0doGmRqMJBeT/jXfhrY3oHjhVkbjzdmf3MVKBSfyz8P4r7lWk6ydNDOJpCS/C4iVbb4zkttY/4lijfGDhTasVt9Qk/I2jdc3GFrD14Q8ahv8+M/QeUrYpIEfUlAP48+/i33aEZU3YGJ9ya7SFGSkmHANSKt498go3FBaou/nXNo1NZpGrM35uRlk0qdX03CF9kl2KHKtz/5H0xKtzNczCjFlEul5tu7NmXVjzAyxr0ceCJ3FcUqSba+5lkC1ui3 cconstantine@thunk"
}