#!/bin/bash

# System-80 emulator
UTF8(){
    local -i _i=$1 _c=$2
    #set -x
    if (( _c<0x80 )); then  # ASCII
        printf -v CHR[0x80+_i] "\\\x%02x" $_c
    elif (( _c<0x0800 )); then  # 2-bytes
        printf -v CHR[0x80+_i] "\\\x%02x\\\x%02x" $((0xc0+(_c>>6))) $((0x80+(_c&0x3f)))
    elif (( _c<0x10000 )); then  # 3-bytes
        printf -v CHR[0x80+_i] "\\\x%02x\\\x%02x\\\x%02x" $((0xe0+(_c>>12))) $((0x80+((_c>>6)&0x3f))) $((0x80+(_c&0x3f)))
    else  # ignore others
        CHR[0x80+_i]="."
    fi
    printf -v CHR[0x80+_i] "%b" "${CHR[0x80+_i]}"        # convert to string into array
    return 0
}

# make a new char table
declare -a CHR

# make ASCII lookup table: eg. CHR[65]="A"
makeCHR() {
    local -i _j
    for (( _j=0x00 ; _j<0x20  ; _j++ )); do
        printf -v CHR[_j] "\\\x%02x" $((_j+0x40))  # make hex char sequence eg. \x41
        printf -v CHR[_j] "%b" "${CHR[_j]}"        # convert to string into array
    done
    for (( _j=0x20 ; _j<0x80  ; _j++ )); do 
        printf -v CHR[_j] "\\\x%02x" $_j           # make hex char sequence eg. \x41
        printf -v CHR[_j] "%b" "${CHR[_j]}"        # convert to string into array
    done
    for (( _j=0x80 ; _j<0xa0  ; _j++ )); do 
        printf -v CHR[_j] "\\\x%02x" $((_j-0x40))  # make hex char sequence eg. \x41
        printf -v CHR[_j] "%b" "${CHR[_j]}"        # convert to string into array
    done
    for (( _j=0xa0 ; _j<0x100  ; _j++ )); do 
        printf -v CHR[_j] "\\\x%02x" $((_j-0x80))  # make hex char sequence eg. \x41
        printf -v CHR[_j] "%b" "${CHR[_j]}"        # convert to string into array
    done

    _blk=" .▘.▝.▀.▖.▌.▞.▛.▗.▚.▐.▜.▄.▙.▟.█"
    for (( _j=0x80; _j<0xc0; _j++ )); do
        printf -v CHR[_j] "%s" ${_blk:(_j-0x80)%16*2:1}
    done
    return 0
}

makeCHR
#print_table CHR
#exit 0
# $_VERBOSE && print_table CHR


#chr() { printf \\$(printf '%03o' $1); }

declare -i ORD
ord() { printf -v ORD '%d' "'$1"; }

# an ugly hack to map terminal keys to system-80 memory mapped keyboard.
# this may be buggy
# when keys are read, they are mapped to keyboard memory addresses. Shift as well.
# System-80 can handle multiple key presses - we can sometimes
# Real users release keys after a while.
# We assume all keys are released by time we read keyboard addresses again.
# So if user presses SHIFT then F, we may miss this combination.
# To improve this, we intercept getkey and waitkey routines and bypass BASIC's
# keyboard scanner - it should also be faster.

# test
# IFS=;while :;do if read -N1 -t0.001 K; then printf "[got:\" %c \"]\n" $K; fi; sleep 1; done

# FIXME: try fns for each kbd line.


