from TRS_common_func import *
import numpy as np


# Computing the intermediate values for snr:
# data in trs file:
# (distinguisher:data_set+) in_a + in_b + mask_a + mask_b + rnd_gadget

######### For computing SNR
# im: InterMediate
def im_data(all_data, ind):
    d = np.zeros(len(all_data))
    for i in range(len(all_data)):
        d[i] = all_data[i][ind]
    return d.astype(np.dtype('B'))


def im_data_xor_2val(v1, v2):
    d = np.zeros(len(v1))
    for i in range(len(v1)):
        d[i] = np.bitwise_xor(v1[i], v2[i])
    return d.astype(np.dtype('B'))


def im_data_xor_3val(v1, v2, v3):
    d = np.zeros(len(v1))
    for i in range(len(v1)):
        d[i] = np.bitwise_xor(np.bitwise_xor(v1[i], v2[i]), v3[i])
    return d.astype(np.dtype('B'))


def table_value(interM_data):
    t_d = np.zeros(len(interM_data))
    for i in range(len(interM_data)):
        t_d[i] = table[interM_data[i]]
    # return t_d.astype(np.dtype(np.int16))
    return t_d.astype(np.dtype('B'))


def im_gf_mul(all_a, all_b):
    d = np.zeros(len(all_a))
    for i in range(len(all_a)):
        d[i] = gf_mult(all_a[i], all_b[i])
    return d.astype(np.dtype('B'))


