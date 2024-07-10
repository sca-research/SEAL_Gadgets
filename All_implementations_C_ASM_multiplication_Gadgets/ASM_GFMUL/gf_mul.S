
  .syntax unified
  .text
  .thumb
  
  .extern table       @@@@ table is used for gfmult


@@@@@ uint8_t gfmul(uint8_t a, uint8_t b, uint8_t c); For calculating: c = a * b
@@@@@@@@ gfmul(in_r0:a, in_r1: b, out_r0: return)
@ r0 = &a, @ r1 = &b, @ r2 = &c

.global gfmul
.func gfmul
gfmul:

	push	 {r2-r6}

    ldr  r6, =table     @ the address of the  "table"

    ldrb r0, [r0, #0]   @ r0 = a
    ldrb r1, [r1, #0]   @ r1 = b
    ldrb r3, [r6, r0]   @ r3 = table[a]
    ldrb r4, [r6, r1]   @ r4 = table[b] 
    adds r3, r4         @ r3 = s = table[a] + table[b]

    @@@@ Get the antilog: s = table[s+256]: g ^ s 
    adds r3, #128       @ r3 = s + 128 :s + 256; : 256 is more than one byte, split: 128 + 128
    adds r3, #128       @ r3 = s + 256
    ldrb r4, [r6, r3]   @ r4 = s = table[s+256]

    @@@@ Checking if a = 0 or b = 0, return 0; without conditional branch
    negs r5, r0         @ r5 = -a
    asrs r5, #32        @ r5 = -a >> 8  (4*8=32)
    ands r5, r1         @ r5 = tmp = b & (-a >> 8)
    negs r5, r5         @ r5 = -tmp 
    asrs r5, #32        @ r5 = -tmp >> 8
    ands r4, r5         @ r4 = s & (-tmp >> 8)

    mov  r0, r4
    strb r4, [r2, #0]   @ r2 = c: a * b
	
  pop {r2-r6}
	
  bx lr
.endfunc
.end

