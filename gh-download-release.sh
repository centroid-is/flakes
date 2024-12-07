#!/usr/bin/env bash
#
# gh-dl-release! It works!
# 
# This script downloads an asset from latest or specific Github release of a
# private repo. Feel free to extract more of the variables into command line
# parameters.
#
# PREREQUISITES
#
# curl, wget, jq
#
# If your version/tag doesn't match, the script will exit with error.

usage() { echo "Usage: $0 -t <github token> -r <repo> -v <version> -f <file> -o <output path> -q" 1>&2; exit 1; }

while getopts "qt:v:r:f:o:" o; do
    case "${o}" in
        t) 
            TOKEN=${OPTARG}
            ;;
        v) 
            VERSION=${OPTARG}
            ;;
        r) 
            REPO=${OPTARG}
            ;;
        f) 
            FILE=${OPTARG}
            ;;
        o)
            OUTPUT=${OPTARG}
            ;;
        q)
            QUIET=1
            ;;
        *) 
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "$OUTPUT" ]; then
    OUTPUT=$FILE
fi

if [ -z "$TOKEN" ] || [ -z "$VERSION" ] || [ -z "$REPO" ] || [ -z "$FILE" ] || [ -z "$OUTPUT" ]; then
    usage
fi

GITHUB="https://api.github.com";

alias errcho='>&2 echo'

gh_curl() {
    curl -H "Authorization: token $TOKEN" \
        -H "Accept: application/vnd.github.v3.raw" \
        -s \
        $@
}

version_exists() {
    jq ". | map(select(.tag_name == \"$VERSION\")) | length"
}

maybe_echo() {
    if [ -z "$QUIET" ]; then
        echo "$@"
    fi
}

echo_error() {
    >&2 maybe_echo "ERROR: $@"
}

echo_info() {
    maybe_echo "INFO: $@"
}

echo_success() {
    maybe_echo SUCCESS: $@
}

if [ "$VERSION" = "latest" ]; then
    # Github should return the latest release first.
    parser=".[0].assets | map(select(.name == \"$FILE\"))[0].id"
else
    parser=". | map(select(.tag_name == \"$VERSION\"))[0].assets | map(select(.name == \"$FILE\"))[0].id"
fi

RESPONSE=$(gh_curl $GITHUB/repos/$REPO/releases)

if [ "$(echo $RESPONSE | version_exists)" = "0" ]; then
    echo_error "version '$VERSION' not found"
    exit 1
else
    echo_info "Found version '$VERSION'"
fi

ASSET_ID=$(echo $RESPONSE | jq "$parser")
if [ "$ASSET_ID" = "null" ]; then
    echo_error "Could not find asset '$FILE'"
    exit 1
else
    echo_info "Found asset '$FILE'"
fi

wget -q --auth-no-challenge --header='Accept:application/octet-stream' \
    https://$TOKEN:@api.github.com/repos/$REPO/releases/assets/$ASSET_ID \
    -O $OUTPUT

echo_success "Asset '$OUTPUT' saved successfully"