resource "aws_security_group" "allow_ssh_http" {
  # checkov:skip=CKV_AWS_24: Acceso SSH público temporalmente habilitado por motivos de desarrollo y pruebas
  name        = "allow_ssh_http"
  description = "Allow SSH and 3001"
  vpc_id = "${aws_vpc.main.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access from anywhere"
  }

  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    security_groups = [aws_security_group.sg-lb.id]
    description = "Allow HTTP (port 3001) from load balancer"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound HTTP traffic"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound tcp traffic"
  }

  egress {
  from_port   = 27017
  to_port     = 27017
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow outbound postgre traffic"
  }

}

resource "aws_instance" "app1" {
  # checkov:skip=CKV_AWS_126: El monitoreo detallado no es necesario en este entorno, evita costos adicionales
  ami                         = "ami-0157af9aea2eef346" 
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.subnet_a.id}"
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http.id]
  associate_public_ip_address = true
  ebs_optimized = true

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              set -xe  
              echo "Esperando red..."

              sleep 30

              sudo dnf clean all
              sudo dnf makecache
              
              sudo dnf install -y git
              sudo dnf install -y nodejs
              sudo dnf install -y npm

              sudo mkdir -p /opt/backend
              cd /opt/backend
              sudo git clone -b iac-develop https://github.com/sdelama1/chambea-peru.git chamba-api
              cd /opt/backend/chamba-api
              cd /opt/backend/chamba-api/Backend
              sudo npm install

                cat <<EOT > .env
                    PORT=${var.port}
                    MONGODB_URI=${local.mongo_uri}
                    JWT_SECRET=${var.jwt_secret}
                    BREVO_SENDER_EMAIL=${var.brevo_email}
                    BREVO_SENDER_NAME=${var.brevo_name}
                    APIS_PERU_KEY=${var.apis_peru_key}
                    MIGO_API_KEY=${var.migo_api_key}
                    FACTILIZA_API_KEY=${var.factiliza_key}
                    APIS_NET_PE_DNI_KEY=${var.apis_net_pe}
                    EOT

              sudo npm install -g pm2
              sudo pm2 start server.js --name chambea-backend
              sudo pm2 save
              sudo pm2 startup systemd      
              EOF

  tags = {
    Name = "app1"
  }

}
resource "aws_instance" "app2" {
  # checkov:skip=CKV_AWS_126: El monitoreo detallado no es necesario en este entorno, evita costos adicionales
  ami                         = "ami-0157af9aea2eef346" 
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.subnet_a.id}"
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http.id]
  associate_public_ip_address = true
  ebs_optimized = true

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              set -xe  
              echo "Esperando red..."

              sleep 30

              sudo dnf clean all
              sudo dnf makecache
              
              sudo dnf install -y git
              sudo dnf install -y nodejs
              sudo dnf install -y npm

              sudo mkdir -p /opt/backend
              cd /opt/backend
              sudo git clone -b iac-develop https://github.com/sdelama1/chambea-peru.git chamba-api
              cd /opt/backend/chamba-api
              cd /opt/backend/chamba-api/Backend
              sudo npm install

                cat <<EOT > .env
                    PORT=${var.port}
                    MONGODB_URI=${local.mongo_uri}
                    JWT_SECRET=${var.jwt_secret}
                    BREVO_SENDER_EMAIL=${var.brevo_email}
                    BREVO_SENDER_NAME=${var.brevo_name}
                    APIS_PERU_KEY=${var.apis_peru_key}
                    MIGO_API_KEY=${var.migo_api_key}
                    FACTILIZA_API_KEY=${var.factiliza_key}
                    APIS_NET_PE_DNI_KEY=${var.apis_net_pe}
                    EOT

              sudo npm install -g pm2
              sudo pm2 start server.js --name chambea-backend
              sudo pm2 save
              sudo pm2 startup systemd      
              EOF

  tags = {
    Name = "app2"
  }
}
