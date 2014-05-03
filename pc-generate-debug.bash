#!/bin/bash

# Debug functions

{
printf "# Generated functions\n"
printf "DAA(){
    local -i _diff _fc _fh _hc
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
    dis DAA; (( a=(a+((f&FN)?(-_diff):_diff))&255, q=1, t=4 )); setfDAA 0 \$_hc \$a
}  # from $0.$LINENO\n"

printf "XDAA() {
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
    dis DAA; (( a=a+((f&FN)?(-diff):diff), q=1, t=4 )); setfDAA 0 \$_hc \$a
}  # from $0.$LINENO\n"

printf "# Some loads - timing checked\n"
printf "LDAmm()  { rmm;       rb \$mm; dis LD \"A=$B,($W)=$B\"    \$a  \$mm \$n;              (( q=4, t=13, a=n   )); return 0; }  # from $0.$LINENO\n"
printf "LDmmA()  { rmm;                dis LD \"($W),A=$B\"       \$mm \$a;      wb \$mm \$a; (( q=4, t=13        )); return 0; }  # from $0.$LINENO\n"
printf "LDBCmA() { (( $BC ));          dis LD \"(BC=$W),A=$B\"    \$bc \$a;      wb \$bc \$a; (( q=2, t=7         )); return 0; }  # from $0.$LINENO\n"
printf "LDDEmA() { (( $DE ));          dis LD \"(DE=$W),A=$B\"    \$de \$a;      wb \$de \$a; (( q=2, t=7         )); return 0; }  # from $0.$LINENO\n"
printf "LDABCm() { (( $BC )); rb \$bc; dis LD \"A=$B,(BC=$W)=$B\" \$a  \$bc \$n;              (( q=2, t=7,  a=n   )); return 0; }  # from $0.$LINENO\n"
printf "LDADEm() { (( $DE )); rb \$de; dis LD \"A=$B,(DE=$W)=$B\" \$a  \$de \$n;              (( q=2, t=7,  a=n   )); return 0; }  # from $0.$LINENO\n"
printf "LDSPnn() { rnn;                dis LD \"SP=$W,$W\"        \$sp \$nn;                  (( q=6, t=20, sp=nn )); return 0; }  # from $0.$LINENO\n"

printf "# Jumps, calls and returns - timing checked\n"
printf "JPnn()   { rnn;   (( q=3, t=10 ));                dnn JP   \"$W\"                    \$nn; pc=nn;            return 0; }  # from $0.$LINENO\n"
printf "CALLnn() { rnn;   (( q=5, t=17 )); pushw \$pc;    dnn CALL \"$W\"                    \$nn; pc=nn;            return 0; }  # from $0.$LINENO\n"
printf "JRn()    { rD;    (( q=3, t=12, $NNPCD ));        dnn JR   \"$R:$W\"      \$D        \$nn; pc=nn;            return 0; }  # from $0.$LINENO\n"
printf "RET()    { popnn; (( q=3, t=10 ));                dis RET  \"(SP=$W)=$W\" \$((sp-2)) \$nn; pc=nn;            return 0; }  # from $0.$LINENO\n"
printf "RETI()   { popnn; (( q=3, t=10 ));                dis RETI \"(SP=$W)=$W\" \$((sp-2)) \$nn; pc=nn; iff1=iff2; return 0; }  # from $0.$LINENO\n"
printf "RETN()   { popnn; (( q=3, t=10 ));                dis RETN \"(SP=$W)=$W\" \$((sp-2)) \$nn; pc=nn; iff1=iff2; return 0; }  # from $0.$LINENO\n"

