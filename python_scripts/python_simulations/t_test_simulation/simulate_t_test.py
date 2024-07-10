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
    plt.grid()
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


def gen_fix_rnd(mask_ord, n_execution, sig_noise=1, fix_value=0):
    n_rnd_data_set, n_fix_data_set = 0, 0
    in_data = np.zeros((n_execution, 5), dtype="uint8")
    d_set = np.zeros(n_execution, dtype="uint8")
    traces = np.zeros((n_execution, 6))
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
        # trace, 3 points:
        p0 = hw(a0) + np.random.normal(0, sig_noise)
        p1 = np.random.normal(0, sig_noise)
        p2 = hw(a0 ^ a2) + np.random.normal(0, sig_noise)
        p3 = np.random.normal(0, sig_noise)
        p4 = hw(a1 ^ a2) + np.random.normal(0, sig_noise)
        p5 = hw(a0 ^ a1) + np.random.normal(0, sig_noise)
        traces[j] = [p0, p1, p2, p3, p4, p5]
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


def central_product_2_cycles(t_set):
    """ t_set is a set of trace contains two cycles.
    the central product of the two cycle in the traces set are computed.
    if t_set.shape(n_t, n_s), it returns: (n_t, n_s*n_s), means:
    new traces has the length:n_s*n_s
    It does not consider the combination of points in the same cycle,
    so instead of new traces has the length (2*n_s)*(2*n_s - 1)/2, they have n_s*n_s
    """

    t_set = t_set.astype("float64")
    mean_t = np.mean(t_set, axis=0)
    t_set = t_set - mean_t
    del mean_t
    n_t = len(t_set)
    n_s = int(len(t_set[0]) / 2)  # it contains two cycles
    cpt = np.empty((n_t, (n_s ** 2)))
    ind = 0
    for i in range(n_s):
        for j in range(n_s, 2 * n_s):
            cpt[:, ind] = t_set[:, i] * t_set[:, j]
            ind += 1
    return cpt


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


class T_Test(object):
    def __init__(self, trsfile_or_npy="trs", two_cycles=False, cy_1=None, cy_2=None, n_shs=2, dset=1,
                 name_file="pini2_2", G_n="pini2_2", ppcy=125):
        self.n_sh = n_shs
        self.G_n = G_n
        self.pp_cy = ppcy
        self.trsfile_or_npy = trsfile_or_npy

        print("The traces and data-set are from npy files ")
        self.name_file = name_file
        if two_cycles:
            self.traces = np.load(f"t_test_results/traces_cy_0_cy_1.npy")
            print(f" traces.shape: {self.traces.shape}")
            self.set_ind_f_r = np.load(f"t_test_results/data_set_cy_0_cy_1.npy")
        if not two_cycles:
            traces_ = np.load(f"t_test_results/tr_{self.name_file}.npy")
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

    def multi_variate_Ttest(self):
        """ The central-product combination, all combinations"""
        print("First-order multi-variate test on all cycles ...")
        cp_fix = central_product(self.fix_t)
        del self.fix_t
        print("[+] Computing product centralized rnd traces")
        cp_rnd = central_product(self.rnd_t)
        del self.rnd_t
        compute_t_MV = ttest_ind(cp_fix, cp_rnd, axis=0, equal_var=False)[0]
        del cp_fix, cp_rnd
        return compute_t_MV

    def multi_variate_Ttest_2_cycles_increasing_N(self, add_k_tr_data=None):
        """ The central-product combination of cy1 and cy2
        It does the t-test on central-product of N traces, and it increased N by add_trace
        """

        print("First-order multi-variate test on two cycles ...")

        # create_dir(f"t_test_results/")
        # np.save(f"t_test_results/traces_cy_{cy_1}_cy_{cy_2}.npy", all_traces)
        # np.save(f"t_test_results/data_set_cy_{cy_1}_cy_{cy_2}.npy", all_set_ind_f_r)
        # all_traces = np.load(f"t_test_results/tr_ttest_isw3_20K_3_cy_{cy_1}_cy_{cy_2}.npy")
        # all_set_ind_f_r = np.load(f"t_test_results/data_set_ttest_isw3_20K_3_cy_{cy_1}_cy_{cy_2}.npy")
        n_all_t = len(self.traces)
        add_k_tr_data = n_all_t if add_k_tr_data is None else add_k_tr_data
        i, n_t_, t_update, l_p = 1, 0, 0, np.array([])
        n_samp = np.arange(ppc ** 2, dtype=np.int32)
        find_l_flag = False
        while not find_l_flag:
            n_t_ = i * add_k_tr_data
            if n_t_ > n_all_t:
                print("n_t in t-test exceeds the length of all_traces")
                find_l_flag = False
                n_t_ = (i - 1) * add_k_tr_data
                break
            print(f"- {n_t_} traces")
            partial_traces = self.traces[:n_t_]
            partial_set_ind_f_r = self.set_ind_f_r[:n_t_]
            fix_t_2 = partial_traces[partial_set_ind_f_r == 1]
            rnd_t_2 = partial_traces[partial_set_ind_f_r == 0]
            del partial_traces
            print("     - Computing central-product fix and rnd traces")
            cp_fix = central_product_2_cycles(fix_t_2)
            del fix_t_2
            cp_rnd = central_product_2_cycles(rnd_t_2)
            del rnd_t_2
            t_update = ttest_ind(cp_fix, cp_rnd, axis=0, equal_var=False)[0]
            print("t:", t_update)
            print(Fore.GREEN + f"n_t: {n_t_}, max_t: {np.max(t_update)}")
            l_m = np.abs(t_update) > 4.5
            l_p = n_samp[l_m]
            find_l_flag = True if len(l_p) >= 1 else False
            i += 1
        if find_l_flag:
            print(Fore.RED, Back.RED + f"     For {n_t_} traces, a leakage was found     ")
            print(f"- Leaky point: {l_p}")
        else:
            print(Fore.GREEN, Back.GREEN + f"     For {n_t_} traces, No leakage was found     ")
        return t_update


