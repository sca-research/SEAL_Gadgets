@ HPC1_OPT_3_V0

@ a = a0^a1^a2, b = b0^b1^b2, c = c0^c1^c1, a * b = c, random numbers: rnd0, rnd1, rnd2
@  ^: xor; +: arithmathic addition; x & y: and operation; *: Galois field multiplication; &x: the address of x

@@@@ ref_b0 = b0^rnd0
@@@@ ref_b1 = b1^rnd1
@@@@ ref_b2 = b2^(rnd0^rnd1)

@@@@ c0 = (a0*ref_b0)^[(a0*ref_b1)^rnd2]^[(a0*ref_b2)^rnd3]
@@@@ c1 = [(a1*ref_b0)^rnd2]^(a1*ref_b1)^[(a1*ref_b2)^rnd4]
@@@@ c2 = [(a2*ref_b0)^rnd3]^[(a2*ref_b1)^rnd4]^(a2*ref_b2) 

  .syntax unified
  .text
  .thumb
  
  .extern table       @@@@ table is used for GFMULT (ai*bj multiplications)
  
@@@@ extern void HPC1_opt_3(uint8_t* inputa: addres: r0, uint8_t* inputb: address: r1, uint8_t* rnd: address: r2, uint8_t* output: address: r3);
@inputa: a0, a1, a2, inputb: b0, b1, b2, rnd: rnd0, ..., rnd4, output: c: c0, c1, c2
@ rnd0 and rnd1 are used in Opt_refresh_mask, and rnd2-rnd4 are used in Dom_indep

.global HPC1_opt_3
.func HPC1_opt_3
HPC1_opt_3:


  push  {lr}

  # This programm is written using Thumb-16 instructions.
  # In Thumb-16 registerlist in push/pop can not contain High registers.
  # As a result, instead of push/pop {r4-r11}, the following instructions are used.

  # about MOV and MOVS instructions in thumb-16:
  # MOVS: #imm to LOWreg, and LOWreg to LOWreg
  # MOV:any_reg to any_reg
  # For moving reg to reg we use MOV, for moving #imm to reg we use MOVS

  push  {r4-r7}
  mov   r4, r8
  mov   r5, r9
  mov   r6, r10
  mov   r7, r11
  push  {r4-r7}



@@@@@ r0 = &a, r1 = &b, r2 = &rnd, r3 = &c

@@@@@ Saving r3 (the address of the output)
  mov  r8, r3        @r8 = &c

@@@@@ Saving r0 (the address of the input a)
  mov  r9, r0        @ r9 = &a

@@@@@ Saving r1 (the address of the input b)
  mov  r10, r1       @ r10 = &b


  ldr  r4, =table    @ r4 = &taable, The address of the "table", for ai*bj multiplications
@@@@ Reducing the use of LDR instruction: ldr rx,=table @ rx = &table; --> mov rx, r11 
  mov  r11, r4       @ r11 = &table

nop
nop
nop
nop


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@ Loading arguments and Optimized Refresh Mask:
@@ Computing ref_bi and storing them in &in_b (&r1)

@@@@ ref_b0

  movs r6, #0         @ r6 = 0

