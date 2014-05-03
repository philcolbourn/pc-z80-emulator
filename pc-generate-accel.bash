#!/bin/bash

# Fast functions

{
printf "# Generated functions\n"
printf "acc_DAA() {
    local _NF=\${HEX[(f&FN)>>1]} _CF=\${HEX[f&FC]} _hi=\${HEX[(a&15)>>4]} _HF=\${HEX[(f&FH)>>4]} _lo=\${HEX[a&15]}
    local K=\${_NF}\${_CF}\${_hi}\${_HF}\${_lo}; local -i diff _hc
    case \$K in
        00[0-9]0[0-9]) (( diff=0x00, _hc= 0| 0 ));;
        00[0-9]1[0-9]) (( diff=0x06, _hc= 0| 0 ));;
        00[0-8]?[a-f]) (( diff=0x06, _hc=FH    ));;
        00[a-f]0[0-9]) (( diff=0x60, _hc=   FC ));;
            01?0[0-9]) (( diff=0x60, _hc=   FC ));;
            01?1[0-9]) (( diff=0x66, _hc=   FC ));;
            01??[a-f]) (( diff=0x66, _hc=FH|FC ));;
        00[9-f]?[a-f]) (( diff=0x66, _hc=FH|FC ));;
        00[a-f]1[0-9]) (( diff=0x66, _hc=   FC ));;

        10[0-9]0[0-9]) (( diff=0x00, _hc= 0| 0 ));;
        10[0-9]1[0-9]) (( diff=0x06, _hc= 0| 0 ));;
        10[0-8]?[a-f]) (( diff=0x06, _hc= 0| 0 ));;
        10[a-f]0[0-9]) (( diff=0x60, _hc=   FC ));;
        
            11?0[0-5]) (( diff=0x60, _hc=FH|FC ));;
            11?0[6-9]) (( diff=0x60, _hc=   FC ));;
            11?1[0-5]) (( diff=0x66, _hc=FH|FC ));;
            11?1[6-9]) (( diff=0x66, _hc=   FC ));;
            11??[a-f]) (( diff=0x66, _hc=   FC ));;
            
        10[9-f]?[a-f]) (( diff=0x66, _hc=   FC ));;
        10[a-f]1[0-9]) (( diff=0x66, _hc=   FC ));;
    esac
    (( a=a+((f&FN)?(-diff):diff) )); setfDAA 0 \$_hc \$a
}  # from $0.$LINENO\n"

printf "# Some loads - timing checked\n"
printf "acc_LDAmm()  {       rb \$mm;     a=n;   return 0; }  # from $0.$LINENO\n"
printf "acc_LDmmA()  {       wb \$mm \$a;        return 0; }  # from $0.$LINENO\n"
printf "acc_LDBCmA() { (( $BC )); wb \$bc \$a;        return 0; }  # from $0.$LINENO\n"
printf "acc_LDDEmA() { (( $DE )); wb \$de \$a;        return 0; }  # from $0.$LINENO\n"
printf "acc_LDABCm() { (( $BC )); rb \$bc;     a=n;   return 0; }  # from $0.$LINENO\n"
printf "acc_LDADEm() { (( $DE )); rb \$de;     a=n;   return 0; }  # from $0.$LINENO\n"
printf "acc_LDSPnn() {                    sp=nn; return 0; }  # from $0.$LINENO\n"

printf "# Jumps, calls and returns - timing checked\n"
printf "acc_JPnn()   {                 pc=nn;            return 0; }  # from $0.$LINENO\n"
printf "acc_CALLnn() {   pushw \$pc;   pc=nn;            return 0; }  # from $0.$LINENO\n"
printf "acc_JRn()    {    (( $NNPCD )); pc=nn;            return 0; }  # from $0.$LINENO\n"
printf "acc_RET()    { popnn;               pc=nn;            return 0; }  # from $0.$LINENO\n"
printf "acc_RETI()   { popnn;               pc=nn; iff1=iff2; return 0; }  # from $0.$LINENO\n"
printf "acc_RETN()   { popnn;               pc=nn; iff1=iff2; return 0; }  # from $0.$LINENO\n"

