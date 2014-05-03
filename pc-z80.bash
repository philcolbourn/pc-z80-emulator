#!/bin/bash

declare -i A B C D E F H L a b c d e f h l IX IY PC SP IPC  # registers in uppercase
declare -i S states=0 M cycles=0  # machine cycles and state counters
declare -i fC fN fP fX fH fY fZ fS # flag names are prefixed by f
declare -i fc fn fp fx fh fy fz fs # flag names are prefixed by f
declare -ia MEM # F F1
#declare -a REG REG1  # map register number to name
declare -a OUT IN
declare -a TRAP
declare -a FLAG_NAMES=( C N P X H Y Z S )
declare -a cc=( NZ Z NC C PO PE P M )  # map flag number to flag name
declare -a qR=( B C D E H L "(HL)" A )  # map register number to register name
declare -a R=( B C D E H L "MEM[H*256+L]" A )  # map register number to register name
declare -a qRP=( BC DE HL SP )  # map register pair number to register pair ame
declare -a sRP=( "B*256+C" "D*256+E" "H*256+L" SP )  # map register pair number to register pair ame
declare -a dRP=( "B=nn/256&255; C=nn%256" "D*256+E" "H*256+L" SP )  # map register pair number to register pair ame
#rpH=( B D H )
#declare -a rp2=( BC DE HL AF )

function make_FLAGS() { (( F = fS*128 + fZ*64 + fY*32 + fH*16 + fX*8 + fP*4 + fN*2 + fC )); }
function make_flags() { (( f = fs*128 + fz*64 + fy*32 + fh*16 + fx*8 + fp*4 + fn*2 + fc )); }
function set_FLAGS()   { 
    (( fS=F>>7 )); (( fZ=F>>6&1 )); (( fY=(F>>5)&1 )); (( fH=(F>>4)&1 )); (( fX=(F>>3)&1 )); (( fP=(F>>2)&1 )); (( fN=(F>>1)&1 )); (( fC=F&1 )); }
function set_flags()  { 
    (( fs=f>>7 )); (( fz=f>>6&1 )); (( fy=(f>>5)&1 )); (( fh=(f>>4)&1 )); (( fx=(f>>3)&1 )); (( fp=(f>>2)&1 )); (( fn=(f>>1)&1 )); (( fc=f&1 )); }
function get_FLAGS() {
    local t=
    (( fS )) && t+=S || t+=" "
    (( fZ )) && t+=Z || t+=" "
    (( fY )) && t+=Y || t+=" "
    (( fH )) && t+=H || t+=" "
    (( fX )) && t+=X || t+=" "
    (( fP )) && t+=P || t+=" "
    (( fN )) && t+=N || t+=" "
    (( fC )) && t+=C || t+=" "
    RET="$t"
}
function EXFf() {
    local -i t
    t=fS; fS=fs; fs=t
    t=fZ; fZ=fz; fz=t
    t=fY; fY=fy; fy=t
    t=fH; fH=fh; fh=t
    t=fX; fX=fx; fx=t
    t=fP; fP=fp; fp=t
    t=fN; fN=fn; fn=t
    t=fC; fC=fc; fc=t
}
#SF=$(( 1 << 7 ))                                 # sign
#ZF=$(( 1 << 6 ))                                 # zero
                                                 # F bit 5 not used
#HF=$(( 1 << 4 ))                                 # half carry
                                                 # F bit 3 not used
#PF=$(( 1 << 2 ))                                 # parity/overflow
#NF=$(( 1 << 1 ))                                 # add/sub
#CF=$(( 1 << 0 ))                                 # carry

# Traps execute a bash function at a defined address, then continue execution if trap returns.

TRAP[1]="testtrap"
TRAP[50]="exitemu"

function testtrap() {
    printf "TRAP: $FUNCNAME: Trapped.\n"
}

function exitemu() {
    printf "TRAP: $FUNCNAME: Exit\n"
    exit 0
}

