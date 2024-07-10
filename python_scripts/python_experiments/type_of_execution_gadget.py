# This script contains functions related to generating gadget inputs
# (a, b, shares of a, shares of b, and randomness). These functions
# are used in acq_gadget.py to generate and send inputs to the Scale
# board and receive the output via the serial port in Rapid-mode.
# Generating:
# 1) Random inputs (used in computing SNR, and F-test).
# 2) Fixed inputs (used in template attack).
# 3) Collapsed inputs (used in F-test).
# 4) Random/fixed inputs (used in first-order T-test).
# 5) Random/fixed inputs, 2-shares out of 3-shares (used in split T-test).

from TRS_common_func import *


def Gen_shares_1byte_random_fix(n_sh, in_x=None):
    """if in_x is None, it generates random value for int_x and then masked it
    if in_x=val, it masked this value
    """
    int_x = secrets.randbits(8) if in_x is None else in_x  # type: int
    # Converting input_a and input_b to "byte" type, in order to store in trs file
    byte_x = int_x.to_bytes(1, sys.byteorder)
    # Masking inputs
    mask_x = masking(int_x, n_sh - 1)  # type: bytearray
    return [int_x, byte_x, mask_x]


def Gen_shares_1byte_0_255(n_sh):
    """ Used in collapsed"""
    q = [0, 255]
    r = [random.randrange(2) for i in range(n_sh)]
    mask_x = []
    int_x = 0
    for i in range(n_sh):
        mask_x.append(q[r[i]])
        int_x ^= q[r[i]]
    byte_x = int_x.to_bytes(1, sys.byteorder)
    return [int_x, byte_x, bytearray(mask_x)]


def EXE_Ftest(gadget_name, n_sh, step, n_execution, input_len_gadget, n_rnd_gadget, output_len, ser, collapsed=False):
    """
    This function generates and sends random inputs to the Scale board, and receives the output via
    serial port """
    """ It is used in rapid measurement"""
    # ser is the serial port:
    # port = '/dev/ttyUSB0'  # Serial port
    # Open serial port
    ##################################################
    # ser = serial.Serial(port)
    # Executing the code n_execution times
    ##################################################
    in_data, out_data = [], []
    for j in range(n_execution):
        # Generate inputs of the gadget
        ##################################################
        G_F = Gen_shares_1byte_0_255 if collapsed else Gen_shares_1byte_random_fix
        rnd_gadget = (G_F(n_rnd_gadget))[2]
        [input_a, in_a, mask_a] = G_F(n_sh)
        [input_b, in_b, mask_b] = G_F(n_sh)

        # The input data
        inputs_of_gadget = mask_a + mask_b + rnd_gadget
        # Check
        if len(inputs_of_gadget) != input_len_gadget:  # length in bytes
            print("ERROR INPUT LENGTH")

        # Send inputs through serial port
        #################################################
        ser.write(inputs_of_gadget)
        # Receive outputs through serial port
        #################################################
        # Read outputs
        shares_c = bytearray(ser.read(output_len))
        # Write trace into trs file
        #################################################
        # The Data need to be saved in trs file
        in_data.append(bytearray(in_a + in_b + inputs_of_gadget))
        out_data.append(shares_c)
        # Checking the correctness of the gadget and printing on the screen
        #################################################
        out_c = 0
        for p in range(0, n_sh):
            out_c ^= shares_c[p]

        correctness_gadget(n_sh - 1, gadget_name, input_a, input_b, mask_a, mask_b, rnd_gadget, shares_c, step, j)
        # Printing the data on screen after "step" times executions
        if j % step == 0:
            print('\n- Input {}:  [{}]'.format(j, inputs_of_gadget.hex()))
            print('- a: {} ---> shares_a: [{}]'.format(in_a.hex(), mask_a.hex()))
            print('- b: {} ---> shares_b: [{}]'.format(in_b.hex(), mask_b.hex()))
            print('- r: [{}] '.format(rnd_gadget.hex()))
            print('- c: {}, shares_c:[{}]'.format(hex(out_c), shares_c.hex()))
            print('___________________________________________________________________')
    return [in_data, out_data]