printf "# Conditional Jump, Call, and Return instructions - timing checked\n"
for g in "Z:NZ:Z" "C:NC:C" "PE:PO:P" "M:P:S"; do S=${g%%:*}; N=${g#*:}; N=${N%:*}; F=${g##*:}  # Set, Not set, and Flag name
    printf "JP${N}nn()   { rnn;     (( q=3, t=7  ));        dnn JP   \"$N,$W\"          \$nn; (( f&F$F )) || {             pc=nn; q+=1; t+=5; }; return 0; }  # from $0.$LINENO\n"
    printf "JP${S}nn()   { rnn;     (( q=3, t=7  ));        dnn JP   \"$S,$W\"          \$nn; (( f&F$F )) && {             pc=nn; q+=1; t+=5; }; return 0; }  # from $0.$LINENO\n"
    #printf "CALL${N}nn() { rnn;     (( q=3, t=10 ));        dnn CALL \"$N,$W\"          \$nn; (( f&F$F )) || { pushw \$pc; pc=nn;             }; return 0; }  # from $0.$LINENO\n"
    #printf "CALL${S}nn() { rnn;     (( q=3, t=10 ));        dnn CALL \"$S,$W\"          \$nn; (( f&F$F )) && { pushw \$pc; pc=nn;             }; return 0; }  # from $0.$LINENO\n"
    printf "CALL${N}nn() { rnn;     (( q=3, t=10 ));        dnn CALL \"$N,$W\"          \$nn; (( f&F$F )) || pushpcnn;           }  # from $0.$LINENO\n"
    printf "CALL${S}nn() { rnn;     (( q=3, t=10 ));        dnn CALL \"$S,$W\"          \$nn; (( f&F$F )) && pushpcnn; return 0; }  # from $0.$LINENO\n"
    printf "RET$N()      { rw \$sp; (( q=1, t=5  ));        dis RET  \"$N (SP)=$W\"     \$nn; (( f&F$F )) || { poppc; q+=2; t+=6; }; return 0; }  # from $0.$LINENO\n"
    printf "RET$S()      { rw \$sp; (( q=1, t=5  ));        dis RET  \"$S (SP)=$W\"     \$nn; (( f&F$F )) && { poppc; q+=2; t+=6; }; return 0; }  # from $0.$LINENO\n"
    printf "JR${N}n()    { rD;      (( q=2, t=7, $NNPCD )); dis JR   \"$N,$R:$W\"   \$D \$nn; (( f&F$F )) || {             pc=nn; q+=1; t+=5; }; return 0; }  # from $0.$LINENO\n"
    printf "JR${S}n()    { rD;      (( q=2, t=7, $NNPCD )); dis JR   \"$S,$R:$W\"   \$D \$nn; (( f&F$F )) && {             pc=nn; q+=1; t+=5; }; return 0; }  # from $0.$LINENO\n"
done

printf "# block move - timing checked\n"
# Notes: must unset AREA after reading character from (DE)
DF="\"; (HL=$W)=$B -> (DE=$W)=$B BC=$W $C\" \$hl \$n \$de \$m \$bc \"\${CHR[n]}\""
INCBLOCK="$INChl,$INCde,$DECbc"
INCBLOCKR="$INChl,$INCde,$DECBC,$SETbc,(bc>0)?(pc=(pc-2)&65535):(q+=3,t+=12)"
DECBLOCK="$DEChl,$DECde,$DECbc"
DECBLOCKR="$DEChl,$DECde,$DECBC,$SETbc,(bc>0)?(pc=(pc-2)&65535):(q+=3,t+=12)"
QT="q=3,t=12"
printf "LDI()  { (( $HL, $DE, $BC, $QT )); rb \$de; m=n; unset \"AREA\"; rb \$hl; wb \$de \$n; dis LDI  $DF; (( $INCBLOCK )); setfLDI 0 \$a \$n; }  # from $0.$LINENO\n"
printf "LDD()  { (( $HL, $DE, $BC, $QT )); rb \$de; m=n; unset \"AREA\"; rb \$hl; wb \$de \$n; dis LDD  $DF; (( $DECBLOCK )); setfLDI 0 \$a \$n; }  # from $0.$LINENO\n"
# z80 implementation of LDIR is LDI + no change to PC - this is inefficient in an emulator due to composing and decomposing double registers each itteration
QT="q=4,t=16"
printf "XLDIR() { (( $HL, $DE, $BC, $QT )); rb \$de; m=n; unset \"AREA\"; rb \$hl; wb \$de \$n; dis LDIR $DF; (( $INCBLOCKR )); setfLDIR 0 \$a \$n; }  # from $0.$LINENO\n"
printf "XLDDR() { (( $HL, $DE, $BC, $QT )); rb \$de; m=n; unset \"AREA\"; rb \$hl; wb \$de \$n; dis LDDR $DF; (( $DECBLOCKR )); setfLDIR 0 \$a \$n; }  # from $0.$LINENO\n"

DF="\"; A=$B,(HL=$W)=$B  BC=$W $C\" \$a \$hl \$n \$bc \"\${CHR[n]}\""
printf "CPI()  { (( $HL, $BC, $QT )); rb \$hl; m=(a-n)&255; unset \"AREA\"; dis CPI  $DF; (( $INChl,$DECbc )); setfCPI \$a \$n \$m; }  # from $0.$LINENO\n"
printf "CPD()  { (( $HL, $BC, $QT )); rb \$hl; m=n; unset \"AREA\"; dis CPD  $DF; (( $DECBLOCK )); setfCPI 0 \$a \$n; }  # from $0.$LINENO\n"


# alternative implementation for efficiency - but can still be done better - timing wrong?
printf "LDIR() { local -i hl0 de0 bc0 ta; local data; 
    (( $HL, $DE, $BC, q=bc*5+4-1, t=bc*21+16-4, hl0=hl, de0=de, bc0=bc, r=(r&128)|(r+(bc*2))&127 ))
    #ta=hl0; dump20
    #ta=de0; dump20
    while ((bc>0)); do
        rb \$de; m=n                             # get dest char for dis
        unset \"AREA\"                           # unset here since we access (DE) twice - ignore first time
        rb \$hl; wb \$de \$n                     # capture memory AREA names from here
        ! $_FAST && {                               # if disassembling, collect copied data
            data+=\"${CHR[n]}\"                  # save byte copied into string
            (( n!=m )) && dis LDIR \"; (HL=$W)=$B->(DE=$W)=$B BC=$W [%%b]\" \$hl \$n \$de \$m \$bc \"${CHR[n]}\" 
        }
        (( $INCHL, $INCDE, bc-=1 ))              # just inc and dec double registers
    done
    #ta=hl0; dump20
    #ta=de0; dump20
    (( $SEThl, $SETde, b=c=0 ))                  # copy results into registers
    setfLDIR 0 $a $n                             # flags set on last character moved
    unset \"AREA\"
    rb \$hl0; rb \$de0                           # extra memory reads to set AREA names
    dis LDIR \"; (HL=$W)->(DE=$W) * BC=$W\n[%%b]\" \$hl0 \$de0 \$bc0 \"\$data\"
    return 0;
}  # from $0.$LINENO\n"

printf "LDDR() { local -i hl0 de0 bc0; local data; 
    (( $HL, $DE, $BC, q=bc*5+4-1, t=bc*21+16-4, hl0=hl, de0=de, bc0=bc, r=(r&128)|(r+(bc*2))&127 ))
    while ((bc>0)); do
        rb \$de; m=n                             # get dest char for dis
        unset \"AREA\"                           # unset here since we access (DE) twice - ignore first time
        rb \$hl; wb \$de \$n                     # capture memory AREA names from here
        ! $_FAST && {                               # if disassembling, collect copied data
            data+=\"${CHR[n]}\"                  # save byte copied into string
            (( n!=m )) && dis LDDR \"; (HL=$W)=$B->(DE=$W)=$B BC=$W [%%b]\" \$hl \$n \$de \$m \$bc \"${CHR[n]}\" 
        }
        (( $DECHL, $DECDE, bc-=1 ))              # just dec double registers
    done
    (( $SEThl, $SETde, b=c=0 ))                  # copy results into registers
    setfLDIR 0 $a $n                             # flags set on last character moved
    unset \"AREA\"
    rb \$hl0; rb \$de0                           # extra memory reads to set AREA names
    dis LDDR \"; (HL=$W)->(DE=$W) * BC=$W\n[%%b]\" \$hl0 \$de0 \$bc0 \"\$data\"  # FIXME: hl and de are at top of data
    return 0;
}  # from $0.$LINENO\n"

