resource "aws_s3_bucket" "frontend" {
  bucket         = "frontend-chambea-peru"
  force_destroy  = true
  # checkov:skip=CKV_AWS_18: No se habilita el logging ya que genera costos adicionales y altera la arquitectura diseñada sin bucket de logs
  # checkov:skip=CKV_AWS_144: Bucket dedicado al backend de Terraform, replicación entre regiones no es necesaria
  # checkov:skip=CKV_AWS_145: No se usa cifrado KMS para evitar costos adicionales por gestión de claves; el bucket utiliza AES256 y no almacena datos sensibles.
  # checkov:skip=CKV2_AWS_62: No necesitamos eventos en este bucket por ahora
}

resource "aws_s3_bucket_versioning" "frontend_versioning" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "frontend_lifecycle" {
  # checkov:skip=CKV_AWS_300: No se agrega abort de multipart uploads ya que el bucket es usado solo por Terraform y no se esperan cargas incompletas
  bucket = aws_s3_bucket.frontend.id

  rule {
    id     = "delete-old-objects"
    status = "Enabled"

    expiration {
      days = 2
    }

    filter {
      prefix = ""
    }
  }
}

resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.frontend_oai.iam_arn
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.frontend_block
  ]
}

resource "aws_s3_bucket_public_access_block" "frontend_block" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "null_resource" "upload_frontend" {
  triggers = {
    api_url = aws_apigatewayv2_stage.default.invoke_url
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      # 1. Limpiar y clonar fresco
      rm -rf ./frontend_temp
      git clone -b iac-develop https://github.com/sdelama1/chambea-peru.git frontend_temp
      
      # 2. Entrar a la carpeta
      cd frontend_temp/Frontend || exit 1

      # 3. Reemplazar el marcador por la URL real
      API_URL="${aws_apigatewayv2_stage.default.invoke_url}"
      API_URL=$${API_URL%/}

      echo "Inyectando URL del Backend: $API_URL"

      grep -rFl '__BACKEND_URL__' . | xargs sed -i "s|__BACKEND_URL__|$API_URL|g"

      # 4. Subir al S3
      aws s3 sync . s3://${aws_s3_bucket.frontend.bucket} --delete
    EOT
    
    interpreter = ["/bin/bash", "-c"]
  }
  
  depends_on = [aws_s3_bucket.frontend, aws_apigatewayv2_stage.default]
}