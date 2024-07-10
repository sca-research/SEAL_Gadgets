# t-test uni-variate (one sample point):
# first-order
# second-order: mean-free squared one sample point
# z = T_Test(trsfile_or_npy="trs", n_shs=n_sh, name_file=nf, G_n=G_n, ppcy=ppc)
# t = z.uni_variate_Ttest(ord_=order)

# t-test multi-variate (two sample point):
# central-product combinations of two sample points
# two_cycles True if multi-variate t-test else False (uni-variate)
# it can extract poi from first cycle, to reduce the number of combinations

from TRS_common_func import *
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl  # for x axis scale
import time
from scipy.stats import ttest_ind
from random_snr import *

start_time = time.time()


class T_Test(object):
    def __init__(self, trsfile_or_npy="trs", two_cycles=False, cy_1=None, cy_2=None, n_shs=2, dset=1,
                 name_file="pini2_2", G_n="pini2_2", ppcy=125, poi_cy_one=None):
        valid_gadget(G_n)
        self.n_sh = n_shs
        self.G_n = G_n
        self.poi_cy_1 = poi_cy_one
        self.pp_cy = ppcy
        self.trsfile_or_npy = trsfile_or_npy
        self.dicnpy = f"/media/IWAS\\mahpar/T7 Shield/Nima_2_Jan/"
        self.path_trace = self.dicnpy
        self.n_t_found_l = 0
        self.n_t_Not_found_l = 0

        if self.trsfile_or_npy == "trs":
            self.name_trs_file = self.path_trace + name_file + ".trs"
            self.trs = TRS(G_n, self.n_sh - 1, self.name_trs_file, dset)
            self.n_s = self.trs.number_of_samples
            if two_cycles:   # it is not used in uni_variate_Ttest
                print(f"[+] Extracting all traces at cycles: {cy_1} and {cy_2} from trs file")
                self.traces, self.set_ind_f_r = self.trs.get_traces_data_fix_rnd_2_cycles(cy1=cy_1, cy2=cy_2,
                                                                                          ppc=self.pp_cy)
                if poi_cy_one is not None:  # concatenating poi_cy1 and cy2
                    print("- poi_cy_1 + cy_2 is being extracted")
                    extract_poi = np.hstack((poi_cy_one, np.arange(ppcy, 2 * ppcy)))
                    self.traces = self.traces[:, extract_poi]
                else:
                    print("- cy_1 + cy_2 is being extracted")
                print(f" traces.shape: {self.traces.shape}")
            if not two_cycles:
                traces_ = self.trs.get_all_traces()
                print(f" traces.shape: {traces_.shape}")
                [self.fix_t, self.rnd_t, n_f, n_r] = self.trs.extract_trace_f_r_sets(traces_, dt="int16")
                del traces_

        elif self.trsfile_or_npy == "npy":
            print("- The traces and data-set are from npy files ")
            self.NF = name_file
            nD = "t_test_results"
            nD = self.dicnpy + "/t_test_results"
            if two_cycles:   # it is not used in uni_variate_Ttest
                Ln = f"_{self.NF}_cy_{cy_1}_cy_{cy_2}.npy"
                if poi_cy_one is not None:  # concatenating poi_cy1 and cy2
                    print("- poi_cy_1 + cy_2 is being extracted")
                    extract_poi = np.hstack((poi_cy_one, np.arange(ppcy, 2 * ppcy)))
                    self.traces = (np.load(f"{nD}/tr{Ln}"))[:, extract_poi]
                else:
                    print("- cy_1 + cy_2 is being extracted")
                    self.traces = np.load(f"{nD}/tr{Ln}")
                print(f" traces.shape: {self.traces.shape}")
                self.set_ind_f_r = np.load(f"{nD}/data_set{Ln}")
            if not two_cycles:
                traces_ = np.load(f"{nD}/tr_{self.NF}.npy")
                print(f" traces.shape: {traces_.shape}")
                set_ind_f_r = np.load(f"{nD}/data_set_{self.NF}.npy")
                self.fix_t = traces_[set_ind_f_r == 1]
                self.rnd_t = traces_[set_ind_f_r == 0]
                del traces_

        else:
            raise Exception("Please entre a correct file")

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

    def multi_variate_Ttest_2_cycles_increasing_N(self, add_k_t_d=None, start_N_tr=None):
        """ The central-product combination of cy1 and cy2
        It does the t-test on central-product of N traces, and it increased N by add_k_t_d
        add_k_t_d: adding k traces and their corresponding data
        start_N_tr: the first t-test is applying on start_N_tr traces and then add_k_t_d traces are added
        """
        poi_cycl1 = self.poi_cy_1
        print("First-order multi-variate test on two cycles ...")
        n_all_t = len(self.traces)
        n_t_ = add_k_start_n(n_all_t, add_k_t_d, start_N_tr)
        t_update, l_p = 0, np.array([])
        print("poi_cycle1:", poi_cycl1)
        new_ns = ppc ** 2 if poi_cycl1 is None else (len(poi_cycl1) * ppc)
        n_samp = np.arange(new_ns, dtype=np.int32)
        find_l_flag = False
        while not find_l_flag:
            n_t_ += add_k_t_d
            if n_t_ > n_all_t:
                print("n_t in t-test exceeds the length of all_traces")
                find_l_flag = False
                n_t_ -= add_k_t_d
                break
            print("-traces:", n_t_)
            partial_traces = self.traces[:n_t_]
            partial_set_ind_f_r = self.set_ind_f_r[:n_t_]
            fix_t_2 = partial_traces[partial_set_ind_f_r == 1]
            rnd_t_2 = partial_traces[partial_set_ind_f_r == 0]
            del partial_traces
            print("     - Computing central-product fix and rnd traces")
            cp_fix = central_product_2_cycles(fix_t_2, self.pp_cy, poi_cycl1=poi_cycl1)
            del fix_t_2
            cp_rnd = central_product_2_cycles(rnd_t_2, self.pp_cy, poi_cycl1=poi_cycl1)
            del rnd_t_2
            t_update = ttest_ind(cp_fix, cp_rnd, axis=0, equal_var=False)[0]
            # print("t:", t_update)
            print(Fore.GREEN + f"n_t: {n_t_}, max_t: {np.max(t_update)}")
            l_m = np.abs(t_update) > 4.5
            l_p = n_samp[l_m]
            find_l_flag = True if len(l_p) >= 1 else False

        if find_l_flag:
            print(Fore.RED, Back.RED + f"     For {n_t_} traces, a leakage was found     ")
            self.n_t_found_l = n_t_
            print(f"- Leaky point: {l_p}")
        else:
            print(Fore.GREEN, Back.GREEN + f"     For {n_t_} traces, No leakage was found     ")
            self.n_t_Not_found_l = n_t_
        return t_update


