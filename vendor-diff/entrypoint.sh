#!/bin/sh

if [[ -z "$GITHUB_WORKSPACE" ]]; then
	echo "Missing required env GITHUB_WORKSPACE"
	exit 1
fi

set +e
DIFF=$(sh -c "python /vendor-diff.py --path $GITHUB_WORKSPACE" 2>&1)
SUCCESS=$?
echo "$DIFF"
set -e

if [[ $SUCCESS -eq 0 ]]; then
	exit 0
fi

payload () {
	# Generate comment payload for PR with vendor diff
	COMMENT="#### Vendor directory is not in sync with \`go.mod\`
\`\`\`
$DIFF
\`\`\`

Run \`go mod vendor\` to update the vendor directory and commit the changes.

*Workflow: \`$GITHUB_WORKFLOW\`, Action: \`$GITHUB_ACTION\`*"

	echo '{}' | jq --arg body "$COMMENT" '.body = $body'
}

action=$(cat /github/workflow/event.json | jq -r .action)

if [[ "$GITHUB_EVENT_NAME" == "pull_request" && "$action" == "opened" ]]; then
	# Comment only when PRs are first opened
	comment=$(payload)
	url=$(cat /github/workflow/event.json | jq -r .pull_request.comments_url)
	curl -s -S -H "Authorization: token $GITHUB_TOKEN" \
		--header "Content-Type: application/json" \
		--data "$comment" "$url"

elif [[ "$GITHUB_EVENT_NAME" == "push" ]]; then
	# Fetch PRs associated with commit from push event to post diff comments
	comment=$(payload)
	pr_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/commits/${GITHUB_SHA}/pulls"
	urls=$(curl -s -S -H "Authorization: token $GITHUB_TOKEN" \
		--header "Content-Type: application/json" \
		--header "Accept: application/vnd.github.groot-preview+json" \
		"$pr_url" | jq -r '.[] | select(.state=="open") | .comments_url')

	for url in $urls; do
		curl -s -S -H "Authorization: token $GITHUB_TOKEN" \
		--header "Content-Type: application/json" \
		--data "$comment" "$url"
	done
fi

exit $SUCCESS
