#!/bin/bash

SECONDS=1

declare -i a b c d e f h l f sp pc i r m t ime
declare -i n nn  # used for holding 8bit and 16bit values
declare -i ipc  # holds pc of current instruction - used for displaying
declare -i cycles states halt stop
declare -i MEM
declare -a OUT IN
declare -a TRAP

declare -a R=( B C D E H L "(HL)" A )
declare -a FLAG_NAMES=( C N P X H Y Z S )
declare -i FS=0x80 FZ=0x40 FY=0x20 FH=0x10 FX=0x08 FP=0x04 FN=0x02 FC=0x01  

declare -a CHR=( 
    [32]=" " "!" "\"" "#" "$" "%" "&" "'" "(" ")" "*" "+" "," "-" "." "/" 
    [48]=0 1 2 3 4 5 6 7 8 9 [58]= ":" ";" "<" "=" ">" "?" 
    [64]="@" A B C D E F G H I J K L M N O P Q R S T U V W X Y Z "[" "\\" "]" "^" "_"
    [96]="\`" a b c d e f g h i j k l m n o p q r s t u v w x y z "{" "|" "}" "~"
)

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

LDHLmn() { nn=h*256+l; rn; dis LD "(HL=%04x),%02x" $nn $n; wb $nn $n; m=3; t=12; }

LDBCmA() { nn=b*256+c; dis LD "(BC=%04x),A(%02x)" $nn $a; wb $nn $a; m=2; t=8; }
LDDEmA() { nn=d*256+e; dis LD "(DE=%04x),A(%02x)" $nn $a; wb $nn $a; m=2; t=8; }

LDmmA() { rnn; rb $nn; dis LD "%04x(%02x),A(%02x)" $nn $n $a; wb $nn $a; m=4; t=16; }

LDABCm() { rb $(( b*256+c )); a=n; m=2; t=8; }
LDADEm() { rb $(( d*256+e )); a=n; m=2; t=8; }

LDAmm() { rnn; rb $nn; a=n; m=4; t=16; }

#LDDEnn() { rn; e=n; rn; d=n; m=3; t=12; }
#LDHLnn() { rn; l=n; rn; h=n; m=3; t=12; }
LDSPnn() { rnn; (( sp=nn, m=3, t=12 )); }


# /*--- Jump ---*/
JPnn()   { rnn; dis JP   "%04x" $nn;          (( pc=nn, m=3, t=12 )); }
CALLnn() { rnn; dis CALL "%04x" $nn; pushnn $pc; (( pc=nn, m=5, t=17 )); }
JPHL()   { (( pc=h*256+l, m=1, t=4 )); dis JP "HL=%04x" $pc; }
JRn()    { rn; assertb n; (( (n>127)?n-=256:0 )); dis JR   "%d(%04x)" $n $(( pc+n )); (( m=3, t=12, pc+=n )); }
RET()    { popnn; dis RET  "[%04x]" $nn; pc=nn; m=3; t=12; };
RETI()   { popnn; dis RETI "[%04x]" $nn; pc=nn; m=3; t=12; ime=1; };

for g in Z C; do
    printf "JPN${g}nn()   { rnn; dis JP   \"N$g,%%04x\" \$nn; (( m=3, t=7, (f&F$g)?0:(pc=nn, m+=1, t+=5) )); }\n"
    printf "JP${g}nn()    { rnn; dis JP   \" $g,%%04x\" \$nn; (( m=3, t=7, (f&F$g)?(pc=nn, m+=1, t+=5):0 )); }\n"
    printf "CALLN${g}nn() { rnn; dis CALL \"N$g,%%04x\" \$nn; (( m=3, t=10 )); (( f&F$g )) && { pushnn \$pc; pc=nn; m+=1; t+=7; }; }\n"
    printf "CALL${g}nn()  { rnn; dis CALL \" $g,%%04x\" \$nn; (( m=3, t=10 )); (( f&F$g )) || { pushnn \$pc; pc=nn; m+=1; t+=7; }; }\n"
    printf "RETN$g()      { dis RET       \"N$g [%%04x]\" \$nn; (( m=1, t=5 )); (( f&F$g )) && { popnn; pc=nn; m+=2; t+=6; }; }\n"
    printf "RET$g()       { dis RET       \" $g [%%04x]\" \$nn; (( m=1, t=5 )); (( f&F$g )) || { popnn; pc=nn; m+=2; t+=6; }; }\n"
    printf "JRN${g}n()    { rn; assertb n; (( (n>127)?n-=256:0 )); dis JRN$g \"%%d(%%04x)\" \$n \$(( pc+n )); (( m=2, t=7, (f&F$g)?0:(pc+=n,m+=1,t+=5) )); }\n"
    printf "JR${g}n()     { rn; assertb n; (( (n>127)?n-=256:0 )); dis JR$g  \"%%d(%%04x)\" \$n \$(( pc+n )); (( m=2, t=7, (f&F$g)?(pc+=n,m+=1,t+=5):0 )); }\n"
