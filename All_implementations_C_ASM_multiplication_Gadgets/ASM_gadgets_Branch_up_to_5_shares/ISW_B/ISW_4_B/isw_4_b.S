@ ISW4_B

@ a = a0^a1^a2^a3, b = b0^b1^b2^b3, c = c0^c1^c2^c3, a*b = c, random numbers: rnd0, ..., rnd5 

@  ^: xor; +: arithmathic addition; x & y: and operation; *: Galois field multiplication; &x: the address of x

@@@@ c0 = (a0*b0)^rnd0^rnd1^rnd2
@@@@ c1 = [((a0*b1)^rnd0)^(a1*b0)]^(a1*b1)^rnd3^rnd4
@@@@ c2 = [((a0*b2)^rnd1)^(a2*b0)]^[((a1*b2)^rnd3)^(a2*b1)]^(a2*b2)^rnd5
@@@@ c3 = [((a0*b3)^rnd2)^(a3*b0)]^[((a1*b3)^rnd4)^(a3*b1)]^[((a2*b3)^rnd5)^(a3*b2)]^(a3*b3)
  .syntax unified
  .text
  .thumb
  
  .extern table       @@@@ table is used for GFMULT (ai*bj multiplications)
  
@@@@ extern void Isw_3(uint8_t* inputa: addres: r0, uint8_t* inputb: address: r1, uint8_t* rnd: address: r2, uint8_t* output: address: r3);
@inputa: a0, a1, a2, inputb: b0, b1, b2, rnd: rnd0, rnd1, rnd2, output: c: c0, c1, c2

.global Isw_4
.func Isw_4
Isw_4:

  push  {lr}
  push  {r4-r11}

@@@@@ r0 = &a, r1 = &b, r2 = &rnd, r3 = &c

@@@@@ Saving r3 (the address of the output)
  mov  r8, r3    @r8 = &c

@@@ r0 and r1 are used in gfmul function as arguments, they have to be saved
@@@@@ Saving r0 (the address of the input a)
  mov  r9, r0     @ r9 = &a

@@@@@ Saving r1 (the address of the input b)
  mov  r10, r1    @ r10 = &b

@@@@@ Saving r2 (the address of the input rnd)
  mov  r11, r2    @ r11 = &rnd


