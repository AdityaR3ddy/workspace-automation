import json
import base64
from handlers import new_workspace

def lambda_handler(event, context):
    try:
        # 1. Handle HTTP API v2 Body Parsing
        body_str = event.get('body', '{}')
        
        # If the body is base64 encoded (common in some browser requests)
        if event.get('isBase64Encoded', False):
            body_str = base64.b64decode(body_str).decode('utf-8')
            
        body = json.loads(body_str)
        request_type = body.get('request-type')

        # 2. Route to the correct handler
        if request_type == "new-workspace":
            # We pass the build_res function so the handler can use it
            return new_workspace.handle(body, build_res)
        
        elif request_type in ["update-version", "convert-to-tep", "change-aws-account", 
                            "access-group-update", "misc-request"]:
            return build_res(403, f"The feature '{request_type}' is currently in development.")
        
        else:
            return build_res(400, "Unknown request type.")

    except Exception as e:
        return build_res(500, f"System Error: {str(e)}")

def build_res(code, msg):
    """Utility to ensure CORS headers are always present."""
    return {
        "statusCode": code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps({"message": msg})
    }