printf "# Conditional Jump, Call, and Return instructions - timing checked\n"
for g in "Z:NZ:Z" "C:NC:C" "PE:PO:P" "M:P:S"; do S=${g%%:*}; N=${g#*:}; N=${N%:*}; F=${g##*:}  # Set, Not set, and Flag name
    printf "acc_JP${N}nn()   {     (( f&F$F )) || {               pc=nn; }; return 0; }  # from $0.$LINENO\n"
    printf "acc_JP${S}nn()   {     (( f&F$F )) && {               pc=nn; }; return 0; }  # from $0.$LINENO\n"
    printf "acc_CALL${N}nn() {     (( f&F$F )) || { pushw \$pc;   pc=nn; }; return 0; }  # from $0.$LINENO\n"
    printf "acc_CALL${S}nn() {     (( f&F$F )) && { pushw \$pc;   pc=nn; }; return 0; }  # from $0.$LINENO\n"
    printf "acc_RET$N()      {          (( f&F$F )) || { popnn;        pc=nn; }; return 0; }  # from $0.$LINENO\n"
    printf "acc_RET$S()      {          (( f&F$F )) && { popnn;        pc=nn; }; return 0; }  # from $0.$LINENO\n"
    printf "acc_JR${N}n()    {      (( $NNPCD )); (( f&F$F )) || { pc=nn; }; return 0; }  # from $0.$LINENO\n"
    printf "acc_JR${S}n()    {      (( $NNPCD )); (( f&F$F )) && { pc=nn; }; return 0; }  # from $0.$LINENO\n"
done

printf "# block move - timing checked\n"
# Notes: must unset AREA after reading character from (DE)
INCBLOCK="$INChl,$INCde,$DECbc"
INCBLOCKR="$INChl,$INCde,$DECBC,$SETbc,(bc>0)?(pc=(pc-2)&65535):(q+=3,t+=12)"
DECBLOCK="$DEChl,$DECde,$DECbc"
DECBLOCKR="$DEChl,$DECde,$DECBC,$SETbc,(bc>0)?(pc=(pc-2)&65535):(q+=3,t+=12)"
printf "acc_LDI()  { (( $HL, $DE, $BC )); rb \$de; m=n; rb \$hl; wb \$de \$n; (( $INCBLOCK )); setfLDI 0 \$a \$n; }  # from $0.$LINENO\n"
printf "acc_LDD()  { (( $HL, $DE, $BC )); rb \$de; m=n; rb \$hl; wb \$de \$n; (( $DECBLOCK )); setfLDI 0 \$a \$n; }  # from $0.$LINENO\n"
# FIXME: dummy
printf "acc_CPI()  { (( $HL, $DE, $BC )); rb \$de; m=n; rb \$hl; wb \$de \$n; (( $INCBLOCK )); setfLDI 0 \$a \$n; }  # from $0.$LINENO\n"
printf "acc_CPD()  { (( $HL, $DE, $BC )); rb \$de; m=n; rb \$hl; wb \$de \$n; (( $DECBLOCK )); setfLDI 0 \$a \$n; }  # from $0.$LINENO\n"
# z80 implementation of LDIR is LDI + no change to PC - this is inefficient in an emulator due to composing and decomposing double registers each itteration
printf "acc_XLDIR() { (( $HL, $DE, $BC )); rb \$de; m=n; rb \$hl; wb \$de \$n; (( $INCBLOCKR )); setfLDIR 0 \$a \$n; }  # from $0.$LINENO\n"
printf "acc_XLDDR() { (( $HL, $DE, $BC )); rb \$de; m=n; rb \$hl; wb \$de \$n; (( $DECBLOCKR )); setfLDIR 0 \$a \$n; }  # from $0.$LINENO\n"

# alternative implementation for efficiency - but can still be done better - timing wrong?
printf "acc_LDIR() { 
    (( $HL, $DE, $BC ))
    while ((bc>0)); do
        rb \$hl; wb \$de \$n                     # capture memory AREA names from here
        (( $INCHL, $INCDE, bc-=1 ))              # just inc and dec double registers
    done
    (( $SEThl, $SETde, b=c=0 ))                  # copy results into registers
    setfLDIR 0 $a $n                             # flags set on last character moved
    return 0;
}  # from $0.$LINENO\n"