def Cal_im_value(all_data, d, n_share, gadget_name):
    # all_data = [in_data, out_dat]
    in_data = all_data[0]
    out_data = all_data[1]
    # gadget_name = ["isw", "bbpp", "dom_indep", "hpc1_opt", "pini1", "pini2"]
    valid_gadget(gadget_name)
    n_rnd = n_rand_in_gadget(gadget_name, n_share - 1)
    a, b, r, c = [], [], [], []
    for i in range(n_rnd):
        r.append(im_data(in_data, d + 2 + 2 * n_share + i))

    for i in range(n_share):
        a.append(im_data(in_data, d + 2 + i))
        b.append(im_data(in_data, d + 2 + i + n_share))
        c.append(im_data(out_data, i))

    if n_share == 2:
        input_a = im_data_xor_2val(a[0], a[1])
        input_b = im_data_xor_2val(b[0], b[1])
        output_c = im_data_xor_2val(c[0], c[1])
        if gadget_name == "hpc1_opt":
            rb = [(b[ele] ^ r[0]) for ele in range(0, n_share)]
    if n_share == 3:
        input_a = im_data_xor_3val(a[0], a[1], a[2])
        input_b = im_data_xor_3val(b[0], b[1], b[2])
        output_c = im_data_xor_3val(c[0], c[1], c[2])

        a0_a1 = im_data_xor_2val(a[0], a[1])
        a0_a2 = im_data_xor_2val(a[0], a[2])
        a1_a2 = im_data_xor_2val(a[1], a[2])
        b0_b1 = im_data_xor_2val(b[0], b[1])
        b0_b2 = im_data_xor_2val(b[0], b[2])
        b1_b2 = im_data_xor_2val(b[1], b[2])

        if gadget_name == "hpc1_opt":
            rb = [(b[ele] ^ r[ele]) for ele in range(0, n_share - 1)]
            rb.append((b[2] ^ (r[0] ^ r[1])))
            rb0_rb1 = im_data_xor_2val(rb[0], rb[1])
            rb0_rb2 = im_data_xor_2val(rb[0], rb[2])
            rb1_rb2 = im_data_xor_2val(rb[1], rb[2])

    in_out_str_im = ["input_a", "input_b", "output_c"]
    in_out_im = [input_a, input_b, output_c]

    if gadget_name == "isw" or "dom_indep" or "bbpp":
        t_a, t_b = [], []
        for i in range(n_share):
            t_a.append(table_value(a[i]))
            t_b.append(table_value(b[i]))

        # table[a] + table[b], s = table[a] + table[b] + 256, table[s + 256], ai * bj
        table_a_table_b, t_a_t_b_256, t_ta_tb_256, a_mul_b = [], [], [], []
        for i in range(n_share):
            for j in range(n_share):
                ## as the result of (uint8_v1 + uint8_v2) is uint_8 ((v1+v2)%255)
                ## it is possible to miss some values, we convert the values to np.int16
                x = np.asarray(t_a[i], np.int16) + np.asarray(t_b[j], np.int16)
                table_a_table_b.append(x)
                t_a_t_b_256.append(x + 256)
                t_ta_tb_256.append(table_value(x + 256))
                a_mul_b.append(im_gf_mul(a[i], b[j]))
        del x
        if n_share == 2:
            common_im_str_isw_dom = ["a[0]", "a[1]", "b[0]", "b[1]", "r[0]",
                                     "t_a[0]", "t_a[1]", "t_b[0]", "t_b[1]",
                                     "table_a_table_b[0]", "table_a_table_b[1]",
                                     "table_a_table_b[2]", "table_a_table_b[3]",
                                     "t_ta_tb_256[0]", "t_ta_tb_256[1]",
                                     "t_ta_tb_256[2]", "t_ta_tb_256[3]",
                                     "a_mul_b[0]", "a_mul_b[1]", "a_mul_b[2]", "a_mul_b[3]"
                                     ]
            common_im_isw_dom = [a[0], a[1], b[0], b[1], r[0],
                                 t_a[0], t_a[1], t_b[0], t_b[1],
                                 table_a_table_b[0], table_a_table_b[1],
                                 table_a_table_b[2], table_a_table_b[3],
                                 t_ta_tb_256[0], t_ta_tb_256[1],
                                 t_ta_tb_256[2], t_ta_tb_256[3],
                                 a_mul_b[0], a_mul_b[1], a_mul_b[2], a_mul_b[3],
                                 ]

        if n_share == 3:

            if gadget_name == "bbpp":
                r_vec_str = ["r[0]", "r[1]"]
                r_vec_imm = [r[0], r[1]]
            else:
                r_vec_str = ["r[0]", "r[1]", "r[2]"]
                r_vec_imm = [r[0], r[1], r[2]]
            common_im_str_isw_dom = ["a[0]", "a[1]", "a[2]",
                                     "a0_a1", "a0_a2", "a1_a2",
                                     "b[0]", "b[1]", "b[2]",
                                     "b0_b1", "b0_b2", "b1_b2"] + r_vec_str + \
                                    ["t_a[0]", "t_a[1]", "t_a[2]", "t_b[0]", "t_b[1]", "t_b[2]",
                                     "table_a_table_b[0]", "table_a_table_b[1]", "table_a_table_b[2]",
                                     "table_a_table_b[3]", "table_a_table_b[4]", "table_a_table_b[5]",
                                     "table_a_table_b[6]", "table_a_table_b[7]", "table_a_table_b[8]",
                                     "t_ta_tb_256[0]", "t_ta_tb_256[1]", "t_ta_tb_256[2]",
                                     "t_ta_tb_256[3]", "t_ta_tb_256[4]", "t_ta_tb_256[5]",
                                     "t_ta_tb_256[6]", "t_ta_tb_256[7]", "t_ta_tb_256[8]",
                                     "a_mul_b[0]", "a_mul_b[1]", "a_mul_b[2]", "a_mul_b[3]",
                                     "a_mul_b[4]", "a_mul_b[5]", "a_mul_b[6]", "a_mul_b[7]", "a_mul_b[8]"
                                     ]
            common_im_isw_dom = [a[0], a[1], a[2],
                                 a0_a1, a0_a2, a1_a2,
                                 b[0], b[1], b[2],
                                 b0_b1, b0_b2, b1_b2] + r_vec_imm + \
                                [t_a[0], t_a[1], t_a[2], t_b[0], t_b[1], t_b[2],
                                 table_a_table_b[0], table_a_table_b[1], table_a_table_b[2],
                                 table_a_table_b[3], table_a_table_b[4], table_a_table_b[5],
                                 table_a_table_b[6], table_a_table_b[7], table_a_table_b[8],
                                 t_ta_tb_256[0], t_ta_tb_256[1], t_ta_tb_256[2],
                                 t_ta_tb_256[3], t_ta_tb_256[4], t_ta_tb_256[5],
                                 t_ta_tb_256[6], t_ta_tb_256[7], t_ta_tb_256[8],
                                 a_mul_b[0], a_mul_b[1], a_mul_b[2], a_mul_b[3],
                                 a_mul_b[4], a_mul_b[5], a_mul_b[6], a_mul_b[7], a_mul_b[8]
                                 ]

            del r_vec_str, r_vec_imm

    if gadget_name == "hpc1_opt":
        t_a, t_rb = [], []
        for i in range(n_share):
            t_a.append(table_value(a[i]))
            t_rb.append(table_value(rb[i]))

        # table[a] + table[b], s = table[a] + table[b] + 256, table[s + 256], ai * bj
        table_a_table_rb, t_a_t_rb_256, t_ta_trb_256, a_mul_rb = [], [], [], []
        for i in range(n_share):
            for j in range(n_share):
                ## as the result of (uint8_v1 + uint8_v2) is uint_8 ((v1+v2)%255)
                ## it is possible to miss some values, we convert the values to np.int16
                x = np.asarray(t_a[i], np.int16) + np.asarray(t_rb[j], np.int16)
                table_a_table_rb.append(x)
                t_a_t_rb_256.append(x + 256)
                t_ta_trb_256.append(table_value(x + 256))
                a_mul_rb.append(im_gf_mul(a[i], rb[j]))
        del x
        if n_share == 2:
            common_im_str_hpc1_opt = ["a[0]", "a[1]", "b[0]", "b[1]", "r[0]", "r[1]",
                                      "rb[0]", "rb[1]",
                                      "t_a[0]", "t_a[1]", "t_rb[0]", "t_rb[1]",
                                      "table_a_table_rb[0]", "table_a_table_rb[1]",
                                      "table_a_table_rb[2]", "table_a_table_rb[3]",
                                      "t_ta_trb_256[0]", "t_ta_trb_256[1]",
                                      "t_ta_trb_256[2]", "t_ta_trb_256[3]",
                                      "a_mul_rb[0]", "a_mul_rb[1]", "a_mul_rb[2]", "a_mul_rb[3]"
                                      ]
            common_im_hpc1_opt = [a[0], a[1], b[0], b[1], r[0], r[1],
                                  rb[0], rb[1],
                                  t_a[0], t_a[1], t_rb[0], t_rb[1],
                                  table_a_table_rb[0], table_a_table_rb[1],
                                  table_a_table_rb[2], table_a_table_rb[3],
                                  t_ta_trb_256[0], t_ta_trb_256[1],
                                  t_ta_trb_256[2], t_ta_trb_256[3],
                                  a_mul_rb[0], a_mul_rb[1], a_mul_rb[2], a_mul_rb[3],
                                  ]

        if n_share == 3:
            common_im_str_hpc1_opt = ["a[0]", "a[1]", "a[2]",
                                      "a0_a1", "a0_a2", "a1_a2",
                                      "b[0]", "b[1]", "b[2]",
                                      "b0_b1", "b0_b2", "b1_b2",
                                      "r[0]", "r[1]", "r[2]",
                                      "rb[0]", "rb[1]", "rb[2]",
                                      "rb0_rb1", "rb0_rb2", "rb1_rb2",
                                      "t_a[0]", "t_a[1]", "t_a[2]", "t_b[0]", "t_b[1]", "t_b[2]",
                                      "table_a_table_b[0]", "table_a_table_b[1]", "table_a_table_b[2]",
                                      "table_a_table_b[3]", "table_a_table_b[4]", "table_a_table_b[5]",
                                      "table_a_table_b[6]", "table_a_table_b[7]", "table_a_table_b[8]",
                                      "t_ta_tb_256[0]", "t_ta_tb_256[1]", "t_ta_tb_256[2]",
                                      "t_ta_tb_256[3]", "t_ta_tb_256[4]", "t_ta_tb_256[5]",
                                      "t_ta_tb_256[6]", "t_ta_tb_256[7]", "t_ta_tb_256[8]",
                                      "a_mul_b[0]", "a_mul_b[1]", "a_mul_b[2]", "a_mul_b[3]",
                                      "a_mul_b[4]", "a_mul_b[5]", "a_mul_b[6]", "a_mul_b[7]", "a_mul_b[8]"
                                      ]
            common_im_hpc1_opt = [a[0], a[1], a[2],
                                  a0_a1, a0_a2, a1_a2,
                                  b[0], b[1], b[2],
                                  b0_b1, b0_b2, b1_b2,
                                  r[0], r[1], r[2],
                                  rb[0], rb[1], rb[2],
                                  rb0_rb1, rb0_rb2, rb1_rb2,
                                  t_a[0], t_a[1], t_a[2], t_b[0], t_b[1], t_b[2],
                                  table_a_table_b[0], table_a_table_b[1], table_a_table_b[2],
                                  table_a_table_b[3], table_a_table_b[4], table_a_table_b[5],
                                  table_a_table_b[6], table_a_table_b[7], table_a_table_b[8],
                                  t_ta_tb_256[0], t_ta_tb_256[1], t_ta_tb_256[2],
                                  t_ta_tb_256[3], t_ta_tb_256[4], t_ta_tb_256[5],
                                  t_ta_tb_256[6], t_ta_tb_256[7], t_ta_tb_256[8],
                                  a_mul_b[0], a_mul_b[1], a_mul_b[2], a_mul_b[3],
                                  a_mul_b[4], a_mul_b[5], a_mul_b[6], a_mul_b[7], a_mul_b[8]
                                  ]

        all_im_str = common_im_str_hpc1_opt + in_out_str_im
        all_im = common_im_hpc1_opt + in_out_im
        del common_im_str_hpc1_opt, in_out_str_im, common_im_hpc1_opt, in_out_im

    if gadget_name == "isw":
        if n_share == 2:
            # c0 = (a0 * b0) ^ rnd
            ####################################################################################################
            c0 = im_data_xor_2val(a_mul_b[0], r[0])
            # c1 = [((a0 * b1) ^ rnd) ^ (a1 * b0)] ^ (a1 * b1)
            ####################################################################################################
            # (a0 * b1) ^ rnd0
            a0b1_x_r0 = im_data_xor_2val(a_mul_b[1], r[0])
            a0b1_x_r0_x_a1b0 = im_data_xor_2val(a0b1_x_r0, a_mul_b[2])
            # c1 = [((a0 * b1) ^ rnd) ^ (a1 * b0)] ^ (a1 * b1)
            c1 = im_data_xor_2val(a0b1_x_r0_x_a1b0, a_mul_b[3])

            x = ["c0", "a0b1_x_r0", "a0b1_x_r0_x_a1b0", "c1"]
            y = [c0, a0b1_x_r0, a0b1_x_r0_x_a1b0, c1]

        if n_share == 3:
            # c0 = (a0 * b0) ^ rnd0 ^ rnd1
            # c1 = [(rnd0 ^ (a0 * b1)) ^ (a1 * b0)] ^ (a1 * b1) ^ rnd2
            # c2 = [(rnd1 ^ (a0 * b2)) ^ (a2 * b0)] ^ [(rnd2 ^ (a1 * b2)) ^ (a2 * b1)] ^ (a2 * b2)
            # c0 = (a0 * b0) ^ rnd0 ^ rnd1
            ####################################################################################################
            # (a0 * b0) ^ rnd0
            a0b0_x_r0 = im_data_xor_2val(a_mul_b[0], r[0])
            # c0 = (a0 * b0) ^ rnd0 ^ rnd1
            a0b0_x_r0_x_r1 = im_data_xor_2val(a0b0_x_r0, r[1])
            c0 = a0b0_x_r0_x_r1
            # c1 = [(rnd0 ^ (a0 * b1)) ^ (a1 * b0)] ^ (a1 * b1) ^ rnd2
            ####################################################################################################
            # rnd0 ^ (a0 * b1)
            a0b1_x_r0 = im_data_xor_2val(a_mul_b[1], r[0])
            # (rnd0 ^ (a0 * b1)) ^ (a1 * b0)
            a0b1_x_r0_x_a1b0 = im_data_xor_2val(a0b1_x_r0, a_mul_b[3])
            # [(rnd0 ^ (a0 * b1)) ^ (a1 * b0)] ^ (a1 * b1)
            a0b1_x_r0_x_a1b0_x_a1b1 = im_data_xor_2val(a0b1_x_r0_x_a1b0, a_mul_b[4])
            #  c1 = [(rnd0 ^ (a0 * b1)) ^ (a1 * b0)] ^ (a1 * b1) ^ rnd2
            c1 = im_data_xor_2val(a0b1_x_r0_x_a1b0_x_a1b1, r[2])
            # c2 = [(rnd1 ^ (a0 * b2)) ^ (a2 * b0)] ^ [(rnd2 ^ (a1 * b2)) ^ (a2 * b1)] ^ (a2 * b2)
            ####################################################################################################
            # rnd1 ^ (a0 * b2)
            a0b2_x_r1 = im_data_xor_2val(a_mul_b[2], r[1])
            # (rnd1 ^ (a0 * b2)) ^ (a2 * b0)
            a0b2_x_r1_x_a2b0 = im_data_xor_2val(a0b2_x_r1, a_mul_b[6])
            # rnd2 ^ (a1 * b2)
            a1b2_x_r2 = im_data_xor_2val(a_mul_b[5], r[2])
            # rnd2 ^ (a1 * b2)) ^ (a2 * b1)
            a1b2_x_r2_x_a2b1 = im_data_xor_2val(a1b2_x_r2, a_mul_b[7])
            # [(rnd1 ^ (a0 * b2)) ^ (a2 * b0)] ^ [(rnd2 ^ (a1 * b2)) ^ (a2 * b1)]
            a0b2_x_r1_x_a2b0_x_a1b2_x_r2_x_a2b1 = im_data_xor_2val(a0b2_x_r1_x_a2b0, a1b2_x_r2_x_a2b1)
            # c2
            c2 = im_data_xor_2val(a0b2_x_r1_x_a2b0_x_a1b2_x_r2_x_a2b1, a_mul_b[8])

            x = [
                "a0b0_x_r0", "c0",
                "a0b1_x_r0", "a0b1_x_r0_x_a1b0", "a0b1_x_r0_x_a1b0_x_a1b1", "c1",
                "a0b2_x_r1", "a0b2_x_r1_x_a2b0", "a1b2_x_r2", "a1b2_x_r2_x_a2b1",
                "a0b2_x_r1_x_a2b0_x_a1b2_x_r2_x_a2b1", "c2"
            ]

            y = [
                a0b0_x_r0, c0,
                a0b1_x_r0, a0b1_x_r0_x_a1b0, a0b1_x_r0_x_a1b0_x_a1b1, c1,
                a0b2_x_r1, a0b2_x_r1_x_a2b0, a1b2_x_r2, a1b2_x_r2_x_a2b1,
                a0b2_x_r1_x_a2b0_x_a1b2_x_r2_x_a2b1, c2
            ]
        #

            b0_xor_r0 = im_data_xor_2val(b[0], r[0])
            a0_xor_b0_xor_r0 = im_data_xor_2val(a[0], b0_xor_r0)
            a1_xor_b0 = im_data_xor_2val(a[1], b[0])
            a2_xor_r1 = im_data_xor_2val(a[2], r[1])
            r1_xor_b0 = im_data_xor_2val(r[1], b[0])
            a0_a1_b0 = im_data_xor_2val(a0_a1, b[0])
        # # The full model for F-test
        # # all_im_str = ["a[0]", "a[1]", "a[2]", "b[0]", "b[1]", "b[2]", "r[0]", "r[1]", "r[2]"]
        # # all_im = [a[0], a[1], a[2], b[0], b[1], b[2], r[0], r[1], r[2]]
        # all_im_str = ["a[0]", "a[1]", "a[2]", "b[0]", "b[1]", "b[2]"]
        # all_im = [a[0], a[1], a[2], b[0], b[1], b[2]]
        # The full model for F-test
        # all_im_str = ["a[0]", "a[1]"
        #               ]
        # all_im = [a[0], a[1]
        #           ]

        # # The full model for F-test
        # all_im_str = [ "a[2]", "b[0]", "b[1]", "b[2]", "r[0]", "r[1]", "r[2]"
        #               ]
        # all_im = [a[2], b[0], b[1], b[2], r[0], r[1], r[2]
        #           ]
        # all_im_str = ["b[0]", "b[1]", "b[2]"
        #               ]
        # all_im = [b[0], b[1], b[2]
        #           ]

        # # # The full model for F-test
        # all_im_str = ["a0_a2"
        #               ]
        # all_im = [a1_a2
        #           ]
        #
        # all_im_str = common_im_str_isw_dom + x + in_out_str_im
        # # all_im = common_im_isw_dom + y + in_out_im
        all_im_str = ["a[0]", "a[1]", "a[2]", "b[0]", "b[1]", "b[2]", "r[0]", "r[1]", "r[2]"]
        all_im = [a[0], a[1], a[2], b[0], b[1], b[2], r[0], r[1], r[2]]
        # print("[+] all_im:\n", all_im_str)

        # all_im_str = ["a[0]", "a[1]", "a[2]", "b[0]", "b[1]"]
        # all_im = [a[0], a[1], a[2], b[0], b[1]]
        # all_im_str = ["a[0]", "a1_a2"]
        # all_im = [a[0], a1_a2]
        # all_im_str = ["a[0]"]
        # all_im = [a[0]]
        print("[+] all_im:\n", all_im_str)

        del common_im_str_isw_dom, x, in_out_str_im, common_im_isw_dom, y, in_out_im

    if gadget_name == "bbpp":
        if n_share == 2:
            # c0 = (a0 * b0) ^ rnd ^ (a0 * b1) ^ (a1 * b0)
            ####################################################################################################
            # (a0 * b0) ^ rnd0
            a0b0_x_r0 = im_data_xor_2val(a_mul_b[0], r[0])
            a0b0_x_r0_x_a0b1 = im_data_xor_2val(a0b0_x_r0, a_mul_b[1])
            c0 = im_data_xor_2val(a0b0_x_r0_x_a0b1, a_mul_b[2])

            # c1 = (a1 * b1) ^ rnd
            ####################################################################################################
            c1 = im_data_xor_2val(a_mul_b[3], r[0])

            x = ["a0b0_x_r0", "a0b0_x_r0_x_a0b1", "c0", "c1"]
            y = [a0b0_x_r0, a0b0_x_r0_x_a0b1, c0, c1]

        if n_share == 3:
            # c0 = (a0 * b0) ^ rnd0 ^ (a0 * b2) ^ (a2 * b0)
            # c1 = (a1 * b1) ^ rnd1 ^ (a0 * b1) ^ (a1 * b0)
            # c2 = (a2 * b2) ^ rnd0 ^ rnd1 ^ (a1 * b2) ^ (a2 * b1)
            # c0 = (a0 * b0) ^ rnd0 ^ (a0 * b2) ^ (a2 * b0)
            ####################################################################################################
            # (a0 * b0) ^ rnd0
            a0b0_x_r0 = im_data_xor_2val(a_mul_b[0], r[0])
            a0b0_x_r0_x_a0b2 = im_data_xor_2val(a0b0_x_r0, a_mul_b[2])
            a0b0_x_r0_x_a0b2_x_a2b0 = im_data_xor_2val(a0b0_x_r0_x_a0b2, a_mul_b[6])
            c0 = a0b0_x_r0_x_a0b2_x_a2b0
            # c1 = (a1 * b1) ^ rnd1 ^ (a0 * b1) ^ (a1 * b0)
            ####################################################################################################
            # (a1 * b1) ^ rnd1
            a1b1_x_r1 = im_data_xor_2val(a_mul_b[4], r[1])
            a1b1_x_r1_x_a0b1 = im_data_xor_2val(a1b1_x_r1, a_mul_b[1])
            a1b1_x_r1_x_a0b1_x_a1b0 = im_data_xor_2val(a1b1_x_r1_x_a0b1, a_mul_b[3])
            c1 = a1b1_x_r1_x_a0b1_x_a1b0
            # c2 = (a2 * b2) ^ rnd0 ^ rnd1 ^ (a1 * b2) ^ (a2 * b1)
            ####################################################################################################
            # (a2 * b2) ^ rnd0
            a2b2_x_r0 = im_data_xor_2val(a_mul_b[8], r[0])
            a2b2_x_r0_x_r1 = im_data_xor_2val(a2b2_x_r0, r[1])
            a2b2_x_r0_x_r1_x_a1b2 = im_data_xor_2val(a2b2_x_r0_x_r1, a_mul_b[5])
            a1b1_x_r1_x_a0b1_x_a1b0 = im_data_xor_2val(a2b2_x_r0_x_r1_x_a1b2, a_mul_b[7])
            c2 = a1b1_x_r1_x_a0b1_x_a1b0

            x = [
                "a0b0_x_r0", "a0b0_x_r0_x_a0b2", "c0",
                "a1b1_x_r1", "a1b1_x_r1_x_a0b1", "c1",
                "a2b2_x_r0", "a2b2_x_r0_x_r1", "a2b2_x_r0_x_r1_x_a1b2", "c2"
            ]

            y = [
                a0b0_x_r0, a0b0_x_r0_x_a0b2, c0,
                a1b1_x_r1, a1b1_x_r1_x_a0b1, c1,
                a2b2_x_r0, a2b2_x_r0_x_r1, a2b2_x_r0_x_r1_x_a1b2, c2
            ]

        all_im_str = common_im_str_isw_dom + x + in_out_str_im
        all_im = common_im_isw_dom + y + in_out_im
        del common_im_str_isw_dom, x, in_out_str_im, common_im_isw_dom, y, in_out_im

        all_im_str = ["a[0]", "a[1]", "a0_a1"]
        all_im = [a[0], a[1], a0_a1]
        # all_im_str = ["a0_a1"]
        # all_im = [a0_a1]

    if gadget_name == "dom_indep":

        if n_share == 2:
            # c0 = (a0 * b0) ^ [(a0 * b1) ^ rnd0]
            ####################################################################################################
            a0b1_x_r0 = im_data_xor_2val(a_mul_b[1], r[0])
            c0 = im_data_xor_2val(a_mul_b[0], a0b1_x_r0)

            # c1 = [(a1 * b0) + rnd0] ^ (a1 * b1)
            ####################################################################################################
            # (a1 * b0) ^ rnd0
            a1b0_x_r0 = im_data_xor_2val(a_mul_b[2], r[0])
            c1 = im_data_xor_2val(a1b0_x_r0, a_mul_b[3])

            x = ["a0b1_x_r0", "c0", "a1b0_x_r0", "c1"]
            y = [a0b1_x_r0, c0, a1b0_x_r0, c1]

        if n_share == 3:
            # c0 = (a0 * b0) ^ [(a0 * b1) ^ rnd0] ^ [(a0 * b2) ^ rnd1]
            ####################################################################################################
            # (a0 * b1) ^ rnd0
            a0b1_x_r0 = im_data_xor_2val(a_mul_b[1], r[0])
            # (a0 * b2) ^ rnd1
            a0b2_x_r1 = im_data_xor_2val(a_mul_b[2], r[1])
            a0b0_x_a0b1_x_r0 = im_data_xor_2val(a_mul_b[0], a0b1_x_r0)
            c0 = im_data_xor_2val(a0b0_x_a0b1_x_r0, a0b2_x_r1)

            # c1 = [(a1 * b0) ^ rnd0] ^ (a1 * b1) ^ [(a1 * b2) ^ rnd2]
            ####################################################################################################
            # (a1 * b0) ^ rnd0
            a1b0_x_r0 = im_data_xor_2val(a_mul_b[3], r[0])
            # (a1 * b2) ^ rnd2
            a1b2_x_r2 = im_data_xor_2val(a_mul_b[5], r[2])
            a1b1_x_a1b0_x_r0 = im_data_xor_2val(a_mul_b[4], a1b0_x_r0)
            c1 = im_data_xor_2val(a1b1_x_a1b0_x_r0, a1b2_x_r2)
            # c2 = [(a2 * b0) ^ rnd1] ^ [(a2 * b1) ^ rnd2] ^ (a2 * b2)
            ####################################################################################################
            # (a2 * b0) ^ rnd1
            a2b0_x_r1 = im_data_xor_2val(a_mul_b[6], r[1])
            # (a2 * b1) ^ rnd2]
            a2b1_x_r2 = im_data_xor_2val(a_mul_b[7], r[2])
            a2b0_x_r1_x_a2b1_x_r2 = im_data_xor_2val(a2b0_x_r1, a2b1_x_r2)
            c2 = im_data_xor_2val(a_mul_b[8], a2b0_x_r1_x_a2b1_x_r2)

            x = ["a0b1_x_r0", "a0b2_x_r1", "a0b0_x_a0b1_x_r0", "c0",
                 "a1b0_x_r0", "a1b2_x_r2", "a1b1_x_a1b0_x_r0", "c1",
                 "a2b0_x_r1", "a2b1_x_r2", "a2b0_x_r1_x_a2b1_x_r2", "c2"
                 ]
            y = [a0b1_x_r0, a0b2_x_r1, a0b0_x_a0b1_x_r0, c0,
                 a1b0_x_r0, a1b2_x_r2, a1b1_x_a1b0_x_r0, c1,
                 a2b0_x_r1, a2b1_x_r2, a2b0_x_r1_x_a2b1_x_r2, c2
                 ]

        all_im_str = common_im_str_isw_dom + x + in_out_str_im
        all_im = common_im_isw_dom + y + in_out_im

        all_im_str = ["a[1]"]
        all_im = [a[1]]
        print("[+] all_im:\n", all_im_str)

        # all_im_str = common_im_str_isw_dom + x
        # all_im = common_im_isw_dom + y
        del common_im_str_isw_dom, x, in_out_str_im, common_im_isw_dom, y, in_out_im
