import boto3
import os

# Initialize outside the handler
dynamodb = boto3.resource('dynamodb')
# Best practice: use an environment variable for the table name
TABLE_NAME = os.environ.get('DYNAMODB_TABLE', 'WorkspaceGovernance')
table = dynamodb.Table(TABLE_NAME)

def handle(data, res_func):
    acc_id = data.get('aws-account-num')
    ws_name = data.get('new-ws-name')
    user_lob = data.get('lob', '').lower()

    if not acc_id or not ws_name:
        return res_func(400, "Missing Account ID or Workspace Name.")

    # DB Lookup
    try:
        response = table.get_item(Key={'account_id': acc_id})
        if 'Item' not in response:
            return res_func(400, f"Account {acc_id} not found in governance DB.")
        
        db_item = response['Item']
        db_lob = db_item['lob'].lower()
        env = db_item['env_type']

        # Rule 1: LOB Match
        if user_lob != db_lob:
            return res_func(400, f"LOB mismatch. Account belongs to {db_lob}.")

        # Rule 2: Prefix Check
        if not ws_name.startswith(f"{db_lob}-"):
            return res_func(400, f"Name must start with '{db_lob}-'")

        # Rule 3: Prod Suffix Check
        if env == "PROD" and not ws_name.endswith("-prod"):
            return res_func(400, "PROD accounts require '-prod' suffix.")

        return res_func(200, "Governance check passed!")
        
    except Exception as e:
        return res_func(500, f"Database error: {str(e)}")