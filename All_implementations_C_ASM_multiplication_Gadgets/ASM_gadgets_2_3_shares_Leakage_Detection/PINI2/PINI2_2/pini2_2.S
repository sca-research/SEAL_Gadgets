@ PINI2_2_V0

@ a = a0^a1, b = b0^b1, c = c0^c1, a * b = c, random numbers: rnd0

@  ^: xor; +: arithmathic addition; x & y: and operation; *: Galois field multiplication; &x: the address of x

@@@@ c0 = (a0*b0)^t01=(a0*b0)^[r01^p0_01^p1_01^p2_01^p3_01] 
@ s01=s0^s1, p0_01 = a0*s01, p1_01 = a0*(b1^s01), p2_01=b0*s01, p3_01= b0*(a1^s01)

@@@@ c0 = (a0*b0)^[r01^(a0*s01)^[a0*(b1^s01)]^(b0*s01)^[b0*(a1^s01)]]
@@@@ c1 = (a1*b1)^r01 = (a1*b1)^rnd2

.syntax unified
  .text
  .thumb

  .extern table       @@@@ table is used for GFMULT (ai* bj multiplications)

@@@@ extern void Pini2_2(uint8_t* inputa: addres: r0, uint8_t* inputb: address: r1, uint8_t* rnd: address: r2, uint8_t* output: address: r3);
@inputa: a0, a1, inputb: b0, b1, rnd: (s0) rnd0, (s1) rnd1, (r01) rnd2, output: c: c0, c1
@@@@ extern void Pini2_2(r0, r1, r2, r3);

.global Pini2_2
.func Pini2_2
Pini2_2:

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

@@@@@ Saving r2 (the address of the input rnd)
  mov  r11, r2       @ r11 = &rnd


@@@@ Saving the value 256 in r11. This decreases one cycle.
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r3, #250       @ r3 = 250, 256 is not possible, so it is split: 250+6
  adds r3, #6         @ r3 = 256
  # mov  r11, r3        @ r11 = 256

@@@@@ Saving the address of the "table"
  ldr  r4, =table    @ r4 = &table, The address of the "table", for ai*bj multiplications


nop
nop
nop
nop

@@@@@@@@@@ Computing: c0 = (a0*b0)^[(a0^1)*rnd]^[a0*(b1^rnd)]

