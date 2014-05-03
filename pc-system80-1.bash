#!/bin/bash

# FIXME: could convert to 16b

#declare -i N=100000 a b c bc d e de

#time { a=0; for ((c=0;c<N;c++));do (( e+=1,(e==256)?(d=(d+1)&255,e=0):0 ));  done; printf "a=%d\n" $a; }  # 0.94
#time { a=0; for ((c=0;c<N;c++));do (( de=(d<<8)|e, de=(de+1)&65535, d=de>>8, e=de&255 ));  done; printf "a=%d\n" $a; }  # 1.2
#time { a=0; de=d*8+e; for ((c=0;c<N;c++));do (( de=(de+1)&65535, d=de/8, e=de&255 ));  done; printf "a=%d\n" $a; }  # 1.0
#time { a=0; de=d*8+e; for ((c=0;c<N;c++));do (( de++, de&=65535, d=de>>8, e=de&255 ));  done; printf "a=%d\n" $a; }  # 0.98

#time { a=0; fn(){ a=c;};         for ((c=0;c<N;c++));do       fn;  done; printf "a=%d\n" $a; }  # 0.93
#time { a=0; fn(){ a=c;};         for ((c=0;c<N;c++));do      a=c;  done; printf "a=%d\n" $a; }  # 0.47

#time { a=0; fn(){ a=c;};         for ((c=0;c<N;c++));do       fn;  done; printf "a=%d\n" $a; }  # 0.9 fastest
#time { a=0; fn(){ a=c;};         for ((c=0;c<N;c++));do eval "fn"; done; printf "a=%d\n" $a; }  # 1.5  eval is slow
#time { a=0; fn(){ a=c;};         for ((c=0;c<N;c++));do eval  fn;  done; printf "a=%d\n" $a; }  # 1.4
#time { a=0; fn(){ a=c;}; X="fn"; for ((c=0;c<N;c++));do eval  $X;  done; printf "a=%d\n" $a; }  # 1.5
#time { a=0; fn(){ a=c;}; X="fn"; for ((c=0;c<N;c++));do       $X;  done; printf "a=%d\n" $a; }  # 1.0 ok
#exit 0

shopt -s extglob

trap_int()  { printf "\nTRAP: <Ctrl+C pressed>\n(You may need to press another key to stop.)\n"; _STOP=true; }
trap_exit() { printf "\nTRAP: Exit trapped\n";     _STOP=true; }

trap trap_int SIGINT
trap trap_exit EXIT

SECONDS=1

# emulator registers and flags
declare -i a  b  c  d  e  f  h  l  sp pc  i r  iff1 iff2  x X y Y
declare -i a1 b1 c1 d1 e1 f1 h1 l1 
declare -i sa  sb  sc  sd  se  sf  sh  sl  ssp spc  si sr  siff1 siff2  sx sX sy sY
declare -i sa1 sb1 sc1 sd1 se1 sf1 sh1 sl1 
declare -i q t cycles states halt
declare -ia MEM MEM_READ MEM_WRITE MEM_EXEC MEM_JIT
declare -a MEM_JITS                              # list of instructions impacted by this JIT'd instruction
declare -a ACC BLK                               # accelerated functions
declare -a MEM_NAME MEM_RW MEM_DRIVER_R MEM_DRIVER_W MEM_DRIVER_E
declare -a OUT IN
declare -a FLAG_NAMES=( C N P X H Y Z S )
# flag masks
declare -i FS=0x80 FZ=0x40 FY=0x20 FH=0x10 FX=0x08 FP=0x04 FN=0x02 FC=0x01  
_STOP=false

# emulator globals
declare -i o                                     # first opcode byte
declare -i n  m                                  # 8 bit temporary value
declare -i nn mm  mn rr rrd jj cc                # 16 bit temporary value
declare -i af af1 bc bc1 de de1 hl hl1 ix iy     # used for holding 16bit register pair values
declare -i D                                     # used for +- displacements
declare -i ipc jpc opc                           # holds pc of current instruction - used for displaying
declare -i blockpc                               # holds address of current block being built
declare BFN                                      # current executing opcode function

# debugging globals
declare -a TRAP MSG

declare -i j                                     # global temporary integers # FIXME: might remove these globals
declare g                                        # global temporary other # FIXME: might remove these globals
declare B="%%02x" W="%%04x" C=" ; [%%b]" R="%%+d" # format strings for computed functions
declare -a HEX=( 0 1 2 3 4 5 6 7 8 9 a b c d e f )

# map emulator CPU register pair names to printed names 
declare -A RPN=( [hl]=HL [xX]=IX [yY]=IY [af]=AF [bc]=BC [de]=DE [sp]=SP [pc]=PC )

# map CPU registers to implemente emulator variables - mostly done for IX and IY
declare -A RN=( [a]=A [f]=F [0]=0 [b]=B [c]=C [d]=D [e]=E [h]=H [l]=L [x]=IXh [X]=IXl [y]=IYh [Y]=IYl )

# print message flags
_LOG=false
_JIT=false
_FAST=false
_BLOCK=false
_ACCEL_2=false
_MEMPROT=false
_VERBOSE=false
_ALL_FLAGS=false                                 # calc all flags or all but FY and FX
while :; do
    case $1 in
            LOG) _LOG=true;;
            JIT) _JIT=true;   _ACCEL_2=true;;
           FAST) _FAST=true;  _DEBUG=false;;
          BLOCK) _BLOCK=true;;
          DEBUG) _FAST=false; _DEBUG=true;;
        MEMPROT) _MEMPROT=true;;
        VERBOSE) _VERBOSE=true;;
       ALLFLAGS) _ALL_FLAGS=true;;
              *) break
    esac
    shift
done

