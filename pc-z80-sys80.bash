#!/bin/bash

# set -u  # unset variables are an error
#set -x
#set -e  # cant ise this with (())

trap_fn() { printf "TRAP: [${FUNCNAME[*]}]: [${BASH_LINENO[*]}]\n"; exit 1; }
trap trap_fn ERR

trap_int() {
    $_FAST && exit 0  # no debug in fast mode
    _SS=true
    printf "\n<Ctrl+C pressed: enter debug mode>\n"
    dis_regs
}
trap trap_int SIGINT

#trap_ss() { _SS=true; printf "\n<Ctrl+T pressed: enter debug mode>\n"; dis_regs; }
#trap trap_int SIGUSR1

trap_exit() { 
    printf "Test: REPLY=[%s] T=[%s]\n" "$REPLY" "$_T"
    inst_dump
}
trap trap_exit EXIT

SECONDS=1


# emulator registers and flags
declare -i a b c d e f h l  sp pc  i r  iff1 iff2  x X y Y
declare -i a1 b1 c1 d1 e1 f1 h1 l1 
declare -i q t cycles states halt
declare -ia MEM MEM_READ MEM_WRITE
declare -a MEM_NAME MEM_RW
declare -a OUT IN
declare -a R=( B C D E H L "(HL)" A )
declare -a FLAG_NAMES=( C N P X H Y Z S )
declare -i FS=0x80 FZ=0x40 FY=0x20 FH=0x10 FX=0x08 FP=0x04 FN=0x02 FC=0x01  
_STOP=false

# emulatior globals
declare -i n nn m mm af af1 bc bc1 de de1 hl hl1 ix iy D # used for holding 8bit and 16bit values
declare -i ipc jpc # holds pc of current instruction - used for displaying

# debugging globals
declare -a TRAP MSG

declare -i j  # global temporary integers
declare g    #global temporary other
declare -a AREA
declare B="%%02x" W="%%04x" C=" ; [%%b]" R="%%+d" # format strings for computed functions
declare -a HEX=( 0 1 2 3 4 5 6 7 8 9 a b c d e f )

# map emulator CPU register pair names to printed names 
declare -A RPN=( [hl]=HL [xX]=IX [yY]=IY [af]=AF [bc]=BC [de]=DE [sp]=SP [pc]=PC )

# map CPU registers to implemente emulator variables - mostly done for IX and IY
declare -A RN=( [a]=A [b]=B [c]=C [d]=D [e]=E [h]=H [l]=L [x]=IXh [X]=IXl [y]=IYh [Y]=IYl )

# print message flags
_TEST=true
_VERBOSE=false
#_VERBOSE=true
_DIS=true
_DIS=false
_ASM=false
_ASSERT=true #false
_MEMPROT=true
_MEMPROT=false
_FAST=false
$_FAST && { _ASSERT=false; _MEMPROT=false; }  # turn off other stuff

GEN=generated-functions.bash
printf "# Generated functions\n" > $GEN

print_table() {
    local T=$1 v; local -i j r c
    printf "\x1b[2J\x1b[1;1H%s TABLE" ${T^^}
    for (( j=0 ; j<256 ; j++ )); do
        (( r=(j>>4), c=(j&15) ))
        (( r==0 )) && printf "\x1b[32m\x1b[%d;%dH%2x\x1b[m" 3 $((c*3+6)) $c  # top row
        (( c==0 )) && printf "\x1b[32m\x1b[%d;%dH%2x\x1b[m" $((r*1+4)) 3 $r  # left column
        eval "v=\"\${$T[$j]}\""
        #printf "\x1b[%d;%dH%2b" $((r*1+4)) $((c*3+6)) $v
        #printf "%3d  %3d  [%c]\n" $((r*1+4)) $((c*3+6)) "$v"  # need quotes to avoid pathname expansion
        printf "\x1b[%d;%dH%2c" $((r*1+4)) $((c*3+6)) "$v"
    done
    printf "\x1b[2E"
    return 0
}

# make byte parity lookup table
declare -ia PAR
makePAR() {
    local -i j p
    for (( j=0 ; j<256 ; j++ )); do
        (( p=j,
           p=(p&15)^(p>>4),
           p=(p& 3)^(p>>2),
           p=(p& 1)^(p>>1),
           PAR[j]=(!p)*FP ))
    done
    return 0
}
makePAR; $_VERBOSE && print_table PAR

# load instruction set
. instruction-set.bash

# define display colours based on RW type
declare -a MEM_COL=( [RO]=1 [RW]=2 [XX]=7 [IO]=3 [VD]=6 )

# setupMMgr <from>[<-to>] <name> <RO|RW> <driver function> # not used <color>
setupMMgr() {
    local ADD="$1" NAME="$2" RW="$3" DRIVER="$4"
    RW=${RW:-RO}
    FR=${ADD%-*}; TO=${ADD#*-};
    for (( j=$FR; j<=$TO; j++ )); do
        MEM_NAME[j]="$NAME"
        MEM_RW[j]=$RW
        [[ -n $DRIVER ]] && MEM_DRIVER[j]="$DRIVER"  # dont set if no driver
    done
    return 0
}

declare -i _RUNS=0
onerun() {
    (( _RUNS==1 )) && { printf "\nWarm-boot so stop.\n"; _STOP=true; }
    _RUNS+=1
    return 0
}

declare -a CHR

# make ASCII lookup table: eg. CHR[65]="A"
makeCHR() {
    local -i j
    for (( j=0x00 ; j<0x100  ; j++ )); do 
        printf -v CHR[j] "\\\x%02x" $j           # make hex char sequence eg. \x41
        printf -v CHR[j] "%b" "${CHR[j]}"        # convert to string into array
    done
}
makeCHR

$_VERBOSE && print_table CHR

# load system-80 ROM
. system80-interface.bash

# printf macros - these help standardise code generation and cause bugs to affect many instructions to aide detection
# these also work in (()) eg. unset X Y HL; HL="1+1"; declare -i Y; declare -ia X=(2 4 6 8); (( Y=X[$HL] )); echo $Y
# WARNING: use no spaces within strings here
RELn="(n>127)?(n-=256):0"                        # printf macro to convert byte to int
RELD="(D>127)?(D-=256):0"                        # printf macro to convert byte to int
RELm="(m>127)?(m-=256):0"                        # printf macro to convert byte to int

PCn="pc=(pc+n)&65535"                            # printf macro to add n to pc and fix result
PCD="pc=(pc+D)&65535"                            # printf macro to add D to pc and fix result
NNPCn="nn=(pc+n)&65535"                          # printf macro to add n to pc and fix result
NNPCD="nn=(pc+D)&65535"                          # printf macro to add D to pc and fix result

SEThl="h=(hl>>8),l=hl&255"
SETde="d=(de>>8),e=de&255"
SETbc="b=(bc>>8),c=bc&255"
SETix="x=(ix>>8),X=ix&255"
SETiy="y=(iy>>8),Y=iy&255"

SETSP="0"
SETPC="0"

SEThlnn="h=(nn>>8),l=nn&255"
SETdenn="d=(nn>>8),e=nn&255"
SETbcnn="b=(nn>>8),c=nn&255"
SETixnn="x=(nn>>8),X=nn&255"
SETiynn="y=(nn>>8),Y=nn&255"
SETSPnn="sp=nn"
SETPCnn="pc=nn"

INCbc="c+=1,(c==256)?(b=(b+1)&255,c=0):0"
INCde="e+=1,(e==256)?(d=(d+1)&255,e=0):0"
INChl="l+=1,(l==256)?(h=(h+1)&255,l=0):0"
INCix="X+=1,(X==256)?(x=(x+1)&255,X=0):0"
INCxX="$INCix"
INCiy="Y+=1,(Y==256)?(y=(y+1)&255,Y=0):0"
INCyY="$INCiy"

INCr="r=(r&128)|((r+1)&127)"

INCBC="bc=(bc+1)&65535"
INCDE="de=(de+1)&65535"
INCHL="hl=(hl+1)&65535"
INCIX="ix=(ix+1)&65535"
INCIY="iy=(iy+1)&65535"
INCSP="sp=(sp+1)&65535"
INCPC="pc=(pc+1)&65535"

DECbc="c-=1,(c==-1)?(b=(b-1)&255,c=255):0"
DECde="e-=1,(e==-1)?(d=(d-1)&255,e=255):0"
DEChl="l-=1,(l==-1)?(h=(h-1)&255,l=255):0"
DECix="X-=1,(X==-1)?(x=(x-1)&255,X=255):0"
DECxX="$DECix"
DECiy="Y-=1,(Y==-1)?(y=(y-1)&255,Y=255):0"
DECyY="$DECiy"

DECBC="bc=(bc-1)&65535"
DECDE="de=(de-1)&65535"
DECHL="hl=(hl-1)&65535"
DECIX="ix=(ix-1)&65535"
DECIY="iy=(iy-1)&65535"
DECSP="sp=(sp-1)&65535"
DECPC="pc=(pc-1)&65535"

HL="hl=(h<<8)|l"
DE="de=(d<<8)|e"
BC="bc=(b<<8)|c"
AF="af=(a<<8)|f"
IX="ix=(x<<8)|X"
IY="iy=(y<<8)|Y"
HL1="hl1=(h1<<8)|l1"
DE1="de1=(d1<<8)|e1"
BC1="bc1=(b1<<8)|c1"
AF1="af1=(a1<<8)|f1"
PC="pc"
SP="sp"

# draft interrupt mechanism

declare -ia TNMI TINT
#TNMI[3302]="NMI"
NMI() { # iff1 not copied to iff2 [SC05]
    printf "NMI @ states=%d  pc=%04x\n" $states $pc
    pushw $pc
    #FIXME: enable later cycles+=3; states+=11
    (( iff1=0, pc=0x0066, r=(r&128)|(r+1)&127 ))
    sleep 3
    return 0
} 
#INT() {local -i inst=$1; if iff1=1 iff1=iff2=0; case im in
#  0) t=13; execute $inst
#  1) rst38 t=13
#  2) nn=i<<8|inst pc=nn t=19
#esac
#}

  # now wait for NMI or INT? then pc+=2

PREFIX=( [0xCB]="CB" [0xED]="ED" [0xFD]="FD" [0xDD]="DD")

# unhandled instructions go here
XX() {
    local inst PRE; local -i j
    rb $((pc-2))  # possible prefix
    PRE="${PREFIX[n]} "
    rb $((pc-1))  # actual instruction
    for (( j=0 ; j<6; j++ )); do inst+="${MEM[pc-1+j]} "; done
    printf "ERROR: $FUNCNAME: Unknown %soperation code [%x %x %x %x %x %x] at %4x(%5d)\n" "$PRE" $inst $((pc-1))
    _STOP=true
}


# write byte to port -ports are mapped to files on demand unless mapped in OUT array
wp() {
    local -i p=$1 v=$2
    [[ -z ${OUT[p]} ]] && { OUT[p]=$p.out; $_DIS && printf "WARNING: $FUNCNAME: Output port $p mapped to [%s]\n" ${OUT[p]}; }
    printf "%c" ${CHR[v]} >> ${OUT[p]}
    return 0
}

rp() {
    local -i p=$1
    [[ -z ${IN[p]} ]] && { IN[p]=/dev/zero; $_DIS && printf "WARNING: $FUNCNAME: Input port $p mapped to [%s]\n" ${IN[p]}; }
    read -N1 n < ${IN[p]}
    return 0
}

# ASSERTS

# assert that specified flags are set or reset. eg. assertf Z NC
assertf() {
    while [[ -n "$1" ]]; do
        case "$1" in
          0|Z) (( (f&FZ)!=FZ )) && { printf "ERROR: [${FUNCNAME[*]}]: Z not set\n";   exit 1; };;
           NZ) (( (f&FZ)==FZ )) && { printf "ERROR: [${FUNCNAME[*]}]: Z set\n";       exit 1; };;
            C) (( (f&FC)!=FC )) && { printf "ERROR: [${FUNCNAME[*]}]: C not set\n";   exit 1; };;
           NC) (( (f&FC)==FC )) && { printf "ERROR: [${FUNCNAME[*]}]: C set\n";       exit 1; };;
           PO) (( (f&FP)!=FP )) && { printf "ERROR: [${FUNCNAME[*]}]: not PO\n";      exit 1; };;
           PE) (( (f&FP)==FP )) && { printf "ERROR: [${FUNCNAME[*]}]: not PE\n";      exit 1; };;
          +|P) (( (f&FS)!=FS )) && { printf "ERROR: [${FUNCNAME[*]}]: not +\n";       exit 1; };;
          -|M) (( (f&FS)==FS )) && { printf "ERROR: [${FUNCNAME[*]}]: not -\n";       exit 1; };;
            O) (( (f&FP)!=FP )) && { printf "ERROR: [${FUNCNAME[*]}]: no overflow\n"; exit 1; };;
           NO) (( (f&FP)==FP )) && { printf "ERROR: [${FUNCNAME[*]}]: overflow\n";    exit 1; };;
        esac
        shift
    done
    return 0
}

