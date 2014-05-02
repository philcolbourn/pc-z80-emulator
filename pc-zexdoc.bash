#!/bin/bash

declare -i counter counter_end shifter shifter_end flag_mask
declare -i test_data

pause() { printf "b=%02x\n" $b; sleep 1; }
stop() { printf "b=%02x\n" $b; _GO=false; }

#setup() {
#    printf "HL=%04x (%02x) -> DE=%04x  B=%02x\n" $(( (h<<8)|l )) ${MEM[(h<<8)|l]} $(( (d<<8)|e )) $b
#    #sleep 0.5
#}

test_loop() {
    printf "TEST: HL=[%04x]\n" $(( (h<<8)|l ))
    #sleep 1
}

# requires address in $1
dump20() {
    local -i _a=$1 _j _c; local _ascii
    printf "\n"
    for (( _j=-(_a&15)-0x10; _j<0x20-(_a&15); _j++ )); do
        #(( ((_a+_j)&15)==0 )) && printf "%04x  " $(( _a+_j ))
        (( _c=MEM[(_a+_j)&65535] )) 
        case $(( (_a+_j)&15 )) in
            0) printf "\x1b[34m%04x\x1b[m  " $(( _a+_j ));;     # print address
        esac
        (( _j>=0 && _j<2 )) && { printf "\x1b[41m"; _ascii+="\x1b[41m"; }
        printf "%02x" $_c
        _ascii+="${CHR[_c]}"                     # make ASCII string 
        (( _j>=0 && _j<2 )) && { printf "\x1b[m"; _ascii+="\x1b[m"; }
        case $(( (_a+_j)&15 )) in
            7) printf "|"; _ascii+="|";;         # divide hex and ASCII displays into groups
           15) printf "  [%b]\n" "$_ascii"      # at byte 15, display ASCII version 
               _ascii="";;
            *) printf " ";;
        esac
    done
    #printf "\x1b[m"
    #sleep 1
    return 0
}

#dumpCounterShifter() {
#    local -i _j _inst _tj=0x1cda; local _char
#    printf "%s\n" "${MEM_NAME[_tj]}"
#    for (( _j=0; _j<80; _j++ )); do
#        (( (_j&7)==0 )) && printf "%04x:  " $(( _tj+_j ))
#        _inst=${MEM[_tj+_j]:-255}
#        _char="${CHR[$_inst]}"
#        printf "%02x[%b]  " $_inst "$_char"
#        (( (_j&7)==7 )) && printf "\n"
#    done
#    printf "\n"
#    #sleep 0.5
#    #exit 0
#}

start_ss() { _SS=true; _DIS=true; }

#Select test:
#   '//1) adc16     'xX/13) daaop     '//25) incl       '//37) ld165      '//49) ld8ixy       'xXX/61) rotz80(rr,sla,sra,slar_b)
#   '//2) add16     '//14) inca     '//26) incm       '//38) ld166      /'x//50) ld8rr	       '/X/62) srz80(res0b)
#   '//3) add16x    '//15) incb      '//27) incsp      '//39) ld167      '//51) ld8rrx       '//63) srzx
#   '//4) add16y    '//16) incbc     '/xXX/28) incx       '//40) ld168      '//52) lda	       '//64) st8ix1
#   xX/5) alu8i     '//17) incc	     '//29) incxh      '//41) ld16im     '//53) ldd1(LDD*)   '//65) st8ix2
#   x/6) alu8r     '//18) incd	     '//30) incxl      '//42) ld16ix     '//54) ldd2(LDD*)   '//66) st8ix3
#   x/7) alu8rx    '//19) incde      '//31) incyh      '//43) ld8bd      '//55) ldi1(LDI*)   '//67) stabd
#   x/8) alu8x     '//20) ince	     '//32) incyl      '//44) ld8im      '//56) ldi2
#   'x//9) bitx      '//21) inch	     '//33) ld161      '//45) ld8imx     '///57) negop
#  'x/X/10) bitz80    '//22) inchl     '//34) ld162      '//46) ld8ix1     /'xXX/58) rldop
#  'xX/11) cpd1      '//23) incix     '//35) ld163      '//47) ld8ix2     '//59) rot8080
#  'X/12) cpi1      '//24) inciy     '//36) ld164      '/x//48) ld8ix3     /'xXX/60) rotxy

# grep -A1 -P "^;.*\([0-9,]+ cycles\)" ~/Development/pc-z80/CPM/zexdoc.src