_DIS=true


function dis() {
    local op=$1 args="$2" inst temp flags; local -i pc
    $_DIS || return 0
    get_FLAGS; flags="$RET"
    printf "%6d: [%8s] %4x " $states "$flags" $IPC
    for (( pc=IPC ; pc<PC ; pc++ )); do
        printf -v temp "%02x" $(( MEM[pc] & 0xff ))
        inst+=$temp
    done
    printf "[%8s]  %-5s %-10s;  %d kHz\n" "$inst" $op "$args" $(( states/SECONDS/1000 ))
}
# LD RP,nn -> ldReg RP nn
function ldReg() {
    local r=$1; local -i n=$2 p
    case $r in
            AF) F=n%256; A=n/256;;
            BC) C=n%256; B=n/256;;
            DE) E=n%256; D=n/256;;
            HL) L=n%256; H=n/256;;
            SP) SP=n;;
        '(HL)') p=256*H+L; MEM[p]=n%256; MEM[p]=n/256;;
             *) eval "$r=$n"
    esac
}
# local variables in lowercase
# uppercase variables for CPU registers
# 
# LD r[1],n
function LDr() {
    local -i r=$1 n=$2
    dis LD "${qR[r]}, $n"
    let ${R[r]}=n
}
# LD rp[1],nn
function LDrp() {
    local -i rp=$1 nn=$2
    dis LD "${qRP[rp]}, $nn"
    eval ${dRP[rp]}
}

function ADDHLrp() { # 11s
    local -i r=$1 t; local p=${rp[r]}
    dis ADD "HL,$p"
    t=H*256+L+${sRP[r]}
    (( H=t/256&255 ))
    L=t%256
    fC=t/65536
    #(( HF=t&0x4000 )) # carry out of bit 11 into bit 12
    fN=0
    M=3
    S=12
}

function INCrp() {
    local -i r=$1; local p=${qRP[r]}
    dis INC "$p"
    let nn=${sRP[r]}+1
    eval ${dRP[r]}
    case $p in
        BC) t=B*256+C+1; (( B=t/256&255 )); C=t%256;; 
        DE) t=D*256+E+1; (( D=t/256&255 )); E=t%256;; 
        HL) t=H*256+L+1; (( H=t/256&255 )); L=t%256;; 
        SP) t=SP+1; SP=t%65536;; 
    esac
    M=1
    S=6
}
function DECrp() {
    local -i r=$1; local p=${rp[r]}
    dis INC "$p"
    case $p in
        BC) t=B*256+C-1; (( B=t/256&255 )); C=t%256;; 
        DE) t=D*256+E-1; (( D=t/256&255 )); E=t%256;; 
        HL) t=H*256+L-1; (( H=t/256&255 )); L=t%256;; 
        SP) t=SP-1; SP=t%65536;; 
    esac
    M=1
    S=6
}
function INCr() {
    local -i r=$1; local p=${rr[r]}
    dis INC "$p"
    eval "fP=$p==127" #P/V is set if r was 7FH before operation; reset otherwise
    eval "(( $p++ ))"
    eval "fS=$p==256" #S is set if result is negative; reset otherwise
    eval "fZ=$p==0"  #Z is set if result is zero; reset otherwise
    #H is set if carry from bit 3; reset otherwise
    fN=0  #N is reset
    #C is not affected
    eval "(( $p&=255 ))"
    M=1
    S=6
}

