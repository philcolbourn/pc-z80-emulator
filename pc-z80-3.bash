#!/bin/bash

#set -u  # unset variables are an error
#set -x
#set -e  # cant ise this with (())

trap_fn() { 
    printf "\nTRAP: Command error [${FUNCNAME[*]}]: [${BASH_LINENO[*]}]\n"
    _STOP=true
}


trap_int() {
    $_FAST && exit 0  # no debug in fast mode
    _SS=true
    printf "\nTRAP: <Ctrl+C pressed: enter debug mode>\n"
    dis_regs
}

trap trap_int SIGINT

trap_exit() { 
    printf "\nTRAP: Exit trapped\n"
    printf "Test: REPLY=[%s] T=[%s]\n" "$REPLY" "$_T"
    #dis_regs
    #inst_dump
    _STOP=true
}

trap trap_exit EXIT

SECONDS=1

declare -a STACK
declare -i STACKP=0
push() { STACK[STACKP++]=${!1}; return 0; }
pop() { local _V=$1; eval $_V=${STACK[--STACKP]}; return 0; }

X="test1";push X; X="test2";push X
pop X; [[ $X != "test2" ]] && exit 1
pop X; [[ $X != "test1" ]] && exit 1

# emulator registers and flags
declare -i a  b  c  d  e  f  h  l  sp pc  i r  iff1 iff2  x X y Y
declare -i a1 b1 c1 d1 e1 f1 h1 l1 
declare -i sa  sb  sc  sd  se  sf  sh  sl  ssp spc  si sr  siff1 siff2  sx sX sy sY
declare -i sa1 sb1 sc1 sd1 se1 sf1 sh1 sl1 
declare -i q t cycles states halt
declare -ia MEM MEM_READ MEM_WRITE MEM_EXEC
declare -a ACC                                   # accelerated functions
declare -a MEM_NAME MEM_RW MEM_DRIVER_R MEM_DRIVER_W MEM_DRIVER_E
declare -a OUT IN
declare -a FLAG_NAMES=( C N P X H Y Z S )
# flag masks
declare -i FS=0x80 FZ=0x40 FY=0x20 FH=0x10 FX=0x08 FP=0x04 FN=0x02 FC=0x01  
_STOP=false

# emulator globals
declare -i o  # first opcode byte
declare -i n  m   # 8 bit temporary value
declare -i nn mm  mn rr rrd  # 16 bit temporary value
declare -i af af1 bc bc1 de de1 hl hl1 ix iy  # used for holding 16bit register pair values
declare -i D  # used for +- displacements
declare -i ipc jpc opc # holds pc of current instruction - used for displaying
declare BFN  # current executing opcode function

# debugging globals
declare -a TRAP MSG

declare -i j  # global temporary integers # FIXME: might remove these globals
declare g    #global temporary other # FIXME: might remove these globals
declare -a AREA
declare B="%%02x" W="%%04x" C=" ; [%%b]" R="%%+d" # format strings for computed functions
declare -a HEX=( 0 1 2 3 4 5 6 7 8 9 a b c d e f )

# FIXME: op code register mapping - used? R is used for format strings
#declare -a R=( B C D E H L "(HL)" A )

# map emulator CPU register pair names to printed names 
declare -A RPN=( [hl]=HL [xX]=IX [yY]=IY [af]=AF [bc]=BC [de]=DE [sp]=SP [pc]=PC )

# map CPU registers to implemente emulator variables - mostly done for IX and IY
declare -A RN=( [a]=A [f]=F [0]=0 [b]=B [c]=C [d]=D [e]=E [h]=H [l]=L [x]=IXh [X]=IXl [y]=IYh [Y]=IYl )

# print message flags
_TEST=true
_DIS=false
_ASM=false
_JIT=false
_FAST=false
_ACCEL=false
_ACCEL_2=false
_ASSERT=false
_VERBOSE=false
_MEMPROT=false
_MEM_NAME=false
_ALL_FLAGS=false  # calc all flags or all but FY and FX
_STATE_LOG=false
_TRAP_CMD=false
while :; do
    case $1 in
            DIS) _DIS=true;;
            ASM) _ASM=true;;
          #  JIT) _JIT=true;   _ACCEL=true;  _ACCEL_2=false;;
           JIT2) _JIT=true;   _ACCEL=false; _ACCEL_2=true;;
           FAST) _FAST=true;  _DEBUG=false;;
          DEBUG) _FAST=false; _DEBUG=true;;
         ASSERT) _ASSERT=true;;
        VERBOSE) _VERBOSE=true;;
        MEMPROT) _MEMPROT=true;;
        MEMNAME) _MEM_NAME=true;;
       ALLFLAGS) _ALL_FLAGS=true;;
       STATELOG) _STATE_LOG=true;;
        TRAPCMD) _TRAP_CMD=true; trap trap_fn ERR;;
              *) break
    esac
    shift
done

# generate a C table. eg. make_cArray <bash array> <type>
# type=FN: array of function pointers
# type=INT: array of ints
make_cArray(){
    local _b=$1 _type=$2; local -i _j _n _c=0
    $_VERBOSE && printf "MAKE C %s TABLE...\n" $_b
    eval _n=\${#$_b[*]}  # number of elements
    eval _i=\"\${!$_b[*]}\"  # elements
    case $_type in
       VFN) printf "void (*$_b[])()={";;
        FN) printf "void (*$_b[])()={";;
       INT) printf "int $_b[]={";;
    esac
    printf "  // from $_c[%d]" $_n
    for _j in $_i; do
        eval _v=\${$_b[_j]}
        (( (_j%8)==0 )) && printf "\n    [0x%02x]=" $_j
        printf "%-10s" $_v
        #(( (++_c)<_n )) && printf ","  # to remove last ',' but C does not care
        printf ","
    done
    printf "\n};\n"
}


GEN=generated-functions.bash
LOG=state.log
cGEN=generated-functions.c

printf "# Generated functions\n" > $GEN
printf "# Execution run\n" > $LOG
printf "// C functions\n" > $cGEN

print_table() {
    local _T=$1 _v; local -i _j _r _c
    printf "\x1b[2J\x1b[1;1H%s TABLE" ${_T^^}
    for (( _j=0 ; _j<256 ; _j++ )); do
        (( _r=(_j>>4), _c=(_j&15) ))
        (( _r==0 )) && printf "\x1b[32m\x1b[%d;%dH%2x\x1b[m" 3 $((_c*3+6)) $_c  # top row
        (( _c==0 )) && printf "\x1b[32m\x1b[%d;%dH%2x\x1b[m" $((_r*1+4)) 3 $_r  # left column
        eval "_v=\"\${$_T[$_j]}\""
        #printf "\x1b[%d;%dH%2b" $((_r*1+4)) $((_c*3+6)) $_v
        #printf "%3d  %3d  [%c]\n" $((_r*1+4)) $((_c*3+6)) "$_v"  # need quotes to avoid pathname expansion
        printf "\x1b[%d;%dH%2c" $((_r*1+4)) $((_c*3+6)) "$_v"
    done
    printf "\x1b[2E"
    return 0
}

# make byte parity lookup table
declare -ia PAR
makePAR() {
    local -i _j _p
    for (( _j=0 ; _j<256 ; _j++ )); do
        (( _p=_j,
           _p=(_p&15)^(_p>>4),
           _p=(_p& 3)^(_p>>2),
           _p=(_p& 1)^(_p>>1),
           PAR[_j]=(!_p)*FP ))
    done
    return 0
}
makePAR; $_VERBOSE && print_table PAR

# record and log instruction state
state_record() {
    #(( sa=a, sf=f, sb=b, sc=c, sd=d, se=e, sh=h, sl=l, sx=x, sX=X, sy=y, sY=Y, ssp=sp ))
    #(( si=i, sr=r, siff1=iff1, siff2=iff2 ))
    #(( sa1=a1, sf1=f1, sb1=b1, sc1=c1, sd1=d1, se1=e1, sh1=h1, sl1=l1 ))
    return 0
}

state_log_diffs() {  # show changes only - good, but hard to debug
    ! $_STATE_LOG && return 0
    local _RP _Bk="\x1b[30m" _Rd="\x1b[31m" _Gn="\x1b[32m" _Yw="\x1b[33m" _Be="\x1b[34m" _Ma="\x1b[35m" _Cn="\x1b[36m" _We="\x1b[37m" _Nl="\x1b[0m"
    local -i _inst
    get_inst
    (((pc&0x000f)==0)) && printf "$_We PC : INSTRUCT OP-CODE  ($_Rd AF |$_Gn BC |$_Yw DE |$_Be HL |$_Ma IX |$_Cn IY |$_Rd AF'|$_Gn BC'|$_Yw DE'|$_Be HL'|$_We SP )\n" >> $LOG
    _RP="%02.0x%02.0x|"
    {
    printf "$_We%04x: %8x %8s ($_Rd$_RP$_Gn$_RP$_Yw$_RP$_Be$_RP$_Ma$_RP$_Cn$_RP$_Rd$_RP$_Gn$_RP$_Yw$_RP$_Be$_RP$_We%04.0x)$_Nl\n"  \
            $ipc $_inst "$BFN"                                                        \
            $((sa!=a?a:0))    $((sf!=f?f:0))    $((sb!=b?b:0))    $((sc!=c?c:0))    \
            $((sd!=d?d:0))    $((se!=e?e:0))    $((sh!=h?h:0))    $((sl!=l?l:0))    \
            $((sx!=x?x:0))    $((sX!=X?X:0))    $((sy!=y?y:0))    $((sY!=Y?Y:0))    \
            $((sa1!=a1?a1:0)) $((sf1!=f1?f1:0)) $((sb1!=b1?b1:0)) $((sc1!=c1?c1:0)) \
            $((sd1!=d1?d1:0)) $((se1!=e1?e1:0)) $((sh1!=h1?h1:0)) $((sl1!=l1?l1:0)) \
            $((ssp!=sp?sp:0));
    } >> $LOG
}

state_log() {  # just log - ignore alt reg set
    ! $_STATE_LOG && return 0
    local _RP _Bk="\x1b[30m" _Rd="\x1b[31m" _Gn="\x1b[32m" _Yw="\x1b[33m" _Be="\x1b[34m" _Ma="\x1b[35m" _Cn="\x1b[36m" _We="\x1b[37m" _Nl="\x1b[0m"
    local -i _inst
    get_inst
    (((pc&0x000f)==0)) && printf "$_We PC : INSTRUCT OP-CODE  ($_Rd AF |$_Gn BC |$_Yw DE |$_Be HL |$_Ma IX |$_Cn IY |$_We SP )\n" >> $LOG
    _RP="%02x%02x|"
    {
    printf "$_We%04x: %8x %8s ($_Rd$_RP$_Gn$_RP$_Yw$_RP$_Be$_RP$_Ma$_RP$_Cn$_RP$_We%04.0x)$_Nl\n"  \
            $ipc $_inst "$BFN"  $a $f $b $c $d $e $h $l  $x $X $y $Y  $sp;
    } >> $LOG
}

state_pause() { ! $_STATE_LOG && return 0; printf "(PAUSE: %s)\n" "$1"  >> $LOG; }
state_resume(){ ! $_STATE_LOG && return 0; printf "(RESUME: %s)\n" "$1" >> $LOG; }
state_note() { ! $_STATE_LOG && return 0; printf "(NOTE: %s)\n" "$1"  >> $LOG; }
state_resume_E(){
    #printf "$FUNCNAME: Emit RESUME at [%04x]\n" $pc
    printf "(RESUME)\n" >> $LOG
}

# nice idea, but too complex to use
state_resume_on_ret(){  # register future point to emit (RESUME) 
    ! $_STATE_LOG && return 0
    local -i _a
    rw $sp; _a=nn  # get return address
    if [[ -z ${MEM_DRIVER_E[_a]} ]]; then  # no driver registered
        printf "$FUNCNAME: Installing resume driver\n"
        setupMMgr $_a "(RESUME)" RO state_resume_E
    else
        if [[ ${MEM_NAME[_a]} =~ ^(RESUME)* ]]; then  # RESUME driver registered so ignore this
            printf "$FUNCNAME: Resume driver already installed[%s]\n" "${MEM_DRIVER_E[_a]}"
            return 0
        else  # chain RESUME driver onto existing driver
            printf "$FUNCNAME: Chaning resume driver before [${MEM_DRIVER_E[_a]}]\n"
            MEM_NAME[_a]="(RESUME); ${MEM_NAME[_a]}"  # change name to indicate RESUME driver installed
            MEM_DRIVER_E[_a]="state_resume_E; ${MEM_DRIVER_E[_a]}"
        fi
    fi
    return 0
}