# generate a C table. eg. make_cArray <bash array> <type>
# type=FN: array of function pointers
# type=INT: array of ints
make_cArray(){
    local _b=$1 _type=$2; local -i _j _n _c=0
    eval _n=\${#$_b[*]}                          # number of elements
    eval _i=\"\${!$_b[*]}\"                      # elements
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
cGEN=generated-functions.c
LOG=$0.log

printf "# Generated functions\n" > $GEN
printf "// C functions\n" > $cGEN
printf "$0 LOG\n" > $LOG

# make byte parity lookup table
declare -ia PAR
makePAR() {
    local -i _j _p
    $_VERBOSE && printf "MAKING PARITY TABLE...\n"
    for (( _j=0 ; _j<256 ; _j++ )); do
        (( _p=_j,
           _p=(_p&15)^(_p>>4),
           _p=(_p& 3)^(_p>>2),
           _p=(_p& 1)^(_p>>1),
           PAR[_j]=(!_p)*FP ))
    done
    return 0
}
makePAR

. instruction-set.bash                           # load instruction set

# setupMMgr <from>[<-to>] <name> <RO|RW|xxS> <driver function> # not used <color>
setupMMgr() {
    local _ADD="$1" _NAME="$2" _RW="$3" _DRIVERS="$4" _FR _TO _T _D; local -i _j
    $_VERBOSE && printf "MAKING MEMORY MANAGER: %-13s  %32s  %3s  %s...\n" "$_ADD" "$_NAME" "$_RW" "$_DRIVERS"
    _RW=${_RW:-RO}
    _FR=${_ADD%-*}; _TO=${_ADD#*-};
    for (( _j=$_FR; _j<=$_TO; _j++ )); do
        MEM_NAME[_j]="$_NAME"
        MEM_RW[_j]=$_RW
        MEM_JIT[_j]=0                            # default is 'may be JIT'd'
        MEM_JITS[_j]=                            # default is not JIT'd
        if [[ ${_RW:2:1} = "S" ]]; then
            MEM_JIT[_j]=-1  # force never to be JIT'd
            #MEM_JITS[_j]=
        fi
        for _D in $_DRIVERS; do
            _T="${_D##*_}"                       # get last 'type' character of driver name. should be W|E|R
            if [[ $_T =~ [WER] ]]; then
                eval "MEM_DRIVER_${_T}[_j]=\$_D"
            else                                 # else assume a universal driver
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
    $_VERBOSE && printf "MAKING CHARACTER TABLE...\n"
    for (( _j=0x00 ; _j<0x100  ; _j++ )); do 
        printf -v CHR[_j] "\\\x%02x" $_j         # make hex char sequence eg. \x41
        printf -v CHR[_j] "%b" "${CHR[_j]}"      # convert to string into array
    done
}
makeCHR

# printf macros - these help standardise code generation and cause bugs to affect many instructions to aide detection
# these also work in (()) eg. unset X Y HL; HL="1+1"; declare -i Y; declare -ia X=(2 4 6 8); (( Y=X[$HL] )); echo $Y
# WARNING: use no spaces within strings here or else C conversion will fail
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

PREFIX=( [0xCB]="CB" [0xED]="ED" [0xFD]="FD" [0xDD]="DD")

# unhandled instructions go here
XX()    { printf "ERROR: $FUNCNAME: Unknown operation code at %04x\n" $ipc; _STOP=true; }
acc_XX(){ printf "ERROR: $FUNCNAME: Unknown operation code at %04x\n" $ipc; _STOP=true; }
STOP()  { printf "\nSTOP: Stop emulator at %4x\n" $((pc-1));                _STOP=true; }

# write byte to port -ports are mapped to files on demand unless mapped in OUT array
wp() {
    local -i _p=$1 _v=$2
    [[ -z ${OUT[_p]} ]] && { OUT[_p]=$_p.out; $_DIS && printf "WARNING: $FUNCNAME: Output port $_p mapped to [%s]\n" ${OUT[_p]}; }
    printf "%c" ${CHR[_v]} >> ${OUT[_p]}
}

rp() {
    local -i _p=$1
    [[ -z ${IN[_p]} ]] && { IN[_p]=/dev/zero; $_DIS && printf "WARNING: $FUNCNAME: Input port $_p mapped to [%s]\n" ${IN[_p]}; }
    read -N1 n < ${IN[_p]}
}

ansi_nl()        {                    printf "\x1b[${1}E";        }
ansi_clearRight(){                    printf "\x1b[0K";           }
ansi_clearLeft() {                    printf "\x1b[1K";           }
ansi_clearLine() {                    printf "\x1b[2K";           }
ansi_c()         { local _c=$1;       printf "\x1b[${_c}G";       }
ansi_pos()       { local _r=$1 _c=$2; printf "\x1b[${_r};${_c}H"; }

# MEMORY MANAGEMENT

#if $_FAST; then
#memread() { local -i _a=$1;       local _DRIVER=${MEM_DRIVER_R[_a]}; [[ -n $_DRIVER ]] && $_DRIVER $_a; }
##memexec(){ local -i _a=$1;       local _DRIVER=${MEM_DRIVER_E[_a]}; [[ -n $_DRIVER ]] && $_DRIVER $_a; }
#memprot() { local -i _a=$1 _b=$2; local _DRIVER=${MEM_DRIVER_W[_a]}; [[ -n $_DRIVER ]] && $_DRIVER $_a $_b; }

#else

# trap read from memory and set memory value before actual read
memread() {
    local -i _a=$1; local _RW=${MEM_RW[_a]} _DRIVER=${MEM_DRIVER_R[_a]}
    [[ -z $_RW ]] && { printf "${FUNCNAME[*]}:\nRead from unassigned address %04x before PC=%04x\n" $_a $pc; _STOP=true; }
    [[ -n $_DRIVER ]] && $_DRIVER $_a            # eval $_DRIVER $_a
}

memexec() {
    local -i _a=$1; local _flags _RW=${MEM_RW[_a]} _DRIVER=${MEM_DRIVER_E[_a]}
    [[ -z $_RW ]] && { printf "${FUNCNAME[*]}:\nExecuted unassigned address at PC=%04x\n" $_a; _STOP=true; }
    [[ -n $_DRIVER ]] && $_DRIVER $_a            # eval $_DRIVER $_a 
}

# FIXME: IO may be RO WO or IO where a write followed by a read will get different values or reading produces different values
# hack to trap write to memory
memprotb() {
    local -i _a=$1 _b=$2 _i _j
    local _RW=${MEM_RW[_a]} _DRIVER=${MEM_DRIVER_W[_a]}
    case $_RW in
         RO) printf "${FUNCNAME[*]}:\nWrite to protected address %04x before PC=%04x\n" $_a $pc; _STOP=true;; 
         "") printf "${FUNCNAME[*]}:\nWrite to unassigned address %04x before PC=%04x\n" $_a $pc; _STOP=true;; 
    esac
    [[ -n $_DRIVER ]] && $_DRIVER $_a $_b        # eval $_DRIVER $_a $_b
    #return 0;
    (( MEM[_a]==_b )) && return 0                # mem value will not be changed so don't remove JIT just yet
    (( MEM_JIT[_a]>0 )) && {
        $_LOG && printf "%04x(%5d) [    ]  de-JIT instructions @ [%s]\n" $_a $_a "${MEM_JITS[_a]}" >> $LOG
        $_LOG && printf "%04x(%5d) [    ]  de-JIT instructions @ [%s]\n" $_a $_a "${MEM_JITS[_a]}"
        for _j in ${MEM_JITS[_a]}; do  # do for each instruction using this byte - usually 1, but could be 3?
            # in block mode it could be lots
            ACC[_j]=                                 # remove JIT or block
            MEM_JIT[_j]=-1                           # never JIT again
            (( MEM[_j]&=255 ))                       # de-jit this inst or block
            $_LOG && printf "%04x(%5d) [%04x=%5d]  de-JIT byte\n" $_a $_a $_j $_j >> $LOG
            $_LOG && printf "%04x(%5d) [%04x=%5d]  de-JIT byte\n" $_a $_a $_j $_j
            if [[ -n MEM_NAME[_j] ]]; then           # fix memory manager so that this should not be JIT'd again
                setupMMgr ${_j} "${MEM_NAME[_j]}" "RWS" "${MEM_DRIVER[_j]}"  # replace mem mgr entry
            else
                setupMMgr ${_j} "MEMPROT SELF MOD from pc=$ipc" "RWS"  # add mem mgr entry
            fi
        done
        MEM_JIT[_a]=-1                             # never JIT again - FIXME: redundant? setupMMgr?
    }
}

memprotw() {
    local -i _a=$1 _w=$2 _i _j
    local _RW=${MEM_RW[_a]} _DRIVER=${MEM_DRIVER_W[_a]}
    case $_RW in
         RO) printf "${FUNCNAME[*]}:\nWrite to protected address %04x before PC=%04x\n" $_a $pc; _STOP=true;; 
         "") printf "${FUNCNAME[*]}:\nWrite to unassigned address %04x before PC=%04x\n" $_a $pc; _STOP=true;; 
    esac
    [[ -n $_DRIVER ]] && $_DRIVER $_a $_w
    #return 0
    (( MEM[_a]+MEM[_a+1]*256==_w )) && return 0                # mem value will not be changed
    for (( _i=_a; _i<_a+2; _i++ )); do
        # FIXME: only do this if value changes
        (( MEM_JIT[_i]>0 )) && {
            $_LOG && printf "%04x(%5d) [    ]  de-JIT instructions @ [%s]\n" $_i $_i "${MEM_JITS[_i]}" >> $LOG
            $_LOG && printf "%04x(%5d) [    ]  de-JIT instructions @ [%s]\n" $_i $_i "${MEM_JITS[_i]}"
            for _j in ${MEM_JITS[_i]}; do  # do for each instruction using this byte - usually 1, but could be 3?
                ACC[_j]=                                 # remove JIT or block
                MEM_JIT[_j]=-1
                (( MEM[_j]&=255 ))                       # de-jit this inst or block
                $_LOG && printf "%04x(%5d) [%04x=%5d]  de-JIT byte\n" $_i $_i $_j $_j >> $LOG
                $_LOG && printf "%04x(%5d) [%04x=%5d]  de-JIT byte\n" $_i $_i $_j $_j
                if [[ -n MEM_NAME[_j] ]]; then           # fix memory manager so that this should not be JIT'd again
                    setupMMgr ${_j} "${MEM_NAME[_j]}" "RWS" "${MEM_DRIVER[_j]}"  # replace mem mgr entry
                else
                    setupMMgr ${_j} "MEMPROT SELF MOD from pc=$ipc" "RWS"  # add mem mgr entry
                fi
            done
            MEM_JIT[_i]=-1                             # never JIT again - FIXME: redundant? setupMMgr?
        }
    done
}

