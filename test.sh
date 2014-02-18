# Get current directory and import config and shared functions files.
SCRIPT_DIR=`dirname $0`
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/functions.sh"

  if ! [ "sudo chown -R $USER:$GROUP $BASE_DIR" ] && [ "sudo chmod -R 770 $BASE_DIR" ]; then
    echo 'could not set permissions.'
    exit 1
  fi
