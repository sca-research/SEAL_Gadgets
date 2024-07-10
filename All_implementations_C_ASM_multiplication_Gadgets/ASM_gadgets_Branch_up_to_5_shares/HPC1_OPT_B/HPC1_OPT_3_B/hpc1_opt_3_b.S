@ HPC1_OPT_3_B

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
  push  {r4-r11}

@@@@@ r0 = &a, r1 = &b, r2 = &rnd, r3 = &c

@@@@@ Saving r3 (the address of the output)
  mov  r11, r3    @ r11 = &c

@@@@@ Saving r2 (the address of the input rnd)
  mov  r10, r2     @ r10 = &rnd

@@@@@ Saving r1 (the address of the input b)
  mov  r9, r1    @ r9 = &b

@@@@@ Saving r0 (the address of the input a)
  mov  r8, r0    @ r8 = &a

@@@@@ Optimized Refresh Mask:
  ldrb r4, [r2, #0] @ r4 = rnd0; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r5, [r2, #1] @ r5 = rnd1; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  
  ldrb r6, [r1, #0] @ r6 = b0; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r7, [r1, #1] @ r7 = b1; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r2, [r1, #2] @ r2 = b2; r0 = &a, r1 = &b, r2 = b2  , r3 = &c

  eors r6, r4       @ r6 = ref_b0  @ ref_b0 = b0 ^ rnd0
  eors r7, r5       @ r7 = ref_b1  @ ref_b1 = b1 ^ rnd1
  eors r5, r4       @ r5 = rnd0 ^ rnd1
  eors r2, r5       @ r2 = ref_b2  @ ref_b2 = b1 ^ (rnd0 ^ rnd1)
@ The values of ref_b0, ref_b1, ref_b2  have to be stored, in case if registers r6, r7, r2 be changed
@ But here, just for computing c2, ref_b1 is needed to be load, so then just ref_b1 is saved 
  strb r7, [r1, #1] @ Saving ref_b1 in &b+1

@@@@@ Loading arguments @@@@@@@@@@@@
  ldrb r4, [r0, #0] @ r4 = a0; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r5, [r0, #1] @ r5 = a1; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  


@@@@@@@@@@ Computing: ai * ref_bi
@@@@@@ In gfmul, r0 and r1 are the arguments
@@@@ a0 * ref_b0
  mov  r0, r4   @ r0 = a0
  mov  r1, r6   @ r1 = ref_b0
  bl   gfmul    @ r0 = a0 * ref_b0
  
  strb r0, [r3, #0] @ Storing (a0 * ref_b0) in c0

@@@@ a1 * ref_b1
  mov  r0, r5   @ r0 = a1
  mov  r1, r7   @ r1 = ref_b1
  bl   gfmul    @ r0 = a1 * ref_b1

  strb r0, [r3, #1] @ Storing (a1 * ref_b1) in c1

@@@@ a2 * ref_b2
  mov  r0, r8       @ r0 = &a
  ldrb r0, [r0, #2] @ r0 = a2
  mov  r1, r2       @ r1 = ref_b2
  bl   gfmul        @ r0 = a2 * ref_b2
  
  strb r0, [r3, #2] @ Storing (a2 * ref_b2) in c2


@@@@@@@@@@ Computing: ci

@From previous step: 
@@@@ r2 = ref_b2, r3 = &c, r4 = a0, r5 = a1, r6 = ref_b0
@@@@ r7 = ref_b1, r8 = &a, r9 = &b, r10 = &rnd, r11 = &c

@@@@ c0 = (a0 * ref_b0) ^ [(a0 * ref_b1) ^ rnd2] ^ [(a0 * ref_b2) ^ rnd3]
  mov  r0, r4         @ r0 = a0
  mov  r1, r7         @ r1 = ref_b1
  bl   gfmul          @ r0 = a0 * ref_b1


  mov  r3, r2         @ r3 = ref_b2
  mov  r2, r10        @ r2 = &rnd
  ldrb r7, [r2, #2]   @ r7 = rnd2 // r7 = ref_b1, for computing c1, ref_b1 (alone) is not needed, so, r7 can be used here
  mov  r10, r7        @ r10 = rnd2    @ Saving for using in C1
  eors r7, r0         @ r7 = [(a0 * ref_b1) ^ rnd2]  

  mov  r0, r4         @ r0 = a0
  mov  r1, r3         @ r1 = ref_b2
  bl   gfmul          @ r0 = a0 * ref_b2


  ldrb r1, [r2, #3]   @ r1 = rnd3
  eors r1, r0         @ r1 = [(a0 * ref_b2) ^ rnd3]
  
  mov  r4, r3         @ r4 = ref_b2   @ a0 in r4 is not needed in c1, Saving ref_b2 for using in C1
  mov  r3, r11        @ r3 = &c
  ldrb r0, [r3, #0]   @ r0 = a0 * ref_b0


  eors r0, r7         @ r0 = (a0 * ref_b0) ^ [(a0 * ref_b1) ^ rnd2]
  eors r1, r0         @ r1 = (a0 * ref_b0) ^ [(a0 * ref_b1) ^ rnd2] ^ [(a0 * ref_b2) ^ rnd3]


  strb r1, [r3, #0]   @ Storing c0 in c0



@From previous step: 
@@@@ r2 = &rnd, r3 = &c, r4 = ref_b2, r5 = a1, r6 = ref_b0
@@@@ r7 = , r8 = &a, r9 = &b, r10 = rnd2, r11 = &c

@@@@ c1 = [(a1 * ref_b0) ^ rnd2] ^ (a1 * ref_b1) ^ [(a1 * ref_b2) ^ rnd4]
  mov  r0, r5         @ r0 = a1
  mov  r1, r6         @ r1 = ref_b0
  bl   gfmul          @ r0 = a1 * ref_b0


  mov  r7, r10        @ r7 = rnd2
  eors r7, r0         @ r7 = [(a1 * ref_b0) ^ rnd2]

  mov  r0, r5         @ r0 = a1
  mov  r1, r4         @ r1 = ref_b2
  bl   gfmul          @ r0 = a1 * ref_b2


  ldrb r5, [r2, #4]   @ r5 = rnd4  // r5 = a1, for computing cc, a1 (alone) is not needed, so, r5 can be used here
  mov  r10, r5        @ r10 = rnd4

  eors r5, r0         @ r5 = [(a1 * ref_b2) ^ rnd4]


  ldrb r0, [r3, #1]   @ r0 = a1 * ref_b1
  eors r0, r7         @ r0 = [(a1 * ref_b0) ^ rnd2] ^ (a1 * ref_b1) 
  eors r0, r5         @ r0 = c1 = [(a1 * ref_b0) ^ rnd2] ^ (a1 * ref_b1) ^ [(a1 * ref_b2) ^ rnd4]
  
  
  strb r0, [r3, #1]   @ Storing c1 in c1

@From previous step: 
@@@@ r2 = &rnd, r3 = &c, r4 = ref_b2, r5 = , r6 = ref_b0
@@@@ r7 = , r8 = &a, r9 = &b, r10 = rnd4, r11 = &c

@@@@ c2 = [(a2 * ref_b0) ^ rnd3] ^ [(a2 * ref_b1) ^ rnd4] ^ (a2 * ref_b2)
  mov  r0, r8         @ r0 = &a
  ldrb r5, [r0, #2]   @ r5 = a2
  ldrb r2, [r2, #3]   @ r2 = rnd3
  mov  r1, r9         @ r1 = &b
  ldrb r4, [r1, #1]   @ r4 = ref_b1

  mov  r0, r5         @ r0 = a2
  mov  r1, r6         @ r1 = ref_b0
  bl   gfmul          @ r0 = a2 * ref_b0

  eors r2, r0         @ r2 = [(a2 * ref_b0) ^ rnd3]

  mov  r0, r5         @ r0 = a2
  mov  r1, r4         @ r1 = ref_b1
  bl   gfmul          @ r0 = a2 * ref_b1

  mov  r4, r10        @ r4 = rnd4
  eors r4, r0         @ r4 = [(a2 * ref_b1) ^ rnd4]

  ldrb r0, [r3, #2]   @ r0 = a2 * ref_b2
  
  eors r4, r2         @ r4 = [(a2 * ref_b0) ^ rnd3] ^ [(a2 * ref_b1) ^ rnd4]

  eors r0, r4         @ r0 = [(a2 * ref_b0) ^ rnd3] ^ [(a2 * ref_b1) ^ rnd4] ^ (a2 * ref_b2)

 
  mov  r3, r11
  strb r0, [r3, #2]    @ Storing c2 in c2
  
  


  pop  {r4-r11}
  pop  {pc}
  .endfunc 




@@@@@ uint8_t gfmul(uint8_t a, uint8_t b); For calculating: input_a[i] * input_b[j]
@@@@@@@@ gfmul(in_r0:a, in_r1: b, out_r0: return)

.global gfmul
.func gfmul
gfmul:
	push	 {r2-r5}

    ldr  r2, =table     @ the address of the  "table"

    ldrb r3, [r2, r0]   @ r3 = table[a] 
    ldrb r4, [r2, r1]   @ r4 = table[b] 
    adds r3, r4         @ r3 = s = table[a] + table[b]

    @@@@ Get the antilog: s = table[s+256]: g ^ s 
    adds r3, #128       @ r3 = s + 128 :s + 256; : 256 is more than one byte, split: 128 + 128
    adds r3, #128       @ r3 = s + 256
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

