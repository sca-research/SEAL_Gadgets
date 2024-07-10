import pprint  # print dict
import copy  # copy dict
import pickle
from intermediate_values_n import *
from TRS_common_func import *

start_time = time.time()


def calcNoise(d_val, traces, filt):
    # if the value "filt" does not exist in data: ind[0] =[], then Var = Nan
    ind = np.nonzero(d_val == filt)
    return np.var(traces[ind, :], axis=1)


def calMean(data_val, traces, filt):
    # if the value "filt" does not exist in data: ind[0] =[], then mean = Nan
    ind = np.nonzero(data_val == filt)
    return [np.mean(traces[ind, :], axis=1), len(ind[0])]


def computing_snr(d_val, traces):
    el_n = np.zeros((256, len(traces[0])))
    for data_val in range(256):
        el_n[data_val, :] = calcNoise(d_val, traces, data_val)
    elNoise = np.nanmean(el_n, axis=0)
    mean_traces = np.zeros((256, len(traces[0])))
    n_traces = np.zeros(256)

    for data_val in range(256):
        [mean_traces[data_val, :], n_traces[data_val]] = calMean(d_val, traces, data_val)

    mean_of_means = np.nanmean(mean_traces, axis=0)
    cent_trace_means = (mean_traces - mean_of_means.transpose())
    # p_exp = np.var(cent_trace_means, axis=0)
    s = 0
    for data_val in range(256):
        if np.isnan(cent_trace_means[data_val][0]):
            s += 0
        else:
            s += n_traces[data_val] * cent_trace_means[data_val] ** 2
    p_exp = s / len(traces)

    # print("p_exp:")
    # print("%s" % np.array_str(p_exp, precision=2))

    s_n_r = p_exp / elNoise

    # print("snr:")
    # print("%s" % np.array_str(s_n_r, precision=2))
    # print("____________________________________")
    return [elNoise, p_exp, s_n_r]


def computing_snr_l(data_value, traces, start, end):
    l = end - start
    el_n = np.zeros((l, len(traces[0])))
    for i_point in range(start, end):
        el_n[i_point - start, :] = calcNoise(data_value, traces, i_point)
    elNoise = np.nanmean(el_n, axis=0)
    mean_traces = np.zeros((l, len(traces[0])))
    n_traces = np.zeros(l)

    for i_point in range(start, end):
        [mean_traces[i_point - start, :], n_traces[i_point - start]] = calMean(data_value, traces, i_point)

    mean_of_means = np.nanmean(mean_traces, axis=0)
    cent_trace_means = (mean_traces - mean_of_means.transpose())
    # p_exp = np.var(cent_trace_means, axis=0)
    s = 0
    for i_point in range(start, end):
        if np.isnan(cent_trace_means[i_point - start][0]):
            s += 0
        else:
            s += n_traces[i_point - start] * cent_trace_means[i_point - start] ** 2
    p_exp = s / len(traces)

    # print("p_exp:")
    # print("%s" % np.array_str(p_exp, precision=2))
    # print("el_noise:")
    # print("%s" % np.array_str(elNoise, precision=2))
    s_n_r = p_exp / elNoise

    # print("snr:")
    # print("%s" % np.array_str(s_n_r, precision=2))
    # print("____________________________________")
    return [elNoise, p_exp, s_n_r]


def poi_with_max_snr_per_cycle(s_n_r, p_per_clock, threshold_val):
    """ This extracts the time-point (sample) with max-value snr in one cycle"""
    p_i_o = []
    num_cycles = int(len(s_n_r) / p_per_clock)
    for iterate in range(num_cycles):
        segm = s_n_r[iterate * p_per_clock:(iterate + 1) * p_per_clock]
        ind = np.argmax(segm)
        if segm[ind] > threshold_val:
            p_i_o.append(ind + iterate * p_per_clock)
    return p_i_o


def poi_snr_G_than_th(s_n_r, threshold_val):
    """ This extracts the time-point (sample) with snr > threshold in for the whole trace"""
    p_i_o = np.nonzero(s_n_r > threshold_val)
    return list(p_i_o[0])


