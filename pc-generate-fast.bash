#!/bin/bash

# Fast functions

# Functions should not contain } unless followed by a " or ; or anything but a comment
# eg. R="${RP[n]}" or R=${RP[n]};
# eg. (( a==0 )) && { a=b; return 0; } || { c=d; return 0; }; 

{
printf "# Generated functions\n"

printf "# Some loads - timing checked\n"
#printf "LDAmm() { rmm; rb \$mm; a=n; return 0; }  # from $0.$LINENO\n"
printf "LDAmm(){ rmm;memread \$mm;a=MEM[mm];return 0;}  # from $0.$LINENO\n"
#printf "LDmmA(){ rmm;wb \$mm \$a;return 0;}  # from $0.$LINENO\n"
printf "LDmmA(){ rmm;memprotb \$mm \$a;MEM[mm]=a;return 0;}  # from $0.$LINENO\n"
#printf "LDAmm() { $rmm; rb \$mm; a=n; return 0; }  # from $0.$LINENO\n"
#printf "LDmmA() { $rmm; wb \$mm \$a;  return 0; }  # from $0.$LINENO\n"
#printf "LDBCmA(){ wb $BCV \$a;return 0;}  # from $0.$LINENO\n"
#printf "LDDEmA(){ wb $DEV \$a;return 0;}  # from $0.$LINENO\n"
printf "LDBCmA(){ (($BC));memprotb \$bc \$a;MEM[bc]=a;return 0;}  # from $0.$LINENO\n"
printf "LDDEmA(){ (($DE));memprotb \$de \$a;MEM[de]=a;return 0;}  # from $0.$LINENO\n"

#printf "LDABCm(){ rb $BCV; a=n; return 0; }  # from $0.$LINENO\n"
#printf "LDADEm(){ rb $DEV; a=n; return 0; }  # from $0.$LINENO\n"
printf "LDABCm(){ (($BC));memread \$bc;a=MEM[bc];return 0;}  # from $0.$LINENO\n"
printf "LDADEm(){ (($DE));memread \$de;a=MEM[de];return 0;}  # from $0.$LINENO\n"

printf "# Jumps, calls and returns - timing checked\n"
#printf "JPnn()  { rnn; pc=nn;              return 0; }  # from $0.$LINENO\n"
#printf "JRn()   { rD; (( $NNPCD, pc=nn )); return 0; }  # from $0.$LINENO\n"
#printf "JRn()   { rD; (( $PCD )); return 0; }  # from $0.$LINENO\n"
printf "JPnn(){ rpc;return 0;}  # from $0.$LINENO\n"
printf "JRn(){ rPCD;return 0;}  # from $0.$LINENO\n"
#printf "CALLnn(){ rnn; pushpcnn; }  # from $0.$LINENO\n"
printf "CALLnn(){ rnn;((MEM[--sp]=pc>>8,MEM[--sp]=pc&255,pc=nn));}  # from $0.$LINENO\n"
#printf "CALLnn(){ $rnn; (( MEM[--sp]=pc>>8, MEM[--sp]=pc&255, pc=nn )); }  # from $0.$LINENO\n"
printf  "RET(){ $poppc;return 0;}  # from $0.$LINENO\n"
printf "RETI(){ $poppc;iff1=iff2;return 0;}  # from $0.$LINENO\n"
printf "RETN(){ $poppc;iff1=iff2;return 0;}  # from $0.$LINENO\n"

printf "# Conditional Jump, Call, and Return instructions - timing checked\n"
for g in "Z:NZ:Z" "C:NC:C" "PE:PO:P" "M:P:S"; do
    S="${g%%:*}"
    N="${g#*:}"; N="${N%:*}"
    F="${g##*:}";  # Set, Not set, and Flag name
    #printf "JP${N}nn(){ rnn;((f&F$F?0:(pc=nn)));return 0;}  # from $0.$LINENO\n"
    #printf "JP${S}nn(){ rnn;((f&F$F?(pc=nn):0));return 0;}  # from $0.$LINENO\n"
    #printf "JR${N}n(){ rD;(($NNPCD,f&F$F?0:(pc=nn)));return 0;}  # from $0.$LINENO\n"
    #printf "JR${S}n(){ rD;(($NNPCD,f&F$F?(pc=nn):0 ));return 0;}  # from $0.$LINENO\n"
    #printf "JR${N}n(){ rD;((f&F$F?0:($PCD)));return 0;}  # from $0.$LINENO\n"
    #printf "JR${S}n(){ rD;((f&F$F?($PCD):0));return 0;}  # from $0.$LINENO\n"
    printf "JP${N}nn(){ rjjcc;((pc=(f&F$F)?cc:jj));return 0;}  # from $0.$LINENO\n"
    printf "JP${S}nn(){ rjjcc;((pc=(f&F$F)?jj:cc));return 0;}  # from $0.$LINENO\n"
    printf  "JR${N}n(){ rDjjcc;((pc=(f&F$F)?cc:jj));return 0;}  # from $0.$LINENO\n"
    printf  "JR${S}n(){ rDjjcc;((pc=(f&F$F)?jj:cc));return 0;}  # from $0.$LINENO\n"
    #printf "CALL${S}nn(){ rnn; if((   (f&F$F)));then pushpcnn;fi;return 0;}  # from $0.$LINENO\n"
    #printf "RET$N(){ if((!(f&F$F)));then poppc;fi;return 0;}  # from $0.$LINENO\n"
    #printf "RET$S(){ if(( (f&F$F)));then poppc;fi;return 0;}  # from $0.$LINENO\n"
    #printf "CALL${N}nn(){ rnn;if((!(f&F$F)));then pushpcnn;fi;return 0;}  # from $0.$LINENO\n"
    #printf "CALL${N}nn(){ rnn;if((!(f&F$F)));then ((MEM[--sp]=pc>>8,MEM[--sp]=pc&255,pc=nn));fi;return 0;}  # from $0.$LINENO\n"
    #printf "CALL${N}nn(){ $rnn;if((!(f&F$F)));then pushpcnn;fi;return 0;}  # from $0.$LINENO\n"
    # I test sed rules with this line
    #printf "CALL${S}nn(){ rnn;if(((f&F$F)));then { pushpcnn;};else { return 0;};fi;}  # from $0.$LINENO\n"
    printf "CALL${N}nn(){ rnn;(((f&F$F)?0:(MEM[--sp]=pc>>8,MEM[--sp]=pc&255,pc=nn)));return 0;}  # from $0.$LINENO\n"
    printf "CALL${S}nn(){ rnn;(((f&F$F)?(MEM[--sp]=pc>>8,MEM[--sp]=pc&255,pc=nn):0));return 0;}  # from $0.$LINENO\n"

    #printf "RET$N(){ ((!(f&F$F))) && poppc || return 0;}  # from $0.$LINENO\n"
    #printf "RET$S(){ (( (f&F$F))) && poppc || return 0;}  # from $0.$LINENO\n"
    #printf "RET$N(){ if((!(f&F$F)));then { $poppc;};else return 0;fi;}  # from $0.$LINENO\n"
    #printf "RET$S(){ if(( (f&F$F)));then { $poppc;};else return 0;fi;}  # from $0.$LINENO\n"
    #printf "RET$N(){ if((!(f&F$F)));then { ((pc=MEM[sp++],pc+=MEM[sp++]*256));};fi;return 0;}  # from $0.$LINENO\n"
    #printf "RET$S(){ if(( (f&F$F)));then { ((pc=MEM[sp++],pc+=MEM[sp++]*256));};fi;return 0;}  # from $0.$LINENO\n"
    #printf "RET$N(){ ((!(f&F$F)))&&((pc=MEM[sp++],pc+=MEM[sp++]*256));return 0;}  # from $0.$LINENO\n"
    #printf "RET$S(){ (( (f&F$F)?(pc=MEM[sp++],pc+=MEM[sp++]*256):0));return 0;}  # from $0.$LINENO\n"
    #badprintf "RET$N(){ (((f&F$F)?(pc=MEM[sp]+MEM[sp+1]*256,sp+=2):0));return 0;}  # from $0.$LINENO\n"
    #badprintf "RET$S(){ (((f&F$F)?0:(pc=MEM[sp]+MEM[sp+1]*256,sp+=2)));return 0;}  # from $0.$LINENO\n"
    #printf "RET$N(){ ((f&F$F))||((pc=MEM[sp++],pc+=MEM[sp++]*256));return 0;}  # from $0.$LINENO\n"
    #printf "RET$S(){ printf \"%%04x  %%02x  \" \$pc \$((f&F$F));((f&F$F))&&((pc=MEM[sp++],pc+=(MEM[sp++]<<8)));printf \"%%04x\\\n\" \$pc;return 0;}  # from $0.$LINENO\n"
    #printf "RET$N(){ (((f&F$F)?0:(pc=MEM[sp++],pc+=(MEM[sp++]<<8))));return 0;}  # from $0.$LINENO\n"
    #printf "RET$S(){ printf \"%%04x  %%02x  \" \$pc \$((f&F$F));(((f&F$F)>0?(pc=MEM[sp++],pc+=(MEM[sp++]<<8)):0));printf \"%%04x\\\n\" \$pc;return 0;}  # from $0.$LINENO\n"
    #printf "RET$S(){ printf ".";(((f&F$F)?(pc=MEM[sp++],pc+=(MEM[sp++]<<8)):0));printf "c";return 0;}  # from $0.$LINENO\n"
    #printf "RET$S(){ printf ".";((f&F$F?(${poppc//;/,}):0));printf "c";return 0;}  # from $0.$LINENO\n"
    printf "RET$N(){ ((f&F$F?0:(pc=MEM[sp++],pc+=(MEM[sp++]<<8))));return 0;}  # from $0.$LINENO\n"
    #printf "RET$S(){ ((f&F$F?(pc=MEM[sp++],pc+=(MEM[sp++]<<8)):0));return 0;}  # from $0.$LINENO\n"
    printf "RET$S(){ ((f&F$F?pc=MEM[sp++],pc+=(MEM[sp++]<<8):0));return 0;}  # from $0.$LINENO\n"
done

printf "# block move - timing checked\n"
# Notes: must unset AREA after reading character from (DE)
 INCBLOCK="$INChl,$INCde,$DECbc"
 DECBLOCK="$DEChl,$DECde,$DECbc"
#INCBLOCKR="$INChl,$INCde,$DECBC,$SETbc,(bc>0)?(pc=(pc-2)&65535):(q+=3,t+=12)"
#DECBLOCKR="$DEChl,$DECde,$DECBC,$SETbc,(bc>0)?(pc=(pc-2)&65535):(q+=3,t+=12)"
if $_FAST; then
    INCBLOCKR="$INChl,$INCde,$DECBC,$SETbc,bc?(pc-=2):(q+=3,t+=12)"
    DECBLOCKR="$DEChl,$DECde,$DECBC,$SETbc,bc?(pc-=2):(q+=3,t+=12)"
      INCCOMP="$INChl,$DECbc"
      DECCOMP="$DEChl,$DECbc"
     INCCOMPR="$INChl,$DECBC,$SETbc,((m!=0)&&(bc>0))?(pc-=2):(q+=3,t+=12)"
     DECCOMPR="$DEChl,$DECBC,$SETbc,((m!=0)&&(bc>0))?(pc-=2):(q+=3,t+=12)"
else
    INCBLOCKR="$INChl,$INCde,$DECBC,$SETbc,bc?(pc=(pc-2)&65535):(q+=3,t+=12)"
    DECBLOCKR="$DEChl,$DECde,$DECBC,$SETbc,bc?(pc=(pc-2)&65535):(q+=3,t+=12)"
      INCCOMP="$INChl,$DECbc"
      DECCOMP="$DEChl,$DECbc"
     INCCOMPR="$INChl,$DECBC,$SETbc,((m!=0)&&(bc>0))?(pc=(pc-2)&65535):(q+=3,t+=12)"
     DECCOMPR="$DEChl,$DECBC,$SETbc,((m!=0)&&(bc>0))?(pc=(pc-2)&65535):(q+=3,t+=12)"
fi

#printf "LDI(){ (($HL,$DE,$BC));rb \$de;m=n;rb \$hl;wb \$de \$n;(($INCBLOCK));setfLDI 0 \$a \$n;}  # from $0.$LINENO\n"
#printf "LDD(){ (($HL,$DE,$BC));rb \$de;m=n;rb \$hl;wb \$de \$n;(($DECBLOCK)); setfLDI 0 \$a \$n;}  # from $0.$LINENO\n"
#printf "LDI(){ (($HL,$DE,$BC));rb \$hl;wb \$de \$n;(($INCBLOCK));setfLDI 0 \$a \$n;}  # from $0.$LINENO\n"
#printf "LDD(){ (($HL,$DE,$BC));rb \$hl;wb \$de \$n;(($DECBLOCK));setfLDI 0 \$a \$n;}  # from $0.$LINENO\n"
#printf "LDI(){ (($HL,$DE,$BC));memread \$hl;n=MEM[hl];wb \$de \$n;(($INCBLOCK));$acc_setfLDI;}  # from $0.$LINENO\n"
#printf "LDD(){ (($HL,$DE,$BC));memread \$hl;n=MEM[hl];wb \$de \$n;(($DECBLOCK));$acc_setfLDI;}  # from $0.$LINENO\n"
printf "LDI(){ (($HL,$DE,$BC));memread \$hl;n=MEM[hl];memprotb \$de \$n;MEM[de]=n;(($INCBLOCK));$acc_setfLDI;}  # from $0.$LINENO\n"
printf "LDD(){ (($HL,$DE,$BC));memread \$hl;n=MEM[hl];memprotb \$de \$n;MEM[de]=n;(($DECBLOCK));$acc_setfLDI;}  # from $0.$LINENO\n"

# z80 implementation of LDIR is LDI + no change to PC - this is inefficient in an emulator due to composing and decomposing double registers each itteration
#printf "XLDIR(){ (($HL,$DE,$BC));rb \$de;m=n;rb \$hl;wb \$de \$n;(($INCBLOCKR));setfLDIR 0 \$a \$n;}  # from $0.$LINENO\n"
#printf "XLDDR(){ (($HL,$DE,$BC));rb \$de;m=n;rb \$hl;wb \$de \$n;(($DECBLOCKR));setfLDIR 0 \$a \$n;}  # from $0.$LINENO\n"
printf "XLDIR(){ (($HL,$DE,$BC));rb \$hl;memprotb \$de \$n;MEM[de]=n;(($INCBLOCKR));$acc_setfLDIR;}  # from $0.$LINENO\n"
printf "XLDDR(){ (($HL,$DE,$BC));rb \$hl;memprotb \$de \$n;MEM[de]=n;(($DECBLOCKR));$acc_setfLDIR;}  # from $0.$LINENO\n"

# alternative implementation for efficiency - but can still be done better - timing wrong?
printf "LDIR(){
    (($HL,$DE,$BC));
    while ((bc>0));do                            # FIXME: assume bc never 0 from start
        #rb \$hl;memprotb \$de \$n;MEM[de]=n;  # wb \$de \$n;
        memread \$hl;n=MEM[hl];memprotb \$de \$n;MEM[de]=n;  # wb \$de \$n;
        (($INCHL,$INCDE,bc-=1));                 # just inc and dec double registers
    done;
    (($SEThl,$SETde,b=c=0));                     # copy results into registers
    #setfLDIR 0 \$a \$n;                         # flags set on last character moved
    $acc_setfLDIR;                               # flags set on last character moved
    return 0;
}  # from $0.$LINENO\n"

