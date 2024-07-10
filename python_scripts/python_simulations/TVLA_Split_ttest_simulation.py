import matplotlib as mpl  # for x axis scale
import time
from scipy.stats import ttest_ind
from datetime import datetime
import numpy as np
from colorama import init, Fore, Back, Style
import matplotlib.pyplot as plt
import secrets
import random
import sys

init(autoreset=True)  # initialize colorama

start_time = time.time()


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


def hw(x):
    return bin(x).count("1")


def masking(x, mask_ORD):
    """ This function masks the input x, the type of the output is bytearray"""
    y = bytearray(mask_ORD + 1)
    rnd = bytearray([secrets.randbits(8) for j in range(0, mask_ORD)])
    y[mask_ORD] = x
    for i in range(0, mask_ORD):
        y[i] = rnd[i]
        y[mask_ORD] ^= rnd[i]
    return y


def gen_trace(a0, a1, a2, sig):
    p0 = hw(a0) + np.random.normal(0, sig)
    p1 = hw(a1) + np.random.normal(0, sig)
    p2 = hw(a2) + np.random.normal(0, sig)
    p3 = np.random.normal(0, sig)
    p4 = hw(a0 ^ a1) + np.random.normal(0, sig)
    p5 = hw(a0 ^ a2) + np.random.normal(0, sig)
    p6 = hw(a1 ^ a2) + np.random.normal(0, sig)
    # p7 = hw(a0 ^ a1 ^ a2) + np.random.normal(0, sig)
    # p7 = np.random.normal(0, sig)
    # t = [p0, p1, p2, p3, p4, p5, p6, p7]
    t = [p0, p1, p2, p3, p4, p5, p6]
    # traces[j] = [p0, p1, p2, p3, p4, p5, p6, p7]
    return t


def gen_fix_rnd_TVLA(mask_ord, n_execution, sig_noise=1, fix_value=0, i=0):
    n_rnd_data_set, n_fix_data_set = 0, 0
    in_data = np.zeros((n_execution, 5), dtype="uint8")
    d_set = np.zeros(n_execution, dtype="uint8")
    traces = np.zeros((n_execution, 7))
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
        traces[j] = gen_trace(a0, a1, a2, sig_noise)
    np.save(f"t_test_results/traces_TVLA_{i}.npy", traces)
    np.save(f"t_test_results/data_set_TVLA_{i}.npy", d_set)
    # return d_set, traces, in_data


def gen_fix_rnd_ST(ii, kk, mask_ord, n_execution, sig_noise=1, fix_value=0, i=0):
    n_rnd_data_set, n_fix_data_set = 0, 0
    in_data = np.zeros((n_execution, 5), dtype="uint8")
    d_set = np.zeros(n_execution, dtype="uint8")
    traces = np.zeros((n_execution, 7))
    for j in range(n_execution):
        # Choosing data_set randomly: rnd_data_set if random bit == 0, fix_data_set if random bit == 1,
        fix_or_rnd_data = random.getrandbits(1)  # Pick a random bit
        input_a = secrets.randbits(8)
        # input_a and input_b are sampled in "int" type for
        # being convinced to use in masking function and gf_mult function
        if fix_or_rnd_data == 0:  # if the random bit is == 0, pick rnd_data_set
            data_set = (0).to_bytes(1, sys.byteorder)  # 0 means data belongs to rnd_data_set
            # input_a = secrets.randbits(8)
            two_sh_a = secrets.randbits(8)
            n_rnd_data_set += 1
        else:  # if the random bit is == 1, pick fix_data_set
            data_set = (1).to_bytes(1, sys.byteorder)  # 1 means data belongs to fix_data_set
            # input_a = fix_value
            two_sh_a = fix_value
            n_fix_data_set += 1
        # Converting input_a and input_b to "byte" type, in order to store in trs file
        in_a = input_a.to_bytes(1, sys.byteorder)
        # Masking inputs
        # a0, a1, a2 = mask_a = masking(input_a, mask_ord)  # type: bytearray
        mask_a = masking(input_a, mask_ord)  # type: bytearray
        mask_2_a = masking(two_sh_a, 1)  # type: bytearray
        mask_a[ii] = mask_2_a[0]
        mask_a[kk] = mask_2_a[1]
        mask_a[3 - (ii + kk)] = input_a ^ two_sh_a
        in_data[j] = bytearray(data_set + in_a + mask_a)
        d_set[j] = fix_or_rnd_data
        a0, a1, a2 = mask_a
        traces[j] = gen_trace(a0, a1, a2, sig_noise)
    np.save(f"t_test_results/traces_ST_{i}.npy", traces)
    np.save(f"t_test_results/data_set_ST_{i}.npy", d_set)
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