function decode() {
    local -i i x y z p q disp t n nn
    $_DIS && printf "%6s: [%8s] %4s [%8s]  %-16s;  %s\n" STATES FLAGS ADDR HEX INSTRUCTION RATE
    while :; do
        IPC=PC                                   # save PC for display
        [[ -n ${TRAP[PC]} ]] && { dis TRAP; eval "${TRAP[PC]}"; } 
        i=MEM[PC]                                # get first instruction opcode
        (( i>255 )) && { dis END; return 0; }  # invalid memory content so return
        PC+=1
        (( x = i              >> 6 ))
        (( y = (i & 2#00111000) >> 3 ))
        (( z = i & 2#00000111      ))
        case $x in
            0) case $z in
                   0) case $y in
                          0) dis NOP; M=1; S=4;;
                          1) dis EX "AF,AF'"; t=A; A=a; a=t; EXFf; M=1; S=4;;
                          2) disp=MEM[PC++]; dis DJNZ $disp; M=2; S=8; (( --B )) && { PC+=disp; M+=1; S+=5; };;
                          3) disp=MEM[PC++]; dis JR $disp; PC+=disp; M=3; S=12;;
                          *) disp=MEM[PC++]; dis JR "${cc[y-4]} $disp"; M=2; S=7
                             case $(( y-4 )) in
                                 0) (( fS )) || { PC+=disp; M+=1; S+=5; };;
                                 1) (( fS )) && { PC+=disp; M+=1; S+=5; };;
                                 2) (( fC )) || { PC+=disp; M+=1; S+=5; };;
                                 3) (( fC )) && { PC+=disp; M+=1; S+=5; };;
                             esac;;
                      esac;;
                   1) q=$((  y & 2#001       ))
                      p=$(( (y & 2#110) >> 1 ))
                      case $q in
                          0) n1=MEM[PC++]; n2=MEM[PC++]; nn=n1+256*n2; LDrp $p $nn;;
                          *) ADDHLrp $p;;
                      esac;;
                   2) q=$((  y & 2#001       ))
                      p=$(( (y & 2#110) >> 1 ))
                      case $q in
                          0) case $p in
                                 0) dis LD "(BC), A"; MEM[B*256+C]=A; M=1; S=7;;
                                 1) dis LD "(DE), A"; MEM[D*256+E]=A; M=1; S=7;;
                                 2) n1=MEM[PC++]; n2=MEM[PC++]; nn=n1+256*n2; dis LD "($nn), HL"; MEM[nn]=L; MEM[nn+1]=H; M=2; S=12;;
                                 *) n1=MEM[PC++]; n2=MEM[PC++]; nn=n1+256*n2; dis LD "($nn), A"; MEM[nn]=A; M=2; S=12;;
                             esac;;
                          *) case $p in
                                 0) dis LD "A, (BC)"; A=MEM[B*256+C]; M=1; S=7;;
                                 1) dis LD "A, (DE)"; A=MEM[D*256+E]; M=1; S=7;;
                                 2) n1=MEM[PC++]; n2=MEM[PC++]; nn=n1+256*n2; dis LD "HL, ($nn)"; L=MEM[nn]; H=MEM[nn+1]; M=2; S=12;;
                                 *) n1=MEM[PC++]; n2=MEM[PC++]; nn=n1+256*n2; dis LD "A, ($nn)"; A=MEM[nn]; M=2; S=12;;
                             esac;;
                      esac;;
                   3) q=$((  y & 2#001       ))
                      p=$(( (y & 2#110) >> 1 ))
                      case $q in
                          0) INCrp $p;;
                          *) DECrp $p;;
                      esac;;
                   4) INCr $y;;
                   5) DECr $y;;
                   *) printf "ERROR: $FUNCNAME: Unknown operation code class: i=%x x=%x z=%x\n" $i $x $z; exit 1;;
               esac;;
            1) echo LD;;
            2) echo BB;;
            3) echo CC;;
            *) printf "ERROR: $FUNCNAME: Unknown operation code class: i=%x x=%x\n" $i $x; exit 1;;
        esac
        set +x
        states+=S
        cycles+=M
    done
    printf "ERROR: $FUNCNAME: Exitted loop\n"
}