#fi

$_FAST && _A1="_a+1" || _A1="(_a+1)&65535"       # macro to return ta+1 withing address space

rb()      { local -i _a=$1;             memread $_a;         n=MEM[_a];                     }  # read byte
rw()      { local -i _a=$1;             memread $_a;     (( nn=MEM[_a] | (MEM[$_A1]<<8) )); }  # read word
rb2()     { local -i _a=$1;             memread $_a;         n=MEM[_a]; m=MEM[$_A1];        }  # read n,m
wb()      { local -i _a=$1 _b=$2;       memprotb $_a $_b;       MEM[_a]=_b;                         }  # write byte
ww()      { local -i _a=$1 _w=$2;       memprotw $_a $_w;    (( MEM[_a]=_w&255, MEM[$_A1]=_w>>8 )); }  # write word
wb2()     { local -i _a=$1 _l=$2 _h=$3; memprotb $_a $_l; memprotb $_a $_h;    (( MEM[_a]=_l,     MEM[$_A1]=_h ));    }  # write l,h

#rb="memread $_a;n=MEM[_a];                     }  # read byte

ARGS=""  # Accelerated functions args list
{
for r1 in a b c d e f h l x X y Y; do
    printf "ldrn$r1(){ $r1=MEM[pc++]; opc=pc; ARGS+=\"$r1=\$$r1;\"; }\n"
done
for rp in af bc de hl xX yY; do
    rh="${rp::1}"
    rl="${rp:1}"
    printf "ldrpnn$rp(){ $rl=MEM[pc++]; $rh=MEM[pc++]; opc=pc; ARGS+=\"$rl=\$$rl;$rh=\$$rh;\"; }\n"
done
} >> $GEN

#rn()      {     n=MEM[pc++];                   opc=pc;              ARGS+="n=$n;";   }  # read instruction byte n
#rm()      {     m=MEM[pc++];                   opc=pc;              ARGS+="m=$m;";   }  # read instruction byte m
#rD()      {     D=MEM[pc++];                   opc=pc; (( $RELD ));        ARGS+="D=$D;";   }  # read instruction displacement
rPCD()    {     D=MEM[pc++];                   opc=pc; (( $RELD, $PCD ));  ARGS+=" pc=$pc;"; }  # calc next pc
rDjjcc()  {     D=MEM[pc++];                   opc=pc; (( $RELD, cc=pc, jj=(pc+D)&65535 ));  ARGS+="cc=$cc;jj=$jj;"; }  # calc conditional alt. pc
rjjcc()   { (( jj=MEM[pc++]|(MEM[pc++]<<8) )); opc=pc; cc=pc;       ARGS+="cc=$cc;jj=$jj;"; }  # calc conditional alt. pc

#rnn()     { (( nn=MEM[pc++]|(MEM[pc++]<<8) )); opc=pc;              ARGS+="nn=$nn;"; }  # read instruction word nn
#rmm()     { (( mm=MEM[pc++]|(MEM[pc++]<<8) )); opc=pc;              ARGS+="mm=$mm;"; }  # read instruction word mm

rn="((n=MEM[pc++]));opc=pc;ARGS+=\"n=\$n;\""
rm="((m=MEM[pc++]));opc=pc;ARGS+=\"m=\$m;\""
rnn="((nn=MEM[pc]+MEM[pc+1]*256,pc+=2,opc=pc));ARGS+=\"nn=\$nn;\""
rmm="((mm=MEM[pc]+MEM[pc+1]*256,pc+=2,opc=pc));ARGS+=\"mm=\$mm;\""
rD="D=MEM[pc++];opc=pc;(($RELD));ARGS+=\"D=\$D;\""

