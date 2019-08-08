
RASPI_HOME=$(pwd)
SCRIPT=/transport/bin/start.py
PIDFILES=var/run/
DEFAULT_IFS=$IFS

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
    export PATH=$RASPI_HOME:$PATH
    export RASPI_HOME
    PYTHON="python"
}

function split() {
    IFS='-'
    read -r -a service <<< i
}

function print_plugins() {
    $PYTHON $RASPI_HOME$SCRIPT -m
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
        $PYTHON $RASPI_HOME$SCRIPT &
    else
        echo -e "RTL is already running:"
        print_running_services
    fi
}

function stop() {
    echo -e "\nHalting the fallowing services:"
    print_running_services
    IFS=''
    pidfiles=(`ls $PIDFILES`)
    IFS=$DEFAULT_IFS
    PIDS=(`ps aux|grep start.py|grep -v grep|awk '{print $2}'`)
    for i in ${pidfiles[@]}; do
        for j in ${!PIDS[@]}; do
            if [[ "${PIDS[$j]}" == `cat $PIDFILES$i` ]]; then
                INDEX=$j
            fi
        done
        kill `cat $PIDFILES$i`
        if [ $? -eq 0 ]; then
            rm -rf $PIDFILES$i
        else
            kill -9 ${PIDS[$INDEX]}
            echo -e "Error shutting down $PIDFILES$i, used force shutdown"
            force=1
        fi
    done
    if [[ $force -eq 1 ]]; then 
        rm -rf var/run/*
    fi
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