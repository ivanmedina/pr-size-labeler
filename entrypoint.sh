#!/bin/bash
set -e

if [[ -z "$GITHUB_REPOSITORY" ]]; then
    echo "The env variable GITHUB_REPOSITORY is required"
    exit 1
fi

if [[ -z "$GITHUB_EVENT_PATH" ]]; then
    echo "The env variable GITHUB_EVENT_PATH is required"
    exit 1
fi

GITHUB_TOKEN="$1"
xs_size_max="$2"
s_size_max="$3"
m_size_max="$4"
l_size_max="$5"
fail_if_xl="$6"

URI="https://api.github.com"
API_HEADER="Accept: application/vnd.github.v3+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

number=$( jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH" )

autolabel(){

    body=$( curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${URI}/repos/${GITHUB_REPOSITORY}/pulls/${number}" )
    additions=$( echo "$body" | jq '.additions' )
    deletions=$( echo "$body" | jq '.deletions' )
    total_modifications=$( echo "$additions + $deletions" | bc )
    label_to_add=$( label_for "$total_modifications" )

    curl -sSL \
        -H "${AUTH_HEADER}" \
        -H "${API_HEADER}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"labels\":[\"${label_to_add}\"]}" \
        "${URI}/repos/${GITHUB_REPOSITORY}/issues/${number}/labels"

    if [ "$label_to_add" == "size/xl" ] && [ "$fail_if_xl" == "true" ]; then
        message="Pr is xl, please, short this!"
        comment $message
        exit 1
    fi
}


comment() {

    local -r comment="$1"
    # jq -n --arg msg "$comment" '{body: $msg }' > tmp.txt
    curl -sSL \
        -H "${AUTH_HEADER}" \
        -H "${API_HEADER}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d '{"body":"Probando"}' \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}/comments"
}

label_for(){
    if [ "$1" -lt "$xs_size_max" ]; then
        label="size/xs"
    elif [ "$1" -lt "$s_size_max" ]; then
        label="size/s"
    elif [ "$1" -lt "$m_size_max" ]; then
        label="size/m"
    elif [ "$1" -lt "$l_size_max" ]; then
        label="size/l"
    else 
        label="size/xl"
    fi
    
    echo "$label"
}

autolabel

exit $?