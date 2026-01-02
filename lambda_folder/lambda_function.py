import json
from handlers import new_workspace

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        request_type = body.get('request-type')

        # Route to the correct handler
        if request_type == "new-workspace":
            return new_workspace.handle(body)
        
        # All other types return "In Development"
        elif request_type in ["update-version", "convert-to-tep", "change-aws-account", 
                            "access-group-update", "misc-request"]:
            return build_res(403, f"The feature '{request_type}' is currently in development.")
        
        else:
            return build_res(400, "Unknown request type.")

    except Exception as e:
        return build_res(500, f"System Error: {str(e)}")

def build_res(code, msg):
    return {
        "statusCode": code,
        "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
        "body": json.dumps({"message": msg})
    }