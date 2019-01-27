provider "aws" {
	version = "~> 1.56"
	
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
	region = "ap-northeast-1"
}

resource "aws_vpc" "main" {
	cidr_block = "10.1.0.0/16"
	enable_dns_support = true
	enable_dns_hostnames = true

	tags {
		Name = "VPC_practice_TF"
	}
}

resource "aws_internet_gateway" "gw" {
	vpc_id = "${aws_vpc.main.id}"

	tags {
		Name = "IGW_practice_TF"
	}
}

resource "aws_route_table" "public" {
	vpc_id = "${aws_vpc.main.id}"

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.gw.id}"
	}
	
	tags {
		Name = "PubRT_practice_TF"
	}
}

resource "aws_route_table" "private" {
	vpc_id = "${aws_vpc.main.id}"

	route {
		cidr_block = "0.0.0.0/0"
		nat_gateway_id = "${aws_nat_gateway.default.id}"
	}
	tags {
		Name = "PriRT_practice_TF"
	}
}

resource "aws_subnet" "public" {
	vpc_id = "${aws_vpc.main.id}"
	cidr_block = "10.1.1.0/24"

	tags {
		Name = "Public_practice_TF"
	}
}

resource "aws_subnet" "private" {
	vpc_id = "${aws_vpc.main.id}"
	cidr_block = "10.1.2.0/24"
	
	tags {
		Name = "Private_practice_TF"
	}
}

resource "aws_eip" "nat" {
	vpc = true
}

resource "aws_nat_gateway" "default" {
	allocation_id = "${aws_eip.nat.id}"
	subnet_id = "${aws_subnet.public.id}"

	tags {
		Name = "NGW_practice_TF"
	}
}

resource "aws_route_table_association" "public" {
	subnet_id = "${aws_subnet.public.id}"
	route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private" {
	subnet_id = "${aws_subnet.private.id}"
	route_table_id = "${aws_route_table.private.id}"
}

resource "aws_security_group" "wsg" {
	name = "WebSG_practice_TF"
	vpc_id = "${aws_vpc.main.id}"

	ingress{
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress{
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = -1
		to_port = -1
		protocol = "icmp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}


	tags {
		Name = "WebSG_practice_TF"
	}
}

resource "aws_security_group" "dsg" {
	name = "db-sg"
	vpc_id = "${aws_vpc.main.id}"

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 3306
		to_port = 3306
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = -1
		to_port = -1
		protocol = "icmp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_key_pair" "auth" {
	key_name = "${var.key_name}"
	public_key = "${file(var.public_key_path)}"
}
resource "aws_key_pair" "auth1" {
	key_name = "${var.key_name1}"
	public_key = "${file(var.public_key_path1)}"
}

resource "aws_instance" "web" {
	ami = "ami-0d7ed3ddb85b521a6" // Amazon Linux 2 AMI (HVM), SSD Volume Type
	instance_type = "t2.micro"
	subnet_id = "${aws_subnet.public.id}"
	private_ip = "10.1.1.10"
	associate_public_ip_address = true
	security_groups = [
		"${aws_security_group.wsg.id}"
	]
	key_name = "${aws_key_pair.auth.id}"

	tags {
		Name = "WebSrv_practice_TF"
	}

}

resource "aws_eip" "lb" {
	instance = "${aws_instance.web.id}"
	associate_with_private_ip = "10.1.1.10"
	vpc = true
	depends_on = ["aws_internet_gateway.gw"]
}


resource "aws_instance" "db" {
	ami = "ami-0d7ed3ddb85b521a6" // Amazon Linux 2 AMI (HVM), SSD Volume Type
	instance_type = "t2.micro"
	subnet_id = "${aws_subnet.private.id}"
	private_ip = "10.1.2.10"
	security_groups = [
		"${aws_security_group.dsg.id}"
	]
	key_name = "${aws_key_pair.auth1.id}"

	tags {
		Name = "DBSrv_practice_TF"
	}

}


