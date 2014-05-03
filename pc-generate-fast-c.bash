#!/bin/bash

# Fast C functions

{
printf "# Generated functions\n"
printf "void DAA(){
    int _diff, _fc, _fh, _hc
    local _NF=\${HEX[(f&FN)>>1]} _CF=\${HEX[f&FC]} _hi=\${HEX[a>>4]} _HF=\${HEX[(f&FH)>>4]} _lo=\${HEX[a&15]}
    local _K=\${_CF}\${_hi}\${_HF}\${_lo}
    case \$_K in
        0[0-9]0[0-9]) _diff=0x00;;
        0[0-9]1[0-9]) _diff=0x06;;
        0[0-8]?[a-f]) _diff=0x06;;
        0[a-f]0[0-9]) _diff=0x60;;
            1?0[0-9]) _diff=0x60;;
            1?1[0-9]) _diff=0x66;;
            1??[a-f]) _diff=0x66;;
        0[9-f]?[a-f]) _diff=0x66;;
        0[a-f]1[0-9]) _diff=0x66;;
        *) printf \"$FUNCNAME: Unknown diff pattern\n\"; exit 1
    esac
    local _K=\${_CF}\${_hi}\${_lo}
    case \$_K in
        0[0-9][0-9]) _fc=0;;
        0[0-8][a-f]) _fc=0;;
        0[9-f][a-f]) _fc=1;;
        0[a-f][0-9]) _fc=1;;
                1??) _fc=1;;
        *) printf \"$FUNCNAME: Unknown CF pattern\n\"; exit 1
    esac
    local _K=\${_NF}\${_HF}\${_lo}
    case \$_K in
        0?[0-9]) _fh=0;;
        0?[a-f]) _fh=FH;;
            10?) _fh=0;;
        11[6-f]) _fh=0;;
        11[0-5]) _fh=FH;;
        *) printf \"$FUNCNAME: Unknown HF pattern\n\"; exit 1
    esac
    (( _hc=_fh|_fc ))
    (( a=(a+((f&FN)?(-_diff):_diff))&255 )); setfDAA 0 \$_hc \$a
}  # from $0.$LINENO\n"

printf "# Some loads - timing checked\n"
printf "void LDAmm() { rmm(); rb(mm); a=n; }  # from $0.$LINENO\n"
printf "void LDmmA() { rmm(); wb(mm,a);  }  # from $0.$LINENO\n"
printf "void LDBCmA(){ wb($cBCV,a); }  # from $0.$LINENO\n"
printf "void LDDEmA(){ wb($cDEV,a); }  # from $0.$LINENO\n"
printf "void LDABCm(){ rb($cBCV; a=n; }  # from $0.$LINENO\n"
printf "void LDADEm(){ rb($cDEV; a=n; }  # from $0.$LINENO\n"
printf "void LDSPnn(){ rnn; sp=nn; }  # from $0.$LINENO\n"

printf "# Jumps, calls and returns - timing checked\n"
printf "void JPnn()  { rnn; pc=nn; }  # from $0.$LINENO\n"
printf "void JRn()   { rD; (( $NNPCD, pc=nn )); }  # from $0.$LINENO\n"
printf "void CALLnn(){ rnn; pushpcnn; }  # from $0.$LINENO\n"
printf "void RET()   { poppc;            }  # from $0.$LINENO\n"
printf "void RETI()  { poppc; iff1=iff2; }  # from $0.$LINENO\n"
printf "void RETN()  { poppc; iff1=iff2; }  # from $0.$LINENO\n"