KEY=""
declare -ia KEY_HOLD  # try making a 
system80_readkey(){
    local -i _a=0x3800 _b=0 _j
    # just say all keys are released by now
    for (( _j=1; _j<=0x80; _j<<=1 )); do
        MEM[0x3800+_j]=0
    done
    #printf "$FUNCNAME: \n"
    IFS=  # we want any key so dont skip space and newlines
    if read -s -N1 -t0.001 KEY; then
        ord "$KEY"
        ansi_pos 8 65; ansi_clearRight; printf "1=[%02x]" $ORD
        (( _b=(1<<(ORD&7)) ))
        case "$KEY" in
            @|[a-g]) (( _a=0x3801 ));;
              [h-o]) (( _a=0x3802 ));;
              [p-w]) (( _a=0x3804 ));;
              [x-z]) (( _a=0x3808 ));;
              [0-7]) (( _a=0x3810 ));;
              [8-9]) (( _a=0x3820 ));;
                 \*) (( _a=0x3820, _b=0x04 ));;
          [+\<=\>?]) (( _a=0x3820 ));;
              [A-G]) (( _a=0x3801 )); MEM[0x3880]=1;;
              [H-O]) (( _a=0x3802 )); MEM[0x3880]=1;;
              [P-W]) (( _a=0x3804 )); MEM[0x3880]=1;;
              [X-Z]) (( _a=0x3808 )); MEM[0x3880]=1;;
     [\!\"#\$%\&\']) (( _a=0x3810 )); MEM[0x3880]=1;;  # 0 1! 2" 3# 4$ 5% 6& 7'
      [\(\):\;,_./]) (( _a=0x3820 )); MEM[0x3880]=1;;  # 8( 9) *: +; <, =_ >. ?/

           # NL CLR BRK ESC CTL BS _aB SP
              $'\n') (( _a=0x3840, _b=0x01 ));; # NL
              $'\t') (( _a=0x3840, _b=0x02 ));;  # use TAB as clear key
              $'\e') if read -s -N1 -t0.001 KEY; then
                         ord "$KEY"
                         ansi_pos 8 75; ansi_clearRight; printf "2=[%02x]" $ORD
                         case "$KEY" in
                             \[) if read -s -N1 -t0.001 KEY; then
                                     ord "$KEY"
                                     ansi_pos 8 85; ansi_clearRight; printf "3=[%02x]" $ORD
                                     case "$KEY" in 
                                         A) (( _a=0x3840, _b=0x08 ));;  # ^ is ESC
                                         B) (( _a=0x3840, _b=0x10 ));;  # v is CTRL
                                         C) (( _a=0x3840, _b=0x40 ));;  # - >
                                         D) (( _a=0x3840, _b=0x20 ));;  # <-
                                         Z) (( _a=0x3840, _b=0x04 ));;  # <shift><TAB> is break
                                     esac
                                 fi;;
                          esac
                     else  # ESC
                         (( _a=0x3840, _b=0x08 ))
                     fi;;
            $'\x7f') (( _a=0x3840, _b=0x20 ));;  # use delete as BS
                ' ') (( _a=0x3840, _b=0x80 ));;
                  *) (( _a=0x3800 ));;
        esac
        MEM[_a]=_b
        show_write $_a $_b
    fi
    unset IFS
    return 0
}

# test readkey
#false && while :; do 
#    system80_readkey
#    [[ -n $KEY ]] && {
#        printf "Read [%s]\n" "$KEY"
#        # display keyboard addresses
#        for (( _j=1; _j<=0x80 ; _j<<=1 )); do
#            printf "%04x[%02x]\n" $((0x3800+_j)) ${MEM[0x3800+_j]}
#        done
#    }
#done


system80_keyboard_R() {
    local -i _a=$1  # FIXME: not used?
    system80_readkey      # fake physical keyboard
    #n=MEM[_a]
}

system80_video_W() {
    local -i _a=$1 _b=$2 _n _row _col
    _n=MEM[_a]  # current
    (( _n==_b )) && return 0
    MEM[_a]=_b  # new
    (( _row=(_a-0x3c00)/64+1, _col=(_a-0x3c00)%64+1 ))
    #printf "\x1b[%d;%dH%c" $_row $_col "${CHR[_b]}"  # goto screen position
    printf "\x1b[%d;%dH%s" $_row $_col "${CHR[_b]}"  # goto screen position
    #printf "\x1b[%d;%dH%02x" $_row $((_col*2+64)) $_b
}

# VIDEO DRIVER
# FIXME: just update character not whole screen
s80video() {
    exit 0
    local -i row col p
    for (( row=1 ; row<=16 ; row++ )); do
        printf "%b" "\e[$row;1H"  ## goto left of row
        for (( col=1 ; col<=64 ; col++ )); do
            (( p = 15360+(row-1)*64+col-1 ))
            n=MEM[p]  # can't use rb here
            if (( n>32 )); then
                printf "%c" ${CHR[n]}
            else
                printf " "
            fi
        done
    done
    printf "%b>>>\n" "\e[17;1H"
    sleep 0.1
}