#; <adc,sbc> hl,<bc,de,hl,sp> (38,912 cycles)    adc16:	db	0c7h		; flag mask
#; add hl,<bc,de,hl,sp> (19,456 cycles)          add16:	db	0c7h		; flag mask
#; add ix,<bc,de,ix,sp> (19,456 cycles)          add16x:	db	0c7h		; flag mask
#; add iy,<bc,de,iy,sp> (19,456 cycles)          add16y:	db	0c7h		; flag mask
#; aluop a,nn (28,672 cycles)                    alu8i:	db	0d7h		; flag mask
#; aluop a,<b,c,d,e,h,l,(hl),a> (753,664 cycles) alu8r:	db	0d7h		; flag mask 770048
#; aluop a,<ixh,ixl,iyh,iyl> (376,832 cycles)    alu8rx:	db	0d7h		; flag mask
#; aluop a,(<ix,iy>+1) (229,376 cycles)          alu8x:	db	0d7h		; flag mask
#; bit n,(<ix,iy>+1) (2048 cycles)               bitx:	db	053h		; flag mask
#; cpd<r> (1) (6144 cycles)                      cpd1:	db	0d7h		; flag mask
#; cpi<r> (1) (6144 cycles)                      cpi1:	db	0d7h		; flag mask
#; <inc,dec> a (3072 cycles)                     inca:	db	0d7h		; flag mask
#; <inc,dec> b (3072 cycles)                     incb:	db	0d7h		; flag mask
#; <inc,dec> bc (1536 cycles)                    incbc:	db	0d7h		; flag mask
#; <inc,dec> c (3072 cycles)                     incc:	db	0d7h		; flag mask
#; <inc,dec> d (3072 cycles)                     incd:	db	0d7h		; flag mask
#; <inc,dec> de (1536 cycles)                    incde:	db	0d7h		; flag mask
#; <inc,dec> e (3072 cycles)                     ince:	db	0d7h		; flag mask
#; <inc,dec> h (3072 cycles)                     inch:	db	0d7h		; flag mask
#; <inc,dec> hl (1536 cycles)                    inchl:	db	0d7h		; flag mask
#; <inc,dec> ix (1536 cycles)                    incix:	db	0d7h		; flag mask
#; <inc,dec> iy (1536 cycles)                    inciy:	db	0d7h		; flag mask
#; <inc,dec> l (3072 cycles)                     incl:	db	0d7h		; flag mask
#; <inc,dec> (hl) (3072 cycles)                  incm:	db	0d7h		; flag mask
#; <inc,dec> sp (1536 cycles)                    incsp:	db	0d7h		; flag mask
#; <inc,dec> (<ix,iy>+1) (6144 cycles)           incx:	db	0d7h		; flag mask
#; <inc,dec> ixh (3072 cycles)                   incxh:	db	0d7h		; flag mask
#; <inc,dec> ixl (3072 cycles)                   incxl:	db	0d7h		; flag mask
#; <inc,dec> iyh (3072 cycles)                   incyh:	db	0d7h		; flag mask
#; <inc,dec> iyl (3072 cycles)                   incyl:	db	0d7h		; flag mask
#; ld <bc,de>,(nnnn) (32 cycles)                 ld161:	db	0d7h		; flag mask
#; ld hl,(nnnn) (16 cycles)                      ld162:	db	0d7h		; flag mask
#; ld sp,(nnnn) (16 cycles)                      ld163:	db	0d7h		; flag mask
#; ld <ix,iy>,(nnnn) (32 cycles)                 ld164:	db	0d7h		; flag mask
#; ld (nnnn),<bc,de> (64 cycles)                 ld165:	db	0d7h		; flag mask
#; ld (nnnn),hl (16 cycles)                      ld166:	db	0d7h		; flag mask
#; ld (nnnn),sp (16 cycles)                      ld167:	db	0d7h		; flag mask
#; ld (nnnn),<ix,iy> (64 cycles)                 ld168:	db	0d7h		; flag mask
#; ld <bc,de,hl,sp>,nnnn (64 cycles)             ld16im:	db	0d7h		; flag mask
#; ld <ix,iy>,nnnn (32 cycles)                   ld16ix:	db	0d7h		; flag mask
#; ld a,<(bc),(de)> (44 cycles)                  ld8bd:	db	0d7h		; flag mask
#; ld <b,c,d,e,h,l,(hl),a>,nn (64 cycles)        ld8im:	db	0d7h		; flag mask
#; ld (<ix,iy>+1),nn (32 cycles)                 ld8imx:	db	0d7h		; flag mask
#; ld <b,c,d,e>,(<ix,iy>+1) (512 cycles)         ld8ix1:	db	0d7h		; flag mask
#; ld <h,l>,(<ix,iy>+1) (256 cycles)             ld8ix2:	db	0d7h		; flag mask
#; ld a,(<ix,iy>+1) (128 cycles)                 ld8ix3:	db	0d7h		; flag mask
#; ld <ixh,ixl,iyh,iyl>,nn (32 cycles)           ld8ixy:	db	0d7h		; flag mask
#; ld <b,c,d,e,h,l,a>,<b,c,d,e,h,l,a> (3456 cycles) ld8rr:	db	0d7h		; flag mask
#; ld <b,c,d,e,ixy,a>,<b,c,d,e,ixy,a> (6912 cycles) ld8rrx:	db	0d7h		; flag mask
#; ld a,(nnnn) / ld (nnnn),a (44 cycles)         lda:	db	0d7h		; flag mask
#; ldd<r> (1) (44 cycles)                        ldd1:	db	0d7h		; flag mask
#; ldd<r> (2) (44 cycles)                        ldd2:	db	0d7h		; flag mask
#; ldi<r> (1) (44 cycles)                        ldi1:	db	0d7h		; flag mask
#; ldi<r> (2) (44 cycles)                        ldi2:	db	0d7h		; flag mask
#; <rld,rrd> (7168 cycles)                       rldop:	db	0d7h		; flag mask
#; <rlca,rrca,rla,rra> (6144 cycles)             rot8080: db	0d7h		; flag mask
#; shift/rotate (<ix,iy>+1) (416 cycles)         rotxy:	db	0d7h		; flag mask
#; shift/rotate <b,c,d,e,h,l,(hl),a> (6784 cycles) rotz80:	db	0d7h		; flag mask
#; <set,res> n,<b,c,d,e,h,l,(hl),a> (7936 cycles) srz80:	db	0d7h		; flag mask
#; <set,res> n,(<ix,iy>+1) (1792 cycles)         srzx:	db	0d7h		; flag mask
#; ld (<ix,iy>+1),<b,c,d,e> (1024 cycles)        st8ix1:	db	0d7h		; flag mask
#; ld (<ix,iy>+1),<h,l> (256 cycles)             st8ix2:	db	0d7h		; flag mask
#; ld (<ix,iy>+1),a (64 cycles)                  st8ix3:	db	0d7h		; flag mask
#; ld (<bc,de>),a (96 cycles)                    stabd:	db	0d7h		; flag mask

decode_from_here() {
    #state_note $FUNCNAME
    pushw 0xdead                                 # fake ret address to exit from sub-emulator
    pc=$1                                        # set pc to z-80 function to call
    decode                                       # emulate from pc
    _GO=true
    return 0
}

# This address was on stack and a ret op was executed.
# A NOP will be read and executed and then decode loop will exit and decode will return 0
dead_E() {
    #state_note $FUNCNAME
    MEM[pc]=0  # force a NOP - not really required as initiated memory returns 0
    _GO=false
    return 0
}

jump(){
    local -i _new_pc=$1
    pc=_new_pc
    #state_note $FUNCNAME
    return 0
}

ret(){
    #popnn; pc=nn
    poppc
    #state_note $FUNCNAME
    return 0
}

setupMMgr 0xdead          "DEAD STOP"    RO dead_E  # special function to force emulator to return to bash

setupMMgr 0x002c-0x00ff   "Test pointer"
setupMMgr 0x0102          "test45"       RW
setupMMgr 0x0103-0x0110   "msbt"         RW # dump20
setupMMgr 0x0111-0x0112   "spbt"         RW
setupMMgr 0x0113          "start"
setupMMgr 0x0122          "start - loop"
setupMMgr 0x012f          "start - done"
setupMMgr 0x013a-0x01c1   "tests"
setupMMgr 0x0148          "test9RLC IY"
setupMMgr 0x01c2-0x1ae1   "INST-DATA"
setupMMgr 0x01c2          "TEST 1"
setupMMgr 0x0222          "TEST 2"
setupMMgr 0x0282          "TEST 3"
setupMMgr 0x02e2          "TEST 4"
setupMMgr 0x0339          "test44"       RW # test 44 writes here
setupMMgr 0x0342          "TEST 5"
setupMMgr 0x03a2          "TEST 6"
setupMMgr 0x0402          "TEST 7"
setupMMgr 0x0462          "TEST 8"
setupMMgr 0x04c2          "TEST 9"
setupMMgr 0x0522          "TEST 10"
setupMMgr 0x0582          "TEST 11"
setupMMgr 0x05e2          "TEST 12"
setupMMgr 0x0642          "TEST 13"
setupMMgr 0x06a2          "TEST 14"
setupMMgr 0x0702          "TEST 15"
setupMMgr 0x0762          "TEST 16"
setupMMgr 0x07c2          "TEST 17"
setupMMgr 0x0822          "TEST 18"
setupMMgr 0x0882          "TEST 19"
setupMMgr 0x08e2          "TEST 20"
setupMMgr 0x0942          "TEST 21"
setupMMgr 0x09a2          "TEST 22"
setupMMgr 0x0a02          "TEST 23"
setupMMgr 0x0a62          "TEST 24"
setupMMgr 0x0ac2          "TEST 25"
setupMMgr 0x0b22          "TEST 26"
setupMMgr 0x0b82          "TEST 27"
setupMMgr 0x0be2          "TEST 28"
setupMMgr 0x0c42          "TEST 29"
setupMMgr 0x0ca2          "TEST 30"
setupMMgr 0x0d02          "TEST 31"
setupMMgr 0x0d62          "TEST 32"
setupMMgr 0x0dc2          "TEST 33"
setupMMgr 0x0e22          "TEST 34"
setupMMgr 0x0e82          "TEST 35"
setupMMgr 0x0ee2          "TEST 36"
setupMMgr 0x0f42          "TEST 37"
setupMMgr 0x0fa2          "TEST 38"
setupMMgr 0x1002          "TEST 39"
setupMMgr 0x1062          "TEST 40"
setupMMgr 0x10c2          "TEST 41"
setupMMgr 0x1122          "TEST 42"
setupMMgr 0x1182          "TEST 43"
setupMMgr 0x11e2          "TEST 44"
setupMMgr 0x1242          "TEST 45"
setupMMgr 0x12a2          "TEST 46"
setupMMgr 0x1302          "TEST 47"
setupMMgr 0x1362          "TEST 48"
setupMMgr 0x13c2          "TEST 49"
setupMMgr 0x1422          "TEST 50"
setupMMgr 0x1482          "TEST 51"
setupMMgr 0x14e2          "TEST 52"
setupMMgr 0x1542          "TEST 53"
setupMMgr 0x15a2          "TEST 54"
setupMMgr 0x1602          "TEST 55"
setupMMgr 0x1662          "TEST 56"
setupMMgr 0x16c2          "TEST 57"
setupMMgr 0x1722          "TEST 58"
setupMMgr 0x1782          "TEST 59"
setupMMgr 0x17e2          "TEST 60"
setupMMgr 0x1842          "TEST 61"
setupMMgr 0x18a2          "TEST 62"
setupMMgr 0x1902          "TEST 63"
setupMMgr 0x1962          "TEST 64"
setupMMgr 0x19c2          "TEST 65"
setupMMgr 0x1a22          "TEST 66"
setupMMgr 0x1a82          "TEST 67"

