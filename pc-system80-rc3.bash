#!/bin/bash

declare -i v=255 V=65535


# FIXME: could convert to 16b

#declare -i N=100000 a b c bc d e de alongvarname

#time { d=e=0; for ((c=0;c<N;c++));do alongvarname=c; done; printf "var=%d\n" $alongvarname; }  # 0.54
#time { d=e=0; for ((c=0;c<N;c++));do a=c; done; printf "var=%d\n" $a; }  # 0.5 faster

#exit 0

#time { d=e=0; for ((c=0;c<N;c++));do (( d=c/256,e=c%256 )); done; printf "de=%d\n" $((d*256+e)); }  # 0.7
#time { d=e=0; for ((c=0;c<N;c++));do ((d=c>>8,e=c&255)); done; printf "de=%d\n" $((d*256+e)); }  # 0.63 fastest
#time { d=e=0; for ((c=0;c<N;c++));do (( d=c/256,e=c&255 )); done; printf "de=%d\n" $((d*256+e)); }  # 0.7
#time { d=e=0; for ((c=0;c<N;c++));do ((d=(c>>8),e=c&255)); done; printf "de=%d\n" $((d*256+e)); }  # 0.66

#exit 0

#time { d=e=0; for ((c=0;c<N;c++));do (( de=(de+1)&65535 )); done; printf "de=%d\n" $de; }  # 0.644 faster
#time { d=e=0; for ((c=0;c<N;c++));do (( de=de==65535?0:de+1 )); done; printf "de=%d\n" $de; }  # 0.664

#exit 0

#time { d=e=0; for ((c=0;c<N;c++));do (( e+=1,(e==256)?(d=(d+1)&255,e=0):0 ));  done; printf "e=%d\n" $e; }  # 0.91
#time { d=e=0; for ((c=0;c<N;c++));do (( e==255?(e=0,d=(d+1)&255):e++ ));  done; printf "e=%d\n" $e; }  # 0.85
#time { d=e=0; for ((c=0;c<N;c++));do (( e=e==255?(d=(d+1)&255,0):e+1 ));  done; printf "e=%d\n" $e; }  # 0.82 fastest
#time { d=e=0; for ((c=0;c<N;c++));do (( e=e>254?(d=(d+1)&255,0):e+1 ));  done; printf "e=%d\n" $e; }  # 0.82 fastest
#time { d=e=0; for ((c=0;c<N;c++));do (( e=(e==255?(d=(d+1)&255,0):e+1) ));  done; printf "e=%d\n" $e; }  # 0.91
#time { d=e=0; for ((c=0;c<N;c++));do (( de=(d<<8)|e,de=(de+1)&65535,d=de>>8,e=de&255 ));  done; printf "e=%d\n" $e; }  # 1.2
#time { d=e=0; de=d*8+e; for ((c=0;c<N;c++));do (( de=(de+1)&65535,d=de/8,e=de&255 ));  done; printf "e=%d\n" $e; }  # 0.9
#time { d=e=0; de=d*8+e; for ((c=0;c<N;c++));do (( de++,de&=65535,d=de>>8,e=de&255 ));  done; printf "e=%d\n" $e; }  # 0.96

#exit 0

#time { a=0; for ((c=0;c<N;c++));do (( a=c&255 )); done; printf "a=%d\n" $a; }  #0.57 0.58 0.59
#time { a=0; for ((c=0;c<N;c++));do (( a=c&0xff )); done; printf "a=%d\n" $a; }  #0.57 0.58 0.59
#time { a=0; b=255; for ((c=0;c<N;c++));do (( a=c&b )); done; printf "a=%d\n" $a; }  #0.56 0.57 0.58
#time { a=0; b=255; for ((c=0;c<N;c++));do ((a=c&b)); done; printf "a=%d\n" $a; }  #0.56 0.53 0.55 ok
#time { a=0;b=255;for((c=0;c<N;c++));do((a=c&b));done;printf "a=%d\n" $a;}  #0.54 0.55 seems slightly longer ok
#time { a=0;b=255;for((c=0;c<N;c++));do ((a=c&b));done;printf "a=%d\n" $a;}  #0.54 fastest

#exit 0

#time { a=0; for ((c=0;c<N;c++));do (( a+=1,a&=255 ));  done; printf "a=%d\n" $a; }  # 0.66 0.68
#time { a=0; for ((c=0;c<N;c++));do (( a++,a&=255 ));  done; printf "a=%d\n" $a; }  # 0.75 0.64
#time { a=0; for ((c=0;c<N;c++));do (( a=(++a)&255 ));  done; printf "a=%d\n" $a; }  # 0.67 0.64
#time { a=0; for ((c=0;c<N;c++));do ((a=(a+1)&255));  done; printf "a=%d\n" $a; }  # 0.57 0.59 fastest
#time { b=255; a=0; for ((c=0;c<N;c++));do ((a=(a+1)&b));  done; printf "a=%d\n" $a; }  # 0.61 ok
#time { a=0; for ((c=0;c<N;c++));do ((a=(a+1)&0xff));  done; printf "a=%d\n" $a; }  # 0.60 ok
#time { a=0; for ((c=0;c<N;c++));do (( a=(a+1)&255 ));  done; printf "a=%d\n" $a; }  # 0.63

#exit 0


#time { a=0; fn(){ a=c;};         for ((c=0;c<N;c++));do       fn;  done; printf "a=%d\n" $a; }  # 0.93
#time { a=0; fn(){ a=c;};         for ((c=0;c<N;c++));do      a=c;  done; printf "a=%d\n" $a; }  # 0.47

#time { a=0; fn(){ a=c;};         for ((c=0;c<N;c++));do       fn;  done; printf "a=%d\n" $a; }  # 0.9 fastest
#time { a=0; fn(){ a=c;};         for ((c=0;c<N;c++));do eval "fn"; done; printf "a=%d\n" $a; }  # 1.5  eval is slow
#time { a=0; fn(){ a=c;};         for ((c=0;c<N;c++));do eval  fn;  done; printf "a=%d\n" $a; }  # 1.4
#time { a=0; fn(){ a=c;}; X="fn"; for ((c=0;c<N;c++));do eval  $X;  done; printf "a=%d\n" $a; }  # 1.5
#time { a=0; fn(){ a=c;}; X="fn"; for ((c=0;c<N;c++));do       $X;  done; printf "a=%d\n" $a; }  # 1.0 ok

#exit 0

shopt -s extglob

trap_int()  { printf "\nTRAP: <Ctrl+C pressed>\n(You may need to press another key to stop.)\n"; _GO=false; }
trap_exit() { printf "TRAP: Exit trapped\n"; sleep 1; _GO=false; }
trap_err() { printf "\nTRAP: Command error\n" >> $LOG; _GO=false; }

trap trap_int SIGINT
trap trap_exit EXIT
trap trap_err ERR
SECONDS=1

# emulator registers and flags r7 is a shaddow r register to high set high bit
declare -i a  b  c  d  e  f  h  l  sp pc  i r r7 iff1 iff2  x X y Y
declare -i a1 b1 c1 d1 e1 f1 h1 l1 
declare -i sa  sb  sc  sd  se  sf  sh  sl  ssp spc  si sr  siff1 siff2  sx sX sy sY
declare -i sa1 sb1 sc1 sd1 se1 sf1 sh1 sl1 
declare -i q t cycles states halt
declare -ia MEM MEM_READ MEM_WRITE MEM_EXEC MEM_JIT
declare -a MEM_JITS MEM_BLK MEM_BLKS             # list of instructions impacted by this JIT'd instruction
declare -a ACC                                   # accelerated functions
declare -a MEM_NAME MEM_DRIVER_R MEM_DRIVER_W MEM_DRIVER_E
declare -ia MEM_R MEM_W MEM_S 
declare -a OUT IN
declare -a FLAG_NAMES=( C N P X H Y Z S )
# flag masks
declare -i FS=0x80 FZ=0x40 FY=0x20 FH=0x10 FX=0x08 FP=0x04 FN=0x02 FC=0x01  
_GO=true

declare -iA ISCNT # instruction counter

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
      _ASM=false
      _JIT=false
     _TEST=false
     _FAST=false
    _BLOCK=false
  _ACCEL_2=false
  _MEMPROT=false
  _VERBOSE=false
_ALL_FLAGS=false                                 # calc all flags or all but FY and FX
while :; do
    case $1 in
            LOG)       _LOG=true;;
            ASM)       _ASM=true;;
            JIT)       _JIT=true;    _ACCEL_2=true;;
           FAST)      _FAST=true;    _DEBUG=false;;
           TEST)      _TEST=true;    _DEBUG=false;;
          BLOCK)     _BLOCK=true;;
          DEBUG)      _FAST=false;   _DEBUG=true;;
        MEMPROT)   _MEMPROT=true;;
        VERBOSE)   _VERBOSE=true;;
       ALLFLAGS) _ALL_FLAGS=true;;
              *) break
    esac
    shift
done

# generate a C table. eg. make_cArray <bash array> <type>
# type=FN: array of function pointers
# type=INT: array of ints
make_cArray(){
    local _b=$1 _type=$2 _i; local -i _j _n _c=0
    eval _n=\${#$_b[*]}                          # number of elements
    eval _i=\"\${!$_b[*]}\"                      # elements
    case $_type in
       VFN) printf "void (*$_b[])()={";;
        FN) printf "void (*$_b[])()={";;
       INT) printf "int $_b[]={";;
     CHARP) printf "char* ${_b}_NAME[]={";;
    esac
    printf "  // from $_b[%d]" $_n
    for _j in $_i; do
        eval _v=\${$_b[_j]}
        (( (_j%8)==0 )) && printf "\n    [0x%02x]=" $_j
        case $_type in
         CHARP) printf "%-10s" "\"$_v\"";;
             *) printf "%-10s" $_v
        esac
        #(( (++_c)<_n )) && printf ","  # to remove last ',' but C does not care
        printf ","
    done
    printf "\n};\n"
}

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
        printf "\x1b[%d;%dH%2s" $((_r*1+4)) $((_c*3+6)) "$_v"
    done
    printf "\x1b[2E"
    return 0
}


GEN=generated-functions.bash
cGEN=generated-functions.c
LOG=$0.log

printf "# Generated functions\n" > $GEN
printf "// C functions\n" > $cGEN
printf "$0 LOG\n" > $LOG

