# Software implementations of Multiplication gadgets in C and Assembly

---

## Table of Contents
<!-- TOC -->

- [Software implementations of Multiplication gadgets in C and Assembly](#software-implementations-of-multiplication-gadgets-in-c-and-assembly)
  - [Table of Contents](#table-of-contents)
- [ASM\_GFMUL](#asm_gfmul)
  - [test\_GFMUL.py](#test_gfmulpy)
- [ASM\_gadgets\_2\_3\_shares\_Leakage\_Detection](#asm_gadgets_2_3_shares_leakage_detection)
  - [Gadgets](#gadgets)
  - [all_gadgets_leakage_detection.pdf](#all_gadgets_leakage_detection.pdf)
  - [Implementation info](#implementation-info)
  - [Example, using on Scale Board, RUN\_gadgets.py](#example-using-on-scale-board-run_gadgetspy)
- [ASM\_gadgets\_Branch\_up\_to\_5\_shares](#asm_gadgets_branch_up_to_5_shares)
  - [Gadgets](#gadgets-1)
  - [Implementation info](#implementation-info-1)
  - [Example, using on Scale board, RUN\_gadgets.py](#example-using-on-scale-board-run_gadgetspy-1)
- [C\_implementations\_Gadgets](#c_implementations_gadgets)
  - [Example](#example)

<!-- /TOC -->



# ASM_GFMUL

c = a * b, where a, b and c are one share.

The function **gfmul** is used in all gadget for computing a[i] * b[i].


**gf_mul.S** is the implementation of GF(2^8) (gfmul(a,b,c), c = a * b) for ARM Cortex-M0/3 in GNU assembly, with THUMB-16 instructions.
The multiplication is based on Log_Ex with table.

**gf_mul.S** can be compiled for any ARM Cortex-M0/3.


**gf_mul.h** contains the table of Log_Exp.


The script is tested via calling gfmul(a,b,c) function in **gf_mul.c**.

## test_GFMUL.py
**test_GFMUL.py** is for generating random inputs, sending the inputs from PC to the
Microcontroller and receiving the output from Microcontroller via UART port.

In case using  [SCALE board](https://github.com/danpage/scale):

From **scale** directory run: 
```./run.sh GFMUL gf_mul```

Then for test, run **test_GFMUL.py**

# ASM_gadgets_2_3_shares_Leakage_Detection
Two and three shares
Multiplication: a.b = c

## Gadgets 

1) ISW
2) BBPP
3) DOM_INDEP
4) HPC1_OPT 
5) PINI1
6) PINI2

## all_gadgets_leakage_detection.pdf
Leakage detection is conducted for the two and three shares implementations, which are also documented in **all_gadgets_leakage_detection.pdf**.

## Implementation info
1) Arm assembly (thumb-16 instructions), tested on LPC NXP Cortex-M3.
2) byte-oriented
3) Inputs (shares of a, b, rnd) of the gadgets are generated **externally** and then sent to the device. 
4) Inputs (shares of a, b, rnd) and outputs (shares of c) of the gadgets
are stored in memory as the follow: For example, when n_sh=3:
    ```
    Mem map:
     * 00 00 00 a0
     * 00 00 00 a1
     * 00 00 00 a2
    ```
   In this way, the horizontal neighbor effects are eliminated.
5) All together 10 Instructions have been used:
    ```
    mov
    movs
    ldrb R_x, [R_y, R_z]
    ldrb R_x, [R_y, \#imm]
    ldr R_x, =table
    adds
    negs
    asrs
    ands
    eors
    strb R_x, [R_y, \#imm]$
    pop
    push
    ```

6) No control-flow instructions: no branch instruction
7) Galois field multiplication for one share is based on Double Log-Exp, using lookup table.
8) In our power-consumption measurement setup, we record the instructions before raising-edge of 
the trigger.  Therefore, trigger instructions (according to [SCALE board](https://github.com/danpage/scale)) is spotted (in these implementations) in the .S file, as the follow: 

```
 @ Trigger
#########################################################################
# Seperating instructions related to main function and trigger, as there are pipeline stages 
  @ Trigger
  @ scale.c: LPC13XX_GPIO1->GPIODATA &= ~( 0x1 <<  0 ) ; // initialise SCALE_GPIO_PIN_TRG = 0
  @ SCALE_GPIO_PIN_TRG in scale board: pin33: PIO1_0
  @ PIO1_0: https://www.digikey.pl/htmldatasheets/production/660585/0/0/1/lpc1311fhn33-551.html : 9.4 Register description
  @ baseaddress: 0x50010000, offset: 0x3ffc, baseaddress: 0x50010000, offset: 0x3ffc
  @ address: 0x5001ffc; producing this value: needs several instructions:
  @ https://developer.arm.com/documentation/den0042/a/Unified-Assembly-Language-Instructions/Instruction-set-basics/Constant-and-immediate-values

  @ Start of trigger
  ldr  r4, =0x50013ffc
  movs r5,#1
  ldr  r6, [r4, #0]  @ r6 = 0 : SCALE_GPIO_PIN_TRG = 0
  # test: str  r6, [r3, #0]  @ r6 = 0xfc0f0000
  eors r5, r6  @ r5 = 1 @ Start trigger: SCALE_GPIO_PIN_TRG = 1
  str  r5, [r4, #0]
  nop
  nop
  nop
  nop
  @ End of trigger
  str  r6, [r4, #0] @ End trigger: r6 = 0 : SCALE_GPIO_PIN_TRG = 0
```
If a trigger is not required, these instruction can be omitted. 

Within the [SCALE board](https://github.com/danpage/scale) framework, it is also possible to add the trigger into a .c file, as demonstrated below:
```
   scale_gpio_wr( SCALE_GPIO_PIN_TRG, true);
        Isw_3(shares_a, shares_b, rnd, shares_ab);
    scale_gpio_wr( SCALE_GPIO_PIN_TRG, false);
```

## Example, using on Scale Board, RUN_gadgets.py
In case you wish to use the implementations on [SCALE board](https://github.com/danpage/scale). 
Please follow the below example.
The same procedure is applied to all gadgets (ISW, BBPP, DOM_INDEP, HPC1_OPT, PINI1, PINI2).

**ISW_2 file**: The implementation of the First-Order ISW multiplication (two shares) in Arm assembly, with THUMB-16 instructions.
 is for testing the isw_2 function.
**RUN_gadgets.py**: Running the gadgets by transferring data through UART to/from the [SCALE board](https://github.com/danpage/scale).


Testing:

Download [SCALE](https://github.com/danpage/scale).

`$ git clone http://www.github.com/danpage/scale.git`

`$ cd scale ; export SCALE="${PWD}"`

`$ git submodule update --init --recursive `

Copy  [ISW_2 file](https://github.com/sca-research/Gadgets_Masking/tree/main/Assembly_implementation/ISW/ISW_2_o/ISW_2)
in `scale/hw` directory.
Then:

`$  cd scale`

`$ export SCALE="${PWD}"`

`$ cd hw`

`$ export SCALE_HW="${PWD}"`

`$ export TARGET="${SCALE_HW}/target/lpc1313fbd48"`

`$  cd ${TARGET}`

`$ make --no-builtin-rules clean all`

`$  cd ${SCALE_HW}/isw_2`

`$ sudo  make --no-builtin-rules -f ${TARGET}/build/lib/scale.mk BSP="${TARGET}/build" USB="/dev/ttyUSB0" PROJECT="isw_2" PROJECT_SOURCES="isw_2.c isw_2.S" clean all program`

Then, on the [SCALE board](https://github.com/danpage/scale):

1) Press and hold the (right-hand) GPI switch,

2) Press and hold the (left-hand) reset switch,

3) Release the (left-hand) reset switch,

4) Transfer via lpc21isp starts,

5) Release the (right-hand) GPI switch,

Finally, running the **RUN_gadgets.py**.




# ASM_gadgets_Branch_up_to_5_shares

 Up to 5 shares
 
 $a_i.b_j$ is calculated by **gfmul** function (```bl gfmul``` in **.S** file).
 
 Prefix **_b, _B** means using branch instruction (```bl gfmul```). 
 
 Leakage detection is not conducted.

Multiplication: a.b = c 

## Gadgets

1) **ISW**: Up to 5 shares

2) **HPC1_OPT**: Up to 4 shares

3) **DOM_DEP**: 3 to 5 shares

4) **DOM_INDEP**: Up to 5 shares

5) **BBPP_OPT**: 3 to 5 shares