printf "# Conditional Jump, Call, and Return instructions - timing checked\n"
for g in "Z:NZ:Z" "C:NC:C" "PE:PO:P" "M:P:S"; do S=${g%%:*}; N=${g#*:}; N=${N%:*}; F=${g##*:}  # Set, Not set, and Flag name
    printf "void JP${N}nn()  { rnn;         (( f&F$F?0:(pc=nn) )); return 0; }  # from $0.$LINENO\n"
    printf "void JP${S}nn()  { rnn;         (( f&F$F?(pc=nn):0 )); return 0; }  # from $0.$LINENO\n"
    printf "void JR${N}n()   { rD;  (( $NNPCD, f&F$F?0:(pc=nn) )); return 0; }  # from $0.$LINENO\n"
    printf "void JR${S}n()   { rD;  (( $NNPCD, f&F$F?(pc=nn):0 )); return 0; }  # from $0.$LINENO\n"
    printf "void CALL${N}nn(){ rnn; (( f&F$F )) || pushpcnn;           }  # from $0.$LINENO\n"
    printf "void CALL${S}nn(){ rnn; (( f&F$F )) && pushpcnn; return 0; }  # from $0.$LINENO\n"
    printf "void RET$N()     {      (( f&F$F )) || poppc;              }  # from $0.$LINENO\n"
    printf "void RET$S()     {      (( f&F$F )) && poppc;    return 0; }  # from $0.$LINENO\n"
done

printf "# block move - timing checked\n"
# Notes: must unset AREA after reading character from (DE)
INCBLOCK="$INChl,$INCde,$DECbc"
INCBLOCKR="$INChl,$INCde,$DECBC,$SETbc,(bc>0)?(pc=(pc-2)&65535):(q+=3,t+=12)"
DECBLOCK="$DEChl,$DECde,$DECbc"
DECBLOCKR="$DEChl,$DECde,$DECBC,$SETbc,(bc>0)?(pc=(pc-2)&65535):(q+=3,t+=12)"
printf "void LDI(){ (( $HL, $DE, $BC )); rb \$hl; wb \$de \$n; (( $INCBLOCK )); setfLDI 0 \$a \$n; }  # from $0.$LINENO\n"
printf "void LDD(){ (( $HL, $DE, $BC )); rb \$hl; wb \$de \$n; (( $DECBLOCK )); setfLDI 0 \$a \$n; }  # from $0.$LINENO\n"
# FIXME: dummy
printf "void CPI(){ (( $HL, $DE, $BC )); rb \$hl; wb \$de \$n; (( $INCBLOCK )); setfLDI 0 \$a \$n; }  # from $0.$LINENO\n"
printf "void CPD(){ (( $HL, $DE, $BC )); rb \$hl; wb \$de \$n; (( $DECBLOCK )); setfLDI 0 \$a \$n; }  # from $0.$LINENO\n"
# z80 implementation of LDIR is LDI + no change to PC - this is inefficient in an emulator due to composing and decomposing double registers each itteration

# alternative implementation for efficiency - but can still be done better - timing wrong?
printf "LDIR(){ 
    (( $HL, $DE, $BC ))
    while ((bc>0)); do
        rb \$hl; wb \$de \$n
        (( $INCHL, $INCDE, bc-=1 ))              # just inc and dec double registers
    done
    (( $SEThl, $SETde, b=c=0 ))                  # copy results into registers
    setfLDIR 0 $a $n                             # flags set on last character moved
    return 0;
}  # from $0.$LINENO\n"

printf "LDDR(){ 
    (( $HL, $DE, $BC ))
    while ((bc>0)); do
        rb \$hl; wb \$de \$n
        (( $DECHL, $DECDE, bc-=1 ))              # just dec double registers
    done
    (( $SEThl, $SETde, b=c=0 ))                  # copy results into registers
    setfLDIR 0 $a $n                             # flags set on last character moved
    return 0;
}  # from $0.$LINENO\n"

printf "# misc - timing checked\n"
printf "DJNZn(){ rD; (( $NNPCD, b=(b-1)&255, b?(pc=nn):0 )); return 0; }  # from $0.$LINENO\n"

printf "NOP() { return 0; }  # from $0.$LINENO\n"
printf "HALT(){ halt=1; return 0; }  # from $0.$LINENO\n"

printf "DI() { iff1=iff2=0; return 0; }  # from $0.$LINENO\n"
printf "EI() { iff1=iff2=1; return 0; }  # from $0.$LINENO\n"
printf "IM1(){ return 0; }  # from $0.$LINENO\n"
printf "IM2(){ return 0; }  # from $0.$LINENO\n"
printf "IM3(){ return 0; }  # from $0.$LINENO\n"