printf "LDDR(){ 
    (($HL,$DE,$BC));
    while ((bc>0));do
        #rb \$hl;memprotb \$de \$n;MEM[de]=n;  # wb \$de \$n;
        memread \$hl;n=MEM[hl];memprotb \$de \$n;MEM[de]=n;  # wb \$de \$n;
        (($DECHL,$DECDE,bc-=1));                 # just dec double registers
    done;
    (($SEThl,$SETde,b=c=0));                     # copy results into registers
    #setfLDIR 0 \$a \$n;                         # flags set on last character moved
    $acc_setfLDIR;                               # flags set on last character moved
    return 0;
}  # from $0.$LINENO\n"


printf  "CPI(){ (($HL,$BC));rb \$hl;((m=(a-n)&255 ));(($INCCOMP));setfCPI \$a \$n \$m;}  # from $0.$LINENO\n"
printf  "CPD(){ (($HL,$BC));rb \$hl;((m=(a-n)&255 ));(($DECCOMP));setfCPI \$a \$n \$m;}  # from $0.$LINENO\n"
printf "CPIR(){ (($HL,$BC));rb \$hl;((m=(a-n)&255 ));(($INCCOMPR));setfCPI \$a \$n \$m;}  # from $0.$LINENO\n"
printf "CPDR(){ (($HL,$BC));rb \$hl;((m=(a-n)&255 ));(($DECCOMPR));setfCPI \$a \$n \$m;}  # from $0.$LINENO\n"


