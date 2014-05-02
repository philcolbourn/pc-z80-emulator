#!/bin/bash

# Z-80 Instruction Set
    
$_VERBOSE && printf "MAKE INSTRUCTION SET TABLES...\n"

# Main IS

declare -a IS=(
    [0x00]=NOP      LDBCnn   LDBCmA   INCBC    INCr_b   DECr_b   LDrn_b   RLCA     EXAFAF   ADDHLBC  LDABCm   DECBC    INCr_c   DECr_c   LDrn_c   RRCA 
    [0x10]=DJNZn    LDDEnn   LDDEmA   INCDE    INCr_d   DECr_d   LDrn_d   RLA      JRn      ADDHLDE  LDADEm   DECDE    INCr_e   DECr_e   LDrn_e   RRA 
    [0x20]=JRNZn    LDHLnn   LDmmHL   INCHL    INCr_h   DECr_h   LDrn_h   DAA      JRZn     ADDHLHL  LDHLmm   DECHL    INCr_l   DECr_l   LDrn_l   CPL 
    [0x30]=JRNCn    LDSPnn   LDmmA    INCSP    INCHLm   DECHLm   LDHLmn   SCF      JRCn     ADDHLSP  LDAmm    DECSP    INCr_a   DECr_a   LDrn_a   CCF 
    [0x40]=LDrr_bb  LDrr_bc  LDrr_bd  LDrr_be  LDrr_bh  LDrr_bl  LDrHLm_b LDrr_ba  LDrr_cb  LDrr_cc  LDrr_cd  LDrr_ce  LDrr_ch  LDrr_cl  LDrHLm_c LDrr_ca 
    [0x50]=LDrr_db  LDrr_dc  LDrr_dd  LDrr_de  LDrr_dh  LDrr_dl  LDrHLm_d LDrr_da  LDrr_eb  LDrr_ec  LDrr_ed  LDrr_ee  LDrr_eh  LDrr_el  LDrHLm_e LDrr_ea 
    [0x60]=LDrr_hb  LDrr_hc  LDrr_hd  LDrr_he  LDrr_hh  LDrr_hl  LDrHLm_h LDrr_ha  LDrr_lb  LDrr_lc  LDrr_ld  LDrr_le  LDrr_lh  LDrr_ll  LDrHLm_l LDrr_la 
    [0x70]=LDHLmr_b LDHLmr_c LDHLmr_d LDHLmr_e LDHLmr_h LDHLmr_l HALT     LDHLmr_a LDrr_ab  LDrr_ac  LDrr_ad  LDrr_ae  LDrr_ah  LDrr_al  LDrHLm_a LDrr_aa 
    [0x80]=ADDr_b   ADDr_c   ADDr_d   ADDr_e   ADDr_h   ADDr_l   ADDHLm   ADDr_a   ADCr_b   ADCr_c   ADCr_d   ADCr_e   ADCr_h   ADCr_l   ADCHLm   ADCr_a 
    [0x90]=SUBr_b   SUBr_c   SUBr_d   SUBr_e   SUBr_h   SUBr_l   SUBHLm   SUBr_a   SBCr_b   SBCr_c   SBCr_d   SBCr_e   SBCr_h   SBCr_l   SBCHLm   SBCr_a 
    [0xA0]=ANDr_b   ANDr_c   ANDr_d   ANDr_e   ANDr_h   ANDr_l   ANDHLm   ANDr_a   XORr_b   XORr_c   XORr_d   XORr_e   XORr_h   XORr_l   XORHLm   XORr_a 
    [0xB0]=ORr_b    ORr_c    ORr_d    ORr_e    ORr_h    ORr_l    ORHLm    ORr_a    CPr_b    CPr_c    CPr_d    CPr_e    CPr_h    CPr_l    CPHLm    CPr_a 
    [0xC0]=RETNZ    POPBC    JPNZnn   JPnn     CALLNZnn PUSHBC   ADDn     RST00    RETZ     RET      JPZnn    MAPcb    CALLZnn  CALLnn   ADCn     RST08 
    [0xD0]=RETNC    POPDE    JPNCnn   OUTnA    CALLNCnn PUSHDE   SUBn     RST10    RETC     EXX      JPCnn    INAn     CALLCnn  MAPdd    SBCn     RST18 
    [0xE0]=RETPO    POPHL    JPPOnn   EXSPmHL  CALLPOnn PUSHHL   ANDn     RST20    RETPE    JPHL     JPPEnn   EXDEHL   CALLPEnn MAPed    XORn     RST28
    [0xF0]=RETP     POPAF2   JPPnn    DI       CALLPnn  PUSHAF2  ORn      RST30    RETM     LDSPHL   JPMnn    EI       CALLMnn  MAPfd    CPn      RST38
# private emulator op codes
   [0x100]=STOP
)