# make byte parity lookup table
declare -ia PAR
#           _p=(_p&15)^(_p>>4),
#           _p=(_p& 3)^(_p>>2),
#           _p=(_p& 1)^(_p>>1),
#           PAR[_j]=(!_p)*FP ))

makePAR() {
    local -i _j _p
    $_VERBOSE && printf "MAKING PARITY TABLE...\n"
    for (( _j=0 ; _j<256 ; _j++ )); do
        (( _p=_j,
           _p=(_p>>4)^_p,
           _p=(_p<<2)^_p,
           _p=(_p>>1)^_p,
           _p=(255-_p)&FP ))
        (( PAR[_j]=_p?FP:0 ))  # broken in 4.3.0(1)-alpha
        PAR[_j]=_p
        #printf "PAR[%02x]=%01x " $_j ${PAR[_j]}
    done
    return 0
}
makePAR

#exit 0
. instruction-set.bash                           # load instruction set

# setupMMgr <from>[<-to>] <name> <RO|RW|xxS> <driver function> # not used <color>
setupMMgr() {
    local _ADD="$1" _NAME="$2" _RW="$3" _DRIVERS="$4" _FR _TO _T _D; local -i _j
    $_VERBOSE && printf "MAKING MEMORY MANAGER: %-13s  %32s  %3s  %s...\n" "$_ADD" "$_NAME" "$_RW" "$_DRIVERS"
    _RW=${_RW:-RO}
    _FR=${_ADD%-*}; _TO=${_ADD#*-};
    for (( _j=$_FR; _j<=$_TO; _j++ )); do
        MEM_NAME[_j]="$_NAME"
        case $_RW in
            RO) MEM_R[_j]=1; MEM_W[_j]=0; MEM_S[_j]=0;;
            RW) MEM_R[_j]=1; MEM_W[_j]=1; MEM_S[_j]=0;;
           RWS) MEM_R[_j]=1; MEM_W[_j]=1; MEM_S[_j]=1;;
             *) printf "ERROR: Unknown RW flag [%s] for address [%s]\n" $_RW $_ADD; _GO=false
        esac
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
    (( _RUNS==1 )) && { printf "\nWarm-boot: stopping\n"; _GO=false; }
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

#RELn="(n>127)?(n-=256):0"                        # printf macro to convert byte to int
#RELD="(D>127)?(D-=256):0"                        # printf macro to convert byte to int
#RELm="(m>127)?(m-=256):0"                        # printf macro to convert byte to int
for g in n D m; do
    #eval "REL$g=\"($g>127)?($g-=256):0\""        # printf macro to convert byte to int
    #eval "REL$g=\"$g-=$g>127?256:0\""        # printf macro to convert byte to int
    #eval "REL$g=\"$g-=($g<<1)&256\""        # printf macro to convert byte to int
    eval "REL$g=\"$g-=($g&128)<<1\""        # printf macro to convert byte to int
done

if $_FAST; then
PCn="pc+=n"
PCD="pc+=D"
#PCRELD="pc-=(D<<1)&256"  # how did this ever work?
PCRELD="pc+=D-(D&128)*2"
NNPCn="nn=pc+n"
NNPCD="nn=pc+D"
JJPCD="jj=pc+D"
#JJPCRELD="jj=pc-((D<<1)&256)"
JJPCRELD="jj=pc+D-((D&128)<<1)"
MMIXD="mm=(x<<8)+X+D"
MMIYD="mm=(y<<8)+Y+D"
else
PCn="pc=(pc+n)&65535"                            # printf macro to add n to pc and fix result
PCD="pc=(pc+D)&65535"                            # printf macro to add D to pc and fix result
#PCRELD="pc=(pc-((D<<1)&256))&65535"
PCRELD="pc=(pc+D-((D<<1)&256))&65535"
NNPCn="nn=(pc+n)&65535"                          # printf macro to add n to pc and fix result
NNPCD="nn=(pc+D)&65535"                          # printf macro to add D to pc and fix result
JJPCD="jj=(pc+D)&65535"                          # printf macro to add D to pc and fix result
#JJPCRELD="jj=(pc-((D<<1)&256))&65535"
JJPCRELD="jj=(pc+D-((D<<1)&256))&65535"
MMIXD="mm=((x<<8)+X+D)&65535"                          # printf macro to add D to pc and fix result
MMIYD="mm=((y<<8)+Y+D)&65535"                          # printf macro to add D to pc and fix result
fi

SETSP="0"
SETPC="0"
SETSPnn="sp=nn"
SETPCnn="pc=nn"

for rp in af bc de hl xX yY; do  # make string macros to inc/dec register pairs
    rh="${rp::1}"
    rl="${rp:1}"
    RP="${RPN[$rp],,}"
    
    eval "SET$RP=\"$rh=$RP>>8,$rl=$RP&255\""     # eg SEThl="h=(hl>>8),l=hl&255"
    #eval "SET$RP=\"$rh=$RP/256,$rl=$RP%%256\""
    eval "SET${rp}nn=\"$rh=nn>>8,$rl=nn&255\""   # eg SEThlnn="h=(nn>>8),l=nn&255"
    #eval "SET${rp}nn=\"$rh=nn/256,$rl=nn%%256\""
done

SETixnn="$SETxXnn"
SETiynn="$SETyYnn"

# NOTE: to avoid typos I generate these. If there is a mistake, it will be very obvious since every use will fail.
# manually typed macros have had typos that are hard to detect and fix 

for rp in af bc de hl xX yY; do  # make string macros to inc/dec register pairs
    rh="${rp::1}"
    rl="${rp:1}"
    
    eval "INC$rp=\"$rl=$rl>254?($rh=($rh+1)&255,0):$rl+1\""  #eg INChl="l+=1,(l==256)?(h=(h+1)&255,l=0):0"
    eval "DEC$rp=\"$rl=$rl?$rl-1:($rh=($rh-1)&255,255)\""  #eg DEChl="l-=1,(l==-1)?(h=(h-1)&255,l=255):0"
done
INCix="$INCxX"
INCiy="$INCyY"
DECix="$DECxX"
DECiy="$DECyY"

#INCr="r=(r&128)|((r+1)&127)"
#INCr="r=r7+((r+1)&127)"
INCr="r=r7+(r+1)%128"

for rp in af bc de hl ix iy; do  # make string macros to inc/dec register pairs
    RP="${RPN[$rp]}"
    eval "INC$RP=\"$rp=($rp+1)&65535\""    # eg INCHL="hl=(hl+1)&65535"
    eval "DEC$RP=\"$rp=($rp-1)&65535\""    # eg DECHL="hl=(hl-1)&65535"

done

for rp in sp pc; do  # make string macros to inc/dec register pairs
    RP="${RPN[$rp]}"
    eval "INC$RP=\"$rp+=1\""    # eg INCPC="pc=(pc+1)&65535"
    eval "DEC$RP=\"$rp-=1\""    # eg DECPC="pc=(pc-1)&65535"
done

# value of register pairs. use: $HLV
# WARNING: don't use spaces to simplify conversion to C
# value of register pairs for C - may not get used

for rp in af bc de hl xX yY; do  # make string macros to inc/dec register pairs
    rh="${rp::1}"
    rl="${rp:1}"
    RP="${RPN[$rp]}"
             eval "$RP=\"$rp=($rh<<8)|$rl\""    # eg HL="hl=(h<<8)|l"
    eval "${RP}1=\"${rp}1=(${rh}1<<8)|${rl}1\""    # eg HL1="hl1=(h1<<8)|l1"
        eval "${RP}V=\"\\\$((($rh<<8)|$rl))\""    # eg HLV="\$(((h<<8)|l))"
             eval "c${RP}V=\"($rh<<8)|$rl\""    # eg cHLV="(h<<8)|l"
done

PC="pc"
SP="sp"

PREFIX=( [0xCB]="CB" [0xED]="ED" [0xFD]="FD" [0xDD]="DD")

# unhandled instructions go here
XX()    { printf "ERROR: $FUNCNAME: Unknown operation code at %04x(%02x)\n" $ipc ${MEM[ipc]}; dis_regs; _GO=false; }
acc_XX(){ printf "ERROR: $FUNCNAME: Unknown operation code at %04x\n" $ipc; _GO=false; }
STOP()  { printf "STOP: Stop emulator at %4x\n" $((pc-1));                _GO=false; }

