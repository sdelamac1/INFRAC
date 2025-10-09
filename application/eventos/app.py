import json

def lambda_handler(event, context):
    """
    Función de marcador de posición.
    TODO: Implementar la lógica real aquí.
    """
    print("Función ejecutada exitosamente.")
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps({'message': 'Función ejecutada correctamente, pendiente de implementación.'})
    }