#Configure the AWS Provider
provider "aws" {
	region = "us-east-2"
		access_key = "AKIAILPKPRHURIQ2CGHA"
		secret_key = "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"
}



resource "aws_vpc" "terraformVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "terraformVPC"
  }
}

resource "aws_subnet" "TPublicSubnet" {
  vpc_id     = aws_vpc.terraformVPC.id
  cidr_block = "10.0.0.0/24"
  availability_zone_id ="use2-az1"
  map_public_ip_on_launch =true

  tags = {
    Name = "TPublicSubnet"
  }
}

resource "aws_subnet" "TprivateSubnet" {
  vpc_id     = aws_vpc.terraformVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone_id ="use2-az1"

  tags = {
    Name = "TprivateSubnet"
  }
}

resource "aws_subnet" "TPublicSubnet02" {
  vpc_id     = aws_vpc.terraformVPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone_id ="use2-az2"
  map_public_ip_on_launch = true
  tags = {
    Name = "TPublicSubnet02"
  }
}

resource "aws_subnet" "TPrivateSubnet02" {
  vpc_id     = aws_vpc.terraformVPC.id
  cidr_block = "10.0.3.0/24"
  availability_zone_id ="use2-az3"

  tags = {
    Name = "TPrivateSubnet02"
  }
}


resource "aws_internet_gateway" "TErraformIGT" {
  vpc_id = aws_vpc.terraformVPC.id

  tags = {
    Name = "TErraformIGT"
  }
}

resource "aws_route_table" "TErraformRoutTablePublic" {
  vpc_id = aws_vpc.terraformVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TErraformIGT.id
  }
  tags = {
    Name = "TErraformRoutTablePublic"
  }
}

resource "aws_route_table_association" "TErraformrouttableassociation" {
  subnet_id      = aws_subnet.TPublicSubnet.id
  route_table_id = aws_route_table.TErraformRoutTablePublic.id
}


resource "aws_route_table_association" "TErraformrouttableassociation02" {
  subnet_id      = aws_subnet.TPublicSubnet02.id
  route_table_id = aws_route_table.TErraformRoutTablePublic.id
}

resource "aws_security_group" "TeraapublicSecurityGroup" {
  name        = "TeraapublicSecurityGroup"
  description = "Allow TeraapublicSecurityGroup inbound traffic"
  vpc_id      = aws_vpc.terraformVPC.id
  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
   ingress { 
    description = "custome tcp"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
ingress {
    description = "ssh tcp"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
	egress {
	description = "ssh fron ec2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "TeraapublicSecurityGroup"
  }
}

resource "aws_security_group" "TeraaprivateSecurityGroup" {
  name        = "TeraaprivateSecurityGroup"
  description = "Allow TeraaprivateSecurityGroup inbound traffic"
  vpc_id      = aws_vpc.terraformVPC.id
  ingress {
    description = "http from ec2"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
	}
   ingress {
	description = "Custom tcp"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
	}
     ingress {
     description = "shh from ec2"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
	description = "mysql from ec2"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   egress {
	description = "ssh fron ec2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TeraaprivateSecurityGroup"
  }
}

resource "aws_instance" "TerraformEC2FrontEnd" {
  ami           = "ami-0e9f795915dafc0be"
  instance_type = "t2.micro"
  availability_zone = "us-east-2a"
  key_name = "Test123"
  subnet_id = aws_subnet.TPublicSubnet.id
  vpc_security_group_ids = [ aws_security_group.TeraapublicSecurityGroup.id ]
  tags = {
    Name = "TerraformEC2FrontEnd"
  }
}

resource "aws_instance" "TerraformECBackEnd" {
  ami           = "ami-0d47c0b0fe42d6b57"
  instance_type = "t2.micro"
  availability_zone = "us-east-2a"
  key_name = "Test123"
  subnet_id = aws_subnet.TprivateSubnet.id
  vpc_security_group_ids = [ aws_security_group.TeraaprivateSecurityGroup.id ]
  tags = {
    Name = "TerraformECBackEnd"
  }
}

resource "aws_eip" "Nateip" {
  vpc      = true
}
resource "aws_nat_gateway" "TerraNatGT" {
  allocation_id = aws_eip.Nateip.id
  subnet_id     = aws_subnet.TPublicSubnet.id

  tags = {
    Name = "TerraNatGT"
  }
    depends_on = [aws_internet_gateway.TErraformIGT]
}
resource "aws_route" "TerraNatrout" {
  route_table_id            = "rtb-0920bcd5002e90625"
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.TerraNatGT.id
}

resource "aws_db_subnet_group" "dbsubnetgroup" {
  name       = "dbsubnetgroup"
  subnet_ids = [aws_subnet.TprivateSubnet.id, aws_subnet.TPrivateSubnet02.id]

  tags = {
    Name = "My DB subnet group"
  }
}
resource "aws_db_instance" "mydb2" {
  allocated_storage    = 20
  availability_zone    = "us-east-2a"
  db_subnet_group_name = "dbsubnetgroup"
  vpc_security_group_ids = [aws_security_group.TeraaprivateSecurityGroup.id]
  storage_type         = "gp2"
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "mydb2"
  username             = "admin"
  password             = "123456789"
  depends_on           =[aws_db_subnet_group.dbsubnetgroup]
}

resource "aws_lb" "TerraformELBFrontend" {
  name               = "TerraformELBFrontend"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.TeraapublicSecurityGroup.id]
  subnets            = [aws_subnet.TPublicSubnet.id , aws_subnet.TPublicSubnet02.id]

  tags = {
    Name = "TerraformELBFrontend"
  }
}
 
resource "aws_lb_target_group" "TerraformFrontEndtargetGroup" {
  name     = "TerraformFrontEndtargetGroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraformVPC.id
}
 resource "aws_lb_listener" "Terraformfront_end" {
  load_balancer_arn = aws_lb.TerraformELBFrontend.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TerraformFrontEndtargetGroup.arn
  }
}
resource "aws_launch_configuration" "FrontendTerraLaunch_config" {
  name          = "frontendTerraLaunch_config"
  image_id      = "ami-053ed9005841602fd"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.TeraapublicSecurityGroup.id]
  key_name        ="Test123"
}