printf "# misc - timing checked\n"
DF="\"$R:$W ; B=$B\" \$D \$nn \$b"
printf "DJNZn() { rD; (( $NNPCD )); dis DJNZ $DF; (( b=(b-1)&255, b?(pc=nn,q=3,t=13):(q=2,t=8) )); return 0; }  # from $0.$LINENO\n"

QT="q=1,t=4"
printf "NOP()   { dis NOP;  (( $QT ));         return 0; }  # from $0.$LINENO\n"
printf "HALT()  { dis HALT; (( $QT, halt=1 )); return 0; }  # from $0.$LINENO\n"

DF="\"; IFF1=%%d IFF2=%%d\" \$iff1 \$iff2"
printf "DI()    { dis DI $DF; (( $QT, iff1=iff2=0 )); return 0; }  # from $0.$LINENO\n"
printf "EI()    { dis EI $DF; (( $QT, iff1=iff2=1 )); return 0; }  # from $0.$LINENO\n"
printf "IM1()   { dis IM1; (( $QT )); return 0; }  # from $0.$LINENO\n"
printf "IM2()   { dis IM2; (( $QT )); return 0; }  # from $0.$LINENO\n"
printf "IM3()   { dis IM3; (( $QT )); return 0; }  # from $0.$LINENO\n"

DF="\"(SP=$W)=$W,HL=$W\" \$sp \$nn \$hl"
QT="q=5,t=19"
printf "EXSPmHL() { rw \$sp; (( $HL )); ww \$sp \$hl; dis EX $DF; (( $SEThlnn, $QT )); return 0; }  # from $0.$LINENO\n"

printf "# IN and OUT - timing checked\n"
DF="\"[$B],A=$B $C\" \$n \$a \"\${CHR[a]}\""
QT="q=3,t=11"
printf "OUTnA() { rn;         dis OUT $DF; (( $QT )); wp \$n \$a; return 0; }  # from $0.$LINENO\n"
DF="\"A,[$B]=$B $C\" \$m \$n \"\${CHR[n]}\""
printf "INAn()  { rm; rp \$m; dis IN  $DF; (( $QT, a=n ));             return 0; }  # from $0.$LINENO\n"

printf "# - timing checked\n"
DF="\"; A=$B $C\" \$a \"\${CHR[a]}\""
QT="q=1,t=4"
printf "CPL() { dis CPL $DF; (( $QT,      a=(~a)&255  )); setfCPL 0 0   \$a; }  # from $0.$LINENO\n"
printf "NEG() { dis NEG $DF; (( $QT, m=a, a=(0-a)&255 )); setfNEG 0 \$m \$a; }  # from $0.$LINENO\n"

DF="\"; CF=%%d\" \$((f&FC))"
printf "CCF() { dis CCF $DF; (( $QT ));                   setfCCF 0 0   0;   }  # from $0.$LINENO\n"
printf "SCF() { dis SCF $DF; (( $QT ));                   setfSCF 0 0   0;   }  # from $0.$LINENO\n"

DF="\"A=$B,(HL=$W)=$B $C\" \$a \$hl \$n \"\${CHR[n]}\""
QT="q=4,t=14"
SETF="setfRLD 0 0 \$a"
printf "RLD() { (( $HL, $QT )); rb \$hl; dis RLD $DF; (( m=a, a=(a&0xf0)|(n>>4), n=((n&15)<<4)|(m&15) )); wb \$hl \$n; $SETF; }  # from $0.$LINENO\n"
printf "RRD() { (( $HL, $QT )); rb \$hl; dis RRD $DF; (( m=a, a=(a&0xf0)|(n&15), n=((m&15)<<4)|(n>>4) )); wb \$hl \$n; $SETF; }  # from $0.$LINENO\n"