# test video
#MEM+=( [0x3c00]=65 66 67 48 49 50 )  # a few characters to display
#s80video  # display video memory

ret(){
    popnn; pc=nn
    return 0
}


show_function(){
    ansi_pos 1 65; ansi_clearRight; printf "FN:  %s" "$1"
    #show_regs
}

show_write(){
    ansi_pos 9 65; ansi_clearRight; printf "WRITE: [%04x]=%02x (%s)" $1 $2 ${CHR[$2]}
    #show_regs
}

show_regs(){
    local _flags
    get_FLAGS; _flags="$RET"
    ansi_pos 2 65; ansi_clearRight; (( $AF )); printf " AF:%04x A=%02x[%s] F=[%s]" $af $a "${CHR[a]}" "$_flags"
    ansi_pos 3 65; ansi_clearRight; (( $BC )); rw $bc; printf "(BC:%04x)=%04x [%c%c]" $bc $nn "${CHR[nn&255]}" "${CHR[nn>>8]}"
    ansi_pos 4 65; ansi_clearRight; (( $DE )); rw $de; printf "(DE:%04x)=%04x [%c%c]" $de $nn "${CHR[nn&255]}" "${CHR[nn>>8]}"
    ansi_pos 5 65; ansi_clearRight; (( $HL )); rw $hl; printf "(HL:%04x)=%04x [%c%c]" $hl $nn "${CHR[nn&255]}" "${CHR[nn>>8]}"
    ansi_pos 6 65; ansi_clearRight;            rw $sp; printf "(SP:%04x)=%04x [%c%c]" $sp $nn "${CHR[nn&255]}" "${CHR[nn>>8]}"
    ansi_pos 7 65; ansi_clearRight;            rw $pc; printf "(PC:%04x)=%04x       " $pc $nn
    return 0
}

info_E(){
    local -i _a=$1
    show_function "${MEM_NAME[_a]}"
    return 0
}

setupMMgr 0x0000        "RESET"

setupMMgr 0x0008        "RST 08 - Compare symbol"        RO #info_E
setupMMgr 0x0010        "RST 10 - Examine next symbol"   RO #info_E
setupMMgr 0x0018        "RST 18 - Compare DE:HL"         RO #info_E
setupMMgr 0x0020        "RST 20 - Test data mode"        RO #info_E
setupMMgr 0x0028        "RST 28 - DOS function call"     RO #info_E
setupMMgr 0x0030        "RST 30 - Load debug"            RO #info_E
setupMMgr 0x0033        "Display character; A=char"      RO #info_E
setupMMgr 0x0038        "RST 38 - Interrupt entry point" RO #info_E

get_key(){
    show_function $FUNCNAME
    IFS=
    if read -s -N1 -t0.001 KEY; then
        case "$KEY" in
            # NL CLR BRK ESC CTL BS TAB SP
            $'\n') a=0x0d;;  # ENTER
            $'\t') a=0x09;;  # ->
            $'\e') if read -s -N1 -t0.001 KEY; then  # got ESC
                       case "$KEY" in
                           \[) if read -s -N1 -t0.001 KEY; then  # got ESC[
                                   case "$KEY" in 
                                       A) a=0x5b;;  # ^ is ESC
                                       B) a=0x0a;;  # v is CTRL
                                       C) a=0x09;;  # - >
                                       D) a=0x08;;  # < -
                                       Z) a=0x01;;  # <shift><TAB> is BREAK
                                       *) ord "$KEY"; a=ORD;;
                                   esac
                               else
                                   a=0x5b
                               fi;;
                            *) ord "$KEY"; a=ORD;;
                       esac
                   else  # ESC
                       a=0x5b
                   fi;;
          $'\x7f') a=0x1f;;  # use delete as CLEAR
              ' ') a=0x20;;  # SPACE
                *) ord "$KEY"; a=ORD;;
        esac
        (( f&=255-FZ ))  # key pressed
        ansi_pos 11 65; ansi_clearRight; printf "GET KEY=[%02x]" $a
        (( a==0x01 )) && {
            ansi_pos 11 95; ansi_clearRight; printf "GET KEY BREAK"
            decode_from_here 0x0028  # BREAK
        }
    else
        a=0  # fixes BREAK error but stops SI working
        (( f|=FZ ))  # no key pressed
    fi
    unset IFS
    ret; return 0
}

