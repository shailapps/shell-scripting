resource "aws_instance" "ec2_example" {
    ami = "ami-0b0af3577fe5e3532"  
    instance_type = "t2.micro" 
    tags = {
        Name = "Terraform EC2"
    }
}