setupMMgr 0x0e03-0xe20    "test33msg"    RO

stt_E() {
    #state_note $FUNCNAME
    test_data=h*256+l
    (( flag_mask=MEM[test_data] ))
    printf "test_data=%04x  flag_mask=%02x\n" $test_data $flag_mask
    # instruction base offset 1 size 4
    # state offset=4 size 16
    # incmask offset=21 size 20
    # shiftmask offset = 41 size 20
    # label offset=61 size ?
    # expected crc offset=61 size 4
    return 0
}

setupMMgr 0x1ae2          "stt start test (hl)"            RO   # FIXME: uncomment to enable bash replacement code stt_E

sttbl_E() {
    printf "\n"
}

setupMMgr 0x1b24          "stt before loop - call initcrc" RO sttbl_E # read_counter_E

tlp_E_org() {                                        # tlp: ; test loop
    #state_pause $FUNCNAME
    #$_DEBUG && return 0;
    local -i _b _h=${MEM[sp+1]} _l=${MEM[sp]}    # get hl from (sp)
    while :; do
        a=MEM[0x1d42]                            # tlp: ld a,(iut)
        _b=b; b=0x76; CPr_b; b=_b                # cp 076h
        (( a!=0x76 )) && {                       # ; pragmatically avoid halt intructions
                                                 # jp z,tlp2
            #b=0xdf; ANDr_b; b=_b                 # and a,0dfh
            (( a&=0xdf ))                        # and a,0dfh
            b=0xdd; CPr_b; b=_b                  # cp 0ddh
            if (( a!=0xdd )); then               # cp 0ddh; jp nz,tlp1
                decode_from_here 0x1d2a          # tlp1: call nz,test ; execute the test instruction
            else                                 # see of 2nd op code is halt
                a=MEM[0x1d43]                    # ld a,(iut+1) ; get second op code
                # FIXME: is CP required?
                b=0x76; CPr_b; b=_b              # cp 076h
                (( a!=0x76 )) && {               # not halt so test it    
                    decode_from_here 0x1d2a      # tlp1: call nz,test ; execute the test instruction
                }
            fi
	    }
        # tlp2:	
        pushw 0xdead; count_E                    # call count ; increment the counter
        (( (f&FZ)==0 )) && { pushw 0xdead; shift_E; }  # call nz,shift ; shift the scan bit
        #POPHL                                    # pop hl ; pointer to test case
        h=_h; l=_l                               # restore hl after setup kills it
        (( (f&FZ)==0 )) && { popnn; break; }      # jp z,tlp3 ; done if shift returned NZ - popn needed since no POPHL
        #tlp3:
        #PUSHHL                                   # push hl - not popped so not pushed
        (( a=MEM[0x1bf0]=MEM[0x1c14]=1 ))        # ld a,1; ld (cntbit),a; ld (shfbit),a
        MEM[0x1bf1]=0xda; MEM[0x1bf2]=0x1c       # ld hl,counter; ld (cntbyt),hl
        MEM[0x1c15]=0x02; MEM[0x1c16]=0x1d       # ld hl,shifter; ld (shfbyt),hl
        b=4                                      # ld b,4 ; bytes in iut field
        #POPHL                                    # pop hl ; pointer to test case - hl not changed
        #PUSHHL                                   # push hl
        d=0x1d; e=0x42                           # ld de,iut
        #decode_from_here 0x1ba4                  # call setup ; setup iut     
        pushw 0xdead; setup_E
        b=16                                     # ld b,16 ; bytes in machine state
        d=0x01; e=0x03                           # ld de,msbt
        #decode_from_here 0x1ba4                  # call setup ; setup iut     
        pushw 0xdead; setup_E
    done
    jump $(( 0x1b3e+10 ))                        # resume ld de,20+20+20
    #printf "\nTest cycle: %d -> %d cycles/h\n" $iut_count $(( iut_count*3600/SECONDS ))
    return 0
}

tlp_E() {                                        # tlp: ; test loop
    local -i _b _h=${MEM[sp+1]} _l=${MEM[sp]}    # get hl from (sp)
    while :; do
        a=MEM[0x1d42]                            # tlp: ld a,(iut)
        _b=b; b=0x76; CPr_b; b=_b                # cp 076h
        (( a!=0x76 )) && {                       # ; pragmatically avoid halt intructions
                                                 # jp z,tlp2
            #b=0xdf; ANDr_b; b=_b                 # and a,0dfh
            (( a&=0xdf ))                        # and a,0dfh
            b=0xdd; CPr_b; b=_b                  # cp 0ddh
            if (( a!=0xdd )); then               # cp 0ddh; jp nz,tlp1
                test_E                           # tlp1: call nz,test ; execute the test instruction
            else                                 # see of 2nd op code is halt
                a=MEM[0x1d43]                    # ld a,(iut+1) ; get second op code
                # FIXME: is CP required?
                b=0x76; CPr_b; b=_b              # cp 076h
                (( a!=0x76 )) && {               # not halt so test it    
                    test_E                       # tlp1: call nz,test ; execute the test instruction
                }
            fi
	    }
        # tlp2:	
        count
        (( (f&FZ)==0 )) && {
            shift2
        }
        h=_h; l=_l                               # restore hl after setup kills it
        (( (f&FZ)==0 )) && { popnn; break; }      # jp z,tlp3 ; done if shift returned NZ - popn needed since no POPHL
        (( a=MEM[0x1bf0]=MEM[0x1c14]=1 ))        # ld a,1; ld (cntbit),a; ld (shfbit),a
        MEM[0x1bf1]=0xda; MEM[0x1bf2]=0x1c       # ld hl,counter; ld (cntbyt),hl
        MEM[0x1c15]=0x02; MEM[0x1c16]=0x1d       # ld hl,shifter; ld (shfbyt),hl
        b=4                                      # ld b,4 ; bytes in iut field
        d=0x1d; e=0x42                           # ld de,iut
        setup
        b=16                                     # ld b,16 ; bytes in machine state
        d=0x01; e=0x03                           # ld de,msbt
        setup
    done
    jump $(( 0x1b3e+10 ))                        # resume ld de,20+20+20
    #(( iut_count%10==0 )) && printf "\nTest cycle: %d -> %d cycles/h\n" $iut_count $(( iut_count*3600/SECONDS ))
    return 0
}

setupMMgr 0x1b27          "tlp - test loop"         RO   # tlp_E # FIXME: uncomment for bash version #4  #test_loop
setupMMgr 0x1b3b          "tlp1 - test instruction" RO #pause