def EXE_fix_rnd_data(gadget_name, mask_ord, step, n_execution, input_len_gadget, n_rnd_gadget, output_len,
                     ser, fix_value=0):
    """ This function generates and sends (fixed and random) inputs to the Scale board, and receives the output via
    serial port """
    """ It is used in rapid measurement"""
    # ser is the serial port:
    # port = '/dev/ttyUSB0'  # Serial port
    # Open serial port
    ##################################################
    # ser = serial.Serial(port)

    # Executing the code n_execution times
    ##################################################
    n_rnd_data_set = 0
    n_fix_data_set = 0
    in_data = []
    out_data = []
    for j in range(n_execution):
        # Generate inputs of the gadget
        ##################################################
        # Choosing data_set randomly: rnd_data_set if random bit == 0, fix_data_set if random bit == 1,
        fix_or_rnd_data = random.getrandbits(1)  # Pick a random bit

        # input_a and input_b are sampled in "int" type for
        # being convinced to use in masking function and gf_mult function

        # if the random bit is == 0, pick rnd_data_set
        if fix_or_rnd_data == 0:
            data_set = (0).to_bytes(1, sys.byteorder)  # 0 means data is belonging to rnd_data_set
            input_a = secrets.randbits(8)
            input_b = secrets.randbits(8)  # type: int
            n_rnd_data_set += 1

        # if the random bit is == 1, pick fix_data_set
        else:
            data_set = (1).to_bytes(1, sys.byteorder)  # 1 means data is belonging to fix_data_set
            input_a = fix_value
            # input_a = secrets.randbits(8)
            input_b = fix_value
            n_fix_data_set += 1

        # Converting input_a and input_b to "byte" type, in order to store in trs file
        in_a = input_a.to_bytes(1, sys.byteorder)
        in_b = input_b.to_bytes(1, sys.byteorder)

        # Masking inputs
        mask_a = masking(input_a, mask_ord)  # type: bytearray
        mask_b = masking(input_b, mask_ord)  # type: bytearray
        # Randomness needed in gadget
        rnd_gadget = bytearray([secrets.randbits(8) for j in range(0, n_rnd_gadget)])

        # The input data
        inputs_of_gadget = mask_a + mask_b + rnd_gadget
        # Check
        if len(inputs_of_gadget) != input_len_gadget:  # length in bytes
            print("ERROR INPUT LENGTH")

        # Send inputs through serial port
        #################################################
        ser.write(inputs_of_gadget)

        # Receive outputs through serial port
        #################################################
        # Read outputs
        shares_c = bytearray(ser.read(output_len))

        # Write trace into trs file
        #################################################
        # The Data need to be saved in trs file
        in_data.append(bytearray(data_set + in_a + in_b + inputs_of_gadget))
        out_data.append(shares_c)

        # Checking the correctness of the gadget and printing on the screen
        #################################################

        out_c = 0
        for p in range(0, mask_ord + 1):
            out_c ^= shares_c[p]
        correctness_gadget(mask_ord, gadget_name, input_a, input_b, mask_a, mask_b, rnd_gadget, shares_c, step, j)

        # Printing the data on screen after "step" times executions
        if j % step == 0:
            print('\n- Input {}:  [{}]'.format(j, inputs_of_gadget.hex()))
            print('- a: {} ---> shares_a: [{}]'.format(in_a.hex(), mask_a.hex()))
            print('- b: {} ---> shares_b: [{}]'.format(in_b.hex(), mask_b.hex()))
            print('- r: [{}] '.format(rnd_gadget.hex()))
            print('- c: {}, shares_c:[{}]'.format(hex(out_c), shares_c.hex()))
            print('___________________________________________________________________')

        # Check the number of whole traces in both data sets is not grater than Number_traces
        if n_rnd_data_set + n_fix_data_set == n_execution + 1:
            print("[+] The acquisition is finished")
            break
    return [in_data, out_data]