@@@@ r0 = &a, r1 = &b, r2 = &rnd, r3 = 256
@@@@ r4 = &table
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &rnd
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@ Loading arguments @@@@@@@@@@@@

  ldrb r6, [r0, #0] @ r6 = a0; r0 = &a, r1 = &b, r2 = &rnd
  ldrb r5, [r1, #0] @ r5 = b0; r0 = &a, r1 = &b, r2 = &rnd


@@@@ r0 = &a, r1 = &b, r2 = &rnd, r3 = 256
@@@@ r4 = &table, r5 = b0, r6 = a0, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &rnd
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ a0*b0
@@@@ c0 = (a0*b0)^[r01^(a0*s01)^[a0*(b1^s01)]^(b0*s01)^[b0*(a1^s01)]]

  ldrb r0, [r4, r6]   @ r0 = table[a0]
  ldrb r1, [r4, r5]   @ r1 = table[b0]

  adds r0, r1         @ r0 = s = table[a0]+table[b0]

  # @@@@ Get the antilog: s = table[s+256]: g+s
  # movs r3, #250       @ r3 = 250, 256 is not possible, so it is split: 250+6
  # adds r3, #6         @ r3 = 256

  adds r0, r3         @ r0 = s+256

  ldrb r1, [r4, r0]   @ r1 = s = table[s+256]

  # @@@@ Checking if a0 = 0 or b0 = 0, return 0; without conditional branch
  negs r0, r6         @ r0 = -a0 hex(256-dec(a0))

  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r7, #32        @ r7 = #32
  asrs r0, r7         @ r0 = -a0 >> 32

  # @@@@ b0 is not used in the rest computation of c0
  ands r5, r0         @ r5 = tmp = b0 & (-a0 >> 32)
  negs r5, r5         @ r5 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r5, r7         @ r5 = -tmp >> 32

  ands r1, r5         @ r1 = s & (-tmp >> 32) = (a0*b0)

  # @ Storing (a0*b0) in [&c+#0]
  mov  r5, r8         @ r5 = &c
  strb r1, [r5, #0]   @ r1 = (a0*b0), Storing (a0*b0) in &c+#0

  
@@@@ r0 = -a0 >> 32, r1 = (a0*b0), r2 = &rnd, r3 = 256
@@@@ r4 = &table, r5 = &c, r6 = a0, r7 = 32, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &rnd
@@@@ rnd: (s0) rnd0, (s1) rnd1, (r01) rnd2
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ r01^(a0*s01)
@@@@ c0 = (a0*b0)^[r01^(a0*s01)^[a0*(b1^s01)]^(b0*s01)^[b0*(a1^s01)]]

  ldrb r5, [r2, #0]   @ r5 = rnd0(s0)
  ldrb r1, [r2, #4]   @ r1 = rnd1(s1)
  ldrb r2, [r2, #8]   @ r2 = rnd2(r01)
  
  eors r5, r1         @ r5 = rnd0^rnd1= s0^s1= s01

  ldrb r0, [r4, r6]   @ r0 = table[a0]     
  ldrb r1, [r4, r5]   @ r1 = table[s01]

  adds r0, r1         @ r0 = s = table[a0]+table[s01]

  # @@@@ Get the antilog: s = table[s+256]: g+s
  # movs r3, #250       @ r3 = 250, 256 is not possible, so it is split: 250+6
  # adds r3, #6         @ r3 = 256

  adds r0, r3         @ r0 = s+256

  ldrb r1, [r4, r0]   @ r1 = s = table[s+256]

  # @@@@ Checking if a0 = 0 or s01 = 0, return 0; without conditional branch
  negs r0, r6         @ r0 = -(a0) hex(256-dec((a0)))

  # @ asrs rd, <#imm> --> #imm: 0-31
  # movs r7, #32        @ r7 = #32
  asrs r0, r7         @ r7 = -(a0) >> 32

  ands r0, r5         @ r0 = tmp = s01 & (-(a0) >> 32)
  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r7         @ r0 = -tmp >> 32

  ands r1, r0         @ r1 = s & (-tmp >> 32) = (a0*s01)

  eors r1, r2         @ r01^(a0*s01)
  

@@@@ r0 = -tmp >> 32, r1 = r01^(a0*s01), r2 = r01, r3 = 256
@@@@ r4 = &table, r5 = s01, r6 = a0, r7 = 32, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &rnd
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ a0*(b1^s01)
@@@@ c0 = (a0*b0)^[r01^(a0*s01)^[a0*(b1^s01)]^(b0*s01)^[b0*(a1^s01)]]
  
  mov  r2, r10        @ r2 = &b
  ldrb r7, [r2, #4]   @ r7 = b1
  eors r7, r5         @ r7 = b1^s01
  ldrb r0, [r4, r6]   @ r0 = table[a0]
  ldrb r2, [r4, r7]   @ r2 = table[b1^s01]
  
  adds r0, r2         @ r0 = s = table[a0]+table[b1^s01]

  @@@@ Get the antilog: s = table[s+256]: g+s
 # movs r3, #250       @ r3 = 250, 256 is not possible, so it is split: 250+6
 # adds r3, #6         @ r3 = 256

  adds r0, r3         @ r0 = s+256

  ldrb r2, [r4, r0]   @ r2 = s = table[s+256]

  # @@@@ Checking if a0 = 0 or b1^s01 = 0, return 0; without conditional branch
  
  negs r0, r6         @ r0 = -a0 hex(256-dec(a0))

  # @ asrs rd, <#imm> --> #imm: 0-31
  # @@ a0 in r6 is not needed any more
  movs r6, #32        @ r6 = #32
  asrs r0, r6         @ r0 = -a0 >> 32

  ands r0, r7         @ r0 = tmp = (b1^s01) & (-a0 >> 32)

  # @ (b1^s01) in r7 is not needed any more
  eors r7, r7         @ r7 = 0
  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r6         @ r0 = -tmp >> 32

  ands r2, r0         @ r2 = s & (-tmp >> 32) = (a0*(b1^s01))

  eors r1, r2         @ r1 = r01^(a0*s01)^[a0*(b1^s01)]

  eors r2, r2         @ r2 = 0, Clearing (a0*(b1^s01))


  
@@@@ r0 = -tmp >> 32, r1 = r01^(a0*s01)^[a0*(b1^s01)], r2 = 0, r3 = 256
@@@@ r4 = &table, r5 = s01, r6 = 32, r7 = 0, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &rnd
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@ (b0*s01)
@@@@ c0 = (a0*b0)^[r01^(a0*s01)^[a0*(b1^s01)]^(b0*s01)^[b0*(a1^s01)]]

  mov  r2, r10      @ r2 = &b
  ldrb r7, [r4, #0] @ r7 = 0, clearing the readbus a0*(b1^s01), table[0] = 0
  ldrb r0, [r2, #0] @ r0 = b0
  
  ldrb r7, [r4, r0]   @ r7 = table[b0]     
  ldrb r2, [r4, r5]   @ r2 = table[s01]

  adds r7, r2         @ r7 = s = table[b0]+table[s01]

  @@@@ Get the antilog: s = table[s+256]: g+s
  # movs r3, #250       @ r3 = 250, 256 is not possible, so it is split: 250+6
  # adds r3, #6         @ r3 = 256

  adds r7, r3         @ r7 = s+256

  ldrb r2, [r4, r7]   @ r2 = s = table[s+256]

  # @@@@ Checking if b0 = 0 or s01 = 0, return 0; without conditional branch
  negs r7, r0         @ r7 = -(b0) hex(256-dec((b0))

  # @ asrs rd, <#imm> --> #imm: 0-31
  # movs r6, #32        @ r6 = #32
  asrs r7, r6         @ r7 = -(b0) >> 32

  ands r7, r5         @ r7 = tmp = s01 & (-(b0) >> 32)
  negs r7, r7         @ r7 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r7, r6         @ r7 = -tmp >> 32

  ands r2, r7         @ r2 = s & (-tmp >> 32) = (b0*s01)

  eors r1, r2         @ r1 = r01^(a0*s01)^[a0*(b1^s01)]^(b0*s01)

  eors r2, r2         @ r2 = 0, clearing (b0*s01)
  
@@@@ r0 = b0, r1 = r01^(a0*s01)^[a0*(b1^s01)]^(b0*s01), r2 = 0, r3 = 256
@@@@ r4 = &table, r5 = s01, r6 = 32, r7 = -tmp >> 32, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &rnd
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@ b0*(a1^s01)
@@@@ c0 = (a0*b0)^[r01^(a0*s01)^[a0*(b1^s01)]^(b0*s01)^[b0*(a1^s01)]]

  mov  r7, r9         @ r7 = &a
  ldrb r2, [r7, #4]   @ r2 = a1
  eors r5, r2         @ r5 = a1^s01
  ldrb r7, [r4, r0]   @ r7 = table[b0]
  ldrb r6, [r4, r5]   @ r6 = table[a1^s01]
  
  adds r7, r6         @ r7 = s = table[b0]+table[a1^s01]

  @@@@ Get the antilog: s = table[s+256]: g+s
 # movs r3, #250       @ r3 = 250, 256 is not possible, so it is split: 250+6
 # adds r3, #6         @ r3 = 256
  
  adds r7, r3         @ r7 = s+256

  ldrb r6, [r4, r7]   @ r6 = s = table[s+256]

  # @@@@ Checking if b0 = 0 or a1^s01 = 0, return 0; without conditional branch
  negs r7, r0         @ r7 = -b0 hex(256-dec(b0))

  # @@ b0 in r0 is not needed any more
  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r0, #32        @ r0 = #32
  asrs r7, r0         @ r7 = -b0 >> 32

  ands r5, r7         @ r5 = tmp = (a1^s01) & (-b0 >> 32)
  negs r5, r5         @ r5 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r5, r0         @ r5 = -tmp >> 32

  ands r6, r5         @ r6 = s & (-tmp >> 32) = (b0*(a1^s01))

  eors r1, r6         @ r1 = r01^(a0*s01)^[a0*(b1^s01)]^(b0*s01)^(b0*(a1^s01))



@@@@ r0 = 32, r1 = r01^(a0*s01)^[a0*(b1^s01)]^(b0*s01)^(b0*(a1^s01)), r2 = a1, r3 = 256
@@@@ r4 = &table, r5 = -tmp >> 32, r6 = (b0*(a1^s01)), r7 = -b0 >> 32, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &rnd
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ c0 = (a0*b0)^[r01^(a0*s01)^[a0*(b1^s01)]^(b0*s01)^[b0*(a1^s01)]]

  mov  r6, r8         @ r6 = &c and also clearing (b0*(a1^s01))
  ldrb r7, [r4, #0]   @ r7 = 0, Clearing the read bus (b0*(a1^s01))
  ldrb r0, [r6, #0]   @ r0 = a0*b0
  strb r7, [r6, #0]   @ r7 = 0, Clearing &c+#0 which contains a0*b0, and also clearing the write bus

  eors r1, r0         @ r1 = c0
  eors r0, r0         @ r0 = 0, removing a0*b0
  strb r1, [r6, #0]   @ r1 = c0, storing c0 in  &c+#0
  strb r0, [r6, #4]   @ r0 = 0, Clearing the write bus

  ands r1, r0         @ r1 = 0, clearing c0
  ands r0, r3         @ r0 = 0, clearing the pipeline registers



@@@@@@@@@@ Computing:  c1 = (a1*b1)^r01 = (a1*b1)^rnd2

@@@@ r0 = 0, r1 = 0, r2 = a1, r3 = 256
@@@@ r4 = &table, r5 = tmp >> 32, r6 = &c, r7 = 0, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = &rnd
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ a1*b1
@@@@ c1 = (a1*b1)^r01

  mov  r0, r10        @ r5 = &b
  mov  r1, r11        @ r7 = &rnd

  ldrb r5, [r0, #4]   @ r5 = b1
  ldrb r7, [r1, #8]   @ r7 = r01

  ldrb r0, [r4, r2]   @ r0 = table[a1]
  ldrb r1, [r4, r5]   @ r1 = table[b1]

  adds r0, r1         @ r0 = s = table[a1]+table[b1]

  # @@@@ Get the antilog: s = table[s+256]: g+s
  # movs r3, #250       @ r3 = 250, 256 is not possible, so it is split: 250+6
  # adds r3, #6         @ r3 = 256

  adds r0, r3         @ r0 = s+256

  ldrb r1, [r4, r0]   @ r1 = s = table[s+256]

  # @@@@ Checking if a1 = 0 or b1 = 0, return 0; without conditional branch
  negs r0, r2         @ r0 = -a1 hex(256-dec(a1))

  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r3, #32        @ r3 = #32
  asrs r0, r3         @ r0 = -a1 >> 32

  # @@@@ b1 is not used in the rest computation of
  ands r5, r0         @ r5 = tmp = b1 & (-a1 >> 32)
  negs r5, r5         @ r5 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r5, r3         @ r5 = -tmp >> 32

  ands r1, r5         @ r1 = s & (-tmp >> 32) = (a1*b1)

  eors r1, r7         @ r1 = (a1*b1)^r01
  
  # @ Storing c1 in [&c+#4]
  strb r1, [r6, #4]   @ r1 = (a1*b1), Storing (a1*b1) in &c+#0


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