assert() {
    ! $_DIS && return 0
    local var=$1; local -i val=$2
    printf "var=%s  val=%d\n" "$var" $val
    if [ ${!var} -eq $val ]; then
        printf "PASS: $FUNCNAME: %s = %x(%d)\n" $var $val $val
        return 0
    fi
    printf "ERROR: LINE [${BASH_LINENO[0]}] [${FUNCNAME[*]}]: %s != %x(%d); %s = %x(%d)\n" $var $val $val $var ${!var} ${!var}
    exit 1
}

# MEMORY MANAGEMENT

memname() {
    ! $_DIS && return 0                          # do nothing if not disassembling
    local -i ta=$1; local name
    j=${#AREA[*]}                                # get number of area names collected so far for this instruction
    name="${MEM_NAME[ta]}"                       # get name
    AREA[j]="$name/${MEM_READ[ta]:-0}r/${MEM_WRITE[ta]:-0}w"  # record and add read/write counts
    return 0
}

# trap access to memory
#memtrap() {
#???    ! $_DIS && return 0                          # do nothing if not disassembling
#    local -i ta=$1 # tn
#    #tn=MEM[ta]
#    $_DIS && [[ -n "${MSG[ta]}" ]] && { printf "\x1b[7;65HMSG: %-60s" "${MSG[ta]}"; sleep 1; }  # display simple messages
#    #(( ta==0x06cc )) &&               { msg "BASIC READY?"; sleep 5; return 0; }
#    DRIVER="${MEM_DRIVER[ta]}"
#    [[ -n $DRIVER ]] && "$DRIVER" $ta
#    return 0
#}

msg() {
    #! $_DIS && return 0
    printf "\x1b[6;65Hmsg: %-60s" "$1"
    return 0
}

ansi_nl()        {                  printf "\x1b[${1}E";      return 0; }
ansi_c()         { local c=$1;      printf "\x1b[${c}G";      return 0; }
ansi_pos()       { local r=$1 c=$2; printf "\x1b[${r};${c}H"; return 0; }
ansi_savecp()    {                  printf "\x1b[s";          return 0; }
ansi_restorecp() {                  printf "\x1b[u";          return 0; }
#ansi_getcp()     { local CP=$( printf "\x1b[6n" ); CP=${CP:2: -1}; ANSI_R=${CP%;*}; ANSI_C=${CP#*;}; return 0; }
ansi_col()       { local COL=$1;    printf "\x1b[%dm" $COL;   return 0; }

dis_regs() {
    local flags
    printf "REGISTERS\n"
    #printf "\x1b[s"  # save cursor
    #ansi_nl; ansi_c 65; 
    get_FLAGS; flags="$RET"
    printf "AF=%04x (%02x=%c) %16d|%-+4d %8s\n" $(( $AF )) $a "${CHR[a]}" $a $(( a>127?a-256:a )) "$flags"
    #rw $de; printf "\nDE:%04x [%04x]" $(( $DE )) $nn
    for rp in BC DE HL IX IY SP PC; do
        rr=$(( ${!rp} )); (( nn=MEM[rr]|(MEM[(rr+1)&65535]<<8) )); (( n=nn>>8, m=nn&255 ))
        printf "$rp=%04x (%04x) %5d|%-+6d %3d|%-+4d %3d|%-+4d [" $rr $nn $nn $(( nn>0x7fff?nn-65536:nn )) $n $(( n>127?n-256:n )) $m $(( m>127?m-256:m ))
        for (( j=0; j<16; j++ )); do printf "%c" "${CHR[MEM[(rr+j)&65535]]}"; done
        printf "]\n"
    done
    printf "\n"
    #printf "\nPC:%04x  SP:%04x" $pc $sp; ansi_col ${MEM_COL[sp]}; printf " [%s]" "${MEM_NAME[sp]}"; ansi_col 0
    #printf "\n[%8s]" "$flags"
    #printf "\x1b[u"  # restore cursor
    return 0
}

if $_FAST; then

memread() {
    local -i ta=$1; local DRIVER
    DRIVER="${MEM_DRIVER[ta]}"
    [[ -n $DRIVER ]] && "$DRIVER" $ta
    return 0
}

memprot() {
    local -i ta=$1; local DRIVER
    DRIVER="${MEM_DRIVER[ta]}"
    [[ -n $DRIVER ]] && "$DRIVER" $ta
    return 0
}

else

# trap read from memory and set memory value before actual read
memread() {
    local -i ta=$1; local flags RW DRIVER
    RW=${MEM_RW[ta]}
    case $RW in
        RW) ;;
        RO) ;;
       # "") printf "MEMREAD: [${FUNCNAME[*]}]\nAttempted read from unassigned %04x[%02x] @ PC=%04x\n" $ta ${MEM[ta]} $pc; exit 1;; 
    esac
    #! $_DIS && {
        #printf "\x1b[1;65H PC:%04x  SP:%04x  \x1b[%dm%s\x1b[0m" $pc $sp ${MEM_COL[RW]} ${MEM[ta]}
        #printf "\x1b[2;65H IX:%04x  IY:%04x" $(( (x<<8)|X )) $(( (y<<8)|Y )) 
        #printf "\x1b[3;65H AF:%04x  BC:%04x" $(( (a<<8)|f )) $(( (b<<8)|c ))
        #printf "\x1b[4;65H DE:%04x  HL:%04x" $(( (d<<8)|e )) $(( (h<<8)|l ))
        #get_FLAGS; flags="$RET"
        #printf "\x1b[5;65H F:%8s" "$flags"
    #}
    (( MEM_READ[ta]++ ))
    DRIVER="${MEM_DRIVER[ta]}"
    [[ -n $DRIVER ]] && eval "$DRIVER"  # use callers $ta
    return 0
}
# FIXME: IO may be RO WO or IO where a write followed by a read will get different values or reading produces different values
# hack to trap write to memory
memprot() {
    local -i ta=$1 tb=$2 tn row col; local RW DRIVER
    RW=${MEM_RW[ta]}
    case $RW in
        RO) printf "MEMPROT: [${FUNCNAME[*]}]\nAttempted write to write protected %04x[%02x] @ PC=%04x\n" $ta ${MEM[ta]} $pc; exit 1;; 
      #  "") printf "MEMPROT: [${FUNCNAME[*]}]\nAttempted write to unassigned %04x[%02x] @ PC=%04x\n" $ta ${MEM[ta]} $pc; exit 1;; 
    esac
    (( MEM_WRITE[ta]++ ))
    DRIVER="${MEM_DRIVER[ta]}"
    [[ -n $DRIVER ]] && eval "$DRIVER" # use caller's $ta
    return 0
}

