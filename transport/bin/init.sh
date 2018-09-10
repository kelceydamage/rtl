
RASPI_HOME=/git/projects/cython/personal
PIDFILES=var/run/

function print_header() {
    echo -en "\n   +  "
    for i in {0..23}; do
        printf "%2b " $i
    done
    for i in {0..5}; do
        let "i = i*36 +16"
        printf "\n\n %3b  " $i
        for j in {0..23}; do
            let "val = i+j"
            echo -en "\033[48;5;${val}m  \033[m "
        done
    done
    echo -e "\n"
    echo -e "         R A S P I      (c) Robot OS                         -K. Damage\n"
}

function setup_env() {
    local_home=`pwd`
    export PATH=$local_home:$PATH
    export RASPI_HOME
    PYTHON="python"
}

function split() {
    IFS='-'
    read -r -a service <<< i
}

function print_plugins() {
    $PYTHON $RASPI_HOME/rtl/transport/bin/start.py -m
}

function print_terminal_lines() {
    myString=$(printf "%79s");echo ${myString// /-} 
}

function print_running_services() {
    print_terminal_lines
    echo -e "Service\t  PID"
    print_terminal_lines
    IFS='-'
    pidfiles=`ls var/run`
    column -t <<< $pidfiles
    IFS=''
    print_terminal_lines
}

function start() {
    if [ -z "$(ls -A var/run)" ]; then
        print_header
        print_plugins
        $PYTHON $RASPI_HOME/rtl/transport/bin/start.py &
    else
        echo -e "RTL is already running:"
        print_running_services
    fi
}

function stop() {
    echo -e "\nHalting the fallowing services:"
    print_running_services
    IFS='
    '
    pidfiles=(`ls $PIDFILES`)
    IFS=''
    for i in ${pidfiles[@]}; do
        kill `cat $PIDFILES$i` 
        if [ $? -eq 0 ]; then
            rm -rf $PIDFILES$i
        else
            echo -e "Error shutting down $PIDFILES$i, exiting script\n"
            exit 1
        fi
    done
    echo -e "RTL has been shut down"
}

function restart() {
    stop
    start
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        print_running_services
        ;;
    plugins)
        print_plugins
        ;;
    *)
        echo $"Usage: $0 {start|stop|restart|status|plugins}"
        exit 1
esac