eval "rD() { $rD;  }"  # read instruction displacement
eval "rn() { $rn;  }"  # read instruction byte n
eval "rm() { $rm;  }"  # read instruction byte m
eval "rnn(){ $rnn; }"  # read instruction word nn
eval "rmm(){ $rmm; }"  # read instruction word mm

rpc()     { local -i _p; (( _p=MEM[pc++]|(MEM[pc++]<<8) )); opc=pc; pc=_p;       ARGS+="pc=$pc;"; }  # read pc

#pushb()   { local -i _b=$1;    MEM[--sp]=_b;                                }  # push byte - not used
pushw()   { local -i _w=$1; (( MEM[--sp]=_w>>8, MEM[--sp]=_w&255 ));        }  # push word
pushpcnn(){                 (( MEM[--sp]=pc>>8, MEM[--sp]=pc&255, pc=nn )); }  # push pc and set pc=nn

#popn(){ n=MEM[sp++]; }
#popm(){ m=MEM[sp++]; }
#popnn(){ ((nn=MEM[sp]+MEM[sp+1]*256,sp+=2)); }
#popmm(){ ((mm=MEM[sp]+MEM[sp+1]*256,sp+=2)); }
#popmn(){ n=MEM[sp];m=MEM[sp+1];sp+=2; }
#poppc(){ pc=MEM[sp]+MEM[sp+1]*256;sp+=2; }

#FIXME: sp wrap

popn="n=MEM[sp++]"
popm="m=MEM[sp++]"
#popnn="nn=MEM[sp]+MEM[sp+1]*256;sp+=2"
#popmm="mm=MEM[sp]+MEM[sp+1]*256;sp+=2"
poppc="pc=MEM[sp]+MEM[sp+1]*256;sp+=2"
popmn="n=MEM[sp];m=MEM[sp+1];sp+=2"
pop="MEM[sp];sp+=1;((sp&=65535))"

eval "popn() { $popn;  }"  # pop byte n - not used
eval "popm() { $popm;  }"  # pop byte m - not used
#eval "popnn(){ $popnn; }"  # pop word nn
#eval "popmm(){ $popmm; }"  # pop word mm
eval "popmn(){ $popmn; }"  # pop bytes n,m
eval "poppc(){ $poppc; }"  # pop return address and set pc

. pc-z80-assembler.bash                          # load assembler

mem_make_readable() {  # make all assigned memory as RO
    local -i _j
    $_VERBOSE && printf "MARKING MEMORY AS READABLE...\n"
    for _j in ${!MEM[*]}; do [[ -z ${MEM_RW[_j]} ]] && MEM_RW[_j]="RO"; done  # set loaded memory to RO
}

# restart CPU will all registers preserved (normally you would set pc to 0x0000)
# CPU lines, timing, i and r are reset
warm_boot() {
    $_VERBOSE && printf "WARM BOOT...\n"
    SECONDS=1                                    # hack to eliminate division/0
    _STOP=false
    (( D=0, q=t=0, halt=0, iff1=iff2=0, i=0xff, r=0 ))  # [SC05]
    cycles=states=0
    decode                                       # like a real reset, start work
}

start() {                                        # start CPU with general purpose registers set
    $_VERBOSE && printf "START (only SP and PC reset)...\n"
    (( sp=0xffff, pc=0x0000 ))                   # [SY05]
    warm_boot                                    # like a real reset, start work
}

# [SY05] The Undocumented Z80 Documented, Sean Young, V0.91, 2005

reset() {                                        # emuilate a real reset or power-on of CPU
    $_VERBOSE && printf "RESET...\n"
    (( a=f=b=c=d=e=h=l=x=X=y=Y=a1=f1=b1=c1=d1=e1=h1=l1=x1=X1=y1=Y1=0xff ))  # [SY05] - could randomise these
    start
}

# FIXME: prefixed instructions at at least 1 M1 cycle and 4 states. IX+d add another 2 cycles and 4 states for d and another 4 for good measure (add?)

# NOTE: only first byte of opcode is treated as opcode for MMgr exec traps - handled in decode
MAPcb()   {              (( $INCr, cycles+=1, states+=4 )); m=MEM[pc++]; opc=pc; BFN="${CB[m]}";   $BFN; }
MAPddcb() { D=MEM[pc++]; (( $RELD, cycles+=2, states+=8 )); m=MEM[pc++]; opc=pc; BFN="${DDCB[m]}"; $BFN; }
MAPfdcb() { D=MEM[pc++]; (( $RELD, cycles+=2, states+=8 )); m=MEM[pc++]; opc=pc; BFN="${FDCB[m]}"; $BFN; }
MAPed()   {              (( $INCr, cycles+=1, states+=4 )); m=MEM[pc++]; opc=pc; BFN="${ED[m]}";   $BFN; }
#MAPdd()   {              (( $INCr, cycles+=1, states+=4 )); m=MEM[pc++]; opc=pc; BFN="${DD[m]}";   eval $BFN; }
MAPdd()   {              (( $INCr, cycles+=1, states+=4 )); m=MEM[pc++]; opc=pc; BFN="${DD[m]}";   $BFN; }
MAPfd()   {              (( $INCr, cycles+=1, states+=4 )); m=MEM[pc++]; opc=pc; BFN="${FD[m]}";   $BFN; }

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


load() {
    local -i _address=$1; local _filename="$2"
    $_VERBOSE && printf "LOADING $_filename...\n"
    if (( _address>0 )); then
        MEM=( [_address-1]=0 $( od -vAn -tu1 -w16 "$_filename" ) )  # load in at a given address
    else
        MEM=( $( od -vAn -tu1 -w16 "$_filename" ) )
    fi
    mem_make_readable
}

get_FLAGS() {
    local _r; local -i _j
    for (( _j=7; _j>=0; _j-- )); do
        (( f&(1<<_j) )) && _r+=${FLAG_NAMES[_j]} || _r+="."
    done
    RET="$_r"
}

decode_single(){
    local -i _apc=-1; local _DRIVER
    while (( pc!=_apc )); do 
        _apc=pc
        _DRIVER=${MEM_DRIVER_E[pc]}
        [[ -n $_DRIVER ]] && $_DRIVER $pc
    done
    ${IS[MEM[pc++]]}
}

decode_single_no_driver(){
    ${IS[MEM[pc++]]}
}

