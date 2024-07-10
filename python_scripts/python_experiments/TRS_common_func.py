import trsfile
import numpy as np
import matplotlib.pyplot as plt
import time
from datetime import datetime
from intermediate_values_n import *
from math import comb as COMB

import secrets
import random
import sys
import matplotlib as mpl  # for x axis scale
from scipy.stats import ttest_ind
import math
import os
import shutil
import pprint
import pickle
from intermediate_values_n import *
from itertools import product as pr
from itertools import combinations, chain
from functools import reduce
from mpmath import matrix, fsum, ones, zeros, mpf, svd_r
from statsmodels.stats.weightstats import DescrStatsW
from colorama import init, Fore, Back, Style
from scipy.stats import multivariate_normal
from tqdm import tqdm

init(autoreset=True)  # initialize colorama


def n_rand_in_gadget(gadget_name, mask_order):
    if gadget_name == "pini1" or "isw" or "dom_indep":
        n_rnd_gadget = int(mask_order * (mask_order + 1) / 2)
    if gadget_name == "bbpp":
        if mask_order <= 2:
            n_rnd_gadget = mask_order
        else:  # optimal
            n_rnd_gadget = mask_order + 1
    if gadget_name == "hpc1_opt":
        n_rnd_gadget = int(mask_order * (mask_order + 1) / 2) + mask_order
    if gadget_name == "pini2":
        n_rnd_gadget = int((mask_order ** 2) / 4) + 2 * mask_order + 1
    return n_rnd_gadget


def tx_rx_data_len(mask_order, d, gadget_name):
    # gadget_name = ["isw", "bbpp", "dom_indep", "hpc1_opt", "pini1", "pini2"]

    # The length of the TX data in Byte (B)
    # For each gadget, just change Mask_ORD and n_rnd_gadget
    # Here the shares of input_a and input_b are computed, so that
    # The TX data is: mask_a (shares_a), mask_b (shares_b) and n_rnd_gadget
    ##################################################
    # main_inputs = 2  # input_a: 1B, input_b: 1B

    # (Mask_ORD+1) B for shares of input_a, (Mask_ORD+1) B for shares of input_b
    n_shares_input = 2 * (mask_order + 1)
    n_rnd_gadget = n_rand_in_gadget(gadget_name, mask_order)

    in_len_gadget = n_shares_input + n_rnd_gadget
    print("- Input length of the gadget (a, b, r): ", in_len_gadget)
    out_len_gadget = mask_order + 1  # output_len = shares of c (c = a * b)
    print("- Output length of the gadget (c): ", out_len_gadget)
    print("- Length of the rnd (r): ", n_rnd_gadget)

    # The Data need to be saved in trs file
    ##################################################
    # d = 1   # f_r_distinguisher = 1, fix and random data
    # data = data_set (= rnd_or_fix) (in TRS.py: self.f_r_distinguisher = 1) + in_a + in_b + input_of_gadget (=
    # mask_a + mask_b + rnd_gadget)
    # data_len = 1 + 1 + 1 + input_len_gadget = 1 + 2 + input_len_gadget
    in_len_trs = d + 1 + 1 + in_len_gadget
    out_len_trs = out_len_gadget
    all_len_trs = in_len_trs + out_len_gadget
    # print("- len in_data in trs:", in_len_trs)
    # print("- len out_data in trs:", out_len_gadget)
    return [n_rnd_gadget, in_len_gadget, out_len_gadget, in_len_trs, out_len_trs, all_len_trs]