printf "# 8 bit register instructions - ?\n"
for r1 in b c d e h l a x X y Y; do R1=${RN[$r1]}
    for r2 in b c d e h l a x X y Y; do R2=${RN[$r2]}

        DF="\"$R1=$B,$R2=$B $C\" \$$r1 \$$r2 \"\${CHR[$r2]}\""
        QT="q=1,t=4"
        printf "LDrr_$r1$r2(){ dis LD $DF; (( $QT, $r1=$r2 )); return 0; }  # from $0.$LINENO\n"

    done
    
    DF="\"$R1=$B,(HL=$W)=$B $C\" \$$r1 \$hl \$n \"\${CHR[n]}\""
    QT="q=2,t=7"
    printf "LDrHLm_$r1(){ (( $HL )); rb \$hl;            dis LD $DF; (( $QT, $r1=n   )); return 0; }  # from $0.$LINENO\n"

    DF="\"(HL=$W),$R1=$B $C\" \$hl \$$r1 \"\${CHR[\$$r1]}\""
    printf "LDHLmr_$r1(){ (( $HL, $QT )); wb \$hl \$$r1; dis LD $DF;                               }  # from $0.$LINENO\n"

    DF="\"$R1=$B,$B $C @ $LINENO\" \$$r1 \$n \"\${CHR[n]}\""
    printf "LDrn_$r1()  { rn;                            dis LD $DF; (( $QT, $r1=n ));   return 0; }  # from $0.$LINENO\n"

    DF="\"$R1=$B,(IX=$W$R)=$W $C\" \$$r1 \$ix \$D \$mm \"\${CHR[n]}\""
    QT="q=2,t=8"
    printf "LDrIXm_$r1(){ rD; (( $IX, mm=(ix+D)&65535 )); rb \$mm; dis LD $DF; (( $QT, $r1=n ));   return 0; }  # from $0.$LINENO\n"

    DF="\"$R1=$B,(IY=$W$R)=$W $C\" \$$r1 \$iy \$D \$mm \"\${CHR[n]}\""
    printf "LDrIYm_$r1(){ rD; (( $IY, mm=(iy+D)&65535 )); rb \$mm; dis LD $DF; (( $QT, $r1=n ));   return 0; }  # from $0.$LINENO\n"

    DF="\"(IX=$W$R)=$W,$R1=$B $C\" \$ix \$D \$mm \$$r1 \"\${CHR[\$$r1]}\""
    QT="q=4,t=15"
    printf "LDIXmr_$r1(){ rD; (( $IX, mm=(ix+D)&65535, $QT )); wb \$mm \$$r1; dis LD $DF; }  # from $0.$LINENO\n"

    DF="\"(IY=$W$R)=$W,$R1=$B $C\" \$iy \$D \$mm \$$r1 \"\${CHR[\$$r1]}\""
    printf "LDIYmr_$r1(){ rD; (( $IY, mm=(iy+D)&65535, $QT )); wb \$mm \$$r1; dis LD $DF; }  # from $0.$LINENO\n"

    DF="\"A=$B,$R1=$B $C\" \$a \$$r1 \"\${CHR[\$$r1]}\""
    QT="q=1,t=4"
    printf "ADDr_$r1(){ dis ADD $DF; (( $QT, n=a, m=(a+$r1)       &255 )); setfADD \$n \$$r1 \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "SUBr_$r1(){ dis SUB $DF; (( $QT, n=a, m=(a-$r1)       &255 )); setfSUB \$n \$$r1 \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "ADCr_$r1(){ dis ADC $DF; (( $QT, n=a, m=(a+$r1+(f&FC))&255 )); setfADC \$n \$$r1 \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "SBCr_$r1(){ dis SBC $DF; (( $QT, n=a, m=(a-$r1-(f&FC))&255 )); setfSBC \$n \$$r1 \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "XORr_$r1(){ dis XOR $DF; (( $QT, n=a, m=a^$r1              )); setfXOR \$n \$$r1 \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "ORr_$r1() { dis OR  $DF; (( $QT, n=a, m=a|$r1              )); setfOR  \$n \$$r1 \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "ANDr_$r1(){ dis AND $DF; (( $QT, n=a, m=a&$r1              )); setfAND \$n \$$r1 \$m; a=m; return 0; }  # from $0.$LINENO\n"
    printf "CPr_$r1() { dis CP  $DF; (( $QT, n=a, m=(a-$r1)       &255 )); setfCP  \$n \$$r1 \$m;                }  # from $0.$LINENO\n"  # different

    #DF="\"$R1=$B $C\" \$$r1 \"\${CHR[\$$r1]}\""
    DF="\"$R1=$B $C @ $LINENO\" \$$r1 \"\${CHR[$r1]}\""
    printf "INCr_$r1(){ dis INC $DF; (( $QT, n=$r1, $r1=($r1+1)&255 )); setfINC \$n 1 \$$r1; }  # from $0.$LINENO\n"
    printf "DECr_$r1(){ dis DEC $DF; (( $QT, n=$r1, $r1=($r1-1)&255 )); setfDEC \$n 1 \$$r1; }  # from $0.$LINENO\n"

    SETF="setfROTr 0 \$m \$$r1"
    QT="q=2,t=8"
    printf "RLr_$r1() { dis RL  $DF; (( $QT, m=$r1>>7, $r1=(($r1<<1)|(f&FC))  &255 )); $SETF; }  # from $0.$LINENO\n"
    printf "RRr_$r1() { dis RR  $DF; (( $QT, m=$r1&FC, $r1=(($r1>>1)|(f<<7))  &255 )); $SETF; }  # from $0.$LINENO\n"
    printf "RLCr_$r1(){ dis RLC $DF; (( $QT, m=$r1>>7, $r1=(($r1<<1)|($r1>>7))&255 )); $SETF; }  # from $0.$LINENO\n"
    printf "RRCr_$r1(){ dis RRC $DF; (( $QT, m=$r1&FC, $r1=(($r1>>1)|($r1<<7))&255 )); $SETF; }  # from $0.$LINENO\n"
    printf "SLAr_$r1(){ dis SLA $DF; (( $QT, m=$r1>>7, $r1=(($r1<<1)         )&255 )); $SETF; }  # from $0.$LINENO\n"
    printf "SLLr_$r1(){ dis SLL $DF; (( $QT, m=$r1>>7, $r1=(($r1<<1)|1       )&255 )); $SETF; }  # from $0.$LINENO\n"
    printf "SRAr_$r1(){ dis SRA $DF; (( $QT, m=$r1&FC, $r1=(($r1>>1)|($r1&FS))&255 )); $SETF; }  # from $0.$LINENO\n"
    printf "SRLr_$r1(){ dis SRL $DF; (( $QT, m=$r1&FC, $r1=(($r1>>1)         )&255 )); $SETF; }  # from $0.$LINENO\n"

    for (( j=0; j<8; j++ )); do
        DF="\"$B,$R1=$B $C @ $LINENO\" $j \$$r1 \"\${CHR[$r1]}\""
        QT="q=2,t=8"; ORM=$(( 1<<j )); ANDM=$(( 255-ORM ))
        printf "BIT$j$r1(){ dis BIT $DF; (( $QT, n=$r1&$ORM )); setfBIT 0 0 \$n; }  # from $0.$LINENO\n"
        printf "SET$j$r1(){ dis SET $DF; (( $QT, $r1|=$ORM  )); return 0; }  # from $0.$LINENO\n"
        printf "RES$j$r1(){ dis RES $DF; (( $QT, $r1&=$ANDM )); return 0; }  # from $0.$LINENO\n"
    done
    
done

DF="\"A=$B,$B $C\" \$a \$n \"\${CHR[n]}\""
QT="q=2,t=7"
printf "ADDn(){ rn; dis ADD $DF; (( $QT, m=a, a=(a+n)       &255 )); setfADD \$m \$n \$a; }  # from $0.$LINENO\n"
printf "SUBn(){ rn; dis SUB $DF; (( $QT, m=a, a=(a-n)       &255 )); setfSUB \$m \$n \$a; }  # from $0.$LINENO\n"
printf "ADCn(){ rn; dis ADC $DF; (( $QT, m=a, a=(a+n+(f&FC))&255 )); setfADC \$m \$n \$a; }  # from $0.$LINENO\n"
printf "SBCn(){ rn; dis SBC $DF; (( $QT, m=a, a=(a-n-(f&FC))&255 )); setfSBC \$m \$n \$a; }  # from $0.$LINENO\n"
printf "XORn(){ rn; dis XOR $DF; (( $QT, m=a, a=(a^n)            )); setfXOR \$m \$n \$a; }  # from $0.$LINENO\n"
printf "ORn() { rn; dis OR  $DF; (( $QT, m=a, a=(a|n)            )); setfOR  \$m \$n \$a; }  # from $0.$LINENO\n"
printf "ANDn(){ rn; dis AND $DF; (( $QT, m=a, a=(a&n)            )); setfAND \$m \$n \$a; }  # from $0.$LINENO\n"

printf "CPn() { rn; dis CP  $DF; (( $QT,      m=(a-n)       &255 )); setfCP  \$a \$n \$m; }  # from $0.$LINENO\n"  # different

DF="\"DE=$W,HL=$W\" \$de \$hl"
QT="q=1,t=4"
printf "EXDEHL(){ (( n=d, m=e, $QT, $DE, $HL )); dis EX  $DF; (( d=h, h=n, e=l, l=m )); return 0; }  # from $0.$LINENO\n"

DF="\"(HL=$W),$B $C\" \$hl \$n \"\${CHR[n]}\""
QT="q=3,t=10"
printf "LDHLmn(){ (( $HL, $QT )); rn; wb \$hl \$n; dis LD $DF ; }  # from $0.$LINENO\n"

printf "# (HL) instructions\n"
for rp in hl; do rh=${rp::1}; rl=${rp:1}; RP=${RPN[$rp]}; RR="rr=($rh<<8)|$rl"

    DF="\"($RP=$W)=$B $C\" \$rr \$n \"\${CHR[n]}\""
    QT="q=3,t=11"
    SETF="setfROTr 0 \$m \$n"
    _RB="(( $RR, \$QT )); rb \$rr"  # allow QT to be set during print, not now
    _WB="wb \$rr \$n; $SETF"
    printf "RL${RP}m() { $_RB; dis RL  $DF; (( m=n>>7, n=((n<<1)|(f&FC))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "RR${RP}m() { $_RB; dis RR  $DF; (( m=n&FC, n=((n>>1)|(f<<7))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "RLC${RP}m(){ $_RB; dis RLC $DF; (( m=n>>7, n=((n<<1)|(n>>7))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "RRC${RP}m(){ $_RB; dis RRC $DF; (( m=n&FC, n=((n>>1)|(n<<7))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SLA${RP}m(){ $_RB; dis SLA $DF; (( m=n>>7, n=((n<<1)       )&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SRA${RP}m(){ $_RB; dis SRA $DF; (( m=n&FC, n=((n>>1)|(n&FS))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SLL${RP}m(){ $_RB; dis SLL $DF; (( m=n>>7, n=((n<<1)|1     )&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SRL${RP}m(){ $_RB; dis SRL $DF; (( m=n&FC, n=((n>>1)       )&255 )); $_WB; }  # from $0.$LINENO\n"

    DF="\"($RP=$W)=$B $C\" \$rr \$n \"\${CHR[n]}\""
    printf "INC${RP}m(){ $_RB; dis INC $DF; (( m=n,    n=(n+1)          &255 )); wb \$rr \$n; setfINC \$m 1 \$n; }  # from $0.$LINENO\n"
    printf "DEC${RP}m(){ $_RB; dis DEC $DF; (( m=n,    n=(n-1)          &255 )); wb \$rr \$n; setfDEC \$m 1 \$n; }  # from $0.$LINENO\n"

    DF="\"A=$B,($RP=$W)=$B $C\" \$a \$rr \$n \"\${CHR[n]}\""
    QT="q=2,t=7"
    printf "ADD${RP}m(){ $_RB; dis ADD $DF; (( m=a,    a=(a+n)          &255 )); setfADD \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "SUB${RP}m(){ $_RB; dis SUB $DF; (( m=a,    a=(a-n)          &255 )); setfSUB \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "ADC${RP}m(){ $_RB; dis ADC $DF; (( m=a,    a=(a+n+(f&FC))   &255 )); setfADC \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "SBC${RP}m(){ $_RB; dis SBC $DF; (( m=a,    a=(a-n-(f&FC))   &255 )); setfSBC \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "XOR${RP}m(){ $_RB; dis XOR $DF; (( m=a,    a=(a^n)               )); setfXOR \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "OR${RP}m() { $_RB; dis OR  $DF; (( m=a,    a=(a|n)               )); setfOR  \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "AND${RP}m(){ $_RB; dis AND $DF; (( m=a,    a=(a&n)               )); setfAND \$m \$n \$a; }  # from $0.$LINENO\n"

    printf "CP${RP}m() { $_RB; dis CP  $DF; ((         m=(a-n)          &255 )); setfCP  \$a \$n \$m; }  # from $0.$LINENO\n"  # different

    for (( j=0; j<8; j++ )); do
        DF="\"$B,($RP=$W)=$B $C\" $j \$rr \$n \"\${CHR[n]}\""
        QT="q=2,t=8"
        printf "BIT$j${RP}m(){ $_RB; dis BIT $DF; (( m=n, n&=$(( 1<<j )) )); setfBITh $j \$h \$n; }  # from $0.$LINENO\n"

        QT="q=3,t=11"
        printf "SET$j${RP}m(){ $_RB; dis SET $DF; (( n&$(( 1<<j )) )) || wb \$rr \$(( n|$((      1<<j  )) )); return 0; }  # from $0.$LINENO\n"
        printf "RES$j${RP}m(){ $_RB; dis RES $DF; (( n&$(( 1<<j )) )) && wb \$rr \$(( n&$(( 255-(1<<j) )) )); return 0; }  # from $0.$LINENO\n"
    done

done

printf "# 16 bit register instructions - assume D already read in map\n"
for rp in xX yY; do 
    rh=${rp::1}
    rl=${rp:1}
    RP=${RPN[$rp]}
    RR="rr=($rh<<8)|$rl"
    RRD="rrd=(($rh<<8)+$rl+D)&65535"

    DF="\"($RP=$W+d=$B:$W),$B $C\" \$rr \$D \$rrd \$n \"\${CHR[n]}\""
    QT="q=4,t=15"
    printf "LD${RP}mn(){ rD; (( $RR, $RRD, $QT )); rn; wb \$rrd \$n; dis LD $DF; }  # from $0.$LINENO\n"

# WARNING: we assume D has been read

    DF="\"($RP=$W+d=$B:$W)=$B $C\" \$rr \$D \$rrd \$n \"\${CHR[n]}\""
    QT="q=3,t=11"
    SETF="setfROTr 0 \$m \$n"
    _RB="(( $RR, $RRD, $QT )); rb \$rrd"
    _WB="wb \$rrd \$n; $SETF"
    printf "RL${RP}m() { $_RB; dis RL  $DF; (( m=n>>7, n=((n<<1)|(f&FC))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "RR${RP}m() { $_RB; dis RR  $DF; (( m=n&FC, n=((n>>1)|(f<<7))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "RLC${RP}m(){ $_RB; dis RLC $DF; (( m=n>>7, n=((n<<1)|(n>>7))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "RRC${RP}m(){ $_RB; dis RRC $DF; (( m=n&FC, n=((n>>1)|(n<<7))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SLA${RP}m(){ $_RB; dis SLA $DF; (( m=n>>7, n=((n<<1)       )&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SRA${RP}m(){ $_RB; dis SRA $DF; (( m=n&FC, n=((n>>1)|(n&FS))&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SLL${RP}m(){ $_RB; dis SLL $DF; (( m=n>>7, n=((n<<1)|1     )&255 )); $_WB; }  # from $0.$LINENO\n"
    printf "SRL${RP}m(){ $_RB; dis SRL $DF; (( m=n&FC, n=((n>>1)       )&255 )); $_WB; }  # from $0.$LINENO\n"

# WARNING: we assume D has been read

    for r1 in a b c d e  h l; do R1=${RN[$r1]} 
        DF="\"($RP=$W+d=$B:$W)=$B,$R1 $C\" \$rr \$D \$rrd \$n \"\${CHR[n]}\""  # make (IX=3+d=1:4)=23,C
        QT="q=3,t=11"
        _RB="(( $RR, $RRD, $QT )); rb \$rrd"
        _WB="wb \$rrd \$n; $SETF"
        printf "RL${RP}mr_$r1() { $_RB; dis RL  $DF; (( m=n>>7, n=((n<<1)|(f&FC))&255, $r1=n )); $_WB; }  # from $0.$LINENO\n"
        printf "RLC${RP}mr_$r1(){ $_RB; dis RLC $DF; (( m=n>>7, n=((n<<1)|(n>>7))&255, $r1=n )); $_WB; }  # from $0.$LINENO\n"
        printf "SLA${RP}mr_$r1(){ $_RB; dis SLA $DF; (( m=n>>7, n=((n<<1)       )&255, $r1=n )); $_WB; }  # from $0.$LINENO\n"
        printf "SLL${RP}mr_$r1(){ $_RB; dis SLL $DF; (( m=n>>7, n=((n<<1)|1     )&255, $r1=n )); $_WB; }  # from $0.$LINENO\n"
    done

# possible further 'simplification'
#    for g in "XOR:^" "OR:|" "AND:&"; do OP=${g%:*}; op=${g#*:}
#        printf "${OP}${RP}m() { (($RR)); rb \$rr; dis $OP \"A=$B,($RP=$W)=$B\" \$a \$rr \$n; (( q=2, t=7, m=a, a$op=n )); setf$OP \$m \$n \$a; }  # from $0.$LINENO\n"    
#        printf "${OP}n()      {          rn;      dis $OP \"A=$B,$B\"          \$a      \$n; (( q=2, t=8, m=a, a$op=n )); setf$OP \$m \$n \$a; }  # from $0.$LINENO\n"
#    done

# WARNING: we assume D has been read

    DF="\"A=$B,($RP=$W+d=$B:$W)=$B $C\" \$a \$rr \$D \$rrd \$n \"\${CHR[n]}\""
    #MM="mm=(rr+D)&65535"
    QT="q=4,t=15"
    _RB="rD; (( $RR, $RRD )); rb \$rrd"
    printf "ADD${RP}m(){ $_RB; dis ADD $DF; (( $QT, m=a, a=(a+n)       &255 )); setfADD \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "SUB${RP}m(){ $_RB; dis SUB $DF; (( $QT, m=a, a=(a-n)       &255 )); setfSUB \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "ADC${RP}m(){ $_RB; dis ADC $DF; (( $QT, m=a, a=(a+n+(f&FC))&255 )); setfADC \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "SBC${RP}m(){ $_RB; dis SBC $DF; (( $QT, m=a, a=(a-n-(f&FC))&255 )); setfSBC \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "XOR${RP}m(){ $_RB; dis XOR $DF; (( $QT, m=a, a=(a^n)            )); setfXOR \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "OR${RP}m() { $_RB; dis OR  $DF; (( $QT, m=a, a=(a|n)            )); setfOR  \$m \$n \$a; }  # from $0.$LINENO\n"
    printf "AND${RP}m(){ $_RB; dis AND $DF; (( $QT, m=a, a=(a&n)            )); setfAND \$m \$n \$a; }  # from $0.$LINENO\n"

    printf "CP${RP}m() { $_RB; dis CP  $DF; (( $QT,      m=(a-n)       &255 )); setfCP  \$a \$n \$m; }  # from $0.$LINENO\n"  # different

    DF="\"($RP=$W+d=$B:$W)=$B $C\" \$rr \$D \$rrd \$n \"\${CHR[n]}\""
    QT="q=5,t=19"
    printf "INC${RP}m(){ $_RB; dis INC $DF; (( $QT, m=n, n=(n+1)       &255 )); wb \$rrd \$n; setfINC \$m 1 \$n; }  # from $0.$LINENO\n"
    printf "DEC${RP}m(){ $_RB; dis DEC $DF; (( $QT, m=n, n=(n-1)       &255 )); wb \$rrd \$n; setfDEC \$m 1 \$n; }  # from $0.$LINENO\n"
    
# WARNING: we assume D has been read

    for (( j=0; j<8; j++ )); do
        DF="\"$B,($RP=$W+d=$B:$W)=$B $C @ $LINENO\" $j \$rr \$D \$rrd \$n \"\${CHR[n]}\""
        QT="q=2,t=8"
        _RB="(( \$QT, $RR, $RRD )); rb \$rrd"
        printf "BIT$j${RP}m(){ $_RB; dis BIT $DF; (( m=n, n&=$(( 1<<j )) )); setfBITx $j \$((rrd>>8)) \$n; }  # from $0.$LINENO\n"  # [SY05]

        QT="q=3,t=11"
        printf "SET$j${RP}m(){ $_RB; dis SET $DF; (( n&$(( 1<<j )) )) || wb \$rrd \$(( n|$((      1<<j  )) )); return 0; }  # from $0.$LINENO\n"
        printf "RES$j${RP}m(){ $_RB; dis RES $DF; (( n&$(( 1<<j )) )) && wb \$rrd \$(( n&$(( 255-(1<<j) )) )); return 0; }  # from $0.$LINENO\n"
    done
done

printf "# (HL) (IX) and (IY) instructions - these can not use D\n"
for rp in hl xX yY; do 
    rh=${rp::1}
    rl=${rp:1} 
    RP=${RPN[$rp]} 
    RR="rr=($rh<<8)|$rl"
    SETrpnn="$rh=nn>>8,$rl=nn&255"

    printf "JP$RP()  { (( $RR, q=1, t=4  ));       dis JP \"$RP=$W\"    \$rr; (( pc=rr )); return 0; }  # from $0.$LINENO\n"
    printf "LDSP$RP(){ (( $RR, q=1, t=6, sp=rr )); dis LD \"SP,$RP=$W\" \$rr;                        }  # from $0.$LINENO\n"
# SP special cases
    DF="\"$RP=$W,SP=$W\" \$rr \$sp"
    QT="q=3,t=11"
    printf "ADD${RP}SP(){ (( $RR,         nn=(rr+sp)  &65535 )); dis ADD $DF; setfADD16 \$rr \$sp \$nn; (( $SETrpnn, $QT )); return 0; }  # from $0.$LINENO\n"
    DF="\"$RP=$W,SP=$W,CF=%%d\" \$rr \$sp \$n"
    printf "ADC${RP}SP(){ (( $RR, n=f&FC, nn=(rr+sp+n)&65535 )); dis ADC $DF; setfADC16 \$rr \$sp \$nn; (( $SETrpnn, $QT )); return 0; }  # from $0.$LINENO\n"
    printf "SBC${RP}SP(){ (( $RR, n=n&FC, nn=(rr-sp-n)&65535 )); dis SBC $DF; setfSBC16 \$rr \$sp \$nn; (( $SETrpnn, $QT )); return 0; }  # from $0.$LINENO\n"
done

printf "# Rotate instructions - m is bit that moves to carry - timing checked\n"
DF="\" ; A=$B $C\" \$a \"\${CHR[n]}\""
QT="q=1,t=4"
SETF="setfROTa 0 \$m \$a"
printf "RLA() { dis RLA  $DF; (( $QT, m=a>>7, a=((a<<1)|(f&FC))&255 )); $SETF; }  # from $0.$LINENO\n"
printf "RRA() { dis RRA  $DF; (( $QT, m=a&FC, a=((a>>1)|(f<<7))&255 )); $SETF; }  # from $0.$LINENO\n"
printf "RLCA(){ dis RLCA $DF; (( $QT, m=a>>7, a=((a<<1)|(a>>7))&255 )); $SETF; }  # from $0.$LINENO\n"
printf "RRCA(){ dis RRCA $DF; (( $QT, m=a&FC, a=((a>>1)|(a<<7))&255 )); $SETF; }  # from $0.$LINENO\n"

printf "# 16 bit register instructions - timing checked\n"
for rp in bc de hl af xX yY; do 
    rh=${rp::1}
    rl=${rp:1}
    RP=${RPN[$rp]}
    RR="rr=($rh<<8)|$rl" 
    MN="mn=(m<<8)|n"
    eval "INCrp=\$INC$rp; DECrp=\$DEC$rp"
    SETrpnn="$rh=nn>>8,$rl=nn&255"
    
    DF="\"$RP=$W\"  \$rr"
    QT="q=1,t=6"
    printf "INC$RP(){ (( $RR )); dis INC $DF; (( $INCrp, $QT )); return 0; }  # from $0.$LINENO\n"
    printf "DEC$RP(){ (( $RR )); dis DEC $DF; (( $DECrp, $QT )); return 0; }  # from $0.$LINENO\n"

    QT="q=3,t=10"
#    printf "LD${RP}nn() { (( $RR )); rnn;               dis LD   \"$RP=$W,$W\"   \$rr \$nn; (( $QT, $SETrpnn )); return 0; }  # from $0.$LINENO\n"
    printf "LD${RP}nn(){ rn; rm; (( $RR, $MN ));       dis LD   \"$RP=$W,$W\"   \$rr \$mn; (( $QT, $rh=m, $rl=n )); return 0; }  # from $0.$LINENO\n"
    QT="q=5,t=16"
    printf "LDmm$RP()  { (( $RR )); rmm; ww \$mm \$rr; dis LD   \"($W),$RP=$W\" \$mm \$rr; (( $QT ));           return 0; }  # from $0.$LINENO\n"
    printf "LD${RP}mm(){            rmm; rw \$mm;      dis LD   \"$RP,($W)=$W\" \$mm \$nn; (( $QT, $SETrpnn )); return 0; }  # from $0.$LINENO\n"

    QT="q=3,t=12"
    printf "PUSH$RP(){        (( $QT, $RR ));  dis PUSH \"$RP=$W ; SP=$W\"      \$rr \$sp;            pushw \$rr;               }  # from $0.$LINENO\n"
    printf "POP$RP() { popnn; (( $QT ));       dis POP  \"$RP=$W ; (SP=$W)=$W\" \$rr \$((sp-2)) \$nn; (( $SETrpnn )); return 0; }  # from $0.$LINENO\n"
    
    for rp2 in hl xX yY; do 
        rh2=${rp2::1}
        rl2=${rp2:1}
        RP2=${RPN[$rp2]}
        RR2="rr2=($rh2<<8)|$rl2"
        SETrp2nn="$rh2=nn>>8,$rl2=nn&255"

        DF="\"$RP2=$W,$RP=$W,CF=%%d\" \$rr2 \$rr \$n"
        QT="q=3,t=11"
        printf "ADC$RP2$RP(){ (( $RR2, $RR, n=f&FC )); dis ADC $DF; (( nn=(rr2+rr+n)&65535, $SETrp2nn, $QT )); setfADC16 \$rr2 \$rr \$nn; }  # from $0.$LINENO\n"
        printf "SBC$RP2$RP(){ (( $RR2, $RR, n=f&FC )); dis SBC $DF; (( nn=(rr2-rr-n)&65535, $SETrp2nn, $QT )); setfSBC16 \$rr2 \$rr \$nn; }  # from $0.$LINENO\n"
        DF="\"$RP2=$W,$RP=$W\" \$rr2 \$rr"
        printf "ADD$RP2$RP(){ (( $RR2, $RR ));         dis ADD $DF; (( nn=(rr2+rr)  &65535, $SETrp2nn, $QT )); setfADD16 \$rr2 \$rr \$nn; }  # from $0.$LINENO\n"
    done
done

printf "# SP instructions - timing checked\n"
printf "LDSPnn(){ rnn;               dis LD  \"SP,$W\"         \$nn;           (( q=3, t=10, sp=nn  )); return 0; }  # from $0.$LINENO\n"
printf "LDmmSP(){ rmm; ww \$mm \$sp; dis LD  \"($W),SP=$W\"    \$mm \$sp;      (( q=5, t=16         )); return 0; }  # from $0.$LINENO\n"
printf "LDSPmm(){ rmm; rw \$mm;      dis LD  \"SP=$W,($W)=$W\" \$sp \$mm \$nn; (( q=5, t=16, sp=nn  )); return 0; }  # from $0.$LINENO\n"
printf "INCSP() {                    dis INC \"SP=$W\"         \$sp;           (( q=1, t=6,  $INCSP )); return 0; }  # from $0.$LINENO\n"
printf "DECSP() {                    dis DEC \"SP=$W\"         \$sp;           (( q=1, t=6,  $DECSP )); return 0; }  # from $0.$LINENO\n"

# timing checked
DF="\"AF=$W,AF'=$W\" \$af \$af1"
QT="q=1,t=4"
printf "EXAFAF(){ (( $QT, $AF, $AF1)); dis EX  $DF; ((n=a,a=a1,a1=n,n=f,f=f1,f1=n)); return 0; }  # from $0.$LINENO\n"

DF="\"; BC=$W DE=$W HL=$W BC'=$W DE'=$W HL'=$W\" \$bc \$de \$hl \$bc1 \$de1 \$hl1"
#printf "EXX(){ (( $QT, $BC, $DE, $HL, $BC1, $DE1, $HL1 )); dis EXX $DF; for g in b c d e h l; do eval \"((n=\$g,\$g=\${g}1,\${g}1=n))\"; done; return 0; }  # from $0.$LINENO\n"
COM=
for g in b c d e h l; do
    COM+="n=$g,$g=${g}1,${g}1=n,"
done
printf "EXX(){ (( $QT, $BC, $DE, $HL, $BC1, $DE1, $HL1 )); dis EXX $DF; (( ${COM:: -1} )); return 0; }  # from $0.$LINENO\n"

printf "# RST instructions - flags, timing checked\n"
for p in '00' '08' 10 18 20 28 30 38; do
    DF="\"$p ; SP=$W\" \$sp"
    printf "RST$p(){ dis RST $DF; pushw \$pc; pc=0x00$p; q=3; t=11; return 0; }  # from $0.$LINENO\n"
done

} >> $GEN

