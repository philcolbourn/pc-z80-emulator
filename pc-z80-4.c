
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int a,f,b,c,d,e,h,l,x,X,y,Y,pc,sp,i,r,r7,iff1,iff2,halt;  // Registers
int a1,f1,b1,c1,d1,e1,h1,l1,x1,X1,y1,Y1;  // Registers
int cycles,states,q,t;  // global timing variables
int ipc, opc, tpc;
char* tis;  // points to instruction name
int o,n,m,nn,mm,D,rr,rrd,rr2,jj,cc;  // global temporary variables
int af,bc,de,hl,ix,iy,xX,yY;  // global temporary variables
int u,k;  // flag use and update indicators
//printf "int af,bc,de,hl,ix,iy,xX,yY;  // global temporary variables
enum FLAG_MASKS{ FS=0x80, FZ=0x40, FY=0x20, FH=0x10, FX=0x08, FP=0x04, FN=0x02, FC=0x01 };  // f register flag masks
//char FLAG_NAMES[]={ 'C', 'N', 'P', 'X', 'H', 'Y', 'Z', 'S' };
char FLAG_NAMES[]="CnpxhyZS";


unsigned char MEM[65536];
char *PREFIX[]={ [0xCB]="CB", [0xED]="ED", [0xFD]="FD", [0xDD]="DD" };
#define FALSE (0==1)
#define TRUE (1==1)
int _GO=TRUE;
int _VERBOSE=TRUE;
int _DIS=TRUE;
int _JIT=FALSE;
int _FAST=TRUE;
int ipc;

// unhandled instructions go here
void XX(){
    int _inst=0, _j;
    for ( _j=0; _j<6; _j++ ){ 
        _inst=_inst<<8|MEM[ipc+_j];
    }
    printf( "ERROR: XX: Unknown %02x operation code [%012x] at %4x(%5d)\n", MEM[ipc], _inst, ipc, ipc );
    _GO=FALSE;
}

void STOP(){
    printf( "\nSTOP: Stop emulator at %4x\n", pc-1 );
    _GO=FALSE;
}

void (*IS[])();
void (*CB[])();
void (*DDCB[])();
void (*FDCB[])();
void (*ED[])();
void (*DD[])();
void (*FD[])();

char* IS_NAME[];
char* CB_NAME[];
char* DDCB_NAME[];
char* FDCB_NAME[];
char* ED_NAME[];
char* DD_NAME[];
char* FD_NAME[];

void MAPcb()  {                            tpc=pc; o=MEM[pc++]; tis=CB_NAME[o];   opc=pc; (*CB[o])();   }
//void MAPddcb(){ D=MEM[pc++]; (D>127)?(D-=256):0; tpc=pc; tis=DDCB_NAME; opc=pc; (*DDCB[MEM[pc++]])(); }
//void MAPfdcb(){ D=MEM[pc++]; (D>127)?(D-=256):0; tpc=pc; tis=FDCB_NAME; opc=pc; (*FDCB[MEM[pc++]])(); }
void MAPddcb(){ D=MEM[pc++]; D-=(D*2)&256; tpc=pc; o=MEM[pc++]; tis=DDCB_NAME[o]; opc=pc; (*DDCB[o])(); }
void MAPfdcb(){ D=MEM[pc++]; D-=(D*2)&256; tpc=pc; o=MEM[pc++]; tis=FDCB_NAME[o]; opc=pc; (*FDCB[o])(); }
void MAPed()  {                            tpc=pc; o=MEM[pc++]; tis=ED_NAME[o];   opc=pc; (*ED[o])();   }
void MAPdd()  {                            tpc=pc; o=MEM[pc++]; tis=DD_NAME[o];   opc=pc; (*DD[o])();   }
void MAPfd()  {                            tpc=pc; o=MEM[pc++]; tis=FD_NAME[o];   opc=pc; (*FD[o])();   }


void wp( int _p, int _v ){
    //[[ -z ${OUT[_p]} ]] && { OUT[_p]=$_p.out; $_DIS && printf "WARNING: $FUNCNAME: Output port $_p mapped to [%s]\n" ${OUT[_p]}; }
    printf( "OUT [%02x=%3d],%c\n", _p, _p, _v );  // >> ${OUT[_p]}
}

