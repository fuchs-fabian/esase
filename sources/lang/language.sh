#!/bin/bash

# DESCRIPTION:
# This source helps to support different languages.


SUPPORTED_LANGUAGES=("en" "de")

LANGUAGE=""
LANGUAGE_CONF=""

validate_language() {
    local lang="$1"

    for supported_lang in "${SUPPORTED_LANGUAGES[@]}"; do
        if [[ "$lang" == "$supported_lang" ]]; then
            log_debug "Language '$lang' is supported."
            return 0
        fi
    done

    return 1
}

get_lang_specific_text() {
    echo "$(get_conf_value "$(realpath "$LANGUAGE_CONF")" "$1")"
}

set_language() {
    if [[ -z "$LANGUAGE" ]]; then
        LANGUAGE=$(echo $LANG | cut -d_ -f1)
        log_debug "System language is used: '$LANGUAGE'"
    fi

    validate_language "$LANGUAGE"
    if [[ $? -ne 0 ]]; then
        log_warning "Unsupported language: '$LANGUAGE'. Defaulting to 'en'."
        LANGUAGE="en"
    fi

    log_debug "Using language: '$LANGUAGE'"

    LANGUAGE_CONF="$LANG_DIR/$LANGUAGE.conf"

    if [[ ! -f $LANGUAGE_CONF ]]; then
        log_error "Language configuration file ('$LANGUAGE_CONF') not found!"
    fi

    log_debug "Using language configuration: '$LANGUAGE_CONF'"

    source "$SOURCES_DIR/lang/dictionary.sh" || { echo "Error: Could not source 'dictionary.sh' for '$0'."; exit 1; }
}