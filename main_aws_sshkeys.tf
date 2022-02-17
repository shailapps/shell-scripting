provider "aws" {
   region     = "us-east-2"
   access_key = "AKIAUVRE5VL5Z5P6Y46F"
   secret_key = "Zfqc9mqVnepwegHciJ2cPVBdjSj0sPd5LeBUFR1J"
   
}

resource "aws_instance" "ec2_example" {

    ami = "ami-0767046d1677be5a0"  
    instance_type = "t2.micro" 
    key_name= "aws_key"
    vpc_security_group_ids = [aws_security_group.main.id]

  provisioner "remote-exec" {
    inline = [
      "touch hello.txt",
      "echo helloworld remote provisioner >> hello.txt",
    ]
  }
  connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2"
      private_key = file("C:\Users\User1\Downloads\keys\aws\aws-keys")
      timeout     = "4m"
   }
}

resource "aws_security_group" "main" {
  egress = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
 ingress                = [
   {
     cidr_blocks      = [ "0.0.0.0/0", ]
     description      = ""
     from_port        = 22
     ipv6_cidr_blocks = []
     prefix_list_ids  = []
     protocol         = "tcp"
     security_groups  = []
     self             = false
     to_port          = 22
  }
  ]
}


resource "aws_key_pair" "deployer" {
  key_name   = "aws_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCgMfgOJBuymR/RjNdg3jHU0ITm/COobzjuFdyzounKgtx4XIIbfzTZv10gqXllvoiHoaDxISeX96yL9Yu6mL3OjZjxu6JIJW3ZcNEGJdn7TqDdHcYomsCo3h3OZy12LSU2LgiF2F6rVDxdeVqtKYbc+nTQLBMOsIb7jbg8UhdF6UnglelgV+ymeC7Wy4IoV8OM6DOQjg5NSr26RUcY/guRwu5G3OxCju55cpOURr8dR7MovTx7x4+L0QC5ySSbvTA+Js6Mz/XoiiA27qyWRgixD2uk5hjsTYdqQaSC4pWffZJ1vGJ4epfXagaFokLE+9nrU3318JIFfseNEZ0L9SYr user1@DESKTOP-CLOG7RI"
}
