provider "aws" {
  region = "us-east-1"
}

#Burada instance type da if li yapı var. workspace e bak dev ise t2 micro değilse t3 micro getir.
# count = de benim workspace ime bak burası prod ise 3 instance değilse 1 instance getir.
#ami kısmında lookup arama commandi.. ami için myami kısmı ile workspace i eşleştir diyoruz.
resource "aws_instance" "tfmyec2" {
  ami = lookup(var.myami, terraform.workspace)
  instance_type = "${terraform.workspace == "dev" ? "t2.micro" : "t3.micro"}"
  count = "${terraform.workspace == "prod" ? 3 : 1}"
  key_name = "<key1"
  tags = {
    Name = "${terraform.workspace}-server"
  }
}

# Burada daha önceki modulese ilave olarak 3 farklı workspacei oluştuyoruz.
# daha genel bir çerçeve çiziyoruz. Variable da dev ise bu prod ise bunu kullan diyoruz.
variable "myami" {
  type = map(string)
  default = {
    default = "ami-0cff7528ff583bf9a"
    dev     = "ami-06640050dc3f556bb"
    prod    = "ami-08d4ac5b634553e16"
  }
  description = "in order of aAmazon Linux 2 ami, Red Hat Enterprise Linux 8 ami and Ubuntu Server 20.04 LTS amis"
}