done > JP.bash
. JP.bash


testsign() {
    local -i j pv=-1 v=0
    for (( j=0 ; j<256 ; j++ )); do
        pv=v
        (( v=j, v>127 ? v=-(((~v)&255)+1) : 0 ))
        (( v0=j, v0>127 ? v0-=256 : 0 ))
        (( v==v0 )) && printf "PASS: " || printf "FAIL: " && printf "j=%02x -> %02x(%4d)  %02x(%4d)\n" $j $v $v $v0 $v0
    done
}
#testsign; exit 0


#DJNZn() { rb $pc; assertb n; (( n>127 ? n-=256 : 0 )); pc+=1; dis DJNZ "%d(%04x) ; B=%02x" $n $(( pc+n )) $b; m=2; t=8; (( --b )) && { pc+=n; m+=1; t+=5; }; }
DJNZn() { rn; assertb n; (( (n>127)?n-=256:0 )); dis DJNZ "%d(%04x) ; B=%02x" $n $(( pc+n )) $b; (( (--b)?(pc+=n,m=3,t=13):(m=2,t=8) )); }
NOP()  { dis NOP;  m=1; t=4; }
HALT() { dis HALT; m=1; t=4; halt=1; }
DI()   { dis DI;   m=1; t=4; ime=0; }
EI()   { dis EI;   m=1; t=4; ime=1; }

XX() {
    local inst
    rb $(( pc-1 ))
    for (( c=0 ; c<6; c++ )); do inst+="${MEM[pc-1+c]} "; done
    printf "ERROR: $FUNCNAME: Unknown operation code [%x %x %x %x %x %x] at %4x(%5d)\n" $inst $(( pc-1 ))
    stop=1
    exit 1
}
CBXX() {
    local inst
    rb $(( pc-1 ))
    for (( c=0 ; c<6; c++ )); do inst+="${MEM[pc-1+c]} "; done
    printf "ERROR: $FUNCNAME: Unknown CB operation code [%x %x %x %x %x %x] at %4x(%5d)\n" $inst $(( pc-1 ))
    stop=1
    exit 1
}

wp() {
    local -i p=$1 v=$2
    [[ -z ${OUT[p]} ]] && { OUT[p]=$p.out; printf "WARNING: $FUNCNAME: Port $p mapped to [%s]\n" ${OUT[p]}; }
    printf "%c" ${CHR[v]} >> ${OUT[p]}
}

OUTnA() { rn; dis OUT "[%02x],A(%02x)" $n $a; wp $n $a; m=3; t=11; }