# load instruction set
. instruction-set.bash

# define display colours based on RW type
declare -a MEM_COL=( [RO]=1 [RW]=2 [XX]=7 [IO]=3 [VD]=6 )

# setupMMgr <from>[<-to>] <name> <RO|RW> <driver function> # not used <color>
setupMMgr() {
    local _ADD="$1" _NAME="$2" _RW="$3" _DRIVERS="$4" _FR _TO _T _D; local -i _j
    _RW=${_RW:-RO}
    _FR=${_ADD%-*}; _TO=${_ADD#*-};
    for (( _j=$_FR; _j<=$_TO; _j++ )); do
        MEM_NAME[_j]="$_NAME"
        MEM_RW[_j]=$_RW
        for _D in $_DRIVERS; do
            _T="${_D##*_}"                         # get last 'type' character of driver name. should be W|E|R
            if [[ $_T =~ [WER] ]]; then
                $_VERBOSE && printf "$FUNCNAME: Registering %s driver %s at %04x\n" "$_T" "$_D" $_j
                eval "MEM_DRIVER_${_T}[_j]=\$_D"
            else                                 # else assume a universal driver
                $_VERBOSE && printf "$FUNCNAME: Registering generic driver %s\n" "$_D"
                MEM_DRIVER_R[_j]=$_D
                MEM_DRIVER_W[_j]=$_D
                MEM_DRIVER_E[_j]=$_D
            fi
        done
    done
    return 0
}

declare -i _RUNS=0
onerun_E() {
    (( _RUNS==1 )) && { printf "\nWarm-boot: stopping\n"; _STOP=true; }
    _RUNS+=1
    return 0
}

declare -a CHR

# make ASCII lookup table: eg. CHR[65]="A"
makeCHR() {
    local -i _j
    for (( _j=0x00 ; _j<0x100  ; _j++ )); do 
        printf -v CHR[_j] "\\\x%02x" $_j         # make hex char sequence eg. \x41
        printf -v CHR[_j] "%b" "${CHR[_j]}"      # convert to string into array
    done
}
makeCHR

$_VERBOSE && print_table CHR

# we can assume memory address is in $ta

# load system-80 ROM
#. system80-interface.bash

# turn on err trap!!!!

#time { unset c X Y; declare -i c Y; for (( c=0; c<100000; c++ )); do X="10"; Y=X; (( Y==0 )) && Y=c; done; echo 2 $Y; }  # 1
#time { unset c X Y; declare -i c Y; for (( c=0; c<100000; c++ )); do X="AB"; Y=X; (( Y==0 )) && Y=c; done; echo 1 $Y; }  # 1
#time { unset c X Y; declare -i c Y; for (( c=0; c<100000; c++ )); do X="AB"; Y=X; [[ ${X::1} =~ [0-9] ]] && Y=c; done; echo 3 $Y; }  # 2.7


#unset X; declare -ia X; for (( c=0; c<100000; c++ )); do X[c]=c; done
#time { unset c Y; declare -i c Y; for (( c=0; c<100000; c++ )); do Y=$c; done; echo 2 $Y; }  # 0.57s ok
#time { unset c Y; declare -i c Y; for (( c=0; c<100000; c++ )); do Y=c; done; echo 3 $Y; }  # 0.53s fastest
#time { unset c Y; declare -i c Y; for (( c=0; c<100000; c++ )); do (( Y=c )); done; echo 4 $Y; }  # 0.58 ok
#time { unset c Y; declare -i c Y; for (( c=0; c<100000; c++ )); do (( Y=X[c] )); done; echo 1 $Y; }  # 0.72s fastest array
#time { unset c Y; declare -i c Y; for (( c=0; c<100000; c++ )); do Y=${X[c]}; done; echo 5 $Y; }  # 0.83 ok
#time { unset c Y; declare -i c Y; for (( c=0; c<100000; c++ )); do Y=${X[$c]}; done; echo 6 $Y; }  # 1.0 slowest


#time { for (( c=0; c<1000000; c++ )); do X=0; done; }  # fastest bash loop = 5.3us
#exit 0

#time { unset __X __Y; declare -i __X __Y; for (( c=0; c<1000000; c++ )); do (( __X=1,__Y=4 )); done; }  # 6.6
#time { unset __X __Y; declare -i __X __Y; __Z="__X=1,__Y=4"; for (( c=0; c<1000000; c++ )); do (( __Z )); done; }  # 6.4
#time { unset __X __Y; declare -i __X __Y; __Z="__X=1,__Y=4"; for (( c=0; c<1000000; c++ )); do (( $__Z )); done; }  # 6.4
#time { unset __X __Y; declare -i __X __Y; for (( c=0; c<1000000; c++ )); do __X=1; __Y=4; done; }  # 6.2 fastest
#time { unset __X __Y; declare -i __X __Y; __Z="__X=1;__Y=4"; for (( c=0; c<1000000; c++ )); do $__Z; done; }  # error
#exit 0

#time { unset __X __Y; declare -i __X=0; __Y=true; for (( c=0; c<1000000; c++ )); do $Y && { __X+=1; }; done; echo $__X; }  # 6.9 fastest
#time { unset __X __Y; declare -i __X=0; __Y=true; for (( c=0; c<10000; c++ )); do $Y && ( __X+=1; ); done; echo $__X; }  # 12x100 wrong answer and Do NOT USE
#time { unset __X __Y; declare -i __X=0; __Y=true; for (( c=0; c<1000000; c++ )); do if $Y; then __X+=1; fi; done; echo $__X; }  # 6.9 fastest
#time { unset __X __Y; declare -i __X=0; __Y=true; for (( c=0; c<1000000; c++ )); do $Y && __X+=1; done; echo $__X; }  # 7.0 ok
#exit 0
#time { unset __X; declare -i __X=0; Y="__X=(__X+1)&65535"; for (( c=0; c<1000000; c++ )); do (( __X=(__X+1)&65535 )); done; echo $__X; } #7.4
#time { unset __X; declare -i __X=0; Y="__X=(__X+1)&65535"; for (( c=0; c<1000000; c++ )); do (( $Y )); done; echo $__X; } # 5.3 fastest!!

#time { unset __X; declare -i __X=0; for (( c=0 ; c<1000000 ; c++ )); do [[ $c -gt 500000 ]] && __X+=1; done; echo $__X; } # 7.0 fastest
#time { unset __X; declare -i __X=0; for (( c=0 ; c<1000000 ; c++ )); do [[ c -gt 500000  ]] && __X+=1; done; echo $__X; } # 7.0
#time { unset __X; declare -i __X=0; for (( c=0 ; c<1000000 ; c++ )); do [  $c -gt 500000  ] && __X+=1; done; echo $__X; } # 10.7 slowest
# does not work time { unset __X; declare -i __X=0; for (( c=0 ; c<1000000 ; c++ )); do [  c -gt 500000   ] && __X+=1; done; echo $__X; } # 
#time { unset __X; declare -i __X=0; for (( c=0 ; c<1000000 ; c++ )); do (( $c > 500000   )) && __X+=1; done; echo $__X; } # 7.4
#time { unset __X; declare -i __X=0; for (( c=0 ; c<1000000 ; c++ )); do (( c > 500000    )) && __X+=1; done; echo $__X; } # 7.4
 

#time { unset __X; declare -i __X __Y=2; for c in {0..1000000}; do __X=__Y*256; done; echo $__X; } # faster 3.3
# does not work time { unset __X; declare -i __X __Y=2; for c in {0..1000000}; do ( __X=__Y*256 ); done; echo $__X; } # 
#time { unset __X; declare -i __X __Y=2; for c in {0..1000000}; do (( __X=__Y*256 )); done; echo $__X; } # 4.3 
#time { unset __X; declare -i __X __Y=2; for c in {0..1000000}; do (( __X=__Y<<8 )); done; echo $__X; } # ok 4.2
#time { unset __X; declare -i __X __Y=2; for c in {0..1000000}; do let __X=__Y*256; done; echo $__X; } # deadly 30.8!!!!!
#time { unset __X; declare -i __X __Y=2; for c in {0..1000000}; do __X=__Y%256; done; echo $__X; } # 
#time { unset __X; declare -i __X __Y=2; for c in {0..1000000}; do (( __X=__Y&255 )); done; echo $__X; } #

#exit 0

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

INCaf="f+=1,(f==256)?(a=(a+1)&255,f=0):0"  # dummy for C version
INCbc="c+=1,(c==256)?(b=(b+1)&255,c=0):0"
INCde="e+=1,(e==256)?(d=(d+1)&255,e=0):0"
INChl="l+=1,(l==256)?(h=(h+1)&255,l=0):0"
INCix="X+=1,(X==256)?(x=(x+1)&255,X=0):0"
INCxX="$INCix"
INCiy="Y+=1,(Y==256)?(y=(y+1)&255,Y=0):0"
INCyY="$INCiy"

INCr="r=(r&128)|((r+1)&127)"

#INCAF="af=(af+1)&65535"  # dummmy for C version
INCBC="bc=(bc+1)&65535"
INCDE="de=(de+1)&65535"
INCHL="hl=(hl+1)&65535"
INCIX="ix=(ix+1)&65535"
INCIY="iy=(iy+1)&65535"
INCSP="sp=(sp+1)&65535"
INCPC="pc=(pc+1)&65535"

DECaf="f-=1,(f==-1)?(a=(a-1)&255,f=255):0"  # dummy for C version
DECbc="c-=1,(c==-1)?(b=(b-1)&255,c=255):0"
DECde="e-=1,(e==-1)?(d=(d-1)&255,e=255):0"
DEChl="l-=1,(l==-1)?(h=(h-1)&255,l=255):0"
DECix="X-=1,(X==-1)?(x=(x-1)&255,X=255):0"
DECxX="$DECix"
DECiy="Y-=1,(Y==-1)?(y=(y-1)&255,Y=255):0"
DECyY="$DECiy"

#DECAF="af=(af-1)&65535"  # dummy for C version
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

# value of register pairs. use: $HVL
# WARNING: don't use spaces to simplify conversion to C
HLV="\$(((h<<8)|l))"
DEV="\$(((d<<8)|e))"
BCV="\$(((b<<8)|c))"
IXV="\$(((x<<8)|X))"
IYV="\$(((y<<8)|Y))"

# value of register pairs for C - may not get used
cHLV="(h<<8)|l"
cDEV="(d<<8)|e"
cBCV="(b<<8)|c"
cIXV="(x<<8)|X"
cIYV="(y<<8)|Y"

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
    local _inst _PRE; local -i _j
    n=MEM[ipc]                                   # possible prefix
    _PRE="${PREFIX[n]} "
    n=MEM[ipc+1]                                 # actual instruction
    for (( _j=0 ; _j<6; _j++ )); do _inst+="${MEM[pc-1+_j]} "; done
    printf "ERROR: $FUNCNAME: Unknown %s operation code [%x %x %x %x %x %x] at %4x(%5d)\n" "$_PRE" $_inst $ipc
    _STOP=true
}
acc_XX() {
    local _inst _PRE; local -i _j
    n=MEM[ipc]                                   # possible prefix
    _PRE="${PREFIX[n]} "
    n=MEM[ipc+1]                                 # actual instruction
    for (( _j=-2 ; _j<6; _j++ )); do _inst+="${MEM[pc-1+_j]} "; done
    printf "ERROR: $FUNCNAME: Unknown %s operation code [%x %x %x %x %x %x] at %4x(%5d)\n" "$_PRE" $_inst $ipc
    _STOP=true
}

STOP() {
    printf "\nSTOP: Stop emulator at %4x\n" $((pc-1))
    #dis_regs
    _STOP=true
    return 0
}

# write byte to port -ports are mapped to files on demand unless mapped in OUT array
wp() {
    local -i _p=$1 _v=$2
    [[ -z ${OUT[_p]} ]] && { OUT[_p]=$_p.out; $_DIS && printf "WARNING: $FUNCNAME: Output port $_p mapped to [%s]\n" ${OUT[_p]}; }
    printf "%c" ${CHR[_v]} >> ${OUT[_p]}
    return 0
}

