#!/bin/bash

# prelim.com
setupMMgr 0x0111        "lab0"
setupMMgr 0x0117        "lab2"
setupMMgr 0x0121        "lab3"
setupMMgr 0x012a        "lab4"
setupMMgr 0x03c4        "lab10"
setupMMgr 0x044a        "okmsg"
setupMMgr 0x0465        "error"
setupMMgr 0x049d        "conout"
setupMMgr 0x04c0-0x04d3 "stack2" RW
setupMMgr 0x04d4-0x4d5  "hlval" RW
setupMMgr 0x04e0-0x04ff "regs2" RW  # guess
setupMMgr 0x0500-0x05ff "stack3" RW
setupMMgr 0x7f00-0x7fff "stack" RW
