import json
import os
import boto3
import psycopg2

# Inicializar clientes fuera del handler para reutilizarlos
sns_client = boto3.client('sns')
db_host = os.environ.get('DB_HOST')
db_user = os.environ.get('DB_USER')
db_password = os.environ.get('DB_PASSWORD')
db_name = os.environ.get('DB_NAME')
sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        user_id = body.get('userId')
        event_id = body.get('eventId')

        if not user_id or not event_id:
            return {'statusCode': 400, 'body': json.dumps({'message': 'Faltan userId o eventId'})}

        # Conectar y escribir en la BD
        conn = psycopg2.connect(host=db_host, user=db_user, password=db_password, dbname=db_name)
        with conn.cursor() as cur:
            cur.execute("INSERT INTO registrations (user_id, event_id) VALUES (%s, %s)", (user_id, event_id))
        conn.commit()
        conn.close()

        # Publicar mensaje en SNS
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Message=json.dumps({'userId': user_id, 'eventId': event_id})
        )

        return {'statusCode': 201, 'body': json.dumps({'message': 'Registro exitoso!'})}

    except Exception as e:
        print(f"ERROR: {e}")
        return {'statusCode': 500, 'body': json.dumps({'message': 'Error interno del servidor'})}