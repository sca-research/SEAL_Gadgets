@ ISW3_B

@ a = a0^a1^a2, b = b0^b1^b2, c = c0^c1^c1, a*b = c, random numbers: rnd0, rnd1, rnd2

@  ^: xor; +: arithmathic addition; x & y: and operation; *: Galois field multiplication; &x: the address of x

@@@@ c0 = (a0*b0)^rnd0^rnd1
@@@@ c1 = [(rnd0^(a0*b1))^(a1*b0)]^(a1*b1)^rnd2
@@@@ c2 = [(rnd1^(a0*b2))^(a2*b0)]^[(rnd2^(a1*b2))^(a2*b1)]^(a2*b2) 

  .syntax unified
  .text
  .thumb
  
  .extern table       @@@@ table is used for GFMULT (ai*bj multiplications)
  
@@@@ extern void Isw_3(uint8_t* inputa: addres: r0, uint8_t* inputb: address: r1, uint8_t* rnd: address: r2, uint8_t* output: address: r3);
@inputa: a0, a1, a2, inputb: b0, b1, b2, rnd: rnd0, rnd1, rnd2, output: c: c0, c1, c2

.global Isw_3
.func Isw_3
Isw_3:
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



@@@@@ Loading arguments @@@@@@@@@@@@
  ldrb r4, [r0, #0] @r4 = a0; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r5, [r0, #1] @r5 = a1; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r6, [r1, #0] @r6 = b0; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c
  ldrb r7, [r1, #1] @r7 = b1; r0 = &a, r1 = &b, r2 = &rnd, r3 = &c

@@@@ Reducing the use of LDRB instruction: ldrb rx, [r0, #0] @ rx = a0; --> mov rx, r11 
  mov  r11, r4   @ r11 = a0

@@@@@@@@@@ Computing: ai*bi
@@@@@@ In gfmul, r0 and r1 are the arguments
@@@@ a0*b0
  mov  r0, r4   @ r0 = a0
  mov  r1, r6   @ r1 = b0
  bl   gfmul    @ r0 = a0*b0
  mov  r4, r0   @ r4 = a0*b0

@@@@ a1*b1
  mov  r0, r5   @ r0 = a1
  mov  r1, r7   @ r1 = b1
  bl   gfmul    @ r0 = a1*b1
  mov  r5, r0   @ r5 = a1*b1

@@@@ a2*b2
  mov  r0, r9    @ r0 = &a
  mov  r1, r10   @ r1 = &b
  ldrb r0, [r0, #2]  @ r0 = a2
  ldrb r1, [r1, #2]  @ r1 = b2
  bl   gfmul    @ r0 = a2*b2
  mov  r3, r0   @ r3 = a2*b2

@@@@ r2 = &rnd, r4 = a0*b0, r5 = a1*b1, r3 = a2*b2
@@@@ r6 = b0, r7 = b1, r8 = &c, r9 = &a, r10 = &b, r11 = a0
@@@@ r0, r1, r6, r7 can be used

@@@@@@@@@@ Computing: ci
@@@@ c0 = (a0*b0)^rnd0^rnd1
  ldrb r6, [r2, #0]  @ r6 = rnd0
  ldrb r7, [r2, #1]  @ r7 = rnd1
  eors r4, r6    @ r4 = (a0*b0)^rnd0
  eors r4, r7    @ r4 = c0 = (a0*b0)^rnd0^rnd1

  @@@@ c1 = [(rnd0^(a0*b1))^(a1*b0)]^(a1*b1)^ rnd2
    mov  r0, r11   @ r0 = a0
    mov  r1, r10   @ r1 = &b
    ldrb r1, [r1, #1]  @ r1 = b1
    ldrb r7, [r2, #2]  @ r7 = rnd2
    bl   gfmul    @ r0 = a0*b1
    eors r6, r0   @ r6 = (rnd0^(a0*b1))
    
    mov  r0, r9    @ r0 = &a
    mov  r1, r10   @ r1 = &b
    ldrb r0, [r0, #1]  @ r0 = a1
    ldrb r1, [r1, #0]  @ r1 = b0
    bl   gfmul    @ r0 = a1*b0
    
    eors r6, r0   @ r6 = [(rnd0^(a0*b1))^(a1*b0)]
    eors r5, r6   @ r5 = (a1*b1)^[(rnd0^(a0*b1))^(a1*b0)]
    eors r5, r7   @ r5 = c1 = (a1*b1)^[(rnd0^(a0*b1))^(a1*b0)]^rnd2

@@@@ r2 = &rnd, r4 = c0, r5 = c1, r3 = a2*b2, r11 = a0

@@@@ c2 = [(rnd1^(a0*b2))^(a2*b0)]^[(rnd2^(a1*b2))^(a2*b1)]^(a2*b2) 
    mov  r0, r11   @ r0 = a0
    mov  r1, r10   @ r1 = &b
    ldrb r1, [r1, #2]  @ r1 = b2
    @@@@ a0 is not needed, r11 can be used
    mov  r11, r1   @ r11 = b2

    bl   gfmul     @ r0 = a0*b2
    ldrb r7, [r2, #1]  @ r7 = rnd1
    eors r7, r0    @ r7 = (rnd1^(a0*b2))

@@@@ c2 = [(rnd1^(a0*b2))^(a2*b0)]^[(rnd2^(a1*b2))^(a2*b1)]^(a2*b2) 
    mov  r0, r9    @ r0 = &a
    mov  r1, r10   @ r1 = &b
    ldrb r0, [r0, #2]  @ r0 = a2
    ldrb r1, [r1, #0]  @ r1 = b0
    bl   gfmul    @ r0 = a2*b0
    eors r7, r0   @ r7 = [(rnd1^(a0*b2))^(a2*b0)] 
    
    
    mov  r0, r9    @ r0 = &a
    ldrb r0, [r0, #1]  @ r0 = a1
    mov  r1, r11  @ r1 = b2
    ldrb r6, [r2, #2]  @ r6 = rnd2
    bl   gfmul    @ r0 = a1*b2
    eors r6, r0   @ r6 = (rnd2^(a1*b2))


    mov  r0, r9    @ r0 = &a
    mov  r1, r10   @ r1 = &b
    ldrb r0, [r0, #2]  @ r0 = a2
    ldrb r1, [r1, #1]  @ r1 = b1
    bl   gfmul    @ r0 = a2*b1
    eors r6, r0   @ r6 = [(rnd2^(a1*b2))^(a2*b1)]
    eors r6, r7   @ r6 = [(rnd1^(a0*b2))^(a2*b0)]^[(rnd2^(a1*b2))^(a2*b1)]
    eors r6, r3   @ r6 = c2 = [(rnd1^(a0*b2))^(a2*b0)]^[(rnd2^(a1*b2))^(a2*b1)]^(a2*b2) 


    
    mov  r3, r8

    strb r4, [r3, #0] @r4 = c0
    strb r5, [r3, #1] @r5 = c1
    strb r6, [r3, #2] @r6 = c2




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