@@@@@@@@@@ Computing: ai*bi
@@@@@@ In gfmul, r0 and r1 are the arguments
@@@@ a0*b0
  ldrb r4, [r0, #0] @ r4 = a0;  r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r5, [r1, #0] @ r5 = b0;  r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  mov  r0, r4       @ r0 = a0; 
  mov  r1, r5       @ r1 = b0; 
  bl   gfmul        @ r0 = a0*b0
  strb r0, [r3, #0] @ Storing (a0*b0) in c0

@@@@ a1*b1
  mov  r0, r9       @ r0 = &a
  mov  r1, r10      @ r1 = &b
  ldrb r6, [r0, #1] @ r6 = a1;  r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r7, [r1, #1] @ r7 = b1;  r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  mov  r0, r6       @ r0 = a1
  mov  r1, r7       @ r1 = b1
  bl   gfmul        @ r0 = a1*b1
  strb r0, [r3, #1] @ Storing (a1*b1) in c1

@@@@ a2*b2
  mov  r0, r9       @ r0 = &a
  mov  r1, r10      @ r1 = &b
  ldrb r0, [r0, #2] @ r0 = a2;  r0 = &a, r1 = &b 
  ldrb r1, [r1, #2] @ r1 = b2;  r0 = &a, r1 = &b
  bl   gfmul        @ r0 = a2*b2
  strb r0, [r3, #2] @ Storing (a2*b2) in c2

@@@@ a3*b3
  mov  r0, r9       @ r0 = &a
  mov  r1, r10      @ r1 = &b
  ldrb r0, [r0, #3] @ r0 = a3;  r0 = &a, r1 = &b 
  ldrb r1, [r1, #3] @ r1 = b3;  r0 = &a, r1 = &b 
  bl   gfmul        @ r0 = a3*b3
  strb r0, [r3, #3] @ Storing (a3*b3) in c3


@@@@@@@@@@ Computing: ci

@@@@ c0 = (a0*b0)^rnd0^rnd1^rnd2
@@@@ From previous step:r2 = &rnd, r3 = &c, r4 = a0, r5 = b0, r6 = a1, r7 = b1, r8 = &c, r9 = &a, r10 = &b, r11 = &rnd
@@@@ r4-r7 are not used to avoid using more LDRB instruction, so r0, r1 can be used
  ldrb r0, [r3, #0]   @ r0 = a0*b0
  ldrb r1, [r2, #0]   @ r1 = rnd0
  mov  r11, r1        @ saving rnd0 for computing c1
  eors r0, r1         @ r0 = (a0*b0)^rnd0 

  ldrb r1, [r2, #1]   @ r1 = rnd1
  eors r0, r1         @ r0 = ((a0*b0)^rnd0 )^rnd1

  ldrb r1, [r2, #2]   @ r1 = rnd2
  eors r0, r1         @ r0 = r0 = ((a0*b0)^rnd0 )^rnd1^rnd2

  strb r0, [r3, #0]   @ Storing c0 in c0



@@@@ c1 = [((a0*b1)^rnd0)^(a1*b0)]^(a1*b1)^rnd3^rnd4
@@@@ From previous step: r2 = &rnd, r3 = &c, r4 = a0, r5 = b0, r6 = a1, r7 = b1, r8 = &c, r9 = &a, r10 = &b, r11 = rnd0
@@@@ r4-r7 are not used to avoid using more LDRB instruction, so r0, r1 can be used
  mov  r0, r4         @ r0 = a0
  mov  r1, r7         @ r1 = b1
  bl   gfmul          @ r0 = a0*b1
  mov  r1, r11        @ r1 = rnd0
  eors r1, r0         @ r1 = (a0*b1)^rnd0
  mov  r11, r1        @ r1 = (a0*b1)^rnd0

  mov  r0, r6         @ r0 = a1
  mov  r1, r5         @ r1 = b0
  bl   gfmul          @ r0 = a1*b0

  mov  r1, r11        @ r1 = (a0*b1)^rnd0
  eors r0, r1         @ r0 = [((a0*b1)^rnd0)^(a1*b0)]
  
  ldrb r3, [r3, #1]   @ r3 = a1*b1
  eors r0, r3         @ r0 = [((a0*b1)^rnd0)^(a1*b0)]^(a1*b1)
  
  ldrb r3, [r2, #3]   @ r3 = rnd3
  mov  r11, r3        @ saving rnd3 for computing c2

  ldrb r1, [r2, #4]   @ r1 = rnd4
  eors r0, r3         @ r0 = [((a0*b1)^rnd0)^(a1*b0)]^(a1*b1)^rnd3
  eors r0, r1         @ r0 = [((a0*b1)^rnd0)^(a1*b0)]^(a1*b1)^rnd3^rnd4

  mov r3, r8
  strb r0, [r3, #1]   @ Storing c1 in c1

@@@@@ c2 = [((a0*b2)^rnd1)^(a2*b0)]^[((a1*b2)^rnd3)^(a2*b1)]^(a2*b2)^rnd5
@@@@ From previous step: r2 = &rnd, r3 = &c, r4 = a0, r5 = b0, r6 = a1, r7 = b1, r8 = &c, r9 = &a, r10 = &b, r11 = rnd3
@@@@ r4-r7 are not used to avoid using more LDRB instruction, so r0, r1 can be used
  mov  r0, r4          @ r0 = a0
  mov  r1, r10         @ r1 = &b
  ldrb r3, [r1, #2]    @ r3 = b2 @ using r3 to avoid loading b2 again
  mov  r1, r3          @ r1 = b2
  bl   gfmul           @ r0 = a0*b2

  ldrb r4, [r2, #1]    @ r4 = rnd1
  eors r4, r0          @ r4 = (a0*b2)^rnd1

  mov  r1, r5          @ r1 = b0
  mov  r0, r9          @ r0 = &a  
  ldrb r5, [r0, #2]    @ r5 = a2 @ using r5 to avoid loading a2 again
  mov  r0, r5          @ r0 = a2
  bl   gfmul           @ r0 = a2*b0
  eors r4, r0          @ r4 = [((a0*b2)^rnd1)^(a2*b0)]

  mov  r0, r6          @ r0 = a1
  mov  r1, r3          @ r1 = b2
  bl   gfmul           @ r0 = a1*b2

  mov  r3, r11         @ r3 = rnd3
  eors r3, r0          @ r3 = (a1*b2)^rnd3

  

  mov  r0, r5          @ r0 = a2
  mov  r1, r7          @ r1 = b1
  bl   gfmul           @ r0 = a2*b1

  eors r0, r3          @ r0 = [((a1*b2)^rnd3)^(a2*b1)]
  eors r0, r4          @ r0 = [((a0*b2)^rnd1)^(a2*b0)]^[((a1*b2)^rnd3)^(a2*b1)]

  mov  r3, r8          @ r3 = &c
  ldrb r3, [r3, #2]    @ r3 = a2*b2
  ldrb r1, [r2, #5]    @ r1 = rnd5
  mov  r4, r1         @ r4 = rnd5 saving rnd5 for computing c3

  eors r0, r3          @ r0 = [((a0*b2)^rnd1)^(a2*b0)]^[((a1*b2)^rnd3)^(a2*b1)]^(a2*b2)
  eors r0, r1          @ r0 = c2 = [((a0*b2)^rnd1)^(a2*b0)]^[((a1*b2)^rnd3)^(a2*b1)]^(a2*b2)^rnd5

  mov  r3, r8
  strb r0, [r3, #2]    @ Storing c2 in c2
  
  
@@@@@ c3 = [((a0*b3)^rnd2)^(a3*b0)]^[((a1*b3)^rnd4)^(a3*b1)]^[((a2*b3)^rnd5)^(a3*b2)]^(a3*b3)
@@@@ From previous step: r2 = &rnd, r3 = , r4 = rnd5, r5 = a2, r6 = a1, r7 = b1, r8 = &c, r9 = &a, r10 = &b, r11 = 
@@@@ r4-r7 are not used to avoid using more LDRB instruction, so r0, r1, r3 can be used
  mov  r0, r9          @ r0 = &a
  mov  r1, r10         @ r1 = &b
  ldrb r0, [r0, #0]    @ r0 = a0
  ldrb r1, [r1, #3]    @ r1 = b3 
  mov  r11, r1         @ r11 = b3 @saving b3
  bl   gfmul           @ r0 = a0*b3

  ldrb r3, [r2, #2]    @ r3 = rnd2
  eors r3, r0          @ r3 = (a0*b3)^rnd2

  mov  r0, r9          @ r0 = &a
  mov  r1, r10         @ r1 = &b
  ldrb r7, [r0, #3]    @ r7 = a3   @ using r7 to avoid  loading a3 again
  mov  r0, r7          @ r0 = a3
  ldrb r1, [r1, #0]    @ r1 = b0
  bl   gfmul           @ r0 = a3*b0

  eors r3, r0          @ r3 = [((a0*b3)^rnd2)^(a3*b0)]

  mov  r0, r6          @ r0 = a1
  mov  r1, r11         @ r0 = b3
  bl   gfmul           @ r0 = a1*b3

  ldrb r2, [r2, #4]    @ r2 = rnd4 : &rnd is not used again, because r4 = rnd5
  eors r2, r0          @ r2 = (a1*b3)^rnd4


  mov  r1, r10         @ r1 = &b
  ldrb r1, [r1, #1]    @ r1 = b1
  mov  r0, r7          @ r0 = a3
  bl   gfmul           @ r0 = a3*b1

  eors r2, r0         @ r2 = [((a1*b3)^rnd4)^(a3*b1)]

  mov  r0, r5         @ r0 = a2
  mov  r1, r11        @ r1 = b3  
  bl   gfmul          @ r0 = a2*b3

  eors r4, r0         @ r5 = (a2*b3)^rnd5)

  mov  r0, r7         @ r0 = a3
  mov  r1, r10        @ r1 = &b
  ldrb r1, [r1, #2]   @ r1 = b2
  bl   gfmul          @ r0 = a3*b2

  eors r4, r0         @ r4 = [((a2*b3)^rnd5)^(a3*b2)]
  
  eors r2, r3         @ r2 = [((a0*b3)^rnd2)^(a3*b0)]^[((a1*b3)^rnd4)^(a3*b1)]
  eors r2, r4         @ r2 = [((a0*b3)^rnd2)^(a3*b0)]^[((a1*b3)^rnd4)^(a3*b1)]^[((a2*b3)^rnd5)^(a3*b2)]

  mov  r3, r8         @ r3 = &c
  ldrb r4, [r3, #3]   @ r4 = a3*b3
  eors r2, r4         @ c3 = [((a0*b3)^rnd2)^(a3*b0)]^[((a1*b3)^rnd4)^(a3*b1)]^[((a2*b3)^rnd5)^(a3*b2)]^(a3*b3)

  strb r2, [r3, #3]    @ Storing c3 in c3
  



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
