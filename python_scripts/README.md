# python_experiments
This contains all python scripts used in Nima's project.

---

## Table of Contents
<!-- TOC -->

- [python\_experiments](#python_experiments)
  - [Table of Contents](#table-of-contents)
- [Python packages](#python-packages)
  - [Python version for the other](#python-version-for-the-other)
- [Gadget I/O data structure in *.trs* file](#gadget-io-data-structure-in-trs-file)
- [General scripts](#general-scripts)
  - [TRS\_common\_func.py](#trs_common_funcpy)
  - [TRS\_Reader.py and TRS\_TraceSet.py](#trs_readerpy-and-trs_tracesetpy)
- [RUN\_gadgets.py](#run_gadgetspy)
- [extracting\_2cy\_dataset.py](#extracting_2cy_datasetpy)
- [Acquisition of power consumption traces](#acquisition-of-power-consumption-traces)
  - [Signal capture window using trigger](#signal-capture-window-using-trigger)
  - [type\_of\_execution\_gadget.py](#type_of_execution_gadgetpy)
  - [acq\_gadget.py](#acq_gadgetpy)
  - [plot\_traces\_trs\_gadget.py](#plot_traces_trs_gadgetpy)
- [SNR](#snr)
  - [intermediate\_values\_n.py](#intermediate_values_npy)
  - [snr.py](#snrpy)
  - [multiprocessing\_snr.py](#multiprocessing_snrpy)
  - [random\_snr.py](#random_snrpy)
- [Ttest](#ttest)
  - [t\_test\_SNR.py](#t_test_snrpy)
    - [Uni-variate T-test](#uni-variate-t-test)
      - [First-order](#first-order)
      - [Second-order](#second-order)
    - [Multi-variate T-test](#multi-variate-t-test)
  - [multiprocessing\_uni\_vaiate\_t\_test.py](#multiprocessing_uni_vaiate_t_testpy)

- [References](#references)

<!-- /TOC -->
# Python packages
Python dependencies are in requirements.txt:

``` pip install -r requirements.txt```

Use: ``` pip install pySerial```

The most important packages are: 
1) ```trsfile==0.3.2```
2) ```numpy==1.19.5```


## Python version for the other
Please use ```python 3.12.10``` and ```numpy==1.19.5```



# Gadget I/O data structure in *.trs* file

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

# General scripts

## TRS_common_func.py
This script contains common Functions and Classes 
that are used across multiple scripts in the project.

## TRS_Reader.py and TRS_TraceSet.py
These scripts are especially writen (by Si) for handling [**.trs**](https://trsfile.readthedocs.io/en/latest/) files
a standard format for storing dataset (inputs, outputs, traces values).

# RUN_gadgets.py
It is used for running and testing Gadgets on [SCALE board](https://github.com/danpage/scale) by sending the gadget's inputs and receiving outputs through UART to and from the board


# extracting_2cy_dataset.py
This code extracts data_set $d$ (distinguishing between fixed and random traces) as well as specific two cycles from all traces within a [**.trs**](https://trsfile.readthedocs.io/en/latest/) file, primarily for the Multivariate-T-test in [t\_test.py](#t_testpy). data_set $d$ (refer [Gadget I/O data structure in *.trs* file](#gadget-io-data-structure-in-trs-file)) and two cycles from all traces are stored in two separate **.npy** files.


# Acquisition of power consumption traces

Capturing the power-consumption of ARM Cortex-M3 microprocessor on [SCALE board](https://github.com/danpage/scale) while it is executing 
multiplication gadgets written in Assembly Thumb-16 instructions.

The power-consumption traces are recorded by [Pico oscilloscope 5000a](https://www.picotech.com/products/oscilloscope), in the Rapid-mode.

These scripts are related to the implementations existed in:
1) All_implementations_C_ASS_multiplication_Gadgets/ASS_gadgets_2_3_shares_Leakage_Detection

2) All_implementations_C_ASS_multiplication_Gadgets/ASS_gadgets_H_HV_16

## Signal capture window using trigger
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


## type_of_execution_gadget.py
 This script contains functions related to generating gadget inputs
 (a, b, shares of a, shares of b, and randomness). These functions
 are used in acq_gadget.py to generate and send inputs to the [SCALE board](https://github.com/danpage/scale) and receive the output via the serial port in the Rapid-mode.

 Generating:

 1) Random inputs used in computing SNR and F-test.
 2) Fixed inputs used in template attack.
 3) Collapsed inputs used in F-test.
 4) Random/fixed inputs used in first-order T-test.
 5) Random/fixed inputs, 2-shares out of 3-shares used in split T-test.
   

## acq_gadget.py
This script measures the power-consumption, and stores all data 
(inputs, outputs, traces values) in [**.trs**](https://trsfile.readthedocs.io/en/latest/) file.
The traces can be generated to be used in SNR, T-test, Template attacks, split-T-test, F-test.


In this code, one can set the *gadget_name*, number of shares (2, 3), 
number of cycles to be captured. Furthermore, the generation of gadget inputs
see section [type_of_execution_gadget.py](#type_of_execution_gadget.py). 


## plot_traces_trs_gadget.py
This code is used to plot the power-consumption traces stored in the [**.trs**](https://trsfile.readthedocs.io/en/latest/) .


# SNR
Computing the SNR based on the *gadget_name* and extracting Point Of Interest (POI), by setting a threshold.

## intermediate_values_n.py
This script computes the intermediate values for SNR and is utilized in **TRS_common_func.py**, which is subsequently called in **snr.py**.


## snr.py
This code claculates the SNR based on the *gadget_name* and the number of shares (2/3), since they have different intermediate values.
It is possible to use different set of traces (T-test, F-test, ...), but it is important to set data_set $d$ correctly, as it is explained in section [Gadget I/O data structure in *.trs* file](#gadget-io-data-structure-in-trs-file).

The intermediate values can be chosen via modifying Function `Cal_im_value` (called in **snr.py**) in **intermediate_values_n.py**.


## multiprocessing_snr.py
This is also like **snr.py**, but it uses multiprocessing with the python package `parmap`.

## random_snr.py
It calculates SNR for traces that are randomly selected from a *.trs* file.


# Ttest
For more information, please see [1].

## t_test_SNR.py
The script is used for conducting uni/multi-variate T-test using `scipy.stats.ttest_ind` package.

Input file format of data_info and traces can be [**.trs**](https://trsfile.readthedocs.io/en/latest/)  or **.npy** files.

SNR is used in the context of multivariate T-tests in order to reduce the complexity of the computations.


### Uni-variate T-test
Using **one** sample (time) point

#### First-order

Variable $order = 1$

This setup can be used to performing statistical t-tests on traces of:

1) *Two shares gadget*
2) *split-t-test* 
3) *Three shares gadget* (in first-order evaluation)

#### Second-order
Variable $order = 2$

Using *mean-free squared* one sample point

This setting can be used to performing statistical t-test on traces of *Three shares gadget* (in second-order uni-variate assessment) and also even *split-t-test*. 


### Multi-variate T-test
Using **two** sample (time) points:

Central-product combinations of two sample points

It can perform second-order multi-variate t-test on:

1) All cycles (samples) in the trace set
2) Two cycles: In this case, POI can be extracted using the class in [snr.py](#snrpy). Or just firstly run [snr.py](#snrpy), obtain the POI and then put the list of POI in the script [t_test_SNR.py](#t_test_snrpy).


## multiprocessing_uni_vaiate_t_test.py
This script is used for conducting first/second-order uni-variate T-test using the `scipy.stats.ttest_ind` module utilizing the `parmap` package for multiprocessing, especially when dealing with a large number of traces. 

Setting variable $order = 1$ or $2$: first/second-order uni-variate T-test


# References
[1]: Leakage Assessment Methodology - A Clear Roadmap for Side-Channel Evaluations.

[2]: A Novel Framework for Explainable Leakage Assessment
