import json

def lambda_handler(event, context):
    for record in event['Records']:
        try:
            sns_message_str = json.loads(record['body'])['Message']
            message_data = json.loads(sns_message_str)
            user_id = message_data.get('userId')
            event_id = message_data.get('eventId')

            # Aquí iría tu lógica para enviar el email con Amazon SES
            print(f"SIMULACIÓN: Enviando email de confirmación para el usuario {user_id} al evento {event_id}.")

        except Exception as e:
            print(f"Error procesando un mensaje: {e}")
            raise e # Lanza el error para que SQS reintente el mensaje

    return {'statusCode': 200, 'body': json.dumps('Procesamiento finalizado.')}