tlp2_E() {
    # not used
    state_note $FUNCNAME
    _GO=false; return 0
    pushw 0xdead; count_E                        # call count ; increment the counter
    (( (f&FZ)==0 )) && { pushw 0xdead; shift_E; }  # call nz,shift ; shift the scan bit
    popmn; l=n; h=m                              # pop hl ; pointer to test case
    (( (f&FZ)>0 )) && { tlp3_E; return 0; }      # jp z,tlp3 ; done if shift returned NZ
    jump $(( 0x1b3e+10 ))                        # resume ld de,20+20+20
    return 0
}

tlp_ldde60_E(){
    state_note $FUNCNAME
}

setupMMgr 0x1b3e          "tlp2 - test loop"        RO #tlp2_E
setupMMgr 0x1b48          "tlp: ld de,20+20+20"     RO #tlp_ldde60_E

tlp3_E() {
    # not used
    state_note $FUNCNAME
    _GO=false; return 0
    local -i _h=h _l=l
    pushb $h; pushb $l                           # push hl
                                                 # initialise count and shift scanners
    a=MEM[0x1c14]=MEM[0x1bf0]=1                  # ld a,1; ld (cntbit),a; ld (shfbit),a
    MEM[0x1bf1]=0xda; MEM[0x1bf2]=0x1c           # ld hl,counter; ld (cntbyt),hl
    MEM[0x1c15]=0x02; MEM[0x1c16]=0x1d           # ld hl,shifter; ld (shfbyt),hl
    b=4                                          # ld b,4 ; bytes in iut field
    h=_h; l=_l                                   # pop hl; push hl; pointer to test case
    d=0x1d; e=0x42                               # ld de,iut
    #decode_from_here 0x1ba4                     # call setup ; setup iut
    pushw 0xdead; setup_E     
    b=16                                         # ld b,16 ; bytes in machine state
    d=0x01; e=0x03                               # ld de,msbt
    #decode_from_here 0x1ba4                     # call setup ; setup iut     
    pushw 0xdead; setup_E
    jump 0x1b27                                  # jp tlp
    return 0
}

setupMMgr 0x1b7a          "tlp3 - test loop"        RO #tlp3_E

declare -i CALL_ASM_COUNT=0

call_asm_E() {
    printf "<$FUNCNAME>"
    (( CALL_ASM_COUNT>0 )) && return             # dont recurse - emulate normally
    CALL_ASM_COUNT+=1
    pushw 0xdead
    decode
    _GO=true
    (( CALL_ASM_COUNT-=1 ))
    ret; return 0
}

# (( l+=1, l==256?(h=(h+1)&255,l=0):0 ))  # inc hl

setup_E_org(){
    #state_note $FUNCNAME
                                                 # setup a field of the test case
                                                 # b  = number of bytes
                                                 # hl = pointer to base case
                                                 # de = destination
    while (( b>0 )); do
        #decode_from_here 0x1bad                  # setup: call subyte - this works
        pushw 0xdead; subyte_E
        (( l+=1, l==256?(h=(h+1)&255,l=0):0, b-- ))  # inc hl; dec b
    done                                         # jp nz,setup
    ret; return 0
}

setup(){
    for (( ; b>0; b-- )); do
        subyte
        (( l+=1, l==256?(h=(h+1)&255,l=0):0 ))   # inc hl; dec b
    done                                         # jp nz,setup
    return 0
}

setupMMgr 0x1ba4          "setup - setup a field of the test case" RO # setup_E #3 # call_asm_E 

subyte_E(){
    #state_note $FUNCNAME
    local -i _hl _de _b=b _c=c _m _a _f
    #pushb $b; pushb $c                           # push bc
    #pushb $d; pushb $e                           # push de - destination
    #pushb $h; pushb $l                           # push hl - base case
    (( _hl=(h<<8)|l, c=MEM[_hl] ))               # ld c,(hl) ; get base byte
    #_de=20                                       # ld de,20
    #_hl+=_de                                     # add hl,de ; point to incmask
    _hl+=20                                      # add hl,de ; point to incmask
    (( a=MEM[_hl] ))                             # ld a,(hl)
	if (( a!=0 )); then                          # cp 0; jp z,subshf
        b=8                                      # ld b,8 ; 8 bits
        while (( b>0 )); do                      # subclp:
            (( _m=a&FC, a=((a>>1)|(a<<7))&255 )); setfROTa 0 $_m $a  # rrca
            _a=a; _f=f                           # push af
            a=0                                  # ld a,0
            (( (f&FC)>0 )) && { pushw 0xdead; nxtcbit_E; }  # call c,nxtcbit ; get next counter bit if mask bit was set
            (( a^=c ))                           # xor c ; flip bit if counter bit was set
            (( _m=a&FC, a=((a>>1)|(a<<7))&255 )); setfROTa 0 $_m $a  # rrca
            c=a                                  # ld c,a
            a=_a; f=_f                           # pop af
            (( b-=1 ))                           # dec b
        done                                     # jp nz,subclp
        # b=8                                     # ld b,8
    fi
#subshf:
    #_de=20                                       # ld de,20
    #_hl+=_de                                     # add hl,de ; point to shift mask
    _hl+=20                                      # add hl,de ; point to shift mask
    (( a=MEM[_hl] ))                             # ld a,(hl)
	if (( a!=0 )); then                          # cp 0; jp z,substr
        b=8                                      # ld b,8 ; 8 bits
        while (( b>0 )); do                      # sbshf1:
            (( _m=a&FC, a=((a>>1)|(a<<7))&255 )); setfROTa 0 $_m $a  # rrca
            _a=a; _f=f                           # push af
            a=0                                  # ld a,0
            (( (f&FC)>0 )) && { pushw 0xdead; nxtsbit_E; }  # call c,nxtsbit ; get next shifter bit if mask bit was set
            (( a^=c ))                           # xor c ; flip bit if shifter bit was set
            (( _m=a&FC, a=((a>>1)|(a<<7))&255 )); setfROTa 0 $_m $a  # rrca
            c=a                                  # ld c,a
            a=_a; f=_f                           # pop af
            (( b-=1 ))                           # dec b
        done                                     # jp nz,sbshf1
#substr:
    fi
    #popmn; l=n; h=m                              # pop hl
    #popmn; e=n; d=m                              # pop de
    a=c                                          # ld a,c
    MEM[(d<<8)|e]=a                              # ld (de),a ; mangled byte to destination
    (( e+=1, e==256?(d=(d+1)&255,e=0):0 ))       # inc de
    b=_b; c=_c                                   # pop bc
    ret; return 0
}

subyte(){
    local -i _hl=h*256+l _b=b _c=c _m _a _f
    (( c=MEM[_hl] ))               # ld c,(hl) ; get base byte
    (( a=MEM[_hl+20] ))                             # ld a,(hl)
	(( a!=0 )) && {                          # cp 0; jp z,subshf
        for (( b=8; b>0; b-- )); do                      # subclp:
            (( _m=a&FC, a=((a>>1)|(a<<7))&255 )); setfROTa 0 $_m $a  # rrca
            _a=a; _f=f                           # push af
            a=0                                  # ld a,0
            (( (f&FC)>0 )) && { pushw 0xdead; nxtcbit_E; }  # call c,nxtcbit ; get next counter bit if mask bit was set
            (( a^=c ))                           # xor c ; flip bit if counter bit was set
            (( _m=a&FC, a=((a>>1)|(a<<7))&255 )); setfROTa 0 $_m $a  # rrca
            c=a                                  # ld c,a
            a=_a; f=_f                           # pop af
        done                                     # jp nz,subclp
    }
#subshf:
    (( a=MEM[_hl+40] ))                             # ld a,(hl)
	(( a!=0 )) && {                          # cp 0; jp z,substr
        for (( b=8; b>0; b-- )); do                      # sbshf1:
            (( _m=a&FC, a=((a>>1)|(a<<7))&255 )); setfROTa 0 $_m $a  # rrca
            _a=a; _f=f                           # push af
            a=0                                  # ld a,0
            (( (f&FC)>0 )) && { pushw 0xdead; nxtsbit_E; }  # call c,nxtsbit ; get next shifter bit if mask bit was set
            (( a^=c ))                           # xor c ; flip bit if shifter bit was set
            (( _m=a&FC, a=((a>>1)|(a<<7))&255 )); setfROTa 0 $_m $a  # rrca
            c=a                                  # ld c,a
            a=_a; f=_f                           # pop af
        done                                     # jp nz,sbshf1
#substr:
    }
    a=c                                          # ld a,c
    MEM[(d<<8)|e]=a                              # ld (de),a ; mangled byte to destination
    (( e+=1, e==256?(d=(d+1)&255,e=0):0 ))       # inc de
    b=_b; c=_c                                   # pop bc
    return 0
}

