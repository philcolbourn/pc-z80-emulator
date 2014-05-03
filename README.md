pc-z80-emulator
===============

A Z-80 emulator written in Bash


Why?

I really enjoyed Fabrice Bellard's PC emulator written in Javascript.

http://bellard.org/jslinux/


I wondered "how hard could it be"?

I decided to have a go but to do something that I suspected few would have tried: to write a CPU emulator in Bash.

It turns out not to be too difficult, just tedious.


Why a Z-80?

I choose Z-80 because that was my first CPU. I still have a few books about Z-80 machine code and I had a reasonable understanding about how this CPU worked (or so I thought before I started).


Why emulate  System-80?

A System 80 is a TRS-80 clone sold in Australia and NZ by Dick Smith Electronics. It was also sold in other countries under other names.

I choose to emulate a System 80 because I was familiar with it. I knew how a lot of it's hardware worked, especially keyboard input, cassette reading, and video generation.


What can it do?

It can do all these things (CTRL-C usually will kill emulator):

1. boot a System-80 ROM - since I doubt these ROMs are in public domain, you will neew to copy one from your own System-80 or get one from a friend such as Google. 

This link looks interesting

http://www.classiccmp.org/cpmarchives/trs80/Software/Model%201/

eg.

./bash ./pc-system80-rc3.bash FAST JIT

<CR> to get READY> prompt
10 FOR I=1 to 10:PRINT I:NEXT
LIST
RUN

2. load and run space invaders

eg.

./bash ./pc-system80-rc3.bash FAST JIT

SYSTEM
INVADE (hold down shift key to enter in lowercase eventhough characters are shown in uppercase)
/

3. 'pass' ZEXDOC Z-80 tests

Note: Version I used is dated 3/11/2002 by J.G.Harston based on Frank D. Cringle's 1994 version. This is in CPM sub directory.

There is a program called ZEXDOC (and ZEXALL) that tests emulators against real Z-80 behaviour. It runs most instructions using about 2,000,000 tests.

https://github.com/anotherlin/z80emu/blob/master/testfiles/zexdoc.z80

My emulator in bash passed all tests (in theory) on 31/3/2013.

To do this I had to write a translator that takes bash and generates C to get it to run fast enough to run all tests. Otherwise I calculated that to run all tests I would need 16-24 hours with a bash version of ZEXDOC - one test (test 6) took 12 hours when I ran it once but after some optimisation it probably now takes 8 hours.

A fully emulated ZEXDOC would take something like 10 times longer. But a C version takes 100s. That makes C about 500 times faster.

Note: Since passing these tests, I have implemented all manner of optimisations which have not been re-tested.

My results are reproduced below.


Issues

1. It is messy
2. Bash 4.2 is buggy and I had to download Bash 4.3 and compile it to get my code to run. I could have worked around bash 4.2 bugs but my code would have been slower and I was focused on keeping it short.

Specifically,

unset a b X
declare -i a=-1 b=1
declare -ia X=( {0..1000..100} )
(( a=X[b],b=b+1 ))  # crashes bash.

If your version of bash does not crash then you should not need 4.3

3. Some stuff like space invader's filename is hard coded
4. I have not documented by JIT or BLOCK optimisations very well
5. Bach to C now generates errors
6. Only FAST bash functions work
7. Lots of left-over code haning around


Command Line

./bash ./pc-system80-rc3.bash <options>

LOG - Log everything to log files
ASM - Can't remember 
JIT - Use (a sort-of) Just-in-time compiling
FAST - Use FAST bash functions (only FAST works)
TEST - ?
BLOCK - Use compiled blocks
DEBUG - ?
MEMPROT - ?
VERBOSE - display lots of info
 

ZEXDOC Test Results


Z80 instruction exerciser

Test 1  hl=[013a]  IUT cycles=0
<adc,sbc> hl,<bc,de,hl,sp>....  OK

Test 2  hl=[013c]  IUT cycles=72704
add hl,<bc,de,hl,sp>..........  OK

Test 3  hl=[013e]  IUT cycles=109056
add ix,<bc,de,ix,sp>..........  OK

Test 4  hl=[0140]  IUT cycles=145408
add iy,<bc,de,iy,sp>..........  OK

Test 5  hl=[0142]  IUT cycles=181760
aluop a,nn....................  OK

Test 6  hl=[0144]  IUT cycles=212480
aluop a,<b,c,d,e,h,l,(hl),a>..  OK

Test 7  hl=[0146]  IUT cycles=982528
aluop a,<ixh,ixl,iyh,iyl>.....  OK

Test 8  hl=[0148]  IUT cycles=1367552
aluop a,(<ix,iy>+1)...........  OK

Test 9  hl=[014a]  IUT cycles=1613312
bit n,(<ix,iy>+1).............  OK

Test 10  hl=[014c]  IUT cycles=1615616
bit n,<b,c,d,e,h,l,(hl),a>....  OK

Test 11  hl=[014e]  IUT cycles=1665792
cpd<r>........................  OK

Test 12  hl=[0150]  IUT cycles=1697887
cpi<r>........................  OK

Test 13  hl=[0152]  IUT cycles=1747405
<daa,cpl,scf,ccf>.............  OK

Test 14  hl=[0154]  IUT cycles=1812941
<inc,dec> a...................  OK

Test 15  hl=[0156]  IUT cycles=1816525
<inc,dec> b...................  OK

Test 16  hl=[0158]  IUT cycles=1820109
<inc,dec> bc..................  OK

Test 17  hl=[015a]  IUT cycles=1821901
<inc,dec> c...................  OK

