# Instalação e configuração

Esse projeto foi desenvolvido na distribuição linux Ubuntu 14.04 e seu repositório git precisa ser baixado no diretório do usuário do sistema -- `home/nome_de_usuário` -- para que o script de configuração `setup.sh` funcione como esperado. Ao todo 3 repositórios compõem o projeto:

* [tcc](https://github.com/Corleo/tcc): instala e configura os sistemas do projeto
* [webapp](https://github.com/Corleo/webapp): sistemas da aplicação web
* [webesp](https://github.com/Corleo/webesp): sistema do microcontrolador Esp8266


Os comandos a seguir são para baixar o repositório git `tcc` no diretório do usuário e executar o script `setup.sh` de instalação do sistema:
```
$ cd ~
$ git clone https://github.com/Corleo/tcc.git
$ cd ~/tcc
$ sudo bash setup.sh main
$ source ~/.bash_aliases
```

O diretório `~/tcc/instance` contém apenas modelos de scripts de configuração do sistema cuja função é armazenar informações sigilosas de acessos do sistema e não deve ser atualizado. Durante a instalação o diretório `~/tcc/instance` é copiado para `~/tcc/webapp/instance` e é desse diretório que os scritps `my_env_vars.sh` e `production.cfg` devem ser atualizados com os parâmetros pertinentes de hashs e senhas, nome de usuário de email, etc.

O primeiro script contém variáveis com informações para usar o sistema na sua configuração de desenvolvimento e debug. Já o segundo, para uso em produção. A escolha de um ou de outro é feita no script `start.sh` que, por padrão, tem a configuração de desenvolvimento definida e o banco de dados nomeado com `udina_db`.

Feitas as configurações, é preciso que o banco de dados da aplicação seja criado:
```
$ cd ~/tcc
$ sudo bash setup.sh config_database
```

>Obs:

>    * Por padrão, o nome de usuário do banco de dados é definido com o mesmo nome do usuário logado na sessão do sistema operacional durante a instalação porque assim, quando logado na sessão, o seu acesso ao banco de dados fica facilitado. Quanto ao sistema da aplicação web, o nome de usuário administrador e sua senha são 'admin'. Essa é também a senha de acesso ao bando de dados definida para o usuário logado, caso seja necessário saber.

>    * Por segurança, os arquivos dentro do diretório `~/tcc/webapp/instance` foram escondidos do sistema de versionamento git para que apenas o administrador do sistema tenha acesso a eles e, portanto, não devem ser expostos no repositório do projeto.


Com o sistema instalado e o banco de dados configurado, basta entrar no ambiente virtual python nomeado `webapp` e no diretório `~/tcc/webapp/` e então executar o script `start.sh`:
```
$ webapp
$ cd ~/tcc/webapp
$ . start.sh --full-app
```

O argumento `--full-app` na última linha de comando logo acima pode ser substituído por sua versão abreviada `-a`. Ele executa ambos os servidores Bokeh e Flask, nessa ordem, colocando o servidor Bokeh para ser executado em segundo plano. Portanto, o comando `Ctrl+C` fará apenas a interrupção do servidor Flask, que está em primeiro plano. Para interromper o servidor Bokeh sendo executado em segundo plano é preciso que se saiba seu código ID de processo:
```
$ jobs -l
```

O retorno do comando deve ser algo como:
```
$ [1]+ <ID> Executando              python app/_bokeh/_bokeh.py &
```

Então basta executar o comando para matar esse processo:
```
$ kill %1
ou
$ kill ID
```

Quando for necessário debugar o código, o sistema pode ter seus servidores Flask e Bokeh iniciados separadamente, um em cada terminal. Nesse caso, no primeiro terminal faça:
```
$ webapp
$ cd ~/tcc/webapp
$ . start.sh --flask-app
```

e em um segundo terminal:
```
$ webapp
$ cd ~/tcc/webapp
$ . start.sh --bokeh-app
```

Os argumentos `--flask-app` e `--bokeh-app` também possuem versões abreviadas: `-f` e `-b`, respectivamente.


O script `setup.sh` cria na instalação o arquivo oculto `~/.tcc_aliases` contendo alguns comandos de atalho:

comando | função
--- | ---
`croot`    | volta ao ambiente virtual python padrão
`pgadm`    | entra no ambiente virtual python do gerenciador de banco de dados PostgreSQL
`webapp`   | entra no ambiente virtual python da aplicação web
`upython`  | entra no ambiente virtual micropython para sistemas Unix
`mpycross` | executa a aplicação que gera arquivos em bytecode para micropython
`webrepl`  | abre uma aba do firefox com uma aplicação REPL para acessar o Esp8266 via Wi-Fi
`mpfshell` | inicia uma aplicação python para se conectar ao REPL do Esp8266 via UART
`pgadmin4` | executa a aplicação python que gerencia o banco de dados PostgreSQL


# Micropython

A ferramenta [esp-open-sdk](https://github.com/pfalcon/esp-open-sdk) é utilizada para compilar e criar o firmware [micropython](https://github.com/micropython/micropython) para sistemas Unix e para o microcontrolador Esp8266. O script `setup.sh` já realiza a instalação dessa ferramenta bem como a compilação e criação do firmware, mas o processo precisa ser repetido para atualizações e o procedimento não está automatizado e, portanto, é necessário um conhecimento prévio de sistemas de versionamento como o `git`.

> É bom lembrar que meu repositório micropython [clonado](https://github.com/Corleo/micropython) foi modificado para adicionar as bibliotecas mosquitto e para remover outras bibliotecas desnecessárias ao sistema do projeto a fim de economizar memória ROM. Por isso, essas modificações precisam ser replicadas quando for feita a atualização do micropython a partir do repositório padrão.

Com essas considerações levadas em conta, para atualizar a ferramenta `esp-open-sdk`:
```
$ cd ~/tcc/esp-open-sdk
$ make clean
$ git pull
$ git submodule sync
$ git submodule update --init
```

Para atualizar o micropython:
```
$ cd ~/tcc/micropython
$ git fetch origin/master
$ git submodule sync
$ git submodule update --init
$ **operações git para replicar minhas modificações na atualização**
$ make -C mpy-cross
```

Para recompilar o micropython para Unix:
```
$ cd ~/tcc/micropython/unix
$ make deplibs
$ make axtls
$ make
```

Para recompilar o micropython para Esp8266:
```
$ cd ~/tcc/micropython/esp8266
$ make clean
$ make axtls
$ make
```

Ainda no diretório `~/tcc/micropython/esp8266`, conecte o módulo Esp8266 a uma porta USB e execute os comandos para:

* Apagar a memória do dispositivo
```
$ esptool.py --port /dev/ttyUSB0 erase_flash
```

* Gravar o novo firmware na memória do dispositivo
```
$ make PORT=/dev/ttyUSB0 deploy
```

# REPL e WebREPL

O micropython possui um terminal de comando interativo chamado REPL para comunicação com o computador do usuário através de conexões serial ou USB. A ferramenta [mpfshell](https://github.com/wendlers/mpfshell) é muito útil para essa tarefa pois além de realizar a comunicação com o REPL, ela ainda possui o recurso para transferir arquivos do computador para o sistema de arquivos do módulo Esp8266.

> Obs: essa aplicação precisa de bibliotecas python instaladas no ambiente virtual `webapp`. Portanto esse ambiente precisa estar ativo quando a aplicação for executada.

Para entrar no REPL diretamente basta executar o comando:
```
$ mpfshell -n -c "open ttyUSB0; repl"
```

e para sair do REPL, bastar enviar o comando `Ctrl+]`.

Já para usar a ferramenta `mpfshell` em modo interativo:
```
$ mpfshell
$ open ttyUSB0
$ help
```

Para a comunicação com o REPL micropython através de uma conexão Wi-Fi existe ainda a ferramenta [webrepl](https://github.com/micropython/webrepl). Ela precisa estar configurada previamente no dispositivo Esp8266.


# Aplicação do Esp8266

Novamente por motivos de segurança, os arquivos `wifi_sta`, `webapp_cfg.py` e  `webrepl_cfg.py` são ignorados pelo versionamento do `git` por conterem informações confidenciais. Contudo, durante a execução do script `setup.sh` esses arquivos são criados com base no script `make_cfg.sh` e os valores de senha e endereços de servidor precisam ser modificados nos 3 arquivos criados e não no script gerador `make_cfg.sh`, pois ele está sendo monitorado pelo git. O script gerador também contém mais detalhes sobre os parâmetros dos arquivos criados.

Com os arquivos configurados e o firmware micropython gravado no módulo Esp8266, falta enviar a ele os scripts da aplicação e de configuração de acessos. O script que contém efetivamente a aplicação é o `esp_app.py` e dele deve ser gerado um arquivo em bytecode toda vez que for modificado:
```
$ mpycross esp_app.py
```

Finalmente, com o terminal no diretório dos arquivos e com o ambiente virtual python `webapp` ativo:
```
$ mpfshell -n -c "\
    open ttyUSB0; \
    put boot.py; \
    put main.py; \
    put esp_app.mpy; \
    put wifi_sta; \
    put webapp_cfg.py; \
    put webrepl_cfg.py; \
    repl"
```

Se tudo ocorreu como esperado, o terminal vai estar conectado ao REPL do Esp8266. Então reinicie o dispositivo para que a aplicação seja executada. Se estiver sendo usado um kit de desenvolvimento NodeMcu, isso pode ser feito pelo botão de reset ou via REPL:
```
>>> import machine
>>> machine.reset()
```
