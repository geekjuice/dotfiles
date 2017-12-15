export CFLAGS="$CFLAGS -I$(brew --prefix openssl)/include"
export LDFLAGS="$LDFLAGS -L$(brew --prefix openssl)/lib -L/usr/local/opt/zlib/lib"
export CPPFLAGS="-I/usr/local/opt/zlib/include"

export CQLSH_NO_BUNDLED=TRUE

klaviyo-services() {
    local action="${1:?Argument must be one of [re]start|stop|status}"

    if [[ $action == "restart" ]]; then
        klaviyo-services stop
        klaviyo-services start
    elif [[ $action == "start" || $action == "stop" ]]; then
        echo memcached rabbitmq mysql@5.6 redis | xargs -n1 brew services $action
        ccm $action
    else
        brew services list
        echo Cassandra:
        ccm status
    fi
}

eval "$(pyenv init - 2>/dev/null)"
eval "$(pyenv virtualenv-init - 2>/dev/null)"
