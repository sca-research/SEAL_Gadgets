@ Dom_dep_5_B

@  ^: xor; +: arithmathic addition; x & y: and operation; *: Galois field multiplication; &x: the address of x
@ a = a0^a1^a2^a3^a4, b = b0^b1^b2^b3^b4, c = c0^c1^c2^c3^c4, a*b = c, random numbers: rnd0, rnd1, rnd2


@ Computing the output of DOM_indep(a, z)
@@@@ c0_indep = (a0*z0)^[(a0*z1)^rand0]^[(a0*z2)^rand1]^[(a0*z3)^rand3]^[(a0*z4)^rand6]
@@@@ c1_indep = [(a1*z0)^rand0]^(a1*z1)^[(a1*z2)^rand2]^[(a1*z3)^rand4]^[(a1*z4)^rand7]
@@@@ c2_indep = [(a2*z0)^rand1]^[(a2*z1)^rand2]^(a2*z2)^[(a2*z3)^rand5]^[(a2*z4)^rand8]
@@@@ c3_indep = [(a3*z0)^rand3]^[(a3*z1)^rand4]^[(a3*z2)^rand5]^(a3*z3)^[(a3*z4)^rand9]
@@@@ c4_indep = [(a4*z0)^rand6]^[(a4*z1)^rand7]^[(a4*z2)^rand8]^[(a4*z3)^rand9]^(a4*z4)

@@@@ Computing: x = Decode(X)
@@ X = x0, x1, x2, x3
@@ x0 = (z0^b0)
@@ x1 = (z1^b1)
@@ x2 = (z2^b2)
@@ x3 = (z3^b3)
@@ x4 = (z4^b4)
@@ x = Decode(X)= x0^x1^x2^x3= (z0^b0)^(z1^b1)^(z2^b2)^(z3^b3)

@@@@@ Computing: the outputs of DOM_depen ci_dep: (ai*x)^(ci_indep)
@@@@ c0: c0_dep: (a0*x)^c0_indep
@@@@ c1: c1_dep: (a1*x)^c1_indep
@@@@ c2: c2_dep: (a2*x)^c2_indep
@@@@ c3: c3_dep: (a3*x)^c3_indep
@@@@ c4: c4_dep: (a4*x)^c4_indep
  .syntax unified
  .text
  .thumb
  
  .extern table       @@@@ table is used for gfmult
  
@@@@ extern void Dom_dep_4(uint8_t* inputa: addres: r0, uint8_t* inputb: address: r1, uint8_t* rnd: address: r2, uint8_t* output: address: r3);
@inputa: a0-a4, inputb: b0-z4, rnd: rnd0-rnd14, output: c: c0-c4
@ (z0, z1, z2, z3, z4) = (rnd0, rnd1, rnd2, rnd3, rnd4); randomness for DOM_indep (rand0, rand9) = (rnd5, rnd14)

.global Dom_dep_5
.func Dom_dep_5
Dom_dep_5:
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