# gadget_name = ["isw", "dom_indep", "hpc1_opt", "pini1", "pini2"]

if __name__ == "__main__":
    nf = "dom_indep3_V0_7000K"
    G_n, ppc, n_sh = "dom_indep", 125, 3
    print(nf)

    #########################################################################################
    # # uni-variate t-test
    # order = 1   # 1 or 2
    # vari = "uni"
    # z = T_Test(trsfile_or_npy="trs", n_shs=n_sh, name_file=nf, G_n=G_n, ppcy=ppc)
    # t = z.uni_variate_Ttest(ord_=order)
    #########################################################################################
    # # multi-variate t-test
    vari = "multi"
    add_N_tr = 20000  # for multi-variate
    start_from_n_tr = 2000000  # for multi-variate
    cycle1, cycle2 = 144, 70  # for multi-variate
    # # for two_cycles=False, there no instruction for poi_cy_one. One can edit
    # # extract poi using snr, by choosing traces randomly
    # out_s = Cal_SNR(mask_order=2, d=1, name_trs_file=nf, gadget_name=G_n, points_per_clock=ppc)
    # list_poi_cy1 = out_s.comput_snr_for_random_traces(10000)
    # list_poi_cy1 = [20167, 20168, 20169, 20170, 20171, 20172, 20173, 20174, 20175, 20176, 20177]
    # poi_in_cy1 = list_poi_cy1 if cycle1 == 0 else (np.array([i % (cycle1 * ppc) for i in list_poi_cy1]))
    # poi_in_cy1 = np.arange(38, 55)
    poi_in_cy1 = np.arange(40, 53)
    poi_in_cy1 = np.arange(46, 58)  # dome-indep
    print("poi_in_cy1:", poi_in_cy1)
    z = T_Test(trsfile_or_npy="npy", two_cycles=True, cy_1=cycle1, cy_2=cycle2, n_shs=n_sh, name_file=nf, G_n=G_n,
               ppcy=ppc, poi_cy_one=poi_in_cy1)
    t = z.multi_variate_Ttest_2_cycles_increasing_N(add_k_t_d=add_N_tr, start_N_tr=start_from_n_tr)
    #########################################################################################
    np.save(f"t_test_results/new_t_val_{nf}.npy", t)
    # t = t[214*ppc:217*ppc]
    [max_p, t_val_max_p, l_point, l_t_val] = Leakage_points(t)
    leak_p = list(l_point)
    print("poi:", leak_p)
    n_t_lab = nf
    #########################################################################################
    if vari == "multi":
        if len(leak_p) != 0:
            print(f"n_t_found_l = {z.n_t_found_l}")
            n_t_lab = f"{z.n_t_found_l}"
            print("The leaky points are combinations of the points: [p_in_cy1, p_in_cy2]:")
            leak_is_comb_i_j(leak_p, poi_cy1=poi_in_cy1, pc_c=ppc)
    #########################################################################################
    print('[+] Number of leaky points: {} (From {} points)'.format(len(l_point), len(t)))
    print("[+] The percentage of leaky points: {}%".format(len(l_point) / len(t) * 100))
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
    path = "t_test_results/Images_t_test/"
    plot_show(path, "Samples", "t-statistics", "", nf)