rp() {
    local -i _p=$1
    [[ -z ${IN[_p]} ]] && { IN[_p]=/dev/zero; $_DIS && printf "WARNING: $FUNCNAME: Input port $_p mapped to [%s]\n" ${IN[_p]}; }
    read -N1 n < ${IN[_p]}
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
    local _var=$1; local -i _val=$2
    printf "_var=%s  _val=%d\n" "$_var" $_val
    if [ ${!_var} -eq $_val ]; then
        printf "PASS: $FUNCNAME: %s = %x(%d)\n" $_var $_val $_val
        return 0
    fi
    printf "ERROR: LINE [${BASH_LINENO[0]}] [${FUNCNAME[*]}]: %s != %x(%d); %s = %x(%d)\n" $_var $_val $_val $_var ${!_var} ${!_var}
    _STOP=true
    #exit 1
}

# MEMORY MANAGEMENT

memname() {
    ! $_DIS && return 0                          # do nothing if not disassembling
    local -i _a=$1; local _name
    _j=${#AREA[*]}                                # get number of area names collected so far for this instruction
    _name="${MEM_NAME[_a]}"                       # get name
    AREA[_j]="$_name/${MEM_READ[_a]:-0}r/${MEM_WRITE[_a]:-0}w"  # record and add read/write counts
    return 0
}

ansi_nl()        {                    printf "\x1b[${1}E";        return 0; }
ansi_clearRight(){                    printf "\x1b[0K";           return 0; }
ansi_clearLeft() {                    printf "\x1b[1K";           return 0; }
ansi_clearLine() {                    printf "\x1b[2K";           return 0; }
ansi_c()         { local _c=$1;       printf "\x1b[${_c}G";       return 0; }
ansi_pos()       { local _r=$1 _c=$2; printf "\x1b[${_r};${_c}H"; return 0; }
ansi_savecp()    {                    printf "\x1b[s";            return 0; }
ansi_restorecp() {                    printf "\x1b[u";            return 0; }
#ansi_getcp()     { local _CP=$( printf "\x1b[6n" ); _CP=${_CP:2: -1}; _ANSI_R=${_CP%;*}; _ANSI_C=${_CP#*;}; return 0; }
#ansi_col()       { local _COL=$1;     printf "\x1b[%dm" $_COL;    return 0; }

dis_regs() {
    local _flags _rp; local -i _rr _nn _h _l _j _ss _sh _sl
    printf "REGISTERS  (a negative in unsigned column means JIT replaced instruction)\n"
    #printf "\x1b[s"  # save cursor
    #ansi_nl; ansi_c 65; 
    get_FLAGS; _flags="$RET"
    printf "RP=%4s (%4s) %5s|%-6s %3s|%-4s %3s|%-4s [%16s]\n" HHLL MMMM UU SS U S u s "16B from MEM[RP]"
    printf "AF=%04x (%02x=%1s) %16d|%-+4d %8s\n" $(( $AF )) $a "${CHR[a]}" $a $(( a>127?a-256:a )) "$_flags"
    #rw $de; printf "\nDE:%04x [%04x]" $(( $DE )) $nn
    for _rp in BC DE HL IX IY SP PC; do
        _rr=$(( ${!_rp} ))
        (( _nn=MEM[_rr]|(MEM[(_rr+1)&65535]<<8) ))
        (( _h=_nn>>8, _l=_nn&255, _ss=_nn>0x7fff?_nn-65536:_nn, _sh=_h>127?_h-256:_h, _sl=_l>127?_l-256:_l ))
        if (( _nn<0 )); then
            printf "$_rp=%04x (----) %5d|%-+6d %3d|%-+4d %3d|%-+4d [" $_rr      $_nn $_ss $_h $_sh $_l $_sl
        else
            printf "$_rp=%04x (%04x) %5d|%-+6d %3d|%-+4d %3d|%-+4d [" $_rr $_nn $_nn $_ss $_h $_sh $_l $_sl
        fi
        for (( _j=0; _j<16; _j++ )); do
            if (( MEM[(_rr+_j)&65535]>=0 )); then
                printf "%c" "${CHR[MEM[(_rr+_j)&65535]]}"
            else
                printf "-"
            fi
        done
        printf "]\n"
    done
    printf "\n"
    #printf "\nPC:%04x  SP:%04x" $pc $sp; ansi_col ${MEM_COL[sp]}; printf " [%s]" "${MEM_NAME[sp]}"; ansi_col 0
    #printf "\n[%8s]" "$flags"
    #printf "\x1b[u"  # restore cursor
    return 0
}

if $_FAST; then

#memread() { local -i _a=$1;       local _DRIVER="${MEM_DRIVER_R[_a]}"; [[ -n $_DRIVER ]] && eval "$_DRIVER $_a"; return 0; }
##memexec() { local -i _a=$1;       local _DRIVER="${MEM_DRIVER_E[_a]}"; [[ -n $_DRIVER ]] && eval "$_DRIVER $_a"; return 0; }
#memprot() { local -i _a=$1 _b=$2; local _DRIVER="${MEM_DRIVER_W[_a]}"; [[ -n $_DRIVER ]] && eval "$_DRIVER $_a $_b"; return 0; }

memread() { local -i _a=$1;       local _DRIVER=${MEM_DRIVER_R[_a]}; [[ -n $_DRIVER ]] && eval $_DRIVER $_a; return 0; }
#memexec() { local -i _a=$1;       local _DRIVER=${MEM_DRIVER_E[_a]}; [[ -n $_DRIVER ]] && eval $_DRIVER $_a; return 0; }
memprot() { local -i _a=$1 _b=$2; local _DRIVER=${MEM_DRIVER_W[_a]}; [[ -n $_DRIVER ]] && eval $_DRIVER $_a $_b; return 0; }

else

# trap read from memory and set memory value before actual read
memread() {
    local -i _a=$1; local _flags _RW _DRIVER=${MEM_DRIVER_R[_a]}
    $_ASSERT && assert_w _a
    (( MEM_READ[_a]++ ))
    _RW=${MEM_RW[_a]}
    case $_RW in
        RW) ;;
        RO) ;;
        "") printf "MEMREAD: [${FUNCNAME[*]}]\nAttempted read from unassigned %04x before PC=%04x\n" $_a $pc; _STOP=true;; 
    esac
    #! $_DIS && {
        #printf "\x1b[1;65H PC:%04x  SP:%04x  \x1b[%dm%s\x1b[0m" $pc $sp ${MEM_COL[RW]} ${MEM[ta]}
        #printf "\x1b[2;65H IX:%04x  IY:%04x" $(( (x<<8)|X )) $(( (y<<8)|Y )) 
        #printf "\x1b[3;65H AF:%04x  BC:%04x" $(( (a<<8)|f )) $(( (b<<8)|c ))
        #printf "\x1b[4;65H DE:%04x  HL:%04x" $(( (d<<8)|e )) $(( (h<<8)|l ))
        #get_FLAGS; flags="$RET"
        #printf "\x1b[5;65H F:%8s" "$flags"
    #}
    [[ -n $_DRIVER ]] && eval $_DRIVER $_a
    return 0
}

memexec() {
    local -i _a=$1; local _flags _RW _DRIVER=${MEM_DRIVER_E[_a]}
    $_ASSERT && assert_w _a
    (( MEM_EXEC[_a]++ ))
    _RW=${MEM_RW[_a]}
    case $_RW in
        RW) ;;
        RO) ;;
        "") printf "MEMEXEC: [${FUNCNAME[*]}]\nAttempted read from unassigned before PC=%04x\n" $_a; _STOP=true;; 
    esac
    #[[ -n $_DRIVER ]] && { push _DIS; push _SS; eval $_DRIVER $_a; pop _SS; pop _DIS; } 
    [[ -n $_DRIVER ]] && eval $_DRIVER $_a 
    return 0
}


# FIXME: IO may be RO WO or IO where a write followed by a read will get different values or reading produces different values
# hack to trap write to memory
memprot() {
    local -i _a=$1 _b=$2 _n _row _col; local _RW _DRIVER=${MEM_DRIVER_W[_a]}
    $_ASSERT && assert_w _a
    #$_ASSERT && assert_b _b  # _b can be byte or word
    (( MEM_WRITE[_a]++ ))
    _RW=${MEM_RW[_a]}
    case $_RW in
        RO) printf "MEMPROT: [${FUNCNAME[*]}]\nAttempted write to write protected %04x[%02x] before PC=%04x\n" $_a ${MEM[_a]} $pc; _STOP=true;; 
        "") printf "MEMPROT: [${FUNCNAME[*]}]\nAttempted write to unassigned %04x before PC=%04x\n" $_a "${MEM[_a]}" $pc; _STOP=true;; 
    esac
    [[ -n $_DRIVER ]] && eval $_DRIVER $_a $_b
    return 0
}

fi

_A1="(_a+1)&65535"  # macro to return ta+1 withing address space

ARGS=""  # ACC args list

if $_ASSERT; then
    # eg. assertb varname value - don't use $var
    assert_b() {
        #return 0  # FIXME: disabled for accel testing
        ! $_DIS && return 0
        local _var=$1
        [[ ${!_var} -lt 0    ]] && { printf "ERROR: [${FUNCNAME[*]}]: %s < 0;    %s = %02x(%d)\n" $_var $_var ${!_var} ${!_var}; _STOP=true; }
        [[ ${!_var} -gt 0xff ]] && { printf "ERROR: [${FUNCNAME[*]}]: %s > 0xff; %s = %02x(%d)\n" $_var $_var ${!_var} ${!_var}; _STOP=true; }
        return 0
    }

    assert_w() {
        #return 0  # FIXME: disabled for accel testing
        ! $_DIS && return 0
        local _var=$1
        [[ ${!_var} -lt 0      ]] && { printf "ERROR: [${FUNCNAME[*]}]: %s < 0;      %s = %02x(%d)\n" $_var $_var ${!_var} ${!_var}; _STOP=true; }
        [[ ${!_var} -gt 0xffff ]] && { printf "ERROR: [${FUNCNAME[*]}]: %s > 0xffff; %s = %02x(%d)\n" $_var $_var ${!_var} ${!_var}; _STOP=true; }
        return 0
    }

    $_MEM_NAME && _NAME="memname \$_a;"
    $_MEM_READ && { _READ="memread \$_a;"; _READPC="memread \$pc;"; _READSP="memread \$so;"; }
    $_MEM_PROT && { _PROTB="memread \$_a \$_b;"; _PROTW="memprot \$_a \$_w;"; _PROTL="memprot \$_a \$_l;"
                    _PROTSPB="memprot \$sp \$_b;"; _PROTSPW="memprot \$sp \$_w;"; _PROTSPPC="memprot \$sp \$pc;"; }
    $_ASSERT && { _ASSB="assert_b n;"; _ASSW="assert_b nn;"; }
    # read b or w from given address
    {
    printf "rb()      { local -i _a=\$1;               $_NAME $_READ      n=MEM[_a];                   $_ASSB              return 0; }\n"
    printf "rw()      { local -i _a=\$1;               $_NAME $_READ  (( nn=MEM[_a]|(MEM[$_A1]<<8) )); $_ASSW             return 0; }\n"
    printf "rb2()     { local -i _a=\$1;               $_NAME $_READ      n=MEM[_a]; m=MEM[$_A1];      $_ASSB assert_b m;  return 0; }\n"
    printf "wb()      { local -i _a=\$1 _b=\$2;        $_NAME $_PROTB    MEM[_a]=_b;                         return 0; }\n"
    printf "ww()      { local -i _a=\$1 _w=\$2;        $_NAME $_PROTW (( MEM[_a]=_w&255, MEM[$_A1]=_w>>8 )); return 0; }\n"
    printf "wb2()     { local -i _a=\$1 _l=\$2 _h=\$3; $_NAME $_PROTL (( MEM[_a]=_l, MEM[$_A1]=_h ));        return 0; }\n"
    # read b or w from (pc) - we currently assume RAM or ROM and therefore no drivers are required
    #printf "ro()      { memexec $pc; o=MEM[pc]; (( $INCPC )); assert_b o;                                                  opc=pc; return 0; }\n"
    printf "rn()      { $_READPC n=MEM[pc]; (( $INCPC )); assert_b n;                                   ARGS+="n=\$n;"; opc=pc; return 0; }\n"
    printf "rD()      { $_READPC D=MEM[pc]; (( $INCPC )); assert_b D;                      (( $RELD )); ARGS+="D=\$D;"; opc=pc; return 0; }\n"
    printf "rm()      { $_READPC m=MEM[pc]; (( $INCPC )); assert_b m;                                   ARGS+="m=\$m;"; opc=pc; return 0; }\n"
    # FIXME: BASH BUG: a pc=pc+1 - like statement after an array read crashed bash - except in second case???
    printf "rnn()     { $_READPC nn=MEM[pc]; (( $INCPC, nn=(MEM[pc]<<8)|nn, $INCPC )); assert_w nn; ARGS+="nn=\$nn;"; opc=pc; return 0; }\n"
    printf "rmm()     { $_READPC mm=MEM[pc]; (( $INCPC, mm=(MEM[pc]<<8)|mm, $INCPC )); assert_w mm; ARGS+="mm=\$mm;"; opc=pc; return 0; }\n"
    printf "pushb()   { local -i _b=\$1; $_PROTSPB  (( $DECSP, MEM[sp]=_b ));                                  return 0; }\n"
    printf "pushw()   { local -i _w=\$1; $_PROTSPW  (( $DECSP, MEM[sp]=_w>>8, $DECSP, MEM[sp]=_w&255 ));        return 0; }\n"
    printf "pushpcnn(){                  $_PROTSPPC (( $DECSP, MEM[sp]=pc>>8, $DECSP, MEM[sp]=pc&255, pc=nn )); return 0; }\n"
    printf "popn()    {                  $_READSP            n=MEM[sp];    (( $INCSP ));                             assert_b n;  return 0; }\n"
    printf "popnn()   {                  $_READSP           nn=MEM[sp];    (( $INCSP, nn=(MEM[sp]<<8)|nn, $INCSP )); assert_w nn; return 0; }\n"
    printf "popmn()   {                  $_READSP            n=MEM[sp];    (( $INCSP )); m=MEM[sp]; (( $INCSP )); assert_b m; assert_b n; return 0; }\n"
    printf "poppc()   {                  $_READSP           pc=MEM[sp];    (( $INCSP, pc=(MEM[sp]<<8)|pc, $INCSP )); assert_w pc; return 0; }\n"
    printf "popm()    {                  $_READSP            m=MEM[sp];    (( $INCSP ));                             assert_b m;  return 0; }\n"
    printf "popmm()   {                  $_READSP           mm=MEM[sp];    (( $INCSP, mm=(MEM[sp]<<8)|mm, $INCSP )); assert_w mm; return 0; }\n"
    } >> $GEN