# write byte to port -ports are mapped to files on demand unless mapped in OUT array
wp() {
    local -i _p=$1 _v=$2
    [[ -z ${OUT[_p]} ]] && { OUT[_p]=$_p.out; $_DIS && printf "WARNING: $FUNCNAME: Output port $_p mapped to [%s]\n" ${OUT[_p]}; }
    printf "[%c]" ${CHR[_v]} >> ${OUT[_p]}
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
ansi_col()       { local _c=$1;       printf "\x1b[${_c}m";       }

# MEMORY MANAGEMENT

#if $_FAST; then
#memread() { local -i _a=$1;       local _DRIVER=${MEM_DRIVER_R[_a]}; [[ -n $_DRIVER ]] && $_DRIVER $_a; }
##memexec(){ local -i _a=$1;       local _DRIVER=${MEM_DRIVER_E[_a]}; [[ -n $_DRIVER ]] && $_DRIVER $_a; }
#memprot() { local -i _a=$1 _b=$2; local _DRIVER=${MEM_DRIVER_W[_a]}; [[ -n $_DRIVER ]] && $_DRIVER $_a $_b; }

#else

# trap read from memory and set memory value before actual read
memread() {
    local -i _a=$1; local _DRIVER=${MEM_DRIVER_R[_a]}
    ((MEM_R[_a])) || { printf "${FUNCNAME[*]}:\nRead from unassigned address %04x before PC=%04x\n" $_a $pc; _GO=false; }
    [[ -n $_DRIVER ]] && $_DRIVER $_a            # eval $_DRIVER $_a
}

memexec() {
    local -i _a=$1; local _flags _DRIVER=${MEM_DRIVER_E[_a]} 
    ((MEM_R[_a])) || { printf "${FUNCNAME[*]}:\nExecuted unassigned address at PC=%04x\n" $_a; _GO=false; }
    [[ -n $_DRIVER ]] && $_DRIVER $_a            # eval $_DRIVER $_a 
}

# FIXME: IO may be RO WO or IO where a write followed by a read will get different values or reading produces different values
# hack to trap write to memory
memprotb() {
    local -i _a=$1 _b=$2 _i _j
    local _DRIVER=${MEM_DRIVER_W[_a]}
    # IDEA: can only write if can read, so don't check read
    #((MEM_R[_a])) || { printf "${FUNCNAME[*]}:\nWrite to unassigned address %04x at PC/block=%04x\n" $_a $pc; _GO=false; }
    ((MEM_W[_a])) || { printf "${FUNCNAME[*]}:\nWrite to protected address %04x before PC=%04x\n" $_a $pc; _GO=false; }
    
    [[ -n $_DRIVER ]] && $_DRIVER $_a $_b        # eval $_DRIVER $_a $_b
    #return 0;
    (( MEM[_a]==_b )) && return 0                # mem value will not be changed so don't remove JIT just yet
    (( MEM_JIT[_a]>0 )) && {                     # instruction is JIT'd
        for _j in ${MEM_JITS[_a]}; do  # do for each instruction using this byte - usually 1, but could be 3?
            $_LOG && printf "%04x(%5d) [%04x=%5d]  de-JIT instruction byte\n" $ipc $ipc $_j $_j >> $LOG
            #$_LOG && printf "%04x(%5d) [%04x=%5d]  de-JIT instruction byte\n" $ipc $ipc $_j $_j
            ACC[_j]=                                 # remove JIT or block
            MEM_JIT[_j]=-1                           # never JIT again
            (( MEM[_j]&=255 ))                       # de-jit this inst
            if [[ -n MEM_NAME[_j] ]]; then           # fix memory manager so that this should not be JIT'd again
                setupMMgr ${_j} "${MEM_NAME[_j]}" "RWS" "${MEM_DRIVER[_j]}"  # replace mem mgr entry
            else
                setupMMgr ${_j} "MEMPROT SELF MOD from pc=$ipc" "RWS"  # add mem mgr entry
            fi
        done
        for _j in ${MEM_BLKS[_a]}; do  # do for each block using this byte
            $_LOG && printf "%04x(%5d) [%04x=%5d]  de-JIT block byte\n" $ipc $ipc $_j $_j >> $LOG
            #$_LOG && printf "%04x(%5d) [%04x=%5d]  de-JIT block byte\n" $ipc $ipc $_j $_j
            # in block mode it could be lots
            ACC[_j]=                                 # remove JIT or block
            (( MEM[_j]&=255 ))                       # de-jit this block
        done
        MEM_JIT[_a]=-1                             # never JIT again - FIXME: redundant? setupMMgr?
    }
}

memprotw() {
    local -i _a=$1 _w=$2 _i _j
    local _DRIVER=${MEM_DRIVER_W[_a]}
    #((MEM_R[_a])) || { printf "${FUNCNAME[*]}:\nWrite to unassigned address %04x at PC/block=%04x\n" $_a $pc; _GO=false; }
    ((MEM_W[_a])) || { printf "${FUNCNAME[*]}:\nWrite to protected address %04x before PC=%04x\n" $_a $pc; _GO=false; }
    [[ -n $_DRIVER ]] && $_DRIVER $_a $_w
    #return 0
    (( MEM[_a]+MEM[_a+1]*256==_w )) && return 0                # mem value will not be changed
    for (( _i=_a; _i<_a+2; _i++ )); do
        # FIXME: only do this if value changes
        (( MEM_JIT[_i]>0 )) && {
            for _j in ${MEM_JITS[_i]}; do  # do for each instruction using this byte - usually 1, but could be 3?
                $_LOG && printf "%04x(%5d) [%04x=%5d]  de-JIT instruction word\n" $ipc $ipc $_j $_j >> $LOG
                #$_LOG && printf "%04x(%5d) [%04x=%5d]  de-JIT instruction word\n" $ipc $ipc $_j $_j
                ACC[_j]=                                 # remove JIT or block
                MEM_JIT[_j]=-1
                (( MEM[_j]&=255 ))                       # de-jit this inst or block
                if [[ -n MEM_NAME[_j] ]]; then           # fix memory manager so that this should not be JIT'd again
                    setupMMgr ${_j} "${MEM_NAME[_j]}" "RWS" "${MEM_DRIVER[_j]}"  # replace mem mgr entry
                else
                    setupMMgr ${_j} "MEMPROT SELF MOD from pc=$ipc" "RWS"  # add mem mgr entry
                fi
            done
            for _j in ${MEM_BLKS[_i]}; do  # do for each block using this byte
                $_LOG && printf "%04x(%5d) [%04x=%5d]  de-JIT block word\n" $ipc $ipc $_j $_j >> $LOG
                #$_LOG && printf "%04x(%5d) [%04x=%5d]  de-JIT block word\n" $ipc $ipc $_j $_j
                ACC[_j]=                                 # remove block
                (( MEM[_j]&=255 ))                       # de-jit this inst or block
            done
            MEM_JIT[_i]=-1                             # never JIT again - FIXME: redundant? setupMMgr?
        }
    done
}

#fi

$_FAST && _A1="_a+1" || _A1="(_a+1)&65535"       # macro to return ta+1 withing address space

rb()      { local -i _a=$1;             memread $_a;         n=MEM[_a];                     }  # read byte
# FIXME: used internally only
rw()      { local -i _a=$1;             memread $_a;     (( nn=MEM[_a] | (MEM[$_A1]<<8) )); }  # read word
#rb2()     { local -i _a=$1;             memread $_a;         n=MEM[_a]; m=MEM[$_A1];        }  # read n,m
wb()      { local -i _a=$1 _b=$2;       memprotb $_a $_b;       MEM[_a]=_b;                         }  # write byte
# FIXME: used internally only
ww()      { local -i _a=$1 _w=$2;       memprotw $_a $_w;    (( MEM[_a]=_w&255, MEM[$_A1]=_w>>8 )); }  # write word
#wb2()     { local -i _a=$1 _l=$2 _h=$3; memprotb $_a $_l; memprotb $_a $_h;    (( MEM[_a]=_l,     MEM[$_A1]=_h ));    }  # write l,h

#rb="memread $_a;n=MEM[_a];                     }  # read byte
# make functions to read instruction operand byte/word into register

ARGS=""  # Accelerated functions args list
{
for r1 in a b c d e f h l x X y Y; do
    printf "ldrn$r1(){ $r1=MEM[pc++];opc=pc;ARGS+=\"$r1=\$$r1;\";}\n"
done

for rp in af bc de hl xX yY; do
    rh="${rp::1}"
    rl="${rp:1}"
    printf "ldrpnn$rp(){ $rl=MEM[pc++];$rh=MEM[pc++];opc=pc;ARGS+=\"$rl=\$$rl;$rh=\$$rh;\";}\n"
done
} >> $GEN

#rn(){ n=MEM[pc++];opc=pc;ARGS+="n=$n;";}  # read instruction byte n
#rm(){ m=MEM[pc++];opc=pc;ARGS+="m=$m;";}  # read instruction byte m
#rD(){ D=MEM[pc++];opc=pc;(($RELD));ARGS+="D=$D;";}  # read instruction displacement
#rPCD(){ D=MEM[pc++];opc=pc;(($RELD,$PCD));ARGS+=" pc=$pc;";}  # calc next pc
rPCD(){ D=MEM[pc++];opc=pc;(($PCRELD));ARGS+=" pc=$pc;";}  # calc next pc
#rDjjcc(){ D=MEM[pc++];opc=pc;(($RELD,cc=pc,jj=(pc+D)&65535));ARGS+="cc=$cc;jj=$jj;";}  # calc conditional alt. pc
#rDjjcc(){ D=MEM[pc++];opc=cc=pc;(($RELD,$JJPCD));ARGS+="cc=$cc;jj=$jj;";}  # calc conditional alt. pc
rDjjcc(){ D=MEM[pc++];opc=cc=pc;(($JJPCRELD));ARGS+="cc=$cc;jj=$jj;";}  # calc conditional alt. pc
rjjcc(){ ((jj=MEM[pc++]|(MEM[pc++]<<8)));opc=cc=pc;ARGS+="cc=$cc;jj=$jj;";}  # calc conditional alt. pc

#rnn()     { (( nn=MEM[pc++]|(MEM[pc++]<<8) )); opc=pc;              ARGS+="nn=$nn;"; }  # read instruction word nn
#rmm()     { (( mm=MEM[pc++]|(MEM[pc++]<<8) )); opc=pc;              ARGS+="mm=$mm;"; }  # read instruction word mm

rn="((n=MEM[pc++]));opc=pc;ARGS+=\"n=\$n;\""
rm="((m=MEM[pc++]));opc=pc;ARGS+=\"m=\$m;\""
#rnn="((nn=MEM[pc]+MEM[pc+1]*256,pc+=2,opc=pc));ARGS+=\"nn=\$nn;\""
rnn="((nn=MEM[pc++],nn+=MEM[pc++]*256,opc=pc));ARGS+=\"nn=\$nn;\""
#rmm="((mm=MEM[pc]+MEM[pc+1]*256,pc+=2,opc=pc));ARGS+=\"mm=\$mm;\""
rmm="((mm=MEM[pc++],mm+=MEM[pc++]*256,opc=pc));ARGS+=\"mm=\$mm;\""
rD="D=MEM[pc++];opc=pc;(($RELD));ARGS+=\"D=\$D;\""

eval  "rD(){ $rD;}"   # read instruction displacement
eval  "rn(){ $rn;}"   # read instruction byte n
eval  "rm(){ $rm;}"   # read instruction byte m
eval "rnn(){ $rnn;}"  # read instruction word nn
eval "rmm(){ $rmm;}"  # read instruction word mm

rpc(){ local -i _p;((_p=MEM[pc++]|(MEM[pc++]<<8)));opc=pc;pc=_p;ARGS+=" pc=$pc;";}  # read pc

# pushb used in zexdoc
pushb(){ local -i _b=$1;MEM[--sp]=_b;}  # push byte - not used
pushw(){ local -i _w=$1;((MEM[--sp]=_w>>8,MEM[--sp]=_w&255));}  # push word
pushpcnn(){ ((MEM[--sp]=pc>>8,MEM[--sp]=pc&255,pc=nn));}  # push pc and set pc=nn

#popn(){ n=MEM[sp++]; }
#popm(){ m=MEM[sp++]; }
#popnn(){ ((nn=MEM[sp]+MEM[sp+1]*256,sp+=2)); }
#popmm(){ ((mm=MEM[sp]+MEM[sp+1]*256,sp+=2)); }
#popmn(){ n=MEM[sp];m=MEM[sp+1];sp+=2; }
#poppc(){ pc=MEM[sp]+MEM[sp+1]*256;sp+=2; }

#FIXME: sp wrap

#popnn="nn=MEM[sp]+MEM[sp+1]*256;sp+=2"
#popmm="mm=MEM[sp]+MEM[sp+1]*256;sp+=2"
#pop="MEM[sp];sp+=1;((sp&=65535))"
if $_FAST; then
    popn="n=MEM[sp++]"
    popm="m=MEM[sp++]"
    #poppc="pc=MEM[sp]+MEM[sp+1]*256;sp+=2"
    poppc="pc=MEM[sp++];pc+=MEM[sp++]*256"
    popnn="nn=MEM[sp++];nn+=MEM[sp++]*256"  # used in zexdoc
    #popmn="n=MEM[sp];m=MEM[sp+1];sp+=2"
    popmn="n=MEM[sp++];m=MEM[sp++]"
    pop="MEM[sp++]"
else
    popn="n=MEM[sp++];(($INCSP))"
    popm="m=MEM[sp++];(($INCSP))"
    poppc="pc=MEM[sp]+MEM[sp+1]*256;((sp=(sp+2)&65535))"
    popnn="nn=MEM[sp]+MEM[sp+1]*256;((sp=(sp+2)&65535))"
    popmn="n=MEM[sp];m=MEM[sp+1];((sp=(sp+2)&65535))"
    pop="MEM[sp];(($INCSP))"
fi

eval "popn(){ $popn;}"  # pop byte n - not used
eval "popm(){ $popm;}"  # pop byte m - not used
eval "popnn(){ $popnn;}"  # pop word nn
#eval "popmm(){ $popmm;}"  # pop word mm
eval "popmn(){ $popmn;}"  # pop bytes n,m
eval "poppc(){ $poppc;}"  # pop return address and set pc

. pc-z80-assembler.bash                          # load assembler

mem_make_readable() {  # make all assigned memory as RO
    local -i _j
    $_VERBOSE && printf "MARKING MEMORY AS READABLE...\n"
    for _j in ${!MEM[*]}; do
        ((MEM_R[_j])) || MEM_R[_j]=1
    done  # set loaded memory to RO
}

# restart CPU will all registers preserved (normally you would set pc to 0x0000)
# CPU lines, timing, i and r are reset
warm_boot() {
    $_VERBOSE && printf "WARM BOOT...\n"
    SECONDS=1                                    # hack to eliminate division/0
    _GO=true
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
if $_FAST; then
              MAPcb(){ m=MEM[pc++];opc=pc;BFN=${CB[m]};$BFN;}
MAPddcb(){ D=MEM[pc++];(($RELD));m=MEM[pc++];opc=pc;BFN=${DDCB[m]};$BFN;}
MAPfdcb(){ D=MEM[pc++];(($RELD));m=MEM[pc++];opc=pc;BFN=${FDCB[m]};$BFN;}
              #XXMAPed(){ dis_regs;m=MEM[pc++];printf "%02x " $m;opc=pc;BFN=${ED[m]};$BFN;}
              MAPed(){ m=MEM[pc++];opc=pc;BFN=${ED[m]};$BFN;}
              MAPdd(){ m=MEM[pc++];opc=pc;BFN=${DD[m]};$BFN;}
              MAPfd(){ m=MEM[pc++];opc=pc;BFN=${FD[m]};$BFN;}
else
              MAPcb(){ (($INCr,cycles+=1,states+=4));m=MEM[pc++];opc=pc;BFN="${CB[m]}";$BFN;}
MAPddcb(){ D=MEM[pc++];(($RELD,cycles+=2,states+=8));m=MEM[pc++];opc=pc;BFN="${DDCB[m]}";$BFN;}
MAPfdcb(){ D=MEM[pc++];(($RELD,cycles+=2,states+=8));m=MEM[pc++];opc=pc;BFN="${FDCB[m]}";$BFN;}
              MAPed(){ (($INCr,cycles+=1,states+=4));m=MEM[pc++];opc=pc;BFN="${ED[m]}";$BFN;}
              MAPdd(){ (($INCr,cycles+=1,states+=4));m=MEM[pc++];opc=pc;BFN="${DD[m]}";$BFN;}
              MAPfd(){ (($INCr,cycles+=1,states+=4));m=MEM[pc++];opc=pc;BFN="${FD[m]}";$BFN;}
fi

dis_regs() {
    local _flags _rp _x; local -i _rr _rr1 _nn _h _l _j _ss _sh _sl
    printf "REGISTERS  (a negative in unsigned column means JIT replaced instruction)\n"
    #printf "\x1b[s"  # save cursor
    #ansi_nl; ansi_c 65; 
    get_FLAGS; _flags="$RET"
    #printf "a=[%02x]\n" $a
    printf "RP=%4s (%4s) %5s|%-6s %3s|%-4s %3s|%-4s [%16s]\n" HHLL MMMM UU SS U S u s "16B from MEM[RP]"
    printf "AF=%04x (%02x=%1s) %16d|%-+4d %8s\n" $(( $AF )) $a "${CHR[a]}" $a $(( a>127?a-256:a )) "$_flags"
    #rw $de; printf "\nDE:%04x [%04x]" $(( $DE )) $nn
    for _rp in BC DE HL IX IY SP PC; do
        (( _rr=${!_rp} ))  # , _rr1=$_rp ))
        #(( _nn=MEM[_rr]|(MEM[(_rr+1)&65535]<<8) ))
        (( _nn=MEM[_rr]+MEM[(_rr+1)&65535]<<8, _nn&=65535 ))
        #printf "_rp=%s _rr=%04x _rr1=%04x _nn=%04x MEM[0]=%02x MEM[1]=%02x\n" $_rp $_rr $_rr1 $_nn ${MEM[0]} ${MEM[1]}
        #_rr=$(( ${!_rp} ))
        (( _h=_nn>>8, _l=_nn&255, _ss=_nn>0x7fff?_nn-65536:_nn, _sh=_h>127?_h-256:_h, _sl=_l>127?_l-256:_l ))
        #if (( _nn<0 )); then
        #    printf "$_rp=%04x (----) %5d|%-+6d %3d|%-+4d %3d|%-+4d [" $_rr      $_nn $_ss $_h $_sh $_l $_sl
        #else
            printf "$_rp=%04x (%04x) %5d|%-+6d %3d|%-+4d %3d|%-+4d [" $_rr $_nn $_nn $_ss $_h $_sh $_l $_sl
        #fi
        for (( _j=0; _j<16; _j++ )); do
            _x=${MEM[(_rr+_j)&65535]}
            if [[ -z $_x ]]; then
                ansi_col 41; printf " "; ansi_col
            elif (( _x>=256 )); then
                ansi_col 42; printf "%c" "${CHR[ $((_x&255)) ]}"; ansi_col
            elif (( _x>=0 )); then
                printf "%c" "${CHR[_x]}"
            else
                ansi_col 43; printf "%c" "${CHR[ $((_x&255)) ]}"; ansi_col            
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
    #return 0
    ! $_LOG return 0
    local -i _pc=$1 _blk=$2; local _brief="$3"
    printf "%04x(%5d) [%04x=%5d] %s %s -- %s\n\n" $_pc $_pc $_blk $_blk "$_brief" "${ACC[_blk]}" "${BLK[_blk]}" >> $LOG
    #printf "%04x(%5d) [%04x=%5d] %s %s\n\n" $_pc $_pc $_blk $_blk "$_brief" "${ACC[_blk]}" >> $LOG
}

log_jit(){
    ! $_LOG return 0
    local -i _pc=$1; local _brief="$2"
    printf "%04x(%5d) %12s %s %s\n\n" $_pc $_pc "" "$_brief" "${ACC[_pc]}" >> $LOG
}

log_note(){
    ! $_LOG return 0
    local -i _pc=$1; local _brief="$2"
    printf "%04x(%5d) %12s %s\n\n" $_pc $_pc "" "$_brief" >> $LOG
}

# removing code is expensive. not filtering pc= and some ((f=...)); statements does not improve speed for up to 100 cycles.

# bulk flag optimisation

append_to_block(){
    local _FILTER="$1" _BODY="$2" _P  # mostly _FILTER is "PC" but sometimes ""
    printf "."

    # change ((f=...) to ((fc=X,fs=X,fz=X,fh=X,fc=X,f=fs+fz+...+fc))
    # then replace fz=(...), with '' and +fz+ with + 
    #_BODY="${_BODY/[,;]k=+([x0-9a-fA-F])/}"
    #_BODY="${_BODY/[,;]u=+([x0-9a-fA-F])/}"

    if [[ -n ${ACC[blockpc]} ]]; then            # only process if not empty
        case "$_FILTER" in
            PC) _P="${ACC[blockpc]/ pc=+([0-9]);/}";;  # remove previous pc=<address> as only last one may be needed
             *) _P="${ACC[blockpc]}"                   # sometimes we need pc
        esac

        # here _P should be used
        # 1. if instruction uses one or more flags, it converts all previous ((f= code to ((  f= to lock it in. DEFGH
        # 2. if instruction uses no flags, do nothing. ABC
        # 3. if instruction sets no flags, no nothing. ADH
        # 4. if instruction sets some flags, do nothing. BE
        # 5. if instruction sets all flags, remove any previous unlocked flag setting code. CFG

        if (( u>0 )); then  # inst. uses one or more flags - lock-in previous flags
            printf "u"
            # if u==1 (FC) then we jut need to save last ((f=...) that has k&u==1 - sets FC
            # 
            _P="${_P//[(][(]f=/(( f=}"           # lock-in flag set
            log_note $pc "Flags used - Lock in previous flag sets"
        fi
        if (( k==0xff )); then
            printf "k"
            _P="${_P//[(][(]f=+([^;]);/}"        # remove flag calcs as only last one may be needed
            log_note $pc "####Removed previous flag sets"
        fi
        ACC[blockpc]="${_P}${_BODY}"             # now we append this accelerated code string to block
    else
        ACC[blockpc]="${_BODY}"                  # just set block
    fi
    log_block $ipc $blockpc "APPEND $BFN"
    return 0;
}