fi

TA1="(ta+1)&65535"  # macro to return ta+1 withing address space

if $_ASSERT; then
    # eg. assertb varname value - don't use $var
    a_b() {
        ! $_DIS && return 0
        local var=$1
        [[ ${!var} -lt 0    ]] && { printf "ERROR: [${FUNCNAME[*]}]: %s < 0;    %s = %02x(%d)\n" $var $var ${!var} ${!var}; exit 1; }
        [[ ${!var} -gt 0xff ]] && { printf "ERROR: [${FUNCNAME[*]}]: %s > 0xff; %s = %02x(%d)\n" $var $var ${!var} ${!var}; exit 1; }
        return 0
    }

    a_w() {
        ! $_DIS && return 0
        local var=$1
        [[ ${!var} -lt 0      ]] && { printf "ERROR: [${FUNCNAME[*]}]: %s < 0;      %s = %02x(%d)\n" $var $var ${!var} ${!var}; exit 1; }
        [[ ${!var} -gt 0xffff ]] && { printf "ERROR: [${FUNCNAME[*]}]: %s > 0xffff; %s = %02x(%d)\n" $var $var ${!var} ${!var}; exit 1; }
        return 0
    }
    # read b or w from given address
    rb()     { local -i ta=$1;       a_w ta;         memname $ta; memread $ta;        n=MEM[ta];                                               a_b n;  return 0; }
    rw()     { local -i ta=$1;       a_w ta;         memname $ta; memread $ta;     (( nn=MEM[ta]|(MEM[$TA1]<<8) ));                            a_w nn; return 0; }
    wb()     { local -i ta=$1 tb=$2; a_w ta; a_b tb; memname $ta; memprot $ta $tb; (( MEM[ta]=tb ));                                                   return 0; }
    ww()     { local -i ta=$1 tw=$2; a_w ta; a_w tw; memname $ta; memprot $ta $tw; (( MEM[ta]=tw&255,           MEM[$TA1]=tw>>8 ));                    return 0; }
    # read b or w from (pc) - we currently assume RAM or ROM and therefore no drivers are required
    rn()     {                       a_w pc;         memread $pc;                     n=MEM[pc];     (( $INCPC ));                             a_b n;  return 0; }
    rD()     {                       a_w pc;         memread $pc;                     D=MEM[pc];     (( $INCPC ));                 a_b D; (( $RELD )); return 0; }
    rm()     {                       a_w pc;         memread $pc;                     m=MEM[pc];     (( $INCPC ));                             a_b m;  return 0; }
    # FIXME: BASH BUG: a pc=pc+1 - like statement after an array read crashed bash - except in second case???
    rnn()    {                       a_w pc;         memread $pc;                  (( nn=MEM[pc] )); (( $INCPC, nn=(MEM[pc]<<8)|nn, $INCPC )); a_w nn; return 0; }
    rmm()    {                       a_w pc;         memread $pc;                  (( mm=MEM[pc] )); (( $INCPC, mm=(MEM[pc]<<8)|mm, $INCPC )); a_w mm; return 0; }
    pushb()  { local -i tb=$1;       a_w sp; a_b tb; memprot $sp $tb;      (( $DECSP, MEM[sp]=tb ));                                                   return 0; }
    pushw()  { local -i tw=$1;       a_w sp; a_w tw; memprot $sp $tw;      (( $DECSP, MEM[sp]=tw>>8,    $DECSP, MEM[sp]=tw&255 ));                     return 0; }
    popn()   {                       a_w sp;         memread $sp;                     n=MEM[sp];     (( $INCSP ));                             a_b n;  return 0; }
    popnn()  {                       a_w sp;         memread $sp;                     nn=MEM[sp];    (( $INCSP, nn=(MEM[sp]<<8)|nn, $INCSP )); a_w nn; return 0; }
    popm()   {                       a_w sp;         memread $sp;                     m=MEM[sp];     (( $INCSP ));                             a_b m;  return 0; }
    popmm()  {                       a_w sp;         memread $sp;                     mm=MEM[sp];    (( $INCSP, mm=(MEM[sp]<<8)|mm, $INCSP )); a_w mm; return 0; }
    
elif $_MEMPROT; then

    # removed asserts
    rb()     { local -i ta=$1;       memread $ta;                n=MEM[ta];                                                  return 0; }
    rw()     { local -i ta=$1;       memread $ta;             (( nn=MEM[ta]|(MEM[$TA1]<<8) ));                               return 0; }
    wb()     { local -i ta=$1 tb=$2; memprot $ta $tb;         (( MEM[ta]=tb ));                                              return 0; }
    ww()     { local -i ta=$1 tw=$2; memprot $ta $tw;         (( MEM[ta]=tw&255,              MEM[$TA1]=tw>>8 ));            return 0; }
    rn()     {                       memread $pc;                n=MEM[pc];     (( $INCPC ));                                return 0; }
    rD()     {                       memread $pc;                D=MEM[pc];     (( $INCPC ));                   (( $RELD )); return 0; }
    rm()     {                       memread $pc;                m=MEM[pc];     (( $INCPC ));                                return 0; }
    rnn()    {                       memread $pc;             (( nn=MEM[pc] )); (( $INCPC,    nn=(MEM[pc]<<8)|nn, $INCPC )); return 0; }
    rmm()    {                       memread $pc;             (( mm=MEM[pc] )); (( $INCPC,    mm=(MEM[pc]<<8)|mm, $INCPC )); return 0; }
    pushb()  { local -i tb=$1; (( $DECSP )); memprot $sp $tb; (( MEM[sp]=tb ));                                              return 0; }
    pushw()  { local -i tw=$1; (( $DECSP )); memprot $sp $tw; (( MEM[sp]=tw>>8,    $DECSP,    MEM[sp]=tw&255 ));             return 0; }
    popn()   {                       memread $sp;                n=MEM[sp];     (( $INCSP ));                                return 0; }
    popnn()  {                       memread $sp;                nn=MEM[sp];    (( $INCSP,    nn=(MEM[sp]<<8)|nn, $INCSP )); return 0; }
    popm()   {                       memread $sp;                m=MEM[sp];     (( $INCSP ));                                return 0; }
    popmm()  {                       memread $sp;                mm=MEM[sp];    (( $INCSP,    mm=(MEM[sp]<<8)|mm, $INCSP )); return 0; }

