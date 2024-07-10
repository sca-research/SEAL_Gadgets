@ HPC1_OPT_4_B

@ a = a0^a1^a2^a3, b = b0^b1^b2^b3, c = c0^c1^c2^c3, a*b = c, random numbers: rnd0, rnd1, rnd9
@  ^: xor; +: arithmathic addition; x & y: and operation; *: Galois field multiplication; &x: the address of x

@@@@ ref_b0 = b0^(rnd0^rnd3)
@@@@ ref_b1 = b1^(rnd1^rnd0)
@@@@ ref_b2 = b2^(rnd2^rnd1)
@@@@ ref_b3 = b3^(rnd3^rnd2)

@@@@ c0 = (a0*ref_b0)^[(a0*ref_b1)^rnd4]^[(a0*ref_b2)^rnd5]^[(a0*ref_b3)^rnd7]
@@@@ c1 = [(a1*ref_b0)^rnd4]^(a1*ref_b1)^[(a1*ref_b2)^rnd6]^[(a1*ref_b3)^rnd8]
@@@@ c2 = [(a2*ref_b0)^rnd5]^[(a2*ref_b1)^rnd6]^(a2*ref_b2)^[(a2*ref_b3)^rnd9]
@@@@ c3 = [(a3*ref_b0)^rnd7]^[(a3*ref_b1)^rnd8]^[(a3*ref_b2)^rnd9]^(a3*ref_b3) 

  .syntax unified
  .text
  .thumb
  
  .extern table       @@@@ table is used for GFMULT (ai*bj multiplications)
  
@@@@ extern void HPC1_opt_4(uint8_t* inputa: addres: r0, uint8_t* inputb: address: r1, uint8_t* rnd: address: r2, uint8_t* output: address: r3);
@inputa: a0-a3, inputb: b0-b3, rnd: rnd0-rnd9, output: c: c0-c3
@ rnd0-rnd3 are used in OPT refresh mask, rnd4-rnd9 are used in DOM_indep

.global HPC1_opt_4
.func HPC1_opt_4
HPC1_opt_4:
  push  {lr}
  push  {r4-r11}

@@@@@ r0 = &a, r1 = &b, r2 = &rnd, r3 = &c

@@@@@ Saving r3 (the address of the output)
  mov  r11, r3    @ r11 = &c

@@@@@ Saving r2 (the address of the input rnd)
  mov  r10, r2   @ r10 = &rnd

@@@@@ Saving r1 (the address of the input b)
  mov  r9, r1    @ r9 = &b

@@@@@ Saving r0 (the address of the input a)
  mov  r8, r0    @ r8 = &a

@@@@@ Optimized Refresh Mask: ref_b = (input b^[S^(S >> 1)])
@@ S^(S >> 1); ".>>i" operator, the "1st" element becomes the "i+1 th". ">>" Rotates left
@ The first 4 "rnd" elements (rnd0-rnd3) are used in OPT refresh mask, all together: 4bytes, using "ldr" for loading all of 4bytes at one time

  ldr  r4, [r2]      @ r4 = S; Loading all 4bytes;Regarding "Big_endian": 32bits reg r4 = rnd3|rnd2|rnd1|rnd0 : rndi: 8 bits
  mov  r5, r4        @ r5 = S; Regarding "Big_endian": 32bits reg r5 = rnd3|rnd2|rnd1|rnd0 
  rors r4, #24       @ r4 = S >> 1; r4 = rnd2|rnd1|rnd0|rnd3 @ rotating 1 byte (8 bits to the left), 32-8 = 24, @ before RORS instruction reg r4 = rnd3|rnd2|rnd1|rnd0
  
  eors r4, r5        @ r4 = S^(S >> 1); [rnd3|rnd2|rnd1|rnd0]^[rnd2|rnd1|rnd0|rnd3] = [(rnd3^rnd2)|(rnd2^rnd1)|(rnd1^rnd0)|(rnd0^rnd3)] = s3|s2|s1|s0
  
  ldr  r5, [r1]      @ r5 = b3|b2|b1|b0 (4bytes) ; Loading all 4 shares of input b;
  
  eors r4, r5        @ r4 = ref_b = ref_b3|ref_b2|ref_b1|ref_b0 = b^[S^(S >> 1)]:  (b3^s3)|(b2^s2)|(b1^s1)|(b0^s0)

  str  r4, [r1]      @ Storing ref_b in &r1 