# individual flag optimisation

append_to_block(){
    local _FILTER="$1" _BODY="$2" _P  # mostly _FILTER is "PC" but sometimes ""
    local -i _j
    #printf "."

    # change ((f=...) to ((fc=X,fs=X,fz=X,fh=X,fc=X,f=fs+fz+...+fc))
    # then replace fz=(...), with '' and +fz+ with + 
    #_BODY="${_BODY/[,;]k=+([x0-9a-fA-F])/}"
    #_BODY="${_BODY/[,;]u=+([x0-9a-fA-F])/}"

    _P="${ACC[blockpc]}"

    if [[ -z $_P ]]; then                        # nothing to do if empty
        ACC[blockpc]="${_BODY}"                  # just set block
        log_block $ipc $blockpc "APPEND $BFN"
        return 0;
    fi

    # block is not empty

    case "$_FILTER" in
        # FIXME: should be //?
        PC) _P="${_P/ pc=+([0-9]);/}";;          # remove previous pc=<address> as only last one may be needed
    esac

    # 1. if instruction uses one or more flags, it converts all previous ((f= code to ((  f= to lock it in. DEFGH
    # 2. if instruction uses no flags, do nothing. ABC
    # 3. if instruction sets no flags, no nothing. ADH
    # 4. if instruction sets some flags, do nothing. BE
    # 5. if instruction sets all flags, remove any previous unlocked flag setting code. CFG

    if (( u>0 )); then  # inst. uses one or more flags - lock-in previous flags
        #printf "u"
        # if u==1 (FC) then we just need to save last ((f=...) that has k&u==1 - sets FC
        log_note $pc "Flags used - Lock in previous flag sets"
        printf "A: %s\n" "$_P" >> $LOG
        u=255
        for (( _j=0; _j<8; _j++ )); do
            if (( u&(1<<_j) )); then
                printf "Lock-in previous f$_j...\n" >> $LOG
                _P="${_P//,f$_j/, f$_j}"         # lock-in prev flag calcs
                _P="${_P//+f$_j+/+ f$_j+}"       # lock-in prev flag calcs
            fi
        done
        #_P="${_P//,f/, f}"           # lock-in flag set
        #_P="${_P//+f/+ f}"           # lock-in flag sum
        printf "B: %s\n" "$_P" >> $LOG
    fi

    if (( k>0 )); then
        #printf "k"
        log_note $pc "####Removed previous flag sets"
        printf "A: %s\n" "$_P" >> $LOG
        for (( _j=0; _j<8; _j++ )); do
            if (( k&(1<<_j) )); then
                #printf "Remove previous f$_j...\n" >> $LOG
                _P="${_P//,f$_j=+([^,]),/,}"     # remove flag calcs as only last one may be needed
                _P="${_P//+f$_j+/+}"             # remove flag calcs as only last one may be needed
            fi
        done
        _P="${_P//k=+([0-9]),/}"            # remove leftovers ((k=xx,f=+0))
        _P="${_P//[(][(]f=+0[)][)];/}"      # remove leftovers ((k=xx,f=+0))
        printf "B: %s\n" "$_P" >> $LOG
    fi
    ACC[blockpc]="${_P}${_BODY}"              # just set block
    log_block $ipc $blockpc "APPEND $BFN"
    return 0;
}


