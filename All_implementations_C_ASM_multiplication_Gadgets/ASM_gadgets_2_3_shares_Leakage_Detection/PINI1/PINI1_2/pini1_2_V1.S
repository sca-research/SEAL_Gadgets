@ PINI1_2_V1

@ a = a0^a1, b = b0^b1, c = c0^c1, a * b = c, random numbers: rnd0

@  ^: xor; +: arithmathic addition; x & y: and operation; *: Galois field multiplication; &x: the address of x

@@@@ c0 = (a0*b0)^[(a0^1)*rnd]^[a0*(b1^rnd)]
@@@@ c1 = (a1*b1)^[(a1^1)*rnd]^[a1*(b0^rnd)]

.syntax unified
  .text
  .thumb

  .extern table       @@@@ table is used for GFMULT (ai * bj multiplications)

@@@@ extern void Pini1_2(uint8_t* inputa: addres: r0, uint8_t* inputb: address: r1, uint8_t* rnd: address: r2, uint8_t* output: address: r3);
@inputa: a0, a1, inputb: b0, b1, rnd: rnd, output: c: c0, c1
@@@@ extern void Pini1_2(r0, r1, r2, r3);

.global Pini1_2
.func Pini1_2
Pini1_2:

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


@@@@ Saving the value 256 in r11. This decreases one cycle.
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r3, #250       @ r3 = 250, 256 is not possible, so it is split: 250+6
  adds r3, #6         @ r3 = 256
  mov  r11, r3        @ r11 = 256

@@@@@ Saving the address of the "table"
  ldr  r4, =table    @ r4 = &table, The address of the "table", for ai*bj multiplications

nop
nop
nop
nop

@@@@@@@@@@ Computing: c0 = (a0*b0)^[(a0^1)*rnd]^[a0*(b1^rnd)]

@@@@ r0 = &a, r1 = &b, r2 = &rnd, r3 = 256
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = 256
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@ Loading arguments @@@@@@@@@@@@

