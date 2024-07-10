@ Bbpp_opt_3_B

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
  push  {r4-r11}

  
@@@@@ r0 = &a, r1 = &b, r2 = &rnd, r3 = &c

@@@@@ Saving r3 (the address of the output)
  mov  r11, r3     @ r11 = &c

@@@@@ Saving r0 (the address of the input rnd)
  mov  r10, r2     @ r10 = &rnd

@@@ r0 and r1 are used in gfmul function as arguments, they have to be saved
@@@@@ Saving r1 (the address of the input b)
  mov  r9, r1      @ r9 = &b

@@@@@ Saving r0 (the address of the input a)
  mov  r8, r0      @ r8 = &a


@@@@@@@@@@ Computing: ci
@@@@ c0 = (a0*b0)^rnd0^(a0*b2)^(a2*b0)

  ldrb r4, [r0, #0] @r4 = a0; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r5, [r0, #2] @r5 = a2; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r6, [r1, #0] @r6 = b0; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r7, [r1, #2] @r7 = b2; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r3, [r2, #0] @r3 = rnd0; r0 = &a, r1 = &b, r2 = &rnd
  mov  r10, r3      @ r10 = rnd0

  mov  r0, r4   @ r0 = a0
  mov  r1, r6   @ r1 = b0 
  bl   gfmul    @ r0 = a0*b0

  eors r3, r0   @ r3 = (a0*b0)^rnd0

  mov  r0, r4   @ r0 = a0
  mov  r1, r7   @ r1 = b2 
  bl   gfmul    @ r0 = a0*b2

  eors r3, r0   @ r3 = (a0*b0)^rnd0^(a0*b2)

  mov  r0, r5   @ r0 = a2
  mov  r1, r6   @ r1 = b0 
  bl   gfmul    @ r0 = a2*b0

  eors r0, r3   @ r0 = c0 = (a0*b0)^rnd0^(a0*b2)^(a2*b0)

  mov  r3, r11
  strb r0, [r3, #0] @r2 = c0 @ Storing c0 in c0



@@@@ From previous step:r2 =, r3 = &c, r4 = a0, r5 = a2, r6 = b0, r7 = b2, r8 = &a, r9 = &b, r10 = rnd0, r11 = &c
  @@@@ c1 = (a1*b1)^rnd1^(a0*b1)^(a1*b0)
    mov  r0, r8      @ r0 = &a
    mov  r1, r9      @ r1 = &b
    ldrb r5, [r0, #1]  @ r5 = a1 @ using r5 to avoid loading a1 again
    ldrb r7, [r1, #1]  @ r7 = b1 @ using r7 to avoid loading b1 again
    ldrb r3, [r2, #1]  @ r3 = rnd1
    mov  r2, r3        @ r2 = rnd1

    mov  r0, r5     @ r0 = a1
    mov  r1, r7     @ r1 = b1
    bl   gfmul      @ r0 = a1*b1

    eors r3, r0     @ r3 = (a1*b1)^rnd1

    mov  r0, r4     @ r0 = a0
    @ r1 has not changed: mov  r1, r7   @ r1 = b1
    bl   gfmul      @ r0 = a0*b1

    eors r3, r0     @ r3 = (a1*b1)^rnd1^(a0*b1)
    

    mov  r0, r5     @ r0 = a1
    mov  r1, r6     @ r1 = b0
    bl   gfmul      @ r0 = a0*b1

    eors r0, r3     @ r0 = (a1*b1)^rnd1^(a0*b1)^(a1*b0)
    
    mov  r3, r11
    strb r0, [r3, #1] @r0 = c1 @ Storing c1 in c1


@@@@ From previous step:r2 = rnd1, r3 = &c, r4 = a0, r5 = a1, r6 = b0, r7 = b1, r8 = &a, r9 = &b, r10 = rnd0, r11 = &c
  @@@@ c2 = (a2*b2)^rnd0^rnd1^(a1*b2)^(a2*b1)
    mov  r0, r8      @ r0 = &a
    mov  r1, r9      @ r1 = &b
    ldrb r4, [r0, #2]  @ r4 = a2 @ using r4 to avoid loading a1 again
    ldrb r6, [r1, #2]  @ r6 = b2 @ using r6 to avoid loading b1 again
  

    mov  r0, r4     @ r0 = a2
    mov  r1, r6     @ r1 = b2
    bl   gfmul      @ r0 = a2*b2

    mov  r3, r10    @ r3 = rnd0
    eors r3, r0     @ r3 = (a2*b2)^rnd0
    eors r3, r2     @ r3 = (a2*b2)^rnd0^rnd1


    mov  r0, r5     @ r0 = a1
    @ r1 has not changed: mov  r1, r6   @ r1 = b2
    bl   gfmul      @ r0 = a1*b2

    eors r3, r0     @ r3 = (a2*b2)^rnd0^rnd1^(a1*b2)


    mov  r0, r4     @ r0 = a2
    mov  r1, r7     @ r1 = b1
    bl   gfmul      @ r0 = a2*b1

    eors r0, r3     @ r3 = c2 = (a2*b2)^rnd0^rnd1^(a1*b2)^(a2*b1)

    mov  r3, r11
    strb r0, [r3, #2] @r0 = c2 @ Storing c2 in c2


  pop  {r4-r11}
  pop  {pc}
  .endfunc 




@@@@@ uint8_t gfmul(uint8_t a, uint8_t b); For calculating: input_a[i]*input_b[j]
@@@@@@@@ gfmul(in_r0:a, in_r1: b, out_r0: return)

.global gfmul
.func gfmul
gfmul:
	push	 {r2-r5}

    ldr  r2, =table     @ the address of the  "table"

    ldrb r3, [r2, r0]   @ r3 = table[a] 
    ldrb r4, [r2, r1]   @ r4 = table[b] 
    adds r3, r4         @ r3 = s = table[a]+table[b]

    @@@@ Get the antilog: s = table[s+256]: g+s 
    adds r3, #128       @ r3 = s+128 :s+256; : 256 is more than one byte, split: 128+128
    adds r3, #128       @ r3 = s+256
    ldrb r4, [r2, r3]   @ r4 = s = table[s+256]

    @@@@ Checking if a = 0 or b = 0, return 0; without conditional branch
    negs r5, r0         @ r5 = -a
    asrs r5, #32        @ r5 = -a >> 8  (4*8=32)
    ands r5, r1         @ r5 = tmp = b & (-a >> 8)
    negs r5, r5         @ r5 = -tmp 
    asrs r5, #32        @ r5 = -tmp >> 8
    ands r4, r5         @ r4 = s & (-tmp >> 8)
    mov  r0, r4

	pop {r2-r5}
	
  bx lr
.endfunc
.end
