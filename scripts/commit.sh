#!/usr/bin/env bash
set -euo pipefail

printf -v red '\033[0;31m'
printf -v yellow '\033[0;33m'
printf -v green '\033[0;32m'
printf -v bold '\033[1m'
printf -v reset '\033[0m'

# Split the input string into an array of file paths
IFS=',' read -ra FILES <<< "$FILES"

echo "::group::Commit files"
echo "${yellow}${bold}Files to commit:${reset}" "${FILES[@]}"
echo "${yellow}${bold}Commit message:${reset} $COMMIT_MESSAGE"

# Check if the files exist and are readable then try to commit them
if [ ${#FILES[@]} -gt 0 ]; then
    # Prepare the JSON payload
    if ! JSON_PAYLOAD=$(jq -n \
        --arg query "$(cat $GITHUB_ACTION_PATH/api/createCommitOnBranch.gql)" \
        --arg repo "$REPOSITORY" \
        --arg branch "$REF_NAME" \
        --arg head "$(git rev-parse HEAD)" \
        --arg message "$COMMIT_MESSAGE" \
        '{query: $query, variables: {githubRepository: $repo, branchName: $branch, expectedHeadOid: $head, commitMessage: $message, files: []}}'); then
        echo "::error::Failed to prepare JSON payload."
        exit 1
    fi

    # Prepare the array of files to commit
    FILES_ARRAY=$(jq -n)

    # Loop through the files and add them to the JSON payload
    for file in "${FILES[@]}"; do
        # Check if the file exists and is readable
        if [ -f "$file" ] && [ -r "$file" ]; then
            base64_content=$(base64 -w0 "$file")
            FILES_ARRAY=$(echo "$FILES_ARRAY" | jq --arg path "$file" --arg content "$base64_content" '. + [{"path": $path, "contents": $content}]')
            echo "${green}Adding $file to commit.${reset}"
        else
            echo "::warning::${red}File $file does not exist, skipping.${reset}"
        fi
    done

    # Add the files array to the JSON payload
    JSON_PAYLOAD=$(echo "$JSON_PAYLOAD" | jq --argjson files "$FILES_ARRAY" '.variables.files |= $files')

    # Debug token preview using Bash substring
    echo "Token preview 2 (first 5 chars): ${GH_AUTH_TOKEN:0:5}"

    # Commit the changes
    if ! curl_output=$(curl --silent --show-error -X POST \
        -H "Authorization: token ${GH_AUTH_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$JSON_PAYLOAD" \
        https://api.github.com/graphql 2>&1) || ! echo "$curl_output" | grep -q '"commit"'; then
        echo "::error title=Failed to commit changes.::Curl output: $curl_output"
        exit 1
    fi
    echo "GitHub API response: $curl_output"
else
    # No files were provided for committing
    echo "::warning::No files to commit."
fi
echo "::endgroup::"