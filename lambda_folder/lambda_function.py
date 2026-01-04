import json
import base64
import logging
from handlers import new_workspace

# Setup logging outside the handler (reused across warm starts)
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Define common CORS headers once
CORS_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
}

def lambda_handler(event, context):
    # 1. Immediate Preflight (OPTIONS) return
    # Use 'routeKey' for HTTP APIs or 'httpMethod' for REST APIs
    method = event.get('httpMethod') or event.get('requestContext', {}).get('http', {}).get('method')
    
    if method == 'OPTIONS':
        return build_res(200)

    try:
        # 2. Optimized Body Parsing
        body_raw = event.get('body', '{}')
        if event.get('isBase64Encoded', False):
            body_raw = base64.b64decode(body_raw).decode('utf-8')
        
        body = json.loads(body_raw)
        req_type = body.get('request-type')

        # 3. Clean Routing Logic
        routes = {
            "new-workspace": lambda: new_workspace.handle(body, build_res),
            "update-version": "in-dev",
            "convert-to-tep": "in-dev",
            "change-aws-account": "in-dev",
        }

        action = routes.get(req_type)
        
        if callable(action):
            return action()
        elif action == "in-dev":
            return build_res(403, f"Feature '{req_type}' is in development.")
        else:
            return build_res(400, f"Invalid request type: {req_type}")

    except json.JSONDecodeError:
        return build_res(400, "Invalid JSON format in request body.")
    except Exception as e:
        logger.error(f"Execution Error: {str(e)}", exc_info=True)
        return build_res(500, "Internal Server Error")

def build_res(code, msg=None):
    """Unified response builder ensuring CORS is always attached."""
    response = {
        "statusCode": code,
        "headers": CORS_HEADERS,
    }
    if msg:
        response["body"] = json.dumps({"message": msg})
    return response