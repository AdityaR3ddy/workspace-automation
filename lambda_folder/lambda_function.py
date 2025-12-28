import json

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")
    
    # This is where we will eventually add the logic to 
    # call Terraform Cloud's API to create workspaces.
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*' # Important for your frontend
        },
        'body': json.dumps({
            'message': 'Hello from Python Lambda!',
            'received_data': event.get('body')
        })
    }