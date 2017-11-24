#!/bin/bash

# run:
#   $ sudo bash setup.sh main

ROOTDIR="$HOME/tcc"
TEMPDIR=$(su ${SUDO_USER} -c "mktemp -d")
POSTGRES_VERSION="9.6"
PGADMIN4_VERSION="1.3"
PGADMIN4_WHEEL="pgadmin4-${PGADMIN4_VERSION}-py2.py3-none-any.whl"

# VirtualBox repositories: for tests
# WEBAPP_REPO="$HOME/shared/webapp"
# WEBESP_REPO="$HOME/shared/webesp"

WEBAPP_REPO='https://github.com/Corleo/webapp.git'
WEBESP_REPO='https://github.com/Corleo/webesp.git'
ESP_SDK_REPO='https://github.com/pfalcon/esp-open-sdk.git'
UPYTHON_REPO='https://github.com/Corleo/micropython.git'
WEBREPL_REPO='https://github.com/micropython/webrepl.git'
MPFSHELL_REPO='https://github.com/wendlers/mpfshell.git'


if [[ ! -f ~/.tcc_aliases ]]; then
    su ${SUDO_USER} << EOF
    touch ~/.tcc_aliases
    echo -e "\n# Aliases and paths for tcc applications" >> ~/.bash_aliases
    echo "if [[ -f ~/.tcc_aliases ]]; then" >> ~/.bash_aliases
    echo "    source ~/.tcc_aliases" >> ~/.bash_aliases
    echo "fi" >> ~/.bash_aliases
EOF
fi

add_repositories() {
    echo -e "\n# ================================================================================================"
    echo -e "Installing repositories \n"

    # general
    apt-get update && apt-get install -y \
    software-properties-common

    # Mosquitto PPA
    apt-add-repository ppa:mosquitto-dev/mosquitto-ppa -y

    # Git PPA
    apt-add-repository ppa:git-core/ppa -y

    # Chrome PPA
    echo "deb [arch=$(dpkg --print-architecture)] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
    wget -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -

    # PostgreSQL PPA
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
    wget -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
}

install_linux_apps(){
    echo -e "\n# ================================================================================================"
    echo -e "Installing linux applications \n"

    apt-get update && apt-get upgrade -y &&
    apt-get install -y \
        mosquitto mosquitto-clients \
        ufw \
        postgresql-${POSTGRES_VERSION} libpq-dev \
        firefox \
        google-chrome-stable \
        git \
        curl wget \
        grep sed \
        p7zip p7zip-full p7zip-rar lzma lzma-dev unzip zip unrar-free \
        gawk flex bison make automake autoconf libtool g++ gperf \
        texinfo help2man ncurses-dev libexpat-dev libffi-dev python-dev
}

install_conda() {
    echo -e "\n# ================================================================================================"
    echo -e "Installing miniconda2 \n"

    su ${SUDO_USER} << EOF
        wget -O ${TEMPDIR}/miniconda2.sh https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh
        bash ${TEMPDIR}/miniconda2.sh -b -p ${HOME}/miniconda2

        # add path
        echo "# Miniconda path" >> ~/.tcc_aliases
        echo 'export PATH="$HOME/miniconda2/bin:\$PATH"' >> ~/.tcc_aliases
        source ~/.tcc_aliases

        echo -e "\nSetting conda"
        conda config --append channels conda-forge
        conda config --append channels javascript
        conda config --set channel_priority false
        conda config --set changeps1 false

        echo -e "\nSetting aliases"
        echo -e "\n# conda env: root" >> ~/.tcc_aliases
        echo 'alias croot=". deactivate"' >> ~/.tcc_aliases
EOF
}

install_web_application() {
    echo -e "\n# ================================================================================================"
    echo -e "Installing webapp application \n"

    su ${SUDO_USER} << EOF
        source ~/.tcc_aliases
        cd ${ROOTDIR}

        conda env create --name webapp --file conda_env.yaml

        cd ~/miniconda2/envs/webapp/lib/python2.7/site-packages/bokeh
        mv embed.py embed_orig.py
        ln -s ${ROOTDIR}/embed_mod.py embed.py

        cd ${ROOTDIR}
        git clone ${WEBAPP_REPO} webapp
        cd ${ROOTDIR}/webapp
        git checkout tags/v0.1
        cp -R ${ROOTDIR}/instance instance

        echo -e "\nSetting aliases"
        echo -e "\n# conda env: webapp" >> ~/.tcc_aliases
        echo 'alias webapp=". activate webapp"' >> ~/.tcc_aliases
EOF
}

