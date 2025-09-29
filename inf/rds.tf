resource "aws_db_subnet_group" "dbsubnets" {
  name       = "${var.project_name}-dbsubnets"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_db_instance" "db" {
  identifier              = "${var.project_name}-db"
  engine                  = var.db_engine
  engine_version          = var.db_engine_ver
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = var.db_username
  password                = var.db_password
  db_name                 = var.db_name
  multi_az                = false
  publicly_accessible     = false
  storage_encrypted       = true
  db_subnet_group_name    = aws_db_subnet_group.dbsubnets.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  deletion_protection     = false
  tags = var.common_tags
}
