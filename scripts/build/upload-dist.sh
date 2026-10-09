#!/bin/bash
echo "::group::Upload"

PLUGIN_NAME=$1

cd dist

star_files=(*.star)
if [ -e "${star_files[0]}" ]; then
  star_file="${star_files[0]}"

  id=$(jq -r '.id' metadata.json) || { echo "::error::Failed to extract id from metadata.json"; exit 1; }

  echo "Uploading star plugin with id $id"
  scp "$star_file" ubuntu@"$SSH_HOST":~/net/storage/steambrew/plugins/"$id.star" || { echo "::error::Failed to upload plugin to server"; exit 1; }
  echo "Successfully uploaded plugin."

  echo "::endgroup::"
  exit 0
fi

echo "Building plugin archive..."
zip -r "$PLUGIN_NAME.zip" .
echo "Successfully built plugin."

id=$(jq -r '.id' "$PLUGIN_NAME"/metadata.json) || { echo "::error::Failed to extract id from $PLUGIN_NAME/metadata.json"; exit 1; }

echo "Uploading plugin with id $id"
scp "$PLUGIN_NAME.zip" ubuntu@"$SSH_HOST":~/net/storage/steambrew/plugins/"$id.zip" || { echo "::error::Failed to upload plugin to server"; exit 1; }
echo "Successfully uploaded plugin."
rm "$PLUGIN_NAME.zip"

echo "::endgroup::"
