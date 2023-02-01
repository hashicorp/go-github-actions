#!/bin/sh
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


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

if [[ "$GITHUB_EVENT_NAME" == "pull_request" ]]; then
	if [[ "$action" == "opened" || "$action" == "reopened" || "$action" == "synchronized" ]]; then
		comment=$(payload)
		url=$(cat /github/workflow/event.json | jq -r .pull_request.comments_url)
		curl -s -S -H "Authorization: token $GITHUB_TOKEN" \
			--header "Content-Type: application/json" \
			--data "$comment" "$url"
	fi
fi

exit $SUCCESS