class Cal_SNR(object):
    def __init__(self, mask_order=1, d=1, name_trs_file="pini2_2", gadget_name="pini2_2", points_per_clock=125):
        valid_gadget(gadget_name)
        self.mask_order = mask_order
        self.name_fig = name_trs_file
        self.path_trace = "/media/IWAS\mahpar/Expansion/Nima/traces/trace_isw/new_traces_isw/"
        self.name_trs_file = self.path_trace + name_trs_file + ".trs"
        self.gadget_name = gadget_name
        self.trs = TRS(gadget_name, self.mask_order, self.name_trs_file, d)
        self.n_t = self.trs.number_of_traces
        self.n_s = self.trs.number_of_samples
        self.points_per_clock = points_per_clock
        self.len_p = self.trs.cryptolen
        self.distinguisher = d

    def comput_snr(self):
        [t, in_data, out_data] = self.trs.extract_trace_sets()
        # t = centring_trace(t)
        # t  = t[:, 0*125: 1*125]
        # t = centring_trace(t[:, 80*125:90*125])
        [all_im_str, all_im] = Cal_im_value([in_data, out_data], self.distinguisher, self.mask_order + 1,
                                            self.gadget_name)
        n_traces = len(t)
        n_sample = len(t[0])
        if self.n_t != n_traces or self.n_s != n_sample:
            print("[!] Warning: self.n_t != n_traces or self.n_s != n_sample")
        n_cy = int(n_sample / self.points_per_clock)
        print("n_traces:", n_traces, ", n_sample:", n_sample, ", n_cycles:", n_cy)
        print("------------------------------------------------------------------------------")
        print("Computing SNR for {} imm_values\n".format(len(all_im)))

        dic_im = {}
        if len(all_im) != len(all_im_str):
            print(len(all_im))
            print(len(all_im_str))
            print("len(all_im) != len(all_im_str)")

        for i in range(len(all_im_str)):
            dic_im[all_im_str[i]] = all_im[i]

        # print("pprint.pprint(dic_im, sort_dicts=False)")
        # pprint.pprint(dic_im, sort_dicts=False)

        e_p_s_dic = dict.fromkeys(all_im_str, {})
        # print("pprint.pprint(e_p_s_dic, sort_dicts=False)")
        # pprint.pprint(e_p_s_dic, sort_dicts=False)

        eln_pvar_snr_base_dic = {"im_values": [], "val_are_not": [], "el_noise": [], "p_var": [], "snr": [], "poi": []}
        eln_pvar_snr_dic = {}
        for j, (key, value) in enumerate(dic_im.items()):
            del eln_pvar_snr_dic
            eln_pvar_snr_dic = copy.deepcopy(eln_pvar_snr_base_dic)

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

            [el, p, snr] = computing_snr_l(value, t, start_, end_)

            eln_pvar_snr_dic.setdefault("im_values", []).append(value)

            s_v = set(value)
            x = []  # values that are not in in_data
            for i in range(start_, end_):
                i_in_s_v = i in s_v
                if not i_in_s_v:
                    x.append(i)

            eln_pvar_snr_dic.setdefault("val_are_not", []).append(x)
            eln_pvar_snr_dic.setdefault("el_noise", []).append(el)
            eln_pvar_snr_dic.setdefault("p_var", []).append(p)
            eln_pvar_snr_dic.setdefault("snr", []).append(snr)
            # x_scale = [i / self.points_per_clock for i in range(n_sample)]
            # plt.plot(x_scale, snr)
            # snr = snr[125*144: 125*146]
            plt.plot(snr)
            # #
            # eln_pvar_snr_dic.setdefault("poi", []).append(
            #     (poi_with_max_snr_per_cycle(snr, self.points_per_clock, threshold)))

            eln_pvar_snr_dic.setdefault("poi", []).append((poi_snr_G_than_th(snr, threshold)))

            e_p_s_dic[key] = eln_pvar_snr_dic

        # print("pprint.pprint(e_p_s_dic, sort_dicts=False)")
        # pprint.pprint(e_p_s_dic, sort_dicts=False)

        # Saving the e_p_s_dic dict in hard disk
        with open('dis_snr_isw_1.pkl', 'wb') as output:
            # Pickle dictionary using protocol 0.
            pickle.dump(e_p_s_dic, output)

        poi = []
        for j, (key, value) in enumerate(e_p_s_dic.items()):
            poi += e_p_s_dic[key]["poi"][0]
        poi = np.sort(list(set(list(poi))))

        print("____________________________________________________________________________________")
        print("- len_poi =", len(list(poi)), "from", self.n_s, "samples")
        print("poi =", list(poi))
        k = int(self.n_s / self.points_per_clock)
        cycles_of_poi = list((poi / self.points_per_clock).astype(int))
        cycles_of_poi = np.sort(list(set(cycles_of_poi)))
        print("len_cycles_of_poi =", len(list(cycles_of_poi)), "from", k, "cycles")
        print("cycles_of_poi =", list(cycles_of_poi))
        print("\n____________________________________________________________________________________")

        anno = all_im_str

        # plt.legend(anno, fontsize='x-small', bbox_to_anchor=(1.05, 1.0), loc="upper left")
        plt.legend(anno, fontsize='x-small', loc="upper left")

        print(self.gadget_name+"_"+str(self.mask_order+1))
        time_run(start_time)
        #
        # path = "Images/Images_" + self.gadget_name + "/image_" + self.gadget_name + "_" + str(
        #     self.mask_order + 1) + "_shares"
        path = "Images"
        # plot_show(path, x_l, y_l, title_l, name)
        # plot_show(path, "Samples", "snr",
        #           "SNR: " + self.name_fig
        #           , "snr_" + self.name_fig)
        # plot_show(path, "Samples", "SNR",
        #                     "SNR: " + self.name_fig
        #                     , "snr_" + self.name_fig)
        plot_show(path, "Samples", "SNR",
                    "", "snr_" + self.name_fig)

if __name__ == "__main__":
    # name_trs = "input_b_all_1_jk_0_255_12_isw3_V2_30K"
    # # name_trs = str(sys.argv[1])
    # out_s = Cal_SNR(mask_order=2, d=0, name_trs_file=name_trs, gadget_name="isw", points_per_clock=125)
    # out_s.comput_snr()

    list_name = [
    "rand_isw3_V0_20K"
    ]
    ### if value is 3_d_numpy
    for name_trs in list_name:
        # name_trs = str(sys.argv[1])
        out_s = Cal_SNR(mask_order=2, d=0, name_trs_file=name_trs, gadget_name="isw", points_per_clock=125)
        out_s.comput_snr()