printf  "INI(){ return 0;}  # from $0.$LINENO\n"
printf  "IND(){ return 0;}  # from $0.$LINENO\n"
printf "INIR(){ return 0;}  # from $0.$LINENO\n"
printf "INDR(){ return 0;}  # from $0.$LINENO\n"
printf "OUTI(){ return 0;}  # from $0.$LINENO\n"
printf "OUTD(){ return 0;}  # from $0.$LINENO\n"
printf "OTIR(){ return 0;}  # from $0.$LINENO\n"
printf "OTDR(){ return 0;}  # from $0.$LINENO\n"

printf "# misc - timing checked\n"
#printf "DJNZn(){ rD;(($NNPCD,b=(b-1)&255,b?(pc=nn):0 ));return 0;}  # from $0.$LINENO\n"
#printf "DJNZn(){ rD;((b=(b-1)&255,b?($PCD):0 ));return 0;}  # from $0.$LINENO\n"
printf "DJNZn(){ rDjjcc;((b=(b-1)&255,pc=(b?jj:cc) ));return 0;}  # from $0.$LINENO\n"
#printf "DJNZn(){ rDjjcc;((b--,b&=255,pc=(b?jj:cc)));return 0;}  # from $0.$LINENO\n"

printf  "NOP(){ return 0;}  # from $0.$LINENO\n"
printf "HALT(){ halt=1;return 0;}  # from $0.$LINENO\n"

printf   "DI(){ iff1=iff2=0;return 0;}  # from $0.$LINENO\n"
printf   "EI(){ iff1=iff2=1;return 0;}  # from $0.$LINENO\n"
printf  "IM0(){ return 0;}  # from $0.$LINENO\n"
printf "IM01(){ return 0;}  # from $0.$LINENO\n"
printf  "IM1(){ return 0;}  # from $0.$LINENO\n"
printf  "IM2(){ return 0;}  # from $0.$LINENO\n"

printf "LDIA(){ i=a;return 0;}  # from $0.$LINENO\n"
printf "LDAI(){ a=i;return 0;}  # from $0.$LINENO\n"
printf "LDRA(){ ((r7=a&0x80,r=a));return 0;}  # from $0.$LINENO\n"
printf "LDAR(){ a=r;return 0;}  # from $0.$LINENO\n"


printf "# IN and OUT - timing checked\n"
printf "OUTnA(){ rn;wp \$n \$a;}  # from $0.$LINENO\n"
printf  "INAn(){ rm;rp \$m;a=n;return 0;}  # from $0.$LINENO\n"

for r1 in a f b c d e h l; do R1="${RN[$r1]}"
    printf  "IN${R1}C(){ rp \$c;\$$r1=n;return 0;}  # from $0.$LINENO\n"
    printf "OUTC${R1}(){ wp \$c \$$r1;}  # from $0.$LINENO\n"
done

printf  "IN0C(){ rp \$c;}  # from $0.$LINENO\n"
printf "OUTC0(){ wp \$c 0;}  # from $0.$LINENO\n"

printf "# - timing checked\n"
printf "CPL(){ ((m=(~a)&255));setfCPL 0 0 \$m;a=m;return 0;}  # from $0.$LINENO\n"
printf "NEG(){ ((m=(0-a)&255));setfSUB 0 \$a \$m;a=m;return 0;}  # from $0.$LINENO\n"

printf "CCF(){ u=$FC;setfCCF 0 \$(((f&FC)*FH)) 0;}  # from $0.$LINENO\n"
printf "SCF(){ setfSCF 0 0 0;}  # from $0.$LINENO\n"

SETF="setfRLD 0 0 \$a"
_RB="(($HL));memread \$hl;n=MEM[hl]"
_WB="memprotb \$hl \$n;MEM[hl]=n;$SETF"
#printf "RLD(){ $_RB;((m=a,a=(a&0xf0)|(n>>4),n=((n&15)<<4)|(m&15)));wb \$hl \$n;$SETF;}  # from $0.$LINENO\n"
#printf "RRD(){ (($HL));rb \$hl;((m=a,a=(a&0xf0)|(n&15),n=((m&15)<<4)|(n>>4)));wb \$hl \$n;$SETF;}  # from $0.$LINENO\n"
printf "RLD(){ $_RB;((m=a,a=(a&0xf0)|(n>>4),n=((n&15)<<4)|(m&15)));$_WB;}  # from $0.$LINENO\n"
printf "RRD(){ $_RB;((m=a,a=(a&0xf0)|(n&15),n=((m&15)<<4)|(n>>4)));$_WB;}  # from $0.$LINENO\n"