scan_keyboard_E(){
    get_key
    return 0
}

setupMMgr 0x002b        "Scan keyboard -> KEY.ASCII->A; BREAK->RST2" RO  scan_keyboard_E

setupMMgr 0x003b        "Print char" RO # info_E

decode_from_here() {
    #state_note $FUNCNAME
    pushw 0xdead                                 # fake ret address to exit from sub-emulator
    pc=$1                                        # set pc to z-80 function to call
    decode                                       # emulate from pc
    _GO=true                                     # we use _GO to exit from decode. To continue, it must be true
    return 0
}
# This address was on stack and a ret op was executed.
# A NOP will be read and executed and then decode loop will exit and decode will return 0
dead_E() {
    #state_note $FUNCNAME
    MEM[pc]=0  # force a NOP - not really required as initiated memory returns 0
    _GO=false
    return 0
}
setupMMgr 0xdead          "DEAD STOP"    RO dead_E  # special function to force emulator to return to bash

jump(){
    local -i _new_pc=$1
    pc=_new_pc
    return 0
}


wait_key_E(){
    show_function $FUNCNAME
    #a=0
    IFS=
    read -s -N1 KEY
    case "$KEY" in
        # NL CLR BRK ESC CTL BS TAB SP
        $'\n') a=0x0d;;  # ENTER
        $'\t') a=0x09;;  # ->
        $'\e') if read -s -N1 -t0.001 KEY; then  # got ESC
                   case "$KEY" in
                       \[) if read -s -N1 -t0.001 KEY; then  # got ESC[
                               case "$KEY" in 
                                   A) a=0x5b;;  # ^ is ESC
                                   B) a=0x0a;;  # v is CTRL
                                   C) a=0x09;;  # - >
                                   D) a=0x08;;  # < -
                                   Z) a=0x01;;  # <shift><TAB> is BREAK
                                   *) ord "$KEY"; a=ORD;;
                               esac
                           else
                               a=0x5b
                           fi;;
                       *) ord="$KEY"; a=ORD;;
                   esac
               else  # ESC
                   a=0x5b
               fi;;
        $'\x7f') a=0x1f;;  # use delete as CLEAR
            ' ') a=0x20;;  # SPACE
              *) ord "$KEY"; a=ORD;;
    esac
    unset IFS
    ansi_pos 10 65; ansi_clearRight; printf "WAIT KEY=[%02x]" $a
    (( a==0x01 )) && {
        ansi_pos 10 95; ansi_clearRight; printf "BREAK"
        decode_from_here 0x0028  # BREAK
    }
    ret; return 0
}

setupMMgr 0x0049        "Wait for keyboard input -> KEY.ASCII->A" RO wait_key_E

delay_E(){  # we dont need more delays!
    show_function $FUNCNAME
    ret; return 0
}

setupMMgr 0x0060        "Delay" RO delay_E

bypass_mem_size_E(){
    h=0x80; l=0x00  # set mem size to 65536 (0) 16384 0x4000?
    jump 0x00e7
    return 0
}

setupMMgr 0x00c4        "Start to determine mem size" RO #info_E
setupMMgr 0x00c7        "Loop to determine mem size" RO bypass_mem_size_E
setupMMgr 0x00e7


setupMMgr 0x0105-0x010c  READY?
setupMMgr 0x012d        "JP TABLE_VEC"

clear_screen_E(){
    for (( _r=1; _r<=16; _r++ )); do
        ansi_pos $_r 64
        ansi_clearLeft
    done
    ret; return 0
}

setupMMgr 0x01c9        "Clear screen" #RO clear_screen_E

setupMMgr 0x0212        "Turn on motor"
setupMMgr 0x022c        "Blink **"

