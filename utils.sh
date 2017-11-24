#!/bin/bash

create_user() {
    # helper function to create user:
    #   $ sudo bash utils.sh create_user admin

    [[ "$#" -lt 1 || "$#" -gt 2 ]] && \
    echo "Error: create_user() expects 1 or 2 arguments" && \
    echo "(1 arg): username -> with password equals to username" && \
    echo "(2 args): username and password" && \
    return 1

    if [[ -z "$2" ]]; then
        # echo useradd -m -p "$1" -U -G sudo "$1"
        useradd -m -p "$1" -U -G sudo "$1"
    else
        # echo useradd -m -p "$2" -U -G sudo "$1"
        useradd -m -p "$2" -U -G sudo "$1"
    fi
}