printf "# 8 bit register instructions - ?\n"
for r1 in b c d e h l a x X y Y; do R1="${RN[$r1]}"
    for r2 in b c d e h l a x X y Y; do R2="${RN[$r2]}"
        printf "LDrr_$r1$r2(){ $r1=$r2;return 0;}  # from $0.$LINENO\n"
    done
    
    #printf "LDrHLm_$r1(){ (($HL));rb \$hl;$r1=n;return 0;}  # from $0.$LINENO\n"
    printf "LDrHLm_$r1(){ (($HL));memread \$hl;$r1=MEM[hl];return 0;}  # from $0.$LINENO\n"
    #printf "LDHLmr_$r1(){ (($HL));wb \$hl \$$r1;}  # from $0.$LINENO\n"
    printf "LDHLmr_$r1(){ (($HL));memprotb \$hl \$$r1;MEM[hl]=$r1;}  # from $0.$LINENO\n"
    #printf   "LDrn_$r1(){ rn; $r1=n; return 0; }  # from $0.$LINENO\n"
    printf   "LDrn_$r1(){ ldrn$r1;return 0;}  # from $0.$LINENO\n"
    # fixed ordering problem: was $r1=n; rb \$mm;
    #printf "LDrIXm_$r1(){ rD;(($IX,mm=(ix+D)&65535));rb \$mm;$r1=n;return 0;}  # from $0.$LINENO\n"
    #printf "LDrIYm_$r1(){ rD;(($IY,mm=(iy+D)&65535));rb \$mm;$r1=n;return 0;}  # from $0.$LINENO\n"
    #printf "LDrIXm_$r1(){ rD;(($IX,mm=ix+D));memread \$mm;$r1=MEM[mm];return 0;}  # from $0.$LINENO\n"
    #printf "LDrIYm_$r1(){ rD;(($IY,mm=iy+D));memread \$mm;$r1=MEM[mm];return 0;}  # from $0.$LINENO\n"
    #printf "LDIXmr_$r1(){ rD;(($IX,mm=ix+D));wb \$mm \$$r1;}  # from $0.$LINENO\n"
    #printf "LDIYmr_$r1(){ rD;(($IY,mm=iy+D));wb \$mm \$$r1;}  # from $0.$LINENO\n"
    printf "LDrIXm_$r1(){ rD;(($MMIXD));memread \$mm;$r1=MEM[mm];return 0;}  # from $0.$LINENO\n"
    printf "LDrIYm_$r1(){ rD;(($MMIYD));memread \$mm;$r1=MEM[mm];return 0;}  # from $0.$LINENO\n"
    #printf "LDIXmr_$r1(){ rD;(($MMIXD));wb \$mm \$$r1;}  # from $0.$LINENO\n"
    #printf "LDIYmr_$r1(){ rD;(($MMIYD));wb \$mm \$$r1;}  # from $0.$LINENO\n"
    printf "LDIXmr_$r1(){ rD;(($MMIXD));memprotb \$mm \$$r1;MEM[mm]=$r1;}  # from $0.$LINENO\n"
    printf "LDIYmr_$r1(){ rD;(($MMIYD));memprotb \$mm \$$r1;MEM[mm]=$r1;}  # from $0.$LINENO\n"
    
    # BUG: where r1=a, ended up with setfADD n a a which means original value of a is lost
    # now, interestingly, these are same as CP
    # FIXME: could be more efficient if a=r1 is a special case
    
    #printf "ADDr_$r1(){ ((m=(a+$r1)       &255));setfADD \$a \$$r1 \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf "SUBr_$r1(){ ((m=(a-$r1)       &255));setfSUB \$a \$$r1 \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf "ADCr_$r1(){ ((m=(a+$r1+(f&FC))&255));setfADD \$a \$$r1 \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf "SBCr_$r1(){ ((m=(a-$r1-(f&FC))&255));setfSUB \$a \$$r1 \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf  "CPr_$r1(){ ((m=(a-$r1)       &255));setfCP  \$a \$$r1 \$m;}  # from $0.$LINENO\n"  # different
    #printf "XORr_$r1(){ ((m=a^$r1));setfXOR \$a \$$r1 \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf  "ORr_$r1(){ ((m=a|$r1));setfXOR \$a \$$r1 \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf "ANDr_$r1(){ ((m=a&$r1));setfAND \$a \$$r1 \$m;a=m;return 0;}  # from $0.$LINENO\n"
    printf "ADDr_$r1(){ ((n=$r1,m=(a+n)       &255));$acc_setfADD;a=m;return 0;}  # from $0.$LINENO\n"
    printf "SUBr_$r1(){ ((n=$r1,m=(a-n)       &255));$acc_setfSUB;a=m;return 0;}  # from $0.$LINENO\n"
    printf "ADCr_$r1(){ ((n=$r1,m=(a+n+(f&FC))&255));$acc_setfADC;a=m;u=$FC;return 0;}  # from $0.$LINENO\n"
    printf "SBCr_$r1(){ ((n=$r1,m=(a-n-(f&FC))&255));$acc_setfSBC;a=m;u=$FC;return 0;}  # from $0.$LINENO\n"
    printf  "CPr_$r1(){ ((n=$r1,m=(a-n)       &255));$acc_setfCP;}  # from $0.$LINENO\n"  # different
    printf "XORr_$r1(){ ((n=$r1,m=a^n));$acc_setfXOR;a=m;return 0;}  # from $0.$LINENO\n"
    printf  "ORr_$r1(){ ((n=$r1,m=a|n));$acc_setfOR; a=m;return 0;}  # from $0.$LINENO\n"
    printf "ANDr_$r1(){ ((n=$r1,m=a&n));$acc_setfAND;a=m;return 0;}  # from $0.$LINENO\n"

    printf "INCr_$r1(){ ((n=$r1,m=(n+1)&255));$acc_setfINC;$r1=m;}  # from $0.$LINENO\n"
    printf "DECr_$r1(){ ((n=$r1,m=(n-1)&255));$acc_setfDEC;$r1=m;}  # from $0.$LINENO\n"

    #SETF="setfROTr 0 \$m \$$r1"
    SETF="$acc_setfROTr"
    printf  "RLr_$r1(){ ((m=$r1>>7,n=$r1=(($r1<<1)|(f&FC))  &255));u=$FC;$SETF;}  # from $0.$LINENO\n"
    printf  "RRr_$r1(){ ((m=$r1&FC,n=$r1=(($r1>>1)|(f<<7))  &255));u=$FC;$SETF;}  # from $0.$LINENO\n"
    printf "RLCr_$r1(){ ((m=$r1>>7,n=$r1=(($r1<<1)|($r1>>7))&255));$SETF;}  # from $0.$LINENO\n"
    printf "RRCr_$r1(){ ((m=$r1&FC,n=$r1=(($r1>>1)|($r1<<7))&255));$SETF;}  # from $0.$LINENO\n"
    printf "SLAr_$r1(){ ((m=$r1>>7,n=$r1=(($r1<<1)         )&255));$SETF;}  # from $0.$LINENO\n"
    printf "SLLr_$r1(){ ((m=$r1>>7,n=$r1=(($r1<<1)|1       )&255));$SETF;}  # from $0.$LINENO\n"
    printf "SRAr_$r1(){ ((m=$r1&FC,n=$r1=(($r1>>1)|($r1&FS))&255));$SETF;}  # from $0.$LINENO\n"
    printf "SRLr_$r1(){ ((m=$r1&FC,n=$r1=(($r1>>1)         )&255));$SETF;}  # from $0.$LINENO\n"

    for (( _j=0; _j<8; _j++ )); do
        _ORM=$(( 1<<_j )); _ANM=$(( 255-_ORM ))
        printf "BIT$_j$r1(){ setfBIT 0 0 \$(($r1&$_ORM));}  # from $0.$LINENO\n"
        printf "SET$_j$r1(){ (($r1|=$_ORM));return 0;}  # from $0.$LINENO\n"
        printf "RES$_j$r1(){ (($r1&=$_ANM));return 0;}  # from $0.$LINENO\n"
    done
