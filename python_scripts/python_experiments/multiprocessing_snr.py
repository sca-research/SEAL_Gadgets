from intermediate_values_n import *
import parmap
import math
import time
start_time = time.time()

mask_order = 2
G_n = gadget_name = "isw"
name_trs_file = "rand_isw3_V0_20K"
distinguisher = 0
points_per_clock = 125  # each clock is sampled with 125 points
path_trace = "/media/IWAS\mahpar/Expansion/Nima/traces/trace_isw/new_traces_isw/"
name_trs_file = path_trace + name_trs_file + ".trs"

# trs = TRS(gadget_name, 2, path_trace + name_trs_file + ".trs", distinguisher)
trs = TRS(gadget_name, mask_order, name_trs_file, distinguisher)

[all_traces, in_data, out_data] = trs.extract_trace_sets()
all_traces = centring_trace(all_traces)

# [all_im_str, all_im] = Cal_im_value([in_data, out_data], distinguisher, n_share, gadget_name)
[all_im_str, all_im] = Cal_im_value([in_data, out_data], distinguisher, mask_order + 1,
                                    gadget_name)
print("Computing SNR for {} imm_values".format(len(all_im)))


def calcNoise(d_val, traces, filt):
    # if the value "filt" does not exist in data: ind[0] =[], then Var = Nan
    ind = np.nonzero(d_val == filt)
    return np.var(traces[ind, :], axis=1)


def calMean(data_val, traces, filt):
    # if the value "filt" does not exist in data: ind[0] =[], then mean = Nan
    ind = np.nonzero(data_val == filt)
    return [np.mean(traces[ind, :], axis=1), len(ind[0])]


dic_im = {}
if len(all_im) != len(all_im_str):
    print(len(all_im))
    print(len(all_im_str))
    print("len(all_im) != len(all_im_str)")
for i in range(len(all_im_str)):
    dic_im[all_im_str[i]] = all_im[i]


def computing_snr_l(data, traces, start, end):
    l = end - start
    el = np.zeros((l, len(traces[0])))
    for i in range(start, end):
        el[i - start, :] = calcNoise(data, traces, i)
    elNoise = np.nanmean(el, axis=0)
    mean_traces = np.zeros((l, len(traces[0])))
    n_traces = np.zeros(l)
    for i in range(start, end):
        [mean_traces[i - start, :], n_traces[i - start]] = calMean(data, traces, i)
    mean_of_means = np.nanmean(mean_traces, axis=0)
    cent_trace_means = (mean_traces - mean_of_means.transpose())
    s = 0
    for i in range(start, end):
        if np.isnan(cent_trace_means[i - start][0]):
            s += 0
        else:
            s += n_traces[i - start] * cent_trace_means[i - start] ** 2
    p_exp = s / len(traces)
    s_n_r = p_exp / elNoise
    return [elNoise, p_exp, s_n_r]


# # i_ch:i_ch+p_p_c
# def individual_poi(s_n_r_partial, threshold, chu):
#     # print(s_n_r_partial)
#     p_o_i = []
#     j = len(s_n_r_partial)
#     k = int(len(s_n_r_partial) / points_per_clock)
#
#     for i in range(k):
#         a = s_n_r_partial[i * points_per_clock:(i + 1) * points_per_clock]  # In each cycle, the max value is selected
#         ind = np.argmax(a)
#         if a[ind] > threshold:
#             p_o_i.append(ind + i * points_per_clock + (j * chu))
#     return p_o_i

# i_ch:i_ch+p_p_c
def individual_poi(s_n_r_partial, threshold, chu):
    # print(s_n_r_partial)
    p_o_i = []
    j = len(s_n_r_partial)
    ind = np.nonzero(s_n_r_partial > threshold)

    for ele in ind[0]:
        p_o_i.append(ele + (j * chu))
    return p_o_i


def main(t, n_chunk, all_poi):
    for j, (key, value) in enumerate(dic_im.items()):  # key is im_str: intermediate values

        threshold = 0.3  # in SNR for selecting poi
        if 'table_a_table_b' in key:
            start_ = 0
            end_ = 2 * 256
            threshold = 0.01  # in SNR for selecting poi
        elif 't_a_t_b_256' in key:
            start_ = 256
            end_ = 3 * 256
        else:
            start_ = 0
            end_ = 256
        [el_np, p_np, snr_np] = \
            computing_snr_l(value, t, start_, end_)
        i_p = individual_poi(snr_np, threshold, n_chunk)

        for ele in i_p:
            if ele is not (all_poi[n_chunk]):
                (all_poi[n_chunk]).append(ele)
    return all_poi[n_chunk]


if __name__ == "__main__":
    s_time = time.time()

    n_traces = len(all_traces)
    n_sample = len(all_traces[0])
    print("n_s:", n_sample)
    n_cy = int(n_sample / points_per_clock)
    print("n_traces:", n_traces, ", n_sample:", n_sample, ", n_cycles:", n_cy)
    print("---------------------------------------")
    n_chunk = math.gcd(n_cy, 10)
    len_chunk = int(n_sample / n_chunk)
    print("len_chunk:", len_chunk)
    print("n_chunk:", n_chunk)

    chunked_traces = np.zeros((n_chunk, n_traces, len_chunk))
    for i in range(n_chunk):
        chunked_traces[i] = all_traces[:, len_chunk * i:len_chunk * i + len_chunk]
    print("Finishing chunking")
    ch = [count for count in range(n_chunk)]
    # all_poi = [[], [], [], [], []]
    all_poi = []
    for i in range(n_chunk):
        all_poi.append([])
    x = parmap.starmap(main, zip(chunked_traces, ch), all_poi, pm_parallel=True)
    print(x)
    print("___________________")
    x = [k for l in x for k in l]
    x = list(np.sort(list(set(list(x)))))
    print("len_poi =", len(x), "from", n_sample, "samples")
    print("poi = ", x)
    print(gadget_name)
    time_run(start_time)