def EXE_i_k_fix_rnd_data(gadget_name, i, k, mask_ord, step, n_execution, input_len_gadget, n_rnd_gadget,
                         output_len,
                         ser, fix_value=0):
    """ This function generates and sends (fixed and random) inputs to the Scale board, and receives the output via
    serial port
     It is used for splitting-t-test for 3 shares"""
    """ It is used in rapid measurement"""
    # ser is the serial port:
    # port = '/dev/ttyUSB0'  # Serial port
    # Open serial port
    ##################################################
    # ser = serial.Serial(port)
    #
    # Executing the code n_execution times
    ##################################################
    n_rnd_data_set = 0
    n_fix_data_set = 0
    in_data = []
    out_data = []
    for j in range(n_execution):
        # Generate inputs of the gadget
        ##################################################
        # Choosing data_set randomly: rnd_data_set if random bit == 0, fix_data_set if random bit == 1,
        fix_or_rnd_data = random.getrandbits(1)  # Pick a random bit

        # input_a and input_b are sampled in "int" type for
        # being convinced to use in masking function and gf_mult function
        input_a = secrets.randbits(8)  # type: int
        input_b = secrets.randbits(8)  # type: int

        # if the random bit is == 0, pick rnd_data_set
        if fix_or_rnd_data == 0:
            data_set = (0).to_bytes(1, sys.byteorder)  # 0 means data belongs to rnd_data_set
            two_sh_a = secrets.randbits(8)
            two_sh_b = secrets.randbits(8)

            n_rnd_data_set += 1

        # if the random bit is == 1, pick fix_data_set
        else:
            data_set = (1).to_bytes(1, sys.byteorder)  # 1 means data belongs to fix_data_set
            two_sh_a = fix_value
            two_sh_b = fix_value
            # two_sh_b = secrets.randbits(8)

            n_fix_data_set += 1

        mask_a = masking(input_a, mask_ord)  # type: bytearray
        mask_2_a = masking(two_sh_a, 1)  # type: bytearray
        mask_a[i] = mask_2_a[0]
        mask_a[k] = mask_2_a[1]
        mask_a[3 - (i + k)] = input_a ^ two_sh_a

        mask_b = masking(input_b, mask_ord)  # type: bytearray
        mask_2_b = masking(two_sh_b, 1)  # type: bytearray
        mask_b[i] = mask_2_b[0]
        mask_b[k] = mask_2_b[1]
        mask_b[3 - (i + k)] = input_b ^ two_sh_b
        # Converting input_a and input_b to "byte" type, in order to store in trs file
        in_a = input_a.to_bytes(1, sys.byteorder)
        in_b = input_b.to_bytes(1, sys.byteorder)

        # Randomness needed in gadget
        rnd_gadget = bytearray([secrets.randbits(8) for j in range(0, n_rnd_gadget)])

        # The input data
        inputs_of_gadget = mask_a + mask_b + rnd_gadget

        # Check
        if len(inputs_of_gadget) != input_len_gadget:  # length in bytes
            print("ERROR INPUT LENGTH")

        # Send inputs through serial port
        #################################################
        ser.write(inputs_of_gadget)

        # Receive outputs through serial port
        #################################################
        # Read outputs
        shares_c = bytearray(ser.read(output_len))

        # Write trace into trs file
        #################################################
        # The Data need to be saved in trs file
        in_data.append(bytearray(data_set + in_a + in_b + inputs_of_gadget))
        out_data.append(shares_c)

        # Checking the correctness of the gadget and printing on the screen
        #################################################

        out_c = 0
        for p in range(0, mask_ord + 1):
            out_c ^= shares_c[p]
        # gadget_name = ["isw", "bbpp", "dom_indep", "hpc1_opt", "pini1", "pini2"]
        correctness_gadget(mask_ord, gadget_name, input_a, input_b, mask_a, mask_b, rnd_gadget, shares_c, step, j)

        # Checking the output of gadget with the output of gf_mult
        if gf_mult(input_a, input_b) != out_c:
            raise Exception("ERROR: gmul(in_b, in_a) != output of gadget")

        # Printing the data on screen after "step" times executions
        if j % step == 0:
            print('\n- Input {}:  [{}]'.format(j, inputs_of_gadget.hex()))
            print('- a: {} ---> shares_a: [{}]'.format(in_a.hex(), mask_a.hex()))
            print('- two_sh_a: {}'.format((two_sh_a.to_bytes(1, sys.byteorder)).hex()))
            print('- b: {} ---> shares_b: [{}]'.format(in_b.hex(), mask_b.hex()))
            print('- two_sh_b: {}'.format((two_sh_b.to_bytes(1, sys.byteorder)).hex()))
            print('- r: [{}] '.format(rnd_gadget.hex()))
            print('- c: {}, shares_c:[{}]'.format(hex(out_c), shares_c.hex()))

            print('___________________________________________________________________')

        # Check the number of whole traces in both data sets is not grater than Number_traces
        if n_rnd_data_set + n_fix_data_set == n_execution + 1:
            print("[+] The acquisition is finished")
            break
    return [in_data, out_data]