class TRS:
    def __init__(self, gadget_name, mask_order, trs_file_name, d) -> object:
        # gadget_name = ["isw", "bbpp", "dom_indep", "hpc1_opt", "pini1", "pini2"]
        valid_gadget(gadget_name)

        self.trace_root = trsfile.open(trs_file_name, 'r')
        self.pos = self.trace_root.engine.data_offset  # data_offset
        self.mask_order = mask_order
        headers = self.trace_root.engine.headers
        for header, value in headers.items():  # Gives the access to key & value f header
            if 'NUMBER_TRACES' in header.name:
                self.number_of_traces = value
            elif 'NUMBER_SAMPLES' in header.name:
                self.number_of_samples = value
            elif 'SAMPLE_CODING' in header.name:
                self.is_float = value.is_float  # sample_coding
            elif 'LENGTH_DATA' in header.name:
                self.cryptolen = value
                # print("len", self.cryptolen)
                # for fixed and random data, that first bit is for distinguishing f and r data acquisition_f_r.py:
                # data_length = 1 + 2 + 2 * (self.mask_order + 1) + self.mask_order *(self.mask_order + 1)/2 + (
                # self.mask_order + 1) self.f_r_distinguisher = 1   # fixed and rnd data
                # otherwise
                # self.f_r_distinguisher = 0
        [n_rnd_gadget, in_len_gadget, out_len_gadget, in_len_trs, out_len_trs, all_len_trs] = tx_rx_data_len(mask_order,
                                                                                                             d,
                                                                                                             gadget_name)
        print("traces: ", (self.number_of_traces, self.number_of_samples))
        self.f_r_distinguisher = d
        self.in_data_len = int(int(self.f_r_distinguisher) + 2 + 2 * (self.mask_order + 1) + n_rnd_gadget)
        self.output_len = int(self.mask_order + 1)
        self.data_length = int(self.in_data_len + self.output_len)

        # self.trace_root = [trace_root[i] for i in range(self.number_of_traces)]

    def get_trace_sample(self, ind):  # ind = index # Gives the samples of the index_th trace
        if 0 <= ind < self.number_of_traces:
            # return self.trace_root[ind].samples
            return self.trace_root[ind].samples
        else:
            raise IndexError(f"Index {ind} in get_trace_sample func is out of bounds")

    def get_all_traces(self):
        """ This function extracts all traces from TRS file"""
        all_trace = np.zeros((int(self.number_of_traces), self.number_of_samples), np.int16)
        for i in range(self.number_of_traces):
            # all_trace[i] = self.trace_root[i].samples
            all_trace[i] = self.get_trace_sample(i)
            # all_trace[i] = self.get_trace_sample(i) * (2 **(-16)) * 1000
        return all_trace

    def get_traces_date_fix_rnd(self):
        """ This function extracts all traces and data from TRS file"""
        n_t = self.number_of_traces
        n_s = self.number_of_samples
        all_trace = np.zeros((n_t, n_s), np.int16)
        set_data_ind = np.zeros(n_t, np.dtype('B'))
        for i in range(n_t):
            all_trace[i] = self.get_trace_sample(i)
            # data_set == 0: random,  data_set == 1: fix
            set_data_ind[i] = self.trace_root[i].data[0]
            # all_trace[i] = self.get_trace_sample(i) * (2 **(-16)) * 1000
        return all_trace, set_data_ind

    def get_traces_data_fix_rnd_2_cycles(self, cy1=None, cy2=None, ppc=125, start_tr=None, end_tr=None):
        """ This function extracts all traces from TRS file"""
        if start_tr is None and end_tr is None:
            n_t = self.number_of_traces
            start_tr, end_tr = 0, n_t
        else:
            n_t = end_tr - start_tr
        flag_all_cy = False
        if cy1 is None and cy2 is None:
            print("All cycles are extracting")
            flag_all_cy = True
            n_s = self.number_of_samples
        else:
            n_s = 2 * ppc
        all_trace = np.zeros((n_t, n_s), np.int16)
        set_data_ind = np.zeros(n_t, np.dtype('B'))
        for i in tqdm(range(start_tr, end_tr)):
            tr = self.get_trace_sample(i)
            if flag_all_cy:
                all_trace[i] = tr
            else:
                all_trace[i] = np.hstack((tr[cy1 * ppc:(cy1 + 1) * ppc], tr[cy2 * ppc:(cy2 + 1) * ppc]))
            del tr
            # data_set == 0: random,  data_set == 1: fix
            set_data_ind[i] = self.trace_root[i].data[0]
            # all_trace[i] = self.get_trace_sample(i) * (2 **(-16)) * 1000
        return all_trace, set_data_ind

    def get_randomly_traces_data(self, cy1=None, cy2=None, ppc=125, list_ind=None):
        """ This function extracts all traces from TRS file"""
        if list_ind is None:
            n_t = np.arange(self.number_of_traces)
        else:
            n_t = len(list_ind)
        flag_all_cy = False
        if cy1 is None and cy2 is None:
            print("All cycles are extracting")
            flag_all_cy = True
            n_s = self.number_of_samples
        else:
            n_s = 2 * ppc

        all_trace = np.zeros((n_t, n_s), np.int16)
        input_data = np.zeros((n_t, self.in_data_len), np.dtype('B'))  # input
        output_data = np.zeros((n_t, self.output_len), np.dtype('B'))  # output
        j = 0
        for i in list_ind:
            tr = self.get_trace_sample(i)
            if flag_all_cy:
                all_trace[j] = tr
            else:
                all_trace[j] = np.hstack((tr[cy1 * ppc:(cy1 + 1) * ppc], tr[cy2 * ppc:(cy2 + 1) * ppc]))
            del tr
            [in_data_int, out_data_int] = self.get_trace_data(i)
            input_data[j] = in_data_int
            output_data[j] = out_data_int
            del in_data_int, out_data_int
            # all_trace[i] = self.get_trace_sample(i) * (2 **(-16)) * 1000
            j += 1
        return [all_trace, input_data, output_data]

    def get_trace_data(self, ind, ret_c=True):
        if ind >= self.number_of_traces:  # Check the correctness of the number_of_traces
            raise ValueError("Index out of bounds")

        d_ind = np.frombuffer(self.trace_root[ind].data, dtype=np.dtype('B'))
        # Use slicing to extract parts of the data
        in_data_ind = d_ind[:self.in_data_len]

        if ret_c:
            c_ind = d_ind[self.in_data_len:self.data_length]
            return [in_data_ind, c_ind]
        else:
            return in_data_ind

    def get_all_trace_data(self):

        # print(self.in_data_len)
        # print(self.output_len)
        n_t_ = self.number_of_traces
        input_data = np.zeros((n_t_, self.in_data_len), np.dtype('B'))  # input
        output_data = np.zeros((n_t_, self.output_len), np.dtype('B'))  # output
        for i in range(int(n_t_)):
            [in_data_int, out_data_int] = self.get_trace_data(i)
            input_data[i] = in_data_int
            output_data[i] = out_data_int
        return [input_data, output_data]
        # in_data_byte = bytearray([j for j in in_data_int])
        # out_data_byte = bytearray([j for j in out_data_int])

    # get_all_poi_traces(self, traces, poi) needs to be edited:
    # use this:
    # a = np.array([[29271, 29511, 29512, 53, 0, 5, 516, 297, 29518, 29],
    #               [201, 271, 7572, 88, 10, 7685, 5566, 278241, 2743578, 29],
    #               [21, 2999511, 4888, 153, 35, 54, 6, 4, 38, 3]])
    # in_ = [2, 4, 6]
    # print(a[:, in_])

    # def get_all_poi_traces(self, traces, poi):
    #     """ This function extracts all points of interest of traces from TRS file"""
    #     print("[+] Extracting points of interest from traces")
    #     poi_all_traces = np.zeros((len(traces), len(poi)), np.float)
    #     for i in range(len(traces)):
    #         poi_all_traces[i, :] = traces[i][poi]
    #     return poi_all_traces

    def get_all_poi_traces(self, traces, poi):
        """ This function extracts all points of interest of traces from TRS file"""
        print("[+] Extracting points of interest from traces")
        return traces[:, poi]

    # Extracting and separating random and fixed traces from TRS file
    ##################################################################
    # def extract_trace_f_r_sets(self, traces):
    #     """This function separates fixed and random traces."""
    #     # Regarding acquisition_f_r.py code, the trs file contains both data sets (random and fixed)
    #     # the first byte of in_data in trs file indicates that the trace belongs to
    #     # which data set (random_set or fixed_set).
    #     # The trace belongs to rnd_data_set if random bit(data_set) == 0, and fix_data_set if random bit == 1.
    #     # Now, regarding the first byte (data_set byte), the two sets are extracted
    #     rnd_trace = []  # rnd_data_set
    #     fix_trace = []  # fix_data_set
    #
    #     n_rnd_data_set = 0  # The number of traces in random input set : random inputs
    #     n_fix_data_set = 0  # The number of traces in  fixed input set : fixed inputs
    #     for i in range(0, len(traces)):
    #         # Extracting the data_set byte, which is the first byte of in_data in trs file
    #         #################################################
    #         [in_data_int, out_data_int] = self.get_trace_data(i)
    #
    #         # out_data_int variable is not needed, deleting from memory:
    #         del out_data_int
    #
    #         data_set = in_data_int[0]
    #         if data_set == 0:
    #             rnd_trace.append(traces[i])
    #             n_rnd_data_set += 1
    #
    #         elif data_set == 1:
    #             fix_trace.append(traces[i])
    #             n_fix_data_set += 1
    #
    #         else:
    #             raise Exception("ERROR: The data in trs file is not correct")
    #
    #         n_rnd_fix_traces = n_rnd_data_set + n_fix_data_set
    #
    #         if n_rnd_fix_traces == len(traces):
    #             # print("[+] Finishing extracting data_sets")
    #             break
    #
    #     fix_trace = np.array(fix_trace, np.float64)
    #     rnd_trace = np.array(rnd_trace, np.float64)
    #     # print("-------------------------------------------------------------------------------")
    #     # print('-------> Info:')
    #     # print('[+] Input length in trs file {} Bytes'.format(self.in_data_len))
    #     # print('[+] Output length in trs file {} Bytes'.format(self.output_len))
    #     # print('[+] The trs file contains {} traces'.format(len(traces)))
    #     # print('[+] The number of fixed  traces: {}'.format(n_fix_data_set))
    #     # print('[+] The number of random traces: {}'.format(n_rnd_data_set))
    #     return [fix_trace, rnd_trace, n_fix_data_set, n_rnd_data_set]

    def extract_trace_f_r_sets(self, traces, dt="int16"):
        """This function separates fixed and random traces."""
        # Regarding acquisition_f_r.py code, the trs file contains both data sets (random and fixed)
        # the first byte of in_data in trs file indicates that the trace belongs to
        # which data set (random_set or fixed_set).
        # The trace belongs to rnd_data_set if random bit(data_set) == 0, and fix_data_set if random bit == 1.
        # Now, regarding the first byte (data_set byte), the two sets are extracted
        n_t, n_s = traces.shape
        allocate_nf_n_r = int(n_t / 10) * 6
        rnd_trace = np.empty((allocate_nf_n_r, n_s), dtype=dt)
        fix_trace = np.empty((allocate_nf_n_r, n_s), dtype=dt)

        n_rnd_data_set = 0  # The number of traces in random input set : random inputs
        n_fix_data_set = 0  # The number of traces in  fixed input set : fixed inputs
        for i in range(0, n_t):
            # Extracting the data_set byte, which is the first byte of in_data in trs file
            #################################################
            in_data_int = self.get_trace_data(i, ret_c=False)
            data_set = in_data_int[0]
            if data_set == 0:
                rnd_trace[n_rnd_data_set] = traces[i]
                n_rnd_data_set += 1

            elif data_set == 1:
                fix_trace[n_fix_data_set] = traces[i]
                n_fix_data_set += 1

            else:
                raise Exception("ERROR: The data in trs file is not correct")

        fix_trace = np.resize(fix_trace, (n_fix_data_set, n_s))
        rnd_trace = np.resize(rnd_trace, (n_rnd_data_set, n_s))

        # print("-------------------------------------------------------------------------------")
        # print('-------> Info:')
        # print('[+] Input length in trs file {} Bytes'.format(self.in_data_len))
        # print('[+] Output length in trs file {} Bytes'.format(self.output_len))
        # print('[+] The trs file contains {} traces'.format(len(traces)))
        # print('[+] The number of fixed  traces: {}'.format(n_fix_data_set))
        # print('[+] The number of random traces: {}'.format(n_rnd_data_set))
        return [fix_trace, rnd_trace, n_fix_data_set, n_rnd_data_set]

    # power traces and input bytes are stored in a trs file
    def extract_trace_sets(self):
        # inD: a, b, sh_a, sh_b, r, outD: sh_c
        all_traces_ = self.get_all_traces()
        # c_all_traces = centring_trace(all_traces_)
        all_data = self.get_all_trace_data()
        print("data_len_in_trs_file: a, b, sh_a, sh_b, r", all_data[0].shape)
        print("out_data_len_in_trs_file: sh_c", all_data[1].shape)
        # input_data = all_data[0]
        # output_data = all_data[1]
        return [all_traces_, all_data[0], all_data[1]]


