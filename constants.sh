# Set project directory structure.
CODE_DIR="$PROJECT_DIR/code"
PERMANENT_FILES_DIR="$PROJECT_DIR/permanent_files"
FILES_DIR="$PERMANENT_FILES_DIR/files"
PRIVATE_FILES_DIR="$PERMANENT_FILES_DIR/private"
DRUPAL_FILES_DIR="sites/default/files"
DRUPAL_PRIVATE_FILES_DIR="sites/default/private"
DRUPAL_SETTINGS_PHP="sites/default/settings.php"
CURRENT_INSTANCE_FILE="$PROJECT_DIR/instance"
SHORTCUT_SYMLINK_DIR="$CODE_DIR/current"
OUTPUT='--debug -v'

# Build site with development repositories or just production files.
BUILD_TYPE=''
if [ "$ENVIRONMENT" == "development" ]
then 
  BUILD_TYPE='--working-copy'
else
  BUILD_TYPE=''
fi