@@@@@@@@@@ Computing: ai*zi
@@@@@@ In gfmul, r0 and r1 are the arguments
@@@@ a0*z0
  ldrb r4, [r0, #0] @ r4 = a0;  r0 = &a, r1 = &b, r2 = &rnd, r3 = &c // for computing c0_indep, a0 is needed, so it is loaded into r4
  ldrb r5, [r2, #0] @ r5 = z0;  r0 = &a, r1 = &b, r2 = &rnd, r3 = &c // for computing c0_indep, b0 is needed, so it is loaded into r5
  mov  r0, r4       @ r0 = a0; 
  mov  r1, r5       @ r1 = z0; 
  bl   gfmul        @ r0 = a0*z0

  strb r0, [r3, #0] @ Storing (a0*z0) in c0

@@@@ a1*z1
  mov  r0, r8       @ r0 = &a
  ldrb r0, [r0, #1] @ r0 = a1;  r0 = a1, r1 = &b, r2 = &rnd, r3 = &c // for computing c0_indep, a1 is not needed, so it is loaded into r0, then it will be clear
  ldrb r6, [r2, #1] @ r6 = z1;  r0 = a1, r1 = &b, r2 = &rnd, r3 = &c // for computing c0_indep, z1 is needed, so it is loaded into r6
  mov  r1, r6       @ r1 = z1
  bl   gfmul        @ r0 = a1*z1

  strb r0, [r3, #1] @ Storing (a1*z1) in c1

@@@@ a2*z2
  mov  r0, r8       @ r0 = &a
  ldrb r0, [r0, #2] @ r0 = a2;  r0 = a2, r1 = &b // for computing c0_indep, a2 is not needed, so it is loaded into r0, then it will be clear
  ldrb r7, [r2, #2] @ r7 = z2;  r0 = a2, r1 = &b // for computing c0_indep, z2 is neededso, so it is loaded into r7
  mov  r1, r7       @ r1 = z2
  bl   gfmul        @ r0 = a2*z2

  strb r0, [r3, #2] @ Storing (a2*z2) in c2

@@@@ a3*z3
  mov  r0, r8       @ r0 = &a
  mov  r1, r9       @ r1 = &b
  ldrb r0, [r0, #3] @ r0 = a3;  r0 = a3, r1 = &b // for computing c0_indep, a3 is not needed, so it is loaded into r0, then it will be clear
  ldrb r1, [r2, #3] @ r1 = z3;  r0 = a3, r1 = z3 
  mov  r10, r1      @ r10 = z3  @ Saving z3 // for computing c0_indep, z3 is needed
  bl   gfmul        @ r0 = a3*z3

  strb r0, [r3, #3] @ Storing (a3*z3) in c3

@@@@ a4*z4
  mov  r0, r8       @ r0 = &a
  ldrb r0, [r0, #4] @ r0 = a4;  r0 = a4, r1 = &b // for computing c0_indep, a4 is not needed, so it is loaded into r0, then it will be clear
  ldrb r1, [r2, #4] @ r1 = z4;  r0 = a4, r1 = z4
  mov  r11, r1      @ r11 = z4  @ Saving z4 // for computing c0_indep, z4 is needed
  bl   gfmul        @ r0 = a4*z4

  strb r0, [r3, #4] @ Storing (a3*z3) in c3


@@@@@@@@@@ Computing: The outputs of DOM_independent ci_indep

@From previous step: 
@@@@ r2 = &rnd, r3 = &c, r4 = a0, r5 = z0, r6 = z1
@@@@ r7 = z2, r8 = &a, r9 = &b, r10 = z3, r11 = z4

@@@@ c0_indep = (a0*z0)^[(a0*z1)^rand0]^[(a0*z2)^rand1]^[(a0*z3)^rand3]^[(a0*z4)^rand6]
  mov  r0, r4         @ r0 = a0
  mov  r1, r6         @ r1 = z1
  bl   gfmul          @ r0 = a0*z1

  ldrb r6, [r2, #5]   @ r6 = rand0 // r6 = z1, for computing c1_indep, z1 (alone) is not needed, so, r6 can be used here
  eors r6, r0         @ r6 = [(a0*z1)^rand0]

  ldrb r0, [r3, #0]   @ r0 = a0*z0

  eors r6, r0         @ r6 = (a0*z0)^[(a0*z1)^rand0]


  mov  r0, r4         @ r0 = a0
  mov  r1, r7         @ r1 = z2
  bl   gfmul          @ r0 = a0*z2

  ldrb r1, [r2, #6]   @ r1 = rand1
  eors r1, r0         @ r1 = [(a0*z2)^rand1]
  
  eors r6, r1         @ r6 = (a0*z0)^[(a0*z1)^rand0]^[(a0*z2)^rand1]


  mov  r0, r4         @ r0 = a0  
  mov  r1, r10        @ r1 = z3
  bl   gfmul          @ r0 = a0*z3

  ldrb r1, [r2, #8]   @ r1 = rand3
  eors r1, r0         @ r1 = [(a0*z3)^rand3]

  eors r6, r1         @ r6 = (a0*z0)^[(a0*z1)^rand0]^[(a0*z2)^rand1]^[(a0*z3)^rand3]


  mov  r0, r4         @ r0 = a0  
  mov  r1, r11        @ r1 = z4
  bl   gfmul          @ r0 = a0*z4

  ldrb r1, [r2, #11]   @ r1 = rand6
  eors r1, r0         @ r1 = [(a0*z4)^rand6]

  eors r6, r1         @ r6 = (a0*z0)^[(a0*z1)^rand0]^[(a0*z2)^rand1]^[(a0*z3)^rand3]^[(a0*z4)^rand6]


  strb r6, [r3, #0]   @ Storing the output of DOM_independent c0_indep in c0



@From previous step: 
@@@@ r2 = &rnd, r3 = &c, r4 = a0, r5 = z0, r6 = 
@@@@ r7 = z2, r8 = &a, r9 = &b, r10 = z3, r11 = z4
@@@@ c1_indep = [(a1*z0)^rand0]^(a1*z1)^[(a1*z2)^rand2]^[(a1*z3)^rand4]^[(a1*z4)^rand7]

  mov  r0, r8         @ r0 = &a
  ldrb r4, [r0, #1]   @ r0 = a1

  mov  r0, r4         @ r0 = a1
  mov  r1, r5         @ r1 = z0
  bl   gfmul          @ r0 = a1*z0

  ldrb r6, [r2, #5]   @ r6 = rand0 
  eors r6, r0         @ r6 = [(a1*z0)^rand0]

  ldrb r0, [r3, #1]   @ r0 = a1*z1

  eors r6, r0         @ r6 = [(a1*z0)^rand0]^(a1*z1)


  mov  r0, r4         @ r0 = a1
  mov  r1, r7         @ r1 = z2
  bl   gfmul          @ r0 = a1*z2

  ldrb r1, [r2, #7]   @ r1 = rand2
  eors r1, r0         @ r1 = [(a1*z2)^rand2]
  
  eors r6, r1         @ r6 = [(a1*z0)^rand0]^(a1*z1)^[(a1*z2)^rand2]


  mov  r0, r4         @ r0 = a1  
  mov  r1, r10        @ r1 = z3
  bl   gfmul          @ r0 = a1*z3

  ldrb r1, [r2, #9]   @ r1 = rand4
  eors r1, r0         @ r1 = [(a1*z3)^rand4]

  eors r6, r1         @ r6 = [(a1*z0)^rand0]^(a1*z1)^[(a1*z2)^rand2]^[(a1*z3)^rand4]


  mov  r0, r4         @ r0 = a1  
  mov  r1, r11        @ r1 = z4
  bl   gfmul          @ r0 = a1*z4

  ldrb r1, [r2, #12]   @ r1 = rand7
  eors r1, r0         @ r1 = [(a1*z4)^rand7]

  eors r6, r1         @ r6 = [(a1*z0)^rand0]^(a1*z1)^[(a1*z2)^rnd2]^[(a1*z3)^rnd4]^[(a1*z4)^rnd7]


  strb r6, [r3, #1]   @ Storing the output of DOM_independent c1_indep in c1



@From previous step: 
@@@@ r2 = &rnd, r3 = &c, r4 = a1, r5 = z0, r6 = 
@@@@ r7 = z2, r8 = &a, r9 = &b, r10 = z3, r11 = z4

@@@@ c2_indep = [(a2*z0)^rand1]^[(a2*z1)^rand2]^(a2*z2)^[(a2*z3)^rand5]^[(a2*z4)^rand8]
  mov  r0, r8         @ r0 = &a
  mov  r1, r9         @ r1 = &b
  ldrb r4, [r0, #2]   @ r0 = a2
  ldrb r7, [r2, #1]   @ r7 = z1  // r7 = z2, for computing c2_indep, z2 (alone) is not needed, so, r7 can be used here

  mov  r0, r4         @ r0 = a2
  mov  r1, r5         @ r1 = z0
  bl   gfmul          @ r0 = a2*z0

  ldrb r6, [r2, #6]   @ r6 = rand1
  eors r6, r0         @ r6 = [(a2*z0)^rand1]


  mov  r0, r4         @ r0 = a2
  mov  r1, r7         @ r1 = z1
  bl   gfmul          @ r0 = a2*z1

  ldrb r1, [r2, #7]   @ r1 = rand2
  eors r1, r0         @ r1 = [(a2*z1)^rand2]
  
  eors r6, r1         @ r6 = [(a2*z0)^rand1]^[(a2*z1)^rand2] 

  ldrb r0, [r3, #2]   @ r0 = a2*z2
  eors r6, r0         @ r6 = [(a2*z0)^rand1]^[(a2*z1)^rand2]^(a2*z2)


  mov  r0, r4         @ r0 = a2  
  mov  r1, r10        @ r1 = z3
  bl   gfmul          @ r0 = a2*z3

  mov  r10, r7        @ r10 = z1 // r10 = z3, r7 = z1; for computing c2_indep, z3 (alone) is not needed, so, r7 can be used here


  ldrb r1, [r2, #10]   @ r1 = rand5
  eors r1, r0         @ r1 = [(a2*z3)^rand5]

  eors r6, r1         @ r6 = [(a2*z0)^rand1]^[(a2*z1)^rand2]^(a2*z2)^[(a2*z3)^rand5] 


  mov  r0, r4         @ r0 = a2  
  mov  r1, r11        @ r1 = z4
  bl   gfmul          @ r0 = a2*z4

  ldrb r1, [r2, #13]   @ r1 = rand8
  eors r1, r0         @ r1 = [(a2*z4)^rand8]

  eors r6, r1         @ r6 = c2_indep = [(a2*z0)^rand1]^[(a2*z1)^rand2]^(a2*z2)^[(a2*z3)^rand5]^[(a2*z4)^rand8]

 
  strb r6, [r3, #2]    @ Storing the output of DOM_independent c2_indep in c2
  
  
@From previous step: 
@@@@ r2 = &rnd, r3 = &c, r4 = a1, r5 = z0, r6 = 
@@@@ r7 = z1, r8 = &a, r9 = &b, r10 = z1, r11 = z4

@@@@ c3_indep = [(a3*z0)^rand3]^[(a3*z1)^rand4]^[(a3*z2)^rand5]^(a3*z3)^[(a3*z4)^rand9]

  mov  r0, r8         @ r0 = &a
  mov  r1, r9         @ r1 = &b
  ldrb r4, [r0, #3]   @ r0 = a3
  ldrb r7, [r2, #2]   @ r7 = z2  // r7 = z1 and r10 = z1, for computing c3_indep, z1 and z2 (alone) are  needed, so, r7 or r10 can be used here.

  mov  r0, r4         @ r0 = a3
  mov  r1, r5         @ r1 = z0
  bl   gfmul          @ r0 = a3*z0

  ldrb r6, [r2, #8]   @ r6 = rand3
  eors r6, r0         @ r6 = [(a3*z0)^rand3]


  mov  r0, r4         @ r0 = a3
  mov  r1, r10        @ r1 = z1
  bl   gfmul          @ r0 = a3*z1

  ldrb r1, [r2, #9]   @ r1 = rand4
  eors r1, r0         @ r1 = [(a3*z1)^rand4]
  
  eors r6, r1         @ r6 = [(a3*z0)^rand3]^[(a3*z1)^rand4] 

  mov  r0, r4         @ r0 = a3  
  mov  r1, r7         @ r1 = z2
  bl   gfmul          @ r0 = a3*z2

  ldrb r1, [r2, #10]   @ r1 = rand5
  eors r1, r0         @ r1 = [(a3*z2)^rand5]

  eors r6, r1         @ r6 = [(a3*z0)^rand3]^[(a3*z1)^rand4]^[(a3*z2)^rand5]

  ldrb r0, [r3, #3]   @ r0 = a3*z3
  eors r6, r0         @ r6 = [(a3*z0)^rand3]^[(a3*z1)^rand4]^[(a3*z2)^rand5]^(a3*z3)

  mov  r0, r4         @ r0 = a3  
  mov  r1, r11        @ r1 = z4
  bl   gfmul          @ r0 = a3*z4

  ldrb r4, [r2, #14]   @ r1 = rand9   @ saving rand9  // r4 = a3; for computing c4_indep, a3 is not  needed, so, r4 can be used here.
  mov  r11, r4        @ r11 = rand9
  eors r4, r0         @ r1 = [(a3*z4)^rand9]

  eors r6, r4         @ r6 = c3_indep = [(a3*z0)^rand3]^[(a3*z1)^rand4]^[(a3*z2)^rand5]^(a3*z3)^[(a3*z4)^rand9]


  strb r6, [r3, #3]    @ Storing the output of DOM_independent c3_indep in c3
  
 

@From previous step: 
@@@@ r2 = &rnd, r3 = &c, r4 = , r5 = z0, r6 = 
@@@@ r7 = z2, r8 = &a, r9 = &b, r10 = z1, r11 = rand9


@@@@ c4_indep = [(a4*z0)^rand6]^[(a4*z1)^rand7]^[(a4*z2)^rand8]^[(a4*z3)^rand9]^(a4*z4)
  mov  r0, r8         @ r0 = &a
  mov  r1, r9         @ r1 = &b
  ldrb r4, [r0, #4]   @ r0 = a4
  ldrb r6, [r2, #3]   @ r6 = z3

  mov  r0, r4         @ r0 = a4
  mov  r1, r5         @ r1 = z0
  bl   gfmul          @ r0 = a4*z0

  ldrb r5, [r2, #11]   @ r5 = rand6 // r5 = z0, z0 is not needed more
  eors r5, r0         @ r5 = [(a4*z0)^rand6] 


  mov  r0, r4         @ r0 = a4
  mov  r1, r10        @ r1 = z1
  bl   gfmul          @ r0 = a4*z1

  ldrb r1, [r2, #12]   @ r1 = rand7
  eors r1, r0         @ r1 = [(a4*z1)^rand7]
  
  eors r5, r1         @ r5 = [(a4*z0)^rand6]^[(a4*z1)^rand7]

  mov  r0, r4         @ r0 = a4  
  mov  r1, r7         @ r1 = z2
  bl   gfmul          @ r0 = a4*z2

  ldrb r1, [r2, #13]   @ r1 = rand8
  eors r1, r0         @ r1 = [(a4*z2)^rand8]

  eors r5, r1         @ r5 = [(a4*z0)^rand6]^[(a4*z1)^rand7]^[(a4*z2)^rand8]

  
  mov  r0, r4         @ r0 = a4
  mov  r1, r6         @ r1 = z3
  bl   gfmul          @ r0 = a4*z3

  mov  r1, r11        @ r11 = rand9
  eors r1, r0         @ r1 = [(a4*z3)^rand9]

  eors r5, r1         @ r5 = [(a4*z0)^rand6]^[(a4*z1)^rand7]^[(a4*z2)^rand8]^[(a4*z3)^rand9] 

  ldrb r0, [r3, #4]   @ r0 = a4*z4

  eors r5, r0         @ r5 = c4_indep = [(a4*z0)^rand6]^[(a4*z1)^rand7]^[(a4*z2)^rand8]^[(a4*z3)^rand9]^(a4*z4)


  strb r5, [r3, #4]    @ Storing the output of DOM_independent c4_indep in c4
  

###############################################################################################
@@@@ Computing: x = Decode(X)
@@@@@@@@@@ Computing: x = (z0^b0)^(z1^b1)^(z2^b2)^(z3^b3)^(z4^b4)  
@From previous step: 
@@@@ r2 = &rnd, r3 = &c, r4 = a4, r5 = , r6 = z3
@@@@ r7 = z2, r8 = &a, r9 = &b, r10 = z1, r11 = rand9
  mov  r11, r3        @ r11 = &c
  mov  r1, r9         @ r1 = &b
  ldrb r4, [r1, #0]   @ r4 = b0
  ldrb r5, [r1, #1]   @ r5 = b1
  ldrb r3, [r1, #2]   @ r3 = b2
  ldrb r0, [r1, #3]   @ r0 = b3
  mov  r9, r0         @ r9 = b3  // r9 = &b is not needed
  ldrb r1, [r1, #4]   @ r1 = b4
  ldrb r0, [r2, #0]   @ r0 = z0  
  ldrb r2, [r2, #4]   @ r2 = z4


  eors r4, r0         @ r4 = z0^b0

  mov  r0, r10        @ r0 = z1
  eors r5, r0         @ r5 = z1^b1

  eors r3, r7         @ r3 = z2^b2

  mov  r0, r9         @ r0 = b3
  eors r6, r0         @ r6 = z3^b3

  eors r1, r2         @ r1 = z4^b4


  eors r4, r5         @ (z0^b0)^(z1^b1)
  eors r4, r3         @ (z0^b0)^(z1^b1)^(z2^b2)
  eors r4, r6         @ r1 = x = (z0^b0)^(z1^b1)^(z2^b2)^(z3^b3)
  eors r1, r4         @ r1 = x = (z0^b0)^(z1^b1)^(z2^b2)^(z3^b3)^(z4^b4)


@@@@@@@@@@ Computing: the outputs of DOM_depen ci_dep: (ai*x)^ci_indep
@From previous step: 
@@@@ r1 = x, r2 = z4, r3 = , r4 = , r5 = , r6 = 
@@@@ r7 = z2 , r8 = &a, r9 = b3, r10 = z1, r11 = &c
  mov  r3, r11         @ r3 = &c

  mov  r0, r8         @ r0 = &a
  ldrb r2, [r0, #1]   @ r2 = a1
  ldrb r4, [r0, #2]   @ r4 = a2
  ldrb r5, [r0, #3]   @ r5 = a3
  mov  r8, r5         @ r8 = a3
  ldrb r5, [r0, #4]   @ r5 = a4
  mov  r9, r5         @ r9 = a4
  ldrb r0, [r0, #0]   @ r0 = a0


  ldrb r5, [r3, #0]   @ r5 = c0_indep
  ldrb r6, [r3, #1]   @ r6 = c1_indep
  ldrb r7, [r3, #2]   @ r7 = c2_indep
  

@r0 = a0, r1 = x
  bl   gfmul          @ r0 = a0*x
  eors r5, r0         @ r5 = c0_dep = (a0*x)^c0_indep

  
@r1 = x
  mov  r0, r2         @ r0 = a1
  bl   gfmul          @ r0 = a1*x
  eors r6, r0         @ r6 = c1_dep = (a1*x)^c1_indep

 
@r1 = x
  mov  r0, r4         @ r0 = a2
  bl   gfmul          @ r0 = a2*x
  eors r7, r0         @ r7 = c2_dep = (a2*x)^c2_indep


  strb r5, [r3, #0]    @ Storing the output of DOM_dependent c0_dep in c0
  strb r6, [r3, #1]    @ Storing the output of DOM_dependent c1_dep in c1
  strb r7, [r3, #2]    @ Storing the output of DOM_dependent c2_dep in c2


  ldrb r6, [r3, #3]   @ r6 = c3_indep
  ldrb r7, [r3, #4]   @ r7 = c4_indep
  

@r1 = x
  mov  r0, r8         @ r0 = a3
  bl   gfmul          @ r0 = a3*x
  eors r6, r0         @ r6 = c3_dep = (a3*x)^c3_indep



@r1 = x
  mov  r0, r9         @ r0 = a4
  bl   gfmul          @ r0 = a4*x
  eors r7, r0         @ r7 = c4_dep = (a4*x)^c4_indep


  strb r6, [r3, #3]    @ Storing the output of DOM_dependent c3_dep in c3
  strb r7, [r3, #4]    @ Storing the output of DOM_dependent c4_dep in c4




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

