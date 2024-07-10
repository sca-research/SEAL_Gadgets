@ Bbpp_opt_3_V1

@  ^: xor; +: arithmathic addition; x & y: and operation; *: Galois field multiplication; &x: the address of x
@ a = a0^a1^a2, b = b0^b1^b2, c = c0^c1^c2, a*b = c, random numbers: rnd0, rnd1, rnd2

@@@@ c0 = (a0*b0)^rnd0^(a0*b2)^(a2*b0)
@@@@ c1 = (a1*b1)^rnd1^(a0*b1)^(a1*b0)
@@@@ c2 = (a2*b2)^rnd0^rnd1^(a1*b2)^(a2*b1)

# For this implementation, we avoide those leakages found in other gadgets
  .syntax unified
  .text
  .thumb
  
  .extern table       @@@@ table is used for GFMULT (ai*bj multiplications)
  
@@@@ extern void Bbpp_opt_3(uint8_t* inputa: addres: r0, uint8_t* inputb: address: r1, uint8_t* rnd: address: r2, uint8_t* output: address: r3);
@inputa: a0, a1, a2, inputb: b0, b1, b2, rnd: rnd0, rnd1, output: c: c0, c1, c2

.global Bbpp_opt_3
.func Bbpp_opt_3
Bbpp_opt_3:

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

