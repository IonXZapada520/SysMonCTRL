#!/bin/bash

# functie pentru monitorizarea periodica a resurselor
monitor_resources() {
    local interval=$1

    # validarea inputului
    if [[ ! $interval =~ ^[0-9]+$ ]]; then
        echo "intervalul trebuie sa fie un numar intreg."
        return 1
    fi

    # loop infinit pentru monitorizare
    while true; do
        clear
        echo "resurse sistem:"

        # utilizare cpu
        echo "utilizare cpu:"
        vmstat 1 2 | tail -1 | awk '{print "  utilizare cpu: " 100-$15"%"}'

        # memorie ram
        echo "memorie ram:"
        free -h | awk '/Mem:/ {print "  folosit: "$3", liber: "$4}'

        # stocare hdd
        echo "stocare hdd:"
        df -h | awk 'NR==1 || /\/$/ {print "  "$0}'

        # utilizare retea
        echo "utilizare retea:"
        awk '/^[a-z]/ {if($1 !~ /lo/) print "  "$1, "rx: "$2, "tx: "$10}' /proc/net/dev

        echo "========================"
        sleep "$interval"
    done
}

# functie pentru listarea proceselor dupa stare
list_processes() {
    local state=$1
    clear
    case $state in
        active)
            ps -eo pid,stat,comm | grep -E 'R'
            ;;
        sleep)
            ps -eo pid,stat,comm | grep -E 'S'
            ;;
        stopped)
            ps -eo pid,stat,comm | grep -E 'T'
            ;;
        zombie)
            ps -eo pid,stat,comm | grep -E 'Z'
            ;;
        orphan)
            ps -eo pid,ppid,comm | awk '$2 == 1 {print $1, $2, $3}'
            ;;
        *)
            echo "input gresit. optiuni valide: active, sleep, stopped, zombie, orphan."
            ;;
    esac
    echo "apasati enter pentru a reveni la meniu."
    read
}

# functie pentru controlul proceselor
process_control() {
    while true; do
        clear
        echo "1. pornire proces"
        echo "2. suspendare proces"
        echo "3. termina proces (soft kill)"
        echo "4. termina proces (hard kill)"
        echo "5. trecere in background"
        echo "6. aducere in foreground"
        echo "7. revenire la meniul principal"
        echo -n "alege o optiune: "
        read -r opt
        ps -eo pid,comm,%mem --sort=%mem
        case $opt in
            1)
                echo -n "comanda proces: "
                read -r cmd
                eval "$cmd &"
                ;;
            2)
                echo -n "pid proces: "
                read -r pid
                kill -STOP "$pid"
                ;;
            3)
                echo -n "pid proces: "
                read -r pid
                kill "$pid"
                ;;
            4)
                echo -n "pid proces: "
                read -r pid
                kill -9 "$pid"
                ;;
            5)
                echo -n "pid proces: "
                read -r pid
                disown "$pid"
                ;;
            6)
                echo -n "pid proces: "
                read -r pid
                fg "$pid"
                ;;
            7)
                return
                ;;
            *)
                echo "optiune invalida."
                ;;
        esac
        echo "apasati enter pentru a continua."
        read
    done
}

# functie pentru configurarea resurselor sistemului
configure_system() {
    while true; do
        clear
        echo "configuratii disponibile:"
        echo "1. modifica limita maxima de procese"
        echo "2. modifica dimensiunea maxima a stivei"
        echo "3. revenire la meniul principal"
        echo -n "alege o optiune: "
        read -r opt
        case $opt in
            1)
                echo -n "noua limita maxima de procese: "
                read -r limit
                echo "* hard nproc $limit" | sudo tee -a /etc/security/limits.conf
                ;;
            2)
                echo -n "noua dimensiune maxima a stivei (kb): "
                read -r size
                echo "* hard stack $size" | sudo tee -a /etc/security/limits.conf
                ;;
            3)
                return
                ;;
            *)
                echo "optiune invalida."
                ;;
        esac
        echo "apasati enter pentru a continua."
        read
    done
}

# functie pentru afisarea topului proceselor consumatoare de resurse
top_n_processes() {
    local n=$1
    clear
    if [[ ! $n =~ ^[0-9]+$ ]]; then
        echo "numarul trebuie sa fie un intreg."
        return 1
    fi

    echo "top $n procese dupa utilizare cpu:"
    ps -eo pid,%cpu,%mem,comm --sort=-%cpu | head -n "$((n + 1))"

    echo "top $n procese dupa utilizare memorie:"
    ps -eo pid,%cpu,%mem,comm --sort=-%mem | head -n "$((n + 1))"

    echo "apasati enter pentru a reveni la meniu."
    read
}

# adaugare optiuni pentru operatiile cu resurse
resource_operations() {
    while true; do
        clear
        echo "operatii cu resurse"ps -eo pid,%cpu,%mem,comm --sort=-%cpu | head -n "$((n + 1))"
        echo "1. afisare resurse disponibile per proces"
        echo "2. curatare cache"
        echo "3. afisare temperaturi hardware"
        echo "4. revenire la meniul principal"
        echo -n "alege o optiune: "
        read -r opt
        case $opt in
            1)
                echo "resurse per proces:"
                ps -eo pid,%cpu,%mem,comm --sort=-%cpu | head -n 20
                echo "apasati enter pentru a reveni la meniu."
                read
                ;;
            2)
                echo "eliberare memorie cache..."
                sudo sync && sudo sysctl -w vm.drop_caches=3
                echo "cache eliberat."
                echo "apasati enter pentru a continua."
                read
                ;;
            3)
                echo "temperaturi hardware:"
                if command -v sensors >/dev/null 2>&1; then
                    sensors
                else
                    echo "comanda sensor nu este instalata"
                fi
                echo "apasati enter pentru a continua."
                read
                ;;
            4)
                return
                ;;
            *)
                echo "optiune invalida."
                ;;
        esac
    done
}

# functia principala
main_menu() {
    while true; do
        clear
        echo "menu principal"
        echo "1. monitorizare resurse (cpu, ram, retea)"
        echo "2. afisare procese dupa stare (active/sleep/stopped/zombie/orphan)"
        echo "3. operatii cu procese"
        echo "4. modifica configurari de sistem"
        echo "5. top procese consumatoare de resurse"
        echo "6. operatii cu resurse"
        echo "7. iesire"
        echo -n "alege o optiune: "
        read -r option
        case $option in
            1)
                echo -n "interval monitorizare (secunde): "
                read -r interval
                monitor_resources "$interval"
                ;;
            2)
                echo -n "stare proces: "
                read -r state
                list_processes "$state"
                ;;
            3)
                process_control
                ;;
            4)
                configure_system
                ;;
            5)
                echo -n "numarul de procese din top: "
                read -r n
                top_n_processes "$n"
                ;;
            6)
                resource_operations
                ;;
            7)
                echo "iesire din script."
                exit 0
                ;;
            *)
                echo "optiune invalida, te rog sa introduci un numar valid."
                ;;
        esac
    done
}

# pornirea aplicatiei
main_menu
