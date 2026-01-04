import json
import base64
from handlers import new_workspace

# Define these globally so they never change between OPTIONS and POST
CORS_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Amz-Date, X-Api-Key, X-Amz-Security-Token"
}

def lambda_handler(event, context):
    # Detection for HTTP API v2 payload format
    method = event.get('requestContext', {}).get('http', {}).get('method', 'POST')
    
    # 1. Handle OPTIONS (Preflight)
    if method == 'OPTIONS':
        return build_res(200, "CORS Preflight OK")

    try:
        # 2. Extract and Parse Body
        body_raw = event.get('body', '{}')
        if event.get('isBase64Encoded', False):
            body_raw = base64.b64decode(body_raw).decode('utf-8')
        
        body = json.loads(body_raw)
        req_type = body.get('requestType')

        # 3. Routing
        if req_type == "new-workspace":
            # IMPORTANT: Ensure your handler actually returns the result of build_res!
            return new_workspace.handle(body, build_res)
        
        return build_res(400, f"Unknown type: {req_type}")

    except Exception as e:
        # If this part triggers, build_res MUST still send the headers
        return build_res(500, f"Error: {str(e)}")

def build_res(code, msg):
    return {
        "statusCode": code,
        "headers": CORS_HEADERS, # Use the global dictionary
        "body": json.dumps({"message": msg})
    }