done

#printf "ADDn(){ rn;((m=(a+n)       &255));setfADD \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
#printf "SUBn(){ rn;((m=(a-n)       &255));setfSUB \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
#printf "ADCn(){ rn;((m=(a+n+(f&FC))&255));setfADD \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
#printf "SBCn(){ rn;((m=(a-n-(f&FC))&255));setfSUB \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
#printf  "CPn(){ rn;((m=(a-n)       &255));setfCP  \$a \$n \$m;}  # from $0.$LINENO\n"  # different
#printf "XORn(){ rn;((m=a^n));setfXOR \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
#printf  "ORn(){ rn;((m=a|n));setfXOR \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
#printf "ANDn(){ rn;((m=a&n));setfAND \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
printf "ADDn(){ rn;((m=(a+n)       &255));$acc_setfADD;a=m;return 0;}  # from $0.$LINENO\n"
printf "SUBn(){ rn;((m=(a-n)       &255));$acc_setfSUB;a=m;return 0;}  # from $0.$LINENO\n"
printf "ADCn(){ rn;((m=(a+n+(f&FC))&255));$acc_setfADC;a=m;u=$FC;return 0;}  # from $0.$LINENO\n"
printf "SBCn(){ rn;((m=(a-n-(f&FC))&255));$acc_setfSBC;a=m;u=$FC;return 0;}  # from $0.$LINENO\n"
printf  "CPn(){ rn;((m=(a-n)       &255));$acc_setfCP;}  # from $0.$LINENO\n"  # different
printf "XORn(){ rn;((m=a^n));$acc_setfXOR;a=m;return 0;}  # from $0.$LINENO\n"
printf  "ORn(){ rn;((m=a|n));$acc_setfOR; a=m;return 0;}  # from $0.$LINENO\n"
printf "ANDn(){ rn;((m=a&n));$acc_setfAND;a=m;return 0;}  # from $0.$LINENO\n"

printf "EXDEHL(){ n=d;d=h;h=n;n=e;e=l;l=n;return 0;}  # from $0.$LINENO\n"
#printf "LDHLmn(){ (($HL));rn;wb \$hl \$n;}  # from $0.$LINENO\n"
printf "LDHLmn(){ (($HL));rn;memprotb \$hl \$n;MEM[hl]=n;}  # from $0.$LINENO\n"

printf "# (HL) instructions\n"
for rp in hl; do
    rh="${rp::1}"
    rl="${rp:1}"
    RP="${RPN[$rp]}"
    RR="rr=($rh<<8)|$rl"

    #SETF="setfROTr 0 \$m \$n"
    SETF="$acc_setfROTr"
    #_RB="(( $RR )); rb \$rr"  # was (( $RR )); rb \$rr
    _RB="(($RR));memread \$rr;n=MEM[rr]"  # was (( $RR )); rb \$rr
    #_WB="wb \$rr \$n;$SETF"  # was wb \$rr \$n; $SETF
    _WB="memprotb \$rr \$n;MEM[rr]=n;$SETF"
    printf  "RL${RP}m(){ $_RB;((m=n>>7,n=((n<<1)|(f&FC))&255));u=$FC;$_WB;}  # from $0.$LINENO\n"
    printf  "RR${RP}m(){ $_RB;((m=n&FC,n=((n>>1)|(f<<7))&255));u=$FC;$_WB;}  # from $0.$LINENO\n"
    printf "RLC${RP}m(){ $_RB;((m=n>>7,n=((n<<1)|(n>>7))&255));$_WB;}  # from $0.$LINENO\n"
    printf "RRC${RP}m(){ $_RB;((m=n&FC,n=((n>>1)|(n<<7))&255));$_WB;}  # from $0.$LINENO\n"
    printf "SLA${RP}m(){ $_RB;((m=n>>7,n=((n<<1)       )&255));$_WB;}  # from $0.$LINENO\n"
    printf "SRA${RP}m(){ $_RB;((m=n&FC,n=((n>>1)|(n&FS))&255));$_WB;}  # from $0.$LINENO\n"
    printf "SLL${RP}m(){ $_RB;((m=n>>7,n=((n<<1)|1     )&255));$_WB;}  # from $0.$LINENO\n"
    printf "SRL${RP}m(){ $_RB;((m=n&FC,n=((n>>1)       )&255));$_WB;}  # from $0.$LINENO\n"

    #printf "INC${RP}m(){ $_RB;((m=(n+1)&255));wb \$rr \$m;setfINC \$n 1 \$m;}  # from $0.$LINENO\n"
    #printf "DEC${RP}m(){ $_RB;((m=(n-1)&255));wb \$rr \$m;setfDEC \$n 1 \$m;}  # from $0.$LINENO\n"
    printf "INC${RP}m(){ $_RB;((m=(n+1)&255));memprotb \$rr \$m;MEM[rr]=m;$acc_setfINC;}  # from $0.$LINENO\n"
    printf "DEC${RP}m(){ $_RB;((m=(n-1)&255));memprotb \$rr \$m;MEM[rr]=m;$acc_setfDEC;}  # from $0.$LINENO\n"

    #printf "ADD${RP}m(){ $_RB;((m=(a+n)       &255));setfADD \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf "SUB${RP}m(){ $_RB;((m=(a-n)       &255));setfSUB \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf "ADC${RP}m(){ $_RB;((m=(a+n+(f&FC))&255));setfADD \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf "SBC${RP}m(){ $_RB;((m=(a-n-(f&FC))&255));setfSUB \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf  "CP${RP}m(){ $_RB;((m=(a-n)       &255));setfCP  \$a \$n \$m;}  # from $0.$LINENO\n"  # different
    #printf "XOR${RP}m(){ $_RB;((m=a^n));setfXOR \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf  "OR${RP}m(){ $_RB;((m=a|n));setfXOR \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf "AND${RP}m(){ $_RB;((m=a&n));setfAND \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
    printf "ADD${RP}m(){ $_RB;((m=(a+n)       &255));$acc_setfADD;a=m;return 0;}  # from $0.$LINENO\n"
    printf "SUB${RP}m(){ $_RB;((m=(a-n)       &255));$acc_setfSUB;a=m;return 0;}  # from $0.$LINENO\n"
    printf "ADC${RP}m(){ $_RB;((m=(a+n+(f&FC))&255));$acc_setfADC;a=m;u=$FC;return 0;}  # from $0.$LINENO\n"
    printf "SBC${RP}m(){ $_RB;((m=(a-n-(f&FC))&255));$acc_setfSBC;a=m;u=$FC;return 0;}  # from $0.$LINENO\n"
    printf  "CP${RP}m(){ $_RB;((m=(a-n)       &255));$acc_setfCP;}  # from $0.$LINENO\n"  # different
    printf "XOR${RP}m(){ $_RB;((m=a^n));$acc_setfXOR;a=m;return 0;}  # from $0.$LINENO\n"
    printf  "OR${RP}m(){ $_RB;((m=a|n));$acc_setfOR; a=m;return 0;}  # from $0.$LINENO\n"
    printf "AND${RP}m(){ $_RB;((m=a&n));$acc_setfAND;a=m;return 0;}  # from $0.$LINENO\n"

    for (( _j=0; _j<8; _j++ )); do
        _ORM=$(( 1<<_j )); _ANM=$(( 255-_ORM ))
        _WB="memprotb \$rr \$m;MEM[rr]=m"
        printf "BIT$_j${RP}m(){ $_RB;setfBITh $_j \$h \$((n&$_ORM));}  # from $0.$LINENO\n"
        #printf "SET$_j${RP}m(){ $_RB;if((!(n&$_ORM)));then wb \$rr \$((n|$_ORM));fi;}  # from $0.$LINENO\n"
        #printf "RES$_j${RP}m(){ $_RB;if(( (n&$_ORM)));then wb \$rr \$((n&$_ANM));fi;}  # from $0.$LINENO\n"
        printf "SET$_j${RP}m(){ $_RB;if((!(n&$_ORM)));then ((m=n|$_ORM));$_WB;fi;}  # from $0.$LINENO\n"
        printf "RES$_j${RP}m(){ $_RB;if(( (n&$_ORM)));then ((m=n&$_ANM));$_WB;fi;}  # from $0.$LINENO\n"
    done