###########################################################################
        # # # # The full model for F-test
        # all_im_str = ["a[0]", "a[1]", "a[2]", "b[0]", "b[1]", "b[2]", "r[0]", "r[1]", "r[2]"
        #               ]
        # all_im = [a[0], a[1], a[2], b[0], b[1], b[2], r[0], r[1], r[2]
        #           ]
        # all_im_str = ["a[0]", "a[1]", "a[2]", "b[0]", "b[1]", "b[2]", "r[0]", "r[1]", "r[2]"
        #               ]
        # all_im = [a[0], a[1], a[2], b[0], b[1], b[2], r[0], r[1], r[2]
        #           ]
        #
        # # The full model for F-test
        # all_im_str = ["a[0]", "a[1]", "a[2]"
        #               ]
        # all_im = [a[0], a[1], a[2]
        #           ]
        # # all_im_str = ["b[0]", "b[1]", "b[2]"
        # #               ]
        # # all_im = [b[0], b[1], b[2]
        # #           ]
        #
        # # # # The full model for F-test
        # # all_im_str = ["a0_a2"
        # #               ]
        # # all_im = [a1_a2
        # #           ]


    ### has to be completed
    if gadget_name == "pini1":
        # t_a, t_a_1, t_b_r = [], [], []
        # for i in range(n_share):
        #     t_a.append(table_value(a[i] ^ 1))
        #     t_rb.append(table_value(b[i]) )

        # table[a] + table[b], s = table[a] + table[b] + 256, table[s + 256], ai * bj
        table_a_table_rb, t_a_t_rb_256, t_ta_trb_256, a_mul_b = [], [], [], []
        # for i in range(n_share):
        #     for j in range(n_share):
        ## as the result of (uint8_v1 + uint8_v2) is uint_8 ((v1+v2)%255)
        ## it is possible to miss some values, we convert the values to np.int16
        # x = np.asarray(t_a[i], np.int16) + np.asarray(t_rb[j], np.int16)
        # table_a_table_rb.append(x)
        # t_a_t_rb_256.append(x + 256)
        # t_ta_trb_256.append(table_value(x + 256))
        #         a_mul_b.append(im_gf_mul(a[i], b[j]))
        # del x
        if n_share == 2:
            #
            common_im_str_pini1 = ["input_b"
                                   ]
            common_im_pini1 = [input_b
                               ]

            all_im_str = common_im_str_pini1
            all_im = common_im_pini1

            # all_im_str = common_im_str_pini1 + in_out_str_im
            # all_im = common_im_pini1 + in_out_im

            del common_im_str_pini1, in_out_str_im, common_im_pini1, in_out_im

        if n_share == 3:
            common_im_str_hpc1_opt = ["a[0]", "a[1]", "a[2]",
                                      "a0_a1", "a0_a2", "a1_a2",
                                      "b[0]", "b[1]", "b[2]",
                                      "b0_b1", "b0_b2", "b1_b2",
                                      "r[0]", "r[1]", "r[2]",
                                      "rb[0]", "rb[1]", "rb[2]",
                                      "rb0_rb1", "rb0_rb2", "rb1_rb2",
                                      "t_a[0]", "t_a[1]", "t_a[2]", "t_b[0]", "t_b[1]", "t_b[2]",
                                      "table_a_table_b[0]", "table_a_table_b[1]", "table_a_table_b[2]",
                                      "table_a_table_b[3]", "table_a_table_b[4]", "table_a_table_b[5]",
                                      "table_a_table_b[6]", "table_a_table_b[7]", "table_a_table_b[8]",
                                      "t_ta_tb_256[0]", "t_ta_tb_256[1]", "t_ta_tb_256[2]",
                                      "t_ta_tb_256[3]", "t_ta_tb_256[4]", "t_ta_tb_256[5]",
                                      "t_ta_tb_256[6]", "t_ta_tb_256[7]", "t_ta_tb_256[8]",
                                      "a_mul_b[0]", "a_mul_b[1]", "a_mul_b[2]", "a_mul_b[3]",
                                      "a_mul_b[4]", "a_mul_b[5]", "a_mul_b[6]", "a_mul_b[7]", "a_mul_b[8]"
                                      ]
            common_im_hpc1_opt = [a[0], a[1], a[2],
                                  a0_a1, a0_a2, a1_a2,
                                  b[0], b[1], b[2],
                                  b0_b1, b0_b2, b1_b2,
                                  r[0], r[1], r[2],
                                  rb[0], rb[1], rb[2],
                                  rb0_rb1, rb0_rb2, rb1_rb2,
                                  t_a[0], t_a[1], t_a[2], t_b[0], t_b[1], t_b[2],
                                  table_a_table_b[0], table_a_table_b[1], table_a_table_b[2],
                                  table_a_table_b[3], table_a_table_b[4], table_a_table_b[5],
                                  table_a_table_b[6], table_a_table_b[7], table_a_table_b[8],
                                  t_ta_tb_256[0], t_ta_tb_256[1], t_ta_tb_256[2],
                                  t_ta_tb_256[3], t_ta_tb_256[4], t_ta_tb_256[5],
                                  t_ta_tb_256[6], t_ta_tb_256[7], t_ta_tb_256[8],
                                  a_mul_b[0], a_mul_b[1], a_mul_b[2], a_mul_b[3],
                                  a_mul_b[4], a_mul_b[5], a_mul_b[6], a_mul_b[7], a_mul_b[8]
                                  ]

    ## Checking shares of c (c = a * b)
    if n_share == 2:
        # if (c0 != c[0]).all() or (c1 != c[1]).all():
        cond = (np.array_equal(c0, c[0])) or (np.array_equal(c1, c[1]))
        if not cond:
            raise Exception("\n - c0 !== c[0] or c1 !== c[1] ")
    if n_share == 3:
        # if (c0 != c[0]).all() or (c1 != c[1]).all() or (c2 != c[2]).all():
        cond = (np.array_equal(c0, c[0])) or (np.array_equal(c1, c[1])) or (np.array_equal(c2, c[2]))
        if not cond:
            raise Exception("\n - c0 !== c[0] or c1 !== c[1] or c2 != c[2] ")

    return [all_im_str, all_im]

