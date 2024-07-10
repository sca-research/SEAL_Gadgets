from TRS_common_func import *


class plot_traces_trs(object):
    def __init__(self, mask_order=1, d=1, name_trs_file="pini2_2", gadget_name="pini2_2", points_per_clock=125):
        # gadget_name = ["isw", "dom_indep", "hpc1_opt", "pini1", "pini2"]
        valid_gadget(gadget_name)
        self.mask_order = mask_order
        self.name_fig = name_trs_file
        self.path_trace = "/media/IWAS\\mahpar/Expansion/Nima/traces/trace_isw/new_traces_isw/"
        self.name_trs_file = self.path_trace + name_trs_file + ".trs"
        self.GN = gadget_name
        self.trs = TRS(self.GN, self.mask_order, self.name_trs_file, d)
        self.n_t = self.trs.number_of_traces
        self.n_s = self.trs.number_of_samples
        self.points_per_clock = points_per_clock
        self.len_p = self.trs.cryptolen
        self.path_image = "Images"
        self.t = self.trs.get_all_traces()
        n_traces = len(self.t)
        n_sample = len(self.t[0])
        if self.n_t != n_traces or self.n_s != n_sample:
            print("[!] Warning: self.n_t != n_traces or self.n_s != n_sample")
        n_cy = int(n_sample / self.points_per_clock)
        print("n_traces:", n_traces, ", n_sample:", n_sample, ", n_cycles:", n_cy)
        print("------------------------------------------------------------------------------")

    def Plot_traces(self):
        # for i in range(self.n_t):
        for i in range(100):
            # Each value is sampled with 16 bits (c.types_int16)
            # values are between -2^15 (32768) , 2^15, all values are 2*2^15= 2^16
            # Voltage V  (-v, +v): from -V to +V= 2*V
            # x = 2*V/2^(16)
            # uint of sample value is voltage: trace[i] * x
            # example: V = 1, 2*1/2^16=2^(-15)
            plt.plot(self.t[i] * (2 ** (-16)))
        plot_show(self.path_image, "Samples", "Voltage",
                  "Traces: " + self.name_fig
                  , "Traces_" + self.name_fig)


if __name__ == "__main__":
    out_a = plot_traces_trs(mask_order=2, d=1, name_trs_file="rand_isw3_V2_20K", gadget_name="isw", points_per_clock=125)
    out_a.Plot_traces()