elif $_MEMPROT; then

    # removed asserts
    rb()      { local -i _a=$1;             memread $_a;              n=MEM[_a];                            return 0; }
    rw()      { local -i _a=$1;             memread $_a;          (( nn=MEM[_a]|(MEM[$_A1]<<8) ));          return 0; }
    rb2()     { local -i _a=$1;             memread $_a;              n=MEM[_a]; m=MEM[$_A1];               return 0; }
    wb()      { local -i _a=$1 _b=$2;       memprot $_a $_b;            MEM[_a]=_b;                         return 0; }
    ww()      { local -i _a=$1 _w=$2;       memprot $_a $_w;         (( MEM[_a]=_w&255, MEM[$_A1]=_w>>8 )); return 0; }
    wb2()     { local -i _a=$1 _l=$2 _h=$3; memprot $_a $_l;         (( MEM[_a]=_l, MEM[$_A1]=_h ));        return 0; }
    #ro()      {                       memexec $pc;              o=MEM[pc];    (( $INCPC ));                                              opc=pc; return 0; }
    rn()      {                       memread $pc;              n=MEM[pc];    (( $INCPC ));                             ARGS+="n=$n;";   opc=pc; return 0; }
    rD()      {                       memread $pc;              D=MEM[pc];    (( $INCPC ));                (( $RELD )); ARGS+="D=$D;";   opc=pc; return 0; }
    rm()      {                       memread $pc;              m=MEM[pc];    (( $INCPC ));                             ARGS+="m=$m;";   opc=pc; return 0; }
    rnn()     {                       memread $pc;             nn=MEM[pc];    (( $INCPC, nn=(MEM[pc]<<8)|nn, $INCPC )); ARGS+="nn=$nn;"; opc=pc; return 0; }
    rmm()     {                       memread $pc;             mm=MEM[pc];    (( $INCPC, mm=(MEM[pc]<<8)|mm, $INCPC )); ARGS+="mm=$mm;"; opc=pc; return 0; }
    pushb()   { local -i _b=$1; (( $DECSP )); memprot $sp $_b;    MEM[sp]=_b;                                           return 0; }
    pushw()   { local -i _w=$1; (( $DECSP )); memprot $sp $_w; (( MEM[sp]=_w>>8, $DECSP,     MEM[sp]=_w&255 ));         return 0; }
    pushpcnn(){                 (( $DECSP )); memprot $sp $pc; (( MEM[sp]=pc>>8, $DECSP,     MEM[sp]=pc&255, pc=nn ));  return 0; }
    popn()    {                       memread $sp;              n=MEM[sp];    (( $INCSP ));                             return 0; }
    popnn()   {                       memread $sp;             nn=MEM[sp];    (( $INCSP, nn=(MEM[sp]<<8)|nn, $INCSP )); return 0; }
    popmn()   {                       memread $sp;              n=MEM[sp];    (( $INCSP )); m=MEM[sp]; (( $INCSP )); return 0; }
    poppc()   {                       memread $sp;             pc=MEM[sp];    (( $INCSP, pc=(MEM[sp]<<8)|pc, $INCSP )); return 0; }
    popm()    {                       memread $sp;              m=MEM[sp];    (( $INCSP ));                             return 0; }
    popmm()   {                       memread $sp;             mm=MEM[sp];    (( $INCSP, mm=(MEM[sp]<<8)|mm, $INCSP )); return 0; }

elif $_FAST; then  # remove wrap around checks and only run memread when getting opcode on pc

    rb()      { local -i _a=$1;              memread $_a;      n=MEM[_a];                   return 0; }
    rw()      { local -i _a=$1;              memread $_a;  (( nn=MEM[_a]|(MEM[$_A1]<<8) )); return 0; }
    rb2()     { local -i _a=$1;              memread $_a;      n=MEM[_a]; m=MEM[$_A1];      return 0; }
    wb()      { local -i _a=$1 _b=$2;        memprot $_a $_b;    MEM[_a]=_b;                         return 0; }
    ww()      { local -i _a=$1 _w=$2;        memprot $_a $_w; (( MEM[_a]=_w&255, MEM[$_A1]=_w>>8 )); return 0; }
    wb2()     { local -i _a=$1 _l=$2 _h=$3;  memprot $_a $_l; (( MEM[_a]=_l, MEM[$_A1]=_h )); return 0; }
    #ro()      {                       memexec $pc;  o=MEM[pc++];                                    opc=pc; return 0; }  # read MEM[pc] AFTER memexec call
    rn()      {                                     n=MEM[pc++];                   ARGS+="n=$n;";   opc=pc; return 0; }
    rD()      {                                     D=MEM[pc++];      (( $RELD )); ARGS+="D=$D;";   opc=pc; return 0; }
    rm()      {                                     m=MEM[pc++];                   ARGS+="m=$m;";   opc=pc; return 0; }
    rnn()     {                                 (( nn=MEM[pc++]|(MEM[pc++]<<8) )); ARGS+="nn=$nn;"; opc=pc; return 0; }
    rmm()     {                                 (( mm=MEM[pc++]|(MEM[pc++]<<8) )); ARGS+="mm=$mm;"; opc=pc; return 0; }
    pushb()   { local -i _b=$1;                       MEM[--sp]=_b;                                return 0; }
    pushw()   { local -i _w=$1;                    (( MEM[--sp]=_w>>8, MEM[--sp]=_w&255 ));        return 0; }
    pushpcnn(){                                    (( MEM[--sp]=pc>>8, MEM[--sp]=pc&255, pc=nn )); return 0; }
    popn()    {                                     n=MEM[sp++];                   return 0; }
    popnn()   {                                 (( nn=MEM[sp++]|(MEM[sp++]<<8) )); return 0; }
    popmn()   {                                     n=MEM[sp++]; m=MEM[sp++];      return 0; }
    poppc()   {                                 (( pc=MEM[sp++]|(MEM[sp++]<<8) )); return 0; }
    popm()    {                                     m=MEM[sp++];                   return 0; }
    popmm()   {                                 (( mm=MEM[sp++]|(MEM[sp++]<<8) )); return 0; }

else

    # removed mem read and write protection
    # need to trap some reads and writes to make drivers
    rb()      { local -i _a=$1;             memread $_a;      n=MEM[_a];                   return 0; }
    rw()      { local -i _a=$1;             memread $_a;  (( nn=MEM[_a]|(MEM[$_A1]<<8) )); return 0; }
    rb2()     { local -i _a=$1;             memread $_a;      n=MEM[_a]; m=MEM[$_A1];      return 0; }
    wb()      { local -i _a=$1 _b=$2;       memprot $_a $_b;    MEM[_a]=_b;                         return 0; }
    ww()      { local -i _a=$1 _w=$2;       memprot $_a $_w; (( MEM[_a]=_w&255, MEM[$_A1]=_w>>8 )); return 0; }
    wb2()     { local -i _a=$1 _l=$2 _h=$3; memprot $_a $_l; (( MEM[_a]=_l, MEM[$_A1]=_h ));        return 0; }
    #ro()      {                       memexec $pc;      o=MEM[pc];    (( $INCPC ));                                             opc=pc; return 0; }
    rn()      {                       memread $pc;      n=MEM[pc];    (( $INCPC ));                             ARGS+="n=$n;";   opc=pc; return 0; }
    rD()      {                       memread $pc;      D=MEM[pc];    (( $INCPC ));                (( $RELD )); ARGS+="D=$D;";   opc=pc; return 0; }
    rm()      {                       memread $pc;      m=MEM[pc];    (( $INCPC ));                             ARGS+="m=$m;";   opc=pc; return 0; }
    rnn()     {                       memread $pc;     nn=MEM[pc];    (( $INCPC, nn=(MEM[pc]<<8)|nn, $INCPC )); ARGS+="nn=$nn;"; opc=pc; return 0; }
    rmm()     {                       memread $pc;     mm=MEM[pc];    (( $INCPC, mm=(MEM[pc]<<8)|mm, $INCPC )); ARGS+="mm=$mm;"; opc=pc; return 0; }
    pushb()   { local -i _b=$1;                (( $DECSP, MEM[sp]=_b ));                                   return 0; }
    pushw()   { local -i _w=$1;                (( $DECSP, MEM[sp]=_w>>8, $DECSP, MEM[sp]=_w&255 ));        return 0; }
    pushpcnn(){                                (( $DECSP, MEM[sp]=pc>>8, $DECSP, MEM[sp]=pc&255, pc=nn )); return 0; }
    popn()    {                                         n=MEM[sp];    (( $INCSP ));                             return 0; }
    popnn()   {                                        nn=MEM[sp];    (( $INCSP, nn=(MEM[sp]<<8)|nn, $INCSP )); return 0; }
    popmn()   {                                         n=MEM[sp];    (( $INCSP )); m=MEM[sp]; (( $INCSP )); return 0; }
    poppc()   {                                        pc=MEM[sp];    (( $INCSP, pc=(MEM[sp]<<8)|pc, $INCSP )); return 0; }
    popm()    {                                         m=MEM[sp];    (( $INCSP ));                             return 0; }
    popmm()   {                                        mm=MEM[sp];    (( $INCSP, mm=(MEM[sp]<<8)|mm, $INCSP )); return 0; }

fi

# load assembler
. pc-z80-assembler.bash

mem_make_readable() {
    local -i _j
    for _j in ${!MEM[*]}; do                      # set loaded memory to RO
        #printf "Mark [%04x] [%02x]\n" $_j ${MEM[_j]}
        [[ ${MEM_RW[_j]} = "" ]] && MEM_RW[_j]="RO"
    done
    return 0
}

