# Software implementations of Multiplication gadgets in C and Assembly
This repository provides materials (Assembly sources, and analysis scripts) for the paper ``Efficiently Detecting Masking Flaws in Software Implementations'' (co-authored by Nima Mahdion and Elisabeth Oswald).
The ower traces that we utlised are archived via Zenodo and can be accessed from [Data set (traces) for Software implementations of Multiplication Gadgets: SEAL
](https://zenodo.org/records/10838182).

---

<!-- TOC -->


- [All_implementations_C_ASM_multiplication_Gadgets](#all_implementations_c_asm_multiplication_gadgets)
    - [ASM_GFMUL](#asm_gfmul)
        - [test_GFMUL.py](#test_gfmulpy)
    - [ASM_gadgets_2_3_shares_Leakage_Detection](#asm_gadgets_2_3_shares_leakage_detection)
        - [Gadgets](#gadgets)
        - [all_gadgets_leakage_detection.pdf](#all_gadgets_leakage_detectionpdf)
        - [Implementation info](#implementation-info)
        - [Example, using on Scale Board, RUN_gadgets.py](#example-using-on-scale-board-run_gadgetspy)
    - [ASM_gadgets_Branch_up_to_5_shares](#asm_gadgets_branch_up_to_5_shares)
        - [Gadgets](#gadgets)
        - [Implementation info](#implementation-info)
        - [Example, using on Scale board, RUN_gadgets.py](#example-using-on-scale-board-run_gadgetspy)
    - [C_implementations_Gadgets](#c_implementations_gadgets)
        - [Example](#example)
- [python_experiments](#python_experiments)
    - [Python packages](#python-packages)
        - [Python version for the other](#python-version-for-the-other)
    - [Gadget I/O data structure in *.trs* file](#gadget-io-data-structure-in-trs-file)
    - [General scripts](#general-scripts)
        - [TRS_common_func.py](#trs_common_funcpy)
        - [TRS_Reader.py and TRS_TraceSet.py](#trs_readerpy-and-trs_tracesetpy)
    - [RUN_gadgets.py](#run_gadgetspy)
    - [extracting_2cy_dataset.py](#extracting_2cy_datasetpy)
    - [Acquisition of power consumption traces](#acquisition-of-power-consumption-traces)
        - [Signal capture window using trigger](#signal-capture-window-using-trigger)
        - [type_of_execution_gadget.py](#type_of_execution_gadgetpy)
        - [acq_gadget.py](#acq_gadgetpy)
        - [plot_traces_trs_gadget.py](#plot_traces_trs_gadgetpy)
    - [SNR](#snr)
        - [intermediate_values_n.py](#intermediate_values_npy)
        - [snr.py](#snrpy)
        - [multiprocessing_snr.py](#multiprocessing_snrpy)
        - [random_snr.py](#random_snrpy)
    - [Ttest](#ttest)
        - [t_test_SNR.py](#t_test_snrpy)
            - [Uni-variate T-test](#uni-variate-t-test)
                - [First-order](#first-order)
                - [Second-order](#second-order)
            - [Multi-variate T-test](#multi-variate-t-test)
        - [multiprocessing_uni_vaiate_t_test.py](#multiprocessing_uni_vaiate_t_testpy)
- [References](#references)
- [Acknowledgement](#acknowledgement)

<!-- /TOC -->


# All_implementations_C_ASM_multiplication_Gadgets

The assembly implementations are for ARM cortex M3.

## ASM_GFMUL

c = a * b, where a, b and c are one share.

The function **gfmul** is used in all gadget for computing a[i] * b[i].


**gf_mul.S** is the implementation of GF(2^8) (gfmul(a,b,c), c = a * b) for ARM Cortex-M0/3 in GNU assembly, with THUMB-16 instructions.
The multiplication is based on Log_Ex with table.

**gf_mul.S** can be compiled for any ARM Cortex-M0/3.


**gf_mul.h** contains the table of Log_Exp.


The script is tested via calling gfmul(a,b,c) function in **gf_mul.c**.

### test_GFMUL.py
**test_GFMUL.py** is for generating random inputs, sending the inputs from PC to the
Microcontroller and receiving the output from Microcontroller via UART port.

In case using  [SCALE board](https://github.com/danpage/scale):

From **scale** directory run: 
```./run.sh GFMUL gf_mul```

Then for test, run **test_GFMUL.py**

## ASM_gadgets_2_3_shares_Leakage_Detection
Two and three shares
Multiplication: a.b = c

### Gadgets 

1) ISW
2) BBPP
3) DOM_INDEP
4) HPC1_OPT 
5) PINI1
6) PINI2

### all_gadgets_leakage_detection.pdf
Leakage detection is conducted for the two and three shares implementations, which are also documented in **all_gadgets_leakage_detection.pdf**.

### Implementation info
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

### Example, using on Scale Board, RUN_gadgets.py
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




## ASM_gadgets_Branch_up_to_5_shares

 Up to 5 shares
 
 $a_i.b_j$ is calculated by **gfmul** function (```bl gfmul``` in **.S** file).
 
 Prefix **_b, _B** means using branch instruction (```bl gfmul```). 
 
 Leakage detection is not conducted.

Multiplication: a.b = c 

### Gadgets

1) **ISW**: Up to 5 shares

2) **HPC1_OPT**: Up to 4 shares

3) **DOM_DEP**: 3 to 5 shares

4) **DOM_INDEP**: Up to 5 shares

5) **BBPP_OPT**: 3 to 5 shares


### Implementation info
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

### Example, using on Scale board, RUN_gadgets.py
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



## C_implementations_Gadgets
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

### Example
From **ISW** directory:

```
gcc main.c ISW.c
```
**a.out** will be generated, 
For running:
```
./a.out
```

# python_experiments

## Python packages
Python dependencies are in requirements.txt:

``` pip install -r requirements.txt```

Use: ``` pip install pySerial```

The most important packages are: 
1) ```trsfile==0.3.2```
2) ```numpy==1.19.5```


### Python version for the other
Please use ```python 3.12.10``` and ```numpy==1.19.5```



## Gadget I/O data structure in *.trs* file

The standard format [**.trs**](https://trsfile.readthedocs.io/en/latest/) file is used for storing data (inputs, outputs, traces values).

All I/O data of the gadgets are represented in bytes and stored in a [**.trs**](https://trsfile.readthedocs.io/en/latest/) file. Within the [**.trs**](https://trsfile.readthedocs.io/en/latest/)  file, the variable $cryptolen$ denotes the total length of the cryptographic data. This is divided into two parts: in_len_trs and out_len_trs, where the total length (all_len_trs) is calculated as 'in_len_trs + out_len_gadget', as follows:

Each gadget includes:

1) $a$, shares of a (mask_a)
2) $b$, shares of b (mask_b)
3) $rnd$ (rnd_gadget)
4) $c$, shares of c (out_len_gadget)


It is important to note that the I/O stored in *.trs* for T-test/split-T-test includes an extra byte compared to those for SNR/Template attacks/F-test. This extra byte referred to as *data_set* byte $d$ and is used to distinguish fixed and random traces for T-test/split-T-test.

```
in_len_trs = data_set (= rnd_or_fix) + a + b + input_of_gadget (= mask_a + mask_b + rnd_gadget)

in_len_trs = d + 1 + 1 + in_len_gadget
```
  
  Where $d$ is as a distinguisher.

```
out_len_trs = out_len_gadget = mask_order + 1 = number of shares
```

Regarding the value of $d$:

  $d = 0$: Indicates the trace set is for SNR/ Template attacks/F-test.

  $d = 1$: First it shows that the trace set is for T-test/split-T-test with the vaue of byte $d$ (0x00/ 0x01), distinguishing whether the input/trace is fixed or random.

Consequently, in all scripts, it is importand to accurately set the value for the variable $d$.

## General scripts

### TRS_common_func.py
This script contains common Functions and Classes 
that are used across multiple scripts in the project.

### TRS_Reader.py and TRS_TraceSet.py
These scripts are especially writen (by Si) for handling [**.trs**](https://trsfile.readthedocs.io/en/latest/) files
a standard format for storing dataset (inputs, outputs, traces values).

## RUN_gadgets.py
It is used for running and testing Gadgets on [SCALE board](https://github.com/danpage/scale) by sending the gadget's inputs and receiving outputs through UART to and from the board


## extracting_2cy_dataset.py
This code extracts data_set $d$ (distinguishing between fixed and random traces) as well as specific two cycles from all traces within a [**.trs**](https://trsfile.readthedocs.io/en/latest/) file, primarily for the Multivariate-T-test in [t\_test.py](#t_testpy). data_set $d$ (refer [Gadget I/O data structure in *.trs* file](#gadget-io-data-structure-in-trs-file)) and two cycles from all traces are stored in two separate **.npy** files.


## Acquisition of power consumption traces

Capturing the power-consumption of ARM Cortex-M3 microprocessor on [SCALE board](https://github.com/danpage/scale) while it is executing 
multiplication gadgets written in Assembly Thumb-16 instructions.

The power-consumption traces are recorded by [Pico oscilloscope 5000a](https://www.picotech.com/products/oscilloscope), in the Rapid-mode.

These scripts are related to the implementations existed in:
1) All_implementations_C_ASS_multiplication_Gadgets/ASS_gadgets_2_3_shares_Leakage_Detection

2) All_implementations_C_ASS_multiplication_Gadgets/ASS_gadgets_H_HV_16

### Signal capture window using trigger
The power-consumption of the instructions before raising-edge of 
the trigger are recorded. Since trigger instructions (correspond [SCALE board](https://github.com/danpage/scale)) is spotted (in these implementations) in the .S file, as the follow: 

```
 @ Trigger
#########################################################################
 Seperating instructions related to main function and trigger, as there are pipeline stages 
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
Furthermore, depending on the trigger setting (instructions), **acq_gadget.py** script allows
specifying the start and end points of the recording window. 


### type_of_execution_gadget.py
 This script contains functions related to generating gadget inputs
 (a, b, shares of a, shares of b, and randomness). These functions
 are used in acq_gadget.py to generate and send inputs to the [SCALE board](https://github.com/danpage/scale) and receive the output via the serial port in the Rapid-mode.

 Generating:

 1) Random inputs used in computing SNR and F-test.
 2) Fixed inputs used in template attack.
 3) Collapsed inputs used in F-test.
 4) Random/fixed inputs used in first-order T-test.
 5) Random/fixed inputs, 2-shares out of 3-shares used in split T-test.
   

### acq_gadget.py
This script measures the power-consumption, and stores all data 
(inputs, outputs, traces values) in [**.trs**](https://trsfile.readthedocs.io/en/latest/) file.
The traces can be generated to be used in SNR, T-test, Template attacks, split-T-test, F-test.


In this code, one can set the *gadget_name*, number of shares (2, 3), 
number of cycles to be captured. Furthermore, the generation of gadget inputs
see section [type_of_execution_gadget.py](#type_of_execution_gadget.py). 


### plot_traces_trs_gadget.py
This code is used to plot the power-consumption traces stored in the [**.trs**](https://trsfile.readthedocs.io/en/latest/) .


## SNR
Computing the SNR based on the *gadget_name* and extracting Point Of Interest (POI), by setting a threshold.

### intermediate_values_n.py
This script computes the intermediate values for SNR and is utilized in **TRS_common_func.py**, which is subsequently called in **snr.py**.


### snr.py
This code claculates the SNR based on the *gadget_name* and the number of shares (2/3), since they have different intermediate values.
It is possible to use different set of traces (T-test, F-test, ...), but it is important to set data_set $d$ correctly, as it is explained in section [Gadget I/O data structure in *.trs* file](#gadget-io-data-structure-in-trs-file).

The intermediate values can be chosen via modifying Function `Cal_im_value` (called in **snr.py**) in **intermediate_values_n.py**.


### multiprocessing_snr.py
This is also like **snr.py**, but it uses multiprocessing with the python package `parmap`.

### random_snr.py
It calculates SNR for traces that are randomly selected from a *.trs* file.


## Ttest
For more information, please see [1].

### t_test_SNR.py
The script is used for conducting uni/multi-variate T-test using `scipy.stats.ttest_ind` package.

Input file format of data_info and traces can be [**.trs**](https://trsfile.readthedocs.io/en/latest/)  or **.npy** files.

SNR is used in the context of multivariate T-tests in order to reduce the complexity of the computations.


#### Uni-variate T-test
Using **one** sample (time) point

##### First-order

Variable $order = 1$

This setup can be used to performing statistical t-tests on traces of:

1) *Two shares gadget*
2) *split-t-test* 
3) *Three shares gadget* (in first-order evaluation)

##### Second-order
Variable $order = 2$

Using *mean-free squared* one sample point

This setting can be used to performing statistical t-test on traces of *Three shares gadget* (in second-order uni-variate assessment) and also even *split-t-test*. 


#### Multi-variate T-test
Using **two** sample (time) points:

Central-product combinations of two sample points

It can perform second-order multi-variate t-test on:

1) All cycles (samples) in the trace set
2) Two cycles: In this case, POI can be extracted using the class in [snr.py](#snrpy). Or just firstly run [snr.py](#snrpy), obtain the POI and then put the list of POI in the script [t_test_SNR.py](#t_test_snrpy).


### multiprocessing_uni_vaiate_t_test.py
This script is used for conducting first/second-order uni-variate T-test using the `scipy.stats.ttest_ind` module utilizing the `parmap` package for multiprocessing, especially when dealing with a large number of traces. 

Setting variable $order = 1$ or $2$: first/second-order uni-variate T-test


# References
[1]: Leakage Assessment Methodology - A Clear Roadmap for Side-Channel Evaluations.

[2]: A Novel Framework for Explainable Leakage Assessment


# Acknowledgement
This research was funded by the European Research Council (ERC) under the European Union’s
Horizon 2020 research and innovation programme (grant agreement No 72504, SEAL).

![EU Logo](LOGO_ERC-FLAG_EU.jpg "ERC")