resource "aws_launch_configuration" "BackendTerraLaunch_config" {
  name          = "BackendTerraLaunch_config"
  image_id      = "ami-02ad4b33c49b2fd14"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.TeraaprivateSecurityGroup.id]
  key_name        ="Test123"
}
resource "aws_autoscaling_group" "TerraformFrontendAutoscaleGroup" {
  name                      = "TerraformFrontendAutoscaleGroup"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 500
  health_check_type         = "ELB"
  desired_capacity          = 1
  launch_configuration      = aws_launch_configuration.FrontendTerraLaunch_config.name
  vpc_zone_identifier       = [aws_subnet.TPublicSubnet.id]
  target_group_arns         = [aws_lb_target_group.TerraformFrontEndtargetGroup.arn]
  tag {
    key                 = "Name"
    value               = "TerraformFrontendEC2AutoScale"
    propagate_at_launch = true
  }
	depends_on = [aws_lb_target_group.TerraformFrontEndtargetGroup]

}

resource "aws_lb" "TerraformELBbackend" {
  name               = "TerraformELBBackend"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.TeraaprivateSecurityGroup.id]
  subnets            = [aws_subnet.TprivateSubnet.id , aws_subnet.TPrivateSubnet02.id ]

  tags = {
    Name = "TerraformELBBackend"
  }
 }
resource "aws_lb_target_group" "TerraformBackEndtargetGroup" {
  name     = "TerraformBackEndtargetGroup"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraformVPC.id
}
 resource "aws_lb_listener" "TerraformBackend" {
  load_balancer_arn = aws_lb.TerraformELBbackend.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TerraformBackEndtargetGroup.arn
  }
}
resource "aws_autoscaling_group" "TerraformBackendAutoscaleGroup" {
  name                      = "TerraformBackendAutoscaleGroup"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 500
  health_check_type         = "ELB"
  desired_capacity          = 1
  launch_configuration      = aws_launch_configuration.BackendTerraLaunch_config.name
  vpc_zone_identifier       = [aws_subnet.TprivateSubnet.id]
  target_group_arns         = [aws_lb_target_group.TerraformBackEndtargetGroup.arn]
  tag {
    key                 = "Name"
    value               = "TerraformBackendEC2AutoScale"
    propagate_at_launch = true
  }
  depends_on = [aws_lb_target_group.TerraformBackEndtargetGroup]

}