dump() {
    printf "DUMP PROGRAMMED MEMORY...\n"
    local -i _j
    for _j in ${!MEM[*]}; do printf "%04x  %2s %02x %d\n" $_j "${MEM_RW[_j]}" ${MEM[_j]} ${MEM[_j]}; done
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

#WARNING: INC_IS requires $o be set to instruction

INC_IS="INST[o]++"
INC_CB="INST[0xcb00|m]++"
INC_DDCB="INST[0xddcb00|m]++"
INC_FD="INST[0xfd00|m]++"
INC_FDCB="INST[0xfdcb00|m]++"
INC_ED="INST[0xed00|m]++"
INC_DD="INST[0xdd00|m]++"

inst_dump() {
    local -i _m; local _g
    for _m in ${!INST[*]}; do
        if   (( _m<=0x1ff ));    then _g="${IS[_m]}"  # allow special op codes
        elif (( _m<=0xcbff ));   then _g="${CB[_m&255]}"
        elif (( _m<=0xddff ));   then _g="${DD[_m&255]}"
        elif (( _m<=0xedff ));   then _g="${ED[_m&255]}"
        elif (( _m<=0xfdff ));   then _g="${FD[_m&255]}"
        elif (( _m<=0xddcbff )); then _g="${DDCB[_m&255]}"
        elif (( _m<=0xfdcbff )); then _g="${FDCB[_m&255]}"
        else                          _g="?????"
        fi
        printf "%9d %6x %8s %d\n" $_m $_m "$_g" ${INST[_m]}
    done | sort -n -r -k4 | cat
}

if $_FAST && ! $_JIT2; then
    # NOTE: only first byte of opcode is treated as opcode for MMgr exec traps
    MAPcb(){ eval ${CB[MEM[pc++]]};}
    MAPddcb(){ D=MEM[pc++];(($RELD));eval ${DDCB[MEM[pc++]]};}
    MAPfdcb(){ D=MEM[pc++];(($RELD));eval ${FDCB[MEM[pc++]]};}
    MAPed(){ eval ${ED[MEM[pc++]]};}
    MAPdd(){ eval ${DD[MEM[pc++]]};}
    MAPfd(){ eval ${FD[MEM[pc++]]};}
elif $_FAST; then
    #execute() { local _DRIVER="${MEM_DRIVER_E[pc]}"; [[ -n $_DRIVER ]] && eval $_DRIVER $pc; o=MEM[pc++]; opc=pc; (( $INC_IS )); BFN="${IS[o]}"; eval $BFN; }
    #execute() { local _DRIVER="${MEM_DRIVER_E[pc]}"; [[ -n $_DRIVER ]] && eval $_DRIVER $pc; o=MEM[pc++]; opc=pc;                BFN="${IS[o]}"; eval $BFN; }
    # NOTE: only first byte of opcode is treated as opcode for MMgr exec traps
    MAPcb()   {                           m=MEM[pc++]; opc=pc; BFN="${CB[m]}";   eval $BFN; }
    MAPddcb() { D=MEM[pc++]; (( $RELD )); m=MEM[pc++]; opc=pc; BFN="${DDCB[m]}"; eval $BFN; }
    MAPfdcb() { D=MEM[pc++]; (( $RELD )); m=MEM[pc++]; opc=pc; BFN="${FDCB[m]}"; eval $BFN; }
    MAPed()   {                           m=MEM[pc++]; opc=pc; BFN="${ED[m]}";   eval $BFN; }
    MAPdd()   {                           m=MEM[pc++]; opc=pc; BFN="${DD[m]}";   eval $BFN; }
    MAPfd()   {                           m=MEM[pc++]; opc=pc; BFN="${FD[m]}";   eval $BFN; }
else
    #execute() {     ro; (( $INCr, $INC_IS ));                         BFN="${IS[o]}";   eval $BFN || exit 1; (( cycles+=q, states+=t )); return 0; }

    # add extra machine cycle and states here
    MAPcb()   {     rm; (( $INCr, $INC_CB,   cycles+=1, states+=4 )); BFN="${CB[m]}";   eval $BFN || exit 1;                             return 0; }
    # read IX offset here. r not increased. extra cycle/states for CB and D
    MAPddcb() { rD; rm; ((        $INC_DDCB, cycles+=2, states+=8 )); BFN="${DDCB[m]}"; eval $BFN || exit 1;                             return 0; }
    MAPfdcb() { rD; rm; ((        $INC_FDCB, cycles+=2, states+=8 )); BFN="${FDCB[m]}"; eval $BFN || exit 1;                             return 0; }

    MAPed()   {     rm; (( $INCr, $INC_ED,   cycles+=1, states+=4 )); BFN="${ED[m]}";   eval $BFN || exit 1;                             return 0; }
    # stray DD and FD increase r too
    MAPdd()   {     rm; (( $INCr, $INC_DD,   cycles+=1, states+=4 )); BFN="${DD[m]}";   eval $BFN || exit 1;                             return 0; }
    MAPfd()   {     rm; (( $INCr, $INC_FD,   cycles+=1, states+=4 )); BFN="${FD[m]}";   eval $BFN || exit 1;                             return 0; }
fi

load() {
    local -i _address=$1; local _filename="$2"
    $_VERBOSE && printf "LOADING $_filename...\n"
    if (( _address>0 )); then
        MEM=( [_address-1]=0 $( od -vAn -tu1 -w16 "$_filename" ) )
    else
        MEM=( $( od -vAn -tu1 -w16 "$_filename" ) )
    fi
      #MEM=( $( od -vAn -tu1 -w16 system_80_rom ) ) # load ROM
      #MEM=( [ta-1]=0 $( od -vAn -tu1 -w16 CPM/zexdoc.com ) ) # load ROM
      #MEM=( [ta-1]=0 $( od -vAn -tu1 -w16 prelim.com ) ) # load ROM
      #dump
    mem_make_readable
    return 0
}

get_FLAGS() {
    local _r; local -i _j
    for (( _j=7; _j>=0; _j-- )); do
        (( f&(1<<_j) )) && _r+=${FLAG_NAMES[_j]} || _r+="."
    done
    RET="$_r"
    return 0
}

# L="o i l z s g a b c d e f"; for a in $L; do for b in $L; do for c in $L; do for d in $L; do grep "^$a$b$c$d$" /usr/share/dict/words; done; done; done; done

get_inst(){
    local -i _j  # updates caller's _inst
    # we mask with 255 to filter JIT'd and special instructions
    #case $(( pc-ipc )) in
    case $(( opc-ipc )) in
        1) (( _inst= (MEM[ipc]&255) ));;
        2) (( _inst=((MEM[ipc]&255)<<8)  |  (MEM[ipc+1]&255) ));;
        3) (( _inst=((MEM[ipc]&255)<<16) | ((MEM[ipc+1]&255)<<8)  |  (MEM[ipc+2]&255) ));;
        4) (( _inst=((MEM[ipc]&255)<<24) | ((MEM[ipc+1]&255)<<16) | ((MEM[ipc+2]&255)<<8) | (MEM[ipc+3]&255) ));;
        *) _inst=0xb10b0000+ipc  # assume a driver skipped instructions
           #for (( _j=ipc; _j<opc; _j++ )); do
           #    (( _inst=(_inst<<8)|(MEM[_j]&255) ))
           #done
    esac
    return 0
}

if $_FAST; then

dis() {
    $_DIS || return 0
    local _op=$1 _format="$2" _flags _args; local -i _j _inst=0
    get_FLAGS; _flags="$RET"
    get_inst
    shift 2
    printf -v _args "$_format" "$@"
    printf "%6d %8s %04x %8x %-5s %-30s\n" $states "$_flags" $ipc $_inst $_op "$_args"
    return 0
}

dnn() {
    $_DIS || return 0
    dis "$@"
}

else

dis() {
#    jpc=pc                                       # save pc before jump or call
    $_DIS || return 0
    local _op=$1 _format="$2" _flags _args _name; local -i _inst
    _name="${MEM_NAME[ipc]}"; [[ -n "$_name" ]] && printf "%s:\n" "$_name" 
    get_FLAGS; _flags="$RET"
    get_inst
    shift 2
    _format="${_format/\(/${AREA[0]}{}"  # name memory - 2 should be enough
    _format="${_format/\(/${AREA[1]}{}"
    _format="${_format//{/(}"
    printf -v _args "$_format" "$@"
    printf "%6d %8s %04x %8x %-5s %-30s; %d kHz [%s:%d]\n" $states "$_flags" $ipc $_inst $_op "$_args" $(( states/SECONDS/1000 )) "${BASH_SOURCE[1]}" ${BASH_LINENO[0]}
    unset "AREA"
    return 0
}

# special case for OP "format" nn. eg. JP "" 0x1234
dnn() {
    #jpc=pc                                       # save pc before jump or call
    $_DIS || return 0
    local _op=$1 _format="$2" _flags _args _name; local -i _inst _jump_pc=$3
    _name="${MEM_NAME[ipc]}"; [[ -n "$_name" ]] && printf "%s:\n" "$_name" 
    get_FLAGS; _flags="$RET"
    get_inst
    shift 2
    _name="${MEM_NAME[_jump_pc]}"
    if [[ -z "$_name" ]]; then 
        printf -v _args "$_format" "$@"
    else
        printf -v _args "$_format:%s" "$@" "$_name"
    fi
    printf "%6d %8s %04x %8x %-5s %-30s; %d kHz [%s:%d]\n" $states "$_flags" $ipc $_inst $_op "$_args" $(( states/SECONDS/1000 )) "${BASH_SOURCE[1]}" ${BASH_LINENO[0]}
    unset "AREA"
    return 0
}

fi

_SS=false

inline_debugger(){
    local _step=true _KEY
    while $_step; do
        _step=false
        printf "PC=[%04x] [cdlqrsx]?>" $pc
        read -N1 _KEY
        printf "_KEY=[%s]\n" "$_KEY"
        case $_KEY in
            c) _SS=false;;                       # contunue
            d) printf " Dump address?> "
               read ta; dump20                   # FIXME: ta????
               _step=true;;                      # dump memory
            l) _SS=false; _pc=ipc;;              # stop loop here WARNING: caller's _pc
            q) _STOP=true;;
            r) dis_regs; _step=true;;            # show regs
            s) printf "\x1b[1G";;                # step
            x) _SS=false; popnn; _pc=nn; pushw $nn;;  # run until return FIXME: assuming TOS is return address!!
          # R) ;;                                # restart and return here
            *) _SS=true; _step=true;
        esac
    done
    return 0
}


#declare -i fast_decode norm_decode
#declare _DRV=true
decode_single(){
    local -i _apc=-1; local _DRIVER
    while (( pc!=_apc )); do 
        _apc=pc
        _DRIVER=${MEM_DRIVER_E[pc]}
        [[ -n $_DRIVER ]] && eval $_DRIVER $pc
    done
    #printf "$FUNCNAME: done drivers\n"
    eval ${IS[MEM[pc++]]}
    return 0
}