done

printf "# 16 bit register instructions - assume D already read in map\n"
for rp in xX yY; do
    rh="${rp::1}"
    rl="${rp:1}"
    RP="${RPN[$rp]}"
    RR="rr=($rh<<8)|$rl"
    if $_FAST; then
        RRD="rrd=($rh<<8)+$rl+D"
        RRDV="\$((($rh<<8)+$rl+D))"
    else
        RRD="rrd=(($rh<<8)+$rl+D)&65535"
        RRDV="\$(((($rh<<8)+$rl+D)&65535))"
    fi
    
    #printf "LD${RP}mn(){ rD;(($RR,$RRD));rn;wb \$rrd \$n;}  # from $0.$LINENO\n"  # redundant RR?
    #printf "LD${RP}mn(){ rD;(($RRD));rn;wb \$rrd \$n;}  # from $0.$LINENO\n"
    printf "LD${RP}mn(){ rD;(($RRD));rn;memprotb \$rrd \$n;MEM[rrd]=n;}  # from $0.$LINENO\n"
    #SETF="setfROTr 0 \$m \$n"
    SETF="$acc_setfROTr"
    #_RB="(( $RRD )); rb \$rrd"
    _RB="(($RRD));memread \$rrd;n=MEM[rrd]"
    #_WB="wb \$rrd \$n;$SETF"  # was wb \$rrd \$n; $SETF
    _WB="memprotb \$rrd \$n;MEM[rrd]=n;$SETF"
    printf  "RL${RP}m(){ $_RB;((m=n>>7,n=((n<<1)|(f&FC))&255 ));u=$FC;$_WB;}  # from $0.$LINENO\n"
    printf  "RR${RP}m(){ $_RB;((m=n&FC,n=((n>>1)|(f<<7))&255 ));u=$FC;$_WB;}  # from $0.$LINENO\n"
    printf "RLC${RP}m(){ $_RB;((m=n>>7,n=((n<<1)|(n>>7))&255 ));$_WB;}  # from $0.$LINENO\n"
    printf "RRC${RP}m(){ $_RB;((m=n&FC,n=((n>>1)|(n<<7))&255 ));$_WB;}  # from $0.$LINENO\n"
    printf "SLA${RP}m(){ $_RB;((m=n>>7,n=((n<<1)       )&255 ));$_WB;}  # from $0.$LINENO\n"
    printf "SRA${RP}m(){ $_RB;((m=n&FC,n=((n>>1)|(n&FS))&255 ));$_WB;}  # from $0.$LINENO\n"
    printf "SLL${RP}m(){ $_RB;((m=n>>7,n=((n<<1)|1     )&255 ));$_WB;}  # from $0.$LINENO\n"
    printf "SRL${RP}m(){ $_RB;((m=n&FC,n=((n>>1)       )&255 ));$_WB;}  # from $0.$LINENO\n"

    for r1 in a b c d e  h l; do
        R1="${RN[$r1]}" 
        printf  "RL${RP}mr_$r1(){ $_RB;((m=n>>7,n=((n<<1)|(f&FC))&255,$r1=n));u=$FC;$_WB;}  # from $0.$LINENO\n"
        printf  "RR${RP}mr_$r1(){ $_RB;((m=n&FC,n=((n>>1)|(f<<7))&255,$r1=n));u=$FC;$_WB;}  # from $0.$LINENO\n"
        printf "RLC${RP}mr_$r1(){ $_RB;((m=n>>7,n=((n<<1)|(n>>7))&255,$r1=n));$_WB;}  # from $0.$LINENO\n"
        printf "RRC${RP}mr_$r1(){ $_RB;((m=n&FC,n=((n>>1)|(n<<7))&255,$r1=n));$_WB;}  # from $0.$LINENO\n"
        printf "SLA${RP}mr_$r1(){ $_RB;((m=n>>7,n=((n<<1)       )&255,$r1=n));$_WB;}  # from $0.$LINENO\n"
        printf "SRA${RP}mr_$r1(){ $_RB;((m=n&FC,n=((n>>1)|(n&FS))&255,$r1=n));$_WB;}  # from $0.$LINENO\n"
        printf "SLL${RP}mr_$r1(){ $_RB;((m=n>>7,n=((n<<1)|1     )&255,$r1=n));$_WB;}  # from $0.$LINENO\n"
        printf "SRL${RP}mr_$r1(){ $_RB;((m=n&FC,n=((n>>1)       )&255,$r1=n));$_WB;}  # from $0.$LINENO\n"
    done

    for (( _j=0; _j<8; _j++ )); do
        _ORM=$(( 1<<_j )); _ANM=$(( 255-_ORM ))
        _WB="memprotb \$rrd \$m;MEM[rrd]=m"
        printf "BIT$_j${RP}m(){ $_RB;setfBITx $_j \$((rrd>>8)) \$((n&$_ORM));}  # from $0.$LINENO\n"  # [SY05]
        printf "SET$_j${RP}m(){ $_RB;if((!(n&$_ORM)));then ((m=n|$_ORM));$_WB;fi;}  # from $0.$LINENO\n"
        printf "RES$_j${RP}m(){ $_RB;if(( (n&$_ORM)));then ((m=n&$_ANM));$_WB;fi;}  # from $0.$LINENO\n"
    done

    #printf "INC${RP}m(){ rD;$_RB;((m=(n+1)&255));setfINC \$n 1 \$m;wb \$rrd \$m;}  # from $0.$LINENO\n"
    #printf "DEC${RP}m(){ rD;$_RB;((m=(n-1)&255));setfDEC \$n 1 \$m;wb \$rrd \$m;}  # from $0.$LINENO\n"
    #incx bug _WB="memprotb \$rrd \$m;MEM[rrd]=m;$SETF"
    _WB="memprotb \$rrd \$m;MEM[rrd]=m"
    printf "INC${RP}m(){ rD;$_RB;((m=(n+1)&255));$acc_setfINC;$_WB;}  # from $0.$LINENO\n"
    printf "DEC${RP}m(){ rD;$_RB;((m=(n-1)&255));$acc_setfDEC;$_WB;}  # from $0.$LINENO\n"

    # FIXME: do for others if ok
    _RB="rD;rb $RRDV"
    #_RB="rD; memread $RRDV; n=MEM[$RRDV]"  # FIXME: broken
    #printf "ADD${RP}m(){ $_RB;((m=(a+n)       &255));setfADD \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf "SUB${RP}m(){ $_RB;((m=(a-n)       &255));setfSUB \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf "ADC${RP}m(){ $_RB;((m=(a+n+(f&FC))&255));setfADD \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf "SBC${RP}m(){ $_RB;((m=(a-n-(f&FC))&255));setfSUB \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf  "CP${RP}m(){ $_RB;((m=(a-n)       &255));setfCP  \$a \$n \$m;}  # from $0.$LINENO\n"  # different
    #printf "XOR${RP}m(){ $_RB;((m=a^n));setfXOR \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf  "OR${RP}m(){ $_RB;((m=a|n));setfXOR \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
    #printf "AND${RP}m(){ $_RB;((m=a&n));setfAND \$a \$n \$m;a=m;return 0;}  # from $0.$LINENO\n"
    printf "ADD${RP}m(){ $_RB;((m=(a+n)       &255));$acc_setfADD;a=m;return 0;}  # from $0.$LINENO\n"
    printf "SUB${RP}m(){ $_RB;((m=(a-n)       &255));$acc_setfSUB;a=m;return 0;}  # from $0.$LINENO\n"
    printf "ADC${RP}m(){ $_RB;((m=(a+n+(f&FC))&255));$acc_setfADC;a=m;u=$FC;return 0;}  # from $0.$LINENO\n"
    printf "SBC${RP}m(){ $_RB;((m=(a-n-(f&FC))&255));$acc_setfSBC;a=m;u=$FC;return 0;}  # from $0.$LINENO\n"
    printf  "CP${RP}m(){ $_RB;((m=(a-n)       &255));$acc_setfCP;}  # from $0.$LINENO\n"  # different
    printf "XOR${RP}m(){ $_RB;((m=a^n));$acc_setfXOR;a=m;return 0;}  # from $0.$LINENO\n"
    printf  "OR${RP}m(){ $_RB;((m=a|n));$acc_setfOR; a=m;return 0;}  # from $0.$LINENO\n"
    printf "AND${RP}m(){ $_RB;((m=a&n));$acc_setfAND;a=m;return 0;}  # from $0.$LINENO\n"