declare -a IS=(
    [0x00]=NOP       LDBCnn    LDBCmA    INCBC     INCr_b    DECr_b    LDrn_b    RLCA      LDmmSP   ADDHLBC  LDABCm   DECBC    INCr_c   DECr_c   LDrn_c    RRCA 
    [0x10]=DJNZn     LDDEnn    LDDEmA    INCDE     INCr_d    DECr_d    LDrn_d    RLA       JRn      ADDHLDE  LDADEm   DECDE    INCr_e   DECr_e   LDrn_e    RRA 
    [0x20]=JRNZn     LDHLnn    LDHLIA    INCHL     INCr_h    DECr_h    LDrn_h    XX        JRZn     ADDHLHL  LDAHLI   DECHL    INCr_l   DECr_l   LDrn_l    CPL 
    [0x30]=JRNCn     LDSPnn    LDHLDA    INCSP     INCHLm    DECHLm    LDHLmn    SCF       JRCn     ADDHLSP  LDAHLD   DECSP    INCr_a   DECr_a   LDrn_a    CCF 
    [0x40]=LDrr_bb   LDrr_bc   LDrr_bd   LDrr_be   LDrr_bh   LDrr_bl   LDrHLm_b  LDrr_ba   LDrr_cb  LDrr_cc  LDrr_cd  LDrr_ce  LDrr_ch  LDrr_cl  LDrHLm_c  LDrr_ca 
    [0x50]=LDrr_db   LDrr_dc   LDrr_dd   LDrr_de   LDrr_dh   LDrr_dl   LDrHLm_d  LDrr_da   LDrr_eb  LDrr_ec  LDrr_ed  LDrr_ee  LDrr_eh  LDrr_el  LDrHLm_e  LDrr_ea 
    [0x60]=LDrr_hb   LDrr_hc   LDrr_hd   LDrr_he   LDrr_hh   LDrr_hl   LDrHLm_h  LDrr_ha   LDrr_lb  LDrr_lc  LDrr_ld  LDrr_le  LDrr_lh  LDrr_ll  LDrHLm_l  LDrr_la 
    [0x70]=LDHLmr_b  LDHLmr_c  LDHLmr_d  LDHLmr_e  LDHLmr_h  LDHLmr_l  HALT      LDHLmr_a  LDrr_ab  LDrr_ac  LDrr_ad  LDrr_ae  LDrr_ah  LDrr_al  LDrHLm_a  LDrr_aa 
    [0x80]=ADDr_b    ADDr_c   ADDr_d     ADDr_e    ADDr_h    ADDr_l    ADDHL     ADDr_a    ADCr_b   ADCr_c   ADCr_d   ADCr_e   ADCr_h   ADCr_l   ADCHL     ADCr_a 
    [0x90]=SUBr_b    SUBr_c   SUBr_d     SUBr_e    SUBr_h    SUBr_l    SUBHL     SUBr_a    SBCr_b   SBCr_c   SBCr_d   SBCr_e   SBCr_h   SBCr_l   SBCHL     SBCr_a 
    [0xA0]=ANDr_b    ANDr_c   ANDr_d     ANDr_e    ANDr_h    ANDr_l    ANDHL     ANDr_a    XORr_b   XORr_c   XORr_d   XORr_e   XORr_h   XORr_l   XORHL     XORr_a 
    [0xB0]=ORr_b     ORr_c    ORr_d      ORr_e     ORr_h     ORr_l     ORHL      ORr_a     CPr_b    CPr_c    CPr_d    CPr_e    CPr_h    CPr_l    CPHL      CPr_a 
    [0xC0]=RETNZ     POPBC    JPNZnn     JPnn      CALLNZnn  PUSHBC    ADDn      RST00     RETZ     RET      JPZnn    MAPcb    CALLZnn  CALLnn   ADCn      RST08 
    [0xD0]=RETNC     POPDE    JPNCnn     OUTnA     CALLNCnn  PUSHDE    SUBn      RST10     RETC     RETI     JPCnn    XX       CALLCnn  MAPdd    SBCn      RST18 
    [0xE0]=LDIOnA    POPHL    LDIOCA     XX        XX        PUSHHL    ANDn      RST20     ADDSPn   JPHL     LDmmA    XX       XX       MAPed    ORn       RST28
    [0xF0]=LDAIOn    POPAF    LDAIOC     DI        XX        PUSHAF    XORn      RST30     LDHLSPn  XX       LDAmm    EI       XX       MAPfd    CPn       RST38
)

declare -a CB=(
    [0x00]=RLCr_b   RLCr_c   RLCr_d   RLCr_e   RLCr_h   RLCr_l   RLCHL   RLCr_a   RRCr_b   RRCr_c   RRCr_d   RRCr_e   RRCr_h   RRCr_l   RRCHL   RRCr_a 
    [0x10]=RLr_b   RLr_c   RLr_d   RLr_e   RLr_h   RLr_l   RLHL   RLr_a   RRr_b   RRr_c   RRr_d   RRr_e   RRr_h   RRr_l   RRHL   RRr_a 
    [0x20]=SLAr_b   SLAr_c   SLAr_d   SLAr_e   SLAr_h   SLAr_l   CBXX   SLAr_a   SRAr_b   SRAr_c   SRAr_d   SRAr_e   SRAr_h   SRAr_l   CBXX   SRAr_a 
    [0x30]=SWAPr_b   SWAPr_c   SWAPr_d   SWAPr_e   SWAPr_h   SWAPr_l   CBXX   SWAPr_a   SRLr_b   SRLr_c   SRLr_d   SRLr_e   SRLr_h   SRLr_l   CBXX   SRLr_a 
    [0x40]=BIT0b   BIT0c   BIT0d   BIT0e   BIT0h   BIT0l   BIT0m   BIT0a   BIT1b   BIT1c   BIT1d   BIT1e   BIT1h   BIT1l   BIT1m   BIT1a 
    [0x50]=BIT2b   BIT2c   BIT2d   BIT2e   BIT2h   BIT2l   BIT2m   BIT2a   BIT3b   BIT3c   BIT3d   BIT3e   BIT3h   BIT3l   BIT3m   BIT3a 
    [0x60]=BIT4b   BIT4c   BIT4d   BIT4e   BIT4h   BIT4l   BIT4m   BIT4a   BIT5b   BIT5c   BIT5d   BIT5e   BIT5h   BIT5l   BIT5m   BIT5a 
    [0x70]=BIT6b   BIT6c   BIT6d   BIT6e   BIT6h   BIT6l   BIT6m   BIT6a   BIT7b   BIT7c   BIT7d   BIT7e   BIT7h   BIT7l   BIT7m   BIT7a 
    [0x80]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX 
    [0x90]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX 
    [0xA0]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX 
    [0xB0]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX 
    [0xC0]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX 
    [0xD0]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX 
    [0xE0]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX 
    [0xF0]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX
)