install_micropython() {
    echo -e "\n# ================================================================================================"

    su ${SUDO_USER} << EOF
        source ~/.tcc_aliases

        echo -e "Installing webesp application \n"
        cd ${ROOTDIR}
        git clone ${WEBESP_REPO} webesp
        cd ${ROOTDIR}/webesp
        git checkout tags/v0.1
        bash make_cfg.sh

        echo -e "\nInstalling esp-open-sdk \n"
        source activate webapp
        conda env list
        cd ${ROOTDIR}
        git clone --recursive ${ESP_SDK_REPO} esp-open-sdk
        cd ${ROOTDIR}/esp-open-sdk
        git submodule sync
        git submodule update --init
        make

        # add path
        echo -e "\n# Esp SDK" >> ~/.tcc_aliases
        echo 'export PATH="$ROOTDIR/esp-open-sdk/xtensa-lx106-elf/bin:\$PATH"' >> ~/.tcc_aliases
        source ~/.tcc_aliases

        echo -e "\nInstalling micropython \n"
        cd ${ROOTDIR}
        git clone ${UPYTHON_REPO} micropython
        cd ${ROOTDIR}/micropython
        git checkout my_modules_v1.9.1
        git submodule sync
        git submodule update --init
        make -C mpy-cross

        echo -e "\nBuilding Unix port \n"
        cd ${ROOTDIR}/micropython/unix
        make axtls
        make
        echo -e "\n# Micropython Unix" >> ~/.tcc_aliases
        echo 'export MICROPYPATH="~/.micropython/lib:$ROOTDIR/webesp:$ROOTDIR/webesp/lib"' >> ~/.tcc_aliases

        echo -e "\nBuilding Esp8266 port \n"
        source activate webapp
        conda env list
        cd ${ROOTDIR}/micropython/esp8266
        make axtls
        make

        echo -e "\nInstalling mpfshell: a tool to connect to Esp upython REPL through UART \n"
        cd ${ROOTDIR}
        git clone ${MPFSHELL_REPO} mpfshell
        cd ${ROOTDIR}/mpfshell
        git checkout e2a2d2d

        echo -e "\nInstalling webrepl: a tool to connect to Esp upython REPL through Wi-Fi \n"
        cd ${ROOTDIR}
        git clone ${WEBREPL_REPO} webrepl
        cd ${ROOTDIR}/webrepl
        git checkout 0e1209a

        echo -e "\nSetting aliases"
        echo -e "\n# Micropython cross compiler" >> ~/.tcc_aliases
        echo 'alias mpycross="$ROOTDIR/micropython/mpy-cross/mpy-cross"' >> ~/.tcc_aliases

        echo -e "\n# Micropython Unix" >> ~/.tcc_aliases
        echo 'alias upython="$ROOTDIR/micropython/unix/micropython"' >> ~/.tcc_aliases

        echo -e "\n# Micropython webrepl" >> ~/.tcc_aliases
        echo 'alias webrepl="firefox $ROOTDIR/webrepl/webrepl.html"' >> ~/.tcc_aliases

        echo -e "\n# mpfshell" >> ~/.tcc_aliases
        echo 'alias mpfshell="python $ROOTDIR/mpfshell/mpfshell"' >> ~/.tcc_aliases
EOF
}

install_pgadmin() {
    echo -e "\n# ================================================================================================"
    echo -e "Installing PgAdmin4 v$PGADMIN4_VERSION \n"

    su ${SUDO_USER} << EOF
        source ~/.tcc_aliases

        # Conda env for PgAdmin 4
        conda create --name pgadm python=2.7 --yes
        source activate pgadm

        wget -O ${TEMPDIR}/${PGADMIN4_WHEEL} "https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v${PGADMIN4_VERSION}/pip/${PGADMIN4_WHEEL}"
        conda install psycopg2=2.6.2 -y
        pip install ${TEMPDIR}/${PGADMIN4_WHEEL}

        echo -e "\nDeploying PgAdmin as a desktop application"
        # Deploy as a desktop application -> create a config_local.py file
        # alongside the existing config.py file:
        echo "SERVER_MODE = False" > ~/miniconda2/envs/pgadm/lib/python2.7/site-packages/pgadmin4/config_local.py

        echo -e "\nSetting aliases"
        echo -e "\n# conda env: pgadm" >> ~/.tcc_aliases
        echo 'alias pgadm=". activate pgadm"' >> ~/.tcc_aliases

        echo -e "\n# PostgreSQL" >> ~/.tcc_aliases
        echo 'alias pgadmin4="pgadm && python ~/miniconda2/envs/pgadm/lib/python2.7/site-packages/pgadmin4/pgAdmin4.py"' >> ~/.tcc_aliases

        # PgAdmin instructions:
        #     Run (with pgadm env activated)
        #     $ pgadmin4
        #     Navigate to http://localhost:5050 in the browser
EOF
}