void rp( int _p ){
    //[[ -z ${IN[_p]} ]] && { IN[_p]=/dev/zero; $_DIS && printf "WARNING: $FUNCNAME: Input port $_p mapped to [%s]\n" ${IN[_p]}; }
    printf("IN [%02x=%3d]\n", _p, _p );  // read -N1 n < ${IN[_p]}
}

void memread( int _a ){}
void memprot( int _a, int _b ){}
void memprotb( int _a, int _b ){}
void memprotw( int _a, int _b ){}
void memexec( int _a ){}

#if defined _FAST
    #define _A1 (_a+1)
#else
    #define _A1 ((_a+1)&65535)
#endif

void rb( int _a )                 { memread( _a );     n=MEM[_a];                             }
void rw( int _a )                 { memread( _a ); (( nn=MEM[_a] | (MEM[_A1]<<8) )); }
void rb2( int _a )                { memread( _a );     n=MEM[_a]; m=MEM[_A1];        }

void wb( int _a, int _b )         { memprot( _a,_b );    MEM[_a]=_b;                                 }
void ww( int _a, int _w )         { memprot( _a,_w ); (( MEM[_a]=_w&255, MEM[_A1]=_w>>8 )); }
void wb2( int _a, int _l, int _h ){ memprot( _a,_l ); (( MEM[_a]=_l,     MEM[_A1]=_h ));    }

void ro()                         { memexec( pc ); o=MEM[pc];        pc+=1; opc=pc;                   }
void rn()                         {                n=MEM[pc++];      pc+=0; opc=pc;                   }
void rm()                         {                m=MEM[pc];        pc+=1; opc=pc; }
#define RELD D-=(D*2)&256
void rD()                         {                D=MEM[pc];        pc+=1; opc=pc; RELD; }
void rR()                         {                D=MEM[pc];        pc+=1; opc=pc; RELD; pc=(pc+D)&65535; }
void rnn()                        { (( nn=MEM[pc]|(MEM[pc+1]<<8) )); pc+=2; opc=pc; }
void rmm()                        { (( mm=MEM[pc]|(MEM[pc+1]<<8) )); pc+=2; opc=pc; }
void rpc()                { int _p; (( _p=MEM[pc]|(MEM[pc+1]<<8) ));        opc=pc+2; pc=_p; }

#define PCRELD pc+=D-(D<<1)&256
void rPCD()                       {                D=MEM[pc];        pc+=1; opc=pc;((PCRELD));}
void rjjcc(){ ((jj=MEM[pc]|(MEM[pc+1]<<8)));pc+=2;opc=cc=pc;}
#define JJPCRELD (jj=pc+D-((D<<1)&256))

void rDjjcc(){ D=MEM[pc];pc+=1;opc=cc=pc;((JJPCRELD));}

void pushb( int _b )              {    MEM[sp-1]=_b;                         sp-=1;           }
void pushw( int _w )              { (( MEM[sp-1]=_w>>8, MEM[sp-2]=_w&255 )); sp-=2;           }
void pushpcnn()                   { (( MEM[sp-1]=pc>>8, MEM[sp-2]=pc&255,    sp-=2, pc=nn )); }

void popn()                       {     n=MEM[sp];                     sp+=1; }
void popm()                       {     m=MEM[sp];                     sp+=1; }
void popmn()                      {     n=MEM[sp]; m=MEM[sp+1];        sp+=2; }
void popnn()                      { (( nn=MEM[sp] | (MEM[sp+1]<<8) )); sp+=2; }
void poppc()                      { (( pc=MEM[sp] | (MEM[sp+1]<<8) )); sp+=2; }
void popmm()                      { (( mm=MEM[sp] | (MEM[sp+1]<<8) )); sp+=2; }

#include "generated-functions.c"

// minimal CP/M bdos emulator

void bdos_E(){
    int _tt, _j;
    //printf( "bdos\n" );
    //printf( "%s: Function  c=%02x  de=%04x  a=%02x\n", __func__, c, (d<<8)|e, a );
    switch (c){
        case 9: (( _tt=(d<<8)|e, _j=MEM[_tt] )); (( _tt=(_tt+1)&65535 ));
                while (( _j!='$' )){
                    switch (_j){
                        case 10: printf( "\n" ); break;
                        case 13: printf( "\n" ); break;
                        default: printf( "%c", _j );
                    }
                    (( _j=MEM[_tt] )); (( _tt=(_tt+1)&65535 ));
                }; break;
        case 2: printf( "%c", e ); break;
       default: printf( "ERROR: [%s]: Function c=%02x not handled.\n", __func__, c ); exit(0);
    }
    popnn(); pc=nn;
}