# JIT Block optimisation: if not a JP, JR, CALL, RET, DJNZ, LDIR, CPIR etc. then we can combine instructions into blocks
# eg. Normal JIT 
# 1000  INC BC     -> pc=1001; INCBC
# 1001  LD A,B     -> pc=1002; LDrr_ab
# 1002  OR C       -> pc=1003; ORr_c
# 1003  JP NZ,1000 -> pc=1006; nn=1000; JPnn

# transforms to BLOCK JIT (normal JIT done as well)
# pc=1001; INCBC; pc=1002; LDrr_ab; pc=1003; ORr_c; pc=1006; nn=1000; JPnn;

# and simplifies to
# INCBC; LDrr_ab; ORr_c; nn=1000; JPnn;

log_block(){
    ! $_LOG return 0
    local -i _pc=$1 _blk=$2; local _brief="$3"
    printf "%04x(%5d) [%04x=%5d] %10s %s\n%s\n" $_pc $_pc $_blk $_blk "$_brief" "${ACC[_blk]}" "${BLK[_blk]}" >> $LOG
}

append_to_block(){
    local _FILTER="$1" _BODY="$2" _P
    case $_FILTER in
        PC) _P="${ACC[blockpc]/ pc=+([0-9]);/}";;  # remove previous pc=<address> as only last one may be needed
         *) _P="${ACC[blockpc]}"
    esac
    ACC[blockpc]="${_P}${_BODY}"                 # now we append this accelerated code string to block
    log_block $ipc $blockpc "APPEND $BFN"
    return 0;
}


make_block_fn(){
    local _FILTER="$1" _BODY="$2" _P _FN
    append_to_block $_FILTER "${_BODY}"
    _FN="blk_${blockpc}(){ ${ACC[blockpc]}}"     # make a bash function - keep space after {
    BLK[blockpc]="$_FN"                          # save code for log
    eval "$_FN"                                  # 'compile it'
    ACC[blockpc]="blk_${blockpc}"                # now we just call new function that does block code
    log_block $ipc $blockpc "MAKE_BLK_FN"
    blockpc=pc
    return 0;
}

make_block(){
    local _FILTER="$1" _BODY="$2" _P _FN
    append_to_block $_FILTER "${_BODY}"
    _FN="${ACC[blockpc]}"
    BLK[blockpc]="$_FN"                          # save code for log
    ACC[blockpc]="$_FN"
    log_block $ipc $blockpc "MAKE_BLK"
    blockpc=pc
    return 0;
}

# FAST JIT 9729
# FAST JIT BLOCK 21176

dis(){ return 0; }
dnn(){ return 0; }


decode_BLOCK(){
    local -i _apc; local _DRIVER _BFN _P
    blockpc=pc
    $_VERBOSE && printf "DECODE JIT+BLOCK...\n"
    while ! $_STOP; do 
        _apc=pc
        _DRIVER=${MEM_DRIVER_E[pc]}
        [[ -n $_DRIVER ]] && {                   # run driver and reprocess possibly new pc
            $_DRIVER $pc                         # eval $_DRIVER $pc
            (( pc!=_apc )) && { blockpc=pc; continue; }  # if driver changes pc then we start a new block
        }
        ipc=pc                                   # save PC for this instruction for display
        o=MEM[pc++]
        opc=pc                                   # track inst. len (len=opc-ipc, next inst starts at MEM[opc])
        # NOTE: if opcode modified, this will switch to normal mode since opcode >=0
        if (( o>=0 )); then                      # normal opcode
            (( $INCr ))
            ARGS=""                              # clear to collect args for this instruction
            BFN="${IS[o]}"                       # updates opc
            log_block $ipc $blockpc "INTERPRET $BFN"
            $BFN                                 # eval $BFN
            #continue
            # sub 256 (so NOP is also negative) from first inst byte to flag JIT'd. we can get back original.
            #[[ ${MEM_RW[ipc]:2:1} = "S" ]] && {  # can't JIT self-modifying code - interpret this (ipc) inst
            (( MEM_JIT[ipc]<0 )) && {            # can't JIT self-modifying code
                log_block $ipc $blockpc "SELF MOD"                
                append_to_block PC "pc=$ipc; # SELF MODIFIED CODE"
                #blockpc=opc                     # we skip this so probably next block is opc
                blockpc=pc
                #make_block_fn " pc=$ipc;} # SELF MODIFIED CODE"  # this is 2x faster than above!!
                #make_block_fn " pc=$ipc"
                continue
            }
            _DRIVER=${MEM_DRIVER_E[ipc]}         # get driver for this address
            _BFN="acc_$BFN"                      # inline string name FIXME: rename to avoid confusion
            if [[ -n $_DRIVER ]]; then           # run driver and reprocess possibly new pc
                                                 # jit: run driver, if pc not changed, run jit instruction
                                                 # WARNING: needs a space after {
                if (( ipc==blockpc )); then      # first instruction of a block so JIT
                    ACC[ipc]="$_DRIVER \$pc;((pc==$ipc))&& { pc=$opc;${ARGS}${!_BFN}};" 
                    MEM[ipc]=o-256
                    log_block $ipc $blockpc $BFN
                else                             # append this onto current block and terminate block
                    #WARNING: need to keep last pc=xxxx; else this fails
                    #ACC[blockpc]+="$_DRIVER \$pc;((pc==$ipc))&& { pc=$opc;${ARGS}${!_BFN}};"
                    # failsappend_to_block "$_DRIVER \$pc; ((pc==$ipc)) && { pc=$opc;${ARGS}${!_BFN}};"
                    make_block_fn "" "$_DRIVER \$pc;((pc==$ipc))&& { pc=$opc;${ARGS}${!_BFN}};"
                    #this failsmake_block_fn "$_DRIVER \$pc;((pc==$ipc))&& { pc=$opc;${ARGS}${!_BFN}};"
                fi
                # after a driver, pc could change so this ends this block
                blockpc=pc
            else                                 # no driver, jit: run jit instruction
                # NOTES: for ACC[ipc], always lead with a space where pc= might be used
                case $BFN in
                                  # DJNZ*) # special: if jj==blockpc make [X]; while ((b>0)); do X; done;
                                         #if (( ipc==blockpc )); then
                                         #    if (( jj==blockpc )); then  # self-looping block
                                         #        ACC[blockpc]="b=0; pc=$opc;"   # trivial block - FIXME: no good for timing
                                         #        log_block $ipc $blockpc "TRIV. DJNZ"
                                         #    else
                                         #        ACC[ipc]="${ARGS}${!_BFN}"  # just a DJNZ
                                         #        log_block $ipc $blockpc $BFN
                                         #        blockpc=pc
                                         #    fi
                                         #    blockpc=pc
                                         #else
                                         #    if (( jj==blockpc )); then  # self-looping block
                                         #        _P="${ACC[blockpc]// pc=+([0-9]);/}"  # block
                                         #        # replace block with a loop
                                         #        ACC[blockpc]="${_P} while ((b-=1,b>0)); do ${_P} done; pc=$opc"
                                         #        log_block $ipc $blockpc "DJNZ WHILE LOOP"
                                         #        blockpc=pc
                                         #    else
                                         #        make_block_fn        "${ARGS}${!_BFN}"
                                         #    fi
                                         #fi
                               JPnn|JRn) append_to_block PC          "${ARGS}${!_BFN}";;
                                 CALLnn) # FIXME: what if called fn pop's ret address? 
                                         #make_block "pushw $opc;${ARGS}pc=nn;";;  # make a bash function
                                         append_to_block PC "pushw $opc;${ARGS}pc=nn;";;
                                  DJNZ*) make_block_fn   PC          "${ARGS}${!_BFN}";;
                                JP*|JR*) make_block_fn   PC          "${ARGS}${!_BFN}";;
                        CALL*|RET*|RST*) make_block_fn   PC " pc=$opc;${ARGS}${!_BFN}";;
                    LDIR|LDDR|CPIR|CPDR) make_block_fn   PC " pc=$opc;${ARGS}${!_BFN}";;
                                      *) append_to_block PC " pc=$opc;${ARGS}${!_BFN}";;
                esac
                (( ipc==blockpc )) && MEM[ipc]=o-256
            fi
            for (( _j=ipc; _j<opc; _j++ )); do
                MEM_JIT[_j]=1            # only mark first instruction
                MEM_JITS[_j]+="$blockpc "        # this inst is in another block
            done  # mark JIT'd block as JIT'd

        else  # switch modes to execute JIT'd instructions until we find a non-JIT'd one
            pc=ipc
            log_block $pc $blockpc "RUN FIRST"
            eval "${ACC[pc]}"
            while ! $_STOP && (( MEM[pc]<0 )); do  # stop if no more jit
                log_block $pc $blockpc "RUN LOOP"
                eval "${ACC[pc]}"              # run jit'd driver and instruction
            done
            blockpc=pc                        # new block start
        fi
    done
    return 0
}