config_database() {
    echo -e "\n# ================================================================================================"
    echo -e "Setting databases '$SUDO_USER' and 'udina_db' \n"

    local user_dbs cluster_status

    cluster_status=$(pg_lsclusters | \
        egrep "^$POSTGRES_VERSION main" | \
        awk '{print $4}')

    echo -e " \npsql cluster main is: $cluster_status"
    [[ "$cluster_status" != "online" ]] && \
    echo -e " \nstarting custer main..." && \
    pg_ctlcluster "$POSTGRES_VERSION" main start

    user_dbs=$(sudo -u postgres psql -c '\l' | \
        awk '{print $3 " " $1}' | \
        egrep "^$SUDO_USER " | \
        awk '{print $NF}')

    [[ -n "$user_dbs" ]] && \
    for db in $user_dbs; do
        echo -e "\ndropping user '$SUDO_USER's database: $db"
        su postgres -c "dropdb --if-exists $db"
    done

    su postgres << EOF
    # : << EOF
        echo -e "\ndropping user '$SUDO_USER'"
        dropuser --if-exists "$SUDO_USER"

        echo -e "\ncreating user '$SUDO_USER'"
        createuser --superuser "$SUDO_USER"
        psql -c "ALTER USER $SUDO_USER WITH PASSWORD 'admin';"

        echo -e "\ncreating database '$SUDO_USER'"
        createdb "$SUDO_USER" -O "$SUDO_USER"

        echo -e "\ncreating database 'udina_db'"
        createdb "udina_db" -O "$SUDO_USER"

        # for tests
        # createdb "${SUDO_USER}2" -O "$SUDO_USER"
        # psql -c '\l' | grep $SUDO_USER
EOF

    su ${SUDO_USER} << EOF
        echo -e "\nSetting database 'udina_db'"
        source ~/.tcc_aliases
        source activate webapp
        cd ${ROOTDIR}/webapp
        source start.sh --reset-db
EOF
}

config_firewall() {
    echo -e "\n# ================================================================================================"
    echo -e "Setting firewall \n"

    ufw default deny incoming
    ufw default allow outgoing

    ufw allow 80/tcp        # http
    ufw allow 443/tcp       # https
    ufw allow 5000/tcp      # Flask app
    ufw allow 1883/tcp      # Mosquitto broker
    # ufw allow 5432/tcp      # postresql

    ufw enable
    ufw reload
    ufw status verbose
}

clear_cache_and_temp() {
    echo -e "\n# ================================================================================================"
    echo -e "Cleanning cached and temp files \n"

    rm -rf \
        /tmp/tmp.* \
        /var/cache/apk/* \
        ${HOME}/.wget-hists

    su ${SUDO_USER} << EOF
        source ~/.tcc_aliases
        conda clean --all --yes
EOF
}

uninstall_tcc() {
    echo -e "\n# ================================================================================================"
    echo -e "Uninstall tcc applications and drop db user \n"

    local user_dbs

    clear_cache_and_temp

    ufw --force reset
    ufw --force disable

    user_dbs=$(sudo -u postgres psql -c '\l' | \
        awk '{print $3 " " $1}' | \
        egrep "^$SUDO_USER " | \
        awk '{print $NF}')

    [[ -n "$user_dbs" ]] && \
    for db in $user_dbs; do
        echo -e "\ndropping user '$SUDO_USER's database: $db"
        su postgres -c "dropdb --if-exists $db"
    done && \
    su postgres -c "dropuser --if-exists $SUDO_USER" && \
    pg_ctlcluster "$POSTGRES_VERSION" main stop

    cd ${HOME} && \
    rm -rf \
        tcc \
        miniconda2 \
        .conda \
        .condarc \
        .tcc_aliases

    sed -i -e '132,$d' ~/.bash_aliases

    echo -e "\nEnd"
}

main() {
    echo -e "\n# ================================================================================================"
    echo -e "Init install for tcc project \n"

    add_repositories        && \
    install_linux_apps      && \
    install_conda           && \
    install_web_application && \
    install_micropython     && \
    install_pgadmin         && \
    # config_database         && \
    config_firewall         && \
    clear_cache_and_temp
}

"$@"