declare -a ED=(
    [0x40]=INBC  OUTCB  SBCHLBC  LDnnBC  NEG  RETN  IM0  LDIA  INCC  OUTCC  ADCHLBC  LDBCnn  NEG  RETI  IM01  LDRA
    [0x50]=INDC  OUTCD  SBCHLDE  LDnnDE  NEG  RETN  IM1  LDAI  INEC  OUTCE  ADCHLDE  LDDEnn  NEG  RETN  IM2   LDAR
    [0x60]=INHC  OUTCH  SBCHLHL  LDnnHL  NEG  RETN  IM0  RRD   INLC  OUTCL  ADCHLHL  LDHLnn  NEG  RETN  IM01  RLD
    [0x70]=INFC  OUTC0  SBCHLSP  LDnnSP  NEG  RETN  IM1  XX    INAC  OUTCA  ADCHLSP  LDSPnn  NEG  RETN  IM2   XX
    [0xA0]=LDI   CPI    INI      OUTI    XX   XX    XX   XX    LDD   CPD    IND      OUTD    XX   XX    XX    XX
    [0xB0]=LDIR  CPIR   INIR     OTIR    XX   XX    XX   XX    LDDR  CPDR   INDR     OTDR    XX   XX    XX    XX
)

declare -a XXED=(
    [0x00]=RLCr_b   RLCr_c   RLCr_d   RLCr_e   RLCr_h   RLCr_l   RLCHL   RLCr_a   RRCr_b   RRCr_c   RRCr_d   RRCr_e   RRCr_h   RRCr_l   RRCHL   RRCr_a 
    [0x10]=RLr_b   RLr_c   RLr_d   RLr_e   RLr_h   RLr_l   RLHL   RLr_a   RRr_b   RRr_c   RRr_d   RRr_e   RRr_h   RRr_l   RRHL   RRr_a 
    [0x20]=SLAr_b   SLAr_c   SLAr_d   SLAr_e   SLAr_h   SLAr_l   CBXX   SLAr_a   SRAr_b   SRAr_c   SRAr_d   SRAr_e   SRAr_h   SRAr_l   CBXX   SRAr_a 
    [0x30]=SWAPr_b   SWAPr_c   SWAPr_d   SWAPr_e   SWAPr_h   SWAPr_l   CBXX   SWAPr_a   SRLr_b   SRLr_c   SRLr_d   SRLr_e   SRLr_h   SRLr_l   CBXX   SRLr_a 
    [0x40]=BIT0b   BIT0c   BIT0d   BIT0e   BIT0h   BIT0l   BIT0m   BIT0a   BIT1b   BIT1c   BIT1d   BIT1e   BIT1h   BIT1l   BIT1m   BIT1a 
    [0x50]=BIT2b   BIT2c   BIT2d   BIT2e   BIT2h   BIT2l   BIT2m   BIT2a   BIT3b   BIT3c   BIT3d   BIT3e   BIT3h   BIT3l   BIT3m   BIT3a 
    [0x60]=BIT4b   BIT4c   BIT4d   BIT4e   BIT4h   BIT4l   BIT4m   BIT4a   BIT5b   BIT5c   BIT5d   BIT5e   BIT5h   BIT5l   BIT5m   BIT5a 
    [0x70]=BIT6b   BIT6c   BIT6d   BIT6e   BIT6h   BIT6l   BIT6m   BIT6a   BIT7b   BIT7c   BIT7d   BIT7e   BIT7h   BIT7l   BIT7m   BIT7a 
    [0x80]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX 
    [0x90]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX 
    [0xA0]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX 
    [0xB0]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX 
    [0xC0]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX 
    [0xD0]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX 
    [0xE0]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX 
    [0xF0]=CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX   CBXX
)

