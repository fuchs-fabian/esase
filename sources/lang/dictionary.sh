#!/bin/bash

# DESCRIPTION:
# This source provides variables for the selected language.
# The files (<lang>.conf) for the languages can be found in the 'esase' main directory under 'lang'.
# For this source, the source 'sources/general/conf.sh' must be included beforehand


# # # # # # # # # # # #|# # # # # # # # # # # #
#         SCRIPT OVERLAPPING VARIABLES        #
# # # # # # # # # # # #|# # # # # # # # # # # #

TXT_SELECT_ACTION_PROMPT=$(get_lang_specific_text "select_action_prompt")
TXT_SUCCESS=$(get_lang_specific_text "success")
TXT_COL_ACTION=$(get_lang_specific_text "col_action")


# # # # # # # # # # # #|# # # # # # # # # # # #
#        'ESASE' SPECIFIC VARIABLES           #
# # # # # # # # # # # #|# # # # # # # # # # # #

TXT_TITLE_ESASE=$(get_lang_specific_text "title_esase")
TXT_RUN_ACTIONS=$(get_lang_specific_text "run_actions")
TXT_EDIT_APP_FILES=$(get_lang_specific_text "edit_app_files")

TXT_UPDATE_ALL=$(get_lang_specific_text "update_all")
TXT_REMOVE_STANDARD_APPS=$(get_lang_specific_text "remove_standard_apps")
TXT_REPLACE_TERMINAL=$(get_lang_specific_text "replace_terminal")
TXT_INSTALL_APPS=$(get_lang_specific_text "install_apps")
TXT_INSTALL_FLATPAK_APPS=$(get_lang_specific_text "install_flatpak_apps")
TXT_INSTALL_ADVANCED_VIRTUALIZATION=$(get_lang_specific_text "install_advanced_virtualization")
TXT_INSTALL_DOCKER=$(get_lang_specific_text "install_docker")
TXT_INSTALL_NPM=$(get_lang_specific_text "install_npm")

TXT_SELECT_APP_FILE=$(get_lang_specific_text "select_app_file")
TXT_SELECT_APP_FILE_PROMPT=$(get_lang_specific_text "select_app_file_prompt")
TXT_APT_APP_FILE_SELECTION=$(get_lang_specific_text "apt_app_file_selection")
TXT_DNF_APP_FILE_SELECTION=$(get_lang_specific_text "dnf_app_file_selection")
TXT_FLATPAK_APP_FILE_SELECTION=$(get_lang_specific_text "flatpak_app_file_selection")

TXT_COL_APP_FILE=$(get_lang_specific_text "col_app_file")


# # # # # # # # # # # #|# # # # # # # # # # # #
#    'APP_FILE_EDITOR' SPECIFIC VARIABLES     #
# # # # # # # # # # # #|# # # # # # # # # # # #

TXT_TITLE_APP_FILE_EDITOR=$(get_lang_specific_text "title_app_file_editor")
TXT_SELECT_ACTION=$(get_lang_specific_text "select_action")

TXT_ADD_APP=$(get_lang_specific_text "add_app")
TXT_ADD_APP_PROMPT=$(get_lang_specific_text "add_app_prompt")

TXT_EDIT_APPS=$(get_lang_specific_text "edit_apps")
TXT_EDIT_APPS_SELECT_PROMPT=$(get_lang_specific_text "edit_apps_select_prompt")
TXT_EDIT_APP=$(get_lang_specific_text "edit_app")
TXT_EDIT_APP_PROMPT=$(get_lang_specific_text "edit_app_prompt")

TXT_SELECT_APPS_FOR_INSTALLATION=$(get_lang_specific_text "select_apps_for_installation")
TXT_SELECT_APPS_FOR_INSTALLATION_PROMPT=$(get_lang_specific_text "select_apps_for_installation_prompt")

TXT_DELETE_APPS=$(get_lang_specific_text "delete_apps")
TXT_DELETE_APPS_PROMPT=$(get_lang_specific_text "delete_apps_prompt")

TXT_ADD_CATEGORY=$(get_lang_specific_text "add_category")
TXT_ADD_CATEGORY_PROMPT=$(get_lang_specific_text "add_category_prompt")

TXT_EDIT_CATEGORIES=$(get_lang_specific_text "edit_categories")
TXT_EDIT_CATEGORIES_SELECT_PROMPT=$(get_lang_specific_text "edit_categories_select_prompt")
TXT_EDIT_CATEGORY=$(get_lang_specific_text "edit_category")
TXT_EDIT_CATEGORY_PROMPT=$(get_lang_specific_text "edit_category_prompt")

TXT_DELETE_CATEGORIES=$(get_lang_specific_text "delete_categories")
TXT_DELETE_CATEGORIES_PROMPT=$(get_lang_specific_text "delete_categories_prompt")

TXT_COL_DELETE=$(get_lang_specific_text "col_delete")
TXT_COL_INDEX=$(get_lang_specific_text "col_index")
TXT_COL_NAME=$(get_lang_specific_text "col_name")
TXT_COL_ALIAS=$(get_lang_specific_text "col_alias")
TXT_COL_INSTALL=$(get_lang_specific_text "col_install")
TXT_COL_DESCRIPTION=$(get_lang_specific_text "col_description")
TXT_COL_CATEGORY=$(get_lang_specific_text "col_category")
TXT_COL_APPS=$(get_lang_specific_text "col_apps")