def centring_trace(trace_set):
    """ All traces in the set are centred: x-mean"""
    mean_t = np.mean(trace_set, axis=0)
    centred_trace = trace_set - mean_t
    return centred_trace


def masking(x, mask_ORD):
    """ This function masks the input x, the type of the output is bytearray"""
    y = bytearray(mask_ORD + 1)
    rnd = bytearray([secrets.randbits(8) for j in range(0, mask_ORD)])
    y[mask_ORD] = x
    for i in range(0, mask_ORD):
        y[i] = rnd[i]
        y[mask_ORD] ^= rnd[i]
    return y


def gf_mult(a, b):
    """ Multiplication in the Galois field GF(2^8) """
    p = 0  # The product of the multiplication
    over_f = 0
    for i in range(8):
        # if b is odd, then add the corresponding a to p (final product = sum of all a's corresponding to odd b's)
        if b & 1 == 1:
            p ^= a  # since we're in GF(2^m), addition is an XOR

        over_f = a & 0x80
        a <<= 1
        if over_f == 0x80:
            a ^= 0x1b  # GF modulo: if a >= 128, then it will overflow when shifted left, so reduce
        b >>= 1
    return p % 256





def plot_show(path, x_l, y_l, title_l, name=""):
    plt.title(title_l)
    plt.xlabel(x_l)
    plt.ylabel(y_l)
    # plt.grid()
    plt.tight_layout()  # the size
    # plt.legend()
    plt.savefig(path + "/{}".format(name))
    # plt.show()
    plt.show()