class T_Test(object):
    def __init__(self, trsfile_or_npy="trs", n_shs=2, dset=1, name_file="isw", G_n="isw", ppcy=125):
        self.n_sh = n_shs
        self.G_n = G_n
        self.pp_cy = ppcy
        self.trsfile_or_npy = trsfile_or_npy

        print("The traces and data-set are from npy files ")
        self.name_file = name_file
        traces_ = np.load(f"t_test_results/traces_{self.name_file}.npy")
        print(f" traces.shape: {traces_.shape}")
        set_ind_f_r = np.load(f"t_test_results/data_set_{self.name_file}.npy")
        self.fix_t = traces_[set_ind_f_r == 1]
        self.rnd_t = traces_[set_ind_f_r == 0]
        del traces_

    def uni_variate_Ttest(self, ord_=1):
        if ord_ == 1:
            print("First-order uni-variate test ")
            print("[+] Separating fixed and random traces")
            compute_t_UV = ttest_ind(self.fix_t, self.rnd_t, axis=0, equal_var=False)[0]
            return compute_t_UV
        if ord_ == 2:
            print("Second-order uni-variate test ")
            print("[+] Separating fixed and random traces")
            print("[+] Computing mean-free squared fix and rnd traces")
            fix_t_2 = self.fix_t.astype("float64")
            del self.fix_t
            mean_fix_t = np.mean(fix_t_2, axis=0)
            fix_t = (fix_t_2 - mean_fix_t) ** 2
            del mean_fix_t
            rnd_t_2 = self.rnd_t.astype("float64")
            del self.rnd_t
            mean_rnd_t = np.mean(rnd_t_2, axis=0)
            rnd_t = (rnd_t_2 - mean_rnd_t) ** 2
            del mean_rnd_t
            compute_t_UV = ttest_ind(fix_t, rnd_t, axis=0, equal_var=False)[0]
            return compute_t_UV


# gadget_name = ["isw", "dom_indep", "hpc1_opt", "pini1", "pini2"]

if __name__ == "__main__":
    G_n, ppc, n_sh, d, order = "isw", 4, 3, 1, 1

    n_traces = 200
    noise_s = 0.5
    #####################################################################
    # TVLA
    nf_tvla = "TVLA_0"
    gen_fix_rnd_TVLA(2, n_traces, sig_noise=noise_s)
    z_tvla = T_Test(trsfile_or_npy="npy", n_shs=n_sh, dset=d, name_file=nf_tvla, G_n=G_n, ppcy=ppc)
    t_tvla = z_tvla.uni_variate_Ttest(ord_=2)
    plt.plot(t_tvla)
    #####################################################################
    # Split t-test
    pairs_ind_ST = [(0, 1), (0, 2), (1, 2)]
    count = 0
    for iii, kkk in pairs_ind_ST:
        gen_fix_rnd_ST(iii, kkk, 2, n_traces, sig_noise=noise_s, i=count)
        nf_st = f"ST_" + str(count)
        z_st = T_Test(trsfile_or_npy="npy", n_shs=n_sh, dset=d, name_file=nf_st, G_n=G_n, ppcy=ppc)
        t_st = z_st.uni_variate_Ttest(ord_=1)
        plt.plot(t_st)
        count += 1

    #####################################################################
    l = [r"$l_{x_0}$", r"$l_{x_1}$", r"$l_{x_2}$", r"$l_{Random}$",
         r"$l_{(x_0 \oplus x_1)}$", r"$l_{(x_0 \oplus x_2)}$",
         r"$l_{(x_1 \oplus x_2)}$"]
    t_ann = ["Second-order-univariate TVLA", f"Split t-tet: shares {iii}, {kkk}"]
    t_ann = ["2nd-order TVLA", f"ST shares (0, 1)",
             f"ST shares (0, 2)", f"ST shares (1, 2)"]
    # plt.xticks(np.arange(7), l, rotation=90)
    plt.xticks(np.arange(7), l)
    plt.legend(t_ann, fontsize="small", loc="lower left")
    plt.axhline(y=4.5, color='r', linestyle='dashed', linewidth=1)
    plt.axhline(y=-4.5, color='r', linestyle='dashed', linewidth=1)
    plt.gca().xaxis.set_major_locator(mpl.ticker.MaxNLocator(integer=True))
    path = "Images/"
#     plot_show(path, "Samples", "t-statistics,
#               "Simulation t-test results ")
plot_show(path, "Samples", "t-statistics", "")
