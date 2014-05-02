#!/bin/bash

# ASSEMBLER

declare -a ASM_PREFIX=( [0xCB]="CB" [0xED]="ED" [0xFD]="FD" [0xDD]="DD")

INCTPC="tpc=(tpc+1)&65535"
DECTPC="tpc=(tpc-1)&65535"

asm() {  # WARNING: dont use local g or k vars
    local -i tpc=0 tpc0=0 _j=0 _pre; local _v _done _id; local -iA _LABEL
    #$_ASM && printf "ASSEMBLING [%s]\n" "$*"
    printf "ASSEMBLING [%s]\n" "$*"
    while { _done=false; eval "_v=$1"; [[ -n "$_v" ]]; }; do

        # process any label
        if [[ ${_v::1} = ":" ]]; then
            _id="${_v:1}"
            _LABEL[_id]=$tpc
            shift; continue
        fi
        
        for _j in ${!IS[*]}; do                   # scan for matching nmenomic
            [[ ${IS[_j]} = "$_v" ]] && { 
                $_ASM && printf "\n%04x  %02x  %s " $tpc $_j ${IS[_j]}
                MEM[tpc]=_j; (( $INCTPC ))
                _done=true; break
            }
        done
        ! $_done && for _pre in ${!ASM_PREFIX[*]}; do  # try prefixed op codes
            #printf "Scanning prefix [%02x]\n" $_pre
            for (( _j=0; _j<256; _j++ )); do        # scan for matching prefixed nmenomic
                eval "_inst=\${${ASM_PREFIX[_pre]}[_j]}"
                #printf "Scanning prefix [%02x] opcode [%s]\n" $_pre $_inst
                [[ $_inst = "$_v" ]] && { 
                    $_ASM && printf "\n%04x  %04x  %s " $tpc $(( (_pre<<8)|_j )) $_inst
                    MEM[tpc]=_pre; (( $INCTPC, MEM[tpc]=_j, $INCTPC ))
                    _done=true; break
                }
            done
            ! $_done && for (( _j=0; _j<256; _j++ )); do        # scan for matching CB nmenomic
                eval "_inst=\${${ASM_PREFIX[_pre]}CB[_j]}"
                #printf "Scanning prefix [%02x] [CB] opcode [%s]\n" $_pre $_inst
                [[ $_inst = "$_v" ]] && { 
                    $_ASM && printf "\n%04x  %06x  %s " $tpc $(( (_pre<<24)|0xcb0000|_j )) $_inst
                    MEM[tpc]=_pre; (( $INCTPC )); MEM[tpc]=0xcb; (( $INCTPC, $INCTPC )); MEM[tpc]=_j; (( $DECTPC ))  # ready to place offset
                    _done=true; break;
                }
            done
        done
        $_done && { shift; continue; }

        # not operation so asssume integer
        # FIXME: this generates odd errors when an OP code name is misspelt
        n=${_v:1}                                # get number part
        (( n==0 )) && n=_LABEL[${_v:1}]          # get label address
        case $_v in
            @*) $_ASM && printf "\nORG %04x\n" $n; tpc=n; tpc0=n;;                 # assemble into this address
            D*) (( n&=255 ));                   $_ASM && printf "%02x(%4d)" $n $n; (( MEM[tpc]=n,        $INCTPC, $INCTPC ));;  # place displacement for DDCB and FDCB    
           # +*) (( RELn, nn=(tpc+n)&65535 ));   $_ASM && printf "%02x(%4d)" $n $n; (( tpc=nn ));;  # skip n bytes +12 skips 12 bytes, +-5 skips back (prob not used)    
            r*) (( RELn, nn=(tpc+n+2)&65535 )); $_ASM && printf "%02x(%4d)" $n $n; (( MEM[tpc]=(nn&255), $INCTPC, MEM[tpc]=(nn>>8), $INCTPC ));;  # store tpc+n   
            R*) (( RELn, nn=(tpc+n+2)&65535 )); $_ASM && printf "%02x(%4d)" $n $n; (( MEM[tpc]=(nn&255), $INCTPC, MEM[tpc]=(nn>>8), $INCTPC ));;  # store tpc+n   
            b*) (( n&=255   ));                 $_ASM && printf "%02x(%4d)" $n $n; (( MEM[tpc]=n,        $INCTPC                            ));;  # store byte  
            w*) (( n&=65535 ));                 $_ASM && printf "%04x(%6d)" $n $n; (( MEM[tpc]=(n&255),  $INCTPC, MEM[tpc]=(n>>8),  $INCTPC ));;  # store word
            A*) (( n&=65535 ));                 $_ASM && printf "%04x(%6d)" $n $n; (( MEM[tpc]=(n&255),  $INCTPC, MEM[tpc]=(n>>8),  $INCTPC ));;  # store address word
             *) printf "ERROR: $FUNCNAME: Invalid OP code [%s] or number [%s]\n" $_v "$n"; exit 1  
        esac
        shift
    done
    # FIXME: put in forward references
    mem_make_readable
    $_ASM && printf "\n"
    return 0
}

# overwrite for dissassembler
#    rb()     { n=0xc4; return 0; }
#    rw()     { nn=0xdead; return 0; }
#    wb()     { return 0; }
#    ww()     { return 0; }

#    rn()     { n=MEM[pc];     (( $INCPC ));                                return 0; }
#    rD()     { D=MEM[pc];     (( $INCPC ));                   (( $RELD )); return 0; }
#    rm()     { m=MEM[pc];     (( $INCPC ));                                return 0; }
#    rnn()    { (( nn=MEM[pc] )); (( $INCPC,    nn=(MEM[pc]<<8)|nn, $INCPC )); return 0; }
#    rmm()    { (( mm=MEM[pc] )); (( $INCPC,    mm=(MEM[pc]<<8)|mm, $INCPC )); return 0; }
#    pushb()  { return 0; }
#    pushw()  { return 0; }
#    popn()   { n=0xd0; return 0; }
#    popnn()  { nn=0xbeef; return 0; }
#    popm()   { m=0x99; return 0; }
#    popmm()  { mm=0xfeed; return 0; }

#dissassemble() {
#    _DIS=true  # need to show dissassembly
#    printf "%6s %8s %4s %8s %-36s; %s\n" STATES FLAGS ADDR HEX INSTRUCTION RATE
#    for (( pc=0; pc<0xffff; )); do
#        ipc=pc                                   # save PC for display
#        inst=MEM[pc]                             # get first instruction opcode
#        if [[ -n MEM_RW[pc] ]]; then
#            execute
#            printf "e"
#            # next instruction expected at jpc
#            pc=jpc  # ignore jumps and calls (push and pop may be an issue)
#            (( pc==ipc )) && { printf "\nODD\n"; pc+=1; }
#        else
#            printf "."
#            pc+=1  # skip unassigned memory
#        fi
#    done
#    return 0
#}