done

printf "# (HL) (IX) and (IY) instructions - these can not use D\n"
for rp in hl xX yY; do 
    rh="${rp::1}"
    rl="${rp:1}"
    RP="${RPN[$rp]}"
    RR="rr=($rh<<8)|$rl"
    SETrpmm="$rh=mm>>8,$rl=mm&255"

    printf      "JP$RP(){ (($RR,pc=rr));return 0;}  # from $0.$LINENO\n"
    printf    "LDSP$RP(){ (($RR,sp=rr));return 0;}  # from $0.$LINENO\n"
#    printf "ADD${RP}SP(){ (($RR,nn=(rr+sp)       &65535));setfADD16 \$rr \$sp \$nn;(($SETrpnn));return 0;}  # from $0.$LINENO\n"
#    printf "ADC${RP}SP(){ (($RR,nn=(rr+sp+(f&FC))&65535));setfADC16 \$rr \$sp \$nn;(($SETrpnn));return 0;}  # from $0.$LINENO\n"
#    printf "SBC${RP}SP(){ (($RR,nn=(rr-sp-(f&FC))&65535));setfSBC16 \$rr \$sp \$nn;(($SETrpnn));return 0;}  # from $0.$LINENO\n"
    printf "ADD${RP}SP(){ (($RR,nn=sp,mm=(rr+nn)       &65535));$acc_setfADD16;(($SETrpmm));return 0;}  # from $0.$LINENO\n"
    printf "ADC${RP}SP(){ (($RR,nn=sp,mm=(rr+nn+(f&FC))&65535));$acc_setfADC16;(($SETrpmm));u=$FC;return 0;}  # from $0.$LINENO\n"
    printf "SBC${RP}SP(){ (($RR,nn=sp,mm=(rr-nn-(f&FC))&65535));$acc_setfSBC16;(($SETrpmm));u=$FC;return 0;}  # from $0.$LINENO\n"
    
#printf "EXSPmHL(){ rw \$sp;(($HL));ww \$sp \$hl;(($SEThlnn));return 0;}  # from $0.$LINENO\n"
#printf "EXSPmIX(){ rw \$sp;(($IX));ww \$sp \$ix;(($SETixnn));return 0;}  # from $0.$LINENO\n"
#printf "EXSPmIY(){ rw \$sp;(($IY));ww \$sp \$iy;(($SETiynn));return 0;}  # from $0.$LINENO\n"
# FIXME: untested
# moved into hl xX yY
#printf "EXSPmHL(){ n=MEM[sp];m=MEM[sp+1];((MEM[sp]=l,MEM[sp+1]=h,l=n,h=m));return 0;}  # from $0.$LINENO\n"
#printf "EXSPmIX(){ n=MEM[sp];m=MEM[sp+1];((MEM[sp]=X,MEM[sp+1]=x,X=n,x=m));return 0;}  # from $0.$LINENO\n"
#printf "EXSPmIY(){ n=MEM[sp];m=MEM[sp+1];((MEM[sp]=Y,MEM[sp+1]=y,Y=n,y=m));return 0;}  # from $0.$LINENO\n"

    printf "EXSPm$RP(){ ((n=MEM[sp],m=MEM[sp+1],MEM[sp]=$rl,MEM[sp+1]=$rh,$rl=n,$rh=m));return 0;}  # from $0.$LINENO\n"

done

printf "# Rotate instructions - m is bit that moves to carry - timing checked\n"
#SETF="setfROTa 0 \$m \$a"
SETF="$acc_setfROTa"
printf  "RLA(){ ((m=a>>7,a=((a<<1)|(f&FC))&255));u=$FC;$SETF;}  # from $0.$LINENO\n"
printf  "RRA(){ ((m=a&FC,a=((a>>1)|(f<<7))&255));u=$FC;$SETF;}  # from $0.$LINENO\n"
printf "RLCA(){ ((m=a>>7,a=((a<<1)|(a>>7))&255));$SETF;}  # from $0.$LINENO\n"
printf "RRCA(){ ((m=a&FC,a=((a>>1)|(a<<7))&255));$SETF;}  # from $0.$LINENO\n"

