#!/bin/sh
SERVER_PORT=${SERVER_PORT:-5000}
SERVER_NAME=${SERVER_NAME:-localhost}
SERVER_SAN=${SERVER_SAN:-""}

SERVER_HTTPS=${SERVER_HTTPS:-""}
SERVER_HTTPS_INCLUDE=${SERVER_HTTPS_INCLUDE:-/etc/nginx/includes/default.https.conf}
SERVER_HTTPS_FNAME=${SERVER_HTTPS_FNAME:-site}

SERVER_WATCH_CRT=${SERVER_WATCH_CRT:-""}

SERVER_LOG=${SERVER_LOG:-""}
SERVER_ROOT=${SERVER_ROOT:-""}
SERVER_INDEX=${SERVER_INDEX:-""}

SERVER_LOCATION=${SERVER_LOCATION:-""}

SERVER_TRYFILES=${SERVER_TRYFILES:-""}
SERVER_TRYFILES_INCLUDE=${SERVER_TRYFILES_INCLUDE:-""}
SERVER_TRYFILES_PATH=${SERVER_TRYFILES_PATH:-"/"}
SERVER_TRYFILES_OTHER=${SERVER_TRYFILES_OTHER:-""}

SERVER_PHP=${SERVER_PHP:-""}
SERVER_PHP_INCLUDE=${SERVER_PHP_INCLUDE:-/etc/nginx/includes/default.php_fastcgi.conf}

SERVER_FAVICON=${SERVER_FAVICON:-0}
SERVER_ROBOTS=${SERVER_ROBOTS:-0}
SERVER_HT=${SERVER_HT:-0}

SERVER_REDIRECT=${SERVER_REDIRECT:-""}

SERVER_YAML=${SERVER_YAML:-""}

function init(){
    local out=${1:?Error}
    
    if [[ -n "${SERVER_YAML}" ]]; then
        set -- \
        --yaml "${SERVER_YAML}"
    else
        set -- print \
        -p "${SERVER_PORT}" \
        -n "${SERVER_NAME}"
        
        
        if [[ -n "${SERVER_SAN}" ]]; then
            set -- "${@}" \
            --san "${SERVER_SAN}"
        fi
        
        if [[ -n "${SERVER_HTTPS}" ]]; then
            SERVER_WATCH_CRT=${SERVER_HTTPS}/${SERVER_HTTPS_FNAME}.crt
            set -- "${@}" \
            --https path="${SERVER_HTTPS}",include="${SERVER_HTTPS_INCLUDE}",filename="${SERVER_HTTPS_FNAME}"
        fi
        
        if [[ -n "${SERVER_LOG}" ]]; then
            set -- "${@}" \
            --log "${SERVER_LOG}"
        fi
        
        if [[ -n "${SERVER_ROOT}" ]]; then
            set -- "${@}" \
            --root "${SERVER_ROOT}"
        fi
        
        if [[ -n "${SERVER_INDEX}" ]]; then
            set -- "${@}" \
            --index "${SERVER_INDEX}"
        fi
        
        if [[ -n "${SERVER_LOCATION}" ]]; then
            set -- "${@}" \
            --location "${SERVER_LOCATION}"
        fi
        
        if [[ -n "${SERVER_TRYFILES}" ]]; then
            set -- "${@}" \
            --location path="${SERVER_TRYFILES_PATH}",type=try_files,value="${SERVER_TRYFILES}",include="${SERVER_TRYFILES_INCLUDE}",other="${SERVER_TRYFILES_OTHER}"
        fi
        
        if [[ -n "${SERVER_PHP}" ]]; then
            set -- "${@}" \
            --location path="~ \.php\$",type=fastcgi_pass,value="${SERVER_PHP}",include="${SERVER_PHP_INCLUDE}"
        fi
        
        if [[ -n "${SERVER_PHP}" || -n "${SERVER_TRYFILES}" ]]; then
            SERVER_FAVICON=1
            SERVER_ROBOTS=1
            SERVER_HT=1
        fi
        
        if [[ $SERVER_FAVICON == 1 || $SERVER_FAVICON == true ]]; then
            set -- "${@}" \
            --location path=/favicon.ico,type=access_log,value=off,other="log_not_found off"
        fi
        
        if [[ $SERVER_ROBOTS == 1 || $SERVER_ROBOTS == true ]]; then
            set -- "${@}" \
            --location path=/robots.txt,type=access_log,value=off,other="log_not_found off"
            
        fi
        
        if [[ $SERVER_HT == 1 || $SERVER_HT == true ]]; then
            set -- "${@}" \
            --location path="~ /\.ht",type=deny,value=all
        fi
        
        if [[ -n "${SERVER_REDIRECT}" ]]; then
            set -- "${@}" \
            --redirect "value=${SERVER_REDIRECT}"
        fi
    fi
    
    camarero "${@}" > ${out}
    
    return 0
}

if [[ -n "${SERVER_WATCH_CRT}" ]]; then
    if [[ ! -f "${SERVER_WATCH_CRT}" ]]; then
        sleep 10 
    fi
    
    certwatch.sh ${SERVER_WATCH_CRT} &
fi

init /etc/nginx/conf.d/default.conf

exec "${@}"