printf "EXSPmHL(){ rw \$sp; (( $HL )); ww \$sp \$hl; (( $SEThlnn )); return 0; }  # from $0.$LINENO\n"

printf "# IN and OUT - timing checked\n"
printf "OUTnA(){ rn; wp \$n \$a; }  # from $0.$LINENO\n"
printf "INAn() { rm; rp \$m; a=n; return 0; }  # from $0.$LINENO\n"

printf "# - timing checked\n"
printf "CPL(){ (( m=(~a)&255  )); setfCPL 0 0   \$m; a=m; return 0; }  # from $0.$LINENO\n"
printf "NEG(){ (( m=(0-a)&255 )); setfNEG 0 \$a \$m; a=m; return 0; }  # from $0.$LINENO\n"

printf "CCF(){ setfCCF 0 0 0; }  # from $0.$LINENO\n"
printf "SCF(){ setfSCF 0 0 0; }  # from $0.$LINENO\n"

SETF="setfRLD 0 0 \$a"
printf "RLD(){ (( $HL )); rb \$hl; (( m=a, a=(a&0xf0)|(n>>4), n=((n&15)<<4)|(m&15) )); wb \$hl \$n; $SETF; }  # from $0.$LINENO\n"
printf "RRD(){ (( $HL )); rb \$hl; (( m=a, a=(a&0xf0)|(n&15), n=((m&15)<<4)|(n>>4) )); wb \$hl \$n; $SETF; }  # from $0.$LINENO\n"