decode() {
    local -i _pc=-1 _apc; local _redo _DRIVER _fn _BFN
    $_DIS && printf "%6s %8s %4s %8s %-36s; %s\n" STATES FLAGS ADDR HEX INSTRUCTION RATE
    if $_FAST && ! $_JIT2; then  # special case for runs - fastest when test harness is totally replaces with bash
        while ! $_STOP; do 
            #_DRIVER=${MEM_DRIVER_E[pc]}
            #[[ -n $_DRIVER ]] && eval $_DRIVER $pc  # assume only 1 driver
            [[ pc -eq 0x1d42 ]] && iut_E $pc
            eval ${IS[MEM[pc++]]}
        done
    elif $_FAST; then
        while ! $_STOP; do 
            _apc=pc
            _DRIVER="${MEM_DRIVER_E[pc]}"
            [[ -n $_DRIVER ]] && {               # run driver and reprocess possibly new pc
                #printf "DRIVER=%s\n" $_DRIVER
                eval $_DRIVER $pc
                (( pc!=_apc )) && continue
            }
            ipc=pc                               # save PC for this instruction for display
            o=MEM[pc++]
            opc=pc                               # track instruction length (length=opc-ipc, next inst starts at MEM[opc])
            if (( o>=0 )); then                  # normal opcode
                ARGS=""                          # clear to collect args for this instruction
                BFN="${IS[o]}"                    # updates opc
                eval $BFN
                state_log
                # NOTE: if opcode is modified, this will automatically switch to normal mode since opcode will be >=0
                # FIXME: WARNING: if operand is modified, we will never know
                if $_JIT; then
                    #[[ ${MEM_RW[ipc]:2:1} = "S" ]] && { printf "\x1b[GJIT: %04x bypassed\n" $ipc; continue; }  # not self-modifying code target result
                    [[ ${MEM_RW[ipc]:2:1} = "S" ]] && continue  # not self-modifying code target result
                    _DRIVER="${MEM_DRIVER_E[ipc]}"  # get driver for this instruction
                    _BFN="acc_$BFN"  # inline string name
                    if [[ -n $_DRIVER ]]; then   # run driver and reprocess possibly new pc
                        # jit: run driver, if pc not changed, run jit instruction
                        # WARNING: needs a space after {
                        $_STATE_LOG && ACC[ipc]="$_DRIVER \$pc; ((pc==$ipc)) && { ipc=$ipc; pc=opc=$opc; $ARGS ${!_BFN} BFN=$BFN; state_log; }" \
                                    || ACC[ipc]="$_DRIVER \$pc; ((pc==$ipc)) && { pc=$opc; $ARGS ${!_BFN} }"
                    else                         # no driver, jit: run jit instruction
                        $_STATE_LOG && ACC[ipc]="ipc=pc; pc=opc=$opc; $ARGS ${!_BFN} BFN=$BFN; state_log" \
                                    || ACC[ipc]="pc=$opc; $ARGS ${!_BFN}"
                    fi
                    MEM[ipc]=o-256              # so we can get back original, 256 so NOP is also negative
                    #printf "\x1b[Ginline %s=[%s]\n" $BFN "${!_BFN}"
                    #printf "\x1b[GJIT: ACC[%04x %5d]  %s = %s\n" $ipc $ipc "$_BFN" "${ACC[ipc]}"
                fi
            else  # switch modes to execute JIT'd instructions until we find a non-JIT'd one
                pc=ipc
                eval "${ACC[pc]}"                  # must use eval here
                while ! $_STOP && [[ -n ${ACC[pc]} ]]; do  # stop if no more jit
                    eval "${ACC[pc]}"              # run jit'd driver and instruction
                done
            fi
        done
    else
        # new scheme required: if driver found, run it and loop if pc unchanged else execute instruction.
        #printf "<$FUNCNAME>"
        #printf "<_STOP=%s>" $_STOP
            #execute() {     ro; (( $INCr, $INC_IS ));                         BFN="${IS[o]}";   eval $BFN || exit 1; (( cycles+=q, states+=t )); return 0; }

        while ! $_STOP; do
            _apc=pc
            _DRIVER="${MEM_DRIVER_E[pc]}"
            [[ -n $_DRIVER ]] && {               # run driver and reprocess possibly new pc
                eval $_DRIVER $pc
                (( pc!=_apc )) && continue
            }
            #printf "B:  %04x  %5d\n" $pc $pc
            ipc=pc                               # save PC for this instruction for display
            o=MEM[pc++]
            opc=pc
            #printf "A:  %04x  %5d\n" $ipc $ipc
            if (( o>=0 )); then                  # normal opcode
                norm_decode+=1
                #state_record
                (( $INCr, $INC_IS ))
                ARGS=""
                BFN="${IS[o]}"                   # this may change during eval
                eval $BFN || exit 1              # run and 'monitor' instruction - collect operands and final pc(opc)
                state_log
                $_JIT && {                       # jit can be dynamically controlled!
                    #[[ ${MEM_RW[ipc]:2:1} = "S" ]] && { printf "\x1b[GJIT: %04x bypassed\n" $ipc; continue; }  # not self-modifying code target result
                    [[ ${MEM_RW[ipc]:2:1} = "S" ]] && continue  # not self-modifying code target result
                    # NOTE: if opcode is modified, this will automatically switch to normal mode since opcode will be >=0
                    # FIXME: WARNING: if operand is modified, we will never know
                    _DRIVER="${MEM_DRIVER_E[ipc]}"  # get driver for this instruction
                    if [[ -n $_DRIVER ]]; then   # run driver and reprocess possibly new pc
                        # jit: run driver, if pc not changed, run jit instruction
                        #printf "ACC[%04x %5d]  %s\n" $ipc $ipc "${ACC[ipc]}"
                        #ACC[ipc]="$_DRIVER $ipc; ((pc==$ipc)) && { ipc=$ipc; pc=$opc; $ARGS acc_$BFN; BFN=$BFN; opc=$opc; state_log; }"  
                        ACC[ipc]="$_DRIVER \$pc; ((pc==$ipc)) && { ipc=$ipc; pc=opc=$opc; $ARGS acc_$BFN; BFN=$BFN; state_log; }"  
                    else                         # no driver
                        #ACC[ipc]="ipc=$ipc; pc=$opc; $ARGS acc_$BFN; BFN=$BFN; opc=$opc; state_log;"  # jit: run jit instruction
                        ACC[ipc]="ipc=pc; pc=opc=$opc; $ARGS acc_$BFN; BFN=$BFN; state_log"  # jit: run jit instruction
                    fi
                    MEM[ipc]=o-256              # so we can get back original, 256 so NOP is also negative
                    #printf "\x1b[GJIT: ACC[%04x %5d]  %s\n" $ipc $ipc "${ACC[ipc]}"
                }
            else
                fast_decode+=1
                #printf "%04x  %5d  %s\n" $ipc $ipc "${ACC[ipc]}"
                #state_record
                pc=ipc                           # set pc
                eval "${ACC[pc]}"                # must use eval here
                while ! $_STOP && [[ -n ${ACC[pc]} ]]; do  # stop if no more jit
                    #printf "%04x  %5d  %s\n" $pc $pc "${ACC[pc]}"
                    #state_record
                    eval "${ACC[pc]}"            # run jit'd driver and instruction
                done
            fi
            # look for interrupts
            # FIXME: except after EI!!! [SC05]
            [[ -n ${TNMI[states]} ]] && NMI;        # NMI 
            #(( iff==1 )) && [[ -n ${TINT[states]} ]] && INT ${TINT[states]};  # INT n 

            # start/restart inline debugger
            (( pc==_pc )) && { _SS=true; _pc=-1; }
            # inline debugger
            $_SS && inline_debugger
        done
    fi
    return 0
}

# flag spec language: see comments
makesetf(){
    local _name=$1 _spec="$2" _flag _flags _PV; local -i _j _mask _fMask=0 _rMask=0 _RMask=0 _sMask=0 _aMask=0 _xMask=0 _f0=0
    printf "setf$_name() { local -i n1=\$1 n2=\$2 re=\$3; (( f="
    if ! $_ALL_FLAGS; then
        # 01234567
        # SZYHXPNC
        #printf "Flag [%s] -> " "$_spec" 1>&2
        _spec="${_spec:0:2}X${_spec:3:1}X${_spec:5}"  # mask undocumented flags
        #printf "[%s]\n" $_spec 1>&2
    fi
    for (( _j=0; _j<8; _j++ )); do
        (( _mask=(1<<(7-_j)) ))
        _flag=${_spec:_j:1}
        case $_flag in
            .) _fMask+=_mask;;                   #/  # no change - keep existing flag value
            r) _rMask+=_mask;;                   #/  # take value from result
            R) _RMask+=_mask;;                   #/  # take value from high byte of result
            s) _sMask+=_mask;;                   #/  # take value from n2
            a) _aMask+=_mask;;                     # take value from register A
            0) ;;                                #/  # set flag value to 0
            1) (( _f0+=_mask ));;                #/  # set flag value to 1
            p) _flags+="+PAR[re]";;            #/  # lookup parity
            I) _flags+="+iff1";;                # LD A,I
          x|X) _xMask+=_mask;;                   #/  # 'randomise' these flags
          z|Z) _flags+="+(re==0?$_mask:0)";;     #/  # rarely a different bit works same as FZ. eg BIT and FP
            !) _flags+="+(f&$_mask)^$_mask";;  #/  # invert flag
           ^|v) case $_mask in                   # flag specific cases
                   $FS) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                   $FZ) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                   $FY) case $_name in
                            LDI*|LDD*) _flags+="+(((n2+re)&FN)<<4)";;
                          # CPI*|CPD*) _flags+="+(((re-(((n1^n2^re)&FH)>>4)))&0x01)";;
                                    *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                        esac;;
                   $FH) case $_name in
                    ADD|ADC|SUB|SBC|CP) _flags+="+( (n1^n2^re)    &FH)";;
                                 ADD16) _flags+="+(((n1^n2^re)>>8)&FH)";;
                           ADC16|SBC16) _flags+="+(((n1^n2^re)>>8)&FH)";;
                               INC|DEC) _flags+="+( (n1^re)       &FH)";;
                                   NEG) _flags+="+( (n2^re)       &FH)";;
                             CPI*|CPD*) _flags+="+( (n1^n2^re)    &FH)";;
                                     *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                        esac;;
                   $FX) case $_name in
                            LDI*|LDD*) _flags+="+((n2+re)&FX)";;
                          # CPI*|CPD*) _flags+="+((re-(((n1^n2^re)&FH)>>4))&FX)";;
                                    *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                        esac;;
                   $FP) case $_name in
                                   ADD|ADC) _flags+="+(((n1^~n2)&(n1^re)&0x80)>>5)";;
                                SUB|SBC|CP) _flags+="+(((n1^ n2)&(n1^re)&0x80)>>5)";;
                                       NEG) _flags+="+(n2==0x80?FP:0)";;
                                       INC) _flags+="+(n1==0x7f?FP:0)";;
                                       DEC) _flags+="+(n1==0x80?FP:0)";;
                               ADD16|ADC16) _flags+="+(((n1^~n2)&(n1^re)&0x8000)>>13)";;
                               SUB16|SBC16) _flags+="+(((n1^ n2)&(n1^re)&0x8000)>>13)";;
                       LDI*|LDD*|CPI*|CPD*) _flags+="+((b+c)>0?FP:0)";;
                                         *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                        esac;;
                   $FN) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                   $FC) case $_name in
                            ADD) _flags+="+(((n1+n2)       >> 8)   )";;
                            ADC) _flags+="+(((n1+n2+(f&FC))>> 8)   )";;
                     SUB|CP|NEG) _flags+="+(((n1-n2)       >> 8)&FC)";;
                            SBC) _flags+="+(((n1-n2-(f&FC))>> 8)&FC)";;
                          ADD16) _flags+="+(((n1+n2)       >>16)&FC)";;
                          ADC16) _flags+="+(((n1+n2+(f&FC))>>16)   )";;
                          SBC16) _flags+="+(((n1-n2-(f&FC))>>16)&FC)";;
                              *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                        esac;;
                 # $FC) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
               esac;;
            *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
        esac
    done
    (( _f0>0      )) && printf "+0x%02x"           $_f0
    (( _fMask>0   )) && printf "+(f&0x%02x)"       $_fMask
    (( _sMask>0   )) && printf "+(n2&0x%02x)"      $_sMask
    (( _rMask>0   )) && printf "+(re&0x%02x)"      $_rMask
    (( _RMask>0   )) && printf "+((re>>8)&0x%02x)" $_RMask
    (( _aMask>0   )) && printf "+(a&0x%02x)"       $_aMask
#    (( _xMask>0   )) && ! $_FAST && printf "+(r&0x%02x)" $_xMask  # randomize based on r
#    (( _xMask>0   )) && printf "+(r&0x%02x)"      $_xMask  # randomize based on r
    [[ -n $_flags ]] && printf "%s"               "$_flags"
    printf " )); return 0; }  # _spec=%s  _f0=%x  f&%x n2&%x re&%x a&%x r&%x\n" "$_spec" $_f0 $_fMask $_sMask $_rMask $_aMask $_xMark
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
makesetf ADD16 "..R^R.0^"
makesetf ADC16 "RZR^Rv0^"
makesetf SBC16 "RZR^Rv1^"  # was "^Z^^^v0-"
makesetf ADD   "rZr^rv0^"   # ADD=ADC
makesetf ADC   "rZr^rv0^"
makesetf SUB   "rZr^rv1^"   # SUB=SBC=NEG
makesetf SBC   "rZr^rv1^"
makesetf NEG   "rZr^rv1^"
makesetf CP    "rZs^sv1^"   # CP != SUB
makesetf INC   "rZr^rv0."
makesetf DEC   "rZr^rv1."
makesetf AND   "rZr1rp00"   # FIXME:
makesetf XOR   "rZr0rp00"   # XOR=OR
makesetf OR    "rZr0rp00"
makesetf ROTa  "..r0r.0s"
makesetf ROTr  "rZr0rp0s"
makesetf RLD   "rZr0rp0."
makesetf CCF   "..asa.0!"
makesetf SCF   "..a0a.01"
makesetf CPL   "..r1r.1."
makesetf BIT   "rZr1rp0."
makesetf BITx  "rZs1sp0."  # more correct version
makesetf BITh  "rZs1sp0."  # [SY05] don't know where FY or FX come from - assume h parsed as n2
# changed Z -> p
#makesetf BITh  "rZs1sZ0."  # [SY05] don't know where FY or FX come from - assume h parsed as n2
makesetf DAA   "rZrsrp.s"
makesetf LDI   "..^0^^0."  # BC=0 -> FP=0 else FP=1
makesetf LDIR  "..^0^00." 
makesetf CPI   "rZ^^^^1."
#makesetf CPIR  "rZ^^^01."
} >> $GEN