decode_normal(){
    local -i _apc; local _DRIVER
    blockpc=-1                                   # not using jit blocks
    $_VERBOSE && printf "DECODE (normal)...\n"
    while ! $_STOP; do 
        _apc=pc
        _DRIVER=${MEM_DRIVER_E[pc]}
        [[ -n $_DRIVER ]] && {                   # run driver and reprocess possibly new pc
            $_DRIVER $pc                         # eval $_DRIVER $pc
            (( pc!=_apc )) && { continue; }
        }
        ipc=pc                                   # save PC for this instruction for display
        o=MEM[pc++]
        opc=pc                                   # track inst len (len=opc-ipc, next inst starts at MEM[opc])
        (( $INCr ))
        ARGS=""                                  # clear to collect args for this instruction
        BFN="${IS[o]}"                           # updates opc
        $_LOG && printf "%04x(%5d) [%04x] %10s %s\n" $ipc $ipc $blockpc "INTERPRET" "$BFN" >> $LOG
        $BFN                                     # does same as eval $BFN
    done
    return 0
}

decode_JIT() {
    local -i _apc _j; local _DRIVER _BFN
    blockpc=-1
    $_VERBOSE && printf "DECODE JIT...\n"
    while ! $_STOP; do 
        _apc=pc
        _DRIVER=${MEM_DRIVER_E[pc]}
        [[ -n $_DRIVER ]] && {                   # run driver and reprocess possibly new pc
            $_DRIVER $pc                         # eval $_DRIVER $pc
            (( pc!=_apc )) && continue
        }
        ipc=pc                                   # save PC for this instruction for display
        o=MEM[pc++]
        opc=pc                                   # track inst len (len=opc-ipc, next inst starts at MEM[opc])
        if (( o>=0 )); then                      # normal opcode
            (( $INCr ))
            ARGS=""                              # clear to collect args for this instruction
            BFN="${IS[o]}"                       # updates opc
            $_LOG && printf "%04x(%5d) [%04x] %10s %s\n" $ipc $ipc $ipc "INTERPRET" "$BFN" >> $LOG
            $BFN                                 # eval $BFN
            (( MEM_JIT[ipc]<0 )) && continue     # can't JIT self-modifying code
            _DRIVER=${MEM_DRIVER_E[ipc]}         # get driver for this instruction
            _BFN="acc_$BFN"                      # inline string name FIXME: rename to avoid confusion
            if [[ -n $_DRIVER ]]; then           # run driver and reprocess possibly new pc
                                                 # jit: run driver, if pc not changed, run jit instruction
                                                 # WARNING: needs a space after {
                ACC[ipc]="$_DRIVER \$pc;((pc==$ipc))&&{ pc=$opc;${ARGS}${!_BFN}};"
            else                                 # no driver, jit: run jit instruction
                ACC[ipc]="pc=$opc;${ARGS}${!_BFN}"
            fi
            for (( _j=ipc; _j<opc; _j++ )); do
                MEM_JITS[_j]+="$ipc "            # append to list of impacted (overlapping) instructios
            done
            MEM_JIT[ipc]=1                    # mark this instruction as JIT'd
            MEM[ipc]=o-256
            $_LOG && printf "%04x(%5d) [%04x] %10s %s\n" $pc $pc $ipc $BFN "${ACC[ipc]}" >> $LOG
        else                                     # execute JIT'd inst until non-JIT'd one
            pc=ipc
            $_LOG && printf "%04x(%5d) [%04x] %10s %s\n" $pc $pc $ipc "RUN FIRST" "${ACC[pc]}" >> $LOG
            eval "${ACC[pc]}"                    # can't drop eval here
            while ! $_STOP && (( MEM[pc]<0 )); do  # stop if no more jit
                $_LOG && printf "%04x(%5d) [%04x] %10s %s\n" $pc $pc $ipc "RUN LOOP" "${ACC[pc]}" >> $LOG
                eval "${ACC[pc]}"                # run jit'd driver and instruction
            done
        fi
    done
    return 0
}

# blocking is 2x faster than normal and JIT is 10% faster than normal
# LOG impacts JIT and normal more due to extra number of writes
# $_LOG && print ... does not seem to impact performance

