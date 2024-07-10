@ Dom_indep_2_V1

@  ^: xor; +: arithmathic addition; x & y: and operation; *: Galois field multiplication; &x: the address of x

@ a = a0^a1, b = b0^b1, c = c0^c1, a*b = c, random numbers: rnd

@@@@@ c0 = (a0*b0)^[(a0*b1)^rnd0]
@@@@@ c1 = [(a1*b0)^rnd0]^(a1*b1)

  .syntax unified
  .text
  .thumb
  
  .extern table       @@@@ table is used for GFMULT (ai*bj multiplications)
  
@@@@ extern void Dom_indep_2(uint8_t* inputa: addres: r0, uint8_t* inputb: address: r1, uint8_t* rnd: address: r2, uint8_t* output: address: r3);
@inputa: a0, a1, inputb: b0, b1, rnd: rnd0, output: c: c0, c1
@@@@ extern void Dom_indep_2(r0, r1, r2, r3);

.global Dom_indep_2
.func Dom_indep_2
Dom_indep_2:

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

###############################################
@@@@@ r0 = &a, r1 = &b, r2 = &rnd, r3 = &c

@@@@@ Saving r3 (the address of the output)
  mov  r8, r3        @ r8 = &c


@@@@ Saving the value 256 in r11. This decreases one cycle.
  # @ adds rd, <#imm> --> #imm: 3 bits, 0-7
  # @ movs rd, <#imm> --> #imm: 0-255
  movs r4, #250       @ r4 = 250, 256 is not possible, so it is split: 250+6
  adds r4, #6         @ r4 = 256
  mov  r11, r4        @ r11 = 256


  ldr  r4, =table    @ r4 = &table, The address of the "table", for ai * bj multiplications
@@@@ Reducing the use of LDR instruction: ldr rx,=table @ rx = &table; --> mov rx, r11 
  mov  r9, r4        @ r9 = &table

nop
nop
nop
nop


