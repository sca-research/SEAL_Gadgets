import time
from datetime import datetime
import numpy as np
from colorama import init, Fore, Back, Style
import matplotlib.pyplot as plt
import secrets
import random
import sys
import pprint
from matplotlib.patches import Patch


init(autoreset=True)  # initialize colorama

start_time = time.time()

dir_f = "sim_var"
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
    np.save(f"{dir_f}/traces_TVLA_{i}.npy", traces)
    np.save(f"{dir_f}/data_set_TVLA_{i}.npy", d_set)
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
    np.save(f"{dir_f}/traces_ST_{ii}_{kk}_{i}.npy", traces)
    np.save(f"{dir_f}/data_set_ST_{ii}_{kk}_{i}.npy", d_set)
    # return d_set, traces, in_data


def var_(nfile, ord_t):
    traces_ = np.load(f"{dir_f}/traces_{nfile}.npy")
    # print(f" traces.shape: {traces_.shape}")
    set_ind_f_r = np.load(f"{dir_f}/data_set_{nfile}.npy")
    fix_t = traces_[set_ind_f_r == 1]
    rnd_t = traces_[set_ind_f_r == 0]
    del traces_
    if ord_t == 2:
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
    var_f = np.var(fix_t, axis=0)
    var_r = np.var(rnd_t, axis=0)
    return var_f, var_r


# gadget_name = ["isw", "dom_indep", "hpc1_opt", "pini1", "pini2"]

if __name__ == "__main__":
    n_traces = 60
    noise_s = 0
    n_experiments = 50
    n_samples = 7
    # zero_mat = np.zeros((n_experiments, n_samples))
    # G_n, ppc, n_sh, d, order = "isw", 4, 3, 1, 1
    nf_tvla = "TVLA_"
    key_d = {"fix", "rnd"}
    all_v_tvla = {k: np.zeros((n_experiments, n_samples)) for k in key_d}

    nf_st = "ST_"
    pairs_ind_ST = [(0, 1), (0, 2), (1, 2)]
    all_v_st = {sh_i_k: {k: np.zeros((n_experiments, n_samples)) for k in key_d} for sh_i_k in pairs_ind_ST}

    for n_e in range(n_experiments):
        # Generating traces for tvla
        gen_fix_rnd_TVLA(2, n_traces, sig_noise=noise_s, i=n_e)

        # Separating fix and random traces, then computing the variances
        var_f_tvla, var_r_tvla = var_(nf_tvla+f"{n_e}", 2)
        # all_v_tvla["fix"].append(var_f_tvla)
        # all_v_tvla["rnd"].append(var_r_tvla)
        all_v_tvla["fix"][n_e] = var_f_tvla
        all_v_tvla["rnd"][n_e] = var_r_tvla

        # Generating traces for split t-test for shares iii, kkk
        for (iii, kkk) in pairs_ind_ST:
            gen_fix_rnd_ST(iii, kkk, 2, n_traces, sig_noise=noise_s, i=n_e)
            var_f_st, var_r_st = var_(nf_st+f"{iii}_{kkk}_{n_e}", 1)
            # all_v_st[(iii, kkk)]["fix"].append(var_f_st)
            # all_v_st[(iii, kkk)]["rnd"].append(var_r_st)
            all_v_st[(iii, kkk)]["fix"][n_e] = var_f_st
            all_v_st[(iii, kkk)]["rnd"][n_e] = var_r_st


    # Plotting the box plot for the variances (for tvla and all st)
    k = "rnd"
    # print("----------------------------------------------------")
    # print("TVLA: \n")
    # pprint.pprint(all_v_tvla)
    # print("----------------------------------------------------")
    # print("Split t-test: \n")
    # pprint.pprint(all_v_st)
    # print("----------------------------------------------------")
    fig, ax = plt.subplots(figsize=(10, 6))
    # fig, ax = plt.subplots()
    width = 0.12  # Width for each box plot
    p = np.arange(0, 1 * n_samples, 1)
    colors = ['blue', 'green', 'red', 'purple']
    sofst = 0.12
    ann = []
    for i, color in enumerate(colors):
        if i == 0:
            # TVLA
            for j in range(n_samples):
                ax.boxplot(all_v_tvla[k][:, j], positions=[p[j]-sofst], widths=width, patch_artist=True,
                           boxprops=dict(facecolor=color))
            ann.append(Patch(facecolor=color, label='TVLA'))
        else:
            # Split t-test
            offset = width * i * 1.25
            sh_i_k = pairs_ind_ST[i - 1]
            for j in range(n_samples):
                ax.boxplot(all_v_st[sh_i_k][k][:, j], positions=[p[j]-sofst + offset], widths=width,
                           patch_artist=True, boxprops=dict(facecolor=color))
            ann.append(Patch(facecolor=color, label=f"ST shares {sh_i_k}"))

ax.set_xticks(p + width)
ax.set_xticklabels([r"$l_{x_0}$", r"$l_{x_1}$", r"$l_{x_2}$", r"$l_{Random}$",
                    r"$l_{(x_0 \oplus x_1)}$", r"$l_{(x_0 \oplus x_2)}$",
                    r"$l_{(x_1 \oplus x_2)}$"])
ax.set_xlabel('Samples')
ax.set_ylabel('Variance')
# ax.set_title('Comparison of variances for TVLA and Split t-test')
ax.legend(handles=ann)
plt.grid(True)
plt.tight_layout()  # the size
# plt.legend()
plt.savefig(f"Images/comp_Var_tvla_st_simu")
plt.show()