import json

def lambda_handler(event, context):
    # Log the event to CloudWatch so we can see what Postman sent
    print(f"Event: {json.dumps(event)}")
    
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps({
            "status": "success",
            "message": "Connected to Lambda!"
        })
    }