@ # fake leakage: Leaky cycles: 324cycles[71, 72]:   270cycle[17, 18]
@ ldrb r5, [r1, #4]   @ r5 = b1


  ldrb r5, [r1, #0]   @ r5 = b0; r0 = &a, r1 = &b, r2 = &rnd, r3 = &table
  ldrb r3, [r2, #0]   @ r3 = rnd0; r0 = &a, r1 = &b, r2 = &rnd
  eors r5, r3         @ r5 = ref_b0  @ ref_b0 = b0^rnd0
  strb r6, [r1, #0]   @ Cleaaring b0 from the memory
  strb r5, [r1, #0]   @ Storing ref_b0 in the memory

@@@@ ref_b1

  ldrb r4, [r2, #4]   @ r4 = rnd1; r0 = &a, r1 = &b, r2 = &rnd
  ldrb r7, [r1, #4]   @ r7 = b1; r0 = &a, r1 = &b, r2 = &rnd
  eors r7, r4         @ r7 = ref_b1  @ ref_b1 = b1^rnd1
  strb r6, [r1, #4]   @ Clearing the write bus and Cleaaring b1 from the memory
  strb r7, [r1, #4]   @ Storing ref_b1 in the memory

@@@@ ref_b2 

  eors r4, r3         @ r3 = rnd0^rnd1
  ldrb r6, [r0, #4]   @ r6 = a1; r0 = &a, r1 = &b, r2 = &rnd
  ldrb r3, [r1, #8]   @ r4 = b2; r0 = &a, r1 = &b, r2 = &rnd  
  eors r3, r4         @ r4 = ref_b2  @ ref_b2 = b2^(rnd0^rnd1)
  strb r0, [r1, #8]   @ Clearing the write bus and Cleaaring b2 from the memory
  strb r3, [r1, #8]   @ Storing ref_b2 in the memory
  ldrb r4, [r0, #0]   @ r4 = a0; r0 = &a, r1 = &b, r2 = &rnd


@@@@@@@@@@ Computing: ai*bi

@@@@ r0 = &a, r1 = &b, r2 = &rnd, r3 = ref_b2
@@@@ r4 = a0, r5 = ref_b0, r6 = a1, r7 = ref_b1, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ a0*ref_b0

  mov  r3, r11        @ r3 = &table
  ldrb r0, [r3, r4]   @ r0 = table[a0]
  ldrb r1, [r3, r5]   @ r1 = table[ref_b0]

  adds r0, r1         @ r0 = s = table[a0]+table[ref_b0]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r1, #250       @ r1 = 250, 256 is not possible, so it is split: 250+6
  adds r1, #6         @ r1 = 256
  adds r0, r1         @ r0 = s+256

  ldrb r1, [r3, r0]   @ r1 = s = table[s+256]

  # @@@@ Checking if a0 = 0 or ref_b0 = 0, return 0; without conditional branch
  negs r0, r4         @ r0 = -a0 hex(256-dec(a0))

  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r3, #32        @ r3 = #32
  asrs r0, r3         @ r0 = -a0 >> 32

  ands r5, r0         @ r5 = tmp = ref_b0 & (-a0 >> 32)
  negs r5, r5         @ r5 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r5, r3         @ r5 = -tmp >> 32

  ands r1, r5         @ r1 = s & (-tmp >> 32) = (a0*ref_b0)

  mov  r0, r8         @ r0 = &c
  mov  r3, r11        @ r3 = &table
  strb r1, [r0, #0]   @ r1 = (a0*ref_b0), Storing (a0*ref_b0) in &c+#0, r1 = (a0*ref_b0)
# we need to clear the read bus and also reg1, istead of using two instructions, just we can use one as:
  # eors r1, r1         @ r1 = 0, clearing (a1*ref_b1) 
  # ldrb rx, [r3, #0]   @ rx = 0 = table[0],  Clearing the read bus
  ldrb r1, [r3, #0]   @ r1 = 0 = table[0],  Clearing the read bus and also reg1
  strb r0, [r0, #4]   @ clearing the write bus

@@@@ r0 = &c, r1 = 0, r2 = &rnd, r3 = &table
@@@@ r4 = a0, r5 = -tmp >> 32, r6 = a1, r7 = ref_b1, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ a1*ref_b1
@ # fake leakage: leaky cycle: 324cycles[118, 119, 120, 121, 122]   
@ ldrb r5, [r3, r4]   @ r5 = table[a0]

  ldrb r5, [r3, r6]   @ r5 = table[a1]
  ldrb r1, [r3, r7]   @ r1 = table[ref_b1]

  adds r5, r1         @ r5 = s = table[a1]+table[ref_b1]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r1, #250       @ r1 = 250, 256 is not possible, so it is split: 250+6
  adds r1, #6         @ r1 = 256
  adds r5, r1         @ r5 = s+256

  ldrb r1, [r3, r5]   @ r1 = s = table[s+256]


  # @@@@ Checking if a1 = 0 or ref_b1 = 0, return 0; without conditional branch
  negs r5, r6         @ r5 = -a1

  @ a1 in r6 is not needed anymore, r6 can be used
  # @ asrs rd, <#imm> --> #imm: 0-31

@ # fake leakage: leaky cycle: 324cycles[129, 130]
@ mov r4, r4

  movs r6, #32
  asrs r5, r6         @ r5 = -a1 >> 32

  ands r5, r7         @ r5 = tmp = ref_b1 & (-a1 >> 32)
  negs r5, r5         @ r5 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r5, r6         @ r5 = -tmp >> 32

  ands r1, r5         @ r1 = s & (-tmp >> 32) = (a1*ref_b1)
  
  # mov  r0, r8         @ r0 = &c
  # mov  r3, r11        @ r3 = &table
  strb r1, [r0, #4]   @ r1 = (a1*ref_b1), Storing (a1*ref_b1) in &c+#4, r1 = (a1*ref_b1)
## we need to clear the read bus and also reg1, istead of using two instructions, just we can use one as:
  # eors r1, r1         @ r1 = 0, clearing (a1*ref_b1) 
  # ldrb rx, [r3, #0]   @ rx = 0 = table[0],  Clearing the read bus
  ldrb r1, [r3, #0]   @ r1 = 0 = table[0],  Clearing the read bus and also reg1
  strb r0, [r0, #8]   @ clearing the write bus

@@@@ r0 = &c, r1 = 0, r2 = &rnd, r3 = &table
@@@@ r4 = a0, r5 = -tmp >> 32, r6 = 32, r7 = ref_b1, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ a2*ref_b2
  mov  r5, r9         @ r5 = &a
  mov  r1, r10        @ r1 = &b

@ # fake leakage: Leaky cycles: 324cycles[142, 143, 144]
@ ldrb r6, [r5, #4]   @ r6 = a1
@ ldrb r6, [r5, #0]   @ r6 = a0

  ldrb r6, [r5, #8]   @ r6 = a2
  ldrb r0, [r1, #8]   @ r0 = ref_b2
  
  ldrb r1, [r3, r6]   @ r1 = table[a2]
  ldrb r5, [r3, r0]   @ r5 = table[ref_b2]

  adds r1, r5         @ r1 = s = table[a2]+table[ref_b2]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r5, #250       @ r5 = 250, 256 is not possible, so it is split: 250+6
  adds r5, #6         @ r5 = 256
  adds r1, r5         @ r1 = s+256

  ldrb r5, [r3, r1]   @ r5 = s = table[s+256]

  # @@@@ Checking if a2 = 0 or ref_b2 = 0, return 0; without conditional branch
  negs r1, r6         @ r1 = -a2

  @ a2 in r6 is not needed anymore, r6 can be used
  # @ asrs rd, <#imm> --> #imm: 0-31


  # fake leakage: Leaky cycles: 324cycles[154, 155]
  @ mov r4, r4

  movs r6, #32
  asrs r1, r6         @ r1 = -a2 >> 32

  ands r1, r0         @ r1 = tmp = ref_b2 & (-a2 >> 32)
  negs r1, r1         @ r1 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r1, r6         @ r1 = -tmp >> 32

  ands r5, r1         @ r5 = s & (-tmp >> 32) = (a2*ref_b2)
  
  mov  r1, r8         @ r1 = &c
  strb r5, [r1, #8]   @ r5 = (a2*ref_b2), Storing (a2*ref_b2) in c2, r1 = (a2*ref_b2)
  ## it is not possible to clear the write bus here
  eors r5, r5         @ r5 = 0, clearing (a2*ref_b2) 
  ldrb r5, [r3, #0]   @ r5 = 0 = table[0],  Clearing the read bus

@@@@@@@@@@ Computing: ci
@@@@ c0 = (a0*ref_b0)^[(a0*ref_b1)^rnd2]^[(a0*ref_b2)^rnd3]
@@@@ c1 = [(a1*ref_b0)^rnd2]^(a1*ref_b1)^[(a1*ref_b2)^rnd4]
@@@@ c2 = [(a2*ref_b0)^rnd3]^[(a2*ref_b1)^rnd4]^(a2*ref_b2) 


@@@@ r0 = ref_b2, r1 = &c, r2 = &rnd, r3 = &table,
@@@@ r4 = a0, r5 = 0, r6 = 32, r7 = ref_b1, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ c0 = (a0*ref_b0)^[(a0*ref_b1)^rnd2]^[(a0*ref_b2)^rnd3]
@@@@ (a0*ref_b1)^rnd2
@@@@ a0*ref_b1

  ldrb r1, [r3, r4]   @ r1 = table[a0]
  ldrb r5, [r3, r7]   @ r5 = table[ref_b1]

  adds r1, r5         @ r1 = s = table[a0]+table[ref_b1]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r5, #250       @ r5 = 250, 256 is not possible, so it is split: 250+6
  adds r5, #6         @ r5 = 256
  adds r1, r5         @ r1 = s+256

  ldrb r5, [r3, r1]   @ r5 = s = table[s+256]
  ldrb r3, [r2, #8]   @ r3 = rnd2

  # @@@@ Checking if a0 = 0 or ref_b1 = 0, return 0; without conditional branch
  negs r1, r4         @ r1 = -a0

  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r6, #32
  asrs r1, r6         @ r1 = -a0 >> 32

  @ ref_b1 in r7 is not needed anymore, r7 can be used
  ands r7, r1         @ r7 = tmp = ref_b1 & (-a0 >> 32)
  negs r7, r7         @ r7 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r7, r6         @ r7 = -tmp >> 32

  ands r5, r7         @ r7 = s & (-tmp >> 32)  = (a0*ref_b1)
  
  eors r5, r3         @ r5 = (a0*ref_b1)^rnd2

@@@@ r0 = ref_b2, r1 = -a0 >> 32, r2 = &rnd, r3 = rnd2,
@@@@ r4 = a0, r5 = (a0*ref_b1)^rnd2, r6 = 32, r7 = -tmp >> 32, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ c0 = (a0*ref_b0)^[(a0*ref_b1)^rnd2]^[(a0*ref_b2)^rnd3]
@@@@ (a0*ref_b2)^rnd3
@@@@ a0*ref_b2

  mov  r3, r11        @ r3 = &table
  ldrb r7, [r3, r4]   @ r7 = table[a0]
  ldrb r6, [r3, r0]   @ r6 = table[ref_b2]

  adds r7, r6         @ r7 = s = table[a0]+table[ref_b2]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r6, #250       @ r6 = 250, 256 is not possible, so it is split: 250+6
  adds r6, #6         @ r6 = 256
  adds r7, r6         @ r7 = s+256

  ldrb r6, [r3, r7]   @ r6 = s = table[s+256]
  
  ldrb r7, [r2, #12]   @ r7 = rnd3

  # @@@@ Checking if a0 = 0 or ref_b2 = 0, return 0; without conditional branch
  # negs r1, r4         @ r1 = -a0

  # # @ asrs rd, <#imm> --> #imm: 0-31
  # movs r6, #32
  # asrs r1, r6         @ r1 = -a0 >> 32
  ### From previous computation: r1 = -a0 >> 32
  @ ref_b2 in r0 is not needed anymore, r0 can be used
  ands r0, r1         @ r0 = tmp = ref_b2 & (-a0 >> 32)

  movs r4, #32        @ r4 = 32     @ for avoiding stall

  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r4         @ r0 = -tmp >> 32

  ands r6, r0         @ r6 = s & (-tmp >> 32)  = (a0*ref_b2)

  mov  r1, r8         @ r1 = &c   @ here for avoiding stall
  
  eors r6, r7         @ r6 = (a0*ref_b2)^rnd3
  

@@@@ r0 = -tmp >> 32, r1 = (-a0 >> 32), r2 = &rnd, r3 = &table,
@@@@ r4 = 32, r5 = (a0*ref_b1)^rnd2, r6 = (a0*ref_b2)^rnd3, r7 = rnd3, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ c0 = (a0*ref_b0)^[(a0*ref_b1)^rnd2]^[(a0*ref_b2)^rnd3]

  ldrb r7, [r3, #0]   @ r7 = 0, clearing rnd3 and the read bus
  ldrb r0, [r1, #0]   @ r0 = (a0*ref_b0)
  strb r7, [r1, #0]   @ r7 = 0, clearing the write bus which contains (a2*ref_b2)

  eors r0, r5         @ r0 = (a0*ref_b0)^[(a0*ref_b1)^rnd2]
  
  mov  r5, r9         @ r5 = &a  @ here for avoiding stall
  
  eors r0, r6         @ r0 = c0 = (a0*ref_b0)^[(a0*ref_b1)^rnd2]^[(a0*ref_b2)^rnd3]
  
  mov  r6, r10        @ r6 = &b  @ here for avoiding stall

  strb r0, [r1, #0]   @ r0 = c0, Storing c0, r0 = c0

  ldrb r0, [r3, #0]   @ r0 = 0, clearing c0 and the read bus which contains (a0*ref_b0)



@@@@ r0 = 0, r1 = &c, r2 = &rnd, r3 = &table,
@@@@ r4 = 32, r5 = &a, r6 = &b, r7 = 0, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c1 = [(a1*ref_b0)^rnd2]^(a1*ref_b1)^[(a1*ref_b2)^rnd4]

@@@@ (a1*ref_b0)^rnd2
@@@@ a1*ref_b0
  
@ @ # fake leakage : Leaky cycles: 324cycles[216, 217]
@ ldrb r7, [r5, #0]   @ r7 = a0

  ldrb r7, [r5, #4]   @ r7 = a1
  ldrb r0, [r6, #0]   @ r0 = ref_b0 

  ldrb r1, [r3, r7]   @ r1 = table[a1]
  ldrb r5, [r3, r0]   @ r5 = table[ref_b0]

  adds r1, r5         @ r1 = s = table[a1]+table[ref_b0]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r5, #250       @ r5 = 250, 256 is not possible, so it is split: 250+6
  adds r5, #6         @ r5 = 256
  adds r1, r5         @ r1 = s+256

  ldrb r5, [r3, r1]   @ r5 = s = table[s+256]
  ldrb r3, [r2, #8]   @ r3 = rnd2

  # @@@@ Checking if a1 = 0 or ref_b0 = 0, return 0; without conditional branch
  negs r1, r7         @ r1 = -a1

  # @ asrs rd, <#imm> --> #imm: 0-31
  # movs r4, #32
  asrs r1, r4         @ r1 = -a1 >> 32

  @ ref_b0 in r0 is not needed anymore, r0 can be used
  ands r0, r1         @ r0 = tmp = ref_b0 & (-a1 >> 32)
  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r4         @ r0 = -tmp >> 32

  ands r5, r0         @ r0 = s & (-tmp >> 32)  = (a1*ref_b0)
  
  eors r5, r3         @ r5 = (a1*ref_b0)^rnd2
  
@@@@ r0 = -tmp >> 32, r1 = -a1 >> 32, r2 = &rnd, r3 = rnd2,
@@@@ r4 = 32, r5 = (a1*ref_b0)^rnd2, r6 = &b, r7 = a1, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ c1 = [(a1*ref_b0)^rnd2]^(a1*ref_b1)^[(a1*ref_b2)^rnd4]
@@@@ (a1*ref_b2)^rnd4
@@@@ a1*ref_b2

  mov  r3, r11        @ r3 = &table
  ldrb r0, [r6, #8]   @ r0 = ref_b2 

  ldrb r6, [r3, r7]   @ r6 = table[a1]

 ### From previous computation: r1 = -a1 >> 32, so r7 = a1 is not needed any more
  ldrb r7, [r3, r0]   @ r7 = table[ref_b2]

  adds r6, r7         @ r6 = s = table[a1]+table[ref_b2]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r7, #250       @ r7 = 250, 256 is not possible, so it is split: 250+6
  adds r7, #6         @ r7 = 256
  adds r6, r7         @ r6 = s+256

  ldrb r7, [r3, r6]   @ r7 = s = table[s+256]
  
  ldrb r4, [r2, #16]   @ r4 = rnd4

  # @@@@ Checking if a1 = 0 or ref_b2 = 0, return 0; without conditional branch
  # negs r1, r4         @ r1 = -a1

  # # @ asrs rd, <#imm> --> #imm: 0-31
  # movs r6, #32
  # asrs r1, r6         @ r1 = -a1 >> 32
  ### From previous computation: r1 = -a1 >> 32
  @ ref_b2 in r0 is not needed anymore, r0 can be used
  ands r0, r1         @ r0 = tmp = ref_b2 & (-a1 >> 32)

  movs r6, #32        @ r6 = 32     @ for avoiding stall

  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r6         @ r0 = -tmp >> 32

  ands r7, r0         @ r6 = s & (-tmp >> 32)  = (a1*ref_b2)
  
  mov  r1, r8         @ r1 = &c @ here for avoiding stall

  eors r7, r4         @ r6 = (a1*ref_b2)^rnd4
  
@@@@ r0 = -tmp >> 32, r1 = (-a1 >> 32), r2 = &rnd, r3 = &table,
@@@@ r4 = rnd2, r5 = (a1*ref_b0)^rnd2, r6 = 32, r7 = (a1*ref_b2)^rnd4, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ c1 = [(a1*ref_b0)^rnd2]^(a1*ref_b1)^[(a1*ref_b2)^rnd4]

  ldrb r4, [r3, #0]   @ r4 = 0, clearing rnd2 and the read bus
  ldrb r0, [r1, #4]   @ r0 = (a1*ref_b1)
  strb r4, [r1, #4]   @ r4 = 0, clearing the write bus which contains c0

  eors r0, r5         @ r0 = [(a1*ref_b0)^rnd2]^(a1*ref_b1)
    
  mov  r5, r9         @ r5 = &a @ here for avoiding stall
  
  eors r0, r7         @ r0 = c1 =  [(a1*ref_b0)^rnd2]^(a1*ref_b1)^[(a1*ref_b2)^rnd4]
  
  mov  r7, r10        @ r7 = &b @ here for avoiding stall

  strb r0, [r1, #4]   @ r0 = c1, Storing c1, r0 = c1
  eors r0, r0
  ldrb r0, [r3, #0]   @ r0 = 0, clearing the read bus which contains (a1*ref_b1)


@@@@ r0 = 0, r1 = &c, r2 = &rnd, r3 = &table,
@@@@ r4 = 0, r5 = &a, r6 = 32, r7 = &b, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ c2 = [(a2*ref_b0)^rnd3]^[(a2*ref_b1)^rnd4]^(a2*ref_b2) 

@@@@ (a2*ref_b0)^rnd3
@@@@ a2*ref_b0
@ # fake leakage: Leaky cycles: 324cycles[265, 266]
@ ldrb r4, [r5, #0]   @ r4 = a0
@ ldrb r4, [r5, #4]   @ r4 = a1

  ldrb r4, [r5, #8]   @ r4 = a2
  ldrb r0, [r7, #0]   @ r0 = ref_b0 

  ldrb r1, [r3, r4]   @ r1 = table[a2]
  ldrb r5, [r3, r0]   @ r5 = table[ref_b0]

  adds r1, r5         @ r1 = s = table[a2]+table[ref_b0]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r5, #250       @ r5 = 250, 256 is not possible, so it is split: 250+6
  adds r5, #6         @ r5 = 256
  adds r1, r5         @ r1 = s+256

  ldrb r5, [r3, r1]   @ r5 = s = table[s+256]
  ldrb r3, [r2, #12]   @ r3 = rnd3

  # @@@@ Checking if a2 = 0 or ref_b0 = 0, return 0; without conditional branch
  negs r1, r4         @ r1 = -a2

  # @ asrs rd, <#imm> --> #imm: 0-31
  # movs r6, #32
  asrs r1, r6         @ r1 = -a2 >> 32

  @ ref_b0 in r0 is not needed anymore, r0 can be used
  ands r0, r1         @ r0 = tmp = ref_b0 & (-a2 >> 32)
  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r6         @ r0 = -tmp >> 32

  ands r5, r0         @ r0 = s & (-tmp >> 32)  = (a2*ref_b0)
  
  eors r5, r3         @ r5 = (a2*ref_b0)^rnd3

@@@@ r0 = -tmp >> 32, r1 = -a2 >> 32, r2 = &rnd, r3 = rnd3,
@@@@ r4 = a2, r5 = (a2*ref_b0)^rnd3, r6 = 32, r7 = &b, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ c2 = [(a2*ref_b0)^rnd3]^[(a2*ref_b1)^rnd4]^(a2*ref_b2) 
@@@@ (a2*ref_b1)^rnd4
@@@@ a2*ref_b1

  mov  r3, r11        @ r3 = &table

  ldrb r0, [r7, #4]   @ r0 = ref_b1

  ldrb r7, [r3, r4]   @ r7 = table[a2]

 ### From previous computation: r1 = -a2 >> 32, so r4 = a2 is not needed any more
  ldrb r4, [r3, r0]   @ r4 = table[ref_b1]

  adds r7, r4         @ r7 = s = table[a2]+table[ref_b1]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r4, #250       @ r4 = 250, 256 is not possible, so it is split: 250+6
  adds r4, #6         @ r4 = 256
  adds r7, r4         @ r7 = s+256

  ldrb r4, [r3, r7]   @ r4 = s = table[s+256]
  
  ldrb r6, [r2, #16]   @ r6 = rnd4

  # @@@@ Checking if a2 = 0 or ref_b1 = 0, return 0; without conditional branch
  # negs r1, r4         @ r1 = -a2

  # # @ asrs rd, <#imm> --> #imm: 0-31
  # movs r7, #32
  # asrs r1, r7         @ r1 = -a2 >> 32
  ### From previous computation: r1 = -a2 >> 32
  @ ref_b1 in r0 is not needed anymore, r0 can be used
  ands r0, r1         @ r0 = tmp = ref_b1 & (-a2 >> 32)

  movs r7, #32        @ r7 = 32     @ here for avoiding stall

  negs r2, r0         @ r2 = -tmp   @ &rnd is not needed any more

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r2, r7         @ r2 = -tmp >> 32

  ands r4, r2         @ r4 = s & (-tmp >> 32)  = (a2*ref_b1)

  mov  r1, r8         @ r1 = &c  @ here for avoiding stall
  
  eors r4, r6         @ r4 = (a2*ref_b1)^rnd4


@@@@ r0 =  ref_b1 & (-a2 >> 32), r1 = -a2 >> 32, r2 = -tmp >> 32, r3 = &table,
@@@@ r4 = (a2*ref_b1)^rnd4, r5 = (a2*ref_b0)^rnd3, r6 = rnd2, r7 = 32, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ c2 = [(a2*ref_b0)^rnd3]^[(a2*ref_b1)^rnd4]^(a2*ref_b2) 

  ldrb r6, [r3, #0]   @ r6 = 0, clearing rnd2 and the read bus
  ldrb r0, [r1, #8]   @ r0 = (a2*ref_b2)

  eors r5, r4         @ r0 = [(a2*ref_b0)^rnd3]^[(a2*ref_b1)^rnd4]
      
  eors r0, r5         @ r0 = c2 = [(a2*ref_b0)^rnd3]^[(a2*ref_b1)^rnd4]^(a2*ref_b2) 
  
  strb r6, [r1, #8]   @ r6 = 0, clearing the write bus which contains c1
  strb r0, [r1, #8]   @ r0 = c2, Storing c2, r0 = c2

  
  nop
  nop
  nop
  nop


 @ Trigger
#########################################################################
# Seperating instructions related to main function and trigger, as there are pipeline stages 
  @ Trigger
  @ scale.c: LPC13XX_GPIO1->GPIODATA &= ~( 0x1 <<  0 ) ; // initialise SCALE_GPIO_PIN_TRG = 0
  @ SCALE_GPIO_PIN_TRG in scale board: pin33: PIO1_0
  @ PIO1_0: https://www.digikey.pl/htmldatasheets/production/660585/0/0/1/lpc1311fhn33-551.html : 9.4 Register description
  @ baseaddress: 0x50010000, offset: 0x3ffc, baseaddress: 0x50010000, offset: 0x3ffc
  @ address: 0x5001ffc; producing this value: needs several instructions:
  @ https://developer.arm.com/documentation/den0042/a/Unified-Assembly-Language-Instructions/Instruction-set-basics/Constant-and-immediate-values

  @ Start of trigger
  ldr  r4, =0x50013ffc
  movs r5,#1
  ldr  r6, [r4, #0]  @ r6 = 0 : SCALE_GPIO_PIN_TRG = 0
  # test: str  r6, [r3, #0]  @ r6 = 0xfc0f0000
  eors r5, r6  @ r5 = 1 @ Start trigger: SCALE_GPIO_PIN_TRG = 1
  str  r5, [r4, #0]
  nop
  nop
  nop
  nop
  @ End of trigger
  str  r6, [r4, #0] @ End trigger: r6 = 0 : SCALE_GPIO_PIN_TRG = 0

  pop  {r4-r7}
  mov   r8, r4
  mov   r9, r5
  mov   r10, r6
  mov   r11, r7
  pop   {r4-r7}
  pop  {pc}
  .endfunc 

.end