elif $_FAST; then  # remove wrap around checks and only run memread when getting opcode on pc

    rb()     { local -i ta=$1;                           n=MEM[ta];                            return 0; }
    rw()     { local -i ta=$1;                        (( nn=MEM[ta]|(MEM[ta+1]<<8) ));         return 0; }
    wb()     { local -i ta=$1 tb=$2;                  (( MEM[ta]=tb ));                        return 0; }
    ww()     { local -i ta=$1 tw=$2;                  (( MEM[ta]=tw&255, MEM[ta+1]=tw>>8 ));   return 0; }
    rn()     {                                           n=MEM[pc++];                          return 0; }
    rD()     {                                           D=MEM[pc++];           (( $RELD ));   return 0; }
    rm()     {                                           m=MEM[pc++];                          return 0; }
    #ro()     {                       memread $pc;        m=MEM[pc++];                          return 0; }
    rnn()    {                                        (( nn=MEM[pc++]|(MEM[pc++]<<8) ));       return 0; }
    rmm()    {                                        (( mm=MEM[pc++]|(MEM[pc++]<<8) ));       return 0; }
    pushb()  { local -i tb=$1;                        (( MEM[--sp]=tb ));                      return 0; }
    pushw()  { local -i tw=$1;                        (( MEM[--sp]=tw>>8, MEM[--sp]=tw&255 )); return 0; }
    popn()   {                                           n=MEM[sp++];                          return 0; }
    popnn()  {                                        (( nn=MEM[sp++]|(MEM[sp++]<<8) ));       return 0; }
    popm()   {                                           m=MEM[sp++];                          return 0; }
    popmm()  {                                        (( mm=MEM[sp++]|(MEM[sp++]<<8) ));       return 0; }

else

    # removed mem read and write protection
    # need to trap some reads and writes to make drivers
    rb()     { local -i ta=$1;       memread $ta;                n=MEM[ta];                                                  return 0; }
    rw()     { local -i ta=$1;       memread $ta;             (( nn=MEM[ta]|(MEM[$TA1]<<8) ));                               return 0; }
    wb()     { local -i ta=$1 tb=$2; memprot $ta $tb;         (( MEM[ta]=tb ));                                              return 0; }
    ww()     { local -i ta=$1 tw=$2; memprot $ta $tw;         (( MEM[ta]=tw&255,              MEM[$TA1]=tw>>8 ));            return 0; }
    rn()     {                       memread $pc;                n=MEM[pc];     (( $INCPC ));                                return 0; }
    rD()     {                       memread $pc;                D=MEM[pc];     (( $INCPC ));                   (( $RELD )); return 0; }
    rm()     {                       memread $pc;                m=MEM[pc];     (( $INCPC ));                                return 0; }
    rnn()    {                       memread $pc;             (( nn=MEM[pc] )); (( $INCPC,    nn=(MEM[pc]<<8)|nn, $INCPC )); return 0; }
    rmm()    {                       memread $pc;             (( mm=MEM[pc] )); (( $INCPC,    mm=(MEM[pc]<<8)|mm, $INCPC )); return 0; }
    pushb()  { local -i tb=$1;                        (( $DECSP, MEM[sp]=tb ));                                              return 0; }
    pushw()  { local -i tw=$1;                        (( $DECSP, MEM[sp]=tw>>8,    $DECSP,    MEM[sp]=tw&255 ));             return 0; }
    popn()   {                                                   n=MEM[sp];     (( $INCSP ));                                return 0; }
    popnn()  {                                                   nn=MEM[sp];    (( $INCSP,    nn=(MEM[sp]<<8)|nn, $INCSP )); return 0; }
    popm()   {                                                   m=MEM[sp];     (( $INCSP ));                                return 0; }
    popmm()  {                                                   mm=MEM[sp];    (( $INCSP,    mm=(MEM[sp]<<8)|mm, $INCSP )); return 0; }

fi

# load assembler
. pc-z80-assembler.bash

mem_make_readable() {
    for j in ${!MEM[*]}; do                      # set loaded memory to RO
        [[ ${MEM_RW[j]} = "" ]] && MEM_RW[j]="RO"
    done
    return 0
}

dump() {
    printf "DUMP PROGRAMMED MEMORY...\n"
    local -i tpc
    for tpc in ${!MEM[*]}; do printf "%04x  %02x %d\n" $tpc ${MEM[tpc]} ${MEM[tpc]}; done
    return 0
}

# restart CPU will all registers preserved (normally you would set pc to 0x0000)
# CPU lines, timing, i and r are reset
warm_boot() {
    $_VERBOSE && printf "Start Program with current register values\n"
    SECONDS=1                                    # hack to eliminate division/0
    _STOP=false
    (( D=0, q=t=0, halt=0, iff1=iff2=0, i=0xff, r=0 ))  # [SC05]
    cycles=states=0
    decode                                       # like a real reset, start work
    #dissassemble
    return 0
}

# start CPU with general purpose registers set
start() {
    $_VERBOSE && printf "Start Program\n"
    (( sp=0xffff, pc=0x0000 ))  # [SY05]
    warm_boot                                       # like a real reset, start work
    return 0
}

# [SY05] The Undocumented Z80 Documented, Sean Young, V0.91, 2005
# emuilate a real reset or power-on of CPU
reset() {
    $_VERBOSE && printf "Reset CPU\n"
    (( a=f=b=c=d=e=h=l=x=X=y=Y=a1=f1=b1=c1=d1=e1=h1=l1=x1=X1=y1=Y1=0xff ))  # [SY05] - could randomise these
    start
    return 0
}

# FIXME: emulate RFSH pin by setting to 0 in M1 and 1 otherwise

declare -i INST  # instruction popularity counter

INC_IS="INST[m]++"
INC_CB="INST[0xcb00|m]++"
INC_DDCB="INST[0xddcb00|m]++"
INC_FD="INST[0xfd00|m]++"
INC_FDCB="INST[0xfdcb00|m]++"
INC_ED="INST[0xed00|m]++"
INC_DD="INST[0xdd00|m]++"

inst_dump() {
    for m in ${!INST[*]}; do
        if   (( m<=0xff ));     then g="${IS[m]}"
        elif (( m<=0xcbff ));   then g="${CB[m&255]}"
        elif (( m<=0xddff ));   then g="${DD[m&255]}"
        elif (( m<=0xedff ));   then g="${ED[m&255]}"
        elif (( m<=0xfdff ));   then g="${FD[m&255]}"
        elif (( m<=0xddcbff )); then g="${DDCB[m&255]}"
        elif (( m<=0xfdcbff )); then g="${FDCB[m&255]}"
        else                             g="?????"
        fi
        printf "%9d %6x %8s %d\n" $m $m "$g" ${INST[m]}
    done | sort -n -r -k4 | cat
}

if $_FAST; then
    #execute() { local DRIVER="${MEM_DRIVER[pc]}"; (( $INC_IS )); [[ -n $DRIVER ]] && { local -i ta=pc; "$DRIVER"; }; m=MEM[pc++]; ${IS[m]}; }
    execute() { local DRIVER="${MEM_DRIVER[pc]}"; [[ -n $DRIVER ]] && { local -i ta=pc; "$DRIVER"; }; m=MEM[pc++]; ${IS[m]}; }
    MAPcb()   {                           m=MEM[pc++]; ${CB[m]};   }
    MAPddcb() { D=MEM[pc++]; (( $RELD )); m=MEM[pc++]; ${EDCB[m]}; }
    MAPfdcb() { D=MEM[pc++]; (( $RELD )); m=MEM[pc++]; ${FDCB[m]}; }
    MAPed()   {                           m=MEM[pc++]; ${ED[m]};   }
    MAPdd()   {                           m=MEM[pc++]; ${DD[m]};   }
    MAPfd()   {                           m=MEM[pc++]; ${FD[m]};   }
else
    execute() {     rm; (( $INCr, $INC_IS ));                       eval ${IS[m]}   || exit 1; (( cycles+=q, states+=t )); return 0; }

    # add extra machine cycle and states here
    MAPcb()   {     rm; (( $INCr, $INC_CB,   cycles+=1, states+=4 )); eval ${CB[m]}   || exit 1;                             return 0; }
    # read IX offset here. r not increased. extra cycle/states for CB and D
    MAPddcb() { rD; rm; ((        $INC_DDCB, cycles+=2, states+=8 )); eval ${EDCB[m]} || exit 1;                             return 0; }
    MAPfdcb() { rD; rm; ((        $INC_FDCB, cycles+=2, states+=8 )); eval ${FDCB[m]} || exit 1;                             return 0; }

    MAPed()   {     rm; (( $INCr, $INC_ED,   cycles+=1, states+=4 )); eval ${ED[m]}   || exit 1;                             return 0; }
    # stray DD and FD increase r too
    MAPdd()   {     rm; (( $INCr, $INC_DD,   cycles+=1, states+=4 )); eval ${DD[m]}   || exit 1;                             return 0; }
    MAPfd()   {     rm; (( $INCr, $INC_FD,   cycles+=1, states+=4 )); eval ${FD[m]}   || exit 1;                             return 0; }
fi

load() {
    local -i ta=$1; local filename="$2"
    $_VERBOSE && printf "LOADING $filename...\n"
    if (( ta==0 )); then
        MEM=( $( od -vAn -tu1 -w16 "$filename" ) ) # load ROM
    else
        MEM=( [ta-1]=0 $( od -vAn -tu1 -w16 "$filename" ) ) # load ROM
    fi
    #MEM=( $( od -vAn -tu1 -w16 system_80_rom ) ) # load ROM
    #MEM=( [ta-1]=0 $( od -vAn -tu1 -w16 CPM/zexdoc.com ) ) # load ROM
    #MEM=( [ta-1]=0 $( od -vAn -tu1 -w16 prelim.com ) ) # load ROM
    #dump
    mem_make_readable
    return 0
}