printf "acc_LDDR() { 
    (( $HL, $DE, $BC ))
    while ((bc>0)); do
        rb \$hl; wb \$de \$n                     # capture memory AREA names from here
        (( $DECHL, $DECDE, bc-=1 ))              # just dec double registers
    done
    (( $SEThl, $SETde, b=c=0 ))                  # copy results into registers
    setfLDIR 0 $a $n                             # flags set on last character moved
    return 0;
}  # from $0.$LINENO\n"

printf "# misc - timing checked\n"
printf "acc_DJNZn() { (( $NNPCD, b=(b-1)&255, b?(pc=nn):0 )); return 0; }  # from $0.$LINENO\n"

printf "acc_NOP()   { return 0; }  # from $0.$LINENO\n"
printf "acc_HALT()  { dis HALT; halt=1; return 0; }  # from $0.$LINENO\n"

printf "acc_DI()    { iff1=iff2=0; return 0; }  # from $0.$LINENO\n"
printf "acc_EI()    { iff1=iff2=1; return 0; }  # from $0.$LINENO\n"
printf "acc_IM1()   { return 0; }  # from $0.$LINENO\n"
printf "acc_IM2()   { return 0; }  # from $0.$LINENO\n"
printf "acc_IM3()   { return 0; }  # from $0.$LINENO\n"

printf "acc_EXSPmHL() { rw \$sp; (( $HL )); ww \$sp \$hl; (( $SEThlnn )); return 0; }  # from $0.$LINENO\n"

printf "# IN and OUT - timing checked\n"
printf "acc_OUTnA() { wp \$n \$a;  return 0; }  # from $0.$LINENO\n"
printf "acc_INAn()  { rp \$m; a=n; return 0; }  # from $0.$LINENO\n"

printf "# - timing checked\n"
printf "acc_CPL() { ((      a=(~a)&255  )); setfCPL 0 0   \$a; }  # from $0.$LINENO\n"
printf "acc_NEG() { (( m=a, a=(0-a)&255 )); setfNEG 0 \$m \$a; }  # from $0.$LINENO\n"

printf "acc_CCF() { setfCCF 0 0 0; }  # from $0.$LINENO\n"
printf "acc_SCF() { setfSCF 0 0 0; }  # from $0.$LINENO\n"

SETF="setfRLD 0 0 \$a"
printf "acc_RLD() { (( $HL )); rb \$hl; (( m=a, a=(a&0xf0)|(n>>4), n=((n&15)<<4)|(m&15) )); wb \$hl \$n; $SETF; }  # from $0.$LINENO\n"
printf "acc_RRD() { (( $HL )); rb \$hl; (( m=a, a=(a&0xf0)|(n&15), n=((m&15)<<4)|(n>>4) )); wb \$hl \$n; $SETF; }  # from $0.$LINENO\n"