function reset() {
    printf "Reset CPU\n"
    SECONDS=1  # hack to eliminate division/0
    states=0
    cycles=0
    PC=0  # FIXME: should reset registers too, but this makes testing hard
    # FIXME: SP=
    decode
}
function dump() {
    local -i pc
    for pc in ${!MEM[*]}; do
        printf "%4x  %2x %d\n" $pc ${MEM[pc-1]} $(( MEM[pc-1]>127 ? MEM[pc-1]-256 : MEM[pc-1] )) 
    done
}
function load() {
    MEM=( $( od -An -tu1 -v -w16 system_80_rom ) )
    dump
    return 0
    local -i V pc=0
    IFS=
    #X=$( od -An -td1 -w1 system_80_rom )
    while read -d'' -r -N1 V; do
        MEM[pc++]=X&255
        printf "%4x  %2x %c\n" $pc ${MEM[pc-1]} ${MEM[pc-1]}  
    done < <( $( od -An -td1 -v -w16 system_80_rom ) )
    unset IFS
}

function assert() {
    local var=$1 val=$2
    if [ ${!var} -eq $val ]; then
        printf "PASS: $FUNCNAME: %s = %x(%d)\n" $var $val $val
        return 0
    fi
    printf "ERROR: $FUNCNAME: %s != %x(%d); %s = %x(%d)\n" $var $val $val $var ${!var} ${!var}
    exit 1
}
function assertMEM() {
    local var=$1 val=$2
    if [ ${MEM[var]} -eq $val ]; then
        printf "PASS: $FUNCNAME: MEM[%s] = %x(%d)\n" $var $val $val
        return 0
    fi
    printf "ERROR: $FUNCNAME: MEM[%s] != %x(%d); MEM[%s] = %x(%d)\n" $var $val $val $var ${MEM[var]} ${MEM[var]}
    exit 1
}

NOP=0
END=256  # anything bigger than 255. 256 works well for dis too

DJNZ=2#00010000
B=255
assert B 255
MEM=( $DJNZ -2 $END )
reset
assert B 0
assert PC 2
assert states $(( 254*13+8 ))

EXAF=2#00001000
A=55; F=176; set_FLAGS
a=0; f=255; set_flags
assert A 55; assert F 176
assert a 0; assert f 255
MEM=( $EXAF $END )
reset
echo $A $F $a $f
assert A 0; make_FLAGS; assert F 255
assert a 55; make_flags; assert f 176
assert PC 1
assert states $(( 4 ))

JR=2#00011000
MEM=( $JR 2 $JR -4 $END )
reset
assert PC 4
assert states $(( 12 ))

JRNZ=2#00100000
JRZ=2#00101000
JRNC=2#00110000
JRC=2#00111000
fZ=1
MEM=( $JRZ 2 $JR -4 $END )
reset
assert PC 4
assert states $(( 12 ))

LDBCnn=2#00000001
B=0; C=0; assert B 0; assert C 0
MEM=( $LDBCnn 34 12 $END )
reset
assert B 12; assert C 34
assert PC 3
assert states $(( 12 ))

ADDHLrp=2#00001001
B=1; C=2; assert B 1; assert C 2
H=10; L=20; assert H 10; assert L 20
MEM=( $ADDHLrp $END )
reset
assert H 11; assert L 22
assert PC 1
assert states $(( 12 ))

LDnnHL=2#00100010
H=99; L=55
MEM=( $LDnnHL 1 0 $END )
reset
assert MEM[1] 55; assertMEM 2 99
assert PC 3
assert states $(( 12 ))

INCHL=2#00100011
H=255; L=255
MEM=( $INCHL $END )
reset
assert H 0; assert L 0; assert fC 0

INCB=2#00000100
B=0
MEM=( $INCB $END )
reset
assert B 1
B=127
MEM=( $INCB $END )
reset
assert B 128
assert fP 1

exit 0

load
reset

exit 0

MEM=( $_NOP 0x20 0x40 $_DJNZ -2 0x00 0 0x00)
reset