setupMMgr 0x1bad          "subyte"                                 RO # subyte_E
setupMMgr 0x1bbd          "subyte - subclp - while b>0"            RO 
setupMMgr 0x1bce          "subyte - subshf"
setupMMgr 0x1bda          "subyte - sbshf1 - while b>0"            RO

setupMMgr 0x1be9          "subyte - substr - exit subyte"          RO

setupMMgr 0x1bf0          "cntbit"                                 RW
setupMMgr 0x1bf1-0x1bf2   "cntbyt"                                 RW

nxtcbit_E() {
    #state_note $FUNCNAME
    local -i _b _c=c _hl _hl1
    (( _hl1=MEM[0x1bf1]|(MEM[0x1bf2]<<8) ))      # ld hl,(cntbyt)
    _b=MEM[_hl1]                                 # ld b,(hl)
    _hl=0x1bf0                                   # ld hl,cntbit
    a=MEM[_hl]                                   # ld a,(hl)
    c=a                                          # ld c,a
    (( a=(((a<<1)|(a>>7))&255) ))                # rlca
    MEM[_hl]=a                                   # ld (hl),a
                                                 # cp a,1 
    if (( a==1 )); then                          # jp nz,nsb1
                                                 # ld hl,(cntbyt)
        _hl1+=1                                  # inc hl
        (( MEM[0x1bf1]=_hl1&255, MEM[0x1bf2]=(_hl1>>8) ))  # ld (cntbyt),hl
    fi
    a=_b                                         # nsb1: ld a,b
	(( a&=c )); setfAND $_b $c $a                # and c
	c=_c
	(( a==0 )) && { ret; return 0; }             # ret z
	a=1                                          # ld a,1
	ret; return 0
}

setupMMgr 0x1bf3          "nxtcbit - get next counter bit in low bit of a" RO # nxtcbit_E #2
setupMMgr 0x1c0c          "nxtcbit - ncb1"

setupMMgr 0x1c14          "shfbit"                                         RW
setupMMgr 0x1c15-0x1c16   "shfbyt"                                         RW

nxtsbit_E() {
    #state_note $FUNCNAME
    local -i _b _c=c _hl _hl1
    (( _hl1=MEM[0x1c15]|(MEM[0x1c16]<<8) ))      # ld hl,(shfbyt)
    _b=MEM[_hl1]                                 # ld b,(hl)
    _hl=0x1c14                                   # ld hl,shfbit
    a=MEM[_hl]                                   # ld a,(hl)
    c=a                                          # ld c,a
    (( a=(((a<<1)|(a>>7))&255) ))                # rlca
    MEM[_hl]=a                                   # ld (hl),a
                                                 # cp a,1 
    if (( a==1 )); then                          # jp nz,nsb1
        #_hl=MEM[0x1c15]|(MEM[0x1c16]<<8)         # ld hl,(shfbyt)
        _hl1+=1                                  # inc hl
        (( MEM[0x1c15]=_hl1&255, MEM[0x1c16]=(_hl1>>8) ))  # ld (shfbyt),hl
    fi
    a=_b                                         # nsb1: ld a,b
	(( a&=c )); setfAND $_b $c $a                # and c
	c=_c
	(( a==0 )) && { ret; return 0; }             # ret z
	a=1                                          # ld a,1
	ret; return 0
}

setupMMgr 0x1c17          "nxtsbit - get next shifter bit in low bit of a" RO # nxtsbit_E #1
setupMMgr 0x1c30          "nxtsbit - nsb1"

clrmem_E_org() {
    #state_note $FUNCNAME
    local _hl=h*256+l _bc=b*256+c
    while (( _bc>0 )); do
        (( MEM[_hl++]=0, _bc-- ))
    done
    ret; return 0
}

clrmem_E() {
    local _hl=h*256+l _bc=b*256+c
    for (( ; _bc>0; _bc-- )); do
        (( MEM[_hl++]=0 ))
    done
    ret; return 0
}

setupMMgr 0x1c38          "clrmem - clear memory at hl, bc bytes"     RO # clrmem_E
setupMMgr 0x1c48          "clrmem - check"                            RO # clrmem_check $(((h<<8)|l)) $(((b<<8)|c))

setupMMgr 0x1c49          "initmask - initialise counter or shifter"
setupMMgr 0x1c51          "initmask - initialise counter or shifter"
setupMMgr 0x1c58          "initmask - imlp"
setupMMgr 0x1c59          "initmask - imlp1"
setupMMgr 0x1c5f          "initmask - imlp2"
setupMMgr 0x1c7c          "initmask - imlp3"                          RO 
setupMMgr 0x1c88          "initmask - imlp3 - ret"                    RO # dumpCounterShifter

count_E_org() {
    #state_note $FUNCNAME
    local -i _hl=0x1cda _de=_hl+20 _b0=b _c      # changes a and flags!
    while :; do
        (( a=MEM[_hl]=(MEM[_hl]+1)&255 ))
        (( a!=0 )) && {
            (( b=a, a=_c=MEM[_de] ));
            (( a&=b )); setfAND $b $_c $a        # and b
            (( (a!=0)?MEM[_hl]=0:0 ))
            b=_b0
            _b0=h; h=b; b=_b0; _b0=l; l=c; c=_b0  # swap bc and hl - seems to be source bug
            ret; return 0
        }
        _hl+=1
        _de+=1
    done
    _GO=false; return 0
}

count(){
    local -i _hl=0x1cda _b=0      # changes a and flags!
    while (( _b==0 )); do
        (( _b=MEM[_hl]=(MEM[_hl]+1)&255 ))
        _hl+=1
    done
    (( a=MEM[_hl+19] ));
    (( a&=_b, a!=0?MEM[_hl-1]=0:0 )); setfAND $_b $a $a        # and b
    _b=h; h=b; b=_b; _b=l; l=c; c=_b  # swap bc and hl - seems to be source bug
    #ret; return 0
    return 0
}

setupMMgr 0x1c89          "count - multi-byte counter" RO # count_E  # disp_counter
setupMMgr 0x1c95          "count - cntlp" 
setupMMgr 0x1ca4          "count - cntend"             RO #disp_counter
setupMMgr 0x1ca8          "count - cntlp1" 

shift_E_org() {
    #state_note $FUNCNAME
    local -i _hl=0x1d02 _de=_hl+20 _b0=b _c      # changes a and flags!
    while :; do
        (( a=MEM[_hl] ))
        (( a!=0 )) && {
            (( b=a, a=_c=MEM[_de] ));
            (( a&=b )); setfAND $b $_c $a        # ANDr_b
            (( a==0 )) && {
                a=b
                (( a=(((a<<1)|(a>>7))&255) ))    # RLCA
                (( a==1?(MEM[_hl]=0, _hl++, _de++ ):0 ))
                _c=MEM[_hl]=a
                a=0; setfXOR $_c $_c 0           # XORr_a 
            }
            b=_b0
            ret; return 0
        }
        _hl+=1
        _de+=1
    done
    _GO=false; return 0
}