get_FLAGS() {
    local t
    for (( j=7; j>=0; j-- )); do
        (( f&(1<<j) )) && t+=${FLAG_NAMES[j]} || t+="."
    done
    RET="$t"
    return 0
}

if $_FAST; then

dis() {
    $_DIS || return 0
    local op=$1 format="$2" flags args; local -i tpc inst=0
    get_FLAGS; flags="$RET"
    case $(( pc-ipc )) in
        1) (( inst= MEM[ipc] ));;
        2) (( inst=(MEM[ipc]<<8)  |  MEM[ipc+1] ));;
        3) (( inst=(MEM[ipc]<<16) | (MEM[ipc+1]<<8)  |  MEM[ipc+2] ));;
        4) (( inst=(MEM[ipc]<<24) | (MEM[ipc+1]<<16) | (MEM[ipc+2]<<8) | MEM[ipc+3] ));;
        *) printf "PC-IPC=%d\n" $(( pc-ipc ))
           for (( tpc=ipc; tpc<pc; tpc++ )); do
               (( inst=(inst<<8)|MEM[tpc] ))
           done
    esac
    shift 2
    printf -v args "$format" "$@"
    printf "%6d %8s %04x %8x %-5s %-30s\n" $states "$flags" $ipc $inst $op "$args"
    return 0
}

dnn() {
    $_DIS || return 0
    dis "$@"
}

else

dis() {
    jpc=pc                                       # save pc before jump or call
    $_DIS || return 0
    local op=$1 format="$2" inst temp flags args name; local -i tpc
    name="${MEM_NAME[ipc]}"
    [[ -n "$name" ]] && printf "%s:\n" "$name" 
    get_FLAGS; flags="$RET"
    printf "%6d %8s %04x " $states "$flags" $ipc
    for (( tpc=ipc; tpc<pc; tpc++ )); do
        printf -v temp "%02x" ${MEM[tpc]}
        inst+=$temp
    done
    shift 2
    #printf "AREA[0]=%s  AREA[1]=%s\n" "${AREA[0]}" "${AREA[1]}"

    format="${format/\(/${AREA[0]}{}"  # name memory - 2 should be enough
    format="${format/\(/${AREA[1]}{}"
    format="${format//{/(}"
    #printf -v args "$format" $*
    printf -v args "$format" "$@"
    printf "%8s %-5s %-30s; %d kHz [%s:%d]\n" "$inst" $op "$args" $(( states/SECONDS/1000 )) "${BASH_SOURCE[1]}" ${BASH_LINENO[0]}
    #printf "format=[%s]  args=[%s]\n" "$format" "$args"
    #printf "param[%s]\n" "$@"
    unset "AREA"
    return 0
}

# special case for OP "format" nn. eg. JP "" 0x1234
dnn() {
    jpc=pc                                       # save pc before jump or call
    $_DIS || return 0
    local op=$1 format="$2" inst temp flags args name; local -i tpc ta=$3
    name="${MEM_NAME[ipc]}"
    [[ -n "$name" ]] && printf "%s:\n" "$name" 
    get_FLAGS; flags="$RET"
    printf "%6d %8s %04x " $states "$flags" $ipc
    for (( tpc=ipc; tpc<pc; tpc++ )); do
        printf -v temp "%02x" ${MEM[tpc]}
        inst+=$temp
    done
    shift 2
    name="${MEM_NAME[ta]}"
    if [[ -z "$name" ]]; then 
        printf -v args "$format" $*
    else
        printf -v args "$format:%s" $* "$name"
    fi
    printf "%8s %-5s %-30s; %d kHz [%s:%d]\n" "$inst" $op "$args" $(( states/SECONDS/1000 )) "${BASH_SOURCE[1]}" ${BASH_LINENO[0]}
    unset "AREA"
    #[[ -z "$name" ]] && exit 1  # pause if address unknown
    return 0
}

fi


_SS=false

decode() {
    local -i inst bpc=-1; local _redo DRIVER
    $_DIS && printf "%6s %8s %4s %8s %-36s; %s\n" STATES FLAGS ADDR HEX INSTRUCTION RATE
    if $_FAST; then
        while ! $_STOP; do 
            ipc=pc
            #execute
            DRIVER="${MEM_DRIVER[pc]}"
            #(( $INC_IS ))
            [[ -n $DRIVER ]] && { local -i ta=pc; "$DRIVER"; }
            m=MEM[pc++]
            ${IS[m]}
        done
    else
        while ! $_STOP; do
            ipc=pc                                   # save PC for display
            #[[ -n ${TRAP[pc]} ]] && { dis TRAP; eval "${TRAP[pc]}"; }  # breakpoints 
            inst=MEM[pc]                             # get first instruction opcode
            execute
            #$_STOP && break
            # look for interrupts
            # FIXME: except after EI!!! [SC05]
            [[ -n ${TNMI[states]} ]] && NMI;        # NMI 
            #(( iff==1 )) && [[ -n ${TINT[states]} ]] && INT ${TINT[states]};  # INT n 
#            ! $_DIS && s80video
            (( pc==bpc )) && { _SS=true; bpc=-1; }
            $_SS && {
                _redo=true
                while $_redo; do
                    _redo=false
                    printf "[cdlqrsxR]?>"
                    read -N1 __KEY
                    case $__KEY in
                        c) _SS=false;;                   # contunue
                        l) _SS=false; bpc=ipc;;          # stop loop here
                        q) exit 1;;
                        r) dis_regs; _redo=true;;                    # show regs
                        s) printf "\x1b[1G";;            # step
                        x) _SS=false; popnn; bpc=nn; pushw $nn;;  # run until return
                       # R) ;;  # restart and return here
                        d) printf " Dump address?> "; read ta; dump20; _redo=true;; # dump memory
                    esac
                done
            }
        done
    fi
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

dissassemble() {
    _DIS=true  # need to show dissassembly
    printf "%6s %8s %4s %8s %-36s; %s\n" STATES FLAGS ADDR HEX INSTRUCTION RATE
    for (( pc=0; pc<0xffff; )); do
        ipc=pc                                   # save PC for display
        inst=MEM[pc]                             # get first instruction opcode
        if [[ -n MEM_RW[pc] ]]; then
            execute
            printf "e"
            # next instruction expected at jpc
            pc=jpc  # ignore jumps and calls (push and pop may be an issue)
            (( pc==ipc )) && { printf "\nODD\n"; pc+=1; }
        else
            printf "."
            pc+=1  # skip unassigned memory
        fi
    done
    return 0
}



