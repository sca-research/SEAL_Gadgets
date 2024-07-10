from TRS_common_func import *
import numpy as np
import time
start_time = time.time()

# gadget_name = ["isw", "dom_indep", "hpc1_opt", "pini1", "pini2"]
if __name__ == "__main__":
    nf = "dom_indep3_V0_7000K"
    cy_1, cy_2 = 144, 70
    G_n, ppc, n_sh, d = "isw", 125, 3, 1
    path_trace = f"/media/IWAS\mahpar/T7 Shield/Nima_2_Jan/"
    n_f = path_trace + nf + ".trs"
    trs_f = TRS(G_n, n_sh - 1, n_f, d)
    print(f"[+] Extracting all traces at cycles: {cy_1} and {cy_2}")
    Ln = f"_{nf}_cy_{cy_1}_cy_{cy_2}.npy"
    all_traces, all_set_ind_f_r = trs_f.get_traces_data_fix_rnd_2_cycles(cy1=cy_1, cy2=cy_2, ppc=ppc)
    np.save(f"{path_trace}t_test_results/tr{Ln}", all_traces)
    np.save(f"{path_trace}t_test_results/data_set{Ln}", all_set_ind_f_r)