# make DD and FD instruction sets from main set

declare -a DD FD DDCB FDCB

makeDDFD() {
    local _ix _iy _is; local -i _j
    $_VERBOSE && printf "MAKE DD and FD PREFIX TABLES...\n"
    $_VERBOSE && printf "%3s (%3s) %8s -> %8s, %-8s\n" HEX DEC IS DD FD
    for (( _j=0 ; _j<256 ; _j++ )); do
        _is=${IS[_j]}
        case $_is in
             EXDEHL) ;;
                EXX) ;;
            *HLmr_?) _ix=${_is/HLm/IXm};             _iy=${_is/HLm/IYm};;
            *rHLm_?) _ix=${_is/HLm/IXm};             _iy=${_is/HLm/IYm};;
              *HLm*) _ix=${_is/HLm/IXm};             _iy=${_is/HLm/IYm};;
               *HL*) _ix=${_is//HL/IX};              _iy=${_is//HL/IY};;
               *r_*) _ix=${_is/h/x}; _ix=${_ix/l/X}; _iy=${_is/h/y}; _iy=${_iy/l/Y};;
              *rn_*) _ix=${_is/h/x}; _ix=${_ix/l/X}; _iy=${_is/h/y}; _iy=${_iy/l/Y};;
                *cb) _ix=${_is/cb/ddcb};             _iy=${_is/cb/fdcb};;
                  *) _ix=$_is;                       _iy=$_is;;
        esac
        DD[_j]=$_ix; FD[_j]=$_iy
        $_VERBOSE && printf " %2x (%3d) %8s -> %8s, %-8s\n" $_j $_j $_is $_ix $_iy
    done
    return 0
}

makeDDFD

# CB instruction set

declare -a CB=(
    [0x00]=RLCr_b   RLCr_c   RLCr_d   RLCr_e   RLCr_h   RLCr_l   RLCHLm   RLCr_a   RRCr_b   RRCr_c   RRCr_d   RRCr_e   RRCr_h   RRCr_l   RRCHLm   RRCr_a 
    [0x10]=RLr_b    RLr_c    RLr_d    RLr_e    RLr_h    RLr_l    RLHLm    RLr_a    RRr_b    RRr_c    RRr_d    RRr_e    RRr_h    RRr_l    RRHLm    RRr_a 
    [0x20]=SLAr_b   SLAr_c   SLAr_d   SLAr_e   SLAr_h   SLAr_l   SLAHLm   SLAr_a   SRAr_b   SRAr_c   SRAr_d   SRAr_e   SRAr_h   SRAr_l   SRAHLm   SRAr_a 
    [0x30]=SLLr_b   SLLr_c   SLLr_d   SLLr_e   SLLr_h   SLLr_l   SLLHLm   SLLr_a   SRLr_b   SRLr_c   SRLr_d   SRLr_e   SRLr_h   SRLr_l   SRLHLm   SRLr_a 
    [0x40]=BIT0b    BIT0c    BIT0d    BIT0e    BIT0h    BIT0l    BIT0HLm  BIT0a    BIT1b    BIT1c    BIT1d    BIT1e    BIT1h    BIT1l    BIT1HLm  BIT1a 
    [0x50]=BIT2b    BIT2c    BIT2d    BIT2e    BIT2h    BIT2l    BIT2HLm  BIT2a    BIT3b    BIT3c    BIT3d    BIT3e    BIT3h    BIT3l    BIT3HLm  BIT3a 
    [0x60]=BIT4b    BIT4c    BIT4d    BIT4e    BIT4h    BIT4l    BIT4HLm  BIT4a    BIT5b    BIT5c    BIT5d    BIT5e    BIT5h    BIT5l    BIT5HLm  BIT5a 
    [0x70]=BIT6b    BIT6c    BIT6d    BIT6e    BIT6h    BIT6l    BIT6HLm  BIT6a    BIT7b    BIT7c    BIT7d    BIT7e    BIT7h    BIT7l    BIT7HLm  BIT7a 
    [0x80]=RES0b    RES0c    RES0d    RES0e    RES0h    RES0l    RES0HLm  RES0a    RES1b    RES1c    RES1d    RES1e    RES1h    RES1l    RES1HLm  RES1a 
    [0x90]=RES2b    RES2c    RES2d    RES2e    RES2h    RES2l    RES2HLm  RES2a    RES3b    RES3c    RES3d    RES3e    RES3h    RES3l    RES3HLm  RES3a 
    [0xA0]=RES4b    RES4c    RES4d    RES4e    RES4h    RES4l    RES4HLm  RES4a    RES5b    RES5c    RES5d    RES5e    RES5h    RES5l    RES5HLm  RES5a 
    [0xB0]=RES6b    RES6c    RES6d    RES6e    RES6h    RES6l    RES6HLm  RES6a    RES7b    RES7c    RES7d    RES7e    RES7h    RES7l    RES7HLm  RES7a 
    [0xC0]=SET0b    SET0c    SET0d    SET0e    SET0h    SET0l    SET0HLm  SET0a    SET1b    SET1c    SET1d    SET1e    SET1h    SET1l    SET1HLm  SET1a 
    [0xD0]=SET2b    SET2c    SET2d    SET2e    SET2h    SET2l    SET2HLm  SET2a    SET3b    SET3c    SET3d    SET3e    SET3h    SET3l    SET3HLm  SET3a 
    [0xE0]=SET4b    SET4c    SET4d    SET4e    SET4h    SET4l    SET4HLm  SET4a    SET5b    SET5c    SET5d    SET5e    SET5h    SET5l    SET5HLm  SET5a 
    [0xF0]=SET6b    SET6c    SET6d    SET6e    SET6h    SET6l    SET6HLm  SET6a    SET7b    SET7c    SET7d    SET7e    SET7h    SET7l    SET7HLm  SET7a 
)

