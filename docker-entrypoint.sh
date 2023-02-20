#!/bin/sh

set -eo pipefail

# Create mount directory for service
mkdir -p $MNT_DIR

echo "Mounting GCS Fuse."
gcsfuse --debug_gcs --debug_fuse $BUCKET $MNT_DIR 
echo "Mounting completed."

if ! which -- "${1}"; then
  # first arg is not an executable
  export DISPLAY=:99
  Xvfb "${DISPLAY}" -nolisten unix &
  exec node /usr/src/app/ "$@"
fi

exec "$@"


# Exit immediately when one of the background processes terminate.
wait -n
# [END cloudrun_fuse_script]