def time_run(start_time):
    print("--------------------------------------------------------------")
    # print('Run time: {} seconds'.format(time.time() - start_time))
    m, s = divmod(time.time() - start_time, 60)
    print('Run time: {}:{} (min, sec)'.format(int(m), int(s)))
    now = datetime.now()  # current date and time
    print('Current time: {}'.format(now.strftime("%H:%M:%S")))
    print("--------------------------------------------------------------")


def valid_gadget(gadget_name):
    g_n = ["isw", "bbpp", "dom_indep", "hpc1_opt", "pini1", "pini2"]
    if gadget_name not in g_n:
        raise Exception("\n - Please enter a valid gadget_name: \n     isw, bbpp, dom_indep, hpc1_opt, pini1, pini2")


table = [
    0x00, 0x00, 0x19, 0x01, 0x32, 0x02, 0x1a, 0xc6, 0x4b, 0xc7, 0x1b, 0x68, 0x33, 0xee, 0xdf, 0x03,
    0x64, 0x04, 0xe0, 0x0e, 0x34, 0x8d, 0x81, 0xef, 0x4c, 0x71, 0x08, 0xc8, 0xf8, 0x69, 0x1c, 0xc1,
    0x7d, 0xc2, 0x1d, 0xb5, 0xf9, 0xb9, 0x27, 0x6a, 0x4d, 0xe4, 0xa6, 0x72, 0x9a, 0xc9, 0x09, 0x78,
    0x65, 0x2f, 0x8a, 0x05, 0x21, 0x0f, 0xe1, 0x24, 0x12, 0xf0, 0x82, 0x45, 0x35, 0x93, 0xda, 0x8e,
    0x96, 0x8f, 0xdb, 0xbd, 0x36, 0xd0, 0xce, 0x94, 0x13, 0x5c, 0xd2, 0xf1, 0x40, 0x46, 0x83, 0x38,
    0x66, 0xdd, 0xfd, 0x30, 0xbf, 0x06, 0x8b, 0x62, 0xb3, 0x25, 0xe2, 0x98, 0x22, 0x88, 0x91, 0x10,
    0x7e, 0x6e, 0x48, 0xc3, 0xa3, 0xb6, 0x1e, 0x42, 0x3a, 0x6b, 0x28, 0x54, 0xfa, 0x85, 0x3d, 0xba,
    0x2b, 0x79, 0x0a, 0x15, 0x9b, 0x9f, 0x5e, 0xca, 0x4e, 0xd4, 0xac, 0xe5, 0xf3, 0x73, 0xa7, 0x57,
    0xaf, 0x58, 0xa8, 0x50, 0xf4, 0xea, 0xd6, 0x74, 0x4f, 0xae, 0xe9, 0xd5, 0xe7, 0xe6, 0xad, 0xe8,
    0x2c, 0xd7, 0x75, 0x7a, 0xeb, 0x16, 0x0b, 0xf5, 0x59, 0xcb, 0x5f, 0xb0, 0x9c, 0xa9, 0x51, 0xa0,
    0x7f, 0x0c, 0xf6, 0x6f, 0x17, 0xc4, 0x49, 0xec, 0xd8, 0x43, 0x1f, 0x2d, 0xa4, 0x76, 0x7b, 0xb7,
    0xcc, 0xbb, 0x3e, 0x5a, 0xfb, 0x60, 0xb1, 0x86, 0x3b, 0x52, 0xa1, 0x6c, 0xaa, 0x55, 0x29, 0x9d,
    0x97, 0xb2, 0x87, 0x90, 0x61, 0xbe, 0xdc, 0xfc, 0xbc, 0x95, 0xcf, 0xcd, 0x37, 0x3f, 0x5b, 0xd1,
    0x53, 0x39, 0x84, 0x3c, 0x41, 0xa2, 0x6d, 0x47, 0x14, 0x2a, 0x9e, 0x5d, 0x56, 0xf2, 0xd3, 0xab,
    0x44, 0x11, 0x92, 0xd9, 0x23, 0x20, 0x2e, 0x89, 0xb4, 0x7c, 0xb8, 0x26, 0x77, 0x99, 0xe3, 0xa5,
    0x67, 0x4a, 0xed, 0xde, 0xc5, 0x31, 0xfe, 0x18, 0x0d, 0x63, 0x8c, 0x80, 0xc0, 0xf7, 0x70, 0x07,

    0x01, 0x03, 0x05, 0x0f, 0x11, 0x33, 0x55, 0xff, 0x1a, 0x2e, 0x72, 0x96, 0xa1, 0xf8, 0x13, 0x35,
    0x5f, 0xe1, 0x38, 0x48, 0xd8, 0x73, 0x95, 0xa4, 0xf7, 0x02, 0x06, 0x0a, 0x1e, 0x22, 0x66, 0xaa,
    0xe5, 0x34, 0x5c, 0xe4, 0x37, 0x59, 0xeb, 0x26, 0x6a, 0xbe, 0xd9, 0x70, 0x90, 0xab, 0xe6, 0x31,
    0x53, 0xf5, 0x04, 0x0c, 0x14, 0x3c, 0x44, 0xcc, 0x4f, 0xd1, 0x68, 0xb8, 0xd3, 0x6e, 0xb2, 0xcd,
    0x4c, 0xd4, 0x67, 0xa9, 0xe0, 0x3b, 0x4d, 0xd7, 0x62, 0xa6, 0xf1, 0x08, 0x18, 0x28, 0x78, 0x88,
    0x83, 0x9e, 0xb9, 0xd0, 0x6b, 0xbd, 0xdc, 0x7f, 0x81, 0x98, 0xb3, 0xce, 0x49, 0xdb, 0x76, 0x9a,
    0xb5, 0xc4, 0x57, 0xf9, 0x10, 0x30, 0x50, 0xf0, 0x0b, 0x1d, 0x27, 0x69, 0xbb, 0xd6, 0x61, 0xa3,
    0xfe, 0x19, 0x2b, 0x7d, 0x87, 0x92, 0xad, 0xec, 0x2f, 0x71, 0x93, 0xae, 0xe9, 0x20, 0x60, 0xa0,
    0xfb, 0x16, 0x3a, 0x4e, 0xd2, 0x6d, 0xb7, 0xc2, 0x5d, 0xe7, 0x32, 0x56, 0xfa, 0x15, 0x3f, 0x41,
    0xc3, 0x5e, 0xe2, 0x3d, 0x47, 0xc9, 0x40, 0xc0, 0x5b, 0xed, 0x2c, 0x74, 0x9c, 0xbf, 0xda, 0x75,
    0x9f, 0xba, 0xd5, 0x64, 0xac, 0xef, 0x2a, 0x7e, 0x82, 0x9d, 0xbc, 0xdf, 0x7a, 0x8e, 0x89, 0x80,
    0x9b, 0xb6, 0xc1, 0x58, 0xe8, 0x23, 0x65, 0xaf, 0xea, 0x25, 0x6f, 0xb1, 0xc8, 0x43, 0xc5, 0x54,
    0xfc, 0x1f, 0x21, 0x63, 0xa5, 0xf4, 0x07, 0x09, 0x1b, 0x2d, 0x77, 0x99, 0xb0, 0xcb, 0x46, 0xca,
    0x45, 0xcf, 0x4a, 0xde, 0x79, 0x8b, 0x86, 0x91, 0xa8, 0xe3, 0x3e, 0x42, 0xc6, 0x51, 0xf3, 0x0e,
    0x12, 0x36, 0x5a, 0xee, 0x29, 0x7b, 0x8d, 0x8c, 0x8f, 0x8a, 0x85, 0x94, 0xa7, 0xf2, 0x0d, 0x17,
    0x39, 0x4b, 0xdd, 0x7c, 0x84, 0x97, 0xa2, 0xfd, 0x1c, 0x24, 0x6c, 0xb4, 0xc7, 0x52, 0xf6, 0x01,

    0x03, 0x05, 0x0f, 0x11, 0x33, 0x55, 0xff, 0x1a, 0x2e, 0x72, 0x96, 0xa1, 0xf8, 0x13, 0x35,
    0x5f, 0xe1, 0x38, 0x48, 0xd8, 0x73, 0x95, 0xa4, 0xf7, 0x02, 0x06, 0x0a, 0x1e, 0x22, 0x66, 0xaa,
    0xe5, 0x34, 0x5c, 0xe4, 0x37, 0x59, 0xeb, 0x26, 0x6a, 0xbe, 0xd9, 0x70, 0x90, 0xab, 0xe6, 0x31,
    0x53, 0xf5, 0x04, 0x0c, 0x14, 0x3c, 0x44, 0xcc, 0x4f, 0xd1, 0x68, 0xb8, 0xd3, 0x6e, 0xb2, 0xcd,
    0x4c, 0xd4, 0x67, 0xa9, 0xe0, 0x3b, 0x4d, 0xd7, 0x62, 0xa6, 0xf1, 0x08, 0x18, 0x28, 0x78, 0x88,
    0x83, 0x9e, 0xb9, 0xd0, 0x6b, 0xbd, 0xdc, 0x7f, 0x81, 0x98, 0xb3, 0xce, 0x49, 0xdb, 0x76, 0x9a,
    0xb5, 0xc4, 0x57, 0xf9, 0x10, 0x30, 0x50, 0xf0, 0x0b, 0x1d, 0x27, 0x69, 0xbb, 0xd6, 0x61, 0xa3,
    0xfe, 0x19, 0x2b, 0x7d, 0x87, 0x92, 0xad, 0xec, 0x2f, 0x71, 0x93, 0xae, 0xe9, 0x20, 0x60, 0xa0,
    0xfb, 0x16, 0x3a, 0x4e, 0xd2, 0x6d, 0xb7, 0xc2, 0x5d, 0xe7, 0x32, 0x56, 0xfa, 0x15, 0x3f, 0x41,
    0xc3, 0x5e, 0xe2, 0x3d, 0x47, 0xc9, 0x40, 0xc0, 0x5b, 0xed, 0x2c, 0x74, 0x9c, 0xbf, 0xda, 0x75,
    0x9f, 0xba, 0xd5, 0x64, 0xac, 0xef, 0x2a, 0x7e, 0x82, 0x9d, 0xbc, 0xdf, 0x7a, 0x8e, 0x89, 0x80,
    0x9b, 0xb6, 0xc1, 0x58, 0xe8, 0x23, 0x65, 0xaf, 0xea, 0x25, 0x6f, 0xb1, 0xc8, 0x43, 0xc5, 0x54,
    0xfc, 0x1f, 0x21, 0x63, 0xa5, 0xf4, 0x07, 0x09, 0x1b, 0x2d, 0x77, 0x99, 0xb0, 0xcb, 0x46, 0xca,
    0x45, 0xcf, 0x4a, 0xde, 0x79, 0x8b, 0x86, 0x91, 0xa8, 0xe3, 0x3e, 0x42, 0xc6, 0x51, 0xf3, 0x0e,
    0x12, 0x36, 0x5a, 0xee, 0x29, 0x7b, 0x8d, 0x8c, 0x8f, 0x8a, 0x85, 0x94, 0xa7, 0xf2, 0x0d, 0x17,
    0x39, 0x4b, 0xdd, 0x7c, 0x84, 0x97, 0xa2, 0xfd, 0x1c, 0x24, 0x6c, 0xb4, 0xc7, 0x52, 0xf6, 0x01
]