shift2() {
    local -i _hl=0x1d02 _b=0 _c      # changes a and flags!
    while (( _b==0 )); do
        (( _b=MEM[_hl++] ))
    done
    (( a=_c=MEM[_hl+19] ));
    (( a&=_b )); setfAND $_b $_c $a        # ANDr_b
    (( a==0 )) && {
        a=_b
        (( a=(((a<<1)|(a>>7))&255) ))    # RLCA
        (( a==1?(MEM[_hl-1]=0, _c=MEM[_hl]=a):(_c=MEM[_hl-1]=a) ))
        a=0; setfXOR $_c $_c 0           # XORr_a 
    }
    #ret; return 0
    return 0
}

setupMMgr 0x1cad          "shift - multi-byte shifter" RO # shift_E  # disp_shifter
setupMMgr 0x1cb9          "shift - shflp"
setupMMgr 0x1ccf          "shift - shflp2"
setupMMgr 0x1cd1          "shift - shlpe"              RO #disp_shifter
setupMMgr 0x1cd5          "shift - shflp1" 

setupMMgr 0x1cda-0x1d01   "counter"                    RW #disp_counter_W  # dumpCounterShifter
setupMMgr 0x1d02-0x1d29   "shifter"                    RW #dump20

test_E_org() {
    #state_pause $FUNCNAME
    #$_DEBUG && return 0
    #printf "<$FUNCNAME>"
    pushb $a; pushb $f                           # push af
    pushb $b; pushb $c                           # push bc
    pushb $d; pushb $e                           # push de
    pushb $h; pushb $l                           # push hl

#    printf "\n"                                  # ld de,crlf; ld c,9; call bdos
#    h=0x1d; e=0x42                               # ld hl,iut
#    b=4                                          # ld b,4
#    pushw 0xdead; hexstr_E                       # call hexstr
#    printf " "                                   # ld e,' '; ld c,2; call bdos
#    b=16                                         # ld b,16
#    h=0x01; l=0x03                               # ld hl,msbt
#    pushw 0xdead
#    hexstr_E                                     # call hexstr
                                                 # di ; disable interrupts
    (( MEM[0x1d8d]=sp&255, MEM[0x1d8e]=sp>>8 ))  # ld (spsav),sp ; save stack pointer
    sp=0x0105                                    # ld sp,msbt+2 ; point to test-case machine state
    popmn; Y=n; y=m                              # pop iy ; and load all regs
    popmn; X=n; x=m                              # pop ix
    popmn; l=n; h=m                              # pop hl
    popmn; e=n; d=m                              # pop de
    popmn; c=n; b=m                              # pop bc
    popmn; f=n; a=m                              # pop af
    (( sp=MEM[0x0111]|(MEM[0x0112]<<8) ))        # ld sp,(spbt)
    jump 0x1d42                                  # decode iut as per normal. memexec allows pc to change and then decode processes a different instruction
    # iut_E should be called next
    return 0
}

#declare -i sa sf sb sc sd se sh sl

test_E_org(){
    pushb $a; pushb $f                           # push af
    pushb $b; pushb $c                           # push bc
    pushb $d; pushb $e                           # push de
    pushb $h; pushb $l                           # push hl
    #sa=a; sf=f sb=b sc=c sd=d se=e sh=h sl=l
                                                     # di ; disable interrupts
    (( MEM[0x1d8d]=sp&255, MEM[0x1d8e]=sp>>8 ))  # ld (spsav),sp ; save stack pointer
    sp=0x0105                                    # ld sp,msbt+2 ; point to test-case machine state
    popmn; Y=n; y=m                              # pop iy ; and load all regs
    popmn; X=n; x=m                              # pop ix
    popmn; l=n; h=m                              # pop hl
    popmn; e=n; d=m                              # pop de
    popmn; c=n; b=m                              # pop bc
    popmn; f=n; a=m                              # pop af
    (( sp=MEM[0x0111]|(MEM[0x0112]<<8) ))        # ld sp,(spbt)
    jump 0x1d42                                  # decode iut as per normal. memexec allows pc to change and then decode processes a different instruction
    return 0
}

test_E(){
    local -i _hl sa=a sf=f sb=b sc=c sd=d se=e sh=h sl=l
    #pushb $a; pushb $f                           # push af
    #pushb $b; pushb $c                           # push bc
    #pushb $d; pushb $e                           # push de
    #pushb $h; pushb $l                           # push hl
                                                     # di ; disable interrupts
    (( MEM[0x1d8d]=sp&255, MEM[0x1d8e]=sp>>8 ))  # ld (spsav),sp ; save stack pointer
    sp=0x0105                                    # ld sp,msbt+2 ; point to test-case machine state
    popmn; Y=n; y=m                              # pop iy ; and load all regs
    popmn; X=n; x=m                              # pop ix
    popmn; l=n; h=m                              # pop hl
    popmn; e=n; d=m                              # pop de
    popmn; c=n; b=m                              # pop bc
    popmn; f=n; a=m                              # pop af
    (( sp=MEM[0x0111]|(MEM[0x0112]<<8) ))        # ld sp,(spbt)
##
    #printf "\x1b[1GTest cycle1: %d -> %d c/h  %d c/m" $iut_count $(( iut_count*3600/SECONDS )) $(( iut_count*60/SECONDS ))
    pc=0x1d42; decode_single                     # decode iut as per normal. memexec allows pc to change and then decode processes a different instruction
    #iut_count+=1
    #(( iut_count%10==0 )) && printf "\x1b[1GTest cycle: %d -> %d c/h  %d c/m" $iut_count $(( iut_count*3600/SECONDS )) $(( iut_count*60/SECONDS ))
##
    #iut_post_E
    (( MEM[0x1d8b]=sp&255, MEM[0x1d8c]=sp>>8 ))  # ld (spat),sp ; save stack pointer
    sp=0x1d8b                                    # ld sp,spat
    pushb $a; pushb $f                           # push af ; save other registers
    pushb $b; pushb $c                           # push bc
    pushb $d; pushb $e                           # push de
    pushb $h; pushb $l                           # push hl
    pushb $x; pushb $X                           # push ix
    pushb $y; pushb $Y                           # push iy
    (( sp=MEM[0x1d8d]|(MEM[0x1d8e]<<8) ))        # ld sp,(spsav) ; restore stack pointer
	                                             # ei ; enable interrupts
                                                 # ld hl,(msbt) ; copy memory operand
    (( MEM[0x1d7d]=MEM[0x0103] ))
    (( MEM[0x1d7e]=MEM[0x0104] ))                # ld (msat),hl
    _hl=0x1d89                                   # ld hl,flgsat ; flags after test
    (( a=MEM[_hl] ))                             # ld a,(hl)
    (( _m=MEM[0x1d65] ))                         # flgmsk: here, flgmsk+1 is modified so we need to read value	
    (( a&=_m ))                                 # and a,mask ; mask-out irrelevant bits (self-modified code!)
    MEM[_hl]=a                                   # ld (hl),a
    _de=0x1d7d                                   # ld de,msat
    _hl=0x1e85                                   # ld hl,crcval
    for (( b=16; b>0; b-- )); do                 # tcrc:
        (( a=MEM[_de++] ))                       # ld a,(de)
        local -i _de1 _b
        (( a^=MEM[_hl+3] ))
        (( _de1=0x1e89+4*a, a=MEM[_de1] )); (( _b=MEM[_hl]   ))
        (( MEM[_hl]=a,      a=MEM[_de1+1]^_b, _b=MEM[_hl+1] ))
        (( MEM[_hl+1]=a,    a=MEM[_de1+2]^_b, _b=MEM[_hl+2] ))
        (( MEM[_hl+2]=a ))
        (( MEM[_hl+3]=MEM[_de1+3]^_b ))

    done                                         # dec b; jp nz,tcrc
    a=sa f=sf b=sb c=sc d=sd e=se h=sh l=sl
    #popmn; l=n; h=m                              # pop hl
    #popmn; e=n; d=m                              # pop de
    #popmn; c=n; b=m                              # pop bc
    #popmn; f=n; a=m                              # pop af
    #printf "\x1b[1GTest cycle2: %d -> %d c/h  %d c/m" $iut_count $(( iut_count*3600/SECONDS )) $(( iut_count*60/SECONDS ))
    ret; return 0  # use this to use test_E as a driver
    #return 0  # use this if test_E is called from another driver. eg. tlp_E
}