# 33 timings LOG/no LOG
#     7714/9818
# JIT 7714/10800
# BLK 15428/15428
# 
decode(){
    if $_JIT; then
        if $_BLOCK; then
            #  time ./pc-system80-1.bash FAST JIT BLOCK LOG "33 34 35 36" = 19s (21176 cycles/hr)
            #  time ./pc-system80-1.bash FAST JIT BLOCK     "33 34 35 36" = 17s (24000 cycles/hr)
            decode_BLOCK  
        else
            #  time ./pc-system80-1.bash FAST JIT LOG "33 34 35 36" = 39s ( 9729 cycles/hr) 8307
            #  time ./pc-system80-1.bash FAST JIT     "33 34 35 36" = 30s (12857 cycles/hr)
            decode_JIT
        fi
    else
        #  time ./pc-system80-1.bash FAST LOG "33 34 35 36" = 42s ( 9000 cycles/hr)
        #  time ./pc-system80-1.bash FAST     "33 34 35 36" = 34s (11250 cycles/hr)
        decode_normal
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
        _spec="${_spec:0:2}X${_spec:3:1}X${_spec:5}"  # mask undocumented flags
    fi
    for (( _j=0; _j<8; _j++ )); do
        (( _mask=(1<<(7-_j)) ))
        _flag=${_spec:_j:1}
        case $_flag in
            .) _fMask+=_mask;;                   # no change - keep existing flag value
            r) _rMask+=_mask;;                   # take value from result
            R) _RMask+=_mask;;                   # take value from high byte of result
            s) _sMask+=_mask;;                   # take value from n2
            a) _aMask+=_mask;;                   # take value from register A
            0) ;;                                # set flag value to 0
            1) (( _f0+=_mask ));;                # set flag value to 1
            p) _flags+="+PAR[re]";;              # lookup parity
            I) _flags+="+iff1";;                 # LD A,I
          x|X) _xMask+=_mask;;                   # 'randomise' these flags
          z|Z) _flags+="+(re==0?$_mask:0)";;     # rarely a different bit works same as FZ. eg BIT and FP
            !) _flags+="+(f&$_mask)^$_mask";;    # invert flag
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
    printf " )); return 0; } # _spec=%s\n" "$_spec"
}

# set flags for re = n1 + n2, re is same register as n1
# flags S Z Y H X P N C
# bits 7(S) 5(Y) and 3(X) of re are copied into f. for add, N=0. for sub, N=1

$_VERBOSE && printf "MAKING INSTRUCTION FLAG FUNCTIONS...\n"

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
makesetf DAA   "rZrsrp.s"
makesetf LDI   "..^0^^0."  # BC=0 -> FP=0 else FP=1
makesetf LDIR  "..^0^00." 
makesetf CPI   "rZ^^^^1."
} >> $GEN


# generate functions
$_VERBOSE && printf "MAKING OTHER INSTRUCTION VERSIONS FROM FAST...\n"

# make accelerated versions of fast functions by prefixing function name with <acc_> and removing rn, rnn, rm, rmm, and rD calls

# NOTES: there are only 2 instruction function files: pc-generate-debug.bash and pc-generate-fast.bash
# fast versions were made manually by removing display (dis) calls and optimising resulting code
# accel version was made automatically from fast version by find & replace - NO LONGER MAINTAINED
# accel-2 version was made from fast version by sed - automatically maintained!
# accel-inline version are made automatically from accel version
# accel-2-inline version are made automatically from accel-2 version
# to change an inline version, modify fast version only. any change can be also copied manually into debug version.
trim(){
    sed -r \
      -e 's/[ ]+;/;/g                              # remove spaces before ;' \
      -e 's/;[ ]+/;/g                              # remove spaces after ;' \
      -e 's/[ ]+[|][|]/||/g                        # remove space before ||' \
      -e 's/[|][|][ ]+/||/g                        # remove space after ||' \
      -e 's/[ ]+[&][&]/\&\&/g                        # remove space before &&' \
      -e 's/[&][&][ ]+/\&\&/g                        # remove space after &&' \
      -e 's/[ ]+[{]/ {/g                            # leave 1 space before {' \
      -e 's/[{][ ]+/{ /g                           # leave 1 space after {' \
      -e 's/[ ]+}/}/g                              # remove spaces before }' \
      -e 's/[ ]+/ /g                               # remove multiple spaces' \
      -e 's/^[ ]+//g                               # removing leading space' \
      -e 's/[ ]+$//g                               # remove trailing space'
}

cat pc-generate-fast.bash \
| trim \
| sed -r \
    -e 's/printf "([^#])/printf "acc_\1/g             # prefix printed functions (not comments) with acc_'    \
    -e 's/([^_a-zA-Z0-9])r(n|nn|pc|m|mm|D|R|PCD|jjcc|Djjcc|nm);/\1/g  # erase these functions: <punct>rn;        -> <punct>'  \
    -e 's/([^_a-zA-Z0-9])ldrn[\\$a-zA-Z0-9]+;/\1/g       # erase these functions: <punct>ldrn<reg>; -> <punct>'  \
    -e 's/([^_a-zA-Z0-9])ldrpnn[\\$a-zA-Z0-9]+;/\1/g     # erase these functions: <punct>ldrpnn<regpair>; -> <punct>'  \
    -e 's/[{] ([^$][^;]+);[ ]*[}];/ \1;/g                # replace { abc; }; with abc;'                                     \
    > pc-generate-accel-2.bash


# make inline version by converting 
# * deleting line comments like [printf "# SP instructions - timing checked\n"]
# * converting [printf "acc_LDSPnn() { sp=nn; return 0; }  # from $0.$LINENO\n"] into [printf "acc_LDSPnn='sp=nn;'\n"]

# this is ugly but it save re-writing a new set of instructions for inline use.
# caveats: except to close a function body, a [;"&|] must follow a }

##from printf "acc_RET$N(){ (( ! (f&F$F) )) &&{ $poppc;} || return 0;} # from $0.$LINENO\n"
##from printf "acc_RET$N='(( ! (f&F$F) )) &&{ $poppc;} || } # from $0.$LINENO\n"
##from printf "acc_RET$N='(( ! (f&F$F) )) &&{ $poppc;} ||} # from $0.$LINENO\n"
##to   printf "acc_RET$N='(( ! (f&F$F) )) &&{ $poppc;} || # from $0.$LINENO\n"

echo 0
echo 1
cat pc-generate-accel-2.bash                                                                                     \
| trim \
| sed -r \
      -e 's/^printf "#.*\$//g                       # erase lines that print comments'                                 \
      -e 's/[(][)][ ]*[{][ ]*/\='\''/g             # replace function definition with string: abc(){ -> abc=<quote>'  \
      -e 's/return 0;//g                           # erase return 0;'                                                \
      -e 's/[{][ ]*[}];/;/g                        # remove { };'                                                     \
      -e 's/[{] ([^$][^;]+);[ ]*[}];/ \1;/g  # replace { abc; }; with abc;'                                     \