def im_data(all_data, ind):
    d = np.zeros(len(all_data))
    for i in range(len(all_data)):
        d[i] = all_data[i][ind]
    return d.astype(np.dtype('B'))


def correctness_gadget(Mask_ORD, gadget_name, input_a, input_b, a, b, r, shares_c, step, i):
    valid_gadget(gadget_name)

    out_c = 0
    for p in range(0, Mask_ORD + 1):
        out_c ^= shares_c[p]
        # all_data = input_a + input_b + a + b + r + shares_c
        gf_a_b = gf_mult(input_a, input_b)

    if i % step == 0:
        print('\ni={0} ----------------------------------'.format(i))
        # print('- in_data {}: {}'.format(i, (all_data + shares_c).hex()))
        print('- shares_a: [{}], a: {}'.format(a.hex(), hex(input_a)))
        print('- shares_b: [{}], b: {}'.format(b.hex(), hex(input_b)))
        print('- shares_r: [{}]'.format(r.hex()))
        print('- shares_c: [{}], c: {}'.format(shares_c.hex(), hex(out_c)))
        print('- gfmult: {}'.format(hex(gf_a_b)))

    ##### Testing different gadgets
    c = bytearray([0 for j in range(0, Mask_ORD + 1)])
    if gadget_name == "isw":
        if Mask_ORD == 1:
            c[0] = gf_mult(a[0], b[0]) ^ r[0]
            c[1] = (gf_mult(a[0], b[1]) ^ r[0]) ^ gf_mult(a[1], b[0]) ^ gf_mult(a[1], b[1])

        if Mask_ORD == 2:
            c[0] = gf_mult(a[0], b[0]) ^ r[0] ^ r[1]
            c[1] = (gf_mult(a[0], b[1]) ^ r[0]) ^ gf_mult(a[1], b[0]) ^ gf_mult(a[1], b[1]) ^ r[2]
            c[2] = (gf_mult(a[0], b[2]) ^ r[1]) ^ gf_mult(a[2], b[0]) ^ gf_mult(a[1], b[2]) ^ gf_mult(a[2], b[1]) ^ \
                   r[2] ^ gf_mult(a[2], b[2])

    if gadget_name == "bbpp":
        if Mask_ORD == 1:
            c[0] = (gf_mult(a[0], b[0]) ^ r[0]) ^ gf_mult(a[0], b[1]) ^ gf_mult(a[1], b[0])
            c[1] = gf_mult(a[1], b[1]) ^ r[0]

        # It is the optimal one, algorithm 4
        if Mask_ORD == 2:
            c[0] = gf_mult(a[0], b[0]) ^ r[0] ^ gf_mult(a[0], b[2]) ^ gf_mult(a[2], b[0])
            c[1] = gf_mult(a[1], b[1]) ^ r[1] ^ gf_mult(a[0], b[1]) ^ gf_mult(a[1], b[0])
            c[2] = gf_mult(a[2], b[2]) ^ r[0] ^ r[1] ^ gf_mult(a[1], b[2]) ^ gf_mult(a[2], b[1])

    if gadget_name == "dom_indep":
        if Mask_ORD == 1:
            c[0] = gf_mult(a[0], b[0]) ^ gf_mult(a[0], b[1]) ^ r[0]
            c[1] = gf_mult(a[1], b[0]) ^ r[0] ^ gf_mult(a[1], b[1])
        if Mask_ORD == 2:
            c[0] = gf_mult(a[0], b[0]) ^ gf_mult(a[0], b[1]) ^ r[0] ^ gf_mult(a[0], b[2]) ^ r[1]
            c[1] = gf_mult(a[1], b[0]) ^ r[0] ^ gf_mult(a[1], b[1]) ^ gf_mult(a[1], b[2]) ^ r[2]
            c[2] = gf_mult(a[2], b[0]) ^ r[1] ^ gf_mult(a[2], b[1]) ^ r[2] ^ gf_mult(a[2], b[2])

    if gadget_name == "hpc1_opt":
        if Mask_ORD == 1:
            ref_b = bytearray([(b[ele] ^ r[0]) for ele in range(0, Mask_ORD + 1)])

            if i % step == 0:
                print('- ref_b {}: {}'.format(i, ref_b.hex()))

            c[0] = gf_mult(a[0], ref_b[0]) ^ gf_mult(a[0], ref_b[1]) ^ r[1]
            c[1] = gf_mult(a[1], ref_b[0]) ^ r[1] ^ gf_mult(a[1], ref_b[1])

        if Mask_ORD == 2:
            x = [(b[ele] ^ r[ele]) for ele in range(0, Mask_ORD)]
            x.append((b[2] ^ (r[0] ^ r[1])))
            ref_b = bytearray(x)
            del x

            if i % step == 0:
                print('- ref_b: [{}] '.format(ref_b.hex()))

            c[0] = gf_mult(a[0], ref_b[0]) ^ gf_mult(a[0], ref_b[1]) ^ r[2] ^ gf_mult(a[0], ref_b[2]) ^ r[3]
            c[1] = gf_mult(a[1], ref_b[0]) ^ r[2] ^ gf_mult(a[1], ref_b[1]) ^ gf_mult(a[1], ref_b[2]) ^ r[4]
            c[2] = gf_mult(a[2], ref_b[0]) ^ r[3] ^ gf_mult(a[2], ref_b[1]) ^ r[4] ^ gf_mult(a[2], ref_b[2])

    if gadget_name == "pini1":
        if Mask_ORD == 1:
            c[0] = gf_mult(a[0], b[0]) ^ gf_mult((a[0] ^ 1), r[0]) ^ gf_mult(a[0], (b[1] ^ r[0]))
            c[1] = gf_mult(a[1], b[1]) ^ gf_mult((a[1] ^ 1), r[0]) ^ gf_mult(a[1], (b[0] ^ r[0]))
        if Mask_ORD == 2:
            c[0] = gf_mult(a[0], b[0]) ^ gf_mult(a[0] ^ 1, r[0]) ^ gf_mult(a[0], (b[1] ^ r[0])) ^ \
                   gf_mult(a[0] ^ 1, r[1]) ^ gf_mult(a[0], (b[2] ^ r[1]))
            c[1] = gf_mult(a[1], b[1]) ^ gf_mult(a[1] ^ 1, r[0]) ^ gf_mult(a[1], (b[0] ^ r[0])) ^ \
                   gf_mult(a[1] ^ 1, r[2]) ^ gf_mult(a[1], (b[2] ^ r[2]))
            c[2] = gf_mult(a[2], b[2]) ^ gf_mult(a[2] ^ 1, r[1]) ^ gf_mult(a[2], (b[0] ^ r[1])) ^ \
                   gf_mult(a[2] ^ 1, r[2]) ^ gf_mult(a[2], (b[1] ^ r[2]))

    if gadget_name == "pini2":
        if Mask_ORD == 1:
            s01 = r[0] ^ r[1]
            c[0] = gf_mult(a[0], b[0]) ^ r[2] ^ \
                   gf_mult(a[0], s01) ^ gf_mult(a[0], (b[1] ^ s01)) ^ \
                   gf_mult(b[0], s01) ^ gf_mult(b[0], (a[1] ^ s01))
            c[1] = gf_mult(a[1], b[1]) ^ r[2]
        if Mask_ORD == 2:
            s01 = r[0] ^ r[1]
            s02 = r[0] ^ r[2]
            s12 = r[1] ^ r[2]
            p0_01 = gf_mult(a[0], s01)
            p1_01 = gf_mult(a[0], (b[1] ^ s01))
            p2_01 = gf_mult(b[0], s01)
            p3_01 = gf_mult(b[0], (a[1] ^ s01))
            p0_02 = gf_mult(a[0], s02)
            p1_02 = gf_mult(a[0], (b[2] ^ s02))
            p2_02 = gf_mult(b[0], s02)
            p3_02 = gf_mult(b[0], (a[2] ^ s02))
            p0_12 = gf_mult(a[1], s12)
            p1_12 = gf_mult(a[1], (b[2] ^ s12))
            p2_12 = gf_mult(b[1], s12)
            p3_12 = gf_mult(b[1], (a[2] ^ s12))

            c[0] = gf_mult(a[0], b[0]) ^ (r[3] ^ p0_02 ^ p1_02 ^ p2_02 ^ p3_02 ^ r[4] ^ p0_01 ^ p1_01 ^ p2_01 ^ p3_01)
            c[1] = gf_mult(a[1], b[1]) ^ (r[5] ^ p0_12 ^ p1_12 ^ p2_12 ^ p3_12) ^ r[4]
            c[2] = gf_mult(a[2], b[2]) ^ r[5] ^ r[3]

    for j in range(0, Mask_ORD + 1):
        if c[j] != shares_c[j]:
            print("i=", i, ":", c[j], "!=", shares_c[j])
            raise Exception(("ERROR: c[{}] != output[{}]".format(j, j)))

    if gf_mult(input_a, input_b) != out_c:
        raise Exception("ERROR: gmul(in_b, in_a) != output of gadget")



