#!/command/with-contenv bashio
HASS_CONFIG_DIR=$(bashio::config 'config_dir')

if ! type j2 > /dev/null 2>&1; then
  echo "jinjanator must be installed: pip install jinjanator (https://github.com/kpfleming/jinjanator)"
  sleep 1
  exit 1
fi
if ! type prettier > /dev/null 2>&1; then
  echo "Prettier must be installed: apt-get install nodejs npm && npm install -g prettier"
  sleep 1
  exit 1
fi

# Generate customization file for jinjanator with custom delimiters
CUSTOMIZE_FILE="/tmp/j2_customize.py"
cat > "$CUSTOMIZE_FILE" << 'PYEOF'
def j2_environment_params():
    """Return parameters for Jinja2 Environment"""
    import os
    params = {}

    # Read delimiter settings from environment variables
    var_start = os.environ.get('J2_VAR_START', '{{')
    var_end = os.environ.get('J2_VAR_END', '}}')
    block_start = os.environ.get('J2_BLOCK_START', '{%')
    block_end = os.environ.get('J2_BLOCK_END', '%}')
    comment_start = os.environ.get('J2_COMMENT_START', '{#')
    comment_end = os.environ.get('J2_COMMENT_END', '#}')

    if var_start:
        params['variable_start_string'] = var_start
    if var_end:
        params['variable_end_string'] = var_end
    if block_start:
        params['block_start_string'] = block_start
    if block_end:
        params['block_end_string'] = block_end
    if comment_start:
        params['comment_start_string'] = comment_start
    if comment_end:
        params['comment_end_string'] = comment_end

    return params
PYEOF

# Export delimiter settings as environment variables for the customization file
export J2_VAR_START=$(bashio::config 'variable_start_string')
export J2_VAR_END=$(bashio::config 'variable_end_string')
export J2_BLOCK_START=$(bashio::config 'block_start_string')
export J2_BLOCK_END=$(bashio::config 'block_end_string')
export J2_COMMENT_START=$(bashio::config 'comment_start_string')
export J2_COMMENT_END=$(bashio::config 'comment_end_string')

remove() {
  OUTPUT_FILE="$1${2/.jinja}"
  echo "$1$2 deleted, removing: $OUTPUT_FILE"
   rm -f "$OUTPUT_FILE"
}

compile() {
  echo "$1$2 changed, compiling to: $1${2/.jinja}"
  ERROR_LOG_FILE="$1$2.errors.log"
  OUTPUT_FILE="$1${2/.jinja}"
  TEMP_OUTPUT_FILE="${OUTPUT_FILE}.tmp"

  echo "# DO NOT EDIT: Generated from: $2" > "$TEMP_OUTPUT_FILE"
  # Log any errors to an .errors.log file, delete if successful
  # Use j2 with customize file and no data (defaults to environment variables)
  if j2 --customize "$CUSTOMIZE_FILE" "$1$2" >> "$TEMP_OUTPUT_FILE" 2> "$ERROR_LOG_FILE"; then
    mv "$TEMP_OUTPUT_FILE" "$OUTPUT_FILE"
    (rm -f "$ERROR_LOG_FILE" || true)
    echo "Formatting $OUTPUT_FILE with Prettier..."
    prettier --write "$OUTPUT_FILE" --log-level warn || true
  else
    (rm -f "$TEMP_OUTPUT_FILE" || true)
    (rm -f "$OUTPUT_FILE" || true)
    echo "Error compiling $1$2!"
    if [ -f "$ERROR_LOG_FILE" ]; then cat "$ERROR_LOG_FILE" >&2; fi
  fi
}

echo "Compiling Jinja templates to YAML: $HASS_CONFIG_DIR/**/*.yaml.jinja"
inotifywait -q -m -r -e modify,delete,create,move "$HASS_CONFIG_DIR" | while read DIRECTORY EVENT FILE; do
  if [[ "$FILE" != *.yaml.jinja ]]; then continue; fi

  case $EVENT in
    MODIFY*)
      compile "$DIRECTORY" "$FILE";;
    CREATE*)
      compile "$DIRECTORY" "$FILE";;
    MOVED_TO*)
      compile "$DIRECTORY" "$FILE";;
    DELETE*)
      remove "$DIRECTORY" "$FILE";;
    MOVED_FROM*)
      remove "$DIRECTORY" "$FILE";;
  esac
  sleep 0.5
done

sleep 1