# ASSERTS

assertb() {
    local var=$1
    [[ ${!var} -lt 0    ]] && { printf "ERROR: ${FUNCNAME[1]}: %s < 0;    %s = %02x(%d)\n" $var $var ${!var} ${!var}; exit 1; }
    [[ ${!var} -gt 0xff ]] && { printf "ERROR: ${FUNCNAME[1]}: %s > 0xff; %s = %02x(%d)\n" $var $var ${!var} ${!var}; exit 1; }
}

assertw() {
    local var=$1
    [[ ${!var} -lt 0      ]] && { printf "ERROR: $FUNCNAME: %s < 0;      %s = %02x(%d)\n" $var $var ${!var} ${!var}; exit 1; }
    [[ ${!var} -gt 0xffff ]] && { printf "ERROR: $FUNCNAME: %s > 0xffff; %s = %02x(%d)\n" $var $var ${!var} ${!var}; exit 1; }
}

assert() {
    local var=$1; local -i val=$2
    printf "var=%s  val=%d\n" "$var" $val
    if [ ${!var} -eq $val ]; then
        printf "PASS: $FUNCNAME: %s = %x(%d)\n" $var $val $val
        return 0
    fi
    printf "ERROR: $FUNCNAME: %s != %x(%d); %s = %x(%d)\n" $var $val $val $var ${!var} ${!var}
    exit 1
}

# MEMORY MANAGEMENT

memtrap() {
    local -i ta=$1 n
    n=MEM[ta]
    (( ta>=0x3c00 && ta<=0x3f00 )) && { s80video; return 0; } 
    (( ta>0x1000 && ta<0x3000 )) && { printf "MEMTRAP: %04x[%02x] \n" $ta $n; exit 1; } 
}

rb()  { local -i ta=$1; assertw ta; memtrap $ta; n=MEM[ta]; assertb n; assertb ta; }
wb()  { local -i ta=$1 tb=$2; assertw ta; assertb tb; memtrap $ta; MEM[ta]=tb; }  # or could use n
rw()  { local -i ta=$1; assertw ta; memtrap $ta; nn=MEM[ta]+MEM[ta+1]*256; assertw nn; }
ww()  { local -i ta=$1 tw=$2; assertw ta; assertw tw; memtrap $ta; (( MEM[ta]=(tw/256)&255 )); MEM[ta+1]=tw%256; }
rn()  { assertw pc; memtrap $pc; n=MEM[pc++]; assertb n; }
rnn() { assertw pc; memtrap $pc; nn=MEM[pc++]+MEM[pc++]*256; assertw nn; }
pushn()  { local -i tb=$1; assertw sp; assertb tb; memtrap $sp; MEM[--sp]=tb; }
pushnn() { local -i tw=$1; assertw sp; assertw tw; memtrap $sp; (( MEM[--sp]=tw%256, MEM[--sp]=(tw/256)&255 )); }
popn()   { assertw sp; memtrap $sp; n=MEM[sp++]; assertb n; }
popnn()  { assertw sp; memtrap $sp; nn=MEM[sp++]+MEM[sp++]*256; assertw nn; }

# VIDEO DRIVER

s80video() {
    local -i r c p
    for (( r=1 ; r<=16 ; r++ )); do
        printf "%b" "\e[${r};1H"  ## goto left of row
        for (( c=1 ; c<=64 ; c++ )); do
            (( p = 15360+(r-1)*64+c-1 ))
            n=MEM[p]  # can't use rb here
            if (( n>32 )); then
                printf "%c" ${CHR[n]}
            else
                printf " "
            fi
        done
    done
    printf "%b>>>" "\e[17;1H"
    sleep 2
}

# test video
MEM+=( [0x3c00]=65 66 67 48 49 50 )  # a few characters to display
wb 0x3c00 65
#s80video  # display video memory

# ASSEMBLER

asm() {
    local done; local -i j=0 p=0
    printf "ASSEMBLING...\n"
    while [[ -n "$1" ]]; do
        done=false
        for (( j=0 ; j<256 ; j++ )); do
            [[ ${IS[j]} = "$1" ]] && { printf "\n%04x  %02x  %s " $p $j ${IS[j]}; MEM[p]=j; p+=1; done=true; break; }
        done
        ! $done && { printf "%d" $(( $1 & 255 )); (( MEM[p]=$1 & 255 )); p+=1; }     # not operation so asssume integer
        shift
    done
    printf "\n"
    SECONDS=1
    pc=0
}

