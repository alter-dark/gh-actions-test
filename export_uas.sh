#!/bin/bash
set -e

xcresult_path=${1:-"./output/scan/WWMobileUITests.xcresult"}

mkdir -p ./output/uas

# Get all tests summaries ids
function getTestSummaryIds() {
    xcrun xcresulttool graph --path "${xcresult_path}" | pcregrep -Mo1 "ActionTestSummary\n *\- Id: (.*)"
}

# Extract UAS log file
function extractLogFiles() {
    # Get a test summary
    testSummaryId=$1
    local actionTestSummary=$(xcrun xcresulttool get --format json --path "${xcresult_path}" --id "${testSummaryId}")

    # Get all the activities performed in the tests
    local activitySummaries=$(echo ${actionTestSummary} | jq -c '.activitySummaries._values')

    # Flatten all attachments in a array
    local allAttachments=$(echo ${activitySummaries} | jq -c '[ ..|.attachments? | select(.) ] | map(._values) | flatten')

    # Find attachment with specific name
    local uasAttachment=$(echo ${allAttachments} | jq -c '.[] | select(.uniformTypeIdentifier._value == "log") | select(.name._value | contains("uas"))')
    
    if [[ -n $uasAttachment ]]; then
        uasAttachmentId=$(echo ${uasAttachment} | jq -r '.payloadRef.id._value')
        uasAttachmentName=$(echo ${uasAttachment} | jq -r '.name._value')
        xcrun xcresulttool get --format raw --path "${xcresult_path}" --id "${uasAttachmentId}" > ./output/uas/${uasAttachmentName}
        echo "./output/uas/${uasAttachmentName}"
    fi
}

for TEST_SUMMARY_ID in $(getTestSummaryIds); do
    extractLogFiles "${TEST_SUMMARY_ID}"
done