#
# def bit_mask_LL(all_im, bitn):
#     """ takes list of list: [[u0, u1], [u2, u3], [u4, u5]]
#     returns bitn bits: list_op = [[u0, u1], [u2, u3], [u4, u5]]"""
#     bitmask = 2 ** bitn - 1
#     for i in range(len(all_im)):
#         all_im[i] = np.array(all_im[i])
#     list_op = []
#     q = len(all_im)
#     for i in range(q):
#         list_op.append(all_im[i] & bitmask)  # Considering "bitn" bits
#     list_op = np.array(list_op)
#     return list_op

def bit_mask_LL(all_im, bitn):
    dt = "uint8"
    bitmask = 2 ** bitn - 1
    list_op = np.array(([im & bitmask for im in all_im]), dtype=dt)
    return list_op


def hw_1_d(x: np):
    d = [bin(x[i]).count("1") for i in range(len(x))]
    return np.asarray(d, np.dtype('uint8'))


def hw_mask_LL(all_im):
    dt = "uint8"
    list_op = np.array(([hw_1_d(im) for im in all_im]), dtype=dt)
    return list_op


def calMean_1_d(data_val, traces, filt):
    # if the value "filt" does not exist in data: ind[0] =[], then mean = Nan
    ind = np.nonzero(data_val == filt)[0]
    if len(ind) == 0:
        m0 = np.zeros((traces.shape[1]))
        return [m0, len(ind)]
    return [np.mean(traces[ind, :], axis=0), len(ind)]