@@@@@@@@@@ Computing: ai*ref_bi
@@@@@@ In gfmul, r0 and r1 are the arguments
@@@@ a0*ref_b0
  ldrb r4, [r0, #0] @ r4 = a0;  r0 = &a, r1 = &ref_b, r2 = &rnd, r3 = &c // for computing c0, a0 is needed, so it is loaded into r4
  ldrb r5, [r1, #0] @ r5 = ref_b0;  r0 = &a, r1 = &ref_b, r2 = &rnd, r3 = &c // for computing c0, ref_b0 is needed, so it is loaded into r5
  mov  r0, r4       @ r0 = a0; 
  mov  r1, r5       @ r1 = ref_b0; 
  bl   gfmul        @ r0 = a0*ref_b0

  strb r0, [r3, #0] @ Storing (a0*ref_b0) in c0

@@@@ a1*ref_b1
  mov  r0, r8       @ r0 = &a
  mov  r1, r9       @ r1 = &ref_b
  ldrb r0, [r0, #1] @ r0 = a1;  r0 = a1, r1 = &ref_b, r2 = &rnd, r3 = &c // for computing c0, a1 is not needed, so it is loaded into r0, then it will be clear
  ldrb r6, [r1, #1] @ r6 = ref_ref_b1;  r0 = a1, r1 = &ref_b, r2 = &rnd, r3 = &c // for computing c0, ref_b1 is needed, so it is loaded into r6
  mov  r1, r6       @ r1 = ref_b1
  bl   gfmul        @ r0 = a1*ref_b1

  strb r0, [r3, #1] @ Storing (a1*ref_b1) in c1

@@@@ a2*ref_b2
  mov  r0, r8       @ r0 = &a
  mov  r1, r9       @ r1 = &ref_b
  ldrb r0, [r0, #2] @ r0 = a2;  r0 = a2, r1 = &ref_b // for computing c0, a2 is not needed, so it is loaded into r0, then it will be clear
  ldrb r7, [r1, #2] @ r7 = ref_b2;  r0 = a2, r1 = &ref_b // for computing c0, ref_b2 is neededso, so it is loaded into r7
  mov  r1, r7       @ r1 = ref_b2
  bl   gfmul        @ r0 = a2*ref_b2

  strb r0, [r3, #2] @ Storing (a2*ref_b2) in c2

@@@@ a3*ref_b3
  mov  r0, r8       @ r0 = &a
  mov  r1, r9       @ r1 = &ref_b
  ldrb r0, [r0, #3] @ r0 = a3;  r0 = a3, r1 = &ref_b // for computing c0, a3 is not needed, so it is loaded into r0, then it will be clear
  ldrb r1, [r1, #3] @ r1 = ref_b3;  r0 = a3, r1 = ref_b3 
  mov  r10, r1      @ r10 = ref_b3  @ Saving ref_b3 // for computing c0, ref_b3 is needed
  bl   gfmul        @ r0 = a3*ref_b3

  strb r0, [r3, #3] @ Storing (a3*ref_b3) in c3


@@@@@@@@@@ Computing: ci

@From previous step: 
@@@@ r2 = &rnd, r3 = &c, r4 = a0, r5 = ref_b0, r6 = ref_b1
@@@@ r7 = ref_b2, r8 = &a, r9 = &ref_b, r10 = ref_b3, r11 = &c

@@@@ c0 = (a0*ref_b0)^[(a0*ref_b1)^rnd4]^[(a0*ref_b2)^rnd5]^[(a0*ref_b3)^rnd7]
  mov  r0, r4         @ r0 = a0
  mov  r1, r6         @ r1 = ref_b1
  bl   gfmul          @ r0 = a0*ref_b1

  ldrb r6, [r2, #4]   @ r6 = rnd4 // r6 = ref_b1, for computing c1, ref_b1 (alone) is not needed, so, r6 can be used here
  eors r6, r0         @ r6 = [(a0*ref_b1)^rnd4]


  mov  r0, r4         @ r0 = a0
  mov  r1, r7         @ r1 = ref_b2
  bl   gfmul          @ r0 = a0*ref_b2

  ldrb r3, [r2, #5]   @ r3 = rnd5
  eors r3, r0         @ r3 = [(a0*ref_b2)^rnd5]


  mov  r0, r4         @ r0 = a0  
  mov  r1, r10        @ r1 = ref_b3
  bl   gfmul          @ r0 = a0*ref_b3
  mov  r4, r3         @ r4 = r3 = [(a0*ref_b2)^rnd5]  // r4 = a0, for the rest copmutations, a0 (alone) is not needed, so, r4 can be used here

  ldrb r1, [r2, #7]   @ r1 = rnd7
  eors r1, r0         @ r1 = [(a0*ref_b3)^rnd7]

  mov  r3, r11        @ r3 = &c
  ldrb r0, [r3, #0]   @ r0 = a0*ref_b0

  eors r0, r6         @ r0 = (a0*ref_b0)^[(a0*ref_b1)^rnd4] 
  eors r0, r4         @ r0 = (a0*ref_b0)^[(a0*ref_b1)^rnd4]^[(a0*ref_b2)^rnd5]
  eors r0, r1         @ r0 = c0 = (a0*ref_b0)^[(a0*ref_b1)^rnd4]^[(a0*ref_b2)^rnd5]^[(a0*ref_b3)^rnd7]

  @mov  r3, r11        @ r3 = &c
  strb r0, [r3, #0]   @ Storing c0 in c0



@From previous step: 
@@@@ r2 = &rnd, r3 = &c, r4 = , r5 = ref_b0, r6 = 
@@@@ r7 = ref_b2, r8 = &a, r9 = &ref_b, r10 = ref_b3, r11 = &c

@@@@ c1 = [(a1*ref_b0)^rnd4]^(a1*ref_b1)^[(a1*ref_b2)^rnd6]^[(a1*ref_b3)^rnd8]
  mov  r0, r8         @ r0 = &a
  ldrb r4, [r0, #1]   @ r4 = a1; 
  ldrb r6, [r2, #4]   @ r6 = rnd4

  mov  r0, r4         @ r0 = a1
  mov  r1, r5         @ r1 = ref_b0
  bl   gfmul          @ r0 = a1*ref_b0

  eors r6, r0         @ r6 = [(a1*ref_b0)^rnd4]


  mov  r0, r4         @ r0 = a1
  mov  r1, r7         @ r1 = ref_b2
  bl   gfmul          @ r0 = a1*ref_b2

  ldrb r7, [r2, #6]   @ r7 = rnd6  // r7 = ref_b2, for computing c2, ref_b2 (alone) is not needed, so, r7 can be used here
  mov  r3, r7         @ r3 = rnd6   @saving 
  eors r7, r0         @ r7 = [(a1*ref_b2)^rnd6]


  mov  r0, r4         @ r0 = a1
  mov  r1, r10        @ r1 = ref_b3
  bl   gfmul          @ r0 = a1*ref_b3

  ldrb r1, [r2, #8]   @ r4 = rnd8  
  eors r1, r0         @ r1 = [(a1*ref_b3)^rnd8] 

  mov  r4, r3         @ r4 = rnd6 // r4 = a1, for the rest computations a1 is not needed, so, r4 can be used here
  

  mov  r3, r11        @ r3 = &c
  ldrb r0, [r3, #1]   @ r0 = a1*ref_b1

  eors r0, r6         @ r0 = [(a1*ref_b0)^rnd4]^(a1*ref_b1) 
  eors r0, r7         @ r0 = [(a1*ref_b0)^4]^(a1*ref_b1)^[(a1*ref_b2)^rnd6]
  eors r0, r1         @ r0 = c1 = [(a1*ref_b0)^rnd0]^(a1*ref_b1)^[(a1*ref_b2)^rnd6]^[(a1*ref_b3)^rnd8]

  @mov  r3, r11
  strb r0, [r3, #1]   @ Storing c1 in c1

@From previous step: 
@@@@ r2 = &rnd, r3 = &c, r4 = rnd6, r5 = ref_b0, r6 = 
@@@@ r7 = , r8 = &a, r9 = &ref_b, r10 = ref_b3, r11 = &c

@@@@ c2 = [(a2*ref_b0)^rnd5]^[(a2*ref_b1)^rnd6]^(a2*ref_b2)^[(a2*ref_b3)^rnd9]
  mov  r0, r8         @ r0 = &a
  ldrb r6, [r0, #2]   @ r6 = a2
  ldrb r7, [r2, #5]   @ r7 = rnd5
  mov  r1, r9         @ r1 = &ref_b
  ldrb r3, [r1, #1]   @ r3 = ref_b1

  mov  r0, r6         @ r0 = a2
  mov  r1, r5         @ r1 = ref_b0
  bl   gfmul          @ r0 = a2*ref_b0

  eors r7, r0         @ r7 = [(a2*ref_b0)^rnd5]


  mov  r0, r6         @ r0 = a2
  mov  r1, r3         @ r1 = ref_b1
  bl   gfmul          @ r0 = a2*ref_b1
  eors r4, r0         @ r4 = [(a2*ref_b1)^rnd6]


  mov  r0, r6         @ r0 = a2
  mov  r1, r10        @ r1 = ref_b3
  bl   gfmul          @ r0 = a2*ref_b3


  ldrb r1, [r2, #9]   @ r1 = rnd9 
  mov  r6, r1         @ r6 = rnd9 // r6 = a2, for the rest computations a2 is not needed, so, r6 can be used here
  eors r1, r0         @ r1 = [(a2*ref_b3)^rnd9] 

  mov  r10, r3        @ r10 = ref_b1   @ saving ref_b1

  mov  r3, r11        @ r3 = &c
  ldrb r0, [r3, #2]   @ r0 = a2*ref_b2
  
  eors r4, r7         @ r4 = [(a2*ref_b0)^rnd5]^[(a2*ref_b1)^rnd6]
  eors r0, r4         @ r0 = [(a2*ref_b0)^rnd5]^[(a2*ref_b1)^rnd6]^(a2*ref_b2)
  eors r0, r1         @ r0 = [(a2*ref_b0)^rnd5]^[(a2*ref_b1)^rnd6]^(a2*ref_b2)^[(a2*ref_b3)^rnd9]

 
  mov  r3, r11
  strb r0, [r3, #2]    @ Storing c2 in c2
  
  
@From previous step: 
@@@@ r2 = &rnd, r3 = &c, r4 = , r5 = ref_b0, r6 = rnd9
@@@@ r7 = , r8 = &a, r9 = &ref_b, r10 = ref_b1, r11 = &c

@@@@ c3 = [(a3*ref_b0)^rnd7]^[(a3*ref_b1)^rnd8]^[(a3*ref_b2)^rnd9]^(a3*ref_b3) 
  mov  r0, r8         @ r0 = &a
  ldrb r4, [r0, #3]   @ r4 = a3
  ldrb r7, [r2, #7]   @ r7 = rnd7
  ldrb r2, [r2, #8]   @ r2 = rnd8 @ rnd9 is in r6, r2 = &rnd is not used again, so it can be used here
  mov  r1, r9         @ r1 = &ref_b
  ldrb r3, [r1, #2]   @ r3 = ref_b2

  mov  r0, r4         @ r0 = a3
  mov  r1, r5         @ r1 = ref_b0
  bl   gfmul          @ r0 = a3*ref_b0

  eors r7, r0         @ r7 = [(a3*ref_b0)^rnd7]


  mov  r0, r4         @ r0 = a3
  mov  r1, r10        @ r1 = ref_b1
  bl   gfmul          @ r0 = a3*ref_b1

  eors r2, r0         @ r2 = [(a3*ref_b1)^rnd8]


  mov  r0, r4         @ r0 = a3
  mov  r1, r3         @ r1 = ref_b2
  bl   gfmul          @ r0 = a3*ref_b2

  eors r6, r0         @ r6 = [(a3*ref_b2)^rnd9] 


  mov  r3, r11        @ r3 = &c
  ldrb r0, [r3, #3]   @ r0 = a3*ref_b3
  
  eors r2, r7         @ r2 = [(a3*ref_b0)^rnd7]^[(a3*ref_b1)^rnd8]
  eors r6, r2         @ r6 = [(a3*ref_b0)^rnd7]^[(a3*ref_b1)^rnd8]^[(a3*ref_b2)^rnd9] 
  eors r0, r6         @ r0 = [(a3*ref_b0)^rnd7]^[(a3*ref_b1)^rnd8]^[(a3*ref_b2)^rnd9]^(a3*ref_b3)

 
  mov  r3, r11
  strb r0, [r3, #3]    @ Storing c3 in c3
  
 

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

