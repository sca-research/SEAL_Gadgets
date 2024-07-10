@ Bbpp_opt_5_B

@  ^: xor; +: arithmathic addition; x & y: and operation; *: Galois field multiplication; &x: the address of x
@ a = a0^a1^a2^a3^a4, b = b0^b1^b2^b3^b4, c = c0^c1^c2^c3^b4, a*b = c, random numbers: rnd0, rnd1, rnd2, rnd3

@@@@ c0 = (a0*b0)^rnd0^(a0*b1)^(a1*b0)^rnd1^(a0*b2)^(a2*b0)
@@@@ c1 = (a1*b1)^rnd1^(a1*b2)^(a2*b1)^rnd2^(a1*b3)^(a3*b1)
@@@@ c2 = (a2*b2)^rnd2^(a2*b3)^(a3*b2)^rnd3^(a2*b4)^(a4*b2)
@@@@ c3 = (a3*b3)^rnd3^(a3*b4)^(a4*b3)^rnd4^(a3*b0)^(a0*b3)
@@@@ c4 = (a4*b4)^rnd4^(a4*b0)^(a0*b4)^rnd0^(a4*b1)^(a1*b4)


  .syntax unified
  .text
  .thumb
  
  .extern table       @@@@ table is used for gfmult
  
@@@@ extern void Bbpp_4(uint8_t* inputa: addres: r0, uint8_t* inputb: address: r1, uint8_t* rnd: address: r2, uint8_t* output: address: r3);
@inputa: a0-a4 inputb: b0-b4 rnd: rnd0-rnd4, output: c: c0-c4