# make DDCB and FDCB instruction sets from CB

# FIXME: just handle documented instructions for now

makeDDFDCB() {
    local _ix _iy _cb; local -i _j
    $_VERBOSE && printf "MAKE DDCB and FDCB PREFIX TABLES...\n"
    $_VERBOSE && printf "%3s (%3s) %8s -> %8s, %-8s\n" HEX DEC CB DDCB, FDCB
    for (( _j=0 ; _j<256 ; _j++ )); do
        _cb=${CB[_j]}
        case $_cb in
               *HLm) _ix=${_cb/HLm/IXm};  _iy=${_cb/HLm/IYm};;
               *r_*) _ix=${_cb/r_/IXmr_}; _iy=${_cb/r_/IYmr_};;
                  *) _ix=XX;              _iy=XX;;
        esac
        DDCB[_j]=$_ix; FDCB[_j]=$_iy
        $_VERBOSE && printf " %02x (%3d) %8s -> %8s, %-8s\n" $_j $_j $_cb $_ix $_iy
    done
    return 0
}

makeDDFDCB

# ED instruction set

declare -a ED=(
    [0x00]=XX      XX        XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX     
    [0x10]=XX      XX        XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX     
    [0x20]=XX      XX        XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX     
    [0x30]=XX      XX        XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX     
    [0x40]=INBC    OUTCB     SBCHLBC  LDmmBC   NEG      RETN     IM0      LDIA     INCC     OUTCC    ADCHLBC  LDBCmm   NEG      RETI     IM01     LDRA
    [0x50]=INDC    OUTCD     SBCHLDE  LDmmDE   NEG      RETN     IM1      LDAI     INEC     OUTCE    ADCHLDE  LDDEmm   NEG      RETN     IM2      LDAR
    [0x60]=INHC    OUTCH     SBCHLHL  LDmmHL   NEG      RETN     IM0      RRD      INLC     OUTCL    ADCHLHL  LDHLmm   NEG      RETN     IM01     RLD
    [0x70]=INFC    OUTC0     SBCHLSP  LDmmSP   NEG      RETN     IM1      XX       INAC     OUTCA    ADCHLSP  LDSPmm   NEG      RETN     IM2      XX  
    [0x80]=XX      XX        XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX     
    [0x90]=XX      XX        XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX     
    [0xA0]=LDI     CPI       INI      OUTI     XX       XX       XX       XX       LDD      CPD      IND      OUTD     XX       XX       XX       XX  
    [0xB0]=LDIR    CPIR      INIR     OTIR     XX       XX       XX       XX       LDDR     CPDR     INDR     OTDR     XX       XX       XX       XX  
    [0xC0]=XX      XX        XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX     
    [0xD0]=XX      XX        XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX     
    [0xE0]=XX      XX        XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX     
    [0xF0]=XX      XX        XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX       XX     
)