declare -ia LOAD=( $( od -vAn -tu1 -w16 "spcinvds.cas" ) )  # invade (lowercase)
#declare -ia LOAD=( $( od -vAn -tu1 -w16 "fs1.cas" ) )  # FS1
#for _j in ${!LOAD[*]}; do
#    printf "LOAD[%04x]=%02x\n" $_j ${LOAD[_j]}
#done
declare -i LOAD_POS=0
declare -i LOAD_BIT=7

cas_read_byte_E(){
    (( a=LOAD[LOAD_POS] ))
    #ansi_pos 13 65; ansi_clearRight; rw $sp; printf "CAS READ LOAD[%04x]=[%02x] RET=[%04x]" $LOAD_POS $a $nn
    (( LOAD_POS+=1 ))
    ret; return 0    
}

cas_read_bit_E(){
    local -i _m
    (( a=a<<1, _m=(1<<LOAD_BIT) ))
    (( a=a|((LOAD[LOAD_POS]&_m)>>LOAD_BIT) ))
    (( LOAD_BIT-=1 ))
    (( LOAD_BIT<0?(LOAD_POS+=1, LOAD_BIT=7):0 ))
    #ansi_pos 14 65; ansi_clearRight; printf "CAS LOAD[POS=%04x]=%02x READ=[%02x] BIT=%d" $LOAD_POS ${LOAD[LOAD_POS]} $a $LOAD_BIT
    (( a==0xa5 )) && sleep 1
    ret; return 0    
}

setupMMgr 0x0235        "Read one byte" RO cas_read_byte_E
setupMMgr 0x0241        "Read one bit" RO cas_read_bit_E
setupMMgr 0x0264        "Write one byte"
setupMMgr 0x0284        "Write leader"
setupMMgr 0x0296        "Read leader"
setupMMgr 0x02a9        "System" RO #info_E
setupMMgr 0x02ed        "Load until 78 or 3C" RO #info_E

setupMMgr 0x0307        "Read chksum" RO #info_E
setupMMgr 0x0314        "Read word" RO #info_E

read_key_E(){
    ansi_pos 11 65; ansi_clearRight; #printf "KEY=[%02x]" $d
    return 0
}

setupMMgr 0x0452        "key in a" RO read_key_E

setupMMgr 0x05d1        "Get printer status"
setupMMgr 0x05d9        "Wait for next line; HL=buffer -> B=count; A=last; C=buffer size"

setupMMgr 0x06cc        "BASIC READY?" RO #info_E # "sleep 5"
setupMMgr 0x06d2-0x0708 "RST INIT"

setupMMgr 0x0a7f        "Float -> Integer"
setupMMgr 0x0ab1        "Integer -> Single"
setupMMgr 0x0adb        "Integer -> Double"

setupMMgr 0x0bc7        "Integer sub: HL=HL-DE"
setupMMgr 0x0bd2        "Integer add; HL=HL+DE"
setupMMgr 0x0bf2        "Integer mul: HL=HL*DE"

setupMMgr 0x0e65        "ASCII -> Double"
setupMMgr 0x0e6c        "ASCII -> Binary"

setupMMgr 0x0faf        "HL -> ASCII"
setupMMgr 0x0fbe        "Float -> ASCII"

setupMMgr 0x132f        "Integer -> ASCII"
setupMMgr 0x18c9-0x18f6 "Error codes"
setupMMgr 0x18f8-0x1904 "RAM DIV support routine"
setupMMgr 0x1905-0x191c "RAM DATA"
setupMMgr 0x191d-0x1923 "ERROR" RO #info_E
setupMMgr 0x1924-0x1928 "IN" RO #info_E
setupMMgr 0x1929-0x192f "READY" RO #info_E
setupMMgr 0x1930-0x1935 "BREAK" RO #info_E
setupMMgr 0x1a76        "READY>" RO #info_E

setupMMgr 0x1bb3        "? input" RO #info_E

setupMMgr 0x1e5a        "ASCII -> Integer"

setupMMgr 0x2490        "Integer div: DE/HL"
setupMMgr 0x27c9        "Return free memory"
setupMMgr 0x2865        "Return string length at HL in ??"
setupMMgr 0x28a7        "Write message" RO #info_E
setupMMgr 0x2b75        "Print message" RO #info_E