# fake leakage: from 160 cycles: Leaky cycles: [17, 18]
@ ldrb r6, [r0, #4] @ r6 = a1; r0 = &a, r1 = &b, r2 = &rnd

  ldrb r6, [r0, #0] @ r6 = a0; r0 = &a, r1 = &b, r2 = &rnd
  ldrb r7, [r1, #4] @ r7 = b1; r0 = &a, r1 = &b, r2 = &rnd
  ldrb r2, [r2, #0] @ r2 = rnd;r0 = &a, r1 = &b
  ldrb r5, [r1, #0] @ r5 = b0; r0 = &a, r1 = &b, r2 = rnd
  # ldrb r3, [r0, #4] @ r3 = a1; r0 = &a, r1 = &b, r2 = rnd, a1 is not used in computing c0
  
@@@@ c0 = (a0*b0)^[(a0^1)*rnd]^[a0*(b1^rnd)]
@@@@ c1 = (a1*b1)^[(a1^1)*rnd]^[a1*(b0^rnd)]

@@@@ r0 = &a, r1 = &b, r2 = rnd, r3 = 256
@@@@ r4 = &table, r5 = b0, r6 = a0, r7 = b1, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = 256
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^[(a0^1)*rnd]^[a0*(b1^rnd)]

@@@@ a0*b0

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
  movs r3, #32        @ r3 = #32
  asrs r0, r3         @ r0 = -a0 >> 32

  # @@@@ b0 is not used in the rest computation of c0
  ands r5, r0         @ r5 = tmp = b0 & (-a0 >> 32)
  negs r5, r5         @ r5 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r5, r3         @ r5 = -tmp >> 32

  ands r1, r5         @ r1 = s & (-tmp >> 32) = (a0*b0)

  # @ Storing (a0*b0) in [&c+#0]
  mov  r5, r8         @ r5 = &c
  strb r1, [r5, #0]   @ r1 = (a0*b0), Storing (a0*b0) in &c+#0
  movs r0, #1         @ r0 = 1, for avoiding stall
  eors r1, r1         @ r1 = 0, Clearing (a0*b0) from r1
  
@@@@ r0 = 1, r1 = 0, r2 = rnd, r3 = 32
@@@@ r4 = &table, r5 = &c, r6 = a0, r7 = b1, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = 256
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^[(a0^1)*rnd]^[a0*(b1^rnd)]

@@@@ (a0^1)*rnd

  eors r6, r0         @ r6 = a0^1
  ldrb r1, [r4, r2]   @ r1 = table[rnd]     
  ldrb r0, [r4, r6]   @ r0 = table[a0^1]

  adds r0, r1         @ r0 = s = table[a0^1]+table[rnd]

  # @@@@ Get the antilog: s = table[s+256]: g+s
  # movs r5, #250       @ r5 = 250, 256 is not possible, so it is split: 250+6
  # adds r5, #6         @ r5 = 256
  mov  r5, r11        @ r5 = 256

  adds r0, r5         @ r0 = s+256

  ldrb r1, [r4, r0]   @ r1 = s = table[s+256]

  # @@@@ Checking if a0 = 0 or b0 = 0, return 0; without conditional branch
  negs r0, r6         @ r0 = -(a0^1) hex(256-dec((a0^1)))

  # @ asrs rd, <#imm> --> #imm: 0-31
  # movs r3, #32        @ r3 = #32
  asrs r0, r3         @ r0 = -(a0^1) >> 32

  ands r0, r2         @ r0 = tmp = rnd & (-(a0^1) >> 32)
  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r3         @ r0 = -tmp >> 32

  ands r1, r0         @ r1 = s & (-tmp >> 32) = ((a0^1)*rnd)

  
@@@@ r0 = -tmp >> 32, r1 = ((a0^1)*rnd), r2 = rnd, r3 = 32
@@@@ r4 = &table, r5 = 256, r6 = a0^1, r7 = b1, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = 256
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^[(a0^1)*rnd]^[a0*(b1^rnd)]

@@@@ a0*(b1^rnd)
  
  movs r0, #1         @ r0 = 1
  eors r6, r0         @ r6 = a0
  eors r7, r2         @ r7 = b1^rnd
  ldrb r0, [r4, r6]   @ r0 = table[a0]
  ldrb r3, [r4, r7]   @ r3 = table[b1^rnd]
  
  adds r0, r3         @ r0 = s = table[a0]+table[b1^rnd]

  @@@@ Get the antilog: s = table[s+256]: g+s
 # # movs r5, #250       @ r5 = 250, 256 is not possible, so it is split: 250+6
 # # adds r5, #6         @ r5 = 256
  # mov  r5, r11        @ r5 = 256

  adds r0, r5         @ r0 = s+256

  ldrb r3, [r4, r0]   @ r3 = s = table[s+256]

  # @@@@ Checking if a0 = 0 or b0 = 0, return 0; without conditional branch
  negs r0, r6         @ r0 = -a0 hex(256-dec(a0))

  # @@ a0 is not needed any more
  eors r6, r6         @ r6 = 0
  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r5, #32        @ r5 = #32
  asrs r0, r5         @ r0 = -a0 >> 32

  ands r0, r7         @ r0 = tmp = (b1^rnd) & (-a0 >> 32)
  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r5         @ r0 = -tmp >> 32

  ands r3, r0         @ r3 = s & (-tmp >> 32) = (a0 *(b1^rnd))


@@@@ r0 = -tmp >> 32, r1 = ((a0^1)*rnd), r2 = rnd, r3 = (a0 *(b1^rnd))
@@@@ r4 = &table, r5 = 32, r6 = 0, r7 = b1^rnd, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = 256
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c0 = (a0*b0)^[(a0^1)*rnd]^[a0*(b1^rnd)]

  eors r3, r1         @ r3 = [(a0^1)*rnd]^[a0*(b1^rnd)]
  eors r1, r1         @ r1 = 0, clearing ((a0^1)*rnd), Clearing the read bus
  mov  r0, r8         @ r0 = &c
  ldrb r1, [r4, #0]   @ r1 = 0, Clearing the read bus, table[0] = 0, as it contains (a0 *(b1^rnd))
  ldrb r5, [r0, #0]   @ r5 = a0*b0
  ldrb r1, [r4, #0]   @ r1 = 0, Clearing the read bus, table[0] = 0, as it contains (a0*b0) 
  eors r5, r3         @ r5 = c0 = (a0*b0)^[(a0^1)*rnd]^[a0*(b1^rnd)]
  mov  r3, r11        @ r3 = 256, for clearing [(a0^1)*rnd]^[a0*(b1^rnd)], and avoiding stall
  strb r5, [r0, #0]   @ r5 = c0, Storing c0
  strb r1, [r0, #4]   @ r1 = 0, Clearing the write bus
  eors r5, r5         @ r5 = 0, learing c0


@@@@@@@@@@ Computing: c1 = (a1*b1)^[(a1^1)*rnd]^[a1*(b0^rnd)]

@@@@ r0 = &c, r1 = 0, r2 = rnd, r3 = 256
@@@@ r4 = &table, r5 = 0, r6 = 0, r7 = b1^rnd, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = 256
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c1 = (a1*b1)^[(a1^1)*rnd]^[a1*(b0^rnd)]

@@@@ (a1*b1)

  mov  r0, r9       @ r0 = &a
  eors r7, r2       @ r7 = b1

@ # fake leakage: 160cycles: Leaky cycles: [89, 90]
@ ldrb r6, [r0, #0] @ r6 = a0;   

  ldrb r6, [r0, #4] @ r6 = a1;   

  ldrb r0, [r4, r6]   @ r0 = table[a1]
  ldrb r1, [r4, r7]   @ r1 = table[b1]

  adds r0, r1         @ r0 = s = table[a1]+table[b1]

  # @@@@ Get the antilog: s = table[s+256]: g+s
  # movs r3, #250       @ r3 = 250, 256 is not possible, so it is split: 250+6
  # adds r3, #6         @ r3 = 256

  adds r0, r3         @ r0 = s+256

  ldrb r1, [r4, r0]   @ r1 = s = table[s+256]

  # @@@@ Checking if a1 = 0 or b1 = 0, return 0; without conditional branch
  negs r0, r6         @ r0 = -a1 hex(256-dec(a1))

  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r5, #32        @ r5 = #32
  asrs r0, r5         @ r0 = -a1 >> 32

  # @@@@ b1 is not used in the rest computation of c1
  ands r7, r0         @ r7 = tmp = b1 & (-a1 >> 32)
  negs r7, r7         @ r7 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r7, r5         @ r7 = -tmp >> 32

  ands r7, r1         @ r7 = s & (-tmp >> 32) = (a1*b1)

  eors r1, r1         @ r1 = 0, clearing table[s+256]

  
@@@@ r0 = -a1 >> 32, r1 = 0, r2 = rnd, r3 = 256
@@@@ r4 = &table, r5 = 32, r6 = a1, r7 = a1*b1, 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = 256
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c1 = (a1*b1)^[(a1^1)*rnd]^[a1*(b0^rnd)]

@@@@ (a1^1)*rnd

  movs r0, #1         @ r0 = 1
  eors r6, r0         @ r6 = a1^1
  ldrb r1, [r4, r2]   @ r1 = table[rnd]     
  ldrb r0, [r4, r6]   @ r0 = table[a1^1]

  adds r0, r1         @ r0 = s = table[a1^1]+table[rnd]

#   # @@@@ Get the antilog: s = table[s+256]: g+s
#   # movs r3, #250       @ r3 = 250, 256 is not possible, so it is split: 250+6
#   # adds r3, #6         @ r3 = 256
#   mov  r3, r11        @ r3 = 256

  adds r0, r3         @ r0 = s+256

  ldrb r1, [r4, r0]   @ r1 = s = table[s+256]

  # @@@@ Checking if a1 = 0 or b0 = 0, return 0; without conditional branch
  negs r0, r6         @ r0 = -(a1^1) hex(256-dec((a1^1)))

  # @ asrs rd, <#imm> --> #imm: 0-31
  # movs r5, #32        @ r5 = #32
  asrs r0, r5         @ r0 = -(a1^1) >> 32

  ands r0, r2         @ r0 = tmp = rnd & (-(a1^1) >> 32)
  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r5         @ r0 = -tmp >> 32

  ands r1, r0         @ r1 = s & (-tmp >> 32) = ((a1^1)*rnd)
  # mov  r3, r8         @ r3 = &c
  # strb r1, [r3, #4]   @ Storing ((a1^1)*rnd) in &c+#0
  # eors r1, r1         @ r1 = 0, Clearing ((a1^1)*rnd)
  
  
@@@@ r0 = -tmp >> 32, r1 = ((a1^1)*rnd), r2 = rnd, r3 = 256
@@@@ r4 = &table, r5 = 32, r6 = a1^1, r7 = (a1*b1), 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = 256
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@ c1 = (a1*b1)^[(a1^1)*rnd]^[a1*(b0^rnd)]

@@@@ a1*(b0^rnd)

  movs r0, #1         @ r0 = 1
  eors r6, r0         @ r6 = a1
  mov  r0, r10        @ r0 = &b
  ldrb r5, [r0, #0]   @ r5 = b0   
  eors r5, r2         @ r5 = b0^rnd  @ r2 = rnd is not needed any more

  ldrb r0, [r4, r6]   @ r0 = table[a1]
  ldrb r2, [r4, r5]   @ r2 = table[b0^rnd]
  

  adds r0, r2         @ r0 = s = table[a1]+table[b0^rnd]

#   @@@@ Get the antilog: s = table[s+256]: g+s
#  # # movs r3, #250       @ r3 = 250, 256 is not possible, so it is split: 250+6
#  # # adds r3, #6         @ r3 = 256
#   # mov  r3, r11         @ r3 = 256

  adds r0, r3         @ r0 = s+256

  ldrb r2, [r4, r0]   @ r2 = s = table[s+256]

  # @@@@ Checking if a1 = 0 or b0 = 0, return 0; without conditional branch
  negs r0, r6         @ r0 = -a1 hex(256-dec(a1))

  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r3, #32        @ r3 = #32
  asrs r0, r3         @ r0 = -a1 >> 32

  ands r0, r5         @ r0 = tmp = (b0^rnd) & (-a1 >> 32)
  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r3         @ r0 = -tmp >> 32

  ands r2, r0         @ r2 = s & (-tmp >> 32) = (a1 *(b0^rnd))


@@@@ r0 = -tmp >> 32, r1 = ((a1^1)*rnd), r2 = (a1 *(b0^rnd)), r3 = 32
@@@@ r4 = &table, r5 = b0^rnd, r6 = a1, r7 = (a1*b1), 
@@@@ r8 = &c, r9 = &a, r10 = &b, r11 = 256
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ c1 = (a1*b1)^[(a1^1)*rnd]^[a1*(b0^rnd)]

  eors r2, r1         @ r2 = [(a1^1)*rnd]^[a1*(b0^rnd)]
  mov  r0, r8         @ r0 = &c
  eors r7, r2         @ r5 = c1 = (a1*b1)^[(a1^1)*rnd]^[a1*(b0^rnd)]
  strb r7, [r0, #4]   @ r5 = c1, Storing c1


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
