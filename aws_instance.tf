resource "aws_instance" "ec2_example" {
    ami = "ami-01fc429821bf1f4b4"  
    instance_type = "t2.micro" 
    tags = {
        Name = "Terraform EC2"
    }
}