dump() {
    printf "DUMP PROGRAMMED MEMORY...\n"
    local -i tpc
    for tpc in ${!MEM[*]}; do
        #printf "%04x  %02x %d\n" $tpc ${MEM[tpc]} $(( MEM[tpc] & 255 ))
        printf "%04x  %02x %d\n" $tpc ${MEM[tpc]} ${MEM[tpc]}
    done
}


start() {
    printf "Start Program\n"
    SECONDS=1                                    # hack to eliminate division/0
    sp=pc=i=r=0
    m=t=0
    halt=stop=0
    cycles=states=0
    ime=1
    decode                                       # like a real reset, start work
}

reset() {
    printf "Reset CPU\n"
    a=b=c=d=e=h=l=f=0
    start
}

execute() {
    local -i inst=MEM[pc++]
    #printf "pc=%4x  i=%2x  IS=%s\n" $pc $inst ${IS[inst]}
    (( r=(r&0x128)+(r+1)&127 ))
    eval ${IS[inst]}
    #dis $inst ""
    (( pc&=65535 ))
    cycles+=m; states+=t
}

MAPcb() { local -i inst=MEM[pc++]; 
    if [[ -n "${CB[inst]}" ]]; then
        eval ${CB[inst]}
    else
        printf "WARNING: $FUNCNAME: Unknown ED operation code [%x] at %4x(%5d)\n" $inst $(( pc-1 ))
    fi
}


load() {
    printf "LOADING...\n"
    MEM=( $( od -vAn -tu1 -w16 system_80_rom ) ) # load ROM
    dump
}

get_FLAGS() {
    local t=; local -i j
    for (( j=0 ; j<8 ; j++ )); do
        (( f&(1<<j) )) && t+=${FLAG_NAMES[j]} || t+=" "
    done
    RET="$t"
}

_DIS=true
#_DIS=false

dis() {
    local op=$1 format="$2" inst temp flags args; local -i tpc
    $_DIS || return 0
    get_FLAGS; flags="$RET"
    printf "%6d %8s %04x " $states "$flags" $ipc
    for (( tpc=ipc ; tpc<pc ; tpc++ )); do
        #printf -v temp "%02x" $(( MEM[tpc] & 0xff ))
        printf -v temp "%02x" ${MEM[tpc]}
        inst+=$temp
    done
    shift 2
    printf -v args "$format" $*
    printf "%8s %-5s %-20s; %d kHz\n" "$inst" $op "$args" $(( states/SECONDS/1000 ))
}

decode() {
    local -i i
    $_DIS && printf "%6s %8s %4s %8s %-26s; %s\n" STATES FLAGS ADDR HEX INSTRUCTION RATE
    while (( stop!=1 && halt!=1 )); do
        ipc=pc                                   # save PC for display
        [[ -n ${TRAP[pc]} ]] && { dis TRAP; eval "${TRAP[pc]}"; } 
        i=MEM[pc]                                # get first instruction opcode
        assertb i  # invalid memory content
        #printf "pc=%4x  i=%2x\n" $pc $i
        execute
        ! $_DIS && s80video
    done
}



