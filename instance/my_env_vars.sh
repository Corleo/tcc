#!/bin/bash
# root/instance/my_env_vars.sh
#
# run:
#   $ . my_env_vars.sh

# Settings for dev and debug

function set_env() {
    echo "Setting env vars..."

    export APP_DB_USERNAME="$USER"
    export APP_DB_PASSWORD="admin"
    export APP_DB_NAME="udina_db"

    export APP_MAIL_USERNAME="system@email.com"
    export APP_MAIL_PASSWORD="system_email_password"

    export APP_ADM_FIRSTNAME="your_firstname"
    export APP_ADM_LASTNAME="your_lastname"
    export APP_ADM_USERNAME="admin"
    export APP_ADM_PASSWORD="admin"
    export APP_ADM_MAIL="your@email.com"
}

set_env