# used to replace above code
append_to_block_simple(){
#append_to_block(){
    ACC[blockpc]="${ACC[blockpc]}$2"                 # now we append this accelerated code string to block
    log_block $ipc $blockpc "APPEND $BFN"
    return 0;
}


make_block_fn(){
    local _FILTER="$1" _BODY="$2" _P _FN
    append_to_block "$_FILTER" "${_BODY}"
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
    append_to_block "$_FILTER" "${_BODY}"
    _FN="${ACC[blockpc]}"
    BLK[blockpc]="$_FN"                          # save code for log
    ACC[blockpc]="$_FN"
    log_block $ipc $blockpc "MAKE_BLK"
    blockpc=pc
    return 0;
}

# this was used to eval next block rather than return to loop - but it segfaults sometimes
# probably recursive

eval_blk(){
    #return 0
    ! $_GO && return 0  # check _GO
    log_block $pc $pc "TAIL EVAL"
    #eval "${ACC[pc]}" 2>> $LOG
    eval "${ACC[pc]}"
    #printf "a=%02x  n=%02x  m=%02x\n" $a $n $m >> $LOG
    #[[ $? -ne 0 ]] && _GO=false
    return 0
}

# FAST JIT 9729
# FAST JIT BLOCK 21176

dis(){ return 0; }
dnn(){ return 0; }


#Test cycle: 34 -> 12240 c/h
#1d42( 7490)              INTERPRET MAPed
#1d42( 7490)              SELF MODIFIED CODE - CLOSE BLOCK
#1d46( 7494)              Flags used - Lock in previous flag sets
#1d46( 7494)              ####Removed previous flag sets
#1d42( 7490) [1d42= 7490] APPEND LDDEmm  pc=7490; -- 

decode_BLOCK(){
    local -i _apc; local _DRIVER _BFN _P
    blockpc=pc
    $_VERBOSE && printf "DECODE JIT+BLOCK...\n"
    while $_GO; do 
        _apc=pc
        _DRIVER=${MEM_DRIVER_E[pc]}
        [[ -n $_DRIVER ]] && {                   # run driver and reprocess possibly new pc
            log_note $_apc "INTERPRET: DRIVER: $_DRIVER $pc"
            $_DRIVER $pc                         # eval $_DRIVER $pc
            ((pc!=_apc)) && {                    # if driver changes pc then we start a new block
                log_note $ipc "INTERPRET: DRIVER CHANGED PC"
                blockpc=pc
                continue
            }  
        }
        u=k=0
        ipc=pc                                   # save PC for this instruction for display
        o=MEM[pc++]
        #opc=pc                                   # track inst. len (len=opc-ipc, next inst starts at MEM[opc])
        # NOTE: if opcode modified, this will switch to normal mode since opcode >=0
        if ((o>=0)); then                      # normal opcode
            opc=pc                                   # track inst. len (len=opc-ipc, next inst starts at MEM[opc])
            #(( $INCr ))
            ARGS=""                              # clear to collect args for this instruction
            BFN="${IS[o]}"                       # updates opc
            log_note $ipc "INTERPRET $BFN"
            #printf "[ipc=%04x]" $ipc
            $BFN                                 # eval $BFN

            # sub 256 (so NOP is also negative) from first inst byte to flag JIT'd. we can get back original.
            ((MEM_JIT[ipc]<0)) && {            # can't JIT self-modifying code
                log_note $ipc "SELF MODIFIED CODE - CLOSE BLOCK"                
                blockpc=pc
                continue
            }
            _DRIVER=${MEM_DRIVER_E[ipc]}         # get driver for this address
            _BFN="acc_$BFN"                      # inline string name FIXME: rename to avoid confusion
            for ((_j=ipc;_j<opc;_j++)); do
                MEM_JIT[_j]=1
                MEM_JITS[_j]+="$ipc "            # this byte is in these instructions
                ((ipc!=blockpc)) && MEM_BLKS[_j]+="$blockpc "        # this inst is in these blocks
            done
            ((ipc==blockpc)) && MEM[ipc]=o-256
            if [[ -n $_DRIVER ]];then           # run driver and reprocess possibly new pc
                                                 # jit: run driver, if pc not changed, run jit instruction
                                                 # WARNING: needs a space after {
                log_note $ipc "START/TERMINATE BLOCK WITH DRIVER $BFN"
                make_block_fn "" "$_DRIVER \$pc;((pc==$ipc))&& { pc=$opc;${ARGS}${!_BFN}};"
            else                                 # no driver, jit: run jit instruction
                # NOTES: for ACC[ipc], always lead with a space where pc= might be used
                case $BFN in
                               JPnn|JRn) append_to_block PC          "${ARGS}${!_BFN}";;
                                 CALLnn) append_to_block PC "pushw $opc;${ARGS}pc=nn;";;  # custom code
                                    RET) make_block_fn PC "${ARGS}${!_BFN}";;
                         JPHL|JPIX|JPIY) #log_note $ipc "JP HL|IX|IY"
                                         make_block_fn PC "${ARGS}${!_BFN}";;
                                JP*|JR*) # special if jj=blockpc make X; while ((pc==jj)); do X; done;
                                         if ((jj==blockpc));then  # self-looping block
                                             append_to_block PC "${ARGS}${!_BFN}"  # add JP/JR code to block
                                             _P="${ACC[blockpc]}"
                                             # replace block with a loop
                                             #log_note $ipc "JP/JR WHILE LOOP"
                                             append_to_block PC "while((pc==jj));do ${_P}done;"
                                         else
                                             #log_note $ipc "JP/JR NORMAL"
                                             make_block_fn PC "${ARGS}${!_BFN}"
                                         fi;;
                                  CALL*) make_block_fn PC " pc=$opc;${ARGS}${!_BFN}";;
                                   RET*) make_block_fn PC " pc=$opc;${ARGS}${!_BFN}";;  # pc= needed for conditional
                                  DJNZ*) # special: if jj==blockpc make X; while ((b>0)); do X; done;
                                         if ((ipc==blockpc));then
                                             if ((jj==blockpc));then  # self-looping block
                                                 log_block $ipc $blockpc "TRIVIAL DJNZ"
                                                 append_to_block "" "b=0; pc=$opc;"   # trivial block - FIXME: no good for timing
                                             else
                                                 log_block $ipc $blockpc "DJNZ $BFN"
                                                 # FIXME: untested - used in INVADE
                                                 make_block_fn "" "${ARGS}${!_BFN}"  # just a DJNZ
                                             fi
                                         else
                                             if ((jj==blockpc));then  # self-looping block
                                                 _P="${ACC[blockpc]// pc=+([0-9]);/}"  # block
                                                 # replace block with a loop
                                                 log_note $ipc "DJNZ WHILE LOOP"
                                                 append_to_block PC "while ((b-=1,b>0));do ${_P}done; pc=$opc"
                                             else
                                                 log_note $ipc "DJNZ NORMAL"
                                                 # FIXME: untested - used in INVADE and BASIC **
                                                 make_block_fn PC "${ARGS}${!_BFN}"
                                             fi
                                         fi;;
                                # DJNZ*) make_block_fn   PC          "${ARGS}${!_BFN}";;
                                   RST*) append_to_block PC "pushw $opc;${ARGS}pc=nn;";;  # custom code
                              LD?R|CP?R) make_block_fn   PC " pc=$opc;${ARGS}${!_BFN}";;
                                         #make_block_fn  PC " pc=$opc;${ARGS}${!_BFN}";;
                                      *) append_to_block PC " pc=$opc;${ARGS}${!_BFN}";;
                esac
            fi

        else  # switch modes to execute JIT'd instructions until we find a non-JIT'd one
            pc=ipc
            log_block $pc $pc "RUN FIRST"
            eval "${ACC[pc]}"
            while $_GO && ((MEM[pc]<0));do  # stop if no more jit
                log_block $pc $pc "RUN LOOP"
                eval "${ACC[pc]}"                # run jit'd driver and instruction
            done
            blockpc=pc                           # new block start
        fi
    done
    return 0
}