# make LDrr_yz() functions
for r1 in b c d e h l a; do
    for r2 in b c d e h l a; do
        printf "LDrr_$r1$r2() { dis LD \"${r1^^}(%%02x),${r2^^}(%%02x)\" \$$r1 \$$r2; (( $r1=$r2, m=1, t=4 )); }\n"  ##
    done
    printf "LDrHLm_$r1() { nn=h*256+l; rb \$nn; dis LD \"${r1^^}(%%02x),(HL=%%04x)\" \$$r1 \$nn; (( $r1=n, m=2, t=8 )); }\n"
    printf "LDHLmr_$r1() { nn=h*256+l; wb \$nn \$$r1; dis LD \"(HL=%%04x),${r1^^}(%%02x)\" \$nn \$$r1; (( m=2, t=8 )); }\n"
    printf "LDrn_$r1() { rn; dis LD \"${r1^^}(%%02x),%%02x\" \$$r1 \$n; (( $r1=n, m=2, t=8 )); }\n"
    printf "XORr_$r1() { dis XOR \"A(%%02x),${r1^^}(%%02x)\" \$a \$$r1; (( a^=$r1, f=(a==0)*FZ + (a>0x7F)*FS, m=1, t=4 )); }\n"
    printf "ORr_$r1()  { dis OR  \"A(%%02x),${r1^^}(%%02x)\" \$a \$$r1; (( a|=$r1, f=(a==0)*FZ + (a>0x7F)*FS, m=1, t=4 )); }\n"
    printf "ANDr_$r1() { dis AND \"A(%%02x),${r1^^}(%%02x)\" \$a \$$r1; (( a&=$r1, f=(a==0)*FZ + (a>0x7F)*FS, m=1, t=4 )); }\n"
    printf "INCr_$r1() { dis INC \"${r1^^}(%%02x)\" \$$r1; (( $r1=($r1+1)&255, f=($r1==0)*FZ + ($r1>0x7F)*FS + ($r1==0x80)*FP, m=1, t=4 )); }\n"
    printf "DECr_$r1() { dis DEC \"${r1^^}(%%02x)\" \$$r1; (( $r1=($r1-1)&255, f=($r1==0)*FZ + ($r1>0x7F)*FS + ($r1==0x7F)*FP, m=1, t=4 )); }\n"
    printf "ADDr_$r1() { dis ADD \"A(%%02x),${r1^^}(%%02x)\" \$a \$$r1; 
                         (( a+=$r1, f=(a==0)*FZ + (a>255)*(FP+FC), a&=255, f+=(a>127)*FS + ((a&15)+($r1&15)>15)*FH, m=1, t=4 )); }\n"  ##
    printf "ADCr_$r1() { dis ADC \"A(%%02x),${r1^^}(%%02x)\" \$a \$$r1; 
                         (( a+=$r1+(f&FC), f=(a==0)*FZ + (a>255)*(FP+FC), a&=255, f+=(a>127)*FS + ((a&15)+($r1&15)>15)*FH, m=1, t=4 )); }\n"  ##

done > LDr.bash
. LDr.bash

declare -ia PAR
# make byte parity lookup table
for (( j=0 ; j<256 ; j++ )); do
    (( p=j,
       p=(p&15)^(p>>4),
       p=(p& 3)^(p>>2),
       p=(p& 1)^(p>>1),
       PAR[j]=(!p)*FP ))
done

print_parity_table() {
    local -i j r c
    printf "\x1b[2J\x1b[1;1HPARITY TABLE"
    for (( j=0 ; j<256 ; j++ )); do
        (( r=(j>>4), c=(j&15) ))
        (( r==0 )) && printf "\x1b[32m\x1b[%d;%dH%2x\x1b[m" 3 $(( c*3+6 )) $c  # top row
        (( c==0 )) && printf "\x1b[32m\x1b[%d;%dH%2x\x1b[m" $(( r*1+4 )) 3 $r
 # left column
        printf "\x1b[%d;%dH%2x" $(( r*1+4 )) $(( c*3+6 )) ${PAR[j]}
    done
    printf "\x1b[2E"
}

#print_parity_table; exit 0

XORHL()  { nn=h*256+l; rb $nn; dis XOR "A(%02x),(HL=%04x)" $a $nn; (( a^=n, f=(a==0)*FZ + (a>0x7F)*FS + PAR[a], m=1, t=4 )); }
ORHL()   { nn=h*256+l; rb $nn; dis OR  "A(%02x),(HL=%04x)" $a $nn; (( a|=n, f=(a==0)*FZ + (a>0x7F)*FS + PAR[a], m=1, t=4 )); }
ANDHL()  { nn=h*256+l; rb $nn; dis AND "A(%02x),(HL=%04x)" $a $nn; (( a&=n, f=(a==0)*FZ + (a>0x7F)*FS + PAR[a], m=1, t=4 )); }
INCHLm() { nn=h*256+l; rb $nn; dis INC "(HL=%04x)[%02x]" $nn $n; (( n=(n+1)&255, f=(n==0)*FZ + (n>0x7F)*FS + (n==0x80)*FP, m=3, t=12 )); wb $nn $n; }
DECHLm() { nn=h*256+l; rb $nn; dis DEC "(HL=%04x)[%02x]" $nn $n; (( n=(n-1)&255, f=(n==0)*FZ + (n>0x7F)*FS + (n==0x7F)*FP, m=3, t=12 )); wb $nn $n; }
ADDHL()  { nn=h*256+l; rb $nn; dis ADD "A(%02x),(HL=%04x)" $a $nn; (( a+=n, f=(a==0)*FZ + (a>255)*(FP+FC), a&=255, f+=(a>127)*FS + ((a&15)+($r1&15)>15)*FH, m=2, t=7 )); }  ##
ADCHL()  { nn=h*256+l; rb $nn; dis ADC "A(%02x),(HL=%04x)" $a $nn; (( a+=n+(f&FC), f=(a==0)*FZ + (a>255)*(FP+FC), a&=255, f+=(a>127)*FS + ((a&15)+($r1&15)>15)*FH, m=2, t=7 )); }  ##