printf "# 8 bit register instructions - ?\n"
for r1 in b c d e h l a x X y Y; do R1=${RN[$r1]}
    for r2 in b c d e h l a x X y Y; do R2=${RN[$r2]}
        printf "acc_LDrr_$r1$r2() { $r1=$r2; return 0; }  # from $0.$LINENO\n"
    done
    
    printf "acc_LDrHLm_$r1() { (( $HL )); rb \$hl; $r1=n; return 0; }  # from $0.$LINENO\n"
    printf "acc_LDHLmr_$r1() { (( $HL )); wb \$hl \$$r1; }  # from $0.$LINENO\n"
    printf "acc_LDrn_$r1()   { $r1=n; return 0; }  # from $0.$LINENO\n"
    printf "acc_LDrIXm_$r1() { (( $IX, mm=(ix+D)&65535 )); rb \$mm; $r1=n; return 0; }  # from $0.$LINENO\n"
    printf "acc_LDrIYm_$r1() { (( $IY, mm=(iy+D)&65535 )); rb \$mm; $r1=n; return 0; }  # from $0.$LINENO\n"
    printf "acc_LDIXmr_$r1() { (( $IX, mm=(ix+D)&65535 )); wb \$mm \$$r1; }  # from $0.$LINENO\n"
    printf "acc_LDIYmr_$r1() { (( $IY, mm=(iy+D)&65535 )); wb \$mm \$$r1; }  # from $0.$LINENO\n"

    printf "acc_ADDr_$r1() { (( n=a, a=(a+$r1)       &255             )); setfADD \$n \$$r1 \$a;   }  # from $0.$LINENO\n"
    printf "acc_SUBr_$r1() { (( n=a, a=(a-$r1)       &255             )); setfSUB \$n \$$r1 \$a;   }  # from $0.$LINENO\n"
    printf "acc_ADCr_$r1() { (( n=a, a=(a+$r1+(f&FC))&255             )); setfADC \$n \$$r1 \$a;   }  # from $0.$LINENO\n"
    printf "acc_SBCr_$r1() { (( n=a, a=(a-$r1-(f&FC))&255             )); setfSBC \$n \$$r1 \$a;   }  # from $0.$LINENO\n"
    printf "acc_XORr_$r1() { (( n=a, a^=$r1                           )); setfXOR \$n \$$r1 \$a;   }  # from $0.$LINENO\n"
    printf "acc_ORr_$r1()  { (( n=a, a|=$r1                           )); setfOR  \$n \$$r1 \$a;   }  # from $0.$LINENO\n"
    printf "acc_ANDr_$r1() { (( n=a, a&=$r1                           )); setfAND \$n \$$r1 \$a;   }  # from $0.$LINENO\n"

    printf "acc_CPr_$r1()  { ((      m=(a-$r1)       &255             )); setfCP  \$a \$$r1 \$m;   }  # from $0.$LINENO\n"  # different

    printf "acc_INCr_$r1() { (( n=$r1, $r1=($r1+1)&255 )); setfINC \$n 1 \$$r1; }  # from $0.$LINENO\n"
    printf "acc_DECr_$r1() { (( n=$r1, $r1=($r1-1)&255 )); setfDEC \$n 1 \$$r1; }  # from $0.$LINENO\n"

    SETF="setfROTr 0 \$m \$$r1"
    printf "acc_RLr_$r1()  { (( m=$r1>>7, $r1=(($r1<<1)|(f&FC))  &255 )); $SETF; }  # from $0.$LINENO\n"
    printf "acc_RRr_$r1()  { (( m=$r1&FC, $r1=(($r1>>1)|(f<<7))  &255 )); $SETF; }  # from $0.$LINENO\n"
    printf "acc_RLCr_$r1() { (( m=$r1>>7, $r1=(($r1<<1)|($r1>>7))&255 )); $SETF; }  # from $0.$LINENO\n"
    printf "acc_RRCr_$r1() { (( m=$r1&FC, $r1=(($r1>>1)|($r1<<7))&255 )); $SETF; }  # from $0.$LINENO\n"
    printf "acc_SLAr_$r1() { (( m=$r1>>7, $r1=(($r1<<1)         )&255 )); $SETF; }  # from $0.$LINENO\n"
    printf "acc_SLLr_$r1() { (( m=$r1>>7, $r1=(($r1<<1)|1       )&255 )); $SETF; }  # from $0.$LINENO\n"
    printf "acc_SRAr_$r1() { (( m=$r1&FC, $r1=(($r1>>1)|($r1&FS))&255 )); $SETF; }  # from $0.$LINENO\n"
    printf "acc_SRLr_$r1() { (( m=$r1&FC, $r1=(($r1>>1)         )&255 )); $SETF; }  # from $0.$LINENO\n"

    for (( j=0; j<8; j++ )); do
        ORM=$(( 1<<j )); ANDM=$(( 255-ORM ))
        printf "acc_BIT$j$r1() { (( n=$r1&$ORM )); setfBIT 0 0 \$n; }  # from $0.$LINENO\n"
        printf "acc_SET$j$r1() { (( $r1|=$ORM  )); return 0; }  # from $0.$LINENO\n"
        printf "acc_RES$j$r1() { (( $r1&=$ANDM )); return 0; }  # from $0.$LINENO\n"
    done
done

printf "acc_ADDn() { (( m=a, a=(a+n)       &255 )); setfADD \$m \$n \$a; }  # from $0.$LINENO\n"
printf "acc_SUBn() { (( m=a, a=(a-n)       &255 )); setfSUB \$m \$n \$a; }  # from $0.$LINENO\n"
printf "acc_ADCn() { (( m=a, a=(a+n+(f&FC))&255 )); setfADC \$m \$n \$a; }  # from $0.$LINENO\n"
printf "acc_SBCn() { (( m=a, a=(a-n-(f&FC))&255 )); setfSBC \$m \$n \$a; }  # from $0.$LINENO\n"
printf "acc_XORn() { (( m=a, a=(a^n)            )); setfXOR \$m \$n \$a; }  # from $0.$LINENO\n"
printf "acc_ORn()  { (( m=a, a=(a|n)            )); setfOR  \$m \$n \$a; }  # from $0.$LINENO\n"
printf "acc_ANDn() { (( m=a, a=(a&n)            )); setfAND \$m \$n \$a; }  # from $0.$LINENO\n"