decode_normal(){
    local -i _apc; local _DRIVER
    blockpc=-1                                   # not using jit blocks
    $_VERBOSE && printf "DECODE (normal)...\n"
    while $_GO; do 
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
    while $_GO; do 
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
            #(( $INCr ))
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
            while $_GO && ((MEM[pc]<0));do  # stop if no more jit
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
            #  time ./pc-system80-1.bash FAST JIT BLOCK LOG "33 34 35 36" = 22s (18947 cycles/hr)
            #  time ./pc-system80-1.bash FAST JIT BLOCK LOG "33 34 35 36" = 22s (16363 cycles/hr) new INCrp
            #  time ./pc-system80-1.bash FAST JIT BLOCK LOG "33 34 35 36" = 22s (18000 cycles/hr) new INCRP
            #  time ./pc-system80-1.bash FAST JIT BLOCK LOG "33 34 35 36" = 21s (18000 cycles/hr) inline flags
            #  time ./pc-system80-1.bash FAST JIT BLOCK     "33 34 35 36" = 21s (20000 cycles/hr) inline flags
            #  time ./pc-system80-1.bash FAST JIT BLOCK LOG "33 34 35 36" = 20s (18947 cycles/hr) inline flags
            # bash 4.3 -Ofast
            #  time ./pc-system80-1.bash FAST JIT BLOCK LOG "33 34 35 36" = 19.7s (20000 cycles/hr) inline flags
            #  time ./pc-system80-1.bash FAST JIT BLOCK     "33 34 35 36" = 19.7s (20000 cycles/hr) inline flags
            #  time ./pc-system80-1.bash FAST JIT BLOCK LOG "33 34 35 36" = 19.7s (21176 cycles/hr) remove redundant flag sets
            decode_BLOCK  
        else
            #  time ./pc-system80-1.bash FAST JIT LOG "33 34 35 36" = 39s ( 9729 cycles/hr) 8307
            #  time ./pc-system80-1.bash FAST JIT     "33 34 35 36" = 30s (12857 cycles/hr)
            #  time ./pc-system80-1.bash FAST JIT LOG "33 34 35 36" = 39s ( 9729 cycles/hr) inline flags
            decode_JIT
        fi
    else
        #  time ./pc-system80-1.bash FAST LOG "33 34 35 36" = 42s ( 9000 cycles/hr)
        #  time ./pc-system80-1.bash FAST     "33 34 35 36" = 34s (11250 cycles/hr)
        #  time ./pc-system80-1.bash FAST LOG "33 34 35 36" = 43s ( 8571 cycles/hr)
        decode_normal
    fi
    return 0
}

# (( b=0,b?100:99 )) returns 99 (alternative)
# same as (( b=0,b==0?99:100 ))
# flag spec language: see comments
makesetf(){
    local _name=$1 _spec="$2" _flag _flags _PV; local -i _j _k=0xff _mask _fMask=0 _rMask=0 _RMask=0 _sMask=0 _aMask=0 _xMask=0 _f0=0
    printf "setf$_name(){ local -i n1=\$1 n2=\$2 re=\$3;((f="
    if ! $_ALL_FLAGS; then
        # 01234567
        # SZYHXPNC
        _spec="${_spec:0:2}X${_spec:3:1}X${_spec:5}"  # mask undocumented flags
    fi
    for (( _j=0; _j<8; _j++ )); do
        (( _mask=(1<<(7-_j)) ))
        _flag=${_spec:_j:1}
        case $_flag in
            .) _fMask+=_mask; ((_k^=_mask));;    # no change - keep existing flag value; record flag unchanged
            r) _rMask+=_mask;;                   # take value from result
            R) _RMask+=_mask;;                   # take value from high byte of result
            s) _sMask+=_mask;;                   # take value from n2
            a) _aMask+=_mask;;                   # take value from register A
            0) ;;                                # set flag value to 0
            1) (( _f0+=_mask ));;                # set flag value to 1
            p) _flags+="+PAR[re]";;              # lookup parity
            I) _flags+="+iff1";;                 # LD A,I
          x|X) _xMask+=_mask;;                   # 'randomise' these flags
        # z|Z) _flags+="+(re==0?$_mask:0)";;     # rarely a different bit works same as FZ. eg BIT and FP
          z|Z) _flags+="+(re?0:$_mask)";;        # rarely a different bit works same as FZ. eg BIT and FP
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
                       LDI*|LDD*|CPI*|CPD*) _flags+="+((b+c)?FP:0)";;
                                         *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                        esac;;
                   $FN) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                   $FC) case $_name in
                            ADD) _flags+="+(((n1+n2)       >> 8)   )";;
                            ADC) _flags+="+(((n1+n2+(f&FC))>> 8)   )";;
                     SUB|CP|NEG) _flags+="+(((n1-n2)       >> 8)&FC)";;
                            SBC) _flags+="+(((n1-n2-(f&FC))>> 8)&FC)";;
                          ADD16) _flags+="+(((n1+n2)       >>16)   )";;
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
    printf ",k=$_k)); return 0; } # _spec=%s\n" "$_spec"
}

# make string macro to set flags using n1 n2 and re variable names
# generally I have used consistent parameter names, but not always

# a new format to allow flag optimisation

makesetfs(){
    local _name=$1 _spec="$2" _n1="$3" _n2="$4" _re="$5" _flag _flags _PV _setf _t _fname _SUM _SET
    local -i _j _k=0xff _mask _fMask=0 _rMask=0 _RMask=0 _sMask=0 _aMask=0 _xMask=0 _f0=0
    _setf="(("                                   # start macro
    if ! $_ALL_FLAGS; then
        # 01234567
        # SZYHXPNC
        _spec="${_spec:0:2}X${_spec:3:1}X${_spec:5}"  # mask undocumented flags
    fi
    _SUM="f=+f7+f6+f5+f4+f3+f2+f1+f0+0"  # generic flag sum - no need to generate - keep initial + for now
    for (( _j=0; _j<8; _j++ )); do  # eg. _j=7
        (( _mask=(1<<_j) ))         # _mask=128
        _flag=${_spec:(7-_j):1}     # _flag=_spec:0:1
        _fname="f$_j"               # eg FS is f7
        _SET+="$_fname="
        case $_flag in
            .) (( _k^=_mask )); _SET+="f&$_mask";;  # no change - keep existing flag value; record unchanged flag
            r) _SET+="$_re&$_mask";;             # take value from result
            R) _SET+="($_re>>8)&$_mask";;        # take value from high byte of result
            s) _SET+="$_n2&$_mask";;             # take value from n2
            a) _SET+="a&$_mask";;                # take value from register A
            0) _SET+="0";;                       # set flag value to 0
            1) _SET+="$_mask";;                  # set flag value to 1
            p) _SET+="PAR[$_re]";;               # lookup parity
   # FIXME: I) _flags+="+iff1";;                 # LD A,I
          x|X) _SET+="0";;                       # randomise these flags
          z|Z) _SET+="($_re?0:$_mask)";;         # rarely a different bit works same as FZ. eg BIT and FP
            !) _SET+="(f&$_mask)^$_mask";;       # invert flag
         #  !) _SET+="f&$_mask?0:$_mask";;       # invert flag
          ^|v) case $_mask in                    # flag specific cases
                   $FS) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                   $FZ) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                  # $FY) case $_name in
                  #          LDI*|LDD*) _flags+="+((($_n2+$_re)&FN)<<4)";;
                  #        # CPI*|CPD*) _flags+="+((($_re-((($_n1^$_n2^$_re)&FH)>>4)))&1)";;
                  #                  *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                  #      esac;;
                   $FH) case $_name in
                    ADD|ADC|SUB|SBC|CP) _SET+="( ($_n1^$_n2^$_re)    &FH)";;
                                ADD16*) _SET+="((($_n1^$_n2^$_re)>>8)&FH)";;
                         ADC16*|SBC16*) _SET+="((($_n1^$_n2^$_re)>>8)&FH)";;
                               INC|DEC) _SET+="( ($_n1^$_re)         &FH)";;
                                   NEG) _SET+="( ($_n2^$_re)         &FH)";;
                             CPI*|CPD*) _SET+="( ($_n1^$_n2^$_re)    &FH)";;
                                     *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                        esac;;
                  # $FX) case $_name in
                  #          LDI*|LDD*) _flags+="+(($_n2+$_re)&FX)";;
                  #        # CPI*|CPD*) _flags+="+(($_re-((($_n1^$_n2^$_re)&FH)>>4))&FX)";;
                  #                  *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                  #      esac;;
                   $FP) case $_name in
                                   ADD|ADC) _SET+="((($_n1^~$_n2)&($_n1^$_re)&128)>>5)";;
                                SUB|SBC|CP) _SET+="((($_n1^ $_n2)&($_n1^$_re)&128)>>5)";;
                                       NEG) _SET+="($_n2==128?FP:0)";;
                                       INC) _SET+="($_n1==127?FP:0)";;
                                       DEC) _SET+="($_n1==128?FP:0)";;
                             ADD16*|ADC16*) _SET+="((($_n1^~$_n2)&($_n1^$_re)&32768)>>13)";;
                             SUB16*|SBC16*) _SET+="((($_n1^ $_n2)&($_n1^$_re)&32768)>>13)";;
                       LDI*|LDD*|CPI*|CPD*) _SET+="((b+c)?FP:0)";;
                                         *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                        esac;;
                   $FN) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                   $FC) case $_name in
                            ADD) _SET+="((($_n1+$_n2)       >> 8)   )";;
                            ADC) _SET+="((($_n1+$_n2+(f&FC))>> 8)   )";;
                     SUB|CP|NEG) _SET+="((($_n1-$_n2)       >> 8)&FC)";;
                            SBC) _SET+="((($_n1-$_n2-(f&FC))>> 8)&FC)";;
                         ADD16*) _SET+="((($_n1+$_n2)       >>16)   )";;
                         ADC16*) _SET+="((($_n1+$_n2+(f&FC))>>16)   )";;
                         SBC16*) _SET+="((($_n1-$_n2-(f&FC))>>16)&FC)";;
                              *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                        esac;;
                 # $FC) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
               esac;;
            *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
        esac
        _SET+=","
    done
    _setf+="k=$_k,"                              # put k in front
    _setf+="${_SET}${_SUM}"                       # make ((fs=x&128,fz=x?0:64,...,fc=1,f=+fs+fz+...+fc))
    _setf="${_setf// /}"                         # remove spaces
    _setf+="))"
    printf "acc_setf%s=\"%s\"\n" $_name "$_setf"  # print macro to file
}


