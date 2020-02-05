#!/bin/bash

document="test-document-prod"
document_name=$(aws ssm list-documents --document-filter-list "key=Name,value=${document}" --query "DocumentIdentifiers[0].Name" --output text)

if [ "$document_name" = "${document}" ]; then
    echo "The document ${document_name} exists, continue execution"
    executionId=$(aws ssm start-automation-execution --document-name "${document_name}" --query "AutomationExecutionId" --output text)
    echo "Document execution ID is ${executionId}"
    while [ "$(aws ssm describe-automation-executions  --filter "Key=ExecutionId,Values=${executionId}" --query "AutomationExecutionMetadataList[].AutomationExecutionStatus" --output text)" = "InProgress" ]; do
        echo "Execution ${executionId} is in progress"
        sleep 60
    done
else
    echo "Didn't find ${document_name}"
fi

aws ssm describe-automation-executions  --filter "Key=ExecutionId,Values=${executionId}"
echo "Finished"