setupMMgr 0x1d2a          "test"                   RO  # test_E # start_ss

declare -i iut_count=0

iut_E() {
    iut_count+=1
    (( iut_count%10==0 )) && printf "\x1b[1GTest cycle: %d -> %d c/h" $iut_count $(( iut_count*3600/SECONDS ))
    #printf "Test cycle: %d -> %d c/h\n" $iut_count $(( iut_count*3600/SECONDS )) >> $LOG
    #printf "Test cycle: %d -> %d c/h\n" $iut_count $(( iut_count*3600/SECONDS ))
    #dis_regs
    #_DIS=true
    return 0
}

iut_W(){
    local -i _a=$1
    #printf "De-JIT iut %04x\n" $_a
    #unset "ACC[_a]"
    return 0
}

iut_no_jit_E(){
    printf "\x1b[1GTest cycle1: %d -> %d c/h" $iut_count $(( iut_count*3600/SECONDS ))
    pc=0x1d42; decode_single_no_driver           # decode iut as per normal. memexec allows pc to change and then decode processes a different instruction
    iut_count+=1
    (( iut_count%10==0 )) && printf "\x1b[1GTest cycle: %d -> %d c/h" $iut_count $(( iut_count*3600/SECONDS ))
#    printf "\x1b[1GTest cycle2: %d -> %d c/h" $iut_count $(( iut_count*3600/SECONDS )) >> $LOG
#    printf "\x1b[1GTest cycle2: %d -> %d c/h" $iut_count $(( iut_count*3600/SECONDS ))
    #pc=0x1d46
    return 0;
}

setupMMgr 0x1d42          "iut - test instruction" RW  iut_E #iut_no_jit_E  #iut_E  # not required since added RWS memory type "iut_E iut_W"
setupMMgr 0x1d43-0x1d45   "iut - test instruction" RW

iut_post_E_org() {
    #state_pause $FUNCNAME
    #printf "<$FUNCNAME>"
    local -i _hl
    (( MEM[0x1d8b]=sp&255, MEM[0x1d8c]=sp>>8 ))  # ld (spat),sp ; save stack pointer
    sp=0x1d8b                                    # ld sp,spat
    pushb $a; pushb $f                           # push af ; save other registers
    pushb $b; pushb $c                           # push bc
    pushb $d; pushb $e                           # push de
    pushb $h; pushb $l                           # push hl
    pushb $x; pushb $X                           # push ix
    pushb $y; pushb $Y                           # push iy

    (( sp=MEM[0x1d8d]|(MEM[0x1d8e]<<8) ))        # ld sp,(spsav) ; restore stack pointer
	                                             # ei ; enable interrupts
    #(( _hl=MEM[0x0103]|(MEM[0x0104]<<8) ))       # ld hl,(msbt) ; copy memory operand
    #(( MEM[0x1d7d]=_hl&255, MEM[0x1d7e]=_hl>>8 ))  # ld (msat),hl
                                                 # ld hl,(msbt) ; copy memory operand
    (( MEM[0x1d7d]=MEM[0x0103] ))
    (( MEM[0x1d7e]=MEM[0x0104] ))                # ld (msat),hl
#
    _hl=0x1d89                                   # ld hl,flgsat ; flags after test
    (( a=MEM[_hl] ))                             # ld a,(hl)
    (( _m=MEM[0x1d65] ))                         # flgmsk: here, flgmsk+1 is modified so we need to read value	
    (( a=a&_m ))                                 # and a,mask ; mask-out irrelevant bits (self-modified code!)
    MEM[_hl]=a                                   # ld (hl),a
    b=16                                         # ld b,16 ; total of 16 bytes of state
    d=0x1d; e=0x7d                               # ld de,msat
    h=0x1e; l=0x85                               # ld hl,crcval
    tcrc_E                                       # 'jump' to tcrc part that I made earlier
    #pc=0x1d6f                                    # OR set pc to next z-80 instruction for tcrc:
    return 0
}


iut_post_E() {
    #exit 1
    local -i _hl
    (( MEM[0x1d8b]=sp&255, MEM[0x1d8c]=sp>>8 ))  # ld (spat),sp ; save stack pointer
    sp=0x1d8b                                    # ld sp,spat
    pushb $a; pushb $f                           # push af ; save other registers
    pushb $b; pushb $c                           # push bc
    pushb $d; pushb $e                           # push de
    pushb $h; pushb $l                           # push hl
    pushb $x; pushb $X                           # push ix
    pushb $y; pushb $Y                           # push iy
    (( sp=MEM[0x1d8d]|(MEM[0x1d8e]<<8) ))        # ld sp,(spsav) ; restore stack pointer
	                                             # ei ; enable interrupts
                                                 # ld hl,(msbt) ; copy memory operand
    (( MEM[0x1d7d]=MEM[0x0103] ))
    (( MEM[0x1d7e]=MEM[0x0104] ))                # ld (msat),hl
    _hl=0x1d89                                   # ld hl,flgsat ; flags after test
    (( a=MEM[_hl] ))                             # ld a,(hl)
    (( _m=MEM[0x1d65] ))                         # flgmsk: here, flgmsk+1 is modified so we need to read value	
    (( a&=_m ))                                 # and a,mask ; mask-out irrelevant bits (self-modified code!)
    MEM[_hl]=a                                   # ld (hl),a
    #b=16                                         # ld b,16 ; total of 16 bytes of state
    _de=0x1d7d                                   # ld de,msat
    _hl=0x1e85                                   # ld hl,crcval
    for (( b=16; b>0; b-- )); do                 # tcrc:
        (( a=MEM[_de++] ))                       # ld a,(de)
        #(( e=e+1, (e==256)?(d=(d+1)&255,e=0):0 ))  # inc de
        #pushw 0xdead; updcrc_E                   # call updcrc ; accumulate     
        local -i _de1 _b
        (( a^=MEM[_hl+3] ))
        (( _de1=0x1e89+4*a, a=MEM[_de1] )); (( _b=MEM[_hl]   ))
        (( MEM[_hl]=a,      a=MEM[_de1+1]^_b, _b=MEM[_hl+1] ))
        (( MEM[_hl+1]=a,    a=MEM[_de1+2]^_b, _b=MEM[_hl+2] ))
        (( MEM[_hl+2]=a ))
        (( MEM[_hl+3]=MEM[_de1+3]^_b ))

    done                                         # dec b; jp nz,tcrc
    #a=sa; f=sf b=sb c=sc d=sd e=se h=sh l=sl
    popmn; l=n; h=m                              # pop hl
    popmn; e=n; d=m                              # pop de
    popmn; c=n; b=m                              # pop bc
    popmn; f=n; a=m                              # pop af
    ret; return 0
    #return 0
}

