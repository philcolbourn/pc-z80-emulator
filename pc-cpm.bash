#!/bin/bash

# CPM

declare -a CHR

# make ASCII lookup table: eg. CHR[65]="A"
makeCHR() {
    local -i j
    for (( j=0x00; j<0x20;  j++ )); do
        printf -v CHR[j] "\\\x%02x" $((j+0x40))  # make hex char sequence eg. \x41
        printf -v CHR[j] "%b" "${CHR[j]}"        # convert to string into array
    done
    for (( j=0x20; j<0x80;  j++ )); do 
        printf -v CHR[j] "\\\x%02x" $j           # make hex char sequence eg. \x41
        printf -v CHR[j] "%b" "${CHR[j]}"        # convert to string into array
    done
    for (( j=0x80; j<0x100; j++ )); do CHR[j]="."; done
}
makeCHR

#$_VERBOSE && print_table CHR

# minimal CP/M bdos emulator

bdos_E() {
    local -i _END _tt _j
    #printf "bdos\n"
    #printf "$FUNCNAME: Function  c=%02x  de=%04x  a=%02x\n" $c $(( (d<<8)|e )) $a
    case "$c" in
        9) printf -v _END "%d" "'$" 
           (( _tt=(d<<8)|e, _j=MEM[_tt] )); (( _tt=(_tt+1)&65535 ))  # bash bug
           while (( _j!=_END )); do
               case $_j in
                   10) ;;
                   13) printf "\n";;
                    *) printf "%c" "${CHR[_j]}"
               esac
               (( _j=MEM[_tt] )); (( _tt=(_tt+1)&65535 ))  # bash bug
           done;;
        2) printf "%c" "${CHR[_e]}";;
        *) printf "ERROR: [${FUNCNAME[*]}]: Function c=%02x not handled.\n" $_c; exit 0;
    esac
    #sleep 1
    #popnn; pc=nn
    poppc
    return 0
}

setupMMgr 0x0000        "RESET"               RO "onerun_E"
setupMMgr 0x0005        "CP/M bdos entry"     RO "bdos_E"
setupMMgr 0x0006-0x0007 "CP/M Stack Pointer"
setupMMgr 0x0100        "CP/M start program"

#printf "$0 loaded.\n"

