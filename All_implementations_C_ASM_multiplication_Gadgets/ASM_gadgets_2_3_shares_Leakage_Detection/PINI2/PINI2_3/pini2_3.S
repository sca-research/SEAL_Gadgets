@ PINI2_3_V0

@ a = a0^a1^a2, b = b0^b1^b2, c = c0^c1^c1, a * b = c, random numbers: rnd0, rnd1, rnd2
@  ^: xor; +: arithmathic addition; x & y: and operation; *: Galois field multiplication; &x: the address of x


.syntax unified
  .text
  .thumb
  .extern table       @@@@ table is used for GFMULT (ai*bj multiplications)

@@@@ extern void Pini2_3(uint8_t* inputa: addres: r0, uint8_t* inputb: address: r1, uint8_t* rnd: address: r2, uint8_t* output: address: r3);
@inputa: a0, a1, a2, inputb: b0, b1, b2, 
@rnd: (s0) rnd0, (s1) rnd1, (s2) rnd2, (r02) rnd3, (r1) rnd4, (r12) rnd5, output: c: c0, c1, c2
@@@@ extern void Pini2_3(r0, r1, r2, r3);

@ s0, s1, s2, r02, r12, r1

@ s01= s0^s1 = rnd0^rnd1, 
@ p0_01= a0*s01,
@ p1_01= a0*(b1^s01),
@ p2_01= b0*s01,
@ p3_01= b0*(a1^s01),

@ s02= s0^s2 = rnd0^rnd2,
@ p0_02= a0*s02,
@ p1_02= a0*(b2^s02),
@ p2_02= b0*s02,
@ p3_02= b0*(a2^s02),

@ s12= s1^s2= rnd1^rnd2,
@ p0_12= a1*s12,
@ p1_12= a1*(b2^s12),
@ p2_12= b1*s12,
@ p3_12= b1*(a2^s12),
@ -------------------------------------------------------------
@@@@ c0 = (a0*b0)^(r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)
@ c0 = (a0*b0)^[rnd3^(a0*s02)^(a0*(b2^s02))^(b0*s02)^(b0*(a2^s02))^rnd4^(a0*s01)^(a0*(b1^s01))^(b0*s01)^(b0*(a1^s01))
@@@@ c1 = [(a1*b1)^(r12(=rnd5)^p0_12^p1_12^p2_12^p3_12)]^r1(=rnd4)
@@@@ c2 = [(a2*b2)^r12(=rnd5))]^r02(=rnd3)


.global Pini2_3
.func Pini2_3
Pini2_3:

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

#@@@@@ Saving r2 (the address of the input rnd)
#  mov  r11, r2       @ r11 = &rnd