# flag spec language: see comments
makesetf(){
    local name=$1 spec=$2 flag flags PV; local -i mask fMask=0 rMask=0 sMask=0 aMask=0 xMask=0 f0=0
    printf "setf$name() { local -i n1=\$1 n2=\$2 re=\$3; (( f="
    for (( j=0; j<8; j++ )); do
        (( mask=(1<<(7-j)) ))
        flag=${spec:j:1}
        case $flag in
            .) fMask+=mask;;                     # no change - keep existing flag value
            r) rMask+=mask;;                     # take value from result
            s) sMask+=mask;;                     # take value from n2
            a) aMask+=mask;;                     # take value from register A
            0) ;;                                # set flag value to 0
            1) (( f0+=mask ));;                  # set flag value to 1
            p) flags+=" + PAR[re]";;             # lookup parity
            I) flags+=" + iff1";;                # LD A,I
          x|X) xMask+=mask;;                     # 'randomise' these flags
          z|Z) flags+=" + (re==0)*$mask";;       # rarely a different bit works same as FZ. eg BIT and FP
            +) flags+=" + (re<n1)*FC";;          # determine FC based on sum but only works on FC flag
            -) flags+=" + (re>n1)*FC";;          # determine FC based on diff but only works on FC flag
            C) flags+=" + (f&FC)*$mask";;        # copy of FC
            !) flags+=" + (f&$mask)^$mask";;     # invert flag
           ^|v) case $mask in                    # flag specific cases
                   $FZ) flags+=" + (re==0)*FZ";; # does same job as z|Z for sign flag
                   $FH) case $name in
                            ADD) flags+=" + ((n1&0x000f) + (n2&0x000f)          > 0x000f) * FH";;
                          ADD16) flags+=" + ((n1&0x0fff) + (n2&0x0fff)          > 0x0fff) * FH";;
                            ADC) flags+=" + ((n1&0x000f) + (n2&0x000f) + (f&FC) > 0x000f) * FH";;
                          ADC16) flags+=" + ((n1&0x0fff) + (n2&0x0fff) + (f&FC) > 0x0fff) * FH";;
                            INC) flags+=" + ((n1&0x000f)                       == 0x000f) * FH";;
                     SUB|CP|NEG) flags+=" + ((n1&0x000f) - (n2&0x000f)          < 0x0000) * FH";;
                          SUB16) flags+=" + ((n1&0x0fff) - (n2&0x0fff)          < 0x0000) * FH";;
                            SBC) flags+=" + ((n1&0x000f) - (n2&0x000f) - (f&FC) < 0x0000) * FH";;
                          SBC16) flags+=" + ((n1&0x0fff) - (n2&0x0fff) - (f&FC) < 0x0000) * FH";;
                            DEC) flags+=" + ((n1&0x000f)                       == 0x0000) * FH";;
                            CCF) flags+=" + (f&FC)                                        * FH";;
                        esac;;
                   $FC) case $name in
                          ADD*|ADC*) flags+=" + (re<n1)*FC";;  # does same job as +
                   SUB*|SBC*|CP|NEG) flags+=" + (re>n1)*FC";;  # does same job as -
                        esac;;
                   $FP) case $name in
                            ADD|ADC) flags+=" + ((n1&n2&~re|~n1&~n2&re) > 0x007f) * FP";;
                        ADD16|ADC16) flags+=" + ((n1&n2&~re|~n1&~n2&re) > 0x7fff) * FP";;
                                INC) flags+=" + ((~n1&re)               > 0x007f) * FP";;
                     SUB|SBC|CP|NEG) flags+=" + ((n1&~n2&~re|~n1&n2&re) > 0x007f) * FP";;
                        SUB16|SBC16) flags+=" + ((n1&~n2&~re|~n1&n2&re) > 0x7fff) * FP";;
                                DEC) flags+=" + ((n1&~re)               > 0x007f) * FP";;
                          LDI*|LDD*) flags+=" + ((b+c)                  > 0     ) * FP";;
                        esac;;
                   $FY) case $name in
                            LDI*|LDD*) flags+=" + ((n2+re)&(1<<1)) * FY";;  # pass 0 a n
                        esac;;
                   $FX) case $name in
                            LDI*|LDD*) flags+=" + ((n2+re)&(1<<3)) * FY";;  # pass 0 a n
                        esac
               esac;;
            *) printf "ERROR: $FUNCNAME: ignored flag=[%c]\n" "$flag";;
        esac
    done
    (( f0>0      )) && printf " + 0x%02x"           $f0
    (( fMask>0   )) && printf " + (f&0x%02x)"       $fMask
    (( sMask>0   )) && printf " + (n2&0x%02x)"      $sMask
    (( rMask>0   )) && printf " + (re&0x%02x)"      $rMask
    (( aMask>0   )) && printf " + (a&0x%02x)"       $aMask
    (( xMask>0   )) && ! $_FAST && printf " + (r&0x%02x)"       $xMask  # randomize based on r
    [[ -n $flags ]] && printf "%s"                 "$flags"
    printf " )); return 0; }  # spec=%s  f0=%x  f&%x n2&%x re&%x a&%x r&%x\n" "$spec" $f0 $fMask $sMask $rMask $aMask $xMark
    return 0
}

debugf(){
    printf "n1=$n1 n2=$n2 re=$re f0=$(( re&0xa8 )) fz=$(( (re==0)*FZ )) fp=$(( ((~n1&re)>127)*FP )) fh=$(( ((n1&15)==15)*FH )) -> f=$f\n"; 
    return 0
}

# set flags for re = n1 + n2, re is same register as n1
# flags S Z Y H X P N C
# bits 7(S) 5(Y) and 3(X) of re are copied into f. for add, N=0. for sub, N=1

{
if $_FAST; then
    makesetf ADD16 "..X^X.0+"
    makesetf ADC16 "rZX^Xv0+"
    makesetf SBC16 "rZX^Xv0-"
    makesetf ADD   "rZX^Xv0+"
    makesetf ADC   "rZX^Xv0+"
    makesetf SUB   "rZX^Xv1-"
    makesetf CP    "rZX^Xv1-"
    makesetf SBC   "rZX^Xv1+"
    makesetf INC   "rZX^Xv0."
    makesetf DEC   "rZX^Xv1."
    makesetf AND   "rZX1Xp00"
    makesetf XOR   "rZX0Xp00"
    makesetf OR    "rZX0Xp00"
    makesetf ROTa  "..X0X.0s"
    makesetf ROTr  "rZX0Xp0s"
    makesetf RLD   "rZX0Xp0."
    makesetf CCF   "..XCX.0!"
    makesetf SCF   "..X0X.01"
    makesetf NEG   "rZX^Xv1-"
    makesetf CPL   "..X1X.1."
    makesetf BIT   "rZX1XZ0."
    #makesetf BITx "rZs1sZ0."
    makesetf BITx  "rZX1Xp0."  # more correct version
    makesetf BITh  "rZX1XZ0."  # [SY05] don't know where FY or FX come from - assume h parsed as n2
    makesetf DAA   "rZXsXp.s"
    makesetf LDI   "..X0X^0."  # BC=0 -> FP=0 else FP=1
    makesetf LDIR  "..X0X00." 
else
    makesetf ADD16 "..^^^.0+"
    makesetf ADC16 "rZ^^^v0+"
    makesetf SBC16 "rZ^^^v0-"
    makesetf ADD  "rZr^rv0+"
    makesetf ADC  "rZr^rv0+"
    makesetf SUB  "rZr^rv1-"
    makesetf CP   "rZs^sv1-"
    makesetf SBC  "rZr^rv1+"
    makesetf INC  "rZr^rv0."
    makesetf DEC  "rZr^rv1."
    makesetf AND  "rZX1Xp00"   # FIXME:
    makesetf XOR  "rZr0rp00"
    makesetf OR   "rZr0rp00"
    makesetf ROTa "..r0r.0s"
    makesetf ROTr "rZr0rp0s"
    makesetf RLD  "rZr0rp0."
    makesetf CCF  "..aCa.0!"
    makesetf SCF  "..a0a.01"
    makesetf NEG  "rZr^rv1-"
    makesetf CPL  "..r1r.1."
    makesetf BIT  "rZr1rZ0."
    #makesetf BITx "rZs1sZ0."
    makesetf BITx "rZs1sp0."  # more correct version
    makesetf BITh "rZs1sZ0."  # [SY05] don't know where FY or FX come from - assume h parsed as n2
    makesetf DAA  "rZrsrp.s"
    makesetf LDI  "..^0^^0."  # BC=0 -> FP=0 else FP=1
    makesetf LDIR "..^0^00." 
fi

} >> $GEN


#setfRO2(){ local -i       re=$1 cf=$2; (( f=            (re&0xa8)  | (re==0)*FZ | PAR[re] | cf )); return 0; }
#setfROD(){ local -i       re=$1 cf=$2; (( f=(f&0x01)  | (re&0xa8)  | (re==0)*FZ | PAR[re] | cf )); return 0; }
#FIXME:makesetf ROT2 ""

#printf "n1=$n1 re=$re f0=$(( re&0xa8 )) fz=$(( (re==0)*FZ )) fp=$(( ((~n1&re)>127)*FP )) fh=$(( ((n1&15)==15)*FH )) -> f=$f\n"; 

# make LDrr_yz() functions
# FIXME: prefixed instructions at at least 1 M1 cycle and 4 states. IX+d add another 2 cycles and 4 states for d and another 4 for good measure (add?)

# generate functions
. pc-generate-debug.bash
#. pc-generate-fast.bash

# load manufactured functions
. $GEN

# detect missing instruction functions

detect_missing_functions() {
    # get list of functions in "^fn$|^fn2$|^fn3$|...|^fnN$" format
    local -i j; local g inst s="^$( set | grep "^[A-Za-z_][A-Za-z0-9_]* ()" | cut -d' ' -f1 | sed 's/$/\$|\^/g' | tr -d '\n' )$"
    for g in IS DD ED FD CB DDCB FDCB; do
        for (( j=0 ; j<256 ; j++ )); do
            eval "inst=\${$g[j]}"
            [[ "$inst" =~ $s ]] && printf "\n" || { printf "$g instruction %s[%02x] not defined\n" "$inst" $j; exit 1; }
        done
    done
    return 0
}

# FIXME: detect_missing_functions

# install NMI ISR for testing
asm @0x0066 EI RETN # NMI ISR

declare -iA SAVE0
declare -iA SAVE1
SAVE_REGS="f a   b c   d e   h l   x X   y Y   i r   sp   pc  iff1 iff2   a1 f1   b1 c1   d1 e1   h1 l1"  # im?
test_save_state() {
    local store=$1 reg
    for reg in $SAVE_REGS; do
        eval SAVE$store[$reg]=${!reg}  # save register
    done
    return 0
}

test_load_state() {
    local store=$1 reg
    for reg in $SAVE_REGS; do
        eval "(( $reg=SAVE$store[$reg] ))"  # load register
    done
    return 0
}