.global Bbpp_opt_5
.func Bbpp_opt_5
Bbpp_opt_5:

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
@@@@ c0 = (a0*b0)^rnd0^(a0*b1)^(a1*b0)^rnd1^(a0*b2)^(a2*b0)
  ldrb r4, [r0, #0] @ r4 = a0; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r5, [r0, #1] @ r5 = a1; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r6, [r1, #0] @ r6 = b0; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r7, [r1, #1] @ r7 = b1; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r3, [r2, #0] @ r3 = rnd0; r0 = &a, r1 = &b, r2 = &rnd
  ldrb r2, [r2, #1] @ r2 = rnd1; r0 = &a, r1 = &b


  mov  r0, r4   @ r0 = a0
  mov  r1, r6   @ r1 = b0 
  bl   gfmul    @ r0 = a0*b0

  eors r3, r0   @ r3 = (a0*b0)^rnd0

  mov  r0, r4   @ r0 = a0
  mov  r1, r7   @ r1 = b1 
  bl   gfmul    @ r0 = a0*b1

  eors r3, r0   @ r3 = (a0*b0)^rnd0^(a0*b1)

  mov  r0, r5   @ r0 = a1
  mov  r1, r6   @ r1 = b0
  bl   gfmul    @ r0 = a1*b0

  eors r3, r0   @ r3 = (a0*b0)^rnd0^(a0*b1)^(a1*b0)
  eors r3, r2   @ r3 = (a0*b0)^rnd0^(a0*b1)^(a1*b0)^rnd1

  mov  r0, r4       @ r0 = a0
  mov  r1, r9       @ r1 = &b
  ldrb r4, [r1, #2] @ r4 = b2; r0 = a0
  mov  r1, r4       @ r1 = b2
  bl   gfmul    @ r0 = a0*b2

  eors r3, r0   @ r3 = (a0*b0)^rnd0^(a0*b1)^(a1*b0)^rnd1^(a0*b2)

  mov  r0, r8       @ r0 = &a
  mov  r1, r6       @ r1 = b0
  ldrb r6, [r0, #2] @ r6 = a2; r2 = rnd1
  mov  r0, r6        @ r0 = a2
  
  bl   gfmul        @ r0 = a2*b0

  eors r0, r3   @ r0 = (a0*b0)^rnd0^(a0*b1)^(a1*b0)^rnd1^(a0*b2)^(a2*b0)

  mov  r3, r11
  strb r0, [r3, #0] @ r0 = c0 @ Storing c0 in c0


@@@@ From previous step:r2 = rnd1, r3 = &c, r4 = b2, r5 = a1, r6 = a2, r7 = b1, r8 = &a, r9 = &b, r10 = &rnd, r11 = &c
@@@@ c1 = (a1*b1)^rnd1^(a1*b2)^(a2*b1)^rnd2^(a1*b3)^(a3*b1)

  mov  r3, r2        @ r3 = rnd1
  mov  r2, r10       @ r2 = &rnd
  ldrb r2, [r2, #2]  @ r2 = rnd2


  mov  r0, r5        @ r0 = a1
  mov  r1, r7        @ r1 = b1
  bl   gfmul         @ r0 = a1*b1

  eors r3, r0   @ r3 = (a1*b1)^rnd1

  mov  r0, r5   @ r0 = a1
  mov  r1, r4   @ r1 = b2
  bl   gfmul    @ r0 = a1*b2

  eors r3, r0   @ r3 = (a1*b1)^rnd1^(a1*b2)

  mov  r0, r6   @ r0 = a2
  mov  r1, r7   @ r1 = b1
  bl   gfmul    @ r0 = a2*b1

  eors r3, r0   @ r3 = (a1*b1)^rnd1^(a1*b2)^(a2*b1)
  eors r3, r2   @ r3 = (a1*b1)^rnd1^(a1*b2)^(a2*b1)^rnd2

  mov  r0, r5       @ r0 = a1
  mov  r1, r9       @ r1 = &b
  ldrb r5, [r1, #3] @ r5 = b3; r0 = a0, r1 = b3
  mov  r1, r5       @ r1 = b3
  bl   gfmul        @ r0 = a1*b3

  eors r3, r0   @ r3 = (a1*b1)^rnd1^(a1*b2)^(a2*b1)^rnd2^(a1*b3)

  mov  r0, r8       @ r0 = &a
  mov  r1, r7       @ r1 = b1
  ldrb r7, [r0, #3] @ r7 = a3; 
  mov  r0, r7       @ r0 = a3
  bl   gfmul        @ r0 = a3*b1

  eors r0, r3   @ r0 = (a1*b1)^rnd1^(a1*b2)^(a2*b1)^rnd2^(a1*b3)^(a3*b1)

  mov  r3, r11
  strb r0, [r3, #1] @ r0 = c1 @ Storing c1 in c1


@@@@ From previous step:r2 = rnd2 , r3 = &c, r4 = b2, r5 = b3, r6 = a2, r7 = a3, r8 = &a, r9 = &b, r10 = &rnd, r11 = &c
@@@@ c2 = (a2*b2)^rnd2^(a2*b3)^(a3*b2)^rnd3^(a2*b4)^(a4*b2)

  mov  r3, r2        @ r3 = rnd2
  mov  r2, r10       @ r2 = &rnd
  ldrb r2, [r2, #3]  @ r2 = rnd3


  mov  r0, r6     @ r0 = a2
  mov  r1, r4     @ r1 = b2
  bl   gfmul      @ r0 = a2*b2

  eors r3, r0     @ r3 = (a2*b2)^rnd2

  mov  r0, r6     @ r0 = a2
  mov  r1, r5     @ r1 = b3
  bl   gfmul      @ r0 = a2*b3

  eors r3, r0     @ r3 = (a2*b2)^rnd2^(a2*b3)
  
  mov  r0, r7     @ r0 = a3
  mov  r1, r4     @ r1 = b2
  bl   gfmul      @ r0 = a3*b2

  eors r3, r0     @ r0 = (a2*b2)^rnd2^(a2*b3)^(a3*b2) 
  eors r3, r2     @ r0 = (a2*b2)^rnd2^(a2*b3)^(a3*b2)^rnd3

  mov  r0, r6       @ r0 = a2
  mov  r1, r9       @ r1 = &b
  ldrb r6, [r1, #4] @ r6 = b4; r0 = a2
  mov  r1, r6       @ r1 = b4
  bl   gfmul    @ r0 = a2*b4

  eors r3, r0   @ r3 = (a2*b2)^rnd2^(a2*b3)^(a3*b2)^rnd3^(a2*b4)

  mov  r0, r8       @ r0 = &a
  mov  r1, r4       @ r1 = b2
  ldrb r4, [r0, #4] @ r4 = a4; 
  mov  r0, r4       @ r0 = a4
  bl   gfmul        @ r0 = a4*b2

  eors r0, r3   @ r0 = (a2*b2)^rnd2^(a2*b3)^(a3*b2)^rnd3^(a2*b4)^(a4*b2)

  mov  r3, r11
  strb r0, [r3, #2] @ r0 = c2 @ Storing c2 in c2


@@@@ From previous step:r2 = rnd3, r3 = &c, r4 = a4, r5 = b3, r6 = b4, r7 = a3, r8 = &a, r9 = &b, r10 = rnd3, r11 = &c
@@@@ c3 = (a3*b3)^rnd3^(a3*b4)^(a4*b3)^rnd4^(a3*b0)^(a0*b3)
  
  mov  r3, r2        @ r3 = rnd3
  mov  r2, r10       @ r2 = &rnd
  ldrb r2, [r2, #4]  @ r2 = rnd4

  mov  r0, r7        @ r0 = a3
  mov  r1, r5        @ r1 = b3
  bl   gfmul         @ r0 = a3*b3
  
  eors r3, r0   @ r3 = (a3*b3)^rnd3

  mov  r0, r7        @ r0 = a3
  mov  r1, r6        @ r1 = b4
  bl   gfmul         @ r0 = a3*b4
  
  eors r3, r0   @ r3 = (a3*b3)^rnd3^(a3*b4)

  mov  r0, r4        @ r0 = a4
  mov  r1, r5        @ r1 = b3
  bl   gfmul         @ r0 = a4*b3
  
  eors r3, r0   @ r3 = (a3*b3)^rnd3^(a3*b4)^(a4*b3)
  eors r3, r2   @ r3 = (a3*b3)^rnd3^(a3*b4)^(a4*b3)^rnd4

  mov  r0, r7       @ r0 = a3
  mov  r1, r9       @ r1 = &b
  ldrb r7, [r1, #0] @ r7 = b0; r0 = a2
  mov  r1, r7       @ r1 = b0
  bl   gfmul        @ r0 = a3*b0

  eors r3, r0   @ r3 = (a3*b3)^rnd3^(a3*b4)^(a4*b3)^rnd4^(a3*b0)

  mov  r0, r8       @ r0 = &a
  mov  r1, r5       @ r1 = b3
  ldrb r5, [r0, #0] @ r5 = a0; 
  mov  r0, r5       @ r0 = a0
  bl   gfmul        @ r0 = a0*b3

  eors r0, r3       @ r0 = (a3*b3)^rnd3^(a3*b4)^(a4*b3)^rnd4^(a3*b0)^(a0*b3)

  mov  r3, r11
  strb r0, [r3, #3] @ r0 = c3 @ Storing c3 in c3



@@@@ From previous step:r2 = rnd4, r3 = &c, r4 = a4, r5 = a0, r6 = b4, r7 = b0, r8 = &a, r9 = &b, r10 = rnd3, r11 = &c

@@@@ c4 = (a4*b4)^rnd4^(a4*b0)^(a0*b4)^rnd0^(a4*b1)^(a1*b4)
  mov  r3, r2        @ r3 = rnd4
  mov  r2, r10       @ r2 = &rnd
  ldrb r2, [r2, #0]  @ r2 = rnd0

  mov  r0, r4        @ r0 = a4
  mov  r1, r6        @ r1 = b4
  bl   gfmul         @ r0 = a4*b4
  
  eors r3, r0        @ r3 = (a4*b4)^rnd4 

  mov  r0, r4        @ r0 = a4
  mov  r1, r7        @ r1 = b0
  bl   gfmul         @ r0 = a4*b0
  
  eors r3, r0        @ r3 = (a4*b4)^rnd4^(a4*b0)

  mov  r0, r5        @ r0 = a0
  mov  r1, r6        @ r1 = b4
  bl   gfmul         @ r0 = a0*b4
  
  eors r3, r0        @ r3 = (a4*b4)^rnd4^(a4*b0)^(a0*b4) 
  eors r3, r2        @ r3 = (a4*b4)^rnd4^(a4*b0)^(a0*b4)^rnd0

  mov  r0, r4        @ r0 = a4
  mov  r1, r9        @ r1 = &b
  ldrb r1, [r1, #1]  @ r1 = b1;
  bl   gfmul         @ r0 = a4*b1

  eors r3, r0       @ r3 = (a4*b4)^rnd4^(a4*b0)^(a0*b4)^rnd0^(a4*b1)

  mov  r0, r8       @ r0 = &a
  ldrb r0, [r0, #1] @ r0 = a1; 
  mov  r1, r6       @ r1 = b4
  bl   gfmul        @ r0 = a1*b4

  eors r0, r3       @ r0 = (a4*b4)^rnd4^(a4*b0)^(a0*b4)^rnd0^(a4*b1)^(a1*b4)


  mov  r3, r11
  strb r0, [r3, #4] @ r0 = c4 @ Storing c4 in c4



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
