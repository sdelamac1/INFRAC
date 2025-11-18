resource "aws_security_group" "allow_ssh_http" {
  # checkov:skip=CKV_AWS_24: Acceso SSH público temporalmente habilitado por motivos de desarrollo y pruebas
  name        = "allow_ssh_http"
  description = "Allow SSH and 3001"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    security_groups = [aws_security_group.sg-lb.id]
    description = "Allow HTTP (port 3001) from load balancer"
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Prometheus access from anywhere (for Grafana)"
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

# 1. INSTALAR PAQUETES DEL SISTEMA 
sudo dnf clean all
sudo dnf makecache
sudo dnf install -y git
sudo dnf install -y nodejs
sudo dnf install -y npm

# 2. INSTALAR PROMETHEUS Y NODE EXPORTER 
echo "Instalando Node Exporter y Prometheus..."

# 2.1 Instalar Node Exporter (Métricas de la máquina)
sudo useradd --no-create-home --shell /bin/false node_exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvf node_exporter-1.7.0.linux-amd64.tar.gz
sudo mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin
rm -rf node_exporter-1.7.0.linux-amd64*

sudo cat <<EOT_SERVICE > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=multi-user.target
EOT_SERVICE

sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# 2.2 Instalar Prometheus (Servidor de monitoreo)
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.53.1/prometheus-2.53.1.linux-amd64.tar.gz
tar xvf prometheus-2.53.1.linux-amd64.tar.gz
sudo mv prometheus-2.53.1.linux-amd64/prometheus /usr/local/bin/
sudo mv prometheus-2.53.1.linux-amd64/promtool /usr/local/bin/
sudo mv prometheus-2.53.1.linux-amd64/consoles /etc/prometheus
sudo mv prometheus-2.53.1.linux-amd64/console_libraries /etc/prometheus
rm -rf prometheus-2.53.1.linux-amd64*

# 2.3 Configurar Prometheus (CON INDENTACIÓN CORRECTA)
sudo cat <<EOT_CONFIG > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOT_CONFIG

sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

# 2.4 Crear servicio de Prometheus (CON INDENTACIÓN CORRECTA)
sudo cat <<EOT_PROMETHEUS_SERVICE > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file /etc/prometheus/prometheus.yml \
  --storage.tsdb.path /var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries
[Install]
WantedBy=multi-user.target
EOT_PROMETHEUS_SERVICE

sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
echo "Instalación de monitoreo completa."

# 3. INSTALAR TU APLICACIÓN 
sudo mkdir -p /opt/backend
cd /opt/backend
sudo git clone -b iac-develop https://github.com/sdelama1/chambea-peru.git chamba-api
cd /opt/backend/chamba-api
cd /opt/backend/chamba-api/Backend
sudo npm install

cat <<EOT > .env
PORT=3001
MONGODB_URI=${var.MONGO_CONNECTION_URI}
JWT_SECRET=superMegaUltraSecretoDeChambeaPeru2025!@#$
BREVO_SENDER_EMAIL=dangamerby12@gmail.com
BREVO_SENDER_NAME=Chambea Perú
APIS_PERU_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImZmZXJ0b3JyZXMxMkBnbWFpbC5jb20ifQ.Rohdvwz_gGV7fMNnnit9ykYvWOCIu8ifoKTSj9_Pd2o
MIGO_API_KEY=VJAB4Was3tjfWXkEQ4ViuteyDcmwoJedrZ25zg1ky5trE5TrCE1pyhcg4r7d
FACTILIZA_API_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzODk3NSIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvcm9sZSI6ImNvbnN1bHRvciJ9.Xv_6EC1pTnI1n_iJD61Irq77q9Nhgurp13RFu-z98H8
APIS_NET_PE_DNI_KEY=sk_11501.j0fGHm4jUrMCFjU4RXKq8EUQUDDoPWsH
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
  subnet_id                   = "${aws_subnet.subnet_b.id}"
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http.id]
  associate_public_ip_address = true
  ebs_optimized = true

  user_data = <<-EOF
#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -xe
echo "Esperando red..."
sleep 30

# 1. INSTALAR PAQUETES DEL SISTEMA 
sudo dnf clean all
sudo dnf makecache
sudo dnf install -y git
sudo dnf install -y nodejs
sudo dnf install -y npm

# 2. INSTALAR PROMETHEUS Y NODE EXPORTER 
echo "Instalando Node Exporter y Prometheus..."

# 2.1 Instalar Node Exporter (Métricas de la máquina)
sudo useradd --no-create-home --shell /bin/false node_exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvf node_exporter-1.7.0.linux-amd64.tar.gz
sudo mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin
rm -rf node_exporter-1.7.0.linux-amd64*

sudo cat <<EOT_SERVICE > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=multi-user.target
EOT_SERVICE

sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# 2.2 Instalar Prometheus (Servidor de monitoreo)
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.53.1/prometheus-2.53.1.linux-amd64.tar.gz
tar xvf prometheus-2.53.1.linux-amd64.tar.gz
sudo mv prometheus-2.53.1.linux-amd64/prometheus /usr/local/bin/
sudo mv prometheus-2.53.1.linux-amd64/promtool /usr/local/bin/
sudo mv prometheus-2.53.1.linux-amd64/consoles /etc/prometheus
sudo mv prometheus-2.53.1.linux-amd64/console_libraries /etc/prometheus
rm -rf prometheus-2.53.1.linux-amd64*

# 2.3 Configurar Prometheus (CON INDENTACIÓN CORRECTA)
sudo cat <<EOT_CONFIG > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOT_CONFIG

sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

# 2.4 Crear servicio de Prometheus (CON INDENTACIÓN CORRECTA)
sudo cat <<EOT_PROMETHEUS_SERVICE > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file /etc/prometheus/prometheus.yml \
  --storage.tsdb.path /var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries
[Install]
WantedBy=multi-user.target
EOT_PROMETHEUS_SERVICE

sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
echo "Instalación de monitoreo completa."

# 3. INSTALAR TU APLICACIÓN 
sudo mkdir -p /opt/backend
cd /opt/backend
sudo git clone -b iac-develop https://github.com/sdelama1/chambea-peru.git chamba-api
cd /opt/backend/chamba-api
cd /opt/backend/chamba-api/Backend
sudo npm install

cat <<EOT > .env
PORT=3001
MONGODB_URI=${var.MONGO_CONNECTION_URI}
JWT_SECRET=superMegaUltraSecretoDeChambeaPeru2025!@#$
BREVO_SENDER_EMAIL=dangamerby12@gmail.com
BREVO_SENDER_NAME=Chambea Perú
APIS_PERU_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImZmZXJ0b3JyZXMxMkBnbWFpbC5jb20ifQ.Rohdvwz_gGV7fMNnnit9ykYvWOCIu8ifoKTSj9_Pd2o
MIGO_API_KEY=VJAB4Was3tjfWXkEQ4ViuteyDcmwoJedrZ25zg1ky5trE5TrCE1pyhcg4r7d
FACTILIZA_API_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzODk3NSIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvcm9sZSI6ImNvbnN1bHRvciJ9.Xv_6EC1pTnI1n_iJD61Irq77q9Nhgurp13RFu-z98H8
APIS_NET_PE_DNI_KEY=sk_11501.j0fGHm4jUrMCFjU4RXKq8EUQUDDoPWsH
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