@@@@ r0 = &a, r1 = &b, r2 = &rnd, r4 = &table
@@@@ r8 = &c, r9 = &table, r11 = 256
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@ Loading arguments @@@@@@@@@@@@
  ldrb r6, [r0, #0] @ r6 = a0; r0 = &a, r1 = &b, r2 = rnd
  ldrb r2, [r2, #0] @ r2 = rnd;r0 = &a, r1 = &b
  ldrb r5, [r1, #0] @ r5 = b0; r0 = &a, r1 = &b, r2 = rnd
  ldrb r3, [r0, #4] @ r3 = a1; r0 = &a, r1 = &b, r2 = rnd
  ldrb r7, [r1, #4] @ r7 = b1; r0 = &a, r1 = &b, r2 = rnd


@@@@@@@@@ Computing c0 = (a0 * b0)^[(a0 * b1)^rnd0]

@@@@ r0 = &a, r1 = &b, r2 = rnd, r4 = &table
@@@@ r3 = a1, r5 = b0, r6 = a0, r7 = b1, 
@@@@ r8 = &c, r9 = &table, r11 = 256 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ a0 * b0

  ldrb r0, [r4, r6]   @ r0 = table[a0]
  ldrb r1, [r4, r5]   @ r1 = table[b0]

  adds r0, r1         @ r0 = s = table[a0]+table[b0]

  @@@@ Get the antilog: s = table[s+256]: g+s
  mov  r1, r11        @ r1 = 256

  adds r0, r1         @ r0 = s+256

  ldrb r1, [r4, r0]   @ r1 = s = table[s+256]

  # @@@@ Checking if a0 = 0 or b0 = 0, return 0; without conditional branch
  negs r0, r6         @ r0 = -a0 hex(256-dec(a0))

  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r4, #32        @ r4 = #32
  asrs r0, r4         @ r0 = -a0 >> 32

  ands r0, r5         @ r0 = tmp = b0 & (-a0 >> 32)
  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r4         @ r0 = -tmp >> 32

  ands r1, r0         @ r1 = s & (-tmp >> 32) = (a0 * b0)
  mov  r10, r1        @ r10 = a0 * b0


@@@@ r0 = -tmp >> 32, r1 = a0 * b0, r2 = rnd, r4 = 32
@@@@ r3 = a1, r5 = b0, r6 = a0, r7 = b1, 
@@@@ r8 = &c, r9 = &table, r10 = a0 * b0, r11 = 256
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ a0 * b1

  mov  r1, r9         @ r1 = &table 
  ldrb r0, [r1, r6]   @ r0 = table[a0]
  ldrb r4, [r1, r7]   @ r4 = table[b1]

  adds r0, r4         @ r0 = s = table[a0]+table[b1]

  @@@@ Get the antilog: s = table[s+256]: g+s
  mov  r4, r11        @ r4 = 256

  adds r0, r4         @ r0 = s+256

  ldrb r4, [r1, r0]   @ r4 = s = table[s+256]

  # @@@@ Checking if a0 = 0 or b1 = 0, return 0; without conditional branch
  negs r0, r6         @ r0 = -a0 hex(256-dec(a0))

  # @ asrs rd, <#imm> --> #imm: 0-31
  @ a0 in r6 is not needed anymore, r6 can be used
  movs r6, #32        @ r6 = #32
  asrs r0, r6         @ r0 = -a0 >> 32

  ands r0, r7         @ r0 = tmp = b1 & (-a0 >> 32)
  negs r0, r0         @ r0 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r0, r6         @ r0 = -tmp >> 32

  ands r0, r4         @ r0 = s & (-tmp >> 32) = (a0 * b1)

  eors r4, r4         @ Removing a0*b1, for avoiding REG HD

  @@@@ (a0 * b1)^rnd

  eors r0, r2         @ r0 = (a0 * b1)^rnd

  
  @@@@ (a0 * b0)^[(a0 * b1)^rnd0]
  mov  r4, r10        @ r4 = a0 * b0
  eors r0, r4         @ r0 = c0 = (a0 * b0)^[(a0 * b1)^rnd0]
  mov  r4, r8         @ r4 = &c
  strb r0, [r4, #0]   @ Storing c0, r0 = c0

@@@@@@@@@ Computing c1 = [(a1 * b0)^rnd]^(a1 * b1)

@@@@ r0 = c0, r1 = &table, r2 = rnd, r4 = &c
@@@@ r3 = a1, r5 = b0, r6 = 32, r7 = b1, 
@@@@ r8 = &c, r9 = &table, r10 = &c, r11 = 256
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ a1 * b0

  ldrb r0, [r1, r3]   @ r0 = table[a1]
  ldrb r4, [r1, r5]   @ r4 = table[b0]

  adds r0, r4         @ r0 = s = table[a1]+table[b0]

  @@@@ Get the antilog: s = table[s+256]: g+s
  mov  r4, r11        @ r4 = 256

  adds r0, r4         @ r0 = s+256

  ldrb r4, [r1, r0]   @ r4 = s = table[s+256]

  # @@@@ Checking if a1 = 0 or b0 = 0, return 0; without conditional branch
  negs r0, r3         @ r0 = -a1 hex(256-dec(a1))

  # @ asrs rd, <#imm> --> #imm: 0-31
  # movs r6, #32        @ r6 = #32
  asrs r0, r6         @ r0 = -a1 >> 32

@ b0 in r5 is not neede any more, r5 can be used
  ands r5, r0         @ r5 = tmp = b0 & (-a1 >> 32)
  negs r5, r5         @ r5 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r5, r6         @ r5 = -tmp >> 32

  ands r5, r4         @ r5 = s & (-tmp >> 32) = (a1 * b0)
 

  @@@@ (a1 * b0)^rnd
  @ rnd in r2 is not needed any more, r2 can be used

  eors r2, r5         @ r2 = (a1 * b0)^rnd

  eors r5, r5         @ Removing Neighbouring effects

@@@@ r0 = -a1 >> 32, r1 = &table, r2 = (a1 * b0)^rnd, r4 = table[s+256]
@@@@ r3 = a1, r5 = (a1 * b0), r6 = 32, r7 = b1, 
@@@@ r8 = &c, r9 = &table, r10 = &c, r11 = 256
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@ a1 * b1

  ldrb r6, [r1, r3]   @ r6 = table[a1]
  ldrb r4, [r1, r7]   @ r4 = table[b1]

  adds r6, r4         @ r6 = s = table[a1]+table[b1]

  @@@@ Get the antilog: s = table[s+256]: g+s
  mov  r0, r11        @ r0 = 256

  adds r6, r0         @ r6 = s+256

  ldrb r4, [r1, r6]   @ r4 = s = table[s+256]

  # @@@@ Checking if a1 = 0 or b1 = 0, return 0; without conditional branch
  negs r6, r3         @ r6 = -a1 hex(256-dec(a1))

  # @ asrs rd, <#imm> --> #imm: 0-31
  movs r5, #32        @ r5 = #32
  asrs r6, r5         @ r6 = -a1 >> 32

  ands r6, r7         @ r6 = tmp = b1 & (-a1 >> 32)
  negs r6, r6         @ r6 = -tmp

  # @ asrs rd, <#imm> --> #imm: 0-31
  asrs r6, r5         @ r6 = -tmp >> 32

  ands r4, r6         @ r4 = s & (-tmp >> 32) = (a1 * b1)
  

  @@@@ c1 = [(a1 * b0)^rnd]^(a1 * b1)

  eors r2, r4         @ r2 =  [((a0 * b1)^rnd)^(a1 * b0)]^(a1 * b1)
  mov  r4, r8         @ r4 = &c

  strb r4, [r4, #4]   @ Clearing the write bus, r4 = &c
  strb r2, [r4, #4]   @ Storing c1, r2 = c1


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