ANDn() { rn; dis AND "A(%02x),%02x" $a $n; (( m=2, t=8, a&=n,        f=(a==0)*FZ + (a>127)*FS + PAR[a] )); }
ORn()  { rn; dis OR  "A(%02x),%02x" $a $n; (( m=2, t=8, a|=n,        f=(a==0)*FZ + (a>127)*FS + PAR[a] )); }
XORn() { rn; dis XOR "A(%02x),%02x" $a $n; (( m=2, t=8, a^=n,        f=(a==0)*FZ + (a>127)*FS + PAR[a] )); }
ADDn() { rn; dis ADD "A(%02x),%02x" $a $n; (( m=2, t=7, a+=n,        f=(a==0)*FZ + (a>255)*(FP+FC), a&=255, f+=(a>127)*FS + ((a&15)+($r1&15)>15)*FH )); }  ##
ADCn() { rn; dis ADC "A(%02x),%02x" $a $n; (( m=2, t=7, a+=n+(f&FC), f=(a==0)*FZ + (a>255)*(FP+FC), a&=255, f+=(a>127)*FS + ((a&15)+($r1&15)>15)*FH )); }  ##

testflag() {
    local -i j pf=-1 f=0 f0; local F pF
    for (( j=0 ; j<256 ; j++ )); do
        get_FLAGS; pF="$RET";
        pf=f
        #(( f=(j==0)*FZ + (j>127)*FS ))
        (( f=(!j)*FZ + (j>127)*FS ))
        f0=0
        (( j==0 )) && f0=FZ
        (( j>127 )) && (( f0|=FS ))
        get_FLAGS; F="$RET"
        
        (( f!=pf )) && { [[ f -eq f0 ]] && printf "PASS: " || printf "FAIL: " ; printf "%02x [%8s]   j=%02x   -> %02x [%8s] f0=%02x\n" $pf "$pF" $j $f "$F" $f0; }
    done
}
#testflag
#exit 0


for rp in bc de hl; do
    rh=${rp::1}; rl=${rp:1}
    printf "LD${rp^^}nn() { rn; nn=n; $rl=n; rn; nn+=n*256; $rh=n; dis LD \"${rp^^}(%%04x),%%04x\" $(( rh*256+rl )) \$nn; m=3; t=12; }\n"
    printf "INC${rp^^}()  { (( $rl+=1, $rl==0  ?$rh=($rh+1)&255:0, nn=$rh*256+$rl, m=1, t=6 )); dis INC \"${rp^^}=%%04x\" \$nn; }\n"
    printf "DEC${rp^^}()  { (( $rl-=1, $rl==255?$rh=($rh-1)&255:0, nn=$rh*256+$rl, m=1, t=6 )); dis DEC \"${rp^^}=%%04x\" \$nn; }\n"
done > LDRPnn.bash
. LDRPnn.bash

LDSPnn() { rnn; dis LD "SP,%04x" $nn; (( sp=nn, m=3, t=12 )); }
INCSP()  { dis INC "SP[%04x]" $sp; (( sp=(sp+1)&65535, m=1, t=6 )); };
DECSP()  { dis DEC "SP[%04x]" $sp; (( sp=(sp-1)&65535, m=1, t=6 )); };

b=9; asm LDBCnn 1 1 HALT; start; dump; assert b 1; assert c 1

b=0;   INCr_b; assert b 1;   assert f $(( 2#00000000 ))
b=127; INCr_b; assert b 128; assert f $(( 2#10000100 ))

for p in '00' '08' 10 18 20 28 30 38; do
    printf "RST$p() { dis RST \"$p\"; let sp-=2; ww \$sp \$pc; pc=0x\$p; m=3; t=12; }\n"
done > RST.bash
. RST.bash

#echo ${IS[2]}
# test
b=255; assert b 255; asm DJNZn -2 HALT; dump; start; assert b 0; assert pc 3; assert states $(( 254*13+8+4 ))

#exit 0

load
reset