makesetfs-org(){
    local _name=$1 _spec="$2" _n1="$3" _n2="$4" _re="$5" _flag _flags _PV _setf _t
    local -i _j _k=0xff _mask _fMask=0 _rMask=0 _RMask=0 _sMask=0 _aMask=0 _xMask=0 _f0=0
    _setf="((f="                                 # start macro
    if ! $_ALL_FLAGS; then
        # 01234567
        # SZYHXPNC
        _spec="${_spec:0:2}X${_spec:3:1}X${_spec:5}"  # mask undocumented flags
    fi
    for (( _j=0; _j<8; _j++ )); do
        (( _mask=(1<<(7-_j)) ))
        _flag=${_spec:_j:1}
        case $_flag in
            .) _fMask+=_mask; (( _k^=_mask ));;  # no change - keep existing flag value; record unchanged flag
            r) _rMask+=_mask;;                   # take value from result
            R) _RMask+=_mask;;                   # take value from high byte of result
            s) _sMask+=_mask;;                   # take value from n2
            a) _aMask+=_mask;;                   # take value from register A
            0) ;;                                # set flag value to 0
            1) (( _f0+=_mask ));;                # set flag value to 1
            p) _flags+="+PAR[$_re]";;            # lookup parity
            I) _flags+="+iff1";;                 # LD A,I
          x|X) _xMask+=_mask;;                   # randomise these flags
        # z|Z) _flags+="+($_re==0?$_mask:0)";;   # rarely a different bit works same as FZ. eg BIT and FP
          z|Z) _flags+="+($_re?0:$_mask)";;      # rarely a different bit works same as FZ. eg BIT and FP
            !) _flags+="+(f&$_mask)^$_mask";;    # invert flag
          ^|v) case $_mask in                    # flag specific cases
                   $FS) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                   $FZ) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                   $FY) case $_name in
                            LDI*|LDD*) _flags+="+((($_n2+$_re)&FN)<<4)";;
                          # CPI*|CPD*) _flags+="+((($_re-((($_n1^$_n2^$_re)&FH)>>4)))&1)";;
                                    *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                        esac;;
                   $FH) case $_name in
                    ADD|ADC|SUB|SBC|CP) _flags+="+( ($_n1^$_n2^$_re)    &FH)";;
                                ADD16*) _flags+="+((($_n1^$_n2^$_re)>>8)&FH)";;
                         ADC16*|SBC16*) _flags+="+((($_n1^$_n2^$_re)>>8)&FH)";;
                               INC|DEC) _flags+="+( ($_n1^$_re)         &FH)";;
                                   NEG) _flags+="+( ($_n2^$_re)         &FH)";;
                             CPI*|CPD*) _flags+="+( ($_n1^$_n2^$_re)    &FH)";;
                                     *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                        esac;;
                   $FX) case $_name in
                            LDI*|LDD*) _flags+="+(($_n2+$_re)&FX)";;
                          # CPI*|CPD*) _flags+="+(($_re-((($_n1^$_n2^$_re)&FH)>>4))&FX)";;
                                    *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                        esac;;
                   $FP) case $_name in
                                   ADD|ADC) _flags+="+((($_n1^~$_n2)&($_n1^$_re)&128)>>5)";;
                                SUB|SBC|CP) _flags+="+((($_n1^ $_n2)&($_n1^$_re)&128)>>5)";;
                                       NEG) _flags+="+($_n2==128?FP:0)";;
                                       INC) _flags+="+($_n1==127?FP:0)";;
                                       DEC) _flags+="+($_n1==128?FP:0)";;
                             ADD16*|ADC16*) _flags+="+((($_n1^~$_n2)&($_n1^$_re)&32768)>>13)";;
                             SUB16*|SBC16*) _flags+="+((($_n1^ $_n2)&($_n1^$_re)&32768)>>13)";;
                       LDI*|LDD*|CPI*|CPD*) _flags+="+((b+c)?FP:0)";;
                                         *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                        esac;;
                   $FN) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                   $FC) case $_name in
                            ADD) _flags+="+((($_n1+$_n2)       >> 8)   )";;
                            ADC) _flags+="+((($_n1+$_n2+(f&FC))>> 8)   )";;
                     SUB|CP|NEG) _flags+="+((($_n1-$_n2)       >> 8)&FC)";;
                            SBC) _flags+="+((($_n1-$_n2-(f&FC))>> 8)&FC)";;
                         ADD16*) _flags+="+((($_n1+$_n2)       >>16)   )";;
                         ADC16*) _flags+="+((($_n1+$_n2+(f&FC))>>16)   )";;
                         SBC16*) _flags+="+((($_n1-$_n2-(f&FC))>>16)&FC)";;
                              *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
                        esac;;
                 # $FC) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
               esac;;
            *) printf "ERROR: $FUNCNAME: ignored _flag=[%c]\n" "$_flag";;
        esac
    done
    (( _f0>0      )) && { printf -v _t "+%d"             $_f0;     _setf+="$_t"; }
    (( _fMask>0   )) && { printf -v _t "+(f&%d)"         $_fMask;  _setf+="$_t"; }
    (( _sMask>0   )) && { printf -v _t "+($_n2&%d)"      $_sMask;  _setf+="$_t"; }
    (( _rMask>0   )) && { printf -v _t "+($_re&%d)"      $_rMask;  _setf+="$_t"; }
    (( _RMask>0   )) && { printf -v _t "+(($_re>>8)&%d)" $_RMask;  _setf+="$_t"; }
    (( _aMask>0   )) && { printf -v _t "+(a&%d)"         $_aMask;  _setf+="$_t"; }
    [[ -n $_flags ]] && { printf -v _t "%s"             "$_flags"; _setf+="$_t"; }
    _setf+=",k=$_k))"                            # end macro
    _setf="${_setf/=+/=}"                        # remove =+
    _setf="${_setf// /}"                         # remove spaces
    printf "acc_setf%s=\"%s\"\n" $_name "$_setf"  # print macro to file
}



# set flags for re = n1 + n2, re is same register as n1
# flags S Z Y H X P N C
# bits 7(S) 5(Y) and 3(X) of re are copied into f. for add, N=0. for sub, N=1

$_VERBOSE && printf "MAKING INSTRUCTION FLAG FUNCTIONS...\n"

{
makesetf  ADD16   "..R^R.0^"
makesetfs ADD16   "..R^R.0^" rr nn mm
makesetfs ADD162  "..R^R.0^" rr2 rr mm
makesetfs ADD1622 "..R^R.0^" rr rr mm

makesetf  ADC16   "RZR^Rv0^"
makesetfs ADC16   "RZR^Rv0^" rr nn mm
makesetfs ADC162  "RZR^Rv0^" rr2 rr mm
makesetfs ADC1622 "RZR^Rv0^" rr rr mm

makesetf  SBC16   "RZR^Rv1^"                      # was "^Z^^^v0-"
makesetfs SBC16   "RZR^Rv1^" rr nn mm
makesetfs SBC162  "RZR^Rv1^" rr2 rr mm
makesetfs SBC1622 "RZR^Rv1^" rr rr mm

makesetf  ADD   "rZr^rv0^"
makesetfs ADD   "rZr^rv0^" a n m
makesetf  ADC   "rZr^rv0^"
makesetfs ADC   "rZr^rv0^" a n m

makesetf  SUB   "rZr^rv1^"
makesetfs SUB   "rZr^rv1^" a n m
makesetf  SBC   "rZr^rv1^"
makesetfs SBC   "rZr^rv1^" a n m
makesetf  NEG   "rZr^rv1^"
makesetfs NEG   "rZr^rv1^" a n m

makesetf  CP    "rZs^sv1^"
makesetfs CP    "rZs^sv1^" a n m

makesetf  INC   "rZr^rv0."
makesetfs INC   "rZr^rv0." n 1 m

makesetf  DEC   "rZr^rv1."
makesetfs DEC   "rZr^rv1." n 1 m

makesetf  AND   "rZr1rp00"                       # FIXME: why?
makesetfs AND   "rZr1rp00" a n m

makesetf  XOR   "rZr0rp00"
makesetfs XOR   "rZr0rp00" a n m
makesetf   OR   "rZr0rp00"
makesetfs  OR   "rZr0rp00" a n m

makesetf  ROTa  "..r0r.0s"
makesetfs ROTa  "..r0r.0s" 0 m a

makesetf  ROTr  "rZr0rp0s"
makesetfs ROTr  "rZr0rp0s" 0 m n

makesetf RLD   "rZr0rp0."
makesetf CCF   "..asa.0!"
makesetf SCF   "..a0a.01"
makesetf CPL   "..r1r.1."
makesetf BIT   "rZr1rp0."
makesetf BITx  "rZs1sp0."                        # more correct version
makesetf BITh  "rZs1sp0."                        # [SY05] don't know where FY or FX come from - assume h parsed as n2
makesetf DAA   "rZrsrp.s"

makesetf  LDI   "..^0^^0."                       # BC=0 -> FP=0 else FP=1
makesetfs LDI   "..^0^^0." 0 a n
makesetf  LDIR  "..^0^00." 
makesetfs LDIR  "..^0^00." 0 a n

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
. $GEN
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
    -e 's/^(acc_setf[a-zA-Z0-9]+=)/\/\/ \1/g     # comment acc_setfXXX strings'  \
    -e 's/^setf([^() ]+)[(][)][^;]+;/void setf\1(int n1, int n2, int re){ /g  # convert setf fns to c fns'  \
    -e 's/^([^#]+[(][)])/void \1/g               # prefix functions with void'  \
    -e 's/return 0;//g                           # delete return 0;'  \
    -e 's/while +([^;]+);do/while \1{/g          # while X;do -> while X{'  \
    -e  's/done;/}/g                             # done; -> }'  \
    -e 's/;then/{/g                              # ;then -> {'  \
    -e 's/else[ ]+fi;/fi;/g                      # replace else fi; with fi;'  \
    -e  's/else[ ]+/} else {/g                   # else -> } else {'  \
    -e  's/fi;/}/g                               # fi; -> }'  \
    -e 's/[ ;]*\#(.*)$/; \/\*\1\*\//g            # replace ;# comments with /* comment */'  \
    -e 's/([ ;])r(D|R|PCD|jjcc|Djjcc|n|m|nn|pc|mm);/\1r\2();/g  # convert rX; -> rX();'  \
    -e 's/([ ;])ldrn([a-fhlxXyY]);/\1ldrn\2();/g  # convert ldrnX; -> ldrnX();'  \
    -e 's/([ ;])ldrpnn([a-fhlxXyY]+);/\1ldrpnn\2();/g  # convert ldrpnnXX; -> ldrpnnXX();'  \
    -e 's/;ARGS[+]=".*";/;/g                     # remove ARGS+="...";'  \
    -e      's/pop([^() ;]+);/pop\1();/g         # convert popX; -> popX();'  \
    -e          's/pushpcnn;/pushpcnn();/g       # convert pushpcnn; -> pushpcnn();'  \
    -e     's/push([^() ]+) +([^ ;]+);/push\1(\2);/g  # convert pushX Y; -> pushX(Y);'  \
    -e     's/setf([^() ]+) +([^ ]+) ([^ ]+) ([^ ;]+);/setf\1(\2,\3,\4);/g' \
    -e               's/wb2 +([^ ]+) ([^ ]+) ([^ ;]+);/wb2(\1,\2,\3);/g' \
    -e                's/wb +([^ ]+) ([^ ;]+);/wb(\1,\2);/g' \
    -e                's/ww +([^ ]+) ([^ ;]+);/ww(\1,\2);/g' \
    -e                's/wp +([^ ]+) ([^ ;]+);/wp(\1,\2);/g' \
    -e          's/memprotb +([^ ]+) ([^ ;]+);/memprotb(\1,\2);/g'  \
    -e          's/memprotw +([^ ]+) ([^ ;]+);/memprotw(\1,\2);/g'  \
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
    -e 's/<local>int/int/g                       # rename to int'  \
    -e 's/([^ ;])[ ]*$/\1;/g                     # ?<space>$ -> ?$ '

    
make_cArray IS FN
make_cArray IS CHARP
make_cArray CB FN
make_cArray CB CHARP
make_cArray DD FN
make_cArray DD CHARP
make_cArray DDCB FN
make_cArray DDCB CHARP
make_cArray ED FN
make_cArray ED CHARP
make_cArray FD FN
make_cArray FD CHARP
make_cArray FDCB FN
make_cArray FDCB CHARP

} >> $cGEN