@@@@@ Loading arguments @@@@@@@@@@@@
  ldrb r3, [r0, #0]  @ r3 = a0; r0 = &a, r1 = &b, r2 = &rnd, r4 = &table
  ldrb r5, [r1, #0]  @ r5 = b0; r0 = &a, r1 = &b, r2 = &rnd, r4 = &table
  ldrb r6, [r0, #4]  @ r6 = a1; r0 = &a, r1 = &b, r2 = &rnd, r4 = &table
  ldrb r7, [r1, #4]  @ r7 = b1; r0 = &a, r1 = &b, r2 = &rnd, r4 = &table

@@@@@@@@@@ Computing: ai*bi

@@@@ r0 = &a, r1 = &b, r2 = &rnd, r3 = a0,
@@@@ r4 = &table, r5 = b0, r6 = a1, r7 = b1, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ a0*b0

  ldrb r0, [r4, r3]   @ r0 = table[a0]
  ldrb r1, [r4, r5]   @ r1 = table[b0]

  adds r0, r1         @ r0 = s = table[a0]+table[b0]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r1, #250       @ r1 = 250, 256 is not possible, so it is split: 250+6
  adds r1, #6         @ r1 = 256
  adds r0, r1         @ r0 = s+256

  ldrb r1, [r4, r0]   @ r1 = s = table[s+256]

  # @@@@ Checking if a0 = 0 or b0 = 0, return 0; without conditional branch
  negs r0, r3         @ r0 = -a0 hex(256-dec(a0))

  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r4, #32        @ r4 = #32
  asrs r0, r4         @ r0 = -a0 >> 32

  ands r0, r5         @ r0 = tmp = b0 & (-a0 >> 32)
  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r4         @ r0 = -tmp >> 32

  ands r1, r0         @ r1 = s & (-tmp >> 32) = (a0*b0)

  mov  r0, r8         @ r0 = &c
  mov  r4, r11        @ r4 = &table    @ here for avoiding stall
  strb r1, [r0, #0]   @ r1 = (a0*b0), Storing (a0*b0) in &c+#0, r1 = (a0*b0)
  
  eors r1, r1         @ r1 = 0, clearing (a0*b0) @ here to avoid stall

  strb r0, [r0, #4]   @ clearing the write bus

### we need to clear the read bus and also reg1, istead of using two instructions
  ## eors r1, r1         @ r1 = 0, clearing (a0*b0) 
  ## ldrb rx, [r4, #0]   @ rx = 0 = table[0],  Clearing the read bus
### just we can use one as:
  # ldrb r1, [r4, #0]   @ r1 = 0 = table[0],  Clearing the read bus and also reg1
### The one instruction, is not enough, we should use the both instruction,
### because the first operand in one-inst can cause leakage with the next inst
  # ex: r1 and r0, two shares from the same family
    # ldrb r1, [r4, #0]   @ r1 = 0 = table[0],  Clearing the read bus and also reg5
    # ldrb r0, [r4, r6]   @ r0 = table[a1]
  # eors r1, r1         @ r1 = 0, clearing (a0*b0) @ above to avoid stall
  ldrb r1, [r4, #0]   @ rx = 0 = table[0],  Clearing the read bus

@@@@ r0 = &c, r1 = 0, r2 = &rnd, r3 = a0,
@@@@ r4 = &table, r5 = b0, r6 = a1, r7 = b1, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ a1*b1

  ldrb r0, [r4, r6]   @ r0 = table[a1]
  ldrb r1, [r4, r7]   @ r1 = table[b1]

  adds r0, r1         @ r0 = s = table[a1]+table[b1]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r1, #250       @ r1 = 250, 256 is not possible, so it is split: 250+6
  adds r1, #6         @ r1 = 256
  adds r0, r1         @ r0 = s+256

  ldrb r1, [r4, r0]   @ r1 = s = table[s+256]


  # @@@@ Checking if a1 = 0 or b1 = 0, return 0; without conditional branch
  negs r0, r6         @ r0 = -a1

  # @ a1 in r6 is not needed anymore, r6 can be used
  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r6, #32
  asrs r0, r6         @ r0 = -a1 >> 32

  # @ b1 in r7 is not needed any more
  ands r7, r0         @ r7 = tmp = b1 & (-a1 >> 32)
  negs r7, r7         @ r7 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r7, r6         @ r7 = -tmp >> 32

  ands r1, r7         @ r1 = s & (-tmp >> 32) = (a1*b1)
  
  mov  r7, r8         @ r7 = &c
  # mov  r4, r11        @ r4 = &table
  strb r1, [r7, #4]   @ r1 = (a1*b1), Storing (a1*b1) in &c+#4, r1 = (a1*b1)
  strb r7, [r7, #8]   @ clearing the write bus

### we need to clear the read bus and also reg1, istead of using two instructions, just we can use one as:
  # eors r1, r1         @ r1 = 0, clearing (a1*b1) 
  # ldrb rx, [r4, #0]   @ rx = 0 = table[0],  Clearing the read bus
  ldrb r1, [r4, #0]   @ r1 = 0 = table[0],  Clearing the read bus and also reg1

@@@@ r0 = &c, r1 = 0, r2 = &rnd, r3 = a0,
@@@@ r4 = &table, r5 = b0, r6 = 32, r7 = &c, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ a2*b2

  mov  r7, r9         @ r7 = &a
  mov  r1, r10        @ r1 = &b

  ldrb r6, [r7, #8]   @ r6 = a2
  ldrb r0, [r1, #8]   @ r0 = b2
  
  ldrb r1, [r4, r6]   @ r1 = table[a2]
  ldrb r7, [r4, r0]   @ r7 = table[b2]

  adds r1, r7         @ r1 = s = table[a2]+table[b2]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r7, #250       @ r7 = 250, 256 is not possible, so it is split: 250+6
  adds r7, #6         @ r7 = 256
  adds r1, r7         @ r1 = s+256

  ldrb r7, [r4, r1]   @ r7 = s = table[s+256]

  # @@@@ Checking if a2 = 0 or b2 = 0, return 0; without conditional branch
  negs r1, r6         @ r1 = -a2

  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r4, #32        @ r4 = 32
  asrs r1, r4         @ r1 = -a2 >> 32

  ands r1, r0         @ r1 = tmp = b2 & (-a2 >> 32)
  negs r1, r1         @ r1 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r1, r4         @ r1 = -tmp >> 32

  ands r7, r1         @ r7 = s & (-tmp >> 32) = (a2*b2)
  
  mov  r1, r8         @ r1 = &c
  mov  r4, r11        @ r4 = &table   @ here for avoiding stall
  strb r7, [r1, #8]   @ r7 = (a2*b2), Storing (a2*b2) in c2, r1 = (a2*b2)
  ## it is not possible to clear the write bus here

### we need to clear the read bus and also reg1, istead of using two instructions
  ## eors r7, r7         @ r7 = 0, clearing (a2*b2) 
  ## ldrb rx, [r4, #0]   @ rx = 0 = table[0],  Clearing the read bus
### just we can use one as:
  # ldrb r7, [r4, #0]   @ r7 = 0 = table[0],  Clearing the read bus and also reg1
### The one instruction, is not enough, we should use the both instruction,
### because the first operand in one-inst can cause leakage with the next inst
  # ex: r7 and r1, two shares from the same family
    # ldrb r7, [r4, #0]   @ r1 = 0 = table[0],  Clearing the read bus and also reg5
    # ldrb r1, [r4, r3]   @ r0 = table[a0]
  eors r7, r7         @ r7 = 0, clearing (a2*b2)
  ldrb r7, [r4, #0]   @ r7 = 0 = table[0],  Clearing the read bus and also reg5

@@@@@@@@@@ Computing: ci
@@@@ c0 = (a0*b0)^rnd0^(a0*b2)^(a2*b0)
@@@@ c1 = (a1*b1)^rnd1^(a0*b1)^(a1*b0)
@@@@ c2 = (a2*b2)^rnd0^rnd1^(a1*b2)^(a2*b1)

@@@@ r0 = b2, r1 = &c, r2 = &rnd, r3 = a0,
@@@@ r4 = &table, r5 = b0, r6 = a2, r7 = 0, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^rnd0^(a0*b2)^(a2*b0)

@@@@ a0*b2

  ldrb r1, [r4, r3]   @ r1 = table[a0]
  ldrb r7, [r4, r0]   @ r7 = table[b2]

  adds r1, r7         @ r1 = s = table[a0]+table[b2]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r7, #250       @ r7 = 250, 256 is not possible, so it is split: 250+6
  adds r7, #6         @ r7 = 256
  adds r1, r7         @ r1 = s+256

  ldrb r7, [r4, r1]   @ r7 = s = table[s+256]

  # @@@@ Checking if a0 = 0 or b2 = 0, return 0; without conditional branch
  negs r1, r3         @ r1 = -a0

  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r4, #32        @ r4 = 32
  asrs r1, r4         @ r1 = -a0 >> 32

# @ b2 in r0 is not needed anymore, r0 can be used 
  ands r0, r1         @ r1 = tmp = b2 & (-a0 >> 32)
  negs r0, r0         @ r1 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r4         @ r0 = -tmp >> 32
  mov  r4, r11        @ r4 = &table    @ here for avoiding stall
  ands r7, r0         @ r7 = s & (-tmp >> 32) = (a0*b2)

@@@@ r0 = -tmp >> 32, r1 = -a0 >> 32, r2 = &rnd, r3 = a0,
@@@@ r4 = &table, r5 = b0, r6 = a2, r7 = (a0*b2), 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^rnd0^(a0*b2)^(a2*b0)

@@@@ a2*b0
## Possible leakage ###########################################################
  ## ldrb r7, [r4, r1]   @ r7 = s = table[s+256] = a0*b2  (the read bus)
  ## .
  ## .
  ## .
  ## ldrb r1, [r4, r6]   @ r1 = table[a2]

  ldrb r0, [r4, #0]   @ r0 = table[0] = 0

  ldrb r1, [r4, r6]   @ r1 = table[a2]
  ldrb r0, [r4, r5]   @ r0 = table[b0]

  adds r1, r0         @ r1 = s = table[a2]+table[b0]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r0, #250       @ r0 = 250, 256 is not possible, so it is split: 250+6
  adds r0, #6         @ r0 = 256
  adds r1, r0         @ r1 = s+256

  ldrb r0, [r4, r1]   @ r0 = s = table[s+256]
  
  # @@@@ Checking if a2 = 0 or b0 = 0, return 0; without conditional branch
  negs r1, r6         @ r1 = -a2

  # @ a2 in r6 is not needed anymore, r6 can be used
  # # @ asrs rd, <#imm> --> #imm: 0-31
  movs r6, #32        @ r6 = 32
  asrs r1, r6         @ r1 = -a2 >> 32

  ands r1, r5         @ r1 = tmp = b0 & (-a2 >> 32)
  negs r1, r1         @ r1 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r1, r6         @ r1 = -tmp >> 32

  ands r0, r1         @ r0 = s & (-tmp >> 32)  = (a2*b0)

@@@@ r0 = (a2*b0), r1 =  -tmp >> 32, r2 = &rnd, r3 = a0,
@@@@ r4 = &table, r5 = b0, r6 = 32, r7 = (a0*b2), 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^rnd0^(a0*b2)^(a2*b0)
  
  mov  r6, r8         @ r6 = &c
  ldrb r1, [r2, #0]   @ r1 = rnd0 and also clearing the read bus
  ldrb r4, [r6, #0]   @ r4 = (a0*b0)
  strb r6, [r6, #0]   @ r6 = &c, clearing the write bus which contains (a0*b0)
  

# uElmo shows for (sh0, sh2) 
  @ eors r4, r1         @ r4 = (a0*b0)^rnd0
  @ mov  r1, r9         @ r1 = &a , here for avoiding stall
  @ eors r7, r4         @ r7 = (a0*b0)^rnd0^(a0*b2)
  @ mov  r4, r11        @ r4 = &table , here for avoiding stall
  @ eors r0, r7         @ r0 = c0 = (a0*b0)^rnd0^(a0*b2)^(a2*b0)
  @ mov  r7, r10        @ r7 = &b , here for avoiding stall
# To remove the leakage: 

  eors r4, r1         @ r4 = (a0*b0)^rnd0
eors r1, r1           @ Adding extra instruction, r1 = 0
  @ mov  r1, r9         @ r1 = &a , here for avoiding stall
  eors r7, r4         @ r7 = (a0*b0)^rnd0^(a0*b2)
eors r1, r1           @ Adding extra instruction, r1 = 0
  @ mov  r4, r11        @ r4 = &table , here for avoiding stall
  eors r0, r7         @ r0 = c0 = (a0*b0)^rnd0^(a0*b2)^(a2*b0)
  mov  r7, r10        @ r7 = &b , here for avoiding stall
mov  r4, r11        @ r4 = &table , here for avoiding stall
mov  r1, r9         @ r1 = &a , here for avoiding stall

  strb r0, [r6, #0]   @ r0 = c0, Storing c0, r0 = c0

  

### we need to clear the read bus and also reg0, istead of using two instructions
  ## eors r0, r0         @ r0 = 0, clearing c0
  ## ldrb rx, [r4, #0]   @ rx = 0 = table[0],  Clearing the read bus
### just we can use one as:
  # ldrb r0, [r4, #0]   @ r0 = 0 = table[0],  Clearing the read bus and also reg1
### The one instruction, is not enough, we should use the both instruction,
### because the first operand in one-inst can cause leakage with the next inst
  # ex: r0 and r0, two shares from the same family
    # ldrb r0, [r4, #0]   @ r0 = 0 = table[0],  Clearing the read bus and also reg5
    # ldrb r6, [r1, #4]   @ r6 = a1
  eors r0, r0         @ r0 = 0, clearing C0 from r0
  ldrb r0, [r4, #0]   @ r0 = 0, clearing c0 and the read bus which contains (a0*b0)


@@@@ r0 = 0, r1 = &a, r2 = &rnd, r3 = a0,
@@@@ r4 = &table, r5 = b0, r6 = &c, r7 = &b, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c1 = (a1*b1)^rnd1^(a0*b1)^(a1*b0)

@@@@ a0*b1

  ldrb r6, [r1, #4]   @ r6 = a1   @ here to avoid stall
  ldrb r0, [r7, #4]   @ r0 = b1 

  ldrb r1, [r4, r3]   @ r1 = table[a0]
  ldrb r7, [r4, r0]   @ r7 = table[b1]

# trick: cycles (from trigger):  [102, 103]

  adds r1, r7         @ r1 = s = table[a0]+table[b1]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r7, #250       @ r7 = 250, 256 is not possible, so it is split: 250+6
  adds r7, #6         @ r7 = 256
  adds r1, r7         @ r1 = s+256

  ldrb r7, [r4, r1]   @ r7 = s = table[s+256]

  # @@@@ Checking if a0 = 0 or b1 = 0, return 0; without conditional branch
  negs r1, r3         @ r1 = -a0


# trick: cycles (from trigger): [94, 95]


  # @ a0 in r3 is not needed anymore, r3 can be used
  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r3, #32        @ r3 = 32
  asrs r1, r3         @ r1 = -a0 >> 32

  ands r1, r0         @ r1 = tmp = b1 & (-a0 >> 32)
  negs r1, r1         @ r1 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r1, r3         @ r1 = -tmp >> 32
  # mov  r4, r11        @ r4 = &table    @ here for avoiding stall
  ands r7, r1         @ r7 = s & (-tmp >> 32) = (a0*b1)

# trick: cycles (from trigger): [88, 89]

@@@@ r0 = b1, r1 = -tmp >> 32, r2 = &rnd, r3 = 32,
@@@@ r4 = &table, r5 = b0, r6 = a1, r7 = (a0*b1), 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c1 = (a1*b1)^rnd1^(a0*b1)^(a1*b0)

@@@@ a1*b0

## Possible leakage ###########################################################
  ## ldrb r7, [r4, r1]   @ r7 = s = table[s+256] = a0*b1  (the read bus)
  ## .
  ## .
  ## .
  ## ldrb r1, [r4, r6]   @ r1 = table[a1]

  ldrb r3, [r4, #0]   @ r1 = table[0] = 0

  ldrb r1, [r4, r6]   @ r1 = table[a1]
  ldrb r3, [r4, r5]   @ r3 = table[b0]

  adds r1, r3         @ r1 = s = table[a1]+table[b0]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r3, #250       @ r3 = 250, 256 is not possible, so it is split: 250+6
  adds r3, #6         @ r3 = 256
  adds r1, r3         @ r1 = s+256

  ldrb r3, [r4, r1]   @ r3 = s = table[s+256]

# trick: cycles (from trigger): [77, 78]

  # @@@@ Checking if a1 = 0 or b0 = 0, return 0; without conditional branch
  negs r1, r6         @ r1 = -a1

  # # @ asrs rd, <#imm> --> #imm: 0-31
  movs r4, #32        @ r4 = 32
  asrs r1, r4         @ r1 = -a1 >> 32

  # @ b0 in r5 is not needed anymore, r5 can be used
  ands r5, r1         @ r5 = tmp = b0 & (-a1 >> 32)
  negs r5, r5         @ r5 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r5, r4         @ r5 = -tmp >> 32
  ands r3, r5         @ r3 = s & (-tmp >> 32)  = (a1*b0)
  
# uElmo shows Glitchy leakage for (sh0, sh1) adding  eors r4, r4 to remove the leakage
eors r4, r4   @ r4 = 0

@@@@ r0 = b1, r1 = -a1 >> 32, r2 = &rnd, r3 = (a1*b0),
@@@@ r4 = 32, r5 = -tmp >> 32, r6 = a1, r7 = (a0*b1), 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c1 = (a1*b1)^rnd1^(a0*b1)^(a1*b0)

  mov  r5, r8         @ r5 = &c
  ldrb r1, [r2, #4]   @ r1 = rnd1 and also clearing the read bus
# fake leakage: cycles (from trigger): [64, 65, 66, 67]
  ldrb r4, [r5, #4]   @ r4 = (a1*b1)
  strb r5, [r5, #4]   @ r5 = &c, clearing the write bus which contains (a0*b0)
  
#   ------------------------------------------------------------------
# uElmo shows Glitchy leakage for (sh0, sh1) reordering instructions to remove the leakage
#   eors r4, r1         @ r4 = (a1*b1)^rnd1
#   mov  r1, r9         @ r1 = &a , here for avoiding stall
#   eors r7, r4         @ r7 = (a1*b1)^rnd1^(a0*b1)
#   mov  r4, r11        @ r4 = &table , here for avoiding stall
#   eors r3, r7         @ r3 = c1 = (a1*b1)^rnd1^(a0*b1)^(a1*b0)
#   mov  r7, r10        @ r7 = &b , here for avoiding stall
# ------------------------------------------------------------------
#   leakage, because mov does not update rs1:
#   eors r4, r1         @ r4 = (a1*b1)^rnd1
#   mov  r1, r9         @ r1 = &a , here for avoiding stall
#   eors r7, r4         @ r7 = (a1*b1)^rnd1^(a0*b1)

#  leakage, because mov does not update rs1:
#   eors r7, r4         @ r7 = (a1*b1)^rnd1^(a0*b1)
#   mov  r4, r11        @ r4 = &table , here for avoiding stall
#   eors r3, r7         @ r3 = c1 = (a1*b1)^rnd1^(a0*b1)^(a1*b0)  
#   ------------------------------------------------------------------

  eors r4, r1         @ r4 = (a1*b1)^rnd1
  eors r1, r1         @ r1 = 0, removing rnd1, updating the rs1 as it is not updated in mov instruction 
  eors r7, r4         @ r7 = (a1*b1)^rnd1^(a0*b1)
  eors r4, r4         @ r4 = 0, removing rnd1, updating the rs1 as it is not updated in mov instruction 
  eors r3, r7         @ r3 = c1 = (a1*b1)^rnd1^(a0*b1)^(a1*b0)
  mov  r1, r9         @ r1 = &a , here for avoiding stall
  mov  r4, r11        @ r4 = &table , here for avoiding stall
  mov  r7, r10        @ r7 = &b , here for avoiding stall
  
  strb r3, [r5, #4]   @ r3 = c1, Storing c1, r3 = c1

### we need to clear the read bus and also reg3, istead of using two instructions
  ## eors r3, r3         @ r3 = 0, clearing c1
  ## ldrb rx, [r4, #0]   @ rx = 0 = table[0],  Clearing the read bus
### just we can use one as:
  # ldrb r3, [r4, #0]   @ r3 = 0 = table[0],  Clearing the read bus and also reg3
### The one instruction, is not enough, we should use the both instruction,
### because the first operand in one-inst can cause leakage with the next inst
  # ex: r3 and r3, two shares from the same family
    # ldrb r3, [r4, #0]   @ r = 0 = table[0],  Clearing the read bus and also reg3
    # ldrb r5, [r1, #8]   @ r5 = a2
  eors r3, r3         @ r3 = 0, clearing C1 from r3
  ldrb r3, [r4, #0]   @ r3 = 0, clearing c1 and the read bus which contains (a1*b1)


@@@@ r0 = b1, r1 = &a, r2 = &rnd, r3 = 0,
@@@@ r4 = &table, r5 = &c, r6 = a1, r7 = &b, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c2 = (a2*b2)^rnd0^rnd1^(a1*b2)^(a2*b1)

@@@@ a1*b2

# trick: cycles (from trigger): [54, 55, 56]

  ldrb r3, [r1, #8]   @ r3 = a2   @ here to avoid stall
  ldrb r5, [r7, #8]   @ r5 = b2 
# leakage for a1, a2, real traces
  ldrb r1, [r4, r6]   @ r1 = table[a1]
  ldrb r7, [r4, r5]   @ r7 = table[b2]

  adds r1, r7         @ r1 = s = table[a1]+table[b2]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r7, #250       @ r7 = 250, 256 is not possible, so it is split: 250+6
  adds r7, #6         @ r7 = 256
  adds r1, r7         @ r1 = s+256

  ldrb r7, [r4, r1]   @ r7 = s = table[s+256]

  # @@@@ Checking if a1 = 0 or b2 = 0, return 0; without conditional branch
  negs r1, r6         @ r1 = -a1

  # @ a1 in r6 is not needed anymore, r6 can be used
  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r6, #32        @ r6 = 32
  asrs r1, r6         @ r1 = -a1 >> 32

  # @ b2 in r5 is not needed anymore, r5 can be used
  ands r5, r1         @ r1 = tmp = b2 & (-a1 >> 32)
  negs r5, r5         @ r1 = -tmp


# trick: cycles (from trigger): [40, 41, 42]

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r5, r6         @ r1 = -tmp >> 32
  # mov  r4, r11        @ r4 = &table    @ here for avoiding stall
  ands r7, r5         @ r7 = s & (-tmp >> 32) = (a1*b2)


@@@@ r0 = b1, r1 = -a1 >> 32, r2 = &rnd, r3 = a2,
@@@@ r4 = &table, r5 = -tmp >> 32, r6 = 32, r7 = (a1*b2), 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c2 = (a2*b2)^rnd0^rnd1^(a1*b2)^(a2*b1)

@@@@ a2*b1

## Possible leakage ###########################################################
  ## ldrb r7, [r4, r1]   @ r7 = s = table[s+256] = a1*b2  (the read bus)
  ## .
  ## .
  ## .
  ## ldrb r1, [r4, r3]   @ r1 = table[a2]
  ldrb r5, [r4, #0]   @ r1 = table[0] = 0

# trick: cycles (from trigger): [39, 40]
# leakage for b1, b2, real traces
  ldrb r1, [r4, r3]   @ r1 = table[a2]
  ldrb r5, [r4, r0]   @ r5 = table[b1]

  adds r1, r5         @ r1 = s = table[a2]+table[b1]

#  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r5, #250       @ r5 = 250, 256 is not possible, so it is split: 250+6
  adds r5, #6         @ r5 = 256
  adds r1, r5         @ r1 = s+256

  ldrb r5, [r4, r1]   @ r5 = s = table[s+256]
  
  # @@@@ Checking if a2 = 0 or b1 = 0, return 0; without conditional branch
  negs r1, r3         @ r1 = -a2

  # # @ asrs rd, <#imm> --> #imm: 0-31
  # movs r6, #32        @ r6 = 32
  asrs r1, r6         @ r1 = -a2 >> 32

  # @ b1 in r0 is not needed anymore, r0 can be used
  ands r0, r1         @ r0 = tmp = b1 & (-a2 >> 32)

  # @ a2 in r3 is not needed anymore, r3 can be used
  negs r3, r0         @ r3 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r3, r6         @ r3 = -tmp >> 32
  mov  r0, r8         @ r0 = &c       @ here to avoid stall
  ands r5, r3         @ r5 = s & (-tmp >> 32)  = (a2*b1)



@@@@ r0 = &c, r1 = -a2 >> 32, r2 = &rnd, r3 = -tmp >> 32,
@@@@ r4 = &table, r5 = (a2*b1), r6 = 32, r7 = (a1*b2), 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c2 = (a2*b2)^rnd0^rnd1^(a1*b2)^(a2*b1)

@ # # uElmo shows 3 kinds of leakages here for (sh0, sh2)
@ # Neighbouring Reg 4 XOR Reg 5
@ # Decoding port 0 HD
@ # Pipeline Reg 1 HD

@   ldrb r1, [r2, #0]   @ r1 = rnd0 and also clearing the read bus
@   ldrb r4, [r0, #8]   @ r4 = (a2*b2)
@   ldrb r3, [r2, #4]   @ r3 = rnd1 and also clearing the read bus
@   strb r6, [r0, #8]   @ r6 = 32, clearing the write bus which contains (a2*b2)
  
@   eors r4, r1         @ r4 = (a2*b2)^rnd0
@   eors r4, r3         @ r4 = (a2*b2)^rnd0^rnd1
@   eors r7, r4         @ r7 = (a2*b2)^rnd0^rnd1^(a1*b2)
@   eors r5, r7         @ r5 = c2 = (a2*b2)^rnd0^rnd1^(a1*b2)^(a2*b1)
@   strb r5, [r0, #8]   @ r5 = c2, Storing c2, r5 = c2

@ @ #######################################################################################
# swapping r3 and r4
  ldrb r1, [r2, #0]   @ r1 = rnd0 and also clearing the read bus
  ldrb r3, [r0, #8]   @ r3 = (a2*b2)
  ldrb r4, [r2, #4]   @ r4 = rnd1 and also clearing the read bus
  strb r6, [r0, #8]   @ r6 = 32, clearing the write bus which contains (a2*b2)
  
  eors r3, r1         @ r3 = (a2*b2)^rnd0
eors r6, r6  
  eors r3, r4         @ r3 = (a2*b2)^rnd0^rnd1
eors r6, r6
  eors r7, r3         @ r7 = (a2*b2)^rnd0^rnd1^(a1*b2)
eors r6, r6
  eors r5, r7         @ r5 = c2 = (a2*b2)^rnd0^rnd1^(a1*b2)^(a2*b1)
  strb r5, [r0, #8]   @ r5 = c2, Storing c2, r5 = c2




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