# gadget_name = ["isw", "dom_indep", "hpc1_opt", "pini1", "pini2"]

if __name__ == "__main__":
    gen_fix_rnd(2, 2000, sig_noise=0)
    nf = "t_test"
    G_n, ppc, n_sh, d, order = "isw", 3, 3, 1, 1
    print(nf)
    # z = T_Test(trsfile_or_npy="trs", two_cycles=False, cy_1=None, cy_2=None, n_shs=n_sh, dset=d,
    #              name_file=nf, G_n=G_n, ppcy=125)
    #
    z = T_Test(trsfile_or_npy="npy", two_cycles=True, cy_1=0, cy_2=1, n_shs=n_sh, dset=d,
               name_file=nf, G_n=G_n, ppcy=ppc)
    # vari = "uni"
    # t = z.uni_variate_Ttest(ord_=order)
    # # # t = t[77 * 125:78 * 125]
    # t = z.multi_variate_Ttest()
    t = z.multi_variate_Ttest_2_cycles_increasing_N(100)
    vari = "multi"
    np.save("t_test_results/t_val.npy", t)
    # t = t[214*ppc:217*ppc]
    [max_p, t_val_max_p, l_point, l_t_val] = Leakage_points(t)
    print("poi:", list(l_point))
    print('[+] Number of leaky points: {} (From {} points)'.format(len(l_point), len(t)))
    print("[+] The percentage of leaky points: {}%".format(len(l_point) / len(t) * 100))
    # lea = set(list((l_point / self.points_per_clock + 1).astype(int)))
    lea = set(list((l_point / ppc).astype(int)))
    lea = list(np.sort(list(set(lea))))
    print("Leaky cycles: \n", lea)
    max_p_cycle = int(max_p / ppc)
    print("-------------------------------------------------------------------------------")
    print("max_p: ", max_p, "\nt_val_max_p: ", t_val_max_p, "\nmax_p_cycle: ", max_p_cycle)
    time_run(start_time)
    plt.plot(t)
    plt.axhline(y=4.5, color='r', linestyle='dashed', linewidth=1)
    plt.axhline(y=-4.5, color='r', linestyle='dashed', linewidth=1)
    plt.gca().xaxis.set_major_locator(mpl.ticker.MaxNLocator(integer=True))
    path = "Images/"
    plot_show(path, "Samples", "t-value",
              "Experimental t-test result: " + f"{order}_Ord_{vari}_" + nf, nf)
