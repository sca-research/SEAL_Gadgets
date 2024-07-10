# Implementations of Multiplication gadgets
 ### Two and three shares
Multiplication: a.b = c

Gadgets: **ISW, BBPP, DOM_INDEP, HPC1_OPT, PINI1, PINI2**

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

## Example
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
