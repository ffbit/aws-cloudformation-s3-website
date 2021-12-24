#!/bin/bash -ex

STACK_NAME='aws-cloudformation-s3-website'
BUCKET_NAME=$(echo -n "$(uuidgen)-cf-website" | tr '[:upper:]' '[:lower:]')

aws cloudformation create-stack \
    --stack-name "${STACK_NAME}" \
    --template-body file://s3_bucket_static_website-template.yaml \
    --parameters ParameterKey=BucketName,ParameterValue="${BUCKET_NAME}" \
    --capabilities CAPABILITY_IAM \
    --client-request-token my-unique-token \
    --output table

aws cloudformation wait stack-create-complete \
    --stack-name "${STACK_NAME}"
echo "CloudFormation stack '${STACK_NAME}' has been created."

BUCKET_S3_URL="s3://${BUCKET_NAME}/"
aws s3 sync . "${BUCKET_S3_URL}" --exclude="*" --include="*.html"

aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query "Stacks[*].Parameters" \
    --output table
aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query "Stacks[*].Outputs" \
    --output table


read -p 'Press enter to create, list, preview, and execute a change set to rename the bucket name: '

# Comment out to make the stack deletion fail.
aws s3 rm "${BUCKET_S3_URL}" --recursive

BUCKET_NAME="new-${BUCKET_NAME}"
CHANGE_SET_NAME="update-s3-bucket-name"
aws cloudformation create-change-set \
    --stack-name "${STACK_NAME}" \
    --template-body file://s3_bucket_static_website-template.yaml \
    --parameters ParameterKey=BucketName,ParameterValue="${BUCKET_NAME}" \
    --change-set-name "${CHANGE_SET_NAME}" \
    --capabilities CAPABILITY_IAM \
    --client-token my-unique-token-2 \
    --output table
aws cloudformation wait change-set-create-complete \
    --stack-name "${STACK_NAME}" \
    --change-set-name "${CHANGE_SET_NAME}"
aws cloudformation list-change-sets \
    --stack-name "${STACK_NAME}"
aws cloudformation describe-change-set \
    --stack-name "${STACK_NAME}" \
    --change-set-name "${CHANGE_SET_NAME}"


read -p 'Press enter to execute the change set: '
aws cloudformation execute-change-set \
    --stack-name "${STACK_NAME}" \
    --change-set-name "${CHANGE_SET_NAME}" \
    --client-request-token unique-token-3
aws cloudformation wait stack-update-complete \
    --stack-name "${STACK_NAME}"

BUCKET_S3_URL="s3://${BUCKET_NAME}/"
aws s3 sync . "${BUCKET_S3_URL}" --exclude="*" --include="*.html"

aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query "Stacks[*].Parameters" \
    --output table
aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query "Stacks[*].Outputs" \
    --output table


read -p 'Press enter to delete the stack: '

# Comment out to make the stack deletion fail.
aws s3 rm "${BUCKET_S3_URL}" --recursive

aws cloudformation delete-stack \
    --stack-name "${STACK_NAME}"

aws cloudformation wait stack-delete-complete \
    --stack-name "${STACK_NAME}"

echo "CloudFormation stack '${STACK_NAME}' has been deleted."

