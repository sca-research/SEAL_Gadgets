# from intermediate_values_n import *
import pprint

from TRS_common_func import *
import parmap
# Checking
# full model: using 9 variables (['a0', 'a1', 'a2', 'b0', 'b1', 'b2', 'r0', 'r1', 'r2']), (2**9) 512 terms.
# Then it removes a variable from the 9 variables, and builds a reduced model:
# reduced model: using 8 variables, (2**8) 256 terms.
# compute the nested f-test
start_time = time.time()
G_n, n_sh, p_p_c, d, threshold = "isw", 3, 125, 0, 5
###################################################################
if __name__ == "__main__":
    name_trs = "coll_isw3_V2_20K"

    # for plotting beta
    create_dir(f"Images/betas/variable_analysis_{name_trs}")
    print("--------------------------------------------\n", name_trs)
    # [abr_SecVal_f_str, abr_SecVal_f_list_op, n_var, n_s, n_cy, n_t, all_traces] = get_info(name_trs , G_n, n_sh, p_p_c)
    [abr_SecVal_f_str, abr_SecVal_f_list_op, n_var, n_s, n_cy, n_t, all_traces] = \
        get_info_(name_trs, G_n, n_sh, p_p_c, bitn=1)

    bad_POI = np.arange(n_s)
    bad_COI = np.arange(int(n_s / 125))

    # all_trace_Badp = all_traces[:, bad_POI]
    all_trace_Badp = all_traces
    del all_traces
    print(f"-------------------------------------------------------------------------------------------------")
    #################################################################################
    # Variable analysis, using collapsed model
    # full model contains all variables:
    beta_m_F, main_val_F = compute_val_beta(all_trace_Badp, abr_SecVal_f_list_op)
    n_ele = len(abr_SecVal_f_str)
    c = []
    pv_all = []
    # abr_SecVal_f_str = ['a0', 'a1', 'a2', 'b0', 'b1', 'b2', 'r0', 'r1', 'r2']
    for i in range(n_ele):
        print(f"REMOVING variable {abr_SecVal_f_str[i]}")
        remove_var = np.delete(abr_SecVal_f_list_op, i, axis=1)
        beta_m_R, main_val_R = compute_val_beta(all_trace_Badp, remove_var)
        p_val = Ftest_p_val(main_val_F, beta_m_F, main_val_R, beta_m_R, all_trace_Badp, n_t)
        plt.plot(p_val)
        [POI, COI] = bad_POI_Ftest(main_val_F, beta_m_F, main_val_R, beta_m_R, all_trace_Badp, n_t, n_s,
                                   bad_POI)
        c.append(COI)
        print("POI:", np.array(POI))
        print("COI:", COI)

    plt.legend(abr_SecVal_f_str, fontsize='x-small', loc="upper left")
    path = "Images"
    plot_show(path, "Samples", "-log10(pv)", "f-test: " + name_trs, "pv_" + name_trs)
    plotttt(c, n_cy, abr_SecVal_f_str, name_trs, None, n_sh, n_exp="Var_analysis")

    time_run(start_time)
