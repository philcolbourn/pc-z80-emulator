#!/bin/bash

# Fast functions

# Functions should not contain} unless followed by a " or;or anything but a comment
# eg. R="${RP[n]}" or R=${RP[n]};
# eg. (( a==0 ))&&{ a=b;}||c=d;

{
printf "# Generated functions\n"

printf "# Some loads - timing checked\n"
#printf "acc_LDAmm='rb \$mm;a=n;'\n"
printf "acc_LDAmm='memread \$mm;a=MEM[mm];'\n"
#printf "acc_LDmmA='wb \$mm \$a;'\n"
printf "acc_LDmmA='memprotb \$mm \$a;MEM[mm]=a;'\n"
#printf "acc_LDAmm='$rb \$mm;a=n;'\n"
#printf "acc_LDmmA='$wb \$mm \$a;'\n"
#printf "acc_LDBCmA='wb $BCV \$a;'\n"
#printf "acc_LDDEmA='wb $DEV \$a;'\n"
printf "acc_LDBCmA='(($BC));memprotb \$bc \$a;MEM[bc]=a;'\n"
printf "acc_LDDEmA='(($DE));memprotb \$de \$a;MEM[de]=a;'\n"

#printf "acc_LDABCm='rb $BCV;a=n;'\n"
#printf "acc_LDADEm='rb $DEV;a=n;'\n"
printf "acc_LDABCm='(($BC));memread \$bc;a=MEM[bc];'\n"
printf "acc_LDADEm='(($DE));memread \$de;a=MEM[de];'\n"

printf "# Jumps, calls and returns - timing checked\n"
#printf "acc_JPnn='pc=nn;'\n"
#printf "acc_JRn='(( $NNPCD, pc=nn ));'\n"
#printf "acc_JRn='(( $PCD ));'\n"
printf "acc_JPnn=''\n"
printf "acc_JRn=''\n"
#printf "acc_CALLnn='pushpcnn;'\n"
printf "acc_CALLnn='((MEM[--sp]=pc>>8,MEM[--sp]=pc&255,pc=nn));'\n"
#printf "acc_CALLnn='$(( MEM[--sp]=pc>>8, MEM[--sp]=pc&255, pc=nn ));'\n"
printf "acc_RET='$poppc;'\n"
printf "acc_RETI='$poppc;iff1=iff2;'\n"
printf "acc_RETN='$poppc;iff1=iff2;'\n"

printf "# Conditional Jump, Call, and Return instructions - timing checked\n"
for g in "Z:NZ:Z" "C:NC:C" "PE:PO:P" "M:P:S";do
S="${g%%:*}"
N="${g#*:}";N="${N%:*}"
F="${g##*:}";# Set, Not set, and Flag name
#printf "acc_JP${N}nn='((f&F$F?0:(pc=nn)));'\n"
#printf "acc_JP${S}nn='((f&F$F?(pc=nn):0));'\n"
#printf "acc_JR${N}n='(($NNPCD,f&F$F?0:(pc=nn)));'\n"
#printf "acc_JR${S}n='(($NNPCD,f&F$F?(pc=nn):0 ));'\n"
#printf "acc_JR${N}n='((f&F$F?0:($PCD)));'\n"
#printf "acc_JR${S}n='((f&F$F?($PCD):0));'\n"
printf "acc_JP${N}nn='((pc=(f&F$F)?cc:jj));'\n"
printf "acc_JP${S}nn='((pc=(f&F$F)?jj:cc));'\n"
printf "acc_JR${N}n='((pc=(f&F$F)?cc:jj));'\n"
printf "acc_JR${S}n='((pc=(f&F$F)?jj:cc));'\n"
#printf "acc_CALL${S}nn='if(( (f&F$F)));then pushpcnn;fi;'\n"
#printf "acc_RET$N='if((!(f&F$F)));then poppc;fi;'\n"
#printf "acc_RET$S='if(( (f&F$F)));then poppc;fi;'\n"
#printf "acc_CALL${N}nn='if((!(f&F$F)));then pushpcnn;fi;'\n"
#printf "acc_CALL${N}nn='if((!(f&F$F)));then ((MEM[--sp]=pc>>8,MEM[--sp]=pc&255,pc=nn));fi;'\n"
#printf "acc_CALL${N}nn='$if((!(f&F$F)));then pushpcnn;fi;'\n"
# I test sed rules with this line
#printf "acc_CALL${S}nn='if(((f&F$F)));then pushpcnn;fi;'\n"
printf "acc_CALL${N}nn='(((f&F$F)?0:(MEM[--sp]=pc>>8,MEM[--sp]=pc&255,pc=nn)));'\n"
printf "acc_CALL${S}nn='(((f&F$F)?(MEM[--sp]=pc>>8,MEM[--sp]=pc&255,pc=nn):0));'\n"

#printf "acc_RET$N='((!(f&F$F)))&&poppc;'\n"
#printf "acc_RET$S='(( (f&F$F)))&&poppc;'\n"
#printf "acc_RET$N='if((!(f&F$F)));then { $poppc;};fi;'\n"
#printf "acc_RET$S='if(( (f&F$F)));then { $poppc;};fi;'\n"
#printf "acc_RET$N='if((!(f&F$F)));then ((pc=MEM[sp++],pc+=MEM[sp++]*256));fi;'\n"
#printf "acc_RET$S='if(( (f&F$F)));then ((pc=MEM[sp++],pc+=MEM[sp++]*256));fi;'\n"
#printf "acc_RET$N='((!(f&F$F)))&&((pc=MEM[sp++],pc+=MEM[sp++]*256));'\n"
#printf "acc_RET$S='(( (f&F$F)?(pc=MEM[sp++],pc+=MEM[sp++]*256):0));'\n"
#badprintf "acc_RET$N='(((f&F$F)?(pc=MEM[sp]+MEM[sp+1]*256,sp+=2):0));'\n"
#badprintf "acc_RET$S='(((f&F$F)?0:(pc=MEM[sp]+MEM[sp+1]*256,sp+=2)));'\n"
#printf "acc_RET$N='((f&F$F))||((pc=MEM[sp++],pc+=MEM[sp++]*256));'\n"
#printf "acc_RET$S='printf \"%%04x %%02x \" \$pc \$((f&F$F));((f&F$F))&&((pc=MEM[sp++],pc+=(MEM[sp++]<<8)));printf \"%%04x\\\n\" \$pc;'\n"
#printf "acc_RET$N='(((f&F$F)?0:(pc=MEM[sp++],pc+=(MEM[sp++]<<8))));'\n"
#printf "acc_RET$S='printf \"%%04x %%02x \" \$pc \$((f&F$F));(((f&F$F)>0?(pc=MEM[sp++],pc+=(MEM[sp++]<<8)):0));printf \"%%04x\\\n\" \$pc;'\n"
#printf "acc_RET$S='printf "acc_.";(((f&F$F)?(pc=MEM[sp++],pc+=(MEM[sp++]<<8)):0));printf "acc_c";'\n"
#printf "acc_RET$S='printf "acc_.";((f&F$F?(${poppc//;/,}):0));printf "acc_c";'\n"
printf "acc_RET$N='((f&F$F?0:(pc=MEM[sp++],pc+=(MEM[sp++]<<8))));'\n"
#printf "acc_RET$S='((f&F$F?(pc=MEM[sp++],pc+=(MEM[sp++]<<8)):0));'\n"
printf "acc_RET$S='((f&F$F?pc=MEM[sp++],pc+=(MEM[sp++]<<8):0));'\n"
done

printf "# block move - timing checked\n"
# Notes: must unset AREA after reading character from (DE)
INCBLOCK="$INChl,$INCde,$DECbc"
DECBLOCK="$DEChl,$DECde,$DECbc"
#INCBLOCKR="$INChl,$INCde,$DECBC,$SETbc,(bc>0)?(pc=(pc-2)&65535):(q+=3,t+=12)"
#DECBLOCKR="$DEChl,$DECde,$DECBC,$SETbc,(bc>0)?(pc=(pc-2)&65535):(q+=3,t+=12)"
if $_FAST;then
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

#printf "acc_LDI='(($HL,$DE,$BC));rb \$de;m=n;rb \$hl;wb \$de \$n;(($INCBLOCK));setfLDI 0 \$a \$n;'\n"
#printf "acc_LDD='(($HL,$DE,$BC));rb \$de;m=n;rb \$hl;wb \$de \$n;(($DECBLOCK));setfLDI 0 \$a \$n;'\n"
#printf "acc_LDI='(($HL,$DE,$BC));rb \$hl;wb \$de \$n;(($INCBLOCK));setfLDI 0 \$a \$n;'\n"
#printf "acc_LDD='(($HL,$DE,$BC));rb \$hl;wb \$de \$n;(($DECBLOCK));setfLDI 0 \$a \$n;'\n"
#printf "acc_LDI='(($HL,$DE,$BC));memread \$hl;n=MEM[hl];wb \$de \$n;(($INCBLOCK));$acc_setfLDI;'\n"
#printf "acc_LDD='(($HL,$DE,$BC));memread \$hl;n=MEM[hl];wb \$de \$n;(($DECBLOCK));$acc_setfLDI;'\n"
printf "acc_LDI='(($HL,$DE,$BC));memread \$hl;n=MEM[hl];memprotb \$de \$n;MEM[de]=n;(($INCBLOCK));$acc_setfLDI;'\n"
printf "acc_LDD='(($HL,$DE,$BC));memread \$hl;n=MEM[hl];memprotb \$de \$n;MEM[de]=n;(($DECBLOCK));$acc_setfLDI;'\n"

# z80 implementation of LDIR is LDI + no change to PC - this is inefficient in an emulator due to composing and decomposing double registers each itteration
#printf "acc_XLDIR='(($HL,$DE,$BC));rb \$de;m=n;rb \$hl;wb \$de \$n;(($INCBLOCKR));setfLDIR 0 \$a \$n;'\n"
#printf "acc_XLDDR='(($HL,$DE,$BC));rb \$de;m=n;rb \$hl;wb \$de \$n;(($DECBLOCKR));setfLDIR 0 \$a \$n;'\n"
printf "acc_XLDIR='(($HL,$DE,$BC));rb \$hl;memprotb \$de \$n;MEM[de]=n;(($INCBLOCKR));$acc_setfLDIR;'\n"
printf "acc_XLDDR='(($HL,$DE,$BC));rb \$hl;memprotb \$de \$n;MEM[de]=n;(($DECBLOCKR));$acc_setfLDIR;'\n"

# alternative implementation for efficiency - but can still be done better - timing wrong?
printf "acc_LDIR='
(($HL,$DE,$BC));
while ((bc>0));do # FIXME: assume bc never 0 from start
#rb \$hl;memprotb \$de \$n;MEM[de]=n;# wb \$de \$n;
memread \$hl;n=MEM[hl];memprotb \$de \$n;MEM[de]=n;# wb \$de \$n;
(($INCHL,$INCDE,bc-=1));# just inc and dec double registers
done;
(($SEThl,$SETde,b=c=0));# copy results into registers
#setfLDIR 0 \$a \$n;# flags set on last character moved
$acc_setfLDIR;# flags set on last character moved

'\n"

printf "acc_LDDR='
(($HL,$DE,$BC));
while ((bc>0));do
#rb \$hl;memprotb \$de \$n;MEM[de]=n;# wb \$de \$n;
memread \$hl;n=MEM[hl];memprotb \$de \$n;MEM[de]=n;# wb \$de \$n;
(($DECHL,$DECDE,bc-=1));# just dec double registers
done;
(($SEThl,$SETde,b=c=0));# copy results into registers
#setfLDIR 0 \$a \$n;# flags set on last character moved
$acc_setfLDIR;# flags set on last character moved

'\n"


printf "acc_CPI='(($HL,$BC));rb \$hl;((m=(a-n)&255 ));(($INCCOMP));setfCPI \$a \$n \$m;'\n"
printf "acc_CPD='(($HL,$BC));rb \$hl;((m=(a-n)&255 ));(($DECCOMP));setfCPI \$a \$n \$m;'\n"
printf "acc_CPIR='(($HL,$BC));rb \$hl;((m=(a-n)&255 ));(($INCCOMPR));setfCPI \$a \$n \$m;'\n"
printf "acc_CPDR='(($HL,$BC));rb \$hl;((m=(a-n)&255 ));(($DECCOMPR));setfCPI \$a \$n \$m;'\n"


printf "acc_INI=''\n"
printf "acc_IND=''\n"
printf "acc_INIR=''\n"
printf "acc_INDR=''\n"
printf "acc_OUTI=''\n"
printf "acc_OUTD=''\n"
printf "acc_OTIR=''\n"
printf "acc_OTDR=''\n"

printf "# misc - timing checked\n"
#printf "acc_DJNZn='(($NNPCD,b=(b-1)&255,b?(pc=nn):0 ));'\n"
#printf "acc_DJNZn='((b=(b-1)&255,b?($PCD):0 ));'\n"
printf "acc_DJNZn='((b=(b-1)&255,pc=(b?jj:cc) ));'\n"
#printf "acc_DJNZn='((b--,b&=255,pc=(b?jj:cc)));'\n"

printf "acc_NOP=''\n"
printf "acc_HALT='halt=1;'\n"

printf "acc_DI='iff1=iff2=0;'\n"
printf "acc_EI='iff1=iff2=1;'\n"
printf "acc_IM0=''\n"
printf "acc_IM01=''\n"
printf "acc_IM1=''\n"
printf "acc_IM2=''\n"

printf "acc_LDIA='i=a;'\n"
printf "acc_LDAI='a=i;'\n"
printf "acc_LDRA='((r7=a&0x80,r=a));'\n"
printf "acc_LDAR='a=r;'\n"


printf "# IN and OUT - timing checked\n"
printf "acc_OUTnA='wp \$n \$a;'\n"
printf "acc_INAn='rp \$m;a=n;'\n"

for r1 in a f b c d e h l;do R1="${RN[$r1]}"
printf "acc_IN${R1}C='rp \$c;\$$r1=n;'\n"
printf "acc_OUTC${R1}='wp \$c \$$r1;'\n"
done

printf "acc_IN0C='rp \$c;'\n"
printf "acc_OUTC0='wp \$c 0;'\n"

printf "# - timing checked\n"
printf "acc_CPL='((m=(~a)&255));setfCPL 0 0 \$m;a=m;'\n"
printf "acc_NEG='((m=(0-a)&255));setfSUB 0 \$a \$m;a=m;'\n"

printf "acc_CCF='u=$FC;setfCCF 0 \$(((f&FC)*FH)) 0;'\n"
printf "acc_SCF='setfSCF 0 0 0;'\n"

SETF="setfRLD 0 0 \$a"
_RB="(($HL));memread \$hl;n=MEM[hl]"
_WB="memprotb \$hl \$n;MEM[hl]=n;$SETF"
#printf "acc_RLD='$_RB;((m=a,a=(a&0xf0)|(n>>4),n=((n&15)<<4)|(m&15)));wb \$hl \$n;$SETF;'\n"
#printf "acc_RRD='(($HL));rb \$hl;((m=a,a=(a&0xf0)|(n&15),n=((m&15)<<4)|(n>>4)));wb \$hl \$n;$SETF;'\n"
printf "acc_RLD='$_RB;((m=a,a=(a&0xf0)|(n>>4),n=((n&15)<<4)|(m&15)));$_WB;'\n"
printf "acc_RRD='$_RB;((m=a,a=(a&0xf0)|(n&15),n=((m&15)<<4)|(n>>4)));$_WB;'\n"

printf "# 8 bit register instructions - ?\n"
for r1 in b c d e h l a x X y Y;do R1="${RN[$r1]}"
for r2 in b c d e h l a x X y Y;do R2="${RN[$r2]}"
printf "acc_LDrr_$r1$r2='$r1=$r2;'\n"
done

#printf "acc_LDrHLm_$r1='(($HL));rb \$hl;$r1=n;'\n"
printf "acc_LDrHLm_$r1='(($HL));memread \$hl;$r1=MEM[hl];'\n"
#printf "acc_LDHLmr_$r1='(($HL));wb \$hl \$$r1;'\n"
printf "acc_LDHLmr_$r1='(($HL));memprotb \$hl \$$r1;MEM[hl]=$r1;'\n"
#printf "acc_LDrn_$r1='$r1=n;'\n"
printf "acc_LDrn_$r1=''\n"
# fixed ordering problem: was $r1=n;rb \$mm;
#printf "acc_LDrIXm_$r1='(($IX,mm=(ix+D)&65535));rb \$mm;$r1=n;'\n"
#printf "acc_LDrIYm_$r1='(($IY,mm=(iy+D)&65535));rb \$mm;$r1=n;'\n"
#printf "acc_LDrIXm_$r1='(($IX,mm=ix+D));memread \$mm;$r1=MEM[mm];'\n"
#printf "acc_LDrIYm_$r1='(($IY,mm=iy+D));memread \$mm;$r1=MEM[mm];'\n"
#printf "acc_LDIXmr_$r1='(($IX,mm=ix+D));wb \$mm \$$r1;'\n"
#printf "acc_LDIYmr_$r1='(($IY,mm=iy+D));wb \$mm \$$r1;'\n"
printf "acc_LDrIXm_$r1='(($MMIXD));memread \$mm;$r1=MEM[mm];'\n"
printf "acc_LDrIYm_$r1='(($MMIYD));memread \$mm;$r1=MEM[mm];'\n"
#printf "acc_LDIXmr_$r1='(($MMIXD));wb \$mm \$$r1;'\n"
#printf "acc_LDIYmr_$r1='(($MMIYD));wb \$mm \$$r1;'\n"
printf "acc_LDIXmr_$r1='(($MMIXD));memprotb \$mm \$$r1;MEM[mm]=$r1;'\n"
printf "acc_LDIYmr_$r1='(($MMIYD));memprotb \$mm \$$r1;MEM[mm]=$r1;'\n"

# BUG: where r1=a, ended up with setfADD n a a which means original value of a is lost
# now, interestingly, these are same as CP
# FIXME: could be more efficient if a=r1 is a special case

#printf "acc_ADDr_$r1='((m=(a+$r1) &255));setfADD \$a \$$r1 \$m;a=m;'\n"
#printf "acc_SUBr_$r1='((m=(a-$r1) &255));setfSUB \$a \$$r1 \$m;a=m;'\n"
#printf "acc_ADCr_$r1='((m=(a+$r1+(f&FC))&255));setfADD \$a \$$r1 \$m;a=m;'\n"
#printf "acc_SBCr_$r1='((m=(a-$r1-(f&FC))&255));setfSUB \$a \$$r1 \$m;a=m;'\n"
#printf "acc_CPr_$r1='((m=(a-$r1) &255));setfCP \$a \$$r1 \$m;'\n"
#printf "acc_XORr_$r1='((m=a^$r1));setfXOR \$a \$$r1 \$m;a=m;'\n"
#printf "acc_ORr_$r1='((m=a|$r1));setfXOR \$a \$$r1 \$m;a=m;'\n"
#printf "acc_ANDr_$r1='((m=a&$r1));setfAND \$a \$$r1 \$m;a=m;'\n"
printf "acc_ADDr_$r1='((n=$r1,m=(a+n) &255));$acc_setfADD;a=m;'\n"
printf "acc_SUBr_$r1='((n=$r1,m=(a-n) &255));$acc_setfSUB;a=m;'\n"
printf "acc_ADCr_$r1='((n=$r1,m=(a+n+(f&FC))&255));$acc_setfADC;a=m;u=$FC;'\n"
printf "acc_SBCr_$r1='((n=$r1,m=(a-n-(f&FC))&255));$acc_setfSBC;a=m;u=$FC;'\n"
printf "acc_CPr_$r1='((n=$r1,m=(a-n) &255));$acc_setfCP;'\n"
printf "acc_XORr_$r1='((n=$r1,m=a^n));$acc_setfXOR;a=m;'\n"
printf "acc_ORr_$r1='((n=$r1,m=a|n));$acc_setfOR;a=m;'\n"
printf "acc_ANDr_$r1='((n=$r1,m=a&n));$acc_setfAND;a=m;'\n"

printf "acc_INCr_$r1='((n=$r1,m=(n+1)&255));$acc_setfINC;$r1=m;'\n"
printf "acc_DECr_$r1='((n=$r1,m=(n-1)&255));$acc_setfDEC;$r1=m;'\n"

#SETF="setfROTr 0 \$m \$$r1"
SETF="$acc_setfROTr"
printf "acc_RLr_$r1='((m=$r1>>7,n=$r1=(($r1<<1)|(f&FC)) &255));u=$FC;$SETF;'\n"
printf "acc_RRr_$r1='((m=$r1&FC,n=$r1=(($r1>>1)|(f<<7)) &255));u=$FC;$SETF;'\n"
printf "acc_RLCr_$r1='((m=$r1>>7,n=$r1=(($r1<<1)|($r1>>7))&255));$SETF;'\n"
printf "acc_RRCr_$r1='((m=$r1&FC,n=$r1=(($r1>>1)|($r1<<7))&255));$SETF;'\n"
printf "acc_SLAr_$r1='((m=$r1>>7,n=$r1=(($r1<<1) )&255));$SETF;'\n"
printf "acc_SLLr_$r1='((m=$r1>>7,n=$r1=(($r1<<1)|1 )&255));$SETF;'\n"
printf "acc_SRAr_$r1='((m=$r1&FC,n=$r1=(($r1>>1)|($r1&FS))&255));$SETF;'\n"
printf "acc_SRLr_$r1='((m=$r1&FC,n=$r1=(($r1>>1) )&255));$SETF;'\n"

for (( _j=0;_j<8;_j++ ));do
_ORM=$(( 1<<_j ));_ANM=$(( 255-_ORM ))
printf "acc_BIT$_j$r1='setfBIT 0 0 \$(($r1&$_ORM));'\n"
printf "acc_SET$_j$r1='(($r1|=$_ORM));'\n"
printf "acc_RES$_j$r1='(($r1&=$_ANM));'\n"
done
done

#printf "acc_ADDn='((m=(a+n) &255));setfADD \$a \$n \$m;a=m;'\n"
#printf "acc_SUBn='((m=(a-n) &255));setfSUB \$a \$n \$m;a=m;'\n"
#printf "acc_ADCn='((m=(a+n+(f&FC))&255));setfADD \$a \$n \$m;a=m;'\n"
#printf "acc_SBCn='((m=(a-n-(f&FC))&255));setfSUB \$a \$n \$m;a=m;'\n"
#printf "acc_CPn='((m=(a-n) &255));setfCP \$a \$n \$m;'\n"
#printf "acc_XORn='((m=a^n));setfXOR \$a \$n \$m;a=m;'\n"
#printf "acc_ORn='((m=a|n));setfXOR \$a \$n \$m;a=m;'\n"
#printf "acc_ANDn='((m=a&n));setfAND \$a \$n \$m;a=m;'\n"
printf "acc_ADDn='((m=(a+n) &255));$acc_setfADD;a=m;'\n"
printf "acc_SUBn='((m=(a-n) &255));$acc_setfSUB;a=m;'\n"
printf "acc_ADCn='((m=(a+n+(f&FC))&255));$acc_setfADC;a=m;u=$FC;'\n"
printf "acc_SBCn='((m=(a-n-(f&FC))&255));$acc_setfSBC;a=m;u=$FC;'\n"
printf "acc_CPn='((m=(a-n) &255));$acc_setfCP;'\n"
printf "acc_XORn='((m=a^n));$acc_setfXOR;a=m;'\n"
printf "acc_ORn='((m=a|n));$acc_setfOR;a=m;'\n"
printf "acc_ANDn='((m=a&n));$acc_setfAND;a=m;'\n"

printf "acc_EXDEHL='n=d;d=h;h=n;n=e;e=l;l=n;'\n"
#printf "acc_LDHLmn='(($HL));wb \$hl \$n;'\n"
printf "acc_LDHLmn='(($HL));memprotb \$hl \$n;MEM[hl]=n;'\n"

printf "# (HL) instructions\n"
for rp in hl;do
rh="${rp::1}"
rl="${rp:1}"
RP="${RPN[$rp]}"
RR="rr=($rh<<8)|$rl"

#SETF="setfROTr 0 \$m \$n"
SETF="$acc_setfROTr"
#_RB="(( $RR ));rb \$rr" # was (( $RR ));rb \$rr
_RB="(($RR));memread \$rr;n=MEM[rr]" # was (( $RR ));rb \$rr
#_WB="wb \$rr \$n;$SETF" # was wb \$rr \$n;$SETF
_WB="memprotb \$rr \$n;MEM[rr]=n;$SETF"
printf "acc_RL${RP}m='$_RB;((m=n>>7,n=((n<<1)|(f&FC))&255));u=$FC;$_WB;'\n"
printf "acc_RR${RP}m='$_RB;((m=n&FC,n=((n>>1)|(f<<7))&255));u=$FC;$_WB;'\n"
printf "acc_RLC${RP}m='$_RB;((m=n>>7,n=((n<<1)|(n>>7))&255));$_WB;'\n"
printf "acc_RRC${RP}m='$_RB;((m=n&FC,n=((n>>1)|(n<<7))&255));$_WB;'\n"
printf "acc_SLA${RP}m='$_RB;((m=n>>7,n=((n<<1) )&255));$_WB;'\n"
printf "acc_SRA${RP}m='$_RB;((m=n&FC,n=((n>>1)|(n&FS))&255));$_WB;'\n"
printf "acc_SLL${RP}m='$_RB;((m=n>>7,n=((n<<1)|1 )&255));$_WB;'\n"
printf "acc_SRL${RP}m='$_RB;((m=n&FC,n=((n>>1) )&255));$_WB;'\n"

#printf "acc_INC${RP}m='$_RB;((m=(n+1)&255));wb \$rr \$m;setfINC \$n 1 \$m;'\n"
#printf "acc_DEC${RP}m='$_RB;((m=(n-1)&255));wb \$rr \$m;setfDEC \$n 1 \$m;'\n"
printf "acc_INC${RP}m='$_RB;((m=(n+1)&255));memprotb \$rr \$m;MEM[rr]=m;$acc_setfINC;'\n"
printf "acc_DEC${RP}m='$_RB;((m=(n-1)&255));memprotb \$rr \$m;MEM[rr]=m;$acc_setfDEC;'\n"

#printf "acc_ADD${RP}m='$_RB;((m=(a+n) &255));setfADD \$a \$n \$m;a=m;'\n"
#printf "acc_SUB${RP}m='$_RB;((m=(a-n) &255));setfSUB \$a \$n \$m;a=m;'\n"
#printf "acc_ADC${RP}m='$_RB;((m=(a+n+(f&FC))&255));setfADD \$a \$n \$m;a=m;'\n"
#printf "acc_SBC${RP}m='$_RB;((m=(a-n-(f&FC))&255));setfSUB \$a \$n \$m;a=m;'\n"
#printf "acc_CP${RP}m='$_RB;((m=(a-n) &255));setfCP \$a \$n \$m;'\n"
#printf "acc_XOR${RP}m='$_RB;((m=a^n));setfXOR \$a \$n \$m;a=m;'\n"
#printf "acc_OR${RP}m='$_RB;((m=a|n));setfXOR \$a \$n \$m;a=m;'\n"
#printf "acc_AND${RP}m='$_RB;((m=a&n));setfAND \$a \$n \$m;a=m;'\n"
printf "acc_ADD${RP}m='$_RB;((m=(a+n) &255));$acc_setfADD;a=m;'\n"
printf "acc_SUB${RP}m='$_RB;((m=(a-n) &255));$acc_setfSUB;a=m;'\n"
printf "acc_ADC${RP}m='$_RB;((m=(a+n+(f&FC))&255));$acc_setfADC;a=m;u=$FC;'\n"
printf "acc_SBC${RP}m='$_RB;((m=(a-n-(f&FC))&255));$acc_setfSBC;a=m;u=$FC;'\n"
printf "acc_CP${RP}m='$_RB;((m=(a-n) &255));$acc_setfCP;'\n"
printf "acc_XOR${RP}m='$_RB;((m=a^n));$acc_setfXOR;a=m;'\n"
printf "acc_OR${RP}m='$_RB;((m=a|n));$acc_setfOR;a=m;'\n"
printf "acc_AND${RP}m='$_RB;((m=a&n));$acc_setfAND;a=m;'\n"

for (( _j=0;_j<8;_j++ ));do
_ORM=$(( 1<<_j ));_ANM=$(( 255-_ORM ))
_WB="memprotb \$rr \$m;MEM[rr]=m"
printf "acc_BIT$_j${RP}m='$_RB;setfBITh $_j \$h \$((n&$_ORM));'\n"
#printf "acc_SET$_j${RP}m='$_RB;if((!(n&$_ORM)));then wb \$rr \$((n|$_ORM));fi;'\n"
#printf "acc_RES$_j${RP}m='$_RB;if(( (n&$_ORM)));then wb \$rr \$((n&$_ANM));fi;'\n"
printf "acc_SET$_j${RP}m='$_RB;if((!(n&$_ORM)));then ((m=n|$_ORM));$_WB;fi;'\n"
printf "acc_RES$_j${RP}m='$_RB;if(( (n&$_ORM)));then ((m=n&$_ANM));$_WB;fi;'\n"
done
done

printf "# 16 bit register instructions - assume D already read in map\n"
for rp in xX yY;do
rh="${rp::1}"
rl="${rp:1}"
RP="${RPN[$rp]}"
RR="rr=($rh<<8)|$rl"
if $_FAST;then
RRD="rrd=($rh<<8)+$rl+D"
RRDV="\$((($rh<<8)+$rl+D))"
else
RRD="rrd=(($rh<<8)+$rl+D)&65535"
RRDV="\$(((($rh<<8)+$rl+D)&65535))"
fi

#printf "acc_LD${RP}mn='(($RR,$RRD));wb \$rrd \$n;'\n"
#printf "acc_LD${RP}mn='(($RRD));wb \$rrd \$n;'\n"
printf "acc_LD${RP}mn='(($RRD));memprotb \$rrd \$n;MEM[rrd]=n;'\n"
#SETF="setfROTr 0 \$m \$n"
SETF="$acc_setfROTr"
#_RB="(( $RRD ));rb \$rrd"
_RB="(($RRD));memread \$rrd;n=MEM[rrd]"
#_WB="wb \$rrd \$n;$SETF" # was wb \$rrd \$n;$SETF
_WB="memprotb \$rrd \$n;MEM[rrd]=n;$SETF"
printf "acc_RL${RP}m='$_RB;((m=n>>7,n=((n<<1)|(f&FC))&255 ));u=$FC;$_WB;'\n"
printf "acc_RR${RP}m='$_RB;((m=n&FC,n=((n>>1)|(f<<7))&255 ));u=$FC;$_WB;'\n"
printf "acc_RLC${RP}m='$_RB;((m=n>>7,n=((n<<1)|(n>>7))&255 ));$_WB;'\n"
printf "acc_RRC${RP}m='$_RB;((m=n&FC,n=((n>>1)|(n<<7))&255 ));$_WB;'\n"
printf "acc_SLA${RP}m='$_RB;((m=n>>7,n=((n<<1) )&255 ));$_WB;'\n"
printf "acc_SRA${RP}m='$_RB;((m=n&FC,n=((n>>1)|(n&FS))&255 ));$_WB;'\n"
printf "acc_SLL${RP}m='$_RB;((m=n>>7,n=((n<<1)|1 )&255 ));$_WB;'\n"
printf "acc_SRL${RP}m='$_RB;((m=n&FC,n=((n>>1) )&255 ));$_WB;'\n"

for r1 in a b c d e h l;do
R1="${RN[$r1]}"
printf "acc_RL${RP}mr_$r1='$_RB;((m=n>>7,n=((n<<1)|(f&FC))&255,$r1=n));u=$FC;$_WB;'\n"
printf "acc_RR${RP}mr_$r1='$_RB;((m=n&FC,n=((n>>1)|(f<<7))&255,$r1=n));u=$FC;$_WB;'\n"
printf "acc_RLC${RP}mr_$r1='$_RB;((m=n>>7,n=((n<<1)|(n>>7))&255,$r1=n));$_WB;'\n"
printf "acc_RRC${RP}mr_$r1='$_RB;((m=n&FC,n=((n>>1)|(n<<7))&255,$r1=n));$_WB;'\n"
printf "acc_SLA${RP}mr_$r1='$_RB;((m=n>>7,n=((n<<1) )&255,$r1=n));$_WB;'\n"
printf "acc_SRA${RP}mr_$r1='$_RB;((m=n&FC,n=((n>>1)|(n&FS))&255,$r1=n));$_WB;'\n"
printf "acc_SLL${RP}mr_$r1='$_RB;((m=n>>7,n=((n<<1)|1 )&255,$r1=n));$_WB;'\n"
printf "acc_SRL${RP}mr_$r1='$_RB;((m=n&FC,n=((n>>1) )&255,$r1=n));$_WB;'\n"
done

for (( _j=0;_j<8;_j++ ));do
_ORM=$(( 1<<_j ));_ANM=$(( 255-_ORM ))
_WB="memprotb \$rrd \$m;MEM[rrd]=m"
printf "acc_BIT$_j${RP}m='$_RB;setfBITx $_j \$((rrd>>8)) \$((n&$_ORM));'\n"
printf "acc_SET$_j${RP}m='$_RB;if((!(n&$_ORM)));then ((m=n|$_ORM));$_WB;fi;'\n"
printf "acc_RES$_j${RP}m='$_RB;if(( (n&$_ORM)));then ((m=n&$_ANM));$_WB;fi;'\n"
done

#printf "acc_INC${RP}m='$_RB;((m=(n+1)&255));setfINC \$n 1 \$m;wb \$rrd \$m;'\n"
#printf "acc_DEC${RP}m='$_RB;((m=(n-1)&255));setfDEC \$n 1 \$m;wb \$rrd \$m;'\n"
#incx bug _WB="memprotb \$rrd \$m;MEM[rrd]=m;$SETF"
_WB="memprotb \$rrd \$m;MEM[rrd]=m"
printf "acc_INC${RP}m='$_RB;((m=(n+1)&255));$acc_setfINC;$_WB;'\n"
printf "acc_DEC${RP}m='$_RB;((m=(n-1)&255));$acc_setfDEC;$_WB;'\n"

# FIXME: do for others if ok
_RB="rb $RRDV"
#_RB="memread $RRDV;n=MEM[$RRDV]" # FIXME: broken
#printf "acc_ADD${RP}m='$_RB;((m=(a+n) &255));setfADD \$a \$n \$m;a=m;'\n"
#printf "acc_SUB${RP}m='$_RB;((m=(a-n) &255));setfSUB \$a \$n \$m;a=m;'\n"
#printf "acc_ADC${RP}m='$_RB;((m=(a+n+(f&FC))&255));setfADD \$a \$n \$m;a=m;'\n"
#printf "acc_SBC${RP}m='$_RB;((m=(a-n-(f&FC))&255));setfSUB \$a \$n \$m;a=m;'\n"
#printf "acc_CP${RP}m='$_RB;((m=(a-n) &255));setfCP \$a \$n \$m;'\n"
#printf "acc_XOR${RP}m='$_RB;((m=a^n));setfXOR \$a \$n \$m;a=m;'\n"
#printf "acc_OR${RP}m='$_RB;((m=a|n));setfXOR \$a \$n \$m;a=m;'\n"
#printf "acc_AND${RP}m='$_RB;((m=a&n));setfAND \$a \$n \$m;a=m;'\n"
printf "acc_ADD${RP}m='$_RB;((m=(a+n) &255));$acc_setfADD;a=m;'\n"
printf "acc_SUB${RP}m='$_RB;((m=(a-n) &255));$acc_setfSUB;a=m;'\n"
printf "acc_ADC${RP}m='$_RB;((m=(a+n+(f&FC))&255));$acc_setfADC;a=m;u=$FC;'\n"
printf "acc_SBC${RP}m='$_RB;((m=(a-n-(f&FC))&255));$acc_setfSBC;a=m;u=$FC;'\n"
printf "acc_CP${RP}m='$_RB;((m=(a-n) &255));$acc_setfCP;'\n"
printf "acc_XOR${RP}m='$_RB;((m=a^n));$acc_setfXOR;a=m;'\n"
printf "acc_OR${RP}m='$_RB;((m=a|n));$acc_setfOR;a=m;'\n"
printf "acc_AND${RP}m='$_RB;((m=a&n));$acc_setfAND;a=m;'\n"
done

printf "# (HL) (IX) and (IY) instructions - these can not use D\n"
for rp in hl xX yY;do
rh="${rp::1}"
rl="${rp:1}"
RP="${RPN[$rp]}"
RR="rr=($rh<<8)|$rl"
SETrpmm="$rh=mm>>8,$rl=mm&255"

printf "acc_JP$RP='(($RR,pc=rr));'\n"
printf "acc_LDSP$RP='(($RR,sp=rr));'\n"
# printf "acc_ADD${RP}SP='(($RR,nn=(rr+sp) &65535));setfADD16 \$rr \$sp \$nn;(($SETrpnn));'\n"
# printf "acc_ADC${RP}SP='(($RR,nn=(rr+sp+(f&FC))&65535));setfADC16 \$rr \$sp \$nn;(($SETrpnn));'\n"
# printf "acc_SBC${RP}SP='(($RR,nn=(rr-sp-(f&FC))&65535));setfSBC16 \$rr \$sp \$nn;(($SETrpnn));'\n"
printf "acc_ADD${RP}SP='(($RR,nn=sp,mm=(rr+nn) &65535));$acc_setfADD16;(($SETrpmm));'\n"
printf "acc_ADC${RP}SP='(($RR,nn=sp,mm=(rr+nn+(f&FC))&65535));$acc_setfADC16;(($SETrpmm));u=$FC;'\n"
printf "acc_SBC${RP}SP='(($RR,nn=sp,mm=(rr-nn-(f&FC))&65535));$acc_setfSBC16;(($SETrpmm));u=$FC;'\n"

#printf "acc_EXSPmHL='rw \$sp;(($HL));ww \$sp \$hl;(($SEThlnn));'\n"
#printf "acc_EXSPmIX='rw \$sp;(($IX));ww \$sp \$ix;(($SETixnn));'\n"
#printf "acc_EXSPmIY='rw \$sp;(($IY));ww \$sp \$iy;(($SETiynn));'\n"
# FIXME: untested
# moved into hl xX yY
#printf "acc_EXSPmHL='n=MEM[sp];m=MEM[sp+1];((MEM[sp]=l,MEM[sp+1]=h,l=n,h=m));'\n"
#printf "acc_EXSPmIX='n=MEM[sp];m=MEM[sp+1];((MEM[sp]=X,MEM[sp+1]=x,X=n,x=m));'\n"
#printf "acc_EXSPmIY='n=MEM[sp];m=MEM[sp+1];((MEM[sp]=Y,MEM[sp+1]=y,Y=n,y=m));'\n"

printf "acc_EXSPm$RP='((n=MEM[sp],m=MEM[sp+1],MEM[sp]=$rl,MEM[sp+1]=$rh,$rl=n,$rh=m));'\n"

done

printf "# Rotate instructions - m is bit that moves to carry - timing checked\n"
#SETF="setfROTa 0 \$m \$a"
SETF="$acc_setfROTa"
printf "acc_RLA='((m=a>>7,a=((a<<1)|(f&FC))&255));u=$FC;$SETF;'\n"
printf "acc_RRA='((m=a&FC,a=((a>>1)|(f<<7))&255));u=$FC;$SETF;'\n"
printf "acc_RLCA='((m=a>>7,a=((a<<1)|(a>>7))&255));$SETF;'\n"
printf "acc_RRCA='((m=a&FC,a=((a>>1)|(a<<7))&255));$SETF;'\n"

printf "# 16 bit register instructions - timing checked\n"
for rp in bc de hl af xX yY;do
rh="${rp::1}"
rl="${rp:1}"
RP="${RPN[$rp]}"
RR="rr=($rh<<8)|$rl"
eval "INCrp=\$INC$rp;DECrp=\$DEC$rp"
SETrpnn="$rh=nn>>8,$rl=nn&255"

printf "acc_INC$RP='(($INCrp));'\n"
printf "acc_DEC$RP='(($DECrp));'\n"
#printf "acc_LD${RP}nn='rm;(( $rl=n, $rh=m ));'\n"
printf "acc_LD${RP}nn=''\n"
#printf "acc_LD${RP}mm='rb2 \$mm;(( $rl=n, $rh=m ));'\n"
if $_FAST;then
printf "acc_LDmm$RP='((rr));memprotw \$mm \$rr;MEM[mm]=$rl;MEM[mm+1]=$rh;'\n"
printf "acc_LD${RP}mm='memread \$mm;$rl=MEM[mm];$rh=MEM[mm+1];'\n"
#printf "acc_PUSH$RP='pushb \$$rh;pushb \$$rl;'\n"
printf "acc_PUSH$RP='MEM[--sp]=$rh;MEM[--sp]=$rl;'\n"
else
#printf "acc_LDmm$RP='wb2 \$mm \$$rl \$$rh;'\n"
printf "acc_LDmm$RP='((rr));memprotw \$mm \$rr;MEM[mm]=$rl;((MEM[(mm+1)&65535]=$rh));'\n"
printf "acc_LD${RP}mm='memread \$mm;$rl=MEM[mm];(($rh=MEM[(mm+1)&65535]));'\n"
printf "acc_PUSH$RP='MEM[sp]=$rh;(($DECSP));MEM[sp]=$rl;(($DECSP));'\n"
fi

#printf "acc_POP$RP='popmn;$rl=n;$rh=m;'\n"
printf "acc_POP$RP='$rl=$pop;$rh=$pop;'\n"

for rp2 in hl xX yY;do
rh2="${rp2::1}"
rl2="${rp2:1}"
RP2="${RPN[$rp2]}"
RR2="rr2=($rh2<<8)|$rl2"
SETrp2mm="$rh2=mm>>8,$rl2=mm&255"

# printf "acc_ADD$RP2$RP='(($RR2,$RR,nn=(rr2+rr) &65535,$SETrp2nn));setfADD16 \$rr2 \$rr \$nn;'\n"
# printf "acc_ADC$RP2$RP='(($RR2,$RR,nn=(rr2+rr+(f&FC))&65535,$SETrp2nn));setfADC16 \$rr2 \$rr \$nn;'\n"
# printf "acc_SBC$RP2$RP='(($RR2,$RR,nn=(rr2-rr-(f&FC))&65535,$SETrp2nn));setfSBC16 \$rr2 \$rr \$nn;'\n"
if [[ $rp == $rp2 ]];then # special cases
printf "acc_ADD$RP2$RP='(($RR,mm=(rr+rr) &65535,$SETrp2mm));$acc_setfADD1622;'\n"
printf "acc_ADC$RP2$RP='(($RR,mm=(rr+rr+(f&FC))&65535,$SETrp2mm));u=$FC;$acc_setfADC1622;'\n"
printf "acc_SBC$RP$RP='(($RR,mm=(0-(f&FC))&65535,$SETrp2mm));u=$FC;$acc_setfSBC1622;'\n"
else
printf "acc_ADD$RP2$RP='(($RR2,$RR,mm=(rr2+rr) &65535,$SETrp2mm));$acc_setfADD162;'\n"
printf "acc_ADC$RP2$RP='(($RR2,$RR,mm=(rr2+rr+(f&FC))&65535,$SETrp2mm));u=$FC;$acc_setfADC162;'\n"
printf "acc_SBC$RP2$RP='(($RR2,$RR,mm=(rr2-rr-(f&FC))&65535,$SETrp2mm));u=$FC;$acc_setfSBC162;'\n"
fi
#printf "acc_ADD$RP2$RP='(( $rl2+=$rl, m=$rh2+$rh, $rl2>255?(m+=1,$rl2-=256):0 ));setfADD \$$rh2 \$$rh \$m;(( $rh2=m&255 ));'\n"
done
done

# special cases for PUSH AF and POP AF
# PUSH AF uses all flags (u=ff)
# POP AF sets all flags (k=ff)
if $_FAST;then
printf "acc_PUSHAF2='MEM[--sp]=a;MEM[--sp]=f;u=0xff;'\n"
else
printf "acc_PUSHAF2='MEM[sp]=a;(($DECSP));MEM[sp]=f;(($DECSP));u=0xff;'\n"
fi
printf "acc_POPAF2='f=$pop;a=$pop;k=0xff;'\n"

printf "# SP instructions - timing checked\n"
printf "acc_LDSPnn='sp=nn;'\n"
#printf "acc_LDmmSP='ww \$mm \$sp;'\n"
printf "acc_LDmmSP='memprotw \$mm \$sp;((MEM[mm]=sp&255,MEM[mm+1]=(sp>>8)));'\n"
#printf "acc_LDSPmm='rw \$mm;sp=nn;'\n"
printf "acc_LDSPmm='memread \$mm;((sp=MEM[mm]+(MEM[mm+1]<<8)));'\n"
printf "acc_INCSP='(($INCSP));'\n"
printf "acc_DECSP='(($DECSP));'\n"

printf "acc_EXAFAF='n=a;a=a1;a1=n;n=f;f=f1;f1=n;u=0xff;'\n"
# printf "acc_EXX='for g in b c d e h l;do eval \"((n=\$g,\$g=\${g}1,\${g}1=n))\";done;'\n"
DF=
for g in b c d e h l;do
DF+="n=$g,$g=${g}1,${g}1=n,"
done
printf "acc_EXX='((${DF:: -1}));'\n"

printf "# RST instructions - flags, timing checked\n"
for p in '00' '08' 10 18 20 28 30 38;do
printf "acc_RST$p='pushw \$pc;pc=0x00$p;'\n"
done

# printf \"a=[%%02x] _K=[%%s] _diff=[%%02x]\n\" \$a \"\$_K\" \$_diff
printf "acc_DAA='
local -i _diff _fc _fh _hc _lo _hi;
(( _lo=a&15, _hi=a>>4, _diff=(_lo<=9) ? (a<=0x99 ? 0 : 0x60) : (a<=0x8f ? 6 : 0x66) ));
(( _diff|=f&FC ? 0x60 : 0, _diff|=f&FH ? 0x06 : 0 ));
(( _fc=(f&FC) ? FC : (a<=0x99 ? 0 : FC) ));
(( _fh=(f&FN) ? (f&FH?(_lo<=5 ? FH : 0) : 0) : (_lo>=10 ? FH : 0) ));
(( _hc=_fc|_fh ));
(( a=(a+(f&FN ? (-_diff) : _diff))&255 ));setfDAA 0 \$_hc \$a;u=$((FH+FN+FC));
'\n"

} >> $GEN