printf "# 8 bit register instructions - ?\n"
for r1 in b c d e h l a x X y Y; do R1=${RN[$r1]}
    for r2 in b c d e h l a x X y Y; do R2=${RN[$r2]}
        printf "LDrr_$r1$r2(){ $r1=$r2; return 0; }  # from $0.$LINENO\n"
    done
    
    printf "LDrHLm_$r1(){ (( $HL )); rb \$hl; $r1=n; return 0; }  # from $0.$LINENO\n"
    printf "LDHLmr_$r1(){ (( $HL )); wb \$hl \$$r1; }  # from $0.$LINENO\n"
    printf "LDrn_$r1()  { rn; $r1=n; return 0; }  # from $0.$LINENO\n"
    # fixed ordering problem: was $r1=n; rb \$mm;
    printf "LDrIXm_$r1(){ rD; (( $IX, mm=(ix+D)&65535 )); rb \$mm; $r1=n; return 0; }  # from $0.$LINENO\n"
    printf "LDrIYm_$r1(){ rD; (( $IY, mm=(iy+D)&65535 )); rb \$mm; $r1=n; return 0; }  # from $0.$LINENO\n"
    printf "LDIXmr_$r1(){ rD; (( $IX, mm=(ix+D)&65535 )); wb \$mm \$$r1; }  # from $0.$LINENO\n"
    printf "LDIYmr_$r1(){ rD; (( $IY, mm=(iy+D)&65535 )); wb \$mm \$$r1; }  # from $0.$LINENO\n"

    # BUG: where r1=a, ended up with setfADD n a a which means original value of a is lost
    # now, interestingly, these are same as CP
    # FIXME: could be more efficient if a=r1 is a special case
    
    printf "ADDr_$r1(){ (( m=(a+$r1)       &255 )); setfADD \$a \$$r1 \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "SUBr_$r1(){ (( m=(a-$r1)       &255 )); setfSUB \$a \$$r1 \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "ADCr_$r1(){ (( m=(a+$r1+(f&FC))&255 )); setfADC \$a \$$r1 \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "SBCr_$r1(){ (( m=(a-$r1-(f&FC))&255 )); setfSBC \$a \$$r1 \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "XORr_$r1(){ (( m=a^$r1              )); setfXOR \$a \$$r1 \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "ORr_$r1() { (( m=a|$r1              )); setfOR  \$a \$$r1 \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "ANDr_$r1(){ (( m=a&$r1              )); setfAND \$a \$$r1 \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "CPr_$r1() { (( m=(a-$r1)       &255 )); setfCP  \$a \$$r1 \$m;                }  # from $0.$LINENO\n"  # different

    printf "INCr_$r1(){ (( n=$r1, $r1=($r1+1)&255 )); setfINC \$n 1 \$$r1; }  # from $0.$LINENO\n"
    printf "DECr_$r1(){ (( n=$r1, $r1=($r1-1)&255 )); setfDEC \$n 1 \$$r1; }  # from $0.$LINENO\n"

    SETF="setfROTr 0 \$m \$$r1"
    printf "RLr_$r1() { (( m=$r1>>7, $r1=(($r1<<1)|(f&FC))  &255 )); $SETF; }  # from $0.$LINENO\n"
    printf "RRr_$r1() { (( m=$r1&FC, $r1=(($r1>>1)|(f<<7))  &255 )); $SETF; }  # from $0.$LINENO\n"
    printf "RLCr_$r1(){ (( m=$r1>>7, $r1=(($r1<<1)|($r1>>7))&255 )); $SETF; }  # from $0.$LINENO\n"
    printf "RRCr_$r1(){ (( m=$r1&FC, $r1=(($r1>>1)|($r1<<7))&255 )); $SETF; }  # from $0.$LINENO\n"
    printf "SLAr_$r1(){ (( m=$r1>>7, $r1=(($r1<<1)         )&255 )); $SETF; }  # from $0.$LINENO\n"
    printf "SLLr_$r1(){ (( m=$r1>>7, $r1=(($r1<<1)|1       )&255 )); $SETF; }  # from $0.$LINENO\n"
    printf "SRAr_$r1(){ (( m=$r1&FC, $r1=(($r1>>1)|($r1&FS))&255 )); $SETF; }  # from $0.$LINENO\n"
    printf "SRLr_$r1(){ (( m=$r1&FC, $r1=(($r1>>1)         )&255 )); $SETF; }  # from $0.$LINENO\n"

    for (( j=0; j<8; j++ )); do
        ORM=$(( 1<<j )); ANDM=$(( 255-ORM ))
        printf "BIT$j$r1(){ (( n=$r1&$ORM )); setfBIT 0 0 \$n; }  # from $0.$LINENO\n"
        printf "SET$j$r1(){ (( $r1|=$ORM  )); return 0; }  # from $0.$LINENO\n"
        printf "RES$j$r1(){ (( $r1&=$ANDM )); return 0; }  # from $0.$LINENO\n"
    done
done

printf "ADDn(){ rn; (( m=(a+n)       &255 )); setfADD \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
printf "SUBn(){ rn; (( m=(a-n)       &255 )); setfSUB \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
printf "ADCn(){ rn; (( m=(a+n+(f&FC))&255 )); setfADC \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
printf "SBCn(){ rn; (( m=(a-n-(f&FC))&255 )); setfSBC \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
printf "XORn(){ rn; (( m=(a^n)            )); setfXOR \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
printf "ORn() { rn; (( m=(a|n)            )); setfOR  \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
printf "ANDn(){ rn; (( m=(a&n)            )); setfAND \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
printf "CPn() { rn; (( m=(a-n)       &255 )); setfCP  \$a \$n \$m;                }  # from $0.$LINENO\n"  # different

printf "EXDEHL(){ n=d; d=h; h=n; n=e; e=l; l=n; return 0; }  # from $0.$LINENO\n"
printf "LDHLmn(){ (( $HL )); rn; wb \$hl \$n; }  # from $0.$LINENO\n"

printf "# (HL) instructions\n"
for rp in hl; do rh=${rp::1}; rl=${rp:1}; RP=${RPN[$rp]}; RR="rr=($rh<<8)|$rl"

    SETF="setfROTr 0 \$m \$n"
    _RB="(( $RR )); rb \$rr"  # was (( $RR )); rb \$rr
    _WB="wb \$rr \$n; $SETF"  # was wb \$rr \$n; $SETF
    printf "RL${RP}m() { $_RB; (( m=n>>7, n=((n<<1)|(f&FC))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "RR${RP}m() { $_RB; (( m=n&FC, n=((n>>1)|(f<<7))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "RLC${RP}m(){ $_RB; (( m=n>>7, n=((n<<1)|(n>>7))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "RRC${RP}m(){ $_RB; (( m=n&FC, n=((n>>1)|(n<<7))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SLA${RP}m(){ $_RB; (( m=n>>7, n=((n<<1)       )&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SRA${RP}m(){ $_RB; (( m=n&FC, n=((n>>1)|(n&FS))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SLL${RP}m(){ $_RB; (( m=n>>7, n=((n<<1)|1     )&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SRL${RP}m(){ $_RB; (( m=n&FC, n=((n>>1)       )&255 )); $_WB; }  # from $0.$LINENO\n"

    printf "INC${RP}m(){ $_RB; (( m=n,    n=(n+1)          &255 )); wb \$rr \$n; setfINC \$m 1 \$n; }  # from $0.$LINENO\n"
    printf "DEC${RP}m(){ $_RB; (( m=n,    n=(n-1)          &255 )); wb \$rr \$n; setfDEC \$m 1 \$n; }  # from $0.$LINENO\n"

    printf "ADD${RP}m(){ $_RB; (( m=(a+n)          &255 )); setfADD \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "SUB${RP}m(){ $_RB; (( m=(a-n)          &255 )); setfSUB \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "ADC${RP}m(){ $_RB; (( m=(a+n+(f&FC))   &255 )); setfADC \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "SBC${RP}m(){ $_RB; (( m=(a-n-(f&FC))   &255 )); setfSBC \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "XOR${RP}m(){ $_RB; (( m=(a^n)               )); setfXOR \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "OR${RP}m() { $_RB; (( m=(a|n)               )); setfOR  \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "AND${RP}m(){ $_RB; (( m=(a&n)               )); setfAND \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "CP${RP}m() { $_RB; (( m=(a-n)          &255 )); setfCP  \$a \$n \$m;                }  # from $0.$LINENO\n"  # different

    for (( j=0; j<8; j++ )); do
        _M=$(( 1<<j ))
        _N=$(( 255-_M ))
        printf "BIT$j${RP}m(){ $_RB; (( n&=$_M )); setfBITh $j \$h \$n; }  # from $0.$LINENO\n"
        printf "SET$j${RP}m(){ $_RB; (( n&$_M )) || wb \$rr \$(( n|$_M )); }  # from $0.$LINENO\n"
        printf "RES$j${RP}m(){ $_RB; (( n&$_M )) && wb \$rr \$(( n&$_N )); }  # from $0.$LINENO\n"
    done
done

printf "# 16 bit register instructions - assume D already read in map\n"
for rp in xX yY; do rh=${rp::1}; rl=${rp:1}; RP=${RPN[$rp]}; RR="rr=($rh<<8)|$rl"; RRD="rrd=(($rh<<8)+$rl+D)&65535"; RRDV="\$(( (($rh<<8)+$rl+D)&65535 ))"

    printf "LD${RP}mn(){ rD; (( $RR, $RRD )); rn; wb \$rrd \$n; }  # from $0.$LINENO\n"
    SETF="setfROTr 0 \$m \$n"
    _RB="(( $RRD )); rb \$rrd"
    _WB="wb \$rrd \$n; $SETF"  # was wb \$rrd \$n; $SETF
    printf "RL${RP}m() { $_RB; (( m=n>>7, n=((n<<1)|(f&FC))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "RR${RP}m() { $_RB; (( m=n&FC, n=((n>>1)|(f<<7))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "RLC${RP}m(){ $_RB; (( m=n>>7, n=((n<<1)|(n>>7))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "RRC${RP}m(){ $_RB; (( m=n&FC, n=((n>>1)|(n<<7))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SLA${RP}m(){ $_RB; (( m=n>>7, n=((n<<1)       )&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SRA${RP}m(){ $_RB; (( m=n&FC, n=((n>>1)|(n&FS))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SLL${RP}m(){ $_RB; (( m=n>>7, n=((n<<1)|1     )&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SRL${RP}m(){ $_RB; (( m=n&FC, n=((n>>1)       )&255 )); $_WB; }  # from $0.$LINENO\n"

    for r1 in a b c d e  h l; do R1=${RN[$r1]} 
        printf "RL${RP}mr_$r1() { $_RB; (( m=n>>7, n=((n<<1)|(f&FC))&255, $r1=n )); $_WB; }  # from $0.$LINENO\n"
        printf "RLC${RP}mr_$r1(){ $_RB; (( m=n>>7, n=((n<<1)|(n>>7))&255, $r1=n )); $_WB; }  # from $0.$LINENO\n"
        printf "SLA${RP}mr_$r1(){ $_RB; (( m=n>>7, n=((n<<1)       )&255, $r1=n )); $_WB; }  # from $0.$LINENO\n"
        printf "SLL${RP}mr_$r1(){ $_RB; (( m=n>>7, n=((n<<1)|1     )&255, $r1=n )); $_WB; }  # from $0.$LINENO\n"
    done

    for (( j=0; j<8; j++ )); do
        _M=$(( 1<<j ))
        _N=$(( 255-_M ))
        printf "BIT$j${RP}m(){ $_RB; (( m=n&$_M )); setfBITx $j \$((rrd>>8)) \$m; }  # from $0.$LINENO\n"  # [SY05]
        printf "SET$j${RP}m(){ $_RB; (( n&$_M )) || wb \$rrd \$(( n|$_M )); }  # from $0.$LINENO\n"
        printf "RES$j${RP}m(){ $_RB; (( n&$_M )) && wb \$rrd \$(( n&$_N )); }  # from $0.$LINENO\n"
    done

    printf "INC${RP}m(){ rD; $_RB; (( m=(n+1)&255 )); setfINC \$n 1 \$m; wb \$rrd \$m; }  # from $0.$LINENO\n"
    printf "DEC${RP}m(){ rD; $_RB; (( m=(n-1)&255 )); setfDEC \$n 1 \$m; wb \$rrd \$m; }  # from $0.$LINENO\n"

    # FIXME: do for others if ok
    _RB="rD; rb $RRDV"
    printf "ADD${RP}m(){ $_RB; (( m=(a+n)       &255 )); setfADD \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "SUB${RP}m(){ $_RB; (( m=(a-n)       &255 )); setfSUB \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "ADC${RP}m(){ $_RB; (( m=(a+n+(f&FC))&255 )); setfADC \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "SBC${RP}m(){ $_RB; (( m=(a-n-(f&FC))&255 )); setfSBC \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "XOR${RP}m(){ $_RB; (( m=(a^n)            )); setfXOR \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "OR${RP}m() { $_RB; (( m=(a|n)            )); setfOR  \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "AND${RP}m(){ $_RB; (( m=(a&n)            )); setfAND \$a \$n \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "CP${RP}m() { $_RB; (( m=(a-n)       &255 )); setfCP  \$a \$n \$m;                }  # from $0.$LINENO\n"  # different
done

printf "# (HL) (IX) and (IY) instructions - these can not use D\n"
for rp in hl xX yY; do 
    rh=${rp::1}
    rl=${rp:1}
    RP=${RPN[$rp]}
    RR="rr=($rh<<8)|$rl"
    SETrpnn="$rh=nn>>8,$rl=nn&255"

    printf "JP$RP()     { (( $RR, pc=rr )); return 0; }  # from $0.$LINENO\n"
    printf "LDSP$RP()   { (( $RR, sp=rr )); return 0; }  # from $0.$LINENO\n"
    printf "ADD${RP}SP(){ (( $RR, nn=(rr+sp)       &65535 )); setfADD16 \$rr \$sp \$nn; (( $SETrpnn )); return 0; }  # from $0.$LINENO\n"
    printf "ADC${RP}SP(){ (( $RR, nn=(rr+sp+(f&FC))&65535 )); setfADC16 \$rr \$sp \$nn; (( $SETrpnn )); return 0; }  # from $0.$LINENO\n"
    printf "SBC${RP}SP(){ (( $RR, nn=(rr-sp-(f&FC))&65535 )); setfSBC16 \$rr \$sp \$nn; (( $SETrpnn )); return 0; }  # from $0.$LINENO\n"
done

printf "# Rotate instructions - m is bit that moves to carry - timing checked\n"
SETF="setfROTa 0 \$m \$a"
printf "RLA() { (( m=a>>7, a=((a<<1)|(f&FC))&255 )); $SETF; }  # from $0.$LINENO\n"
printf "RRA() { (( m=a&FC, a=((a>>1)|(f<<7))&255 )); $SETF; }  # from $0.$LINENO\n"
printf "RLCA(){ (( m=a>>7, a=((a<<1)|(a>>7))&255 )); $SETF; }  # from $0.$LINENO\n"
printf "RRCA(){ (( m=a&FC, a=((a>>1)|(a<<7))&255 )); $SETF; }  # from $0.$LINENO\n"

printf "# 16 bit register instructions - timing checked\n"
for rp in bc de hl af xX yY; do 
    rh=${rp::1}
    rl=${rp:1}
    RP=${RPN[$rp]}
    RR="rr=($rh<<8)|$rl"
    eval "INCrp=\$INC$rp; DECrp=\$DEC$rp"
    SETrpnn="$rh=nn>>8,$rl=nn&255"

    printf "INC$RP()   { (( $INCrp )); return 0; }  # from $0.$LINENO\n"
    printf "DEC$RP()   { (( $DECrp )); return 0; }  # from $0.$LINENO\n"
    printf "LD${RP}nn(){ rn; rm; (( $rl=n, $rh=m ));        return 0; }  # from $0.$LINENO\n"
    printf "LDmm$RP()  { rmm; wb2 \$mm \$$rl \$$rh;                   }  # from $0.$LINENO\n"
    printf "LD${RP}mm(){ rmm; rb2 \$mm; (( $rl=n, $rh=m )); return 0; }  # from $0.$LINENO\n"

    printf "PUSH$RP(){ pushb \$$rh; pushb \$$rl;           }  # from $0.$LINENO\n"
    printf "POP$RP() { popmn; $rl=n; $rh=m;      return 0; }  # from $0.$LINENO\n"
    
    for rp2 in hl xX yY; do 
        rh2=${rp2::1}
        rl2=${rp2:1}
        RP2=${RPN[$rp2]}
        RR2="rr2=($rh2<<8)|$rl2"
        SETrp2nn="$rh2=nn>>8,$rl2=nn&255"
        
        printf "ADC$RP2$RP(){ (( $RR2, $RR, nn=(rr2+rr+(f&FC))&65535, $SETrp2nn )); setfADC16 \$rr2 \$rr \$nn; }  # from $0.$LINENO\n"
        printf "SBC$RP2$RP(){ (( $RR2, $RR, nn=(rr2-rr-(f&FC))&65535, $SETrp2nn )); setfSBC16 \$rr2 \$rr \$nn; }  # from $0.$LINENO\n"
        printf "ADD$RP2$RP(){ (( $RR2, $RR, nn=(rr2+rr)       &65535, $SETrp2nn )); setfADD16 \$rr2 \$rr \$nn; }  # from $0.$LINENO\n"
    done
done

printf "# SP instructions - timing checked\n"
printf "LDSPnn(){ rnn;               sp=nn; return 0; }  # from $0.$LINENO\n"
printf "LDmmSP(){ rmm; ww \$mm \$sp;        return 0; }  # from $0.$LINENO\n"
printf "LDSPmm(){ rmm; rw \$mm;      sp=nn; return 0; }  # from $0.$LINENO\n"
printf "INCSP() { (( $INCSP )); return 0; }  # from $0.$LINENO\n"
printf "DECSP() { (( $DECSP )); return 0; }  # from $0.$LINENO\n"

printf "EXAFAF(){ n=a; a=a1; a1=n; n=f; f=f1; f1=n; return 0; }  # from $0.$LINENO\n"
#printf "EXX(){ for g in b c d e h l; do eval \"((n=\$g,\$g=\${g}1,\${g}1=n))\"; done; return 0; }  # from $0.$LINENO\n"
DF=
for g in b c d e h l; do
    DF+="n=$g,$g=${g}1,${g}1=n,"
done
printf "EXX(){ (( ${DF:: -1} )); return 0; }  # from $0.$LINENO\n"

printf "# RST instructions - flags, timing checked\n"
for p in '00' '08' 10 18 20 28 30 38; do
    printf "RST$p(){ pushw \$pc; pc=0x00$p; return 0; }  # from $0.$LINENO\n"
done
} >> $GEN