@@@@@ Saving the address of the "table"
  ldr  r4, =table    @ r4 = &table, The address of the "table", for ai*bj multiplications
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
  @ b0 in r5 is not needed anymore
  mov  r5, r11        @ r5 = &table    @ here for avoiding stall
  strb r1, [r0, #0]   @ r1 = (a0*b0), Storing (a0*b0) in &c+#0, r1 = (a0*b0)
  
  eors r1, r1         @ r1 = 0, clearing (a0*b0) @ here to avoid stall

  strb r0, [r0, #4]   @ clearing the write bus

### we need to clear the read bus and also reg1, istead of using two instructions
  ## eors r1, r1         @ r1 = 0, clearing (a0*b0) 
  ## ldrb rx, [r5, #0]   @ rx = 0 = table[0],  Clearing the read bus
### just we can use one as:
  # ldrb r1, [r5, #0]   @ r1 = 0 = table[0],  Clearing the read bus and also reg1
### The one instruction, is not enough, we should use the both instruction,
### because the first operand in one-inst can cause leakage with the next inst
  # ex: r1 and r0, two shares from the same family
    # ldrb r1, [r5, #0]   @ r1 = 0 = table[0],  Clearing the read bus and also reg5
    # ldrb r0, [r5, r6]   @ r0 = table[a1]
  # eors r1, r1         @ r1 = 0, clearing (a0*b0) @ above to avoid stall
  ldrb r1, [r5, #0]   @ rx = 0 = table[0],  Clearing the read bus

@@@@ r0 = &c, r1 = 0, r2 = &rnd, r3 = a0,
@@@@ r4 = 32, r5 = &table, r6 = a1, r7 = b1, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ a1*b1

  ldrb r0, [r5, r6]   @ r0 = table[a1]
  ldrb r1, [r5, r7]   @ r1 = table[b1]

  adds r0, r1         @ r0 = s = table[a1]+table[b1]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r4, #250       @ r4 = 250, 256 is not possible, so it is split: 250+6
  adds r4, #6         @ r4 = 256
  adds r0, r4         @ r0 = s+256

  ldrb r1, [r5, r0]   @ r1 = s = table[s+256]


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
  # mov  r5, r11        @ r5 = &table
  strb r1, [r7, #4]   @ r1 = (a1*b1), Storing (a1*b1) in &c+#4, r1 = (a1*b1)
  strb r7, [r7, #8]   @ clearing the write bus

### we need to clear the read bus and also reg1, istead of using two instructions, just we can use one as:
  # eors r1, r1         @ r1 = 0, clearing (a1*b1) 
  # ldrb rx, [r5, #0]   @ rx = 0 = table[0],  Clearing the read bus
  ldrb r1, [r5, #0]   @ r1 = 0 = table[0],  Clearing the read bus and also reg1

@@@@ r0 = -a1 >> 32, r1 = 0, r2 = &rnd, r3 = a0,
@@@@ r4 = 256, r5 = &table, r6 = 32, r7 = &c, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ a2*b2

  mov  r7, r9         @ r7 = &a
  mov  r1, r10        @ r1 = &b

  ldrb r6, [r7, #8]   @ r6 = a2
  ldrb r0, [r1, #8]   @ r0 = b2
  
  ldrb r1, [r5, r6]   @ r1 = table[a2]
  ldrb r7, [r5, r0]   @ r7 = table[b2]

  adds r1, r7         @ r1 = s = table[a2]+table[b2]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
#  movs r4, #250       @ r4 = 250, 256 is not possible, so it is split: 250+6
#  adds r4, #6         @ r4 = 256
  adds r1, r4         @ r1 = s+256

  ldrb r7, [r5, r1]   @ r7 = s = table[s+256]

  # @@@@ Checking if a2 = 0 or b2 = 0, return 0; without conditional branch
  negs r1, r6         @ r1 = -a2

@ a2 in r6 is not needed anymore
  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r6, #32        @ r6 = 32
  asrs r1, r6         @ r1 = -a2 >> 32

  ands r1, r0         @ r1 = tmp = b2 & (-a2 >> 32)
  negs r1, r1         @ r1 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r1, r6         @ r1 = -tmp >> 32

  ands r7, r1         @ r7 = s & (-tmp >> 32) = (a2*b2)
  
  mov  r4, r8         @ r4 = &c
  strb r7, [r4, #8]   @ r7 = (a2*b2), Storing (a2*b2) in c2, r1 = (a2*b2)
  ## it is not possible to clear the write bus here

### we need to clear the read bus and also reg7, istead of using two instructions
  ## eors r7, r7         @ r7 = 0, clearing (a2*b2) 
  ## ldrb rx, [r5, #0]   @ rx = 0 = table[0],  Clearing the read bus
### as rnd0 and rnd2 are loaded into r7 and r1, reg7 and the read bus are cleared

########################################################################################################################
@@@@@@@@@@ Computing: ci
@@@@ c0 = (a0*b0)^(r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)
@ c0 = (a0*b0)^[rnd3^(a0*s02)^(a0*(b2^s02))^(b0*s02)^(b0*(a2^s02))^rnd4^(a0*s01)^(a0*(b1^s01))^(b0*s01)^(b0*(a1^s01))
@@@@ c1 = [(a1*b1)^(r12(=rnd5)^p0_12^p1_12^p2_12^p3_12)]^r1(=rnd4)
@@@@ c2 = [(a2*b2)^r12(=rnd5))]^r02(=rnd3)

@@@@ r0 = b2, r1 = -tmp >> 32, r2 = &rnd, r3 = a0,
@@@@ r4 = &c, r5 = &table, r6 = 32, r7 = (a2*b2), 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^(r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)
@ r02(=rnd3)^p0_02^p1_02^p2_02^p3_02

@@@@ r02(=rnd3)^p0_02 = rnd3^(a0*s02)
@ s02= s0^s2 = rnd0^rnd2,
@ p0_02= a0*s02,
@ p1_02= a0*(b2^s02),
@ p2_02= b0*s02,
@ p3_02= b0*(a2^s02),

  ldrb r7, [r2, #0]   @ r7 = rnd0
  ldrb r1, [r2, #8]   @ r1 = rnd2

  eors r7, r1         @ r7 = rnd0^rnd2 = s02
  ldrb r6, [r5, r3]   @ r6 = table[a0]
  ldrb r1, [r5, r7]   @ r1 = table[s02]

  adds r6, r1         @ r6 = s = table[a0]+table[s02]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r1, #250       @ r1 = 250, 256 is not possible, so it is split: 250+6
  adds r1, #6         @ r1 = 256
  adds r6, r1         @ r6 = s+256

  ldrb r1, [r5, r6]   @ r1 = s = table[s+256]
  ldrb r4, [r2, #12]  @ r4 = rnd3   @ it also clears the read bus wich contains (a0*s02)

  # @@@@ Checking if a0 = 0 or s02 = 0, return 0; without conditional branch
  negs r6, r3         @ r6 = -a0 hex(256-dec(a0))

  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r5, #32        @ r5 = #32
  asrs r6, r5         @ r6 = -a0 >> 32

  ands r6, r7         @ r6 = tmp = s02 & (-a0 >> 32)
  negs r6, r6         @ r6 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r6, r5         @ r6 = -tmp >> 32

  ands r1, r6         @ r1 = s & (-tmp >> 32) = p0_02= (a0*s02)

  # mov  r5, r11        @ r5 = &table, @ here to avoid stall
  eors r1, r4         @ r1 = rnd3^(a0*s02)=r02(=rnd3)^p0_02

### it is better to clear the read bus, as they are (a0*s02)
### we need to clear the read bus which contains (a0*s02)
  ## but it was done by:
  # ldrb r4, [r2, #12]  @ r4 = rnd3
### no need to clear r4 = rnd3
  
  mov  r5, r11        @ r5 = &table, @ here to clear the piplines registers and decoding ports

@@@@ r0 = b2, r1 = r02(=rnd3)^p0_02, r2 = &rnd, r3 = a0,
@@@@ r4 = rnd3, r5 = &table, r6 = -tmp >> 32, r7 = s02, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^(r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)
@ r02(=rnd3)^p0_02^p1_02^p2_02^p3_02

@ p2_02= b0*s02,
@ p3_02= b0*(a2^s02),

@@@@ p1_02= a0*(b2^s02)

@ b2 in r0 is not needed anymore, but s02 is needed
  eors r0, r7         @ r0 = b2^s02
  ldrb r6, [r5, r3]   @ r6 = table[a0]
  ldrb r4, [r5, r0]   @ r4 = table[(b2^s02)]

  adds r6, r4         @ r6 = s = table[a0]+table[(b2^s02)]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r4, #250       @ r4 = 250, 256 is not possible, so it is split: 250+6
  adds r4, #6         @ r4 = 256
  adds r6, r4         @ r6 = s+256

  ldrb r4, [r5, r6]   @ r4 = s = table[s+256]

  # @@@@ Checking if a0 = 0 or (b2^s02) = 0, return 0; without conditional branch
  negs r6, r3         @ r6 = -a0 hex(256-dec(a0))

@ a0 in r3 is not needed anymore
  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r3, #32        @ r3 = #32
  asrs r6, r3         @ r6 = -a0 >> 32

  ands r6, r0         @ r6 = tmp = (b2^s02) & (-a0 >> 32)
  negs r6, r6         @ r6 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r6, r3         @ r6 = -tmp >> 32

# (b2^s02) in r0 is not needed anymore
  mov  r0, r10        @ r0 = &b, for clearing r0 = (b2^s02) and for loading b0 later, @ hear to avoid stall, 

  ands r4, r6         @ r4 = s & (-tmp >> 32) = p1_02= (a0*(b2^s02))

  eors r1, r4         @ r1 = r02(=rnd3)^p0_02^p1_02

### It is better to clear the read bus and also reg4, as they are (a0*(b2^s02)), which seems random
  eors r4, r4          @ r4 = 0, clearing (a0*(b2^s02)) 
  ldrb r4, [r5, #0]    @ rx = 0 = table[0],  Clearing the read bus

@@@@ r0 = &b, r1 = r02(=rnd3)^p0_02^p1_02, r2 = &rnd, r3 = 32,
@@@@ r4 = 0, r5 = &table, r6 = -tmp >> 32, r7 = s02, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^(r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)
@ r02(=rnd3)^p0_02^p1_02^p2_02^p3_02

@ p3_02= b0*(a2^s02)

@@@@ p2_02= b0*s02

  ldrb r6, [r0, #0]   @ r6 = b0
  ### reordering to avoid one stall
  # ldrb r0, [r5, r6]   @ r0 = table[b0]
  # ldrb r4, [r5, r7]   @ r4 = table[s02]
  ldrb r4, [r5, r7]   @ r4 = table[s02]
  ldrb r0, [r5, r6]   @ r0 = table[b0]

  adds r0, r4         @ r0 = s = table[b0]+table[s02]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r4, #250       @ r4 = 250, 256 is not possible, so it is split: 250+6
  adds r4, #6         @ r4 = 256
  adds r0, r4         @ r0 = s+256

  ldrb r4, [r5, r0]   @ r4 = s = table[s+256]

  # @@@@ Checking if b0 = 0 or s02 = 0, return 0; without conditional branch
  negs r0, r6         @ r0 = -b0 hex(256-dec(b0))

  # @ asrs rd, <#imm> --> #imm: 0-31
  # movs r3, #32        @ r3 = #32
  asrs r0, r3         @ r0 = -b0 >> 32

  ands r0, r7         @ r0 = tmp = s02 & (-b0 >> 32)
  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r3         @ r0 = -tmp >> 32

  ands r4, r0         @ r4 = s & (-tmp >> 32) = p2_02= (b0*s02)

  eors r1, r4        @ r1 = r02(=rnd3)^p0_02^p1_02^p2_02

### it is better to clear the read bus and also reg4, as they are (b0*s02), which seems random
  # eors r4, r4          @ r4 = 0, clearing (b0*s02)
  mov  r4, r9         @ r4 = &a, for loading a2 later, @ hear to avoid stall,  

  ldrb r0, [r5, #0]    @ rx = 0 = table[0],  Clearing the read bus

@@@@ r0 = 0, r1 = r02(=rnd3)^p0_02^p1_02^p2_02, r2 = &rnd, r3 = 32,
@@@@ r4 = &a, r5 = &table, r6 = b0, r7 = s02, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^(r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)
@ r02(=rnd3)^p0_02^p1_02^p2_02^p3_02

@@@@ p3_02= b0*(a2^s02),

  ldrb r0, [r4, #8]   @ r0 = a2
#@ a2 in r0 is not needed anymore
  eors r0, r7         @ r0 = a2^s02
  ldrb r3, [r5, r6]   @ r3 = table[b0]
  ldrb r4, [r5, r0]   @ r4 = table[(a2^s02)]

  adds r3, r4         @ r3 = s = table[b0]+table[(a2^s02)]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r4, #250       @ r4 = 250, 256 is not possible, so it is split: 250+6
  adds r4, #6         @ r4 = 256
  adds r3, r4         @ r3 = s+256

  ldrb r4, [r5, r3]   @ r4 = s = table[s+256]

  # @@@@ Checking if b0 = 0 or (a2^s02) = 0, return 0; without conditional branch
  negs r3, r6         @ r3 = -b0 hex(256-dec(b0))

@ b0 in r6 is not needed anymore
  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r6, #32        @ r6 = #32
  asrs r3, r6         @ r3 = -b0 >> 32

  ands r3, r0         @ r3 = tmp = (a2^s02) & (-b0 >> 32)
  negs r3, r3         @ r3 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r3, r6         @ r3 = -tmp >> 32

# (a2^s02) in r0 is not needed anymore

  mov  r0, r9        @ r0 = &a, for clearing r0 = (a2^s02) and for loading b0 later, @ hear to avoid stall, 

  ands r4, r3         @ r4 = s & (-tmp >> 32) = p3_02= (b0*(a2^s02))
 
  eors r1, r4         @ r1 = r02(=rnd3)^p0_02^p1_02^p2_02^p3_02

### it is better to clear the read bus and also reg4, as they are (b0*(a2^s02)), which seems random
  eors r4, r4          @ r4 = 0, clearing (b0*(a2^s02) 

  # not needed, beacuse of the next instruction
  # ldrb r4, [r5, #0]    @ rx = 0 = table[0],  Clearing the read bus

################################################################################
@@@@ r0 = &a, r1 = r02(=rnd3)^p0_02^p1_02^p2_02^p3_02, r2 = &rnd, r3 = -tmp >> 32,
@@@@ r4 = 0, r5 = &table, r6 = 32, r7 = s02, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^(r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)
@ r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)

@ p1_01= a0*(b1^s01),
@ p2_01= b0*s01,
@ p3_01= b0*(a1^s01),

@@@@ p0_01= a0*s01 

  ldrb r7, [r2, #0]   @ r7 = rnd0
  ldrb r3, [r0, #0]   @ r3 = a0
  ldrb r0, [r2, #4]   @ r0 = rnd1

  eors r7, r0         @ r7 = rnd0^rnd1 = s01
  ldrb r6, [r5, r3]   @ r6 = table[a0]
  ldrb r0, [r5, r7]   @ r0 = table[s01]

  adds r6, r0         @ r6 = s = table[a0]+table[s01] 

  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r0, #250       @ r0 = 250, 256 is not possible, so it is split: 250+6
  adds r0, #6         @ r0 = 256
  adds r6, r0         @ r6 = s+256

  ldrb r0, [r5, r6]   @ r0 = s = table[s+256]
  ldrb r4, [r2, #16]  @ r4 = rnd4   @ it also clears the read bus wich contains (a0*s01)

  # @@@@ Checking if a0 = 0 or s01 = 0, return 0; without conditional branch
  negs r6, r3         @ r6 = -a0 hex(256-dec(a0))

  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r5, #32        @ r5 = #32
  asrs r6, r5         @ r6 = -a0 >> 32

  ands r6, r7         @ r6 = tmp = s01 & (-a0 >> 32)
  negs r6, r6         @ r6 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r6, r5         @ r6 = -tmp >> 32

  ands r0, r6         @ r0 = s & (-tmp >> 32) = p0_01=(a0*s01)

  # mov  r5, r11        @ r5 = &table, @ here to avoid stall
#  @ r1 = r02(=rnd3)^p0_02^p1_02^p2_02^p3_02
  eors r1, r4         @ r1 = r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)

  mov  r4, r10        @ r0 = &b @ here for avoidind stall

  eors r1, r0         @ r1 = r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01 
  
### we need to clear the read bus which contains (a0*s01)
  ## but it was done by:
  # ldrb r4, [r2, #12]  @ r4 = rnd3
### clear r0 = p0_01=(a0*s01)
  eors r0, r0         @ r0 = 0

  mov  r5, r11        @ r5 = &table, @ here to clear the piplines registers and decoding ports

@@@@ r0 = 0, r1 = r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01
@@@@ r2 = &rnd, r3 = a0,
@@@@ r4 = &b, r5 = &table, r6 = -tmp >> 32, r7 = s01, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^(r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)
@ r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)

@ p2_01= b0*s01,
@ p3_01= b0*(a1^s01),

@@@@ p1_01= a0*(b1^s01)

  ldrb r0, [r4, #4]  @ r0 = b1
# @ b1 in r0 is not needed anymore, but s01 is needed
  eors r0, r7         @ r0 = b1^s01
  ldrb r6, [r5, r3]   @ r6 = table[a0]
  ldrb r4, [r5, r0]   @ r4 = table[(b1^s01)]

  adds r6, r4         @ r6 = s = table[a0]+table[(b1^s01)]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r4, #250       @ r4 = 250, 256 is not possible, so it is split: 250+6
  adds r4, #6         @ r4 = 256
  adds r6, r4         @ r6 = s+256

  ldrb r4, [r5, r6]   @ r4 = s = table[s+256]

  # @@@@ Checking if a0 = 0 or (b1^s01) = 0, return 0; without conditional branch
  negs r6, r3         @ r6 = -a0 hex(256-dec(a0))

@ a0 in r3 is not needed anymore
  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r3, #32        @ r3 = #32
  asrs r6, r3         @ r6 = -a0 >> 32

  ands r6, r0         @ r6 = tmp = (b1^s01) & (-a0 >> 32)
  negs r6, r6         @ r6 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r6, r3         @ r6 = -tmp >> 32

# (b1^s01) in r0 is not needed anymore
  mov  r0, r10        @ r0 = &b, for clearing r0 = (b1^s01) and for loading b0 later, @ hear to avoid stall, 

  ands r4, r6         @ r4 = s & (-tmp >> 32) = p1_01 = (a0*(b1^s01))

# r1 = r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01
  eors r1, r4         @ r1 = r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01

### It is better to clear the read bus and also reg4, as they are (a0*(b1^s01)), which seems random
  eors r4, r4          @ r4 = 0, clearing (a0*(b1^s01)) 
  ldrb r4, [r5, #0]    @ rx = 0 = table[0],  Clearing the read bus

@@@@ r0 = &b, r1 = r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01
@@@@ r2 = &rnd, r3 = 32,
@@@@ r4 = 0, r5 = &table, r6 = -tmp >> 32, r7 = s01, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^(r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)
@ r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)

@ p3_01= b0*(a1^s01),

@@@@ p2_01= b0*s01

  ldrb r6, [r0, #0]   @ r6 = b0
  ### reordering to avoid one stall
  # ldrb r0, [r5, r6]   @ r0 = table[b0]
  # ldrb r4, [r5, r7]   @ r4 = table[s01]
  ldrb r4, [r5, r7]   @ r4 = table[s01]
  ldrb r0, [r5, r6]   @ r0 = table[b0]

  adds r0, r4         @ r0 = s = table[b0]+table[s01]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r4, #250       @ r4 = 250, 256 is not possible, so it is split: 250+6
  adds r4, #6         @ r4 = 256
  adds r0, r4         @ r0 = s+256

  ldrb r4, [r5, r0]   @ r4 = s = table[s+256]

  # @@@@ Checking if b0 = 0 or s01 = 0, return 0; without conditional branch
  negs r0, r6         @ r0 = -b0 hex(256-dec(b0))

  # @ asrs rd, <#imm> --> #imm: 0-31
  # movs r3, #32        @ r3 = #32
  asrs r0, r3         @ r0 = -b0 >> 32

  ands r0, r7         @ r0 = tmp = s01 & (-b0 >> 32)
  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r3         @ r0 = -tmp >> 32

  ands r4, r0         @ r4 = s & (-tmp >> 32) = p2_01= b0*s01

# @ r1 = r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01
  eors r1, r4        @ r1 = r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01

### it is better to clear the read bus and also reg4, as they are (b0*s01), which seems random
  # eors r4, r4          @ r4 = 0, clearing (b0*s01)
  mov  r4, r9         @ r4 = &a, for loading a1 later, @ hear to avoid stall,  

  ldrb r0, [r5, #0]    @ rx = 0 = table[0],  Clearing the read bus

@@@@ r0 = 0, r1 = r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01,
@@@@ r2 = &rnd, r3 = 32,
@@@@ r4 = &a, r5 = &table, r6 = b0, r7 = s01, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^(r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)
@ r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)

@@@@ p3_01= b0*(a1^s01),

  ldrb r0, [r4, #4]   @ r0 = a1
#@ s01 in r7 is not needed anymore, but a1 is needed
  eors r7, r0         @ r7 = a1^s01
  ldrb r3, [r5, r6]   @ r3 = table[b0]
  ldrb r4, [r5, r7]   @ r4 = table[(a1^s01)]

  adds r3, r4         @ r3 = s = table[b0]+table[(a1^s01)]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r4, #250       @ r4 = 250, 256 is not possible, so it is split: 250+6
  adds r4, #6         @ r4 = 256
  adds r3, r4         @ r3 = s+256

  ldrb r4, [r5, r3]   @ r4 = s = table[s+256]

  # @@@@ Checking if b0 = 0 or (a1^s01) = 0, return 0; without conditional branch
  negs r3, r6         @ r3 = -b0 hex(256-dec(b0))

@ b0 in r6 is not needed anymore
  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r6, #32        @ r6 = #32
  asrs r3, r6         @ r3 = -b0 >> 32

  ands r3, r7         @ r3 = tmp = (a1^s01) & (-b0 >> 32)
  negs r3, r3         @ r3 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r3, r6         @ r3 = -tmp >> 32

# (a1^s01) in r7 is not needed anymore
  mov  r7, r8        @ r7 = &c, for clearing r7 = (a1^s01) and for loading (a0*b0) later, @ hear to avoid stall 

  ands r4, r3         @ r4 = s & (-tmp >> 32) = p3_01 = (b0*(a1^s01))

# @ r1 = r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01,
  eors r1, r4         @ r1 = r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01^p3_01

### it is better to clear the read bus and also reg4, as they are (b0*(a1^s01)), which seems random
  eors r4, r4          @ r4 = 0, clearing (b0*(a1^s01) 
  ldrb r4, [r5, #0]    @ rx = 0 = table[0],  Clearing the read bus
# ################################################################################
@@@@ r0 = a1, r1 = r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01^p3_01,
@@@@ r2 = &rnd, r3 = -tmp >> 32,
@@@@ r4 = 0, r5 = &table, r6 = 32, r7 = &c, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^(r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)

  ldrb r6, [r7, #0]   @ r6 = (a0*b0)
  strb r4, [r7, #0]   @ r4 = 0, clearing the write bus which contains (a0*b0)

  eors r1, r6         @ r1 = c0 =(a0*b0)^(r02(=rnd3)^p0_02^p1_02^p2_02^p3_02^r1(=rnd4)^p0_01^p1_01^p2_01^p3_01)  

  strb r1, [r7, #0]   @ r1 = c0, Storing c0, r0 = c0
  eors r6, r6         @ r6 = 0, clearin (a0*b0)
  eors r1, r1         @ r1 = 0, clearing c0 from r1
# here the ldrb is not needed as first rnd1 is loaded, so it clear the read bus
#  ldrb r6, [r5, #0]   @ r6 = 0, clearing c0 and the read bus which contains (a0*b0)
# ################################################################################
@@@@ r0 = a1, r1 = 0, r2 = &rnd, r3 = -tmp >> 32,
@@@@ r4 = 0, r5 = &table, r6 = 0, r7 = &c, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c1 = [(a1*b1)^(r12(=rnd5)^p0_12^p1_12^p2_12^p3_12)]^r1(=rnd4)

@ s12= s1^s2= rnd1^rnd2,
@ p0_12= a1*s12,
@ p1_12= a1*(b2^s12),
@ p2_12= b1*s12,
@ p3_12= b1*(a2^s12),

@@@@ p0_12= a1*s12

  ldrb r7, [r2, #4]   @ r7 = rnd1
  ldrb r1, [r2, #8]   @ r1 = rnd2

  eors r7, r1         @ r7 = rnd0^rnd2 = s12
  ldrb r6, [r5, r0]   @ r6 = table[a1]
  ldrb r1, [r5, r7]   @ r1 = table[s12]

  adds r6, r1         @ r6 = s = table[a1]+table[s12]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r1, #250       @ r1 = 250, 256 is not possible, so it is split: 250+6
  adds r1, #6         @ r1 = 256
  adds r6, r1         @ r6 = s+256

  ldrb r1, [r5, r6]   @ r1 = s = table[s+256]
  ldrb r4, [r2, #20]  @ r4 = rnd5   @ it also clears the read bus wich contains (a1*s12)

  # @@@@ Checking if a1 = 0 or s12 = 0, return 0; without conditional branch
  negs r6, r0         @ r6 = -a1 hex(256-dec(a1))

  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r3, #32        @ r3 = #32
  asrs r6, r3         @ r6 = -a1 >> 32

  ands r6, r7         @ r6 = tmp = s12 & (-a1 >> 32)
  negs r6, r6         @ r6 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r6, r3         @ r6 = -tmp >> 32

  ands r1, r6         @ r1 = s & (-tmp >> 32) = p0_12= (a1*s12)
 
  mov  r6, r10        @ r6 = &b, @ here to avoid stall

  eors r1, r4         @ r1 = rnd5^(a1*s12)=r12(=rnd5)^p0_12
  
### it is better to clear the read bus, as they are (a1*s12)
### we need to clear the read bus which contains (a1*s12)
  ## but it was done by:
  # ldrb r4, [r2, #20]  @ r4 = rnd5
### no need to clear as it is r4 = rnd5

@@@@ r0 = a1, r1 = r12(=rnd5)^p0_02, r2 = &rnd, r3 = 32,
@@@@ r4 = rnd5, r5 = &table, r6 = &b, r7 = s12, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c1 = [(a1*b1)^(r12(=rnd5)^p0_12^p1_12^p2_12^p3_12)]^r1(=rnd4)

@ p2_12= b1*s12,
@ p3_12= b1*(a2^s12),

@@@@ p1_12= a1*(b2^s12),

  ldrb r3, [r6, #8]   @ r3 = b2
# @ b2 in r3 is not needed anymore, but s12 is needed
  eors r3, r7         @ r3 = b2^s12
  ldrb r6, [r5, r0]   @ r6 = table[a1]
  ldrb r4, [r5, r3]   @ r4 = table[(b2^s12)]

  adds r6, r4         @ r6 = s = table[a1]+table[(b2^s12)]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r4, #250       @ r4 = 250, 256 is not possible, so it is split: 250+6
  adds r4, #6         @ r4 = 256
  adds r6, r4         @ r6 = s+256

  ldrb r4, [r5, r6]   @ r4 = s = table[s+256]

  # @@@@ Checking if a1 = 0 or (b2^s12) = 0, return 0; without conditional branch
  negs r6, r0         @ r6 = -a1 hex(256-dec(a1))

@ a1 in r0 is not needed anymore
  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r0, #32        @ r0 = #32
  asrs r6, r0         @ r6 = -a1 >> 32

  ands r6, r3         @ r6 = tmp = (b2^s12) & (-a1 >> 32)
  negs r6, r6         @ r6 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r6, r0         @ r6 = -tmp >> 32

# @ (b2^s12) in r3 is not needed anymore
  mov  r3, r10        @ r3 = &b, for clearing r3 = (b2^s12) and for loading b1 later, @ hear to avoid stall, 

  ands r4, r6         @ r4 = s & (-tmp >> 32) = p1_12= (a1*(b2^s12))

  eors r1, r4         @ r1 = r12(=rnd5)^p0_12^p1_12

### It is better to clear the read bus and also reg4, as they are (a1*(b2^s12)), which seems random
  eors r4, r4          @ r4 = 0, clearing (a1*(b2^s12)) 
  ldrb r4, [r5, #0]    @ rx = 0 = table[0],  Clearing the read bus

@@@@ r0 = 32, r1 = r12(=rnd5)^p0_12^p1_12, r2 = &rnd, r3 = &b,
@@@@ r4 = 0, r5 = &table, r6 = -tmp >> 32, r7 = s12, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c1 = [(a1*b1)^(r12(=rnd5)^p0_12^p1_12^p2_12^p3_12)]^r1(=rnd4)

@ p3_12= b1*(a2^s12),

@@@@ p2_12= b1*s12

  ldrb r6, [r3, #4]   @ r6 = b1
  ### reordering to avoid one stall
  # ldrb r3, [r5, r6]   @ r3 = table[b1]
  # ldrb r4, [r5, r7]   @ r4 = table[s12]
  ldrb r4, [r5, r7]   @ r4 = table[s12]
  ldrb r3, [r5, r6]   @ r3 = table[b1]

  adds r3, r4         @ r3 = s = table[b1]+table[s12]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r4, #250       @ r4 = 250, 256 is not possible, so it is split: 250+6
  adds r4, #6         @ r4 = 256
  adds r3, r4         @ r3 = s+256

  ldrb r4, [r5, r3]   @ r4 = s = table[s+256]

  # @@@@ Checking if b1 = 0 or s12 = 0, return 0; without conditional branch
  negs r3, r6         @ r3 = -b1 hex(256-dec(b1))

  # @ asrs rd, <#imm> --> #imm: 0-31
  # movs r0, #32        @ r0 = #32
  asrs r3, r0         @ r3 = -b1 >> 32

  ands r3, r7         @ r3 = tmp = s12 & (-b1 >> 32)
  negs r3, r3         @ r3 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r3, r0         @ r3 = -tmp >> 32

  ands r4, r3         @ r4 = s & (-tmp >> 32) = p2_12= (b1*s12)

  eors r1, r4        @ r1 = r12(=rnd5)^p0_12^p1_12^p2_12

### it is better to clear the read bus and also reg4, as they are (b1*s12), which seems random
  # eors r4, r4          @ r4 = 0, clearing (b1*s12)
  mov  r4, r9         @ r4 = &a, for loading a2 later, @ hear to avoid stall,  

  ldrb r3, [r5, #0]    @ rx = 0 = table[0],  Clearing the read bus

@@@@ r0 = 32, r1 = r12(=rnd5)^p0_12^p1_12^p2_12, r2 = &rnd, r3 = 0,
@@@@ r4 = &a, r5 = &table, r6 = b1, r7 = s12, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c1 = [(a1*b1)^(r12(=rnd5)^p0_12^p1_12^p2_12^p3_12)]^r1(=rnd4)

@@@@ p3_12= b1*(a2^s12),

  ldrb r3, [r4, #8]   @ r3 = a2
#@ a2 in r3 is not needed anymore
  eors r3, r7         @ r3 = a2^s12
  ldrb r0, [r5, r6]   @ r0 = table[b1]
  ldrb r4, [r5, r3]   @ r4 = table[(a2^s12)]

  adds r0, r4         @ r0 = s = table[b1]+table[(a2^s12)]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r4, #250       @ r4 = 250, 256 is not possible, so it is split: 250+6
  adds r4, #6         @ r4 = 256
  adds r0, r4         @ r0 = s+256

  ldrb r4, [r5, r0]   @ r4 = s = table[s+256]

  # @@@@ Checking if b1 = 0 or (a2^s12) = 0, return 0; without conditional branch
  negs r0, r6         @ r0 = -b1 hex(256-dec(b1))

@ b1 in r6 is not needed anymore
  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r6, #32        @ r6 = #32
  asrs r0, r6         @ r0 = -b1 >> 32

  ands r0, r3         @ r0 = tmp = (a2^s12) & (-b1 >> 32)
  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r6         @ r0 = -tmp >> 32

# (a2^s12) in r3 is not needed anymore

  mov  r3, r8        @ r3 = &c, for clearing r3 = (a2^s12) and for loading a1*b1 later, @ hear to avoid stall, 

  ands r4, r0         @ r4 = s & (-tmp >> 32) = p3_12= (b1*(a2^s12))
 
  eors r1, r4         @ r1 = r12(=rnd5)^p0_12^p1_12^p2_12^p3_12

### it is better to clear the read bus and also reg4, as they are (b1*(a2^s12)), which seems random
  eors r4, r4          @ r4 = 0, clearing (b1*(a2^s12) 

  # not needed, beacuse of the next instruction
  # ldrb r4, [r5, #0]    @ rx = 0 = table[0],  Clearing the read bus
# ################################################################################
@@@@ r0 = -tmp >> 32, r1 = r12(=rnd5)^p0_12^p1_12^p2_12^p3_12,
@@@@ r2 = &rnd, r3 = &c,
@@@@ r4 = 0, r5 = &table, r6 = 32, r7 = &c, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c1 = [(a1*b1)^(r12(=rnd5)^p0_12^p1_12^p2_12^p3_12)]^r1(=rnd4)

  ldrb r7, [r2, #16]  @ r7 = rnd4 @ it also clears the read bus wich contains b1*(a2^s12)

  ldrb r6, [r3, #4]   @ r6 = (a1*b1)
  strb r4, [r3, #4]   @ r4 = 0, clearing the write bus which contains (a1*b1)

  eors r1, r6         @ r1 = (a1*b1)^(r12(=rnd5)^p0_12^p1_12^p2_12^p3_12)
  eors r1, r7         @ r1 = c1
  strb r1, [r3, #4]   @ r1 = c1, Storing c1, r1 = c1
  eors r6, r6         @ r6 = 0, clearin (a1*b1)
  eors r1, r1         @ r1 = 0, clearing c1 from r1
# here the ldrb is not needed as first rnd1 is loaded, so it clear the read bus
#  ldrb r6, [r5, #0]   @ r6 = 0, clearing c1 and the read bus which contains (a1*b1)
# ################################################################################
@@@@ r0 = -tmp >> 32, r1 = 0, r2 = &rnd, r3 = &c,
@@@@ r4 = 0, r5 = &table, r6 = 0, r7 = rnd4, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &table 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c2 = [(a2*b2)^r12(=rnd5))]^r02(=rnd3)
  
  ldrb r0, [r2, #20]  @ r0 = rnd5 @ it also clears the read bus wich contains a1*b1
  ldrb r4, [r3, #8]   @ r6 = (a2*b2)
  
  eors r4, r0         @ r4 = (a2*b2)^(r12(=rnd5)

  strb r6, [r3, #8]   @ r4 = 0, clearing the write bus which contains (a2*b2)
  ldrb r5, [r2, #12]  @ r5 = rnd3 @ it also clears the read bus wich contains a2*b2

  eors r4, r5         @ r4 = c2
  strb r4, [r3, #8]   @ r4 = c2, Storing c2, r4 = c2


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
  movs r5, #1
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
