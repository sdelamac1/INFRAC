import json
import os
import bcrypt # Librería para encriptar contraseñas
import psycopg2
from psycopg2 import sql

# Variables de entorno para la base de datos
db_host = os.environ.get('DB_HOST')
db_user = os.environ.get('DB_USER')
db_password = os.environ.get('DB_PASSWORD')
db_name = os.environ.get('DB_NAME')

def lambda_handler(event, context):
    try:
        # 1. Obtener email y contraseña del cuerpo de la petición
        body = json.loads(event.get('body', '{}'))
        email = body.get('email')
        password = body.get('password')

        if not email or not password:
            return {'statusCode': 400, 'body': json.dumps({'message': 'Email y contraseña son requeridos'})}

        # 2. Encriptar la contraseña (la parte más importante)
        # Nunca guardes contraseñas en texto plano
        salt = bcrypt.gensalt()
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), salt)

        # 3. Conectar a la base de datos y guardar el nuevo usuario
        conn = psycopg2.connect(host=db_host, user=db_user, password=db_password, dbname=db_name)
        with conn.cursor() as cur:
            # Usamos 'INSERT INTO ... ON CONFLICT' para manejar el caso de que el email ya exista
            query = sql.SQL("""
                INSERT INTO users (email, password_hash) VALUES (%s, %s)
                ON CONFLICT (email) DO NOTHING
                RETURNING user_id;
            """)
            cur.execute(query, (email, hashed_password.decode('utf-8')))
            
            # Verificar si se insertó una nueva fila
            result = cur.fetchone()
            if result is None:
                # Si fetchone() es None, significa que el email ya existía (ON CONFLICT)
                return {'statusCode': 409, 'body': json.dumps({'message': 'El email ya está registrado'})}

        conn.commit()
        conn.close()

        return {
            'statusCode': 201, # 201 Created es el código correcto para un nuevo recurso
            'body': json.dumps({'message': 'Usuario creado exitosamente', 'userId': result[0]})
        }

    except Exception as e:
        print(f"ERROR: {e}")
        return {'statusCode': 500, 'body': json.dumps({'message': 'Error interno del servidor'})}