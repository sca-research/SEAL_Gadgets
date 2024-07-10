# using multiprocessing
# t-test uni-variate, one sample point,
# first-order
# second-order: mean-free squared one sample point

from TRS_common_func import *
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl  # for x axis scale
import time
from scipy.stats import ttest_ind
import parmap
import pickle
import os

start_time = time.time()
# nf = sys.argv[1]
nf = "hpc1_opt_3_V0_sh0_sh1_100K_r5_a1_r7_a0"
G_n, ppc, n_sh, d, order = "hpc1_opt", 125, 3, 1, 1


class T_Test_multi_process(object):
    def __init__(self, n_shs=2, dset=1, name_file="pini2_2", G_n="pini2_2", ppcy=125):
        valid_gadget(G_n)
        self.n_sh = n_shs
        self.G_n = G_n
        self.pp_cy = ppcy
        self.path_trace = f"/media/IWAS\\mahpar/T7 Shield/Nima_2_Jan/"
        self.name_trs_file = self.path_trace + name_file + ".trs"
        self.trs = TRS(G_n, self.n_sh - 1, self.name_trs_file, dset)
        self.n_s = self.trs.number_of_samples
        self.n_t = self.trs.number_of_traces
        self.n_cyc = int(self.trs.number_of_samples / self.pp_cy)
        self.NF_ = name_file
        self.nDi = f"{self.path_trace}/multi_proc_UNI_t_test/{self.NF_}"
        create_dir(self.nDi)

    def set_data_ind_f_r(self):
        """this function extracts and saves the set_data, related to fix_random input
         and the returns them"""
        # set_dat needs to be extracted just one time
        fNAME = f"{self.nDi}/set_data_{self.NF_}.npy"
        e = os.path.exists(fNAME)
        if e:
            print(f"\n set_data_{self.NF_}.npy already exists, no need to extract data-set")
            set_data_ind = np.load(fNAME)
        else:
            set_data_ind = np.zeros(self.n_t, np.dtype('B'))
            print("- extracting set_data")
            # for i in tqdm(range(self.n_t)):
            for i in range(self.n_t):
                # data_set == 0: random,  data_set == 1: fix
                set_data_ind[i] = self.trs.trace_root[i].data[0]
        inde_f_tr = set_data_ind == 1
        inde_r_tr = set_data_ind == 0
        np.save(fNAME, set_data_ind)
        del set_data_ind
        return inde_f_tr, inde_r_tr

    def storing_traces_data_fix_rnd_kcy(self, start_cy=None, k_cy=None, p=125):
        """ This function extracts all traces at cycle start_cy=None till k_cy=None from TRS file
        and save them in tr_cy_{sC}_{eC}.npy files.
        """
        sC = start_cy
        eC = start_cy + k_cy
        if sC > self.n_cyc or eC - 1 > self.n_cyc:
            raise Exception("sC > self.n_cyc or eC - 1 > self.n_cyc:,"
                            " in Func: storing_traces_data_fix_rnd_kcy")
        len_chu = p * k_cy
        all_trace = np.zeros((self.n_t, len_chu), np.int16)

        # for i in tqdm(range(self.n_t)):
        for i in range(self.n_t):
            tr = self.trs.get_trace_sample(i)
            all_trace[i] = tr[sC * p:eC * p]
            del tr
        np.save(f"{self.nDi}/tr_cy_{sC}_{eC}.npy", all_trace)

    def uni_variate_Ttest_multi_process(self, ind_f, ind_r, ord_=1, start_cy=None, k_cy=None, p=125):
        """ This function loads tr_cy_{sC}_{eC}.npy files and apply uni-variate t-test on them """
        sC = start_cy
        eC = start_cy + k_cy
        if sC > self.n_cyc or eC - 1 > self.n_cyc:
            raise Exception("sC > self.n_cyc or eC - 1 > self.n_cyc:,"
                            " in Func: uni_variate_Ttest_multi_process")
        len_chu = p * k_cy
        all_trace = np.load(f"{self.nDi}/tr_cy_{sC}_{eC}.npy")
        # checking once:
        if len(all_trace) != self.n_t:
            raise Exception("len(all_trace) != self.n_t")
        if len(all_trace[0]) != len_chu:
            raise Exception("len(all_trace[0]) != len_chu")

        fix_t = all_trace[ind_f]
        rnd_t = all_trace[ind_r]
        del all_trace
        if ord_ == 2:
            # print("Second-order uni-variate test ")
            # print("[+] Separating fixed and random traces")
            # print("[+] Computing mean-free squared fix and rnd traces")
            fix_t_2 = fix_t.astype("float64")
            del fix_t
            mean_fix_t = np.mean(fix_t_2, axis=0)
            fix_t = (fix_t_2 - mean_fix_t) ** 2
            del mean_fix_t
            rnd_t_2 = rnd_t.astype("float64")
            del rnd_t
            mean_rnd_t = np.mean(rnd_t_2, axis=0)
            rnd_t = (rnd_t_2 - mean_rnd_t) ** 2
            del mean_rnd_t
        compute_t_UV = ttest_ind(fix_t, rnd_t, axis=0, equal_var=False)[0]
        del fix_t, rnd_t
        print(f"- cy_{sC}_{eC}")
        os.remove(f"{self.nDi}/tr_cy_{sC}_{eC}.npy")
        return compute_t_UV


def main_ch_UIN_ttest(SC, KC, pcy, Idx_F, Idx_r, order_test,
                      cm=T_Test_multi_process(n_shs=n_sh, dset=d, name_file=nf, G_n=G_n, ppcy=ppc)):
    # print("PASSED: main_ch_UIN_ttest(self, SC, KC, pcy, Idx_F, Idx_r, order_test):")
    cm.storing_traces_data_fix_rnd_kcy(start_cy=SC, k_cy=KC, p=pcy)
    part_t = cm.uni_variate_Ttest_multi_process(Idx_F, Idx_r, ord_=order_test, start_cy=SC, k_cy=KC, p=pcy)
    return part_t


# gadget_name = ["isw", "dom_indep", "hpc1_opt", "pini1", "pini2"]
if __name__ == "__main__":
    k = n_cy_in_chunk = 10
    len_chunk = n_cy_in_chunk * ppc
    z = T_Test_multi_process(n_shs=n_sh, dset=d, name_file=nf, G_n=G_n, ppcy=ppc)
    idx_f_tr, idx_r_tr = z.set_data_ind_f_r()
    n_cy = z.n_cyc
    ch = [count for count in range(0, n_cy, k)]
    all_partial_t = parmap.starmap(main_ch_UIN_ttest, [(count, k, ppc, idx_f_tr, idx_r_tr, order) for count in ch],
                                   pm_parallel=True)
    x = [k for l in all_partial_t for k in l]
    t = np.array(x)
    #########################################################################################
    np.save(f"t_test_results/uni_var_t_val_multi_process_{nf}.npy", t)
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
    #########################################################################################
    time_run(start_time)
    plt.plot(t)
    plt.axhline(y=4.5, color='r', linestyle='dashed', linewidth=1)
    plt.axhline(y=-4.5, color='r', linestyle='dashed', linewidth=1)
    plt.gca().xaxis.set_major_locator(mpl.ticker.MaxNLocator(integer=True))
    path = "t_test_results/Images_t_test"
    plot_show(path, "Samples", "t-statistics", "", nf)