Test 18  hl=[015c]  IUT cycles=1825485
<inc,dec> d...................  OK

Test 19  hl=[015e]  IUT cycles=1829069
<inc,dec> de..................  OK

Test 20  hl=[0160]  IUT cycles=1830861
<inc,dec> e...................  OK

Test 21  hl=[0162]  IUT cycles=1834445
<inc,dec> h...................  OK

Test 22  hl=[0164]  IUT cycles=1838029
<inc,dec> hl..................  OK

Test 23  hl=[0166]  IUT cycles=1839821
<inc,dec> ix..................  OK

Test 24  hl=[0168]  IUT cycles=1841613
<inc,dec> iy..................  OK

Test 25  hl=[016a]  IUT cycles=1843405
<inc,dec> l...................  OK

Test 26  hl=[016c]  IUT cycles=1846989
<inc,dec> (hl)................  OK

Test 27  hl=[016e]  IUT cycles=1850573
<inc,dec> sp..................  OK

Test 28  hl=[0170]  IUT cycles=1852365
<inc,dec> (<ix,iy>+1).........  OK

Test 29  hl=[0172]  IUT cycles=1859533
<inc,dec> ixh.................  OK

Test 30  hl=[0174]  IUT cycles=1863117
<inc,dec> ixl.................  OK

Test 31  hl=[0176]  IUT cycles=1866701
<inc,dec> iyh.................  OK

Test 32  hl=[0178]  IUT cycles=1870285
<inc,dec> iyl.................  OK

Test 33  hl=[017a]  IUT cycles=1873869
ld <bc,de>,(nnnn).............  OK

Test 34  hl=[017c]  IUT cycles=1873903
ld hl,(nnnn)..................  OK

Test 35  hl=[017e]  IUT cycles=1873920
ld sp,(nnnn)..................  OK

Test 36  hl=[0180]  IUT cycles=1873937
ld <ix,iy>,(nnnn).............  OK

Test 37  hl=[0182]  IUT cycles=1873971
ld (nnnn),<bc,de>.............  OK

Test 38  hl=[0184]  IUT cycles=1874037
ld (nnnn),hl..................  OK

Test 39  hl=[0186]  IUT cycles=1874054
ld (nnnn),sp..................  OK

Test 40  hl=[0188]  IUT cycles=1874071
ld (nnnn),<ix,iy>.............  OK

Test 41  hl=[018a]  IUT cycles=1874137
ld <bc,de,hl,sp>,nnnn.........  OK

Test 42  hl=[018c]  IUT cycles=1874205
ld <ix,iy>,nnnn...............  OK

Test 43  hl=[018e]  IUT cycles=1874239
ld a,<(bc),(de)>..............  OK

Test 44  hl=[0190]  IUT cycles=1874285
ld <b,c,d,e,h,l,(hl),a>,nn....  OK

Test 45  hl=[0192]  IUT cycles=1874357
ld (<ix,iy>+1),nn.............  OK

Test 46  hl=[0194]  IUT cycles=1874391
ld <b,c,d,e>,(<ix,iy>+1)......  OK

Test 47  hl=[0196]  IUT cycles=1874935
ld <h,l>,(<ix,iy>+1)..........  OK

Test 48  hl=[0198]  IUT cycles=1875207
ld a,(<ix,iy>+1)..............  OK

Test 49  hl=[019a]  IUT cycles=1875343
ld <ixh,ixl,iyh,iyl>,nn.......  OK

Test 50  hl=[019c]  IUT cycles=1875379
ld <bcdehla>,<bcdehla>........  OK

Test 51  hl=[019e]  IUT cycles=1878844
ld <bcdexya>,<bcdexya>........  OK

Test 52  hl=[01a0]  IUT cycles=1885774
ld a,(nnnn) / ld (nnnn),a.....  OK

Test 53  hl=[01a2]  IUT cycles=1885820
ldd<r> (1)....................  OK

Test 54  hl=[01a4]  IUT cycles=1885866
ldd<r> (2)....................  OK

Test 55  hl=[01a6]  IUT cycles=1885912
ldi<r> (1)....................  OK

Test 56  hl=[01a8]  IUT cycles=1885958
ldi<r> (2)....................  OK

Test 57  hl=[01aa]  IUT cycles=1886004
neg...........................  OK

Test 58  hl=[01ac]  IUT cycles=1902388
<rrd,rld>.....................  OK

Test 59  hl=[01ae]  IUT cycles=1910068
<rlca,rrca,rla,rra>...........  OK

Test 60  hl=[01b0]  IUT cycles=1917236
shf/rot (<ix,iy>+1)...........  OK

Test 61  hl=[01b2]  IUT cycles=1917684
shf/rot <b,c,d,e,h,l,(hl),a>..  OK

Test 62  hl=[01b4]  IUT cycles=1924596
<set,res> n,<bcdehl(hl)a>.....  OK

Test 63  hl=[01b6]  IUT cycles=1931636
<set,res> n,(<ix,iy>+1).......  OK

Test 64  hl=[01b8]  IUT cycles=1932116
ld (<ix,iy>+1),<b,c,d,e>......  OK

Test 65  hl=[01ba]  IUT cycles=1933172
ld (<ix,iy>+1),<h,l>..........  OK

Test 66  hl=[01bc]  IUT cycles=1933444
ld (<ix,iy>+1),a..............  OK

Test 67  hl=[01be]  IUT cycles=1933516
ld (<bc,de>),a................  OK

Test 68  hl=[01c0]  IUT cycles=1933616
Tests complete
Warm boot

real	1m45.121s
user	1m45.040s
sys	0m0.000s