printf "acc_CPn()  { ((      m=(a-n)       &255 )); setfCP  \$a \$n \$m; }  # from $0.$LINENO\n"  # different

printf "acc_EXDEHL() { n=d; d=h; h=n; n=e; e=l; l=n; return 0; }  # from $0.$LINENO\n"
printf "acc_LDHLmn() { (( $HL )); wb \$hl \$n; }  # from $0.$LINENO\n"

printf "# (HL) instructions\n"
for rp in hl; do rh=${rp::1}; rl=${rp:1}; RP=${RPN[$rp]}; RR="rr=($rh<<8)|$rl"

    SETF="setfROTr 0 \$m \$n"
    printf "acc_RL${RP}m()  { (( $RR )); rb \$rr; (( m=n>>7, n=((n<<1)|(f&FC))&255 )); wb \$rr \$n; $SETF;               }  # from $0.$LINENO\n"
    printf "acc_RR${RP}m()  { (( $RR )); rb \$rr; (( m=n&FC, n=((n>>1)|(f<<7))&255 )); wb \$rr \$n; $SETF;               }  # from $0.$LINENO\n"
    printf "acc_RLC${RP}m() { (( $RR )); rb \$rr; (( m=n>>7, n=((n<<1)|(n>>7))&255 )); wb \$rr \$n; $SETF;               }  # from $0.$LINENO\n"
    printf "acc_RRC${RP}m() { (( $RR )); rb \$rr; (( m=n&FC, n=((n>>1)|(n<<7))&255 )); wb \$rr \$n; $SETF;               }  # from $0.$LINENO\n"
    printf "acc_SLA${RP}m() { (( $RR )); rb \$rr; (( m=n>>7, n=((n<<1)       )&255 )); wb \$rr \$n; $SETF;               }  # from $0.$LINENO\n"
    printf "acc_SRA${RP}m() { (( $RR )); rb \$rr; (( m=n&FC, n=((n>>1)|(n&FS))&255 )); wb \$rr \$n; $SETF;               }  # from $0.$LINENO\n"
    printf "acc_SLL${RP}m() { (( $RR )); rb \$rr; (( m=n>>7, n=((n<<1)|1     )&255 )); wb \$rr \$n; $SETF;               }  # from $0.$LINENO\n"
    printf "acc_SRL${RP}m() { (( $RR )); rb \$rr; (( m=n&FC, n=((n>>1)       )&255 )); wb \$rr \$n; $SETF;               }  # from $0.$LINENO\n"

    printf "acc_INC${RP}m() { (( $RR )); rb \$rr; (( m=n,    n=(n+1)          &255 )); wb \$rr \$n; setfINC \$m 1   \$n; }  # from $0.$LINENO\n"
    printf "acc_DEC${RP}m() { (( $RR )); rb \$rr; (( m=n,    n=(n-1)          &255 )); wb \$rr \$n; setfDEC \$m 1   \$n; }  # from $0.$LINENO\n"

    printf "acc_ADD${RP}m() { (( $RR )); rb \$rr; (( m=a,    a=(a+n)          &255 ));              setfADD \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "acc_SUB${RP}m() { (( $RR )); rb \$rr; (( m=a,    a=(a-n)          &255 ));              setfSUB \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "acc_ADC${RP}m() { (( $RR )); rb \$rr; (( m=a,    a=(a+n+(f&FC))   &255 ));              setfADC \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "acc_SBC${RP}m() { (( $RR )); rb \$rr; (( m=a,    a=(a-n-(f&FC))   &255 ));              setfSBC \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "acc_XOR${RP}m() { (( $RR )); rb \$rr; (( m=a,    a=(a^n)               ));              setfXOR \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "acc_OR${RP}m()  { (( $RR )); rb \$rr; (( m=a,    a=(a|n)               ));              setfOR  \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "acc_AND${RP}m() { (( $RR )); rb \$rr; (( m=a,    a=(a&n)               ));              setfAND \$m \$n \$a; }  # from $0.$LINENO\n"

    printf "acc_CP${RP}m()  { (( $RR )); rb \$rr; ((         m=(a-n)          &255 ));              setfCP  \$a \$n \$m; }  # from $0.$LINENO\n"  # different

    for (( j=0; j<8; j++ )); do
        printf "acc_BIT$j${RP}m() { (( $RR )); rb \$rr; (( m=n, n&=$(( 1<<j )) )); setfBITh $j \$h \$n; }  # from $0.$LINENO\n"
        printf "acc_SET$j${RP}m() { (( $RR )); rb \$rr; (( n&$(( 1<<j )) )) || wb \$rr \$(( n|$((      1<<j  )) )); return 0; }  # from $0.$LINENO\n"
        printf "acc_RES$j${RP}m() { (( $RR )); rb \$rr; (( n&$(( 1<<j )) )) && wb \$rr \$(( n&$(( 255-(1<<j) )) )); return 0; }  # from $0.$LINENO\n"
    done
done

printf "# 16 bit register instructions - assume D already read in map\n"
for rp in xX yY; do rh=${rp::1}; rl=${rp:1}; RP=${RPN[$rp]}; RR="rr=($rh<<8)|$rl"; RRD="rrd=(($rh<<8)+$rl+D)&65535"

    printf "acc_LD${RP}mn() { (( $RR, $RRD )); wb \$rrd \$n; }  # from $0.$LINENO\n"
    SETF="setfROTr 0 \$m \$n"
    printf "acc_RL${RP}m()  { (( $RRD )); rb \$rrd; (( m=n>>7, n=((n<<1)|(f&FC))&255 ));       wb \$rrd \$n; $SETF; }  # from $0.$LINENO\n"
    printf "acc_RR${RP}m()  { (( $RRD )); rb \$rrd; (( m=n&FC, n=((n>>1)|(f<<7))&255 ));       wb \$rrd \$n; $SETF; }  # from $0.$LINENO\n"
    printf "acc_RLC${RP}m() { (( $RRD )); rb \$rrd; (( m=n>>7, n=((n<<1)|(n>>7))&255 ));       wb \$rrd \$n; $SETF; }  # from $0.$LINENO\n"
    printf "acc_RRC${RP}m() { (( $RRD )); rb \$rrd; (( m=n&FC, n=((n>>1)|(n<<7))&255 ));       wb \$rrd \$n; $SETF; }  # from $0.$LINENO\n"
    printf "acc_SLA${RP}m() { (( $RRD )); rb \$rrd; (( m=n>>7, n=((n<<1)       )&255 ));       wb \$rrd \$n; $SETF; }  # from $0.$LINENO\n"
    printf "acc_SRA${RP}m() { (( $RRD )); rb \$rrd; (( m=n&FC, n=((n>>1)|(n&FS))&255 ));       wb \$rrd \$n; $SETF; }  # from $0.$LINENO\n"
    printf "acc_SLL${RP}m() { (( $RRD )); rb \$rrd; (( m=n>>7, n=((n<<1)|1     )&255 ));       wb \$rrd \$n; $SETF; }  # from $0.$LINENO\n"
    printf "acc_SRL${RP}m() { (( $RRD )); rb \$rrd; (( m=n&FC, n=((n>>1)       )&255 ));       wb \$rrd \$n; $SETF; }  # from $0.$LINENO\n"

    for r1 in a b c d e  h l; do R1=${RN[$r1]} 
        printf "acc_RL${RP}mr_$r1()  { (( $RRD )); rb \$rrd; (( m=n>>7, n=((n<<1)|(f&FC))&255, $r1=n )); wb \$rrd \$n; $SETF; }  # from $0.$LINENO\n"
        printf "acc_RLC${RP}mr_$r1() { (( $RRD )); rb \$rrd; (( m=n>>7, n=((n<<1)|(n>>7))&255, $r1=n )); wb \$rrd \$n; $SETF; }  # from $0.$LINENO\n"
        printf "acc_SLA${RP}mr_$r1() { (( $RRD )); rb \$rrd; (( m=n>>7, n=((n<<1)       )&255, $r1=n )); wb \$rrd \$n; $SETF; }  # from $0.$LINENO\n"
        printf "acc_SLL${RP}mr_$r1() { (( $RRD )); rb \$rrd; (( m=n>>7, n=((n<<1)|1     )&255, $r1=n )); wb \$rrd \$n; $SETF; }  # from $0.$LINENO\n"
    done

    printf "acc_ADD${RP}m() { (( $RRD )); rb \$rrd; (( m=a, a=(a+n)       &255 )); setfADD \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "acc_SUB${RP}m() { (( $RRD )); rb \$rrd; (( m=a, a=(a-n)       &255 )); setfSUB \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "acc_ADC${RP}m() { (( $RRD )); rb \$rrd; (( m=a, a=(a+n+(f&FC))&255 )); setfADC \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "acc_SBC${RP}m() { (( $RRD )); rb \$rrd; (( m=a, a=(a-n-(f&FC))&255 )); setfSBC \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "acc_XOR${RP}m() { (( $RRD )); rb \$rrd; (( m=a, a=(a^n)            )); setfXOR \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "acc_OR${RP}m()  { (( $RRD )); rb \$rrd; (( m=a, a=(a|n)            )); setfOR  \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "acc_AND${RP}m() { (( $RRD )); rb \$rrd; (( m=a, a=(a&n)            )); setfAND \$m \$n \$a; }  # from $0.$LINENO\n"

    printf "acc_CP${RP}m()  { (( $RRD )); rb \$rrd; ((      m=(a-n)       &255 )); setfCP  \$a \$n \$m; }  # from $0.$LINENO\n"  # different

    printf "acc_INC${RP}m() { (( $RRD )); rb \$rrd; (( m=n, n=(n+1)       &255 )); wb \$rrd \$n; setfINC \$m 1   \$n; }  # from $0.$LINENO\n"
    printf "acc_DEC${RP}m() { (( $RRD )); rb \$rrd; (( m=n, n=(n-1)       &255 )); wb \$rrd \$n; setfDEC \$m 1   \$n; }  # from $0.$LINENO\n"
    
    for (( j=0; j<8; j++ )); do
        printf "acc_BIT$j${RP}m() { (( $RRD )); rb \$rrd; (( m=n, n&=$(( 1<<j )) )); setfBITx $j \$((rrd>>8)) \$n; }  # from $0.$LINENO\n"  # [SY05]
        printf "acc_SET$j${RP}m() { (( $RRD )); rb \$rrd; (( n&$(( 1<<j )) )) || wb \$rrd \$(( n|$((      1<<j  )) )); return 0; }  # from $0.$LINENO\n"
        printf "acc_RES$j${RP}m() { (( $RRD )); rb \$rrd; (( n&$(( 1<<j )) )) && wb \$rrd \$(( n&$(( 255-(1<<j) )) )); return 0; }  # from $0.$LINENO\n"
    done
done

printf "# (HL) (IX) and (IY) instructions - these can not use D\n"
for rp in hl xX yY; do 
    rh=${rp::1}
    rl=${rp:1}
    RP=${RPN[$rp]}
    RR="rr=($rh<<8)|$rl"
    SETrpnn="$rh=nn>>8,$rl=nn&255"

    printf "acc_JP$RP()      { (( $RR, pc=rr )); return 0; }  # from $0.$LINENO\n"
    printf "acc_LDSP$RP()    { (( $RR, sp=rr )); return 0; }  # from $0.$LINENO\n"
    printf "acc_ADD${RP}SP() { (( $RR, nn=(rr+sp)       &65535 )); setfADD16 \$rr \$sp \$nn; (( $SETrpnn )); return 0; }  # from $0.$LINENO\n"
    printf "acc_ADC${RP}SP() { (( $RR, nn=(rr+sp+(f&FC))&65535 )); setfADC16 \$rr \$sp \$nn; (( $SETrpnn )); return 0; }  # from $0.$LINENO\n"
    printf "acc_SBC${RP}SP() { (( $RR, nn=(rr-sp-(f&FC))&65535 )); setfSBC16 \$rr \$sp \$nn; (( $SETrpnn )); return 0; }  # from $0.$LINENO\n"
done

printf "# Rotate instructions - m is bit that moves to carry - timing checked\n"
SETF="setfROTa 0 \$m \$a"
printf "acc_RLA()   { (( m=a>>7, a=((a<<1)|(f&FC))&255 )); $SETF; }  # from $0.$LINENO\n"
printf "acc_RRA()   { (( m=a&FC, a=((a>>1)|(f<<7))&255 )); $SETF; }  # from $0.$LINENO\n"
printf "acc_RLCA()  { (( m=a>>7, a=((a<<1)|(a>>7))&255 )); $SETF; }  # from $0.$LINENO\n"
printf "acc_RRCA()  { (( m=a&FC, a=((a>>1)|(a<<7))&255 )); $SETF; }  # from $0.$LINENO\n"

printf "# 16 bit register instructions - timing checked\n"
for rp in bc de hl af xX yY; do 
    rh=${rp::1}
    rl=${rp:1}
    RP=${RPN[$rp]}
    RR="rr=($rh<<8)|$rl"
    eval "INCrp=\$INC$rp; DECrp=\$DEC$rp"
    SETrpnn="$rh=nn>>8,$rl=nn&255"

    printf "acc_INC$RP()    { (( $INCrp )); return 0; }  # from $0.$LINENO\n"
    printf "acc_DEC$RP()    { (( $DECrp )); return 0; }  # from $0.$LINENO\n"
    printf "acc_LD${RP}nn() { (( $SETrpnn ));                     return 0; }  # from $0.$LINENO\n"
    printf "acc_LDmm$RP()   { (( $RR )); ww \$mm \$rr;                      }  # from $0.$LINENO\n"
    printf "acc_LD${RP}mm() {            rw \$mm; (( $SETrpnn )); return 0; }  # from $0.$LINENO\n"

    printf "acc_PUSH$RP()   { pushb \$$rh; pushb \$$rl;           }  # from $0.$LINENO\n"
    printf "acc_POP$RP()    { popn; $rl=n; popn; $rh=n; return 0; }  # from $0.$LINENO\n"
    
    for rp2 in hl xX yY; do 
        rh2=${rp2::1}
        rl2=${rp2:1}
        RP2=${RPN[$rp2]}
        RR2="rr2=($rh2<<8)|$rl2"
        SETrp2nn="$rh2=nn>>8,$rl2=nn&255"
        
        printf "acc_ADC$RP2$RP(){ (( $RR2, $RR, nn=(rr2+rr+(f&FC))&65535, $SETrp2nn )); setfADC16 \$rr2 \$rr \$nn; }  # from $0.$LINENO\n"
        printf "acc_SBC$RP2$RP(){ (( $RR2, $RR, nn=(rr2-rr-(f&FC))&65535, $SETrp2nn )); setfSBC16 \$rr2 \$rr \$nn; }  # from $0.$LINENO\n"
        printf "acc_ADD$RP2$RP(){ (( $RR2, $RR, nn=(rr2+rr)       &65535, $SETrp2nn )); setfADD16 \$rr2 \$rr \$nn; }  # from $0.$LINENO\n"
    done
done

printf "# SP instructions - timing checked\n"
printf "acc_LDSPnn() {               sp=nn; return 0; }  # from $0.$LINENO\n"
printf "acc_LDmmSP() { ww \$mm \$sp;        return 0; }  # from $0.$LINENO\n"
printf "acc_LDSPmm() { rw \$mm;      sp=nn; return 0; }  # from $0.$LINENO\n"
printf "acc_INCSP()  {             (( $INCSP )); return 0; }  # from $0.$LINENO\n"
printf "acc_DECSP()  {             (( $DECSP )); return 0; }  # from $0.$LINENO\n"

printf "acc_EXAFAF() { n=a; a=a1; a1=n; n=f; f=f1; f1=n; return 0; }  # from $0.$LINENO\n"
#printf "acc_EXX()    { for g in b c d e h l; do eval \"((n=\$g,\$g=\${g}1,\${g}1=n))\"; done; return 0; }  # from $0.$LINENO\n"
DF=
for g in b c d e h l; do
    DF+="n=$g,$g=${g}1,${g}1=n,"
done
printf "acc_EXX()    { (( ${DF:: -1} )); return 0; }  # from $0.$LINENO\n"

printf "# RST instructions - flags, timing checked\n"
for p in '00' '08' 10 18 20 28 30 38; do
    printf "acc_RST$p() { pushw \$pc; pc=0x00$p; return 0; }  # from $0.$LINENO\n"
done
} >> $GEN