def calMean_2_d(data_val, traces, filt):
    # if the value "filt" does not exist in data: ind[0] =[], then mean = Nan
    # ind = np.nonzero(data_val == filt)
    ind = np.where(np.all(data_val == filt, axis=1))[0]
    # print("ind_filt:", filt, ind)
    if len(ind) == 0:
        m0 = np.zeros((traces.shape[1]))
        return [m0, len(ind)]
    else:
        if traces.ndim == 1:
            return [np.mean(traces[ind]), len(ind)]
        else:
            return [np.mean(traces[ind, :], axis=0), len(ind)]


def create_dir(path_dir):
    """ It checks if a directory exists, if not, creates it."""
    if not os.path.exists(path_dir):
        try:
            os.makedirs(path_dir)
        except OSError as e:
            print(f"Error: {e}")
    else:
        print(f"The directory {path_dir} already exists.")


def plot_tr(tr):
    for i in range(tr.shape[0]):
        plt.plot(tr[i])


def plot_one_sample_tr(s_tr):
    x = [1] * len(s_tr)
    plt.scatter(x, s_tr)



def hw(x):
    return bin(x).count("1")


def gen_fix_rnd(mask_ord, n_execution, sig_noise=1, fix_value=0):
    n_rnd_data_set, n_fix_data_set = 0, 0
    in_data = np.zeros((n_execution, 5), dtype="uint8")
    d_set = np.zeros(n_execution, dtype="uint8")
    traces = np.zeros((n_execution, 8))
    for j in range(n_execution):
        # Choosing data_set randomly: rnd_data_set if random bit == 0, fix_data_set if random bit == 1,
        fix_or_rnd_data = random.getrandbits(1)  # Pick a random bit
        # input_a and input_b are sampled in "int" type for
        # being convinced to use in masking function and gf_mult function
        if fix_or_rnd_data == 0:  # if the random bit is == 0, pick rnd_data_set
            data_set = (0).to_bytes(1, sys.byteorder)  # 0 means data belongs to rnd_data_set
            input_a = secrets.randbits(8)
            n_rnd_data_set += 1
        else:  # if the random bit is == 1, pick fix_data_set
            data_set = (1).to_bytes(1, sys.byteorder)  # 1 means data belongs to fix_data_set
            input_a = fix_value
            n_fix_data_set += 1
        # Converting input_a and input_b to "byte" type, in order to store in trs file
        in_a = input_a.to_bytes(1, sys.byteorder)
        # Masking inputs
        a0, a1, a2 = mask_a = masking(input_a, mask_ord)  # type: bytearray
        in_data[j] = bytearray(data_set + in_a + mask_a)
        d_set[j] = fix_or_rnd_data
        # trace, 8 points:
        p0 = hw(a0) + np.random.normal(0, sig_noise)
        p1 = np.random.normal(0, sig_noise)
        p2 = hw(a0 ^ a2) + np.random.normal(0, sig_noise)
        p3 = np.random.normal(0, sig_noise)
        p4 = hw(a1 ^ a2) + np.random.normal(0, sig_noise)
        p5 = hw(a0 ^ a1) + np.random.normal(0, sig_noise)
        p6 = hw(a1) + np.random.normal(0, sig_noise)
        p7 = hw(a2) + np.random.normal(0, sig_noise)
        traces[j] = [p0, p1, p2, p3, p4, p5, p6, p7]
    np.save(f"t_test_results/traces_cy_0_cy_1.npy", traces)
    np.save(f"t_test_results/data_set_cy_0_cy_1.npy", d_set)
    # return d_set, traces, in_data