| trim \
| sed -r \
      -e 's/else[ ]+fi;/fi;/g                        # replace else fi; with fi;'  \
      -e 's/[&][&];/;/g                        # replace &&; with ;'                                              \
      -e 's/[&][&]}/;}/g                       # replace &&} with ;}'                                            \
      -e 's/[|][|];/;/g                        # replace ||; with ;'                                            \
      -e 's/[|][|]}/;}/g                       # replace ||} with ;}'                                           \
| trim                                                                                                           \
| sed -r \
      -e 's/[}] #.*$/'\''\\n"/g             # replace function close and following comment with quote'        \
> pc-generate-accel-2-inline.bash

#    -e 's/[ ][{][ ]*([^;]+;)[ ]*[}][ ]*;/ \1 /g  # replace { abc; }; with abc;'                                     \


# FIXME: this is not used anymore
# make a version with no 'return 0; '
echo 2
cat pc-generate-fast.bash           \
| trim \
| sed -r \
    -e 's/return 0;//g'            \
    -e 's/[{][ ]*[}]/ { return 0;}/g  # must return something if function does nothing'  \
| trim \
> pc-generate-fast-noret.bash

# instruction set functions require normal, accel and if JIT'd accel inline strings.
# debug (manual) -> fast -> (auto) -> accel-2 -> accel-2-inline

$_VERBOSE && printf "MAKING INSTRUCTION SET FUNCTIONS...\n"

$_DEBUG    && . pc-generate-debug.bash
$_FAST     && . pc-generate-fast.bash

# make c version
$_VERBOSE && printf "MAKING C VERSION OF INSTRUCTIONS...\n"
{
make_cArray PAR INT
# FIXME: is [ ]*[;]? same as [ ;]*?
cat generated-functions.bash \
| trim \
| sed -r \
    -e 's/dis[^;]+;//g                           # remove dis calls'  \
    -e 's/^setf([^() ]+)[(][)][^;]+;/void setf\1(int n1, int n2, int re){ /g  # convert setf fns to c fns'  \
    -e 's/^([^#]+[(][)])/void \1/g               # prefix functions with void'  \
    -e 's/return 0;//g                # delete return 0;'  \
    -e 's/while +([^;]+);do/while \1{/g  # while X;do -> while X{'  \
    -e  's/done;/}/g                      # done; -> }'  \
    -e 's/;then/{/g                        # ;then -> {'  \
    -e 's/else[ ]+fi;/fi;/g                        # replace else fi; with fi;'  \
    -e  's/else[ ]+/} else {/g                        # else -> } else {'  \
    -e  's/fi;/}/g                        # fi; -> }'  \
    -e 's/[ ;]*\#(.*)$/; \/\*\1\*\//g         # replace ;# comments with /* comment */'  \
    -e 's/([ ;])r(D|R|PCD|jjcc|Djjcc|n|m|nn|pc|mm);/\1r\2();/g  # convert rX; -> rX();'  \
    -e 's/([ ;])ldrn([a-fhlxXyY]);/\1ldrn\2();/g      # convert ldrnX; -> ldrnX();'  \
    -e 's/;ARGS[+]=".*";/;/g                   # remove ARGS+="...";'  \
    -e      's/pop([^() ;]+);/pop\1();/g  # convert popX; -> popX();'  \
    -e          's/pushpcnn;/pushpcnn();/g  # convert pushpcnn; -> pushpcnn();'  \
    -e     's/push([^() ]+) +([^ ;]+);/push\1(\2);/g  # convert pushX Y; -> pushX(Y);'  \
    -e     's/setf([^() ]+) +([^ ]+) ([^ ]+) ([^ ;]+);/setf\1(\2,\3,\4);/g' \
    -e               's/wb2 +([^ ]+) ([^ ]+) ([^ ;]+);/wb2(\1,\2,\3);/g' \
    -e                's/wb +([^ ]+) ([^ ;]+);/wb(\1,\2);/g' \
    -e                's/ww +([^ ]+) ([^ ;]+);/ww(\1,\2);/g' \
    -e                's/wp +([^ ]+) ([^ ;]+);/wp(\1,\2);/g' \
    -e                's/rb +([^ ;]+);/rb(\1);/g'  \
    -e               's/rb2 +([^ ;]+);/rb2(\1);/g'  \
    -e                's/rw +([^ ;]+);/rw(\1);/g'  \
    -e                's/rp +([^ ;]+);/rp(\1);/g'  \
    -e           's/memread +([^ ;]+);/memread(\1);/g'  \
    -e 's/local +-i/<local>int/g'  \
    -e 's/[$]//g'  \
    -e ':loop' \
        -e 's/<local>int ([^ ;]+)[ ]+/<local>int \1,/g  # ' \
    -e 't loop' \
    -e 's/<local>int/int/g  # rename to int'  \
    -e 's/([^ ;])[ ]*$/\1;/g  # ?<space>$ -> ?$ '

    
make_cArray IS FN
make_cArray CB FN
make_cArray DD FN
make_cArray DDCB FN
make_cArray ED FN
make_cArray FD FN
make_cArray FDCB FN

} >> $cGEN


$_ACCEL_2  && . pc-generate-accel-2.bash
$_ACCEL_2  && . pc-generate-accel-2-inline.bash

$_VERBOSE && printf "LOADING INSTRUCTION SET FUNCTIONS...\n"

. $GEN                                           # load manufactured functions



asm @0x0066 EI RETN                              # install NMI ISR for testing

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

test_overlap_code(){
    setupMMgr 0x0000-0x0600  RAM RW
    asm @0x0000 JPnn     w0x0100                \
        @0x0100 LDSPnn   w0x0600                \
                LDrn_b   b10                    \
                CALLnn   w0x0201                \
                CALLnn   w0x0200                \
                CALLnn   w0x0201                \
                CALLnn   w0x0200                \
                STOP                            \
        @0x0200 LDrn_a   LDBCnn LDrr_cb LDrr_bc \
                LDrn_a   b6                     \
                CPr_b                           \
                CALLZnn  w0x0300                \
                LDrn_a   b3                     \
                CPr_b                           \
                CALLZnn  w0x0400                \
                DJNZn    b-16                   \
                RET                             \
        @0x0300 LDrn_a   LDrr_bb                \
                LDmmA    w0x0203                \
                RET                             \
        @0x0400 LDrn_a   LDrr_cc                \
                LDmmA    w0x0202                \
                RET                             \
        @0x0500 STOP
    reset
    dis_regs
}

#test_overlap_code
#exit 0
zexdoc "$1"

gcc pc-z80-4.c 2>&1 | head -n 10                 # compile c version
exit 0

system80(){
    $_VERBOSE && printf "EMULATE SYSTEM-80\n"
    . system80-interface.bash
    load 0x0000 "system_80_rom"
    reset
    printf "\n\nTerminated\n"
}

#system80