setupMMgr 0x1d46          "iut-post - test instruction" RO  #iut_post_E
#setupMMgr 0x1d64          "flgmsk"                      ROS # don't jit this either
#setupMMgr 0x1d65          "flgmsk+1"                    RWS # self modify code
# test new auto -de-JITing code
setupMMgr 0x1d64          "flgmsk"                      RO # don't jit this either
setupMMgr 0x1d65          "flgmsk+1"                    RW # self modify code

tcrc_E_org() {  # all regs preserved
    #state_note $FUNCNAME
    #printf "<$FUNCNAME>"
    while (( b>0 )); do                          # tcrc:
        (( a=MEM[d*256+e] ))                     # ld a,(de)
        (( e=e+1, (e==256)?(d=(d+1)&255,e=0):0 ))  # inc de
        pushw 0xdead; updcrc_E                   # call updcrc ; accumulate     
        (( b-=1 ))                               # dec b; jp nz,tcrc
    done
#    printf " "                                   # ld e,' '; ld c,2; call bdos
#    h=0x1e; l=0x85                               # ld hl,crcval
#    pushw 0xdead; phex8_E                        # call phex8
#    printf "\n"                                  # ld de,crlf; ld c,9, call bdos
#    h=0x1d; l=0x7d                               # ld hl,msat
#    b=16                                         # ld b,16
#    pushw 0xdead; hexstr_E                       # call hexstr
#    printf "\n"                                  # ld de,crlf; ld c,9, call bdos
    popmn; l=n; h=m                              # pop hl
    popmn; e=n; d=m                              # pop de
    popmn; c=n; b=m                              # pop bc
    popmn; f=n; a=m                              # pop af
    ret; return 0
}

tcrc_E() {  # all regs preserved
    for (( ; b>0; b-- )); do                     # tcrc:
        (( a=MEM[d<<8|e] ))                      # ld a,(de)
        (( e=e+1, (e==256)?(d=(d+1)&255,e=0):0 ))  # inc de
        pushw 0xdead; updcrc_E                   # call updcrc ; accumulate     
    done                                         # dec b; jp nz,tcrc
    popmn; l=n; h=m                              # pop hl
    popmn; e=n; d=m                              # pop de
    popmn; c=n; b=m                              # pop bc
    popmn; f=n; a=m                              # pop af
    ret; return 0
    #return 0
}

setupMMgr 0x1d6f          "tcrc - while b>0" RO  # tcrc_E  # run tcrc loop and return - bypass z-80

setupMMgr 0x1d7d-0x1d7e   "msat"             RW  # memop,iy,ix,hl,de,bc,af
setupMMgr 0x1d7f-0x1d80   "msat - iy"        RW
setupMMgr 0x1d81-0x1d82   "msat - ix"        RW
setupMMgr 0x1d83-0x1d84   "msat - hl"        RW
setupMMgr 0x1d85-0x1d86   "msat - de"        RW
setupMMgr 0x1d87-0x1d88   "msat - bc"        RW
setupMMgr 0x1d89-0x1d8a   "msat - af"        RW
setupMMgr 0x1d8b-0x1d8c   "spat"             RW
setupMMgr 0x1d8d-0x1d8e   "spsav"            RW

# hexstr is high-level emulated
hexstr_E() {
    #state_note $FUNCNAME
    local -i _j _hl=(h*256+l)
    while (( b>0 )); do
        printf "%02x" ${MEM[_hl]}
        (( _hl+=1, b-=1 )) 
    done
    ret; return 0
}

setupMMgr 0x1d8f          "hexstr" RO            # display hex string (pointer in hl, byte count in b)

# phex8 is high-level emulated
phex8_E() {
    #state_note $FUNCNAME
    local -i _j _hl=(h*256+l)
    for (( _j=3; _j>=0; _j-- )); do
        printf "%02x" ${MEM[_hl+_j]} 
    done
    ret; return 0
}

setupMMgr 0x1d99          "phex8" RO # phex8_E  # phex8 - display hex - display the big-endian 32-bit value pointed to by hl

# phex2 is high-level emulated
phex2_E() {
    #state_note $FUNCNAME
    #printf "%02x" ${MEM[(h<<8)|l]} 
    printf "%02x" $a 
    ret; return 0
}

setupMMgr 0x1dab          "phex2"        RO # phex2_E  #  phex2 - display byte in a
setupMMgr 0x1db4          "phex1"
setupMMgr 0x1dc1          "phex2 - phl1"

setupMMgr 0x1dce          "bdos"         RO  # bdos_E # start_ss
setupMMgr 0x1dda-0x1df9   "msg1"             # 31 'Z80doc instruction exerciser',10,13,'$'
setupMMgr 0x1df9-0x1e07   "msg2"             # 15 'Tests complete$'
setupMMgr 0x1e08-0x1e0e   "okmsg"            # 7 '  OK',10,13,'$'
setupMMgr 0x1e0f-0x1e29   "errmsg1"          # 27 '  ERROR **** crc expected:$'
setupMMgr 0x1e2a-0x1e31   "errsmg2"          # 8 ' found:$'
setupMMgr 0x1e32-0x1e34   "crlf"             # 3 10,13,'$'

setupMMgr 0x1e32-0x1e48   "cmpcrc"       RO # start_ss # disp_crcs

updcrc_E_org() {
    local -i _a=a _hl=h*256+l _de _b=0 _c=4
    (( _a^=MEM[_hl+3] ))
    (( _de=0x1e89+4*_a ))
    while :; do
        (( _a=MEM[_de++]^_b ))                     # get crctab, xor with b
        _b=MEM[_hl]
        MEM[_hl++]=_a
        (( _de++, _hl++, _c-- ))
        (( _c==0 )) && break
    done
    ret; return 0
}

updcrc_E_better() {
    local -i _a=a _hl=h*256+l _de _b=0 _c
    (( _a^=MEM[_hl+3] ))
    (( _de=0x1e89+4*_a ))
    for (( _c=4; _c>0; _c-- )); do
        (( _a=MEM[_de++]^_b ))                     # get crctab, xor with b
        _b=MEM[_hl]
        MEM[_hl++]=_a
    done
    ret; return 0
}

updcrc_E() {
    #state_note $FUNCNAME
    local -i _a=a _hl=h*256+l _de _b=0
    (( _a^=MEM[_hl+3] ))
    (( _de=0x1e89+4*_a, _a=MEM[_de++]^_b, _b=MEM[_hl] ))
    (( MEM[_hl++]=_a, _a=MEM[_de++]^_b, _b=MEM[_hl] ))
    (( MEM[_hl++]=_a, _a=MEM[_de++]^_b, _b=MEM[_hl] ))
    (( MEM[_hl++]=_a, _a=MEM[_de]^_b, _b=MEM[_hl] ))
    (( MEM[_hl]=_a ))
    ret; return 0
}

# Memory Manager can be used to trigger actions prior to execution, when reading or writing to memory.
# Memory locations or ranges are registered with setupMMgr <address>[-end address] "name" RO|RW driver
# To distinguish modes, an execution driver is <driver>_E, a read driver is <driver>_R and a write driver is <driver>_W

setupMMgr 0x1e49          "updcrc - 32-bit crc routine"  RO # updcrc_E # start_ss
setupMMgr 0x1e62          "updcrc - crclp - while c>0"

setupMMgr 0x1e38          "cmpcrc - display crcs"        RO # disp_crcs_R
setupMMgr 0x1e71          "initcrc - "
setupMMgr 0x1e7b          "initcrc - icrclp - while b>0"

setupMMgr 0x1e85-0x1e88   "crcval"                       RW # disp_crcval
setupMMgr 0x1e89-0x1a00   "crctab"                       RO

setupMMgr 0xe000-0xe400   "stack"                        RW