def Leakage_points(t_values):
    """ This functions finds the points that have t_values > |+-4.5|"""
    leakage_m = np.abs(t_values) > 4.5
    n_samp = np.arange(len(t_values), dtype=np.int32)
    leakage_point = n_samp[leakage_m]
    leakage_t_val = t_values[leakage_m].astype(np.float32)
    # max_point = np.argmax(t_values)
    max_point = np.argmax(np.abs(t_values))
    t_val_max_point = t_values[max_point]
    return [max_point, t_val_max_point, leakage_point, leakage_t_val]


def leak_is_comb_i_j(leaky_p, poi_cy1=None, pc_c=125):
    c1 = poi_cy1 if poi_cy1 is not None else np.arange(pc_c)
    c2 = np.arange(pc_c)
    all_comb = []
    for i in c1:
        for j in c2:
            all_comb.append([i, j])
    all_comb = np.array(all_comb)
    print(all_comb[leaky_p])


# def central_product_2_cycles(t_set):
#     """ t_set is a set of trace contains two cycles.
#     the central product of the two cycle in the traces set are computed.
#     if t_set.shape(n_t, n_s), it returns: (n_t, n_s*n_s), means:
#     new traces has the length:n_s*n_s
#     It does not consider the combination of points in the same cycle,
#     so instead of new traces has the length (2*n_s)*(2*n_s - 1)/2, they have n_s*n_s
#     """
#
#     t_set = t_set.astype("float64")
#     mean_t = np.mean(t_set, axis=0)
#     t_set = t_set - mean_t
#     del mean_t
#     n_t = len(t_set)
#     n_s = int(len(t_set[0]) / 2)  # it contains two cycles
#     cpt = np.empty((n_t, (n_s ** 2)))
#     ind = 0
#     for i in range(n_s):
#         for j in range(n_s, 2 * n_s):
#             cpt[:, ind] = t_set[:, i] * t_set[:, j]
#             ind += 1
#     return cpt
#
def central_product_2_cycles(t_set, p_p_clock, poi_cycl1=None):
    """ if  poi_cycl1=None:
     t_set is a set of trace contains two cycles.
    the central product of the two cycle in the traces set are computed.
    if t_set.shape(n_t, n_s), it returns: (n_t, n_s*n_s), means:
    new traces has the length:n_s*n_s
    It does not consider the combination of points in the same cycle,
    so instead of new traces has the length (2*n_s)*(2*n_s - 1)/2, they have n_s*n_s
    if  poi_cycl1=np.array([0, 10, 150]):
    t_set is a set of trace contains poi + 1 cycle.
    the central product of the poi with the cycle in the traces set are computed.
    if t_set.shape(n_t, len(poi)+ppc), it returns: (n_t, len(poi)*ppc), means:
    new traces has the length:len(poi)*ppc
    It does not consider the combination of points in the same cycle,
    so instead of new traces has the length (len(poi)+ppc)*(len(poi)+ppc - 1)/2, they have len(poi)*ppc
    """
    n_s = len(t_set[0])
    t_set = t_set.astype("float64")
    mean_t = np.mean(t_set, axis=0)
    t_set = t_set - mean_t
    del mean_t
    n_t = len(t_set)
    if poi_cycl1 is None:
        l_p1 = int(n_s / 2)  # it contains two cycles
        di_cp = l_p1 ** 2
        # l_p2 = l_p1
        # chek_
        if (2 * p_p_clock) != (2 * l_p1):
            raise Exception("Please check: p_p_clock, poi_cycl1=None")
    else:
        l_p1 = len(poi_cycl1)
        di_cp = l_p1 * p_p_clock
        # l_p2 = n_s - l_p1
        # chek_
        if (p_p_clock + l_p1) != n_s:
            raise Exception("Please check: p_p_clock, poi_cycl1=None")

    cpt = np.empty((n_t, di_cp))
    ind = 0
    for i in range(l_p1):
        for j in range(l_p1, n_s):
            cpt[:, ind] = t_set[:, i] * t_set[:, j]
            ind += 1
    return cpt


def add_k_start_n(tN, add_k, sN):
    """tN: total traces, add_k: adding k traces (their data),
     sN: start from sN traces:
    """
    if add_k is not None:
        if add_k > tN:
            raise Exception("add_k_t > total_Nt: add-k-traces cannot exceed the total-traces")
        if sN is not None:
            if add_k >= sN:
                raise Exception("add_k_t >= sN: add-k-traces cannot exceed the start-traces")
            else:
                n_t0 = sN - add_k
        else:
            n_t0 = 0
    else:
        n_t0 = tN
    return n_t0


def central_product(t_set):
    """ t_set is a set of trace .
    if t_set.shape(n_t, n_s), it returns: (n_t,n_s)*(n_s - 1)/2)
    """
    t_set = t_set.astype("float64")
    mean_t = np.mean(t_set, axis=0)
    t_set = t_set - mean_t
    del mean_t
    n_t = len(t_set)
    n_s = len(t_set[0])
    new_n_s = int((n_s * (n_s - 1)) / 2)  # it contains two cycles
    cpt = np.empty((n_t, new_n_s))
    ind = 0
    for i in range(n_s):
        for j in range(i + 1, new_n_s):
            cpt[:, ind] = t_set[:, i] * t_set[:, j]
            ind += 1
    return cpt




def check_pickle_obj(obj_):
    try:
        pickle.dumps(obj_)
        print("It is pickleable")
    except (pickle.PickleError, TypeError):
        print("It is NOT pickleable")