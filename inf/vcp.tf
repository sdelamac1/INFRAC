data "aws_availability_zones" "available" {}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.common_tags, { Name = "${var.project_name}-vpc" })
}

# Subredes públicas (2 AZ)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_a_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_name}-public-a" }
}
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_b_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_name}-public-b" }
}

# Subredes privadas (2 AZ)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.priv_a_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = { Name = "${var.project_name}-private-a" }
}
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.priv_b_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = { Name = "${var.project_name}-private-b" }
}

# Internet Gateway y tabla de ruta pública
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.project_name}-igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.project_name}-public-rt" }
}
resource "aws_route" "public_inet" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "pub_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# NAT Gateway (en pública A) + tabla de rutas privadas
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = { Name = "${var.project_name}-eip-nat" }
}
resource "aws_nat_gateway" "nat" {
  subnet_id     = aws_subnet.public_a.id
  allocation_id = aws_eip.nat.id
  tags = { Name = "${var.project_name}-nat" }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.project_name}-private-rt" }
}
resource "aws_route" "priv_out" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}
resource "aws_route_table_association" "prv_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "prv_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}

# SG para Lambdas
resource "aws_security_group" "lambda_sg" {
  name   = "${var.project_name}-lambda-sg"
  vpc_id = aws_vpc.this.id
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
  tags = var.common_tags
}

# SG para RDS (solo desde Lambda SG)
resource "aws_security_group" "rds_sg" {
  name   = "${var.project_name}-rds-sg"
  vpc_id = aws_vpc.this.id
  ingress {
    from_port       = var.db_engine == "postgres" ? 5432 : 3306
    to_port         = var.db_engine == "postgres" ? 5432 : 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
  tags = var.common_tags
}