# check_ftest_ttest
def check_status_ftest_ttest_template(ftest, ftest_collapsed, ttest_f_vs_r, split_ttest, sh_i, sh_k, template_t):
    # They can not be True (False) at the same time
    if (ftest + ttest_f_vs_r + template_t) != 1:
        raise Exception("Check the status of ttest_f_vs_r=F/T, split_ttest=F/T, template_t=F/T in Acquisition_Gadget")
    # if not (ftest ^ ttest_f_vs_r):
    #     raise Exception("Check the status of ttest_f_vs_r=F/T, split_ttest=F/T in Acquisition_Gadget")
    if ttest_f_vs_r:
        if split_ttest:
            if (sh_i is None) or (sh_k is None):
                raise Exception("Check the status of split_ttest, sh_i, sh_k in Acquisition_Gadget")
        else:
            sh_i, sh_k = None, None


def EXE_FIX(gadget_name, n_sh, step, n_execution, input_len_gadget, n_rnd_gadget, output_len, ser,
            a_fix=None, b_fix=None):
    """
    This function generates and sends fix inputs to the Scale board, and receives the output via
    Used in template attack
    serial port """
    """ It is used in rapid measurement"""
    # ser is the serial port:
    # port = '/dev/ttyUSB0'  # Serial port
    # Open serial port
    ##################################################
    # ser = serial.Serial(port)
    # Executing the code n_execution times
    ##################################################
    in_data, out_data = [], []
    for j in range(n_execution):
        # Generate inputs of the gadget
        ##################################################
        G_F = Gen_shares_1byte_random_fix
        rnd_gadget = (G_F(n_rnd_gadget))[2]
        [input_a, in_a, mask_a] = G_F(n_sh, in_x=a_fix)
        [input_b, in_b, mask_b] = G_F(n_sh, in_x=b_fix)

        # The input data
        inputs_of_gadget = mask_a + mask_b + rnd_gadget
        # Check
        if len(inputs_of_gadget) != input_len_gadget:  # length in bytes
            print("ERROR INPUT LENGTH")

        # Send inputs through serial port
        #################################################
        ser.write(inputs_of_gadget)
        # Receive outputs through serial port
        #################################################
        # Read outputs
        shares_c = bytearray(ser.read(output_len))
        # Write trace into trs file
        #################################################
        # The Data need to be saved in trs file
        in_data.append(bytearray(in_a + in_b + inputs_of_gadget))
        out_data.append(shares_c)
        # Checking the correctness of the gadget and printing on the screen
        #################################################
        out_c = 0
        for p in range(0, n_sh):
            out_c ^= shares_c[p]

        correctness_gadget(n_sh - 1, gadget_name, input_a, input_b, mask_a, mask_b, rnd_gadget, shares_c, step, j)
        # # Printing the data on screen after "step" times executions
        # if j % step == 0:
        #     print('\n- Input {}:  [{}]'.format(j, inputs_of_gadget.hex()))
        #     print('- a: {} ---> shares_a: [{}]'.format(in_a.hex(), mask_a.hex()))
        #     print('- b: {} ---> shares_b: [{}]'.format(in_b.hex(), mask_b.hex()))
        #     print('- r: [{}] '.format(rnd_gadget.hex()))
        #     print('- c: {}, shares_c:[{}]'.format(hex(out_c), shares_c.hex()))
        #     print('___________________________________________________________________')
    return [in_data, out_data]
