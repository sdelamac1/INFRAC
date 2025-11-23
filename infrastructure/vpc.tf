# Prueba commit- creando nueva rama
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "CorpEvent-VPC" }
}

# --- 1. Crear la "Puerta a Internet" ---
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "CorpEvent-IGW"
  }
}

# --- 2. Crear la "Tabla de Rutas" para dirigir el tráfico ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0" # Tráfico a cualquier IP
    gateway_id = aws_internet_gateway.gw.id # Enviar a la puerta de internet
  }
  tags = {
    Name = "CorpEvent-Public-RT"
  }
}

# --- 3. Subnets Públicas ---
resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true # Importante para que los recursos sean accesibles
  tags                    = { Name = "CorpEvent-Subnet-A" }
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "CorpEvent-Subnet-B" }
}

# --- 4. Asociar las rutas a las subnets ---
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public.id
}
