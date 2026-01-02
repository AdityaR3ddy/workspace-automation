import boto3
import json

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('WorkspaceGovernance')

def handle(data):
    # 1. Extract inputs
    acc_id = data.get('aws-account-num')
    ws_name = data.get('new-ws-name')
    user_lob = data.get('lob', '').lower()

    # 2. DB Lookup
    response = table.get_item(Key={'account_id': acc_id})
    if 'Item' not in response:
        return {"statusCode": 400, "body": json.dumps({"message": "Account ID not registered."})}

    db_item = response['Item']
    db_lob = db_item['lob'].lower()
    env = db_item['env_type']

    # 3. Apply your 3 Rules
    # Rule A: LOB Match
    if user_lob != db_lob:
        return error_res(f"LOB mismatch. Expected {db_lob}.")

    # Rule B: Name Prefix
    if not ws_name.startswith(f"{db_lob}-"):
        return error_res(f"Name must start with {db_lob}-")

    # Rule C: Prod Suffix
    if env == "PROD" and not ws_name.endswith("-prod"):
        return error_res("PROD accounts require -prod suffix.")

    return {"statusCode": 200, "body": json.dumps({"message": "Governance Passed"})}

def error_res(msg):
    return {"statusCode": 400, "body": json.dumps({"message": msg})}