#
#
# def extract_secrets(step_1_or_2, input_invest, in_data, out_data, n_shares, gadget_name):
#     """ step_1_or_2 = {"step1", ("step2", [j, k])}"""
#     [st, j_k] = which_step(step_1_or_2)
#     # all_im_str = ["a[0]", "a[1]", "a[2]", "b[0]", "b[1]", "b[2]", "r[0]", "r[1]", "r[2]"]
#     [all_im_str, all_im] = Cal_im_value([in_data, out_data], 0, n_shares, gadget_name)
#
#     if (input_invest == "input_a") and (st == "step1"):
#         secrets_str = all_im_str[0:n_shares]
#         secrets_val = all_im[0:n_shares]
#
#     elif (input_invest == "input_b") and (st == "step1"):
#         secrets_str = all_im_str[n_shares:2*n_shares]
#         secrets_val = all_im[n_shares:2*n_shares]
#
#     elif (input_invest == "input_a") and (st == "step2"):
#         secrets_str = [all_im_str[j_k[0]], all_im_str[j_k[1]]]
#         secrets_val = [all_im[j_k[0]], all_im[j_k[1]]]
#
#     elif (input_invest == "input_b") and (st == "step2"):
#         secrets_str = [all_im_str[j_k[0] + n_shares], all_im_str[j_k[1] + n_shares]]
#         secrets_val = [all_im[j_k[0] + n_shares], all_im[j_k[1] + n_shares]]
#
#     del all_im, all_im_str
#     print("[+] Secrets are:", secrets_str)
#     ###################################################################################################
#     secrets_val = [list(i) for i in zip(*secrets_val)]
#
#     return secrets_val
#
#
# #
# def get_extract_beta_model(trs_file, G_n, n_sh, seg_traces, p_p_c, step_1_or_2, II):
#     """ step_1_or_2 = {"step1", ("step2", [j, k])}"""
#
#     [inD, outD, n_s, n_t, all_traces] = get_info(trs_file, G_n, n_sh, seg_traces, p_p_c)
#     secrets_val = extract_secrets(step_1_or_2, II, inD, outD, n_sh, G_n)
#     [f_Model, n_Model, b_full, b_naive] = betas_and_model_steps(secrets_val, n_t, all_traces, step_1_or_2)
#     return [n_s, n_t, all_traces, b_full, b_naive, f_Model, n_Model]