## Implementation info
1) Arm assembly (thumb-16 instructions), tested on LPC NXP Cortex-M3.
2) byte-oriented
3) Inputs (shares of a, b, rnd) of the gadgets are generated **externally** and then sent to the device. 
4) Inputs (shares of a, b, rnd) and outputs (shares of c) of the gadgets
are stored in memory as the follow: For example, when n_sh=4:
    ```
    Mem map:
     * a3 a2 a1 a0
     * ...
     * b3 b2 b1 b0
     * ...
     * c3 c2 c1 c0
    ```
5) All together the below instructions have been used:
    ```
    bl
    bx
    mov
    movs
    ldrb R_x, [R_y, R_z]
    ldrb R_x, [R_y, \#imm]
    ldr R_x, =table
    adds
    negs
    asrs
    ands
    eors
    strb R_x, [R_y, \#imm]$
    pop
    push
    ```

6) **gfmul**: Galois field multiplication for one share is based on Double Log-Exp, using lookup table.
   **gfmul** is defined as a function that computes the multiplication of $a_i.b_j$, and it is called by ```bl gfmul``` in **.S** file.

7) Branch instruction to call function **gfmul**.

## Example, using on Scale board, RUN_gadgets.py
In case you wish to use the implementations on [SCALE board](https://github.com/danpage/scale). 
Please follow the below example.
The same procedure is applied to all gadgets (ISW, BBPP, DOM_INDEP, HPC1_OPT, PINI1, PINI2).

**ISW_2_B file**: 
**_b, _B** in **ISW_2_B** means branch instruction. Branch instruction to call function **gfmul**. The implementation of the First-Order ISW multiplication (two shares) in Arm assembly, with THUMB-16 instructions.


**RUN_gadgets.py**: Running the gadgets by transferring data through UART to/from the [SCALE board](https://github.com/danpage/scale).


Testing:

Download [SCALE](https://github.com/danpage/scale).

`$ git clone http://www.github.com/danpage/scale.git`

`$ cd scale ; export SCALE="${PWD}"`

`$ git submodule update --init --recursive `

Copy  **ISW_2_B file** in `scale/hw` directory.
Then:

`$  cd scale`

`$ export SCALE="${PWD}"`

`$ cd hw`

`$ export SCALE_HW="${PWD}"`

`$ export TARGET="${SCALE_HW}/target/lpc1313fbd48"`

`$  cd ${TARGET}`

`$ make --no-builtin-rules clean all`

`$  cd ${SCALE_HW}/isw_2_b`

`$ sudo  make --no-builtin-rules -f ${TARGET}/build/lib/scale.mk BSP="${TARGET}/build" USB="/dev/ttyUSB0" PROJECT="isw_2_b" PROJECT_SOURCES="isw_2_b.c isw_2_b.S" clean all program`

Then, on the [SCALE board](https://github.com/danpage/scale):

1) Press and hold the (right-hand) GPI switch,

2) Press and hold the (left-hand) reset switch,

3) Release the (left-hand) reset switch,

4) Transfer via lpc21isp starts,

5) Release the (right-hand) GPI switch,

Finally, running the **RUN_gadgets.py**.



# C_implementations_Gadgets
C implementations of the gadgets.

Each gadget is encapsulated in its own directory including a header file (Gadget_name.h) and two source files (Gadget_name.c, main.c).


The number of ```Mask_ORD``` (number of shares = Mask_ORD+1) can be changed.

can be adjusted directly in the gadget's header file (Gadget_name.h).


For compilation:

Using the **GCC compiler**
```
gcc main.c Gadget_name.c
```

For running:
```
./a.out
```

## Example
From **ISW** directory:

```
gcc main.c ISW.c
```
**a.out** will be generated, 
For running:
```
./a.out
```