#compState() {
#    local reg diff=false
#    for reg in $SAVE_REGS; do
#        SAVE1[$reg]=${!reg}  # save register
#        (( $reg != "r" && SAVE0[$reg] != SAVE1[$reg] )) && { diff=true; printf "Reg [$reg] was [%04x] now [%04x]\n" ${SAVE0[$reg]} ${SAVE1[$reg]}; }
#    done
#    $diff && { printf "FAIL: States are different\n"; return 1; } || { printf "PASS: \n"; return 0; }
#}

# test pattern
TEST_PATTERNS="0x00 0x01 0x02 0x04 0x08 0x10 0x20 0x40 0x80 0x03 0x07 0x0f 0x1f 0x3f 0x7f 0xff 0xfe 0xfc 0xf8 0xf0 0xe0 0xc0 0x80 0xaa 0x55 0x7e 0x81"

test_setup() {
    local init="$1" res="$2" flg="$3" reg g; local -i mask
    shift 3
    $_TEST && printf "Test instruction\n"
    $_TEST && printf "    init: %s\n" "$init"
    $_TEST && printf "    res : %s\n" "$res"
    $_TEST && printf "    flg : %s\n" "$flg"
    $_TEST && printf "Randomise CPU registers\n"
    for reg in f a   b c   d e   h l   x X   y Y  r  i  a1 f1  b1 c1  d1 e1  h1 l1; do
        eval "(( $reg=$RANDOM&255 ))"                    # initialize registers
    done
    $_TEST && printf "Set SP\n"
    sp=0xff00
    setupMMgr 0xfef0-0xff00    "test stack" RW
    iff1=$RANDOM%2
    iff2=$RANDOM%2
    $_TEST && printf "Set initial values\n"
    f=0x00
    for g in $init; do
        $_TEST && printf "Init eval [%s]\n" "$g"
        eval "$g"                                # set initial values
    done
    $_TEST && printf "Save registers\n"
    test_save_state 0
    $_TEST && printf "Set expected register and flag values\n"
    for g in $res; do
        $_TEST && printf "Result eval [%s]\n" "$g"
        eval "$g"                                # set expected values
    done
    #dis_regs
    f=0x00                                       # start with no flags - too hard otherwise
    (( mask=FS|FZ|FH|FP|FN|FC ))                 # just look at documented flags
    for g in $flg; do                            # set expected flags
        case $g in
               -|M|NEG|S) (( f|=FS, mask|=FS ));;       +|P|POS|NS) (( f&=~FS, mask|=FS ));;  XS) (( mask&=~FS ));;
                     0|Z) (( f|=FZ, mask|=FZ ));;               NZ) (( f&=~FZ, mask|=FZ ));;  XZ) (( mask&=~FZ ));;
                       Y) (( f|=FY, mask|=FY ));;               NY) (( f&=~FY, mask|=FY ));;  XY) (( mask&=~FY ));;
                       H) (( f|=FH, mask|=FH ));;               NH) (( f&=~FH, mask|=FH ));;  XH) (( mask&=~FH ));;
                       X) (( f|=FX, mask|=FX ));;               NX) (( f&=~FX, mask|=FX ));;  XX) (( mask&=~FX ));;
          EVEN|OVER|O|PE) (( f|=FP, mask|=FP ));;  ODD|NOVER|NO|PO) (( f&=~FP, mask|=FP ));;  XP) (( mask&=~FP ));;
                   SUB|N) (( f|=FN, mask|=FN ));;           ADD|NN) (( f&=~FN, mask|=FN ));;  XN) (( mask&=~FN ));;
                       C) (( f|=FC, mask|=FC ));;               NC) (( f&=~FC, mask|=FC ));;  XC) (( mask&=~FC ));;
                     ALL) mask=0xff;;
             IGNORE|NONE) mask=0x00;;
                       *) #printf "Before: a=[%02x] b=[%02x] f=[%02x]" $a $b $f; 
                          eval "$g"; 
                          #printf "  After f=[%02x]\n" $f
        esac
    done
    #$_TEST && printf "Flags=%02x  Mask=%02x\n" $f $mask
    $_TEST && printf "Save expected register state\n"
    test_save_state 1
    $_TEST && printf "Load initial register values\n"
    test_load_state 0
    RET=$mask
    return 0
}

test_run() {
    local -i mask=$1; local reg pass=true 
    $_TEST && printf "Run code\n"
    pc=0; warm_boot
    $_TEST && printf "Verify that CPU has not changed state\n"
    for reg in a   b c   d e   h l   x X   y Y   a1 f1  b1 c1  d1 e1  h1 l1; do # ignore sp, i (reset at warm boot) and r
        [[ ${!reg} -ne ${SAVE1[$reg]} ]] && { printf "Reg [${reg^^}] should be [%04x], not [%04x]\n" ${SAVE1[$reg]} ${!reg}; pass=false; }
    done
    (( f&=mask ))                                # ignore flags not specified
    (( f!=SAVE1["f"] )) && { printf "Reg F & %02x should be [%02x], not [%02x]\n" $mask ${SAVE1[f]} $f; pass=false; }
    dis_regs
    $pass && printf "\nPASS: Results, unless ignored, are as expected\n\n"
    $pass || exit 1
    return 0
}

# test_inst "h4 l=0 sp=8000" "Z S NC" LDSPnn w8000 LDHLnn w4000 PUSHAF DECr_A POPAF HALT
test_inst() {
    local init="$1" res="$2" flg="$3"; local -i mask
    shift 3
    $_TEST && printf "Assemble code\n"
    asm $* HALT
    test_setup "$init" "$res" "$flg" $*; mask=$RET
    test_run $mask
    return 0
}

# test that a set on instructions does not change CPU state
test_cycle() {
    local vars="$1" res="$2" flg="$3" VAR; local -i mask VAL
    shift 3
    for VAR in $vars; do
        for VAL in $TEST_PATTERNS; do
            printf "Test: %s=[%x]\n" $VAR $VAL
            $_TEST && printf "Assemble code\n"
            asm $* HALT  # put in loop for dynamic instructions
            test_setup "$VAR=$VAL" "$VAR=$VAL $res" "$flg" $*; mask=$RET  # setup with dynamic variable. expect var not to change unless specified
            test_run $mask
        done
    done
    return 0
}