printf "# 16 bit register instructions - timing checked\n"
for rp in bc de hl af xX yY; do 
    rh="${rp::1}"
    rl="${rp:1}"
    RP="${RPN[$rp]}"
    RR="rr=($rh<<8)|$rl"
    eval "INCrp=\$INC$rp; DECrp=\$DEC$rp"
    SETrpnn="$rh=nn>>8,$rl=nn&255"

    printf    "INC$RP(){ (($INCrp));return 0;}  # from $0.$LINENO\n"
    printf    "DEC$RP(){ (($DECrp));return 0;}  # from $0.$LINENO\n"
    #printf "LD${RP}nn(){ rn; rm; (( $rl=n, $rh=m ));        return 0; }  # from $0.$LINENO\n"
    printf "LD${RP}nn(){ ldrpnn$rp;return 0;}  # from $0.$LINENO\n"
    #printf "LD${RP}mm(){ rmm; rb2 \$mm; (( $rl=n, $rh=m )); return 0; }  # from $0.$LINENO\n"
    if $_FAST; then
        printf   "LDmm$RP(){ rmm;((rr));memprotw \$mm \$rr;MEM[mm]=$rl;MEM[mm+1]=$rh;return 0;}  # from $0.$LINENO\n"
        printf "LD${RP}mm(){ rmm;memread \$mm;$rl=MEM[mm];$rh=MEM[mm+1];return 0;}  # from $0.$LINENO\n"
        #printf   "PUSH$RP(){ pushb \$$rh;pushb \$$rl;}  # from $0.$LINENO\n"
        printf   "PUSH$RP(){ MEM[--sp]=$rh;MEM[--sp]=$rl;return 0;}  # from $0.$LINENO\n"
    else
        #printf   "LDmm$RP(){ rmm;wb2 \$mm \$$rl \$$rh;}  # from $0.$LINENO\n"
        printf   "LDmm$RP(){ rmm;((rr));memprotw \$mm \$rr;MEM[mm]=$rl;((MEM[(mm+1)&65535]=$rh));return 0;}  # from $0.$LINENO\n"
        printf "LD${RP}mm(){ rmm;memread  \$mm;$rl=MEM[mm];(($rh=MEM[(mm+1)&65535]));return 0;}  # from $0.$LINENO\n"
        printf   "PUSH$RP(){ MEM[sp]=$rh;(($DECSP));MEM[sp]=$rl;(($DECSP));return 0;}  # from $0.$LINENO\n"
    fi
    
    #printf    "POP$RP(){ popmn;$rl=n;$rh=m;return 0;}  # from $0.$LINENO\n"
    printf     "POP$RP(){ $rl=$pop;$rh=$pop;return 0;}  # from $0.$LINENO\n"
    
    for rp2 in hl xX yY; do 
        rh2="${rp2::1}"
        rl2="${rp2:1}"
        RP2="${RPN[$rp2]}"
        RR2="rr2=($rh2<<8)|$rl2"
        SETrp2mm="$rh2=mm>>8,$rl2=mm&255"
        
#        printf "ADD$RP2$RP(){ (($RR2,$RR,nn=(rr2+rr)       &65535,$SETrp2nn));setfADD16 \$rr2 \$rr \$nn;}  # from $0.$LINENO\n"
#        printf "ADC$RP2$RP(){ (($RR2,$RR,nn=(rr2+rr+(f&FC))&65535,$SETrp2nn));setfADC16 \$rr2 \$rr \$nn;}  # from $0.$LINENO\n"
#        printf "SBC$RP2$RP(){ (($RR2,$RR,nn=(rr2-rr-(f&FC))&65535,$SETrp2nn));setfSBC16 \$rr2 \$rr \$nn;}  # from $0.$LINENO\n"
        if [[ $rp == $rp2 ]]; then  # special cases
            printf "ADD$RP2$RP(){ (($RR,mm=(rr+rr)       &65535,$SETrp2mm));$acc_setfADD1622;}  # from $0.$LINENO\n"
            printf "ADC$RP2$RP(){ (($RR,mm=(rr+rr+(f&FC))&65535,$SETrp2mm));u=$FC;$acc_setfADC1622;}  # from $0.$LINENO\n"
            printf "SBC$RP$RP(){ (($RR,mm=(0-(f&FC))&65535,$SETrp2mm));u=$FC;$acc_setfSBC1622;}  # from $0.$LINENO\n"
        else
            printf "ADD$RP2$RP(){ (($RR2,$RR,mm=(rr2+rr)       &65535,$SETrp2mm));$acc_setfADD162;}  # from $0.$LINENO\n"
            printf "ADC$RP2$RP(){ (($RR2,$RR,mm=(rr2+rr+(f&FC))&65535,$SETrp2mm));u=$FC;$acc_setfADC162;}  # from $0.$LINENO\n"
            printf "SBC$RP2$RP(){ (($RR2,$RR,mm=(rr2-rr-(f&FC))&65535,$SETrp2mm));u=$FC;$acc_setfSBC162;}  # from $0.$LINENO\n"
        fi
        #printf "ADD$RP2$RP(){ (( $rl2+=$rl, m=$rh2+$rh, $rl2>255?(m+=1,$rl2-=256):0 )); setfADD \$$rh2 \$$rh \$m; (( $rh2=m&255 )); }  # from $0.$LINENO\n"
    done
done

# special cases for PUSH AF and POP AF
# PUSH AF uses all flags (u=ff)
# POP AF sets all flags (k=ff)
if $_FAST; then
    printf "PUSHAF2(){ MEM[--sp]=a;MEM[--sp]=f;u=0xff;return 0;}  # from $0.$LINENO\n"
else
    printf "PUSHAF2(){ MEM[sp]=a;(($DECSP));MEM[sp]=f;(($DECSP));u=0xff;return 0;}  # from $0.$LINENO\n"
fi
printf  "POPAF2(){ f=$pop;a=$pop;k=0xff;return 0;}  # from $0.$LINENO\n"

printf "# SP instructions - timing checked\n"
printf "LDSPnn(){ rnn;sp=nn;return 0;}  # from $0.$LINENO\n"
#printf "LDmmSP(){ rmm;ww \$mm \$sp;return 0;}  # from $0.$LINENO\n"
printf "LDmmSP(){ rmm;memprotw \$mm \$sp;((MEM[mm]=sp&255,MEM[mm+1]=(sp>>8)));return 0;}  # from $0.$LINENO\n"
#printf "LDSPmm(){ rmm;rw \$mm;sp=nn;return 0;}  # from $0.$LINENO\n"
printf "LDSPmm(){ rmm;memread \$mm;((sp=MEM[mm]+(MEM[mm+1]<<8)));return 0;}  # from $0.$LINENO\n"
printf  "INCSP(){ (($INCSP));return 0;}  # from $0.$LINENO\n"
printf  "DECSP(){ (($DECSP));return 0;}  # from $0.$LINENO\n"

printf "EXAFAF(){ n=a;a=a1;a1=n;n=f;f=f1;f1=n;u=0xff;return 0;}  # from $0.$LINENO\n"
# printf "EXX(){ for g in b c d e h l; do eval \"((n=\$g,\$g=\${g}1,\${g}1=n))\"; done; return 0; }  # from $0.$LINENO\n"
DF=
for g in b c d e h l; do
    DF+="n=$g,$g=${g}1,${g}1=n,"
done
printf "EXX(){ ((${DF:: -1}));return 0;}  # from $0.$LINENO\n"

printf "# RST instructions - flags, timing checked\n"
for p in '00' '08' 10 18 20 28 30 38; do
    printf "RST$p(){ pushw \$pc;pc=0x00$p;return 0;}  # from $0.$LINENO\n"
done

#    printf \"a=[%%02x] _K=[%%s] _diff=[%%02x]\n\" \$a \"\$_K\" \$_diff
printf "DAA(){
    local -i _diff _fc _fh _hc _lo _hi;
    (( _lo=a&15, _hi=a>>4, _diff=(_lo<=9) ? (a<=0x99 ? 0 : 0x60) : (a<=0x8f ? 6 : 0x66) ));
    (( _diff|=f&FC ? 0x60 : 0, _diff|=f&FH ? 0x06 : 0 ));
    (( _fc=(f&FC) ? FC : (a<=0x99 ? 0 : FC) ));
    (( _fh=(f&FN) ? (f&FH?(_lo<=5 ? FH : 0) : 0) : (_lo>=10 ? FH : 0) ));
    (( _hc=_fc|_fh ));
    (( a=(a+(f&FN ? (-_diff) : _diff))&255 )); setfDAA 0 \$_hc \$a; u=$((FH+FN+FC));
}  # from $0.$LINENO\n"

} >> $GEN