#define MAX(a,b) ((a>b)?(a):(b))

void dump20( int _a ){
    int _j, _c;
    char _ascii[100];
    int _i=0;
    printf( "\n" );
    for ( _j=MAX( -(_a&15)-0x10, 0 ); _j<0x200-(_a&15); _j++ ){
        //(( ((_a+_j)&15)==0 )) && printf "%04x  " $(( _a+_j ))
        _c=MEM[(_a+_j)&65535];
        switch ((_a+_j)&15){
            case 0: printf( "\x1b[34m%04x\x1b[m  ", _a+_j );     // print address
        }
        if (( _j>=0 && _j<2 )){ printf( "\x1b[41m"); strncat( _ascii, "\x1b[41m", 100 ); _i+=5;  }
        printf( "%02x", _c );
        _ascii[_i++]=_c; _ascii[_i]='\0';                    // make ASCII string 
        if (( _j>=0 && _j<2 )){ printf( "\x1b[m"); strncat( _ascii, "\x1b[m", 100 ); _i+=3; }
        switch ((_a+_j)&15){
            case 7: printf( "|" ); _ascii[_i++]='|'; _ascii[_i]='\0'; break;        // divide hex and ASCII displays into groups
            case 15: printf( "  [%s]\n", _ascii );      // at byte 15, display ASCII version 
               _i=0;
               break;
            default: printf( " " );
        }
    }
}


void load(int _address, char *_filename){
    //_VERBOSE && printf( "LOADING %s...\n",_filename );
    FILE *_f;
    _f=fopen( _filename,"r" );
    int _n=fread( &MEM[_address],1,16384,_f );              // load ROM
    fclose( _f );
    printf( "%s: Read %d bytes\n", __func__, _n );
    //mem_make_readable();
}

void get_FLAGS( char *_r ){
    int _j;
    for ( _j=7; _j>=0; _j-- ){
        _r[7-_j]=( f&(1<<_j) )? FLAG_NAMES[_j]: '.';
    }
    _r[8]=0;
}


void dis_reg( const char *rp, int h, int l ){
    int _rr, _nn, _h, _l, _j, _ss, _sh, _sl, _x; 
    _rr=h*256+l; _nn=MEM[_rr]+MEM[_rr+1]*256;
    (( _h=_nn>>8, _l=_nn&255, _ss=_nn>0x7fff?_nn-65536:_nn, _sh=_h>127?_h-256:_h, _sl=_l>127?_l-256:_l ));
    printf( "%2s=%04x (%04x) %5d|%-+6d %3d|%-+4d %3d|%-+4d [", rp, _rr, _nn, _nn, _ss, _h, _sh, _l, _sl );
    for ( _j=0; _j<16; _j++ ){
        _x=MEM[(_rr+_j)&65535];
        printf( "%c", _x );
    }
    printf( "]\n" );
}

void dis_regs(){
    //int _rr, _nn;
    char _flags[9];  // _rp; 
    //int _rr1, _h, _l, _j, _ss, _sh, _sl, _x;
    printf( "REGISTERS  (a negative in unsigned column means JIT replaced instruction)\n" );
    get_FLAGS( _flags );
    printf( "RP=%4s (%4s) %5s|%-6s %3s|%-4s %3s|%-4s [%16s]\n", "HHLL", "MMMM", "UU", "SS", "U", "S", "u", "s", "16B from MEM[RP]" );
    printf( "a=%02x  f=%02x  n=%02x  m=%02x  nn=%04x  mm=%04x\n", a, f, n, m, nn, mm );
    printf( "AF=%04x (%02x=%1c) %16d|%-+4d %8s\n", a*256+f, a, a, a, a>127?a-256:a, _flags );
    dis_reg( "BC", b, c );
    dis_reg( "DE", d, e );
    dis_reg( "HL", h, l );
    dis_reg( "IX", x, X );
    dis_reg( "IY", y, Y );
    dis_reg( "PC", pc>>8, pc&255 );
    dis_reg( "SP", sp>>8, sp&255 );
}

char *dis_opcode(){
    int _i=MEM[pc];
    return( IS_NAME[_i] );
}

int iut_count=0;
int test_count=0;