setupMMgr 0x2bc6        "DELETE" RO #info_E
setupMMgr 0x2bf5        "CSAVE" RO #info_E
setupMMgr 0x2c1f        "CLOAD" RO #info_E

#setupMMgr 0x ""

setupMMgr 0x3000        "ROM"
setupMMgr 0x3000-0x37df  "??"

setupMMgr 0x37e0        "INT LAT " RW
setupMMgr 0x37e1        "DSK SEL " RW
setupMMgr 0x37ec        "DSK CON " RW # "MEM[ta]=0xff; sleep 5"

setupMMgr 0x3c00-0x3fff "VID" RW system80_video_W 
#????setupMMgr 0x3c00-0x3f00 "VID"         RW

setupMMgr 0x3800-0x3bff "KBD"                              RW
setupMMgr 0x3801        "KBD @ABCDEFG"                     RW system80_keyboard_R
setupMMgr 0x3802        "KBD HIJKLMNO"                     RW system80_keyboard_R
setupMMgr 0x3804        "KBD PQRSTUVW"                     RW system80_keyboard_R
setupMMgr 0x3808        "KBD XYZ     "                     RW system80_keyboard_R
setupMMgr 0x3810        "KBD 01!2\"3#4\$5%6&7'"            RW system80_keyboard_R
setupMMgr 0x3820        "KBD 8(9)*:+;<,=_>.?/"             RW system80_keyboard_R
setupMMgr 0x3840        "KBD NL CLR BRK ESC CTL BS TAB SP" RW system80_keyboard_R
setupMMgr 0x3880        "KBD SHIFT"                        RW system80_keyboard_R


setupMMgr 0x4000-0x7fff "RAM"            RW

setupMMgr 0x4000-0x4013 "RST"            RW
setupMMgr 0x4014        "?"              RW

setupMMgr 0x4015-0x401d "KBD DEV"        RW
setupMMgr 0x4016-0x4017 "KBD CALL"       RW

setupMMgr 0x401d-0x4025 "VID DEV"        RW
setupMMgr 0x401e-0x401f "VID CALL"       RW
setupMMgr 0x4020-0x4021 "VID CUR"        RW

setupMMgr 0x4025-0x404f "PRT DEV"        RW
setupMMgr 0x4026-0x4027 "PRT CALL"       RW
setupMMgr 0x4028        "PRT LINES/PAGE" RW
setupMMgr 0x4029        "PRT LINE"       RW

show_mem_size_W(){
    local -i _a=$1 _b=$2
    ansi_pos 12 65; ansi_clearRight; printf "MEM SIZE=[%02x] @ pc=%04x" $_b $pc
    return 0
}

setupMMgr 0x4049        "MEM SIZE"       RW show_mem_size_W

setupMMgr 0x4050-0x4051 "DSK INT" RW
setupMMgr 0x4052-0x4053 "COM INT" RW

setupMMgr 0x4054-0x40a3 "?" RW

setupMMgr 0x40a4-0x40a5 "BAS BEG" RW
setupMMgr 0x40b1-0x40b2 "BAS END" RW # show_mem_size_W

setupMMgr 0x40d6-0x40d7 "RAM SIZ" RW
setupMMgr 0x40df-0x40e0 "SYS BEG" RW

setupMMgr 0x40ec-0x40ed "EDIT LINE" RW
setupMMgr 0x40f5-0x40f6 "BAS LINE" RW
setupMMgr 0x40fd-0x40fd "BAS FREE" RW
setupMMgr 0x4152-0x41a5 "JP TABLE (JP 012d)" RW
setupMMgr 0x41a6-0x41e5 "CALL TABLE (RET)" RW

setupMMgr 0x41e6-0x42e7 "BUF IO" RW
setupMMgr 0x41e6-0x41f9 "INIT STACK" RW

setupMMgr 0x42e8        ZERO RW
setupMMgr 0x42e9-0x7fff BASIC RW
#setupMMgr 0x8000-0xffff 32K RW
#setupMMgr 0xc000-0xffff 48K RW



