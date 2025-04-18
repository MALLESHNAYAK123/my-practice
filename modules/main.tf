#vpc

resource "aws_vpc" "vpc01" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "vpc-${var.project_name}"
  }
}

#subnets

resource "aws_subnet" "public-sub" {
  count                   = length(local.selected_azs)
  vpc_id                  = aws_vpc.vpc01.id
  availability_zone       = local.selected_azs[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-sub-${var.project_name}"
  }
}

resource "aws_subnet" "private-sub" {
  count             = length(local.selected_azs)
  vpc_id            = aws_vpc.vpc01.id
  availability_zone = local.selected_azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(local.selected_azs))
  tags = {
    Name = "private-sub-${var.project_name}"
  }
}

#gateways

resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.vpc01.id
  tags = {
    Name = "my-igw-${var.project_name}"
  }
}

resource "aws_eip" "eip" {
  tags = {
    Name = "eip-${var.project_name}"
  }
}

resource "aws_nat_gateway" "nat-gate" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public-sub[1].id
  tags = {
    Name = "nat-gate-${var.project_name}"
  }
}

#routes

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc01.id
  route {
    gateway_id = aws_internet_gateway.my-igw.id
    cidr_block = "0.0.0.0/0"
  }
  tags = {
    Name = "public-rt-${var.project_name}"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.vpc01.id
  route {
    nat_gateway_id = aws_nat_gateway.nat-gate.id
    cidr_block     = "0.0.0.0/0"
  }
  tags = {
    Name = "private-rt-${var.project_name}"
  }
}

#route table association

resource "aws_route_table_association" "pub-asso" {
  count          = length(aws_subnet.public-sub)
  subnet_id      = aws_subnet.public-sub[count.index].id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "pvt-asso" {
  count          = length(aws_subnet.private-sub)
  subnet_id      = aws_subnet.private-sub[count.index].id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_security_group" "my-sg" {
  description = "security group for my network"
  vpc_id      = aws_vpc.vpc01.id
}

resource "aws_security_group_rule" "allow_all_traffic_ipv4_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my-sg.id
}

resource "aws_security_group_rule" "allow_all_traffic_ipv4_egress" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my-sg.id
}