#    -e 's/^([^#]+[(][)])/void \1/g               # prefix functions with void'  \
#    -e 's/^([^#]+)[(][)][{]/void \1(){ printf("%s\\n", "\1");/g               # prefix functions with void'  \

$_ACCEL_2  && . pc-generate-accel-2.bash
$_ACCEL_2  && . pc-generate-accel-2-inline.bash

$_VERBOSE && printf "LOADING INSTRUCTION SET FUNCTIONS...\n"

. $GEN                                           # load manufactured functions



asm @0x0066 EI RETN                              # install NMI ISR for testing


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
    #f=0x00  # FIXME: how to allow this to be random????????
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
    #printf "nn=%04x\n" $nn
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
    $pass && printf "PASS: Results, unless ignored, are as expected\n"
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

    test_cycle "a f" "((m=a,n=a+a+(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC+((m^m^n)&FH))) XP NN" @0 ADCr_a
    test_cycle "b f" "((m=a,n=a+b+(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC+((m^b^n)&FH))) XP NN" @0 ADCr_b
    test_cycle "c f" "((m=a,n=a+c+(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC+((m^c^n)&FH))) XP NN" @0 ADCr_c
    test_cycle "d f" "((m=a,n=a+d+(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC+((m^d^n)&FH))) XP NN" @0 ADCr_d
    test_cycle "e f" "((m=a,n=a+e+(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC+((m^e^n)&FH))) XP NN" @0 ADCr_e
    test_cycle "h f" "((m=a,n=a+h+(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC+((m^h^n)&FH))) XP NN" @0 ADCr_h
    test_cycle "l f" "((m=a,n=a+l+(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC+((m^l^n)&FH))) XP NN" @0 ADCr_l

    #exit 1

    test_cycle "a f" "((m=a,n=a+a,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC+((m^m^n)&FH))) XP NN" @0 ADDr_a
    test_cycle "b f" "((m=a,n=a+b,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC+((m^b^n)&FH))) XP NN" @0 ADDr_b
    test_cycle "c f" "((m=a,n=a+c,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC+((m^c^n)&FH))) XP NN" @0 ADDr_c
    test_cycle "d f" "((m=a,n=a+d,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC+((m^d^n)&FH))) XP NN" @0 ADDr_d
    test_cycle "e f" "((m=a,n=a+e,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC+((m^e^n)&FH))) XP NN" @0 ADDr_e
    test_cycle "h f" "((m=a,n=a+h,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC+((m^h^n)&FH))) XP NN" @0 ADDr_h
    test_cycle "l f" "((m=a,n=a+l,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n>0xff)*FC+((m^l^n)&FH))) XP NN" @0 ADDr_l

    #exit 1

    
    test_cycle "a f" "((n=a&a,a=n))" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) H NN NC"      @0 ANDr_a
    test_cycle "b f" "((n=a&b,a=n))" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) H NN NC"      @0 ANDr_b
    test_cycle "c f" "((n=a&c,a=n))" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) H NN NC"      @0 ANDr_c
    test_cycle "d f" "((n=a&d,a=n))" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) H NN NC"      @0 ANDr_d
    test_cycle "e f" "((n=a&e,a=n))" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) H NN NC"      @0 ANDr_e
    test_cycle "h f" "((n=a&h,a=n))" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) H NN NC"      @0 ANDr_h
    test_cycle "l f" "((n=a&l,a=n))" "((f|=(a&FS)|(a==0)*FZ|PAR[a])) H NN NC"      @0 ANDr_l

    exit 1

    test_cycle "a" "((n=a-a-(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SBCr_a
    test_cycle "b" "((n=a-b-(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SBCr_b
    test_cycle "c" "((n=a-c-(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SBCr_c
    test_cycle "d" "((n=a-d-(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SBCr_d
    test_cycle "e" "((n=a-e-(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SBCr_e
    test_cycle "h" "((n=a-h-(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SBCr_h
    test_cycle "l" "((n=a-l-(f&FC),a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SBCr_l

    #exit 1

    test_cycle "a" "((n=a-a,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SUBr_a
    test_cycle "b" "((n=a-b,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SUBr_b
    test_cycle "c" "((n=a-c,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SUBr_c
    test_cycle "d" "((n=a-d,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SUBr_d
    test_cycle "e" "((n=a-e,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SUBr_e
    test_cycle "h" "((n=a-h,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SUBr_h
    test_cycle "l" "((n=a-l,a=n&255))" "((f|=(a&FS)|(a==0)*FZ|(n<0)*FC)) XH XP N"      @0 SUBr_l

    #exit 1

    test_cycle "a"   "((n=a+1,a=n&255))" "((f|=(a&FS)|(a==0)*FZ)) XH XP NN"      @0 INCr_a
    test_cycle "b"   "((n=b+1,b=n&255))" "((f|=(b&FS)|(b==0)*FZ)) XH XP NN"      @0 INCr_b
    test_cycle "c"   "((n=c+1,c=n&255))" "((f|=(c&FS)|(c==0)*FZ)) XH XP NN"      @0 INCr_c
    test_cycle "d"   "((n=d+1,d=n&255))" "((f|=(d&FS)|(d==0)*FZ)) XH XP NN"      @0 INCr_d
    test_cycle "e"   "((n=e+1,e=n&255))" "((f|=(e&FS)|(e==0)*FZ)) XH XP NN"      @0 INCr_e
    test_cycle "h"   "((n=h+1,h=n&255))" "((f|=(h&FS)|(h==0)*FZ)) XH XP NN"      @0 INCr_h
    test_cycle "l"   "((n=l+1,l=n&255))" "((f|=(l&FS)|(l==0)*FZ)) XH XP NN"      @0 INCr_l

    #exit 1

    test_cycle "a"   "((n=a-1,a=n&255))" "((f|=(a&FS)|(a==0)*FZ)) XH XP N XC"      @0 DECr_a
    test_cycle "b"   "((n=b-1,b=n&255))" "((f|=(b&FS)|(b==0)*FZ)) XH XP N XC"      @0 DECr_b
    test_cycle "c"   "((n=c-1,c=n&255))" "((f|=(c&FS)|(c==0)*FZ)) XH XP N XC"      @0 DECr_c
    test_cycle "d"   "((n=d-1,d=n&255))" "((f|=(d&FS)|(d==0)*FZ)) XH XP N XC"      @0 DECr_d
    test_cycle "e"   "((n=e-1,e=n&255))" "((f|=(e&FS)|(e==0)*FZ)) XH XP N XC"      @0 DECr_e
    test_cycle "h"   "((n=h-1,h=n&255))" "((f|=(h&FS)|(h==0)*FZ)) XH XP N XC"      @0 DECr_h
    test_cycle "l"   "((n=l-1,l=n&255))" "((f|=(l&FS)|(l==0)*FZ)) XH XP N XC"      @0 DECr_l

    #exit 1


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

#test
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
#zexdoc "$1"

#gcc pc-z80-4.c 2>&1 | head -n 10                 # compile c version
#exit 0

# system
# INVADE
# /


system80(){
    $_VERBOSE && printf "EMULATE SYSTEM-80\n"
    . system80-interface.bash
    load 0x0000 "system_80_rom"
    sleep 0.5
    clear
    reset
    printf "\n\nTerminated\n"
}

system80