#printf "n1=$n1 re=$re f0=$(( re&0xa8 )) fz=$(( (re==0)*FZ )) fp=$(( ((~n1&re)>127)*FP )) fh=$(( ((n1&15)==15)*FH )) -> f=$f\n"; 

# make LDrr_yz() functions
# FIXME: prefixed instructions at at least 1 M1 cycle and 4 states. IX+d add another 2 cycles and 4 states for d and another 4 for good measure (add?)

# generate functions

# make accelerated versions of fast functions by prefixing function name with <acc_> and removing rn, rnn, rm, rmm, and rD calls

# NOTES: there are only 2 instruction function files: pc-generate-debug.bash and pc-generate-fast.bash
# fast versions were made manually by removing display (dis) calls and optimising resulting code
# accel version was made automatically from fast version by find & replace - NO LONGER MAINTAINED
# accel-2 version was made from fast version by sed - automatically maintained!
# accel-inline version are made automatically from accel version
# accel-2-inline version are made automatically from accel-2 version
# to change an inline version, modify fast version only. any change can be also copied manually into debug version.

sed -re 's/printf[ ]+"([^#])/printf "acc_\1/g' pc-generate-fast.bash \
    -e 's/r(n|nn|m|mm|D|nm);[ ]?//g'                                 \
    > pc-generate-accel-2.bash
    
# mgdiff -args -b pc-generate-accel.bash pc-generate-accel-2.bash  # compare to orginial
    
# make inline version by converting 
# * deleting line comments like [printf "# SP instructions - timing checked\n"]
# * converting [printf "acc_LDSPnn() {               sp=nn; return 0; }  # from $0.$LINENO\n"] into [printf "acc_LDSPnn='sp=nn;'\n"]

# this is ugly but it save re-writing a new set of instructions for inline use.
    
# * remove lines that generate comment lines like <printf "#...>
# * replace function definition <() {> with <='>
# * remove function close and trailing comments <}; # from...> -> <'\n">
# * remove function <return 0;>
# * remove multiple spaces
# * remove leading space
# * remove trailing space
sed -e 's/^printf "#.*$//g' pc-generate-accel-2.bash \
    -e 's/[(][)][ ]*{[ ]*/\='\''/g'                  \
    -e 's/[ ]*}[; ]*# from .*$/'\''\\n"/g'           \
    -e 's/return 0;[ ]*//g'                          \
    -re 's/[ ]+/ /g'                                 \
    -e 's/^[ ]//g'                                   \
    -e 's/[ ]$//g'                                   \
    > pc-generate-accel-2-inline.bash

# make a version with no 'return 0; '
sed -r pc-generate-fast.bash  \
    -e 's/return 0;[ ]?//g'  \
    -e 's/\{[ ]*\}/{ return 0; }/g'  \
    -e 's/[ ]+/ /g'  \
    -e 's/^[ ]//g'                                   \
    -e 's/[ ]$//g'                                   \
    > pc-generate-fast-noret.bash

# instruction set functions require normal, accel and if JIT'd accel inline strings.
# debug (manual) -> fast -> (manual) -> accel   -> accel-inline  # NOTE: this line is now too buggy and unmaintained
#                        -> (auto)   -> accel-2 -> accel-2-inline

$_DEBUG    && . pc-generate-debug.bash
$_FAST     && { $_TRAP_CMD && . pc-generate-fast.bash || . pc-generate-fast-noret.bash; }
$_ACCEL_2  && { . pc-generate-accel-2.bash; . pc-generate-accel-2-inline.bash; }

# load manufactured functions
. $GEN

# make c version
{
make_cArray PAR INT
# FIXME: is [ ]*[;]? same as [ ;]*?
sed -r generated-functions.bash \
    -e 's/[ ]+;/;/g'  \
    -e 's/dis[^;]+;//g'  \
    -e 's/^setf([^() ]+)[(][)][^;]+;/void setf\1(int n1, int n2, int re){ /g'  \
    -e 's/^([^#]+[(][)])/void \1/g'  \
    -e 's/return[ ]+0[ ]*;[ ]?//g'  \
    -e 's/while[ ]+([^;]+)[;][ ]+do/while \1{/g'  \
    -e  's/done[ ]*[;]?/}/g'  \
    -e 's/[;][ ]+then/{/g'  \
    -e  's/fi[ ]*[;]?/}/g'  \
    -e 's/[ ;]*\#(.*)$/;  \/\* \1 \*\//g'  \
    -e 's/[ ]r(D|n|m|nn|mm)[ ]*[;]?/r\1();/g'  \
    -e      's/pop([^() ;]+)[ ]*[;]?/pop\1();/g'  \
    -e          's/pushpcnn[ ]*[;]?/pushpcnn();/g'  \
    -e     's/push([^() ]+)[ ]+([^ ;]+)[ ]*[;]?/push\1(\2);/g'  \
    -e     's/setf([^() ]+)[ ]+([^ ]+)[ ]+([^ ]+)[ ]+([^ ;]+)[ ]*[;]?/setf\1(\2,\3,\4);/g' \
    -e               's/wb2[ ]+([^ ]+)[ ]+([^ ]+)[ ]+([^ ;]+)[ ]*[;]?/wb2(\1,\2,\3);/g' \
    -e                's/wb[ ]+([^ ]+)[ ]+([^ ;]+)[ ]*[;]?/wb(\1,\2);/g' \
    -e                's/ww[ ]+([^ ]+)[ ]+([^ ;]+)[ ]*[;]?/ww(\1,\2);/g' \
    -e                's/wp[ ]+([^ ]+)[ ]+([^ ;]+)[ ]*[;]?/wp(\1,\2);/g' \
    -e                's/rb[ ]+([^ ;]+)[ ]*[;]?/rb(\1);/g'  \
    -e               's/rb2[ ]+([^ ;]+)[ ]*[;]?/rb2(\1);/g'  \
    -e                's/rw[ ]+([^ ;]+)[ ]*[;]?/rw(\1);/g'  \
    -e                's/rp[ ]+([^ ;]+)[ ]*[;]?/rp(\1);/g'  \
    -e 's/local[ ]+-i/<local>int/g'  \
    -e 's/[$]//g'  \
    -e ':loop' \
        -e 's/<local>int ([^ ;]+)[ ]+/<local>int \1,/g' \
    -e 't loop' \
    -e 's/<local>int/int/g'  \
    -e 's/([^ ;])[ ]*$/\1;/g'
#    >> $cGEN

#() { local -i n1=$1 n2=$2 re=$3;

make_cArray IS FN
make_cArray CB FN
make_cArray DD FN
make_cArray DDCB FN
make_cArray ED FN
make_cArray FD FN
make_cArray FDCB FN

} >> $cGEN

# exit 1

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
COMP_REGS="f a   b c   d e   h l   x X   y Y         sp   pc              a1 f1   b1 c1   d1 e1   h1 l1"  # im?
test_save_state() {
    local _store=$1 _reg
    for _reg in $SAVE_REGS; do
        eval SAVE$_store[$_reg]=${!_reg}  # save register
    done
    return 0
}

test_load_state() {
    local _store=$1 _reg
    for _reg in $SAVE_REGS; do
        eval "(( $_reg=SAVE$_store[$_reg] ))"  # load register
    done
    return 0
}

test_comp_state() {
    local _store=$1 _reg _diff=false; local -i _this _prev
    for _reg in $COMP_REGS; do
        eval "(( _prev=SAVE$_store[$_reg] ))"  # previous register value
        _this=${!_reg}
        (( _reg != "r" && _this != _prev )) && { diff=true; printf "Reg [$_reg] was [%04x] now [%04x]\n" $_prev $_this; }
    done
    $_diff && { printf "FAIL: States are different\n"; return 1; } || { printf "PASS: Register values identical\n"; return 0; }
}

test_save_state 0
test_comp_state 0

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
    f=0x00  # FIXME: how to allow this to be random????????
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
    dis_regs
    printf "nn=%04x\n" $nn
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
    dis_regs
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
    asm $* STOP
    test_setup "$init" "$res" "$flg" $*; mask=$RET
    test_run $mask
    return 0
}

# test that a set on instructions does not change CPU state
test_cycle() {
    local _vars="$1" _res="$2" _flg="$3" _VAR; local -i _mask _VAL
    shift 3
    for _VAR in $_vars; do
        for _VAL in $TEST_PATTERNS; do
            printf "Test: %s=[%x]\n" $_VAR $_VAL
            $_TEST && printf "Assemble code\n"
            asm $* STOP   # put in loop for dynamic instructions
            test_setup "$_VAR=$_VAL" "$_VAR=$_VAL $_res" "$_flg" $*; _mask=$RET  # setup with dynamic variable. expect var not to change unless specified
            #dump
            test_run $_mask
        done
    done
    return 0
}