tests() {
    _DIS=true
    _ASM=false
    _TEST=false
    # test_inst <initial reg values> <expect reg values> <expect flags> <instructions>
    # test_cycle <register to cycle> <expected reg values> <expected flags> <instructions>
    # we can use any so-called printf macros here as well as use bash variables
    # WARNING: no spaces allowed in (())
    # simple expressions without bash special characters (like &, |) can be entered directly, else enclose in (())
    test_cycle a ""               "H N" @0 CPL CPL
    test_cycle a "((a=(~a)&255))" "H N" @0 CPL
    test_inst "" "" @0 CALLnn w4 HALT RET
    test_cycle a "((a=(~a+1)&255))" "((f|=(a&FS)|(a==0)*FZ|(VAL==128)*FP|(VAL!=0)*FC)) XH N"                     @0 NEG
    test_cycle a ""                 "((f|=(a&FS)|(a==0)*FZ|(((0-VAL)&255)==128)*FP|(((0-VAL)&255)!=0)*FC)) XH N" @0 NEG NEG
    test_cycle  "a b c d e h l"  ""  ""  @0 PUSHBC LDBCnn w0 POPBC PUSHDE LDDEnn w0 POPDE PUSHHL LDHLnn w0 POPHL PUSHAF LDrn_a b0 POPAF
    #exit 0
    test_cycle "d e h l" "(($HL,$DE,hl=(hl+de)&65535,$SEThl))" "XH NN ((f|=(hl<de)*FC))"      @0 ADDHLDE
    test_cycle a     ""                            "((f|=(f)*FC)) NH NN"           @0 RLA RRA
    test_cycle a     ""                            "((f|=(a&1)*FC)) NH NN"         @0 RRCA RLCA
    test_cycle a     ""                            "((f|=(a>>7)*FC)) NH NN"        @0 RLCA RRCA
    test_cycle a     "((a=(a==0)?0:0x55))"         "IGNORE"                        @0 ORr_a JPZnn r+2 LDrn_a b0x55  
    test_inst  ""    "h=0x55 l=0xaa"               ""                              @0xff00 w0x55aa @0 LDHLmm w0xff00 
    test_cycle "h l" "((sp=(h<<8)|l))"             ""                              @0 LDSPHL
    test_inst  ""    "h=0x80 l=0x00 d=0x00 e=0x01" ""                              @0 LDHLnn w0x0001 LDDEnn w0x8000 EXDEHL
    test_inst  ""    "a=0x23 h=0x01 l=0x00"        "ALL"                           @0x0100 b0x23 @0 LDHLnn w0x0100 LDrHLm_a
    test_cycle a     ""                            "((f|=(a&FS)|(a==0)*FZ|PAR[a])) NH NN NC"        @0 ORr_a
    # g is register name, k is test run value
    test_cycle "a b c d e h l"     "((a|=VAL))"  "((f|=(a&FS)|(a==0)*FZ|PAR[a])) NH NN NC"        @0 "ORr_\$VAR" # dynamic instruction
    test_cycle "a b c d e h l"     "((a^=VAL))"  "((f|=(a&FS)|(a==0)*FZ|PAR[a])) NH NN NC"        @0 "XORr_\$VAR" # dynamic instruction
    test_cycle "a b c d e h l"     "((a&=VAL))"  "((f|=(a&FS)|(a==0)*FZ|PAR[a]))  H NN NC"        @0 "ANDr_\$VAR" # dynamic instruction
    test_cycle "a b c d e h l"     "((a=(a+VAL)&255))"  "((f|=(a&FS)|(a==0)*FZ|(a<VAL)*FC))  XH XP NN"        @0 "ADDr_\$VAR" # dynamic instruction
    test_inst  "hl=0x7fff (($SEThl)) de=1 (($SETde))"        "h=0x80 l=0x00" "XH NN NC"       @0 LDHLnn w0x7fff LDDEnn w0x0001 ADDHLDE
    test_inst  "" "h=0x80 l=0x00 d=0x00 e=0x01" "XH NN NC"  @0 NOP NOP NOP JRn b-21 @0xfff0 CALLnn w0xff00 HALT @0xff00 LDHLnn w0x7fff LDDEnn w0x0001 ADDHLDE
    test_cycle b "b=0"                         ""           @0 DJNZn b-2
    
    test_cycle b ""                            "((f|=(a&FS)|(a==0)*FZ|(((a+b)&255)<b)*FC)) XH XP N"           @0 ADDr_b SUBr_b
    test_cycle c ""                            "((f|=(c&FS)|(c==0)*FZ)) XH N XP"           @0 INCr_c DECr_c
    
    test_inst "" ""                            ""           @0 JPnn w4 RST38

    setupMMgr 0x0100 "BIT" RW
    for _n in {0..7}; do
        test_cycle a "" "((f|=(((a&(1<<$_n))==0)*FZ))) XS H XP NN" @0 LDmmA w0x0100 PUSHHL LDHLnn w0x0100 BIT${_n}HLm LDrHLm_a POPHL 
        # write a to (HL), test bit _n, if set, reset it else set it.
        test_cycle a "((a^=1<<$_n))" "XZ XS H XP NN" @0 LDmmA w0x0100 PUSHHL LDHLnn w0x0100 BIT${_n}HLm JRNZn b4 SET${_n}HLm JRn b2 RES${_n}HLm LDrHLm_a POPHL 
    done

    setupMMgr 0x0100 "RLD" RW
    test_cycle  a "" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) NH NN" @0x0100 b0x23 @0 PUSHHL LDHLnn w0x0100 RLD RLD RLD POPHL
    test_cycle  a "" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) NH NN" @0x0100 b0x23 @0 PUSHHL LDHLnn w0x0100 RRD RRD RRD POPHL
    test_cycle  a "" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) NH NN" @0x0100 b0x23 @0 PUSHHL LDHLnn w0x0100 RLD RRD POPHL
    test_cycle  a "" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) NH NN" @0x0100 b0x23 @0 PUSHHL LDHLnn w0x0100 RRD RLD POPHL
    test_cycle "b c" "" "" @0 INCBC PUSHBC LDBCnn w0 POPBC DECBC
    test_cycle "d e" "" "" @0 INCDE PUSHDE LDDEnn w0 POPDE DECDE
    test_cycle "h l" "" "" @0 INCHL PUSHHL LDHLnn w0 POPHL DECHL
    test_cycle "a b c d e h l" "((\$VAR=(VAL+1)&255))" "((f|=(VAR&FS)|(VAR==0)*FZ|(VAR==128)*FP)) XH NN" @0 INCr_\$VAR
    test_cycle "a b c d e h l" "((\$VAR=(VAL-1)&255))" "((f|=(VAR&FS)|(VAR==0)*FZ|(VAR==127)*FP)) XH N" @0 DECr_\$VAR
    setupMMgr 0x0100 "test" RW
    test_cycle "a" "((MEM[0x0100]=\$VAL))" "" @0x0100 b0x55 @0 LDmmA w0x0100
    test_cycle "a" "((\$VAR=0x55))" "" @0x0100 b0x55 @0 LDAmm w0x0100
    test_cycle "a b c d e" "((\$VAR=0x55)) h=0x01 l=0x00" "" @0x0100 b0x55 @0 LDHLnn w0x0100 "LDrHLm_\$VAR"  
    test_cycle "a b c d e h l" "x=0x01 X=0x00" "" @0x0101 b\$VAL @0 LDrn_\$VAR b0x55 LDIXnn w0x0100 "LDrIXm_\$VAR" b0x01 
    test_cycle "a b c d e" "h=0x01 l=0x00" "" @0x0100 b\$VAL @0 LDrn_\$VAR b0x55 LDHLnn w0x0100 "LDrHLm_\$VAR"   
    test_cycle "a b c d e h l" "" "" @0 "LDrn_\$VAR" "b\$VAL"
    test_inst  "a=0x7f"  "a=0xfe"  "NH NN NC"  @0 RLCA
    test_inst  "a=0x80"  "a=0x01"  "NH NN C"  @0 RLCA
    test_inst  "a=0xfe"  "a=0x7f"  "NH NN NC"  @0 RRCA
    test_inst  "a=0x01"  "a=0x80"  "NH NN C"  @0 RRCA
    test_cycle "h l"  "(($HL,hl=(hl+1)&65535,$SEThl))"  ""  @0 INCHL
    test_cycle "b c"  "(($BC,bc=(bc+1)&65535,$SETbc))"  ""  @0 INCBC
    test_cycle "d e"  "(($DE,de=(de+1)&65535,$SETde))"  ""  @0 INCDE
    test_cycle "x X"  "(($IX,ix=(ix+1)&65535,$SETix))"  ""  @0 INCIX
    test_cycle "y Y"  "(($IY,iy=(iy+1)&65535,$SETiy))"  ""  @0 INCIY
    test_cycle "h l"  "(($HL,hl=(hl-1)&65535,$SEThl))"  ""  @0 DECHL
    test_cycle "b c"  "(($BC,bc=(bc-1)&65535,$SETbc))"  ""  @0 DECBC
    test_cycle "d e"  "(($DE,de=(de-1)&65535,$SETde))"  ""  @0 DECDE
    test_cycle "x X"  "(($IX,ix=(ix-1)&65535,$SETix))"  ""  @0 DECIX
    test_cycle "y Y"  "(($IY,iy=(iy-1)&65535,$SETiy))"  ""  @0 DECIY
    
    test_inst "" ""               "((f^=FC))" @0 CCF
    test_inst "" ""                      "XH" @0 CCF CCF
    
    
}    

#tests

# more tests that I am working on
_DIS=true
_ASM=false
_TEST=false

#test_cycle "a b" "((c=(a==b)?2:1))" "((n=(a-b)&255,f|=(n&FS)|(n==0)*FZ|(n>a)*FC)) XP XH N" @0 CPr_b JPZnn w0x0100 LDrn_c b1 HALT @0x0100 LDrn_c b2
#exit 0

zexdoc() {
    # CP/M functions
    . pc-cpm.bash

    # prelim.com
    . pc-zexdoc.bash

    _DIS=false
    load 0x100 "CPM/zexdoc.com"
    # MEM[0x3840]=0x04 BRK # Boot from disk?
    asm @0 JPnn w0x0100 @5 RET w0xe400  # for zexdoc.com
    #asm @0x013a w0  # don't do any tests

    ZEXDOC_TESTS=$(  grep -oP "^[\t]dw[\t]([a-z0-9]+)" CPM/zexdoc.src | cut -f3 )  # get tests from source code

    #while :; do
        setupMMgr 0x013a-0x01c1 "$REPLY" RW  # allow writing to first (and second) test data address pointer
        printf "Select tests: "
        select _T in $ZEXDOC_TESTS; do
            (( ta=0x013a ))                      # location of first test pointer
            for _R in $REPLY; do
                rw $(( 0x013a+2*(_R-1) ))     # get test pointer
                printf "Test: _R=[%s] _T=[%s] nn=[%04x]\n" "$_R" "$_T" $nn
                ww $ta $nn
                ww $(( ta+2 )) 0                 # end tests
                ta+=2                            # next test
            done
            _RUNS=0
            reset
            printf "Test: REPLY=[%s] _T=[%s]\n" "$REPLY" "$_T"
            break
        done
    #done
}

#zexdoc
#inst_dump

prelim() {
    # CP/M functions
    . pc-cpm.bash

    # prelim.com
    . pc-prelim.bash

    load 0x0100 "prelim.com"
    asm @0 LDSPnn w0x7fff JRn b1 @5 RET @6 JPnn w0x0100   # for prelim.com - 25/2/2013 passes!
    reset
}

#prelim

system80() {
    _DIS=false
    . system80-interface.bash

    load 0x0000 "system_80_rom"
    reset
}

system80

