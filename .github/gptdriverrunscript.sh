#!/usr/bin/env bash

set -eo pipefail

# Constants should ideally be set as environment variables for security
readonly API_URL="https://api.mobileboost.io"
readonly API_ORG_KEY="${API_ORG_KEY}"
readonly API_TOKEN="${API_TOKEN:-null}"
readonly TEST_TIMEOUT="${TEST_TIMEOUT:-7200}"
readonly TEST_TAGS="${TEST_TAGS:-}"

# Function to post data using curl and handle errors
post_data() {
  local url=$1
  local body=$2
  if ! response=$(curl -s -f -X POST -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" -d "$body" "$url"); then
    echo "Error: Network request failed with error $response" >&2
    exit 1
  fi
  echo "$response"
}

# Validate inputs
if [[ -z "$1" || -z "$2" ]]; then
  echo "Usage: $0 <build_filename> <build_platform>"
  exit 1
fi

# Validate environment variables
if [[ -z "$API_ORG_KEY" ]]; then
  echo "Please set API_ORG_KEY to your organization key"
  exit 1
fi

buildFilename="$1"
buildPlatform="$2"
tags=()

# Check if TEST_TAGS is provided and split into an array
if [[ -n "$TEST_TAGS" ]]; then
  IFS=',' read -ra tags <<< "$TEST_TAGS"
fi

# Upload build file
echo -n "Uploading build from $buildFilename for $buildPlatform: "
if ! uploadedBuildResponse=$(curl -s -f -X POST \
                  -H "Authorization: Bearer $API_TOKEN" \
                  -H "Content-Type: multipart/form-data" \
                  -F "build=@$buildFilename" \
                  -F "organisation_key=$API_ORG_KEY" \
                  -F "platform=$buildPlatform" \
                  -F "metadata={}" \
                  "$API_URL/uploadBuild/"); then
  echo "Error: Failed to upload build" >&2
  exit 1
fi

# Extract the buildId
if ! buildId=$(jq -r '.buildId' <<< "$uploadedBuildResponse") || [ -z "$buildId" ]; then
  echo "Error: Failed to extract build ID from the response" >&2
  exit 1
fi
echo "uploaded (ID: $buildId), app link: $(jq -r '.app_link' <<< "$uploadedBuildResponse")"

# Execute test suite
echo "Executing test suite..."
jsonPayload="{\"organisationId\": \"$API_ORG_KEY\", \"uploadId\": \"$buildId\""
if [ ${#tags[@]} -gt 0 ]; then
  jsonTags=$(printf ',\"%s\"' "${tags[@]}")
  jsonTags="[${jsonTags:1}]"
  jsonPayload+=", \"tags\": $jsonTags"
fi
jsonPayload+="}"
if ! testSuiteRunId=$(post_data "$API_URL/tests/execute" "$jsonPayload" | jq -r '.test_suite_ids[0]') || [ -z "$testSuiteRunId" ]; then
  echo "Error: Test suite execution failed" >&2
  exit 1
fi

# Wait for test suite to finish
echo -n "Waiting for test suite to finish..."
startTime=$(date +%s)
while true; do
  if ! testSuiteData=$(curl -s -f "$API_URL/testSuiteRuns/$testSuiteRunId/gh"); then
    echo "Error: Failed to retrieve test suite data" >&2
    exit 1
  fi
  testSuiteStatus=$(jq -r '.status' <<< "$testSuiteData")

  if [[
        "$testSuiteStatus" == "completed"
      ]]; then
    echo "Status is $testSuiteStatus!" >&2
    break
  fi

  if (( $(date +%s) - startTime >= TEST_TIMEOUT )); then
    echo "Timeout exceeded while waiting for test suite to finish." >&2
    exit 1
  fi

  echo -n "."
  sleep 1
done
echo " done!"

# Write test suite summary to file if available
if [[ -n "$GITHUB_STEP_SUMMARY" && -w "$GITHUB_STEP_SUMMARY" ]]; then
  jq -r '.markdown' <<< "$testSuiteData" >> "$GITHUB_STEP_SUMMARY"
  echo "Step summary written to $GITHUB_STEP_SUMMARY"
fi

# Check test suite result
if ! testSuiteResult=$(jq -r '.result' <<< "$testSuiteData"); then
  echo "Test suite did not pass, result: $testSuiteResult" >&2
  exit 1
fi

if [[ "$testSuiteResult" == "succeeded" ]]; then
  echo "Test passed successfully"
  exit 0
else
  echo "Test suite did not pass, result: $testSuiteResult" >&2
  exit 1
fi
