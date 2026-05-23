#!/bin/bash

APP_NAME=$1
STATUS=$2
SLACK_WEBHOOK=$3

if [ -z "$SLACK_WEBHOOK" ]; then
    echo "Error: SLACK_WEBHOOK not provided"
    exit 1
fi

if [ "$STATUS" == "FAILED" ]; then
    COLOR="#ff0000"
    EMOJI=":x:"
elif [ "$STATUS" == "SUCCESS" ]; then
    COLOR="#36a64f"
    EMOJI=":white_check_mark:"
else
    COLOR="#ffaa00"
    EMOJI=":warning:"
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

PAYLOAD="{
    \"attachments\": [
        {
            \"color\": \"$COLOR\",
            \"title\": \"${EMOJI} Internal Tools Upgrade - ${APP_NAME}\",
            \"text\": \"Status: ${STATUS}\",
            \"fields\": [
                {
                    \"title\": \"Application\",
                    \"value\": \"${APP_NAME}\",
                    \"short\": true
                },
                {
                    \"title\": \"Status\",
                    \"value\": \"${STATUS}\",
                    \"short\": true
                },
                {
                    \"title\": \"Timestamp\",
                    \"value\": \"${TIMESTAMP}\",
                    \"short\": false
                }
            ]
        }
    ]
}"

curl -X POST -H 'Content-type: application/json' \
    --data "$PAYLOAD" \
    "$SLACK_WEBHOOK"
