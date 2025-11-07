#!/bin/bash
set -e

echo "Testing j2cli with custom delimiters..."

# Test 1: Standard delimiters
echo "Test 1: Standard delimiters"
cat > /tmp/j2_test_standard.py << 'EOF'
def j2_environment_params():
    return {
        'variable_start_string': '{{',
        'variable_end_string': '}}',
        'block_start_string': '{%',
        'block_end_string': '%}',
        'comment_start_string': '{#',
        'comment_end_string': '#}'
    }
EOF

j2 --customize /tmp/j2_test_standard.py config/test_standard.yaml.jinja > /tmp/test_standard.yaml
echo "Standard delimiters output:"
cat /tmp/test_standard.yaml
echo ""

# Test 2: Custom delimiters
echo "Test 2: Custom delimiters"
cat > /tmp/j2_test_custom.py << 'EOF'
def j2_environment_params():
    return {
        'variable_start_string': '((',
        'variable_end_string': '))',
        'block_start_string': '<%',
        'block_end_string': '%>',
        'comment_start_string': '/*',
        'comment_end_string': '*/'
    }
EOF

j2 --customize /tmp/j2_test_custom.py config/test_custom.yaml.jinja > /tmp/test_custom.yaml
echo "Custom delimiters output:"
cat /tmp/test_custom.yaml
echo ""

echo "All tests passed!"
