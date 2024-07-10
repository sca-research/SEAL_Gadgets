# Galois field multiplication based on Log_Exp: GF(2^8)

c = a * b, where a, b and c are one share.

The function **gfmul** is used in all gadget for computing a[i] * b[i].


**gf_mul.S** is the implementation of GF(2^8) (gfmul(a,b,c), c = a * b) for ARM Cortex-M0/3 in GNU assembly, with THUMB-16 instructions.
The multiplication is based on Log_Ex with table.

**gf_mul.S** can be compiled for any ARM Cortex-M0/3.


**gf_mul.h** contains the table of Log_Exp.


The script is tested via calling gfmul(a,b,c) function in **gf_mul.c**.


**test_GFMUL.py** is for generating random inputs, sending the inputs from PC to the
Microcontroller and receiving the output from Microcontroller via UART port.

In case using  [SCALE board](https://github.com/danpage/scale):

From **scale** directory run: 
```./run.sh GFMUL gf_mul```

Then for test, run **test_GFMUL.py**



