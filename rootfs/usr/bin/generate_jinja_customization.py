#!/usr/bin/env python3
"""
Generate Jinja2 customization file for j2cli
"""

def j2_environment_params():
    """
    Return custom delimiter parameters for Jinja2 environment
    Changes delimiters from {{ }} to [[ ]] and from {% %} to [% %]
    """
    return dict(
        variable_start_string='[[',
        variable_end_string=']]',
        block_start_string='[%',
        block_end_string='%]',
        comment_start_string='[#',
        comment_end_string='#]'
    )