decode(){
    int _pc=-1, _apc, _i;
    int _j;
    int _redo;
    // _DRIVER _fn _BFN
    if ( _DIS ) printf( "%6s %8s %4s %8s %-36s; %s\n", "STATES", "FLAGS", "ADDR", "HEX", "INSTRUCTION", "RATE" );
    if ( _FAST && ! _JIT ) {  // special case for runs - fastest when test harness is totally replaces with bash
        while (_GO){
            //_DRIVER=${MEM_DRIVER_E[pc]}
            //[[ -n $_DRIVER ]] && eval $_DRIVER $pc  # assume only 1 driver
            if ( pc==0x0005 ) bdos_E();
            if ( pc==0x0122 ) {  // test loop
                test_count++;
                //printf( "\nTest %d  hl=[%04x]  IUT cycles=%d\n", test_count, (h<<8)|l, iut_count );
            }

            ipc=tpc=pc;
            o=MEM[pc++];
            opc=pc;
            tis=IS_NAME[o];
            (*IS[o])();
            
            if ( ipc==0x1d42 ) {
                iut_count++;
                //if (( iut_count%10000==0 )) printf( "." );
                _i=0;
                for ( _j=ipc; _j<opc; _j++ ){
                    _i=_i*256+MEM[_j];
                }
                //printf( "%04x  %8x  %-10s  IUT  cycles=%d\n", ipc, _i, tis, iut_count );
                //"\x1b[1GTest cycle: %d -> %d c/h  %d c/m" $iut_count $(( iut_count*3600/SECONDS )) $(( iut_count*60/SECONDS ))
            }
            //dis_regs();
            if ( pc == 0 ) { printf( "\nWarm boot\n" ); break; }
            if ( pc >0x4000 ) { printf( "\nCrashed?\n" ); break; }
        }
    }
    printf( "Test %d  hl=[%04x]  IUT cycles=%d\n", test_count, (h<<8)|l, iut_count );
    
}

// restart CPU will all registers preserved (normally you would set pc to 0x0000)
// CPU lines, timing, i and r are reset
void warm_boot(){
    if (_VERBOSE) printf( "Start Program with current register values\n" );
    //SECONDS=1;                                    // hack to eliminate division/0
    _GO=TRUE;
    (( D=0, q=t=0, halt=0, iff1=iff2=0, i=0xff, r=0 ));  // [SC05]
    cycles=states=0;
    decode();                                       // like a real reset, start work
}

// start CPU with general purpose registers set
start(){
    if (_VERBOSE) printf( "Start Program\n" );
    (( sp=0xffff, pc=0x0000 ));  // [SY05]
    warm_boot();                                       // like a real reset, start work
}

// [SY05] The Undocumented Z80 Documented, Sean Young, V0.91, 2005
// emuilate a real reset or power-on of CPU
reset(){
    if (_VERBOSE) printf( "Reset CPU\n" );
    (( a=f=b=c=d=e=h=l=x=X=y=Y=a1=f1=b1=c1=d1=e1=h1=l1=x1=X1=y1=Y1=0xff ));  // [SY05] - could randomise these
    start();
}


void main(){
    int _a=0x013a;
    int _t=0;
    if ( _t>0 ){
        for ( ; _t<=67; _t++ ){
            iut_count=0;
            test_count=0;
            printf( "########## Run test [%d]\n", _t );
            load( 0x0100,"CPM/zexdoc.com" );
            //load( 0x0100,"CPM/zexall.com" );
            MEM[0]=0xc3; MEM[1]=0x00; MEM[2]=0x01; MEM[5]=0xc9; MEM[6]=0x00; MEM[7]=0xe4; //  asm @0 JPnn w0x0100 @5 RET w0xe400  # for zexdoc.com
            MEM[_a]=MEM[_a+(_t-1)*2];
            MEM[_a+1]=MEM[_a+1+(_t-1)*2];
            MEM[_a+2]=0;
            MEM[_a+3]=0;
            //dump20( 0x0100 );
            reset();
        } 
    }   
    else{
        load( 0x0100,"CPM/zexdoc.com" );
        //load( 0x0100,"CPM/zexall.com" );
        MEM[0]=0xc3; MEM[1]=0x00; MEM[2]=0x01; MEM[5]=0xc9; MEM[6]=0x00; MEM[7]=0xe4; //  asm @0 JPnn w0x0100 @5 RET w0xe400  # for zexdoc.com
        reset();
    }
}


