#!/bin/bash
set -e

CLUSTER_NAME="prod-eks-mongo"
NAMESPACE="sync"
SERVICE_ACCOUNT="sync-sa"
ROLE_NAME="mongodb-sync-role"
TRUST_POLICY_FILE="$HOME/mongodb-sync/scripts/policy/sync-trust-policy.json"
S3_POLICY_FILE="$HOME/mongodb-sync/scripts/policy/sync-s3-policy.json"
REGION="us-east-1"

echo "🔎 Fetching OIDC ID for cluster $CLUSTER_NAME..."
OIDC_URL=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.identity.oidc.issuer" --output text)
OIDC_ID=$(basename "$OIDC_URL")

echo "✅ OIDC URL: $OIDC_URL"
echo "✅ OIDC ID: $OIDC_ID"

echo "📝 Writing trust policy..."
cat > $TRUST_POLICY_FILE <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::561030001202:oidc-provider/oidc.eks.$REGION.amazonaws.com/id/$OIDC_ID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.$REGION.amazonaws.com/id/$OIDC_ID:sub": "system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT",
          "oidc.eks.$REGION.amazonaws.com/id/$OIDC_ID:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF

echo "🛠 Checking if IAM role $ROLE_NAME exists..."
if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  echo "ℹ️ Role exists. Updating trust policy..."
  aws iam update-assume-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-document file://$TRUST_POLICY_FILE
else
  echo "🛠 Creating IAM role..."
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document file://$TRUST_POLICY_FILE
fi

echo "📝 Writing S3 inline policy..."
aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "sync-s3-policy" \
  --policy-document file://$S3_POLICY_FILE

ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query "Role.Arn" --output text)
echo "✅ Role ARN: $ROLE_ARN"

echo "📦 Patching ServiceAccount $SERVICE_ACCOUNT..."
kubectl -n $NAMESPACE apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $SERVICE_ACCOUNT
  namespace: $NAMESPACE
  annotations:
    eks.amazonaws.com/role-arn: "$ROLE_ARN"
EOF

echo "🎉 Sync IRSA setup complete!"

