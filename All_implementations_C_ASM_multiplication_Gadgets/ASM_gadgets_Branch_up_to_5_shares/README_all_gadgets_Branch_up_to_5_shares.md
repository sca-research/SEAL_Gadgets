# Implementations of Multiplication gadgets
 ### Up to 5 shares
 ### $a_i.b_j$ is calculated by **gfmul** function (```bl gfmul``` in **.S** file).
 ### Prefix **_b, _B** means using branch instruction (```bl gfmul```). 
 ### Leakage detection is not conducted.

Multiplication: a.b = c 

## Gadgets: 

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

## Example
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