tests() {
    # test_inst <initial reg values> <expect reg values> <expect flags> <instructions>
    # test_cycle <register to cycle> <expected reg values> <expected flags> <instructions>
    # we can use any so-called printf macros here as well as use bash variables
    # WARNING: no spaces allowed in (())
    # simple expressions without bash special characters (like &, |) can be entered directly, else enclose in (())

    test_cycle "b c h l" "(($HL,$BC,nn=hl-bc-(f&FC),hl=nn&65535,$SEThl))" "XH NN XP ((f|=((hl>>8)&FS)|(hl==0)*FZ|(nn<0)*FC))"      @0 SBCHLBC
    test_cycle "d e h l" "(($HL,$DE,nn=hl-de-(f&FC),hl=nn&65535,$SEThl))" "XH NN XP ((f|=((hl>>8)&FS)|(hl==0)*FZ|(nn<0)*FC))"      @0 SBCHLDE
    test_cycle "h l"     "(($HL,$HL,nn=hl-hl-(f&FC),hl=nn&65535,$SEThl))" "XH NN XP ((f|=((hl>>8)&FS)|(hl==0)*FZ|(nn<0)*FC))"      @0 SBCHLHL
    test_cycle "h l"     "(($HL,$SP,nn=hl-sp-(f&FC),hl=nn&65535,$SEThl))" "XH NN XP ((f|=((hl>>8)&FS)|(hl==0)*FZ|(nn<0)*FC))"      @0 SBCHLSP

    test_cycle "b c h l" "(($HL,$BC,nn=hl+bc,hl=nn&65535,$SEThl))" "XH NN ((f|=(nn>0xffff)*FC))"      @0 ADDHLBC
    test_cycle "d e h l" "(($HL,$DE,nn=hl+de,hl=nn&65535,$SEThl))" "XH NN ((f|=(nn>0xffff)*FC))"      @0 ADDHLDE
    test_cycle "h l"     "(($HL,$HL,nn=hl+hl,hl=nn&65535,$SEThl))" "XH NN ((f|=(nn>0xffff)*FC))"      @0 ADDHLHL
    test_cycle "h l"     "(($HL,$SP,nn=hl+sp,hl=nn&65535,$SEThl))" "XH NN ((f|=(nn>0xffff)*FC))"      @0 ADDHLSP

    test_cycle "b c x X" "(($IX,$BC,nn=ix+bc,ix=nn&65535,$SETix))" "XH NN ((f|=(nn>0xffff)*FC))"      @0 ADDIXBC
    test_cycle "d e x X" "(($IX,$DE,nn=ix+de,ix=nn&65535,$SETix))" "XH NN ((f|=(nn>0xffff)*FC))"      @0 ADDIXDE
    test_cycle "x X"     "(($IX,$IX,nn=ix+ix,ix=nn&65535,$SETix))" "XH NN ((f|=(nn>0xffff)*FC))"      @0 ADDIXIX
    test_cycle "x X"     "(($IX,$SP,nn=ix+sp,ix=nn&65535,$SETix))" "XH NN ((f|=(nn>0xffff)*FC))"      @0 ADDIXSP

    test_cycle "b c h l" "(($HL,$BC,nn=hl+bc+(f&FC),hl=(nn&65535),$SEThl))" "XH NN XP ((f|=((hl>>8)&FS)|(hl==0)*FZ|(nn>0xffff)*FC))"      @0 ADCHLBC
    test_cycle "d e h l" "(($HL,$DE,nn=hl+de+(f&FC),hl=(nn&65535),$SEThl))" "XH NN XP ((f|=((hl>>8)&FS)|(hl==0)*FZ|(nn>0xffff)*FC))"      @0 ADCHLDE
    test_cycle "h l"     "(($HL,$HL,nn=hl+hl+(f&FC),hl=(nn&65535),$SEThl))" "XH NN XP ((f|=((hl>>8)&FS)|(hl==0)*FZ|(nn>0xffff)*FC))"      @0 ADCHLHL
    test_cycle "h l"     "(($HL,$SP,nn=hl+sp+(f&FC),hl=(nn&65535),$SEThl))" "XH NN XP ((f|=((hl>>8)&FS)|(hl==0)*FZ|(nn>0xffff)*FC))"      @0 ADCHLSP

    test_cycle "d e h l" "(($HL,$DE,hl=(hl+de)&65535,$SEThl))" "XH NN ((f|=(hl<de)*FC))"      @0 ADDHLDE
    test_inst  "hl=0x7fff (($SEThl)) de=1 (($SETde))"        "h=0x80 l=0x00" "XH NN NC"       @0 LDHLnn w0x7fff LDDEnn w0x0001 ADDHLDE
    test_inst  "" "h=0x80 l=0x00 d=0x00 e=0x01" "XH NN NC"  @0 NOP NOP NOP JRn b-21 @0xfff0 CALLnn w0xff00 HALT @0xff00 LDHLnn w0x7fff LDDEnn w0x0001 ADDHLDE

    test_cycle a ""               "H N" @0 CPL CPL
    test_cycle a "((a=(~a)&255))" "H N" @0 CPL
    test_inst "" "" @0 CALLnn w4 STOP RET
    test_cycle a "((a=(~a+1)&255))" "((f|=(a&FS)|(a==0)*FZ|(VAL==128)*FP|(VAL!=0)*FC)) XH N"                     @0 NEG
    test_cycle a ""                 "((f|=(a&FS)|(a==0)*FZ|(((0-VAL)&255)==128)*FP|(((0-VAL)&255)!=0)*FC)) XH N" @0 NEG NEG
    test_cycle  "a b c d e h l"  ""  ""  @0 PUSHBC LDBCnn w0 POPBC PUSHDE LDDEnn w0 POPDE PUSHHL LDHLnn w0 POPHL PUSHAF LDrn_a b0 POPAF
    #exit 0
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

# test debug and fast versions
#. pc-generate-fast.bash
#tests
#. pc-generate-debug.bash
#tests

tests_dev() {
    local -i _n _m
    # more tests that I am working on

    test_cycle "a" "((n=a&a,a=n))" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) H NN NC"      @0 ANDr_a
    test_cycle "b" "((n=a&b,a=n))" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) H NN NC"      @0 ANDr_b
    test_cycle "c" "((n=a&c,a=n))" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) H NN NC"      @0 ANDr_c
    test_cycle "d" "((n=a&d,a=n))" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) H NN NC"      @0 ANDr_d
    test_cycle "e" "((n=a&e,a=n))" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) H NN NC"      @0 ANDr_e
    test_cycle "h" "((n=a&h,a=n))" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) H NN NC"      @0 ANDr_h
    test_cycle "l" "((n=a&l,a=n))" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) H NN NC"      @0 ANDr_l

    exit 1
    test_cycle "a"   "((n=a-a-(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SBCr_a
    test_cycle "b" "((n=a-b-(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SBCr_b
    test_cycle "c" "((n=a-c-(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SBCr_c
    test_cycle "d" "((n=a-d-(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SBCr_d
    test_cycle "e" "((n=a-e-(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SBCr_e
    test_cycle "h" "((n=a-h-(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SBCr_h
    test_cycle "l" "((n=a-l-(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SBCr_l

    exit 1

    test_cycle "a"   "((n=a-a,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SUBr_a
    test_cycle "b" "((n=a-b,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SUBr_b
    test_cycle "c" "((n=a-c,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SUBr_c
    test_cycle "d" "((n=a-d,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SUBr_d
    test_cycle "e" "((n=a-e,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SUBr_e
    test_cycle "h" "((n=a-h,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SUBr_h
    test_cycle "l" "((n=a-l,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SUBr_l

    exit 1


    test_cycle "a"   "((n=a+a,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC)) XH XP NN"      @0 ADDr_a
    test_cycle "b" "((n=a+b,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC)) XH XP NN"      @0 ADDr_b
    test_cycle "c" "((n=a+c,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC)) XH XP NN"      @0 ADDr_c
    test_cycle "d" "((n=a+d,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC)) XH XP NN"      @0 ADDr_d
    test_cycle "e" "((n=a+e,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC)) XH XP NN"      @0 ADDr_e
    test_cycle "h" "((n=a+h,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC)) XH XP NN"      @0 ADDr_h
    test_cycle "l" "((n=a+l,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC)) XH XP NN"      @0 ADDr_l

    exit 1
    test_cycle "a"   "((n=a+1,a=n&255))" "((f|=(a&FS)|(a==0)*FZ)) XH XP NN"      @0 INCr_a
    test_cycle "b"   "((n=b+1,b=n&255))" "((f|=(b&FS)|(b==0)*FZ)) XH XP NN"      @0 INCr_b
    test_cycle "c"   "((n=c+1,c=n&255))" "((f|=(c&FS)|(c==0)*FZ)) XH XP NN"      @0 INCr_c
    test_cycle "d"   "((n=d+1,d=n&255))" "((f|=(d&FS)|(d==0)*FZ)) XH XP NN"      @0 INCr_d
    test_cycle "e"   "((n=e+1,e=n&255))" "((f|=(e&FS)|(e==0)*FZ)) XH XP NN"      @0 INCr_e
    test_cycle "h"   "((n=h+1,h=n&255))" "((f|=(h&FS)|(h==0)*FZ)) XH XP NN"      @0 INCr_h
    test_cycle "l"   "((n=l+1,l=n&255))" "((f|=(l&FS)|(l==0)*FZ)) XH XP NN"      @0 INCr_l

    exit 1

    test_cycle "a"   "((n=a-1,a=n&255))" "((f|=(a&FS)|(a==0)*FZ)) XH XP N XC"      @0 DECr_a
    test_cycle "b"   "((n=b-1,b=n&255))" "((f|=(b&FS)|(b==0)*FZ)) XH XP N XC"      @0 DECr_b
    test_cycle "c"   "((n=c-1,c=n&255))" "((f|=(c&FS)|(c==0)*FZ)) XH XP N XC"      @0 DECr_c
    test_cycle "d"   "((n=d-1,d=n&255))" "((f|=(d&FS)|(d==0)*FZ)) XH XP N XC"      @0 DECr_d
    test_cycle "e"   "((n=e-1,e=n&255))" "((f|=(e&FS)|(e==0)*FZ)) XH XP N XC"      @0 DECr_e
    test_cycle "h"   "((n=h-1,h=n&255))" "((f|=(h&FS)|(h==0)*FZ)) XH XP N XC"      @0 DECr_h
    test_cycle "l"   "((n=l-1,l=n&255))" "((f|=(l&FS)|(l==0)*FZ)) XH XP N XC"      @0 DECr_l

    exit 1
    test_cycle "a"   "((n=a+a+(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC)) XH XP NN"      @0 ADCr_a
    test_cycle "b" "((n=a+b+(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC)) XH XP NN"      @0 ADCr_b
    test_cycle "c" "((n=a+c+(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC)) XH XP NN"      @0 ADCr_c
    test_cycle "d" "((n=a+d+(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC)) XH XP NN"      @0 ADCr_d
    test_cycle "e" "((n=a+e+(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC)) XH XP NN"      @0 ADCr_e
    test_cycle "h" "((n=a+h+(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC)) XH XP NN"      @0 ADCr_h
    test_cycle "l" "((n=a+l+(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC)) XH XP NN"      @0 ADCr_l

    exit 1

    for _n in {99..0}; do
        for (( _m=0; _m<99-_n; _m++ )); do
            test_inst "((a=((_n/10)<<4)+(_n%10))) ((b=((_m/10)<<4)+(_m%10)))" "((a=(((_n+_m)/10)<<4)+((_n+_m)%10)))" "IGNORE" @0 ADDr_b DAA
        done    
    done    
    exit 0
    setupMMgr 0x0101 "BIT" RW
    for _n in {0..7}; do
        #test_cycle a "" "((f|=(((a&(1<<$_n))==0)*FZ))) XS H XP NN" @0 LDmmA w0x0101 PUSHIX LDIXnn w0x0100 BIT${_n}IXm D1 LDrIXm_a b1 POPIX 
        # write a to (HL), test bit _n, if set, reset it else set it.
        test_cycle a "((a^=1<<$_n))"                  "XZ XS H XP NN" @0 LDmmA w0x0101 PUSHIX LDIXnn w0x0100 :IF BIT${_n}IXm D1 JRNZn b6 :THEN SET${_n}IXm D1 JRn b4 :ELSE RES${_n}IXm D1 :FI LDrIXm_a b1 POPIX 
    done
    #test_cycle "a b" "((c=(a==b)?2:1))" "((n=(a-b)&255,f|=(n&FS)|(n==0)*FZ|(n>a)*FC)) XP XH N" @0 CPr_b JPZnn w0x0100 LDrn_c b1 HALT @0x0100 LDrn_c b2
    return 0
}

# test
#tests_dev
#exit 0

schedule_tests(){
    local -i _a; local _TESTS="$1" _R
    (( _a=0x013a ))                      # location of first test pointer
    for _R in $_TESTS; do
        rw $(( 0x013a+2*(_R-1) ))     # get test pointer
        printf "Schedule: _R=[%s] _TESTS=[%s] nn=[%04x]\n" "$_R" "$_TESTS" $nn
        ww $_a $nn
        ww $(( _a+2 )) 0                 # end tests
        _a+=2                            # next test
    done
    _RUNS=0
    reset
    return 0
}

zexdoc() {
    local -i _a; local _TESTS="$1" ZEXDOC_TESTS
    ZEXDOC_TESTS=$(  grep -oP "^[\t]dw[\t]([a-z0-9]+)" CPM/zexdoc.src | cut -f3 )  # get tests from source code
    . pc-cpm.bash     # CP/M functions
    . pc-zexdoc.bash  # prelim.com

    load 0x100 "CPM/zexdoc.com"
    # MEM[0x3840]=0x04 BRK # Boot from disk?
    asm @0 JPnn w0x0100 @5 RET w0xe400  # for zexdoc.com
    #asm @0x013a w0  # don't do any tests

    setupMMgr 0x013a-0x01c1 "$REPLY" RW  # allow writing to first (and second) test data address pointer

    if [[ -n $_TESTS ]]; then
        schedule_tests "$_TESTS"
    else
        printf "Select tests:\n"
        select _TESTS in $ZEXDOC_TESTS; do
            schedule_tests "$REPLY"
            break
        done
    fi
    return 0
}

#zexdoc "$1"

#printf "norm decode=%d  fast decode=%d\n" $norm_decode $fast_decode
#inst_dump

# write-out JIT'd program
dump_jit(){
    local -i _j
    for _j in ${!MEM[*]}; do  # for each assigned memory location
        o=MEM[_j];
        if (( o>=0 )); then  # assume non-JIT'd
            printf "%04x  %5d  %02x\n" $_j $_j $o
        else
            printf "%04x  %5d      %s\n" $_j $_j "${ACC[_j]}" 
        fi
    done
}

#dump_jit > dump-jit.jit

prelim(){
    . pc-cpm.bash     # CP/M functions
    . pc-prelim.bash  # prelim.com

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


gcc pc-z80-4.c 2>&1 | head -n 10

