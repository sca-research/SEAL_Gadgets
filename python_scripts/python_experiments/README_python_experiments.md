# python_experiments
This contains all python scripts used in Nima's project.

---

## Table of Contents
<!-- TOC -->

- [python\_experiments](#python_experiments)
  - [Table of Contents](#table-of-contents)
- [Python packages](#python-packages)
  - [Python version for Ftest](#python-version-for-ftest)
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
- [Nested Ftest](#nested-ftest)
  - [general\_smallest\_model.py](#general_smallest_modelpy)
  - [Ftest\_CV.py](#ftest_cvpy)
  - [variable\_analysis.py](#variable_analysispy)
  - [CV\_F\_N.py](#cv_f_npy)
  - [poweranalysis.py](#poweranalysispy)
  - [Folder nested\_ftest](#folder-nested_ftest)
    - [Result\_running\_Ftest\_CV\_partial\_results.txt](#result_running_ftest_cv_partial_resultstxt)
    - [Result\_running\_general\_smallest\_model.txt](#result_running_general_smallest_modeltxt)
    - [Images](#images)
    - [nested\_ftest\_traces\_isw\_3\_V2.zip](#nested_ftest_traces_isw_3_v2zip)
      - [reduced\_coll\_isw3\_V2\_20K.trs](#reduced_coll_isw3_v2_20ktrs)
      - [reduced\_rand\_isw3\_V2\_20K.trs](#reduced_rand_isw3_v2_20ktrs)
      - [isw3\_V2\_20K.trs](#isw3_v2_20ktrs)
      - [rand\_isw3\_V2\_20K.trs](#rand_isw3_v2_20ktrs)
      - [reduced\_rnd\_isw\_3\_V2\_1000K.trs](#reduced_rnd_isw_3_v2_1000ktrs)
      - [ftest\_coll\_isw3\_V2\_20K\_26\_30\_cy.trs](#ftest_coll_isw3_v2_20k_26_30_cytrs)
- [Template attack](#template-attack)
  - [rank\_key\_attack.py](#rank_key_attackpy)
  - [Why applying TA in our analisys](#why-applying-ta-in-our-analisys)
  - [Overall veiw of TA on multiplication gadgets](#overall-veiw-of-ta-on-multiplication-gadgets)
  - [Profiling in our setup](#profiling-in-our-setup)
  - [Attack in our setup](#attack-in-our-setup)
  - [Folder template\_attack](#folder-template_attack)
    - [Templates\_cy\_26\_30](#templates_cy_26_30)
    - [Result figures](#result-figures)
    - [Folder ta\_traces\_cy\_26\_30\_ISW\_3\_V2](#folder-ta_traces_cy_26_30_isw_3_v2)
      - [AttackTrace\_isw3\_V2\_100K\_26\_30\_cy.zip](#attacktrace_isw3_v2_100k_26_30_cyzip)
      - [tpl\_isw3\_V2\_6000K\_26\_30\_cy.zip](#tpl_isw3_v2_6000k_26_30_cyzip)
    - [Conclusion on TA](#conclusion-on-ta)
- [References](#references)

<!-- /TOC -->
# Python packages
Python dependencies are in requirements.txt:

``` pip install -r requirements.txt```

The most important packages are: 
1) ```trsfile==0.3.2```
2) ```numpy==1.19.5```

## Python version for Ftest
Please use ```python 3.8.10``` 

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


# Nested Ftest
For more information, please see [2].

Also, we did more experiences before that the results are documented in **Ftest_CrossValidation_TemplateAttack.pdf**.

## general_smallest_model.py
Aim: Using *Nested F-test* to achieve the smallest model for a sample (time) point in all traces that can explain the values of the traces for the sample point.

Nested F-test *using degree analysis*.

collapsed_set traces (using [acq\_gadget.py](#acq_gadgetpy)): According to [2] paper, the collapsed technique, all inputs of gadgets are randomly drawn from the small space $\{0x00, 0xff\}$. Then in the computations just consider the Least Significant Bit (LSB) $\{0, 1\}$. 


We explain with **isw_3**, but the same strategy can be applied for the other gadgets.

**isw_3**:  ISW multiplication for 3 shares, it contains 9 inputs as the follow:

$a_0, a_1, a_2, b_0, b_1, b_2, r_0, r_1, r_2$

where all are from $\{0x00, 0xff\}$, but in the computations we mapped them to $\{0, 1\}$.

Note: These steps are done for each sample point separately. However, there is a possibility to reduce the number of investigated sample points, like finding the bad points, please see Function `Finding_BAD_POINT` in [TRS\_common\_func.py](#trs_common_funcpy). And just considering those points.


1) **Full model**: First the full model is built using all 9 variables as follows:

    $\beta_0. + \beta_1.a_0 + \beta_2.a_1 + \beta_3.a_2 + \beta_4.b_0 + \beta_5.b_1 + \beta_6.b_2 + \beta_7.r_0 + \beta_8.r_1 + \beta_9.r_2 + \ldots + \beta_{10}.a_0.a_1 + \beta_{11}.a_0.a_2 + \beta_{12}.a_0.b_0 +\beta_{511}.a_0.a_1.a_2.b_0.b_1.b_2.r_0.r_1.r_2$

    Number of terms = 512 = $2 ^ 9$

    All coefficients $\beta_0 + \ldots + \beta_{511}$ have to be computed.

2) **Degree analysis-Drop Terms**:

    a) To speed up the dropping term, instead of dropping term by term, firstly, several terms at once are dropped, till the max-degree is found.
    
    b) Second, **Drop terms**, till achieving the smallest model by redefining the full model iteratively. Starts with the full model and iteratively removes terms one by one. When one finds a term that does not have
    a significant effect, the term is removed from the full model and redefine the full model.
    
3) The last model from step 2) is the smallest model.
    
From the smallest model, check the bad terms like:

  $a_0.a_1.a_2$, where $a = a0 \oplus a1 \oplus a2$

The result of running this script is stored in Result_runing_general_smallest_model.txt. Note, Each sample point can have a uniqe smallest model. 


## Ftest_CV.py
This script performs the Nested F-test *without using degree analysis*. It sequentially drops each term, and if a term cannot be dropped, it then loads the **non-collapsed traces** and computes the CV-R2 (cross-validation R-squared) and ES (Effect Size).

If r2_r > r2_f (Reduced model: $r$, Full model: $f$), it will remove the investigated term from the full model in col-set.
The result of running this script is stored in Result_running_Ftest_CV_partial_results


## variable_analysis.py
 To check which points/cycles depends on which variables.

It firstly builds the full model by using 9 variables ($a_0, a_1, a_2, b_0, b_1, b_2, r_0, r_1, r_2$), ($2^9$) 512 terms.
Then it removes a variable from the 9 variables, and builds a reduced model by using 8 variables, ($2^8$) 256 terms.
EX: Removing $a_2$ from all terms in the full model, so that the reduced model will have 256 terms.
and then compute the Nested F-test. If p-val>th means the point/cycle depends on the removed variable.


## CV_F_N.py
 Computes 
 1) CV for naive model and the full model (512 terms), 
 2) Correlations between 512 terms in the full model 
               and plots them and saves them in the folder: Images/ftest_and_cross_v_r2 



## poweranalysis.py
It is for calculating Nested F-test parameters



## Folder nested_ftest

This folder contains results (.txt and images) from performing **Nested F-test** on traces in traces.zip which are related to ISW-3, specifically cycles 28 and 29.

### Result_running_Ftest_CV_partial_results.txt
### Result_running_general_smallest_model.txt
### Images 


### nested_ftest_traces_isw_3_V2.zip
These traces are used in **Nested F-test**:
Theyare coressponding to ISW with 3 shares implementation.

Each cycles in the traces contains 125 sample/time points

20K: Number of traces: 20K

1M: Number of traces: 1M

#### reduced_coll_isw3_V2_20K.trs 
It concerns collapsed-inputs and contains just two cycles of traces, which are cycles 28 and 29.

#### reduced_rand_isw3_V2_20K.trs
 
random-inputs, cycles 28 and 29 within traces, for computing CV


#### isw3_V2_20K.trs
 
collapsed-inputs, 250 cycles within traces

#### rand_isw3_V2_20K.trs
 
random-inputs, 250 cycles within traces, computing CV

#### reduced_rnd_isw_3_V2_1000K.trs 
random-inputs, cycles 28 and 29 within traces, for computing CV.

#### ftest_coll_isw3_V2_20K_26_30_cy.trs
collapsed-inputs, cycles 28 to 30 within traces

# Template attack

## rank_key_attack.py 

## Why applying TA in our analisys

In our **Nested F-test** analysis on *ISW_3_V2*, we observed that at some sample points (in most cycles) within the traces, *the smallest model* obtained consists of terms as follows:

```
S_M: β0 + β1.a0 + β2.a1 + β3.a2 + ... 
```

Interestingly, this type of the model occurs even for sample points where $a_2$ is not initially
loaded (around cycle 28, where 250 cycles are captured from raising-adge of trigger at the end of .S file. Each cycle contains 125 samples), with $a_2$ being loaded after several instructions. In order to find that is this model exploitable or not in terms of having a seccusful attack, the *Template attack* was conducted. 

In all experiments, we consider cycles 26 t0 30 within traces of ISW_3_V2.

## Overall veiw of TA on multiplication gadgets
For applying a template attack in (key-recovery) on masking schemes, it is assumed that the device performs a specific operation on the plaintex $a'$ using the secret key $k$. With the general format $y = f(a', k)$ would be $y = a' \oplus k$, where $y$ is any secret variable ($a, b, c$ in multiplication gadgets), and with the key $k$ which is not physically present in the device, but theoretically set to zero. In this scenario, the goal is to achieve **the rank $k = 0$ in the top positions**, meaning a successful attack.
After successfully recovering the key $k=0$ (top ranks), the secret value $a$ can be recovered as well.
To recover the variable $a$, where $a = a' \oplus k$, where $a = \oplus_{i=0}^{d} a_i$, since the rank $k=0$ is one (indicating the correct key is zero):

$y: a = a' \oplus k = a' \oplus 0 = a' \rightarrow a = a'$
  
Sine $a'$ is the known plainthext, so $a$ is recovered. 



## Profiling in our setup 

Regarding $a = a' \oplus k$, building templates for $(a', k)$, 256*256 templates:

To speed up the attack: since $k = 0$, it would be: $a = a' \oplus k = a' \oplus 0 = a'$, and instead of having 256*256 templates (implementations are byte-oriented, 8 bits, 256 possibilities), we have just 256 templates based on values of $a'$. Thereby, the templates are made based on $a'$. 

## Attack in our setup 

Attack traces are corresponding to unknown-fix $k=0$ and random $a'$.

One compares the attacked-traces with the templates, if it matched one of templates, means that the $k=0$ is recovered. $a$.


## Folder template_attack
This folder holds the results and traces of the TA in our experiments.

### Templates_cy_26_30
There are 256 templates (based on the value of $a'$ as input) extracted from 6M traces from ISW_3_V2. 
The templates (means, variences) are stored in **.npy** files.  

tpl_isw3_V2_6000K_26_30_cy_mean_V_t.npy

tpl_isw3_V2_6000K_26_30_cy_mean_V_t2.npy

tpl_isw3_V2_6000K_26_30_cy_var_V_t.npy

tpl_isw3_V2_6000K_26_30_cy_var_V_t2.npy

In the name of **.npy** files:

1) "$\_t$" is the main traces.

2) "$\_t2$" is the squared-traces.

### Result figures
Also the images show the distribution of rank $k=0$ for 200 experiments with 10K as well as 100K traces.

### Folder ta_traces_cy_26_30_ISW_3_V2

#### AttackTrace_isw3_V2_100K_26_30_cy.zip
Traces for the attack
#### tpl_isw3_V2_6000K_26_30_cy.zip
Traces for the bulding the templates

### Conclusion on TA
The conclusion of our experiments is the smallest model `S_M: β0 + β1.a0 + β2.a1 + β3.a2 + ... `, even by containg all three shares of $a$ at the same time can not lead to a seccusfull TA with in 100K attack-traces.


# References
[1]: Leakage Assessment Methodology - A Clear Roadmap for Side-Channel Evaluations.

[2]: A Novel Framework for Explainable Leakage Assessment
