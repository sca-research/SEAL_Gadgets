@ISW2_B

@  ^: xor; +: arithmathic addition; x & y: and operation; *: Galois field multiplication; &x: the address of x

@ a = a0^a1, b = b0^b1, c = c0^c1, a*b = c, random numbers: rnd

@@@@ c0 = (a0*b0)^rnd
@@@@ c1 = [((a0*b1)^rnd)^(a1*b0)]^(a1*b1)

.syntax unified
  .text
  .thumb

  .extern table       @@@@ table is used for GFMULT (ai*bj multiplications)

@@@@ extern void Isw_2(uint8_t* inputa: addres: r0, uint8_t* inputb: address: r1, uint8_t* rnd: address: r2, uint8_t* output: address: r3);
@inputa: a0, a1, inputb: b0, b1, rnd: rnd, output: c: c0, c1
@@@@ extern void Isw_2(r0, r1, r2, r3);

.global Isw_2
.func Isw_2
Isw_2:

  push  {lr}
  push  {r4-r9}

@@@@@ r0 = &a, r1 = &b, r2 = &r, r3 = &c
@@@@@ Saving r3 (the address of the output)
  mov r8, r3    @r8 = &c

@@@@@ Loading arguments @@@@@@@@@@@@
  ldrb r2, [r2, #0] @r2 = r ; r0 = &a, r1 = &b, r2 = &rnd, r8 = &c
  ldrb r3, [r0, #0] @r3 = a0; r0 = &a, r1 = &b, r2 =  r, r8 = &c
  ldrb r4, [r0, #1] @r4 = a1; r0 = &a, r1 = &b, r2 =  r, r8 = &c
  ldrb r5, [r1, #0] @r5 = b0; r0 = &a, r1 = &b, r2 =  r, r8 = &c
  ldrb r6, [r1, #1] @r6 = b1; r0 = &a, r1 = &b, r2 =  r, r8 = &c

@@@@@ r2 = r, r3 = a0, r4 = a1, r5 = b0, r6 = b1
@@@@@ r0, r1, r7 can be used

@@@@@@@@@@ Computing c0 = (a0*b0)^r
  mov  r0, r3   @ r0 = a0
  mov  r1, r5   @ r1 = b0
  bl   gfmul    @ r0 = a0*b0

  eors r0, r2   @ r0 = c0 = (a0*b0)^r
  mov  r9, r0   @ saving r0 = c0 

@@@@@@@@@@ Computing c1 = (a1*b1)^([(a0*b1)^r]^(a1, b0))
  mov  r0, r3   @ r0 = a0
  mov  r1, r6   @ r1 = b1
  bl   gfmul    @ r0 = a0*b1

  eors r2, r0   @ r2 = (a0*b1)^r

  mov  r0, r4   @ r0 = a1
  mov  r1, r5   @ r1 = b0
  bl   gfmul    @ r0 = a1*b0

  eors r2, r0   @ r0 = r2:[(a0*b0)^r]^ r0:(a1*b0)

  mov  r0, r4   @ r0 = a1
  mov  r1, r6   @ r0 = b1
  bl   gfmul    @ r0 = a1*b1

  eors r0, r2   @ r0 = c1

  mov r1, r9    @ r1 = c0

  mov  r3, r8   @ r3 = &c (output) 

  strb r1, [r3, #0] @r3 = c0
  strb r0, [r3, #1] @r3 = c1



  pop  {r4-r9}
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

