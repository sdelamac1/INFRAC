import json

def lambda_handler(event, context):
    # TODO: Implementar la lógica de esta función
    print("Función ejecutada exitosamente.")
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps({'message': 'Función ejecutada correctamente'})
    }