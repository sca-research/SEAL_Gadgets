import serial
from time import sleep
import secrets
import random
import sys
from functools import reduce


def valid_gadget(gadget_name):
    g_n = ["isw", "bbpp", "dom_indep", "hpc1_opt", "pini1", "pini2", "dom_dep"]
    if gadget_name not in g_n:
        raise Exception("\n - Please enter a valid gadget_name: \n     isw, bbpp, dom_indep, hpc1_opt, pini1, pini2")


def masking(x, mask_ORD):
    """ This function masks the input x, the type of the output is bytearray"""
    y = bytearray(mask_ORD + 1)
    rnd = bytearray([secrets.randbits(8) for j in range(0, mask_ORD)])
    y[mask_ORD] = x
    for i in range(0, mask_ORD):
        y[i] = rnd[i]
        y[mask_ORD] ^= rnd[i]
    return y


def gf_mult(a, b):
    """ Multiplication in the Galois field GF(2^8) """
    p = 0  # The product of the multiplication
    over_f = 0
    for i in range(8):
        # if b is odd, then add the corresponding a to p (final product = sum of all a's corresponding to odd b's)
        if b & 1 == 1:
            p ^= a  # since we're in GF(2^m), addition is an XOR

        over_f = a & 0x80
        a <<= 1
        if over_f == 0x80:
            a ^= 0x1b  # GF modulo: if a >= 128, then it will overflow when shifted left, so reduce
        b >>= 1
    return p % 256


def n_rand_in_gadget(gadget_name, mask_order):
    if gadget_name == "pini1" or "isw" or "dom_indep":
        n_rnd_gadget = int(mask_order * (mask_order + 1) / 2)
    if gadget_name == "bbpp":
        if mask_order <= 2:
            n_rnd_gadget = mask_order
        else:  # optimal
            n_rnd_gadget = mask_order + 1
    if gadget_name == "hpc1_opt":
        n_rnd_gadget = int(mask_order * (mask_order + 1) / 2) + mask_order
        if mask_order == 3:
            n_rnd_gadget = n_rnd_gadget + 1
    if gadget_name == "pini2":
        n_rnd_gadget = int((mask_order ** 2) / 4) + 2 * mask_order + 1
    if gadget_name == "dom_dep":
        n_rnd_gadget = int((mask_order * (mask_order + 1) / 2) + mask_order + 1)
    return n_rnd_gadget


def correctness_gadget(Mask_ORD, gadget_name, input_a, input_b, a, b, r, shares_c, step, i):
    valid_gadget(gadget_name)
    out_c = 0
    for p in range(0, Mask_ORD + 1):
        out_c ^= shares_c[p]
        gf_a_b = gf_mult(input_a, input_b)

    if i % step == 0:
        print('\ni={0} ----------------------------------'.format(i))
        # print('- in_data {}: {}'.format(i, (all_data + shares_c).hex()))
        print('- shares_a: [{}], a: {}'.format(a.hex(), hex(input_a)))
        print('- shares_b: [{}], b: {}'.format(b.hex(), hex(input_b)))
        print('- shares_r: [{}]'.format(r.hex()))
        print('- shares_c: [{}], c: {}'.format(shares_c.hex(), hex(out_c)))
        print('- gfmult: {}'.format(hex(gf_a_b)))

    ##### Testing different gadgets
    c = bytearray([0 for j in range(0, Mask_ORD + 1)])
    if gadget_name == "isw":
        if Mask_ORD == 1:
            c[0] = gf_mult(a[0], b[0]) ^ r[0]
            c[1] = (gf_mult(a[0], b[1]) ^ r[0]) ^ gf_mult(a[1], b[0]) ^ gf_mult(a[1], b[1])
        if Mask_ORD == 2:
            c[0] = gf_mult(a[0], b[0]) ^ r[0] ^ r[1]
            c[1] = (gf_mult(a[0], b[1]) ^ r[0]) ^ gf_mult(a[1], b[0]) ^ gf_mult(a[1], b[1]) ^ r[2]
            c[2] = (gf_mult(a[0], b[2]) ^ r[1]) ^ gf_mult(a[2], b[0]) ^ gf_mult(a[1], b[2]) ^ gf_mult(a[2], b[1]) ^ \
                   r[2] ^ gf_mult(a[2], b[2])

        if Mask_ORD == 3:
            c[0] = gf_mult(a[0], b[0]) ^ r[0] ^ r[1] ^ r[2]
            c[1] = (gf_mult(a[0], b[1]) ^ r[0]) ^ gf_mult(a[1], b[0]) ^ gf_mult(a[1], b[1]) ^ r[3] ^ r[4]
            c[2] = (gf_mult(a[0], b[2]) ^ r[1]) ^ gf_mult(a[2], b[0]) ^ \
                   (gf_mult(a[1], b[2]) ^ r[3]) ^ gf_mult(a[2], b[1]) ^ \
                   (gf_mult(a[2], b[2]) ^ r[5])
            c[3] = (gf_mult(a[0], b[3]) ^ r[2]) ^ gf_mult(a[3], b[0]) ^ \
                   (gf_mult(a[1], b[3]) ^ r[4]) ^ gf_mult(a[3], b[1]) ^ \
                   (gf_mult(a[2], b[3]) ^ r[5]) ^ gf_mult(a[3], b[2]) ^ gf_mult(a[3], b[3])

        if Mask_ORD == 4:
            c[0] = gf_mult(a[0], b[0]) ^ r[0] ^ r[1] ^ r[2] ^ r[3]
            c[1] = (gf_mult(a[0], b[1]) ^ r[0]) ^ gf_mult(a[1], b[0]) ^ gf_mult(a[1], b[1]) ^ r[4] ^ r[5] ^ r[6]
            c[2] = (gf_mult(a[0], b[2]) ^ r[1]) ^ gf_mult(a[2], b[0]) ^ \
                   (gf_mult(a[1], b[2]) ^ r[4]) ^ gf_mult(a[2], b[1]) ^ \
                   (gf_mult(a[2], b[2])) ^ r[7] ^ r[8]
            c[3] = (gf_mult(a[0], b[3]) ^ r[2]) ^ gf_mult(a[3], b[0]) ^ \
                   (gf_mult(a[1], b[3]) ^ r[5]) ^ gf_mult(a[3], b[1]) ^ \
                   (gf_mult(a[2], b[3]) ^ r[7]) ^ gf_mult(a[3], b[2]) ^ gf_mult(a[3], b[3]) ^ r[9]
            c[4] = (gf_mult(a[0], b[4]) ^ r[3]) ^ gf_mult(a[4], b[0]) ^ \
                   (gf_mult(a[1], b[4]) ^ r[6]) ^ gf_mult(a[4], b[1]) ^ \
                   (gf_mult(a[2], b[4]) ^ r[8]) ^ gf_mult(a[4], b[2]) ^ gf_mult(a[3], b[4]) ^ r[9] ^ \
                   (gf_mult(a[4], b[3]) ^ gf_mult(a[4], b[4]))

    if gadget_name == "bbpp":
        if Mask_ORD == 1:
            c[0] = (gf_mult(a[0], b[0]) ^ r[0]) ^ gf_mult(a[0], b[1]) ^ gf_mult(a[1], b[0])
            c[1] = gf_mult(a[1], b[1]) ^ r[0]

        # It is the optimal one, algorithm 4
        if Mask_ORD == 2:
            c[0] = gf_mult(a[0], b[0]) ^ r[0] ^ gf_mult(a[0], b[2]) ^ gf_mult(a[2], b[0])
            c[1] = gf_mult(a[1], b[1]) ^ r[1] ^ gf_mult(a[0], b[1]) ^ gf_mult(a[1], b[0])
            c[2] = gf_mult(a[2], b[2]) ^ r[0] ^ r[1] ^ gf_mult(a[1], b[2]) ^ gf_mult(a[2], b[1])

        # It is the optimal one
        if Mask_ORD == 3:
            c[0] = (gf_mult(a[0], b[0]) ^ r[0] ^ gf_mult(a[0], b[3]) ^ gf_mult(a[3], b[0]) ^ r[1] ^
                    gf_mult(a[0], b[2]) ^ gf_mult(a[2], b[0]))
            c[1] = (gf_mult(a[1], b[1]) ^ r[2] ^ gf_mult(a[1], b[3]) ^ gf_mult(a[3], b[1]) ^ r[1] ^
                    gf_mult(a[1], b[2]) ^ gf_mult(a[2], b[1]))
            c[2] = gf_mult(a[2], b[2]) ^ r[3] ^ gf_mult(a[2], b[3]) ^ gf_mult(a[3], b[2])
            c[3] = gf_mult(a[3], b[3]) ^ r[3] ^ r[2] ^ r[0] ^ gf_mult(a[0], b[1]) ^ gf_mult(a[1], b[0])

        # It is the optimal one
        if Mask_ORD == 4:
            c[0] = (gf_mult(a[0], b[0]) ^ r[0] ^ gf_mult(a[0], b[1]) ^ gf_mult(a[1], b[0]) ^ r[1] ^
                    gf_mult(a[0], b[2]) ^ gf_mult(a[2], b[0]))
            c[1] = (gf_mult(a[1], b[1]) ^ r[1] ^ gf_mult(a[1], b[2]) ^ gf_mult(a[2], b[1]) ^ r[2] ^
                    gf_mult(a[1], b[3]) ^ gf_mult(a[3], b[1]))
            c[2] = (gf_mult(a[2], b[2]) ^ r[2] ^ gf_mult(a[2], b[3]) ^ gf_mult(a[3], b[2]) ^ r[3] ^
                    gf_mult(a[2], b[4]) ^ gf_mult(a[4], b[2]))
            c[3] = (gf_mult(a[3], b[3]) ^ r[3] ^ gf_mult(a[3], b[4]) ^ gf_mult(a[4], b[3]) ^ r[4] ^
                    gf_mult(a[3], b[0]) ^ gf_mult(a[0], b[3]))
            c[4] = (gf_mult(a[4], b[4]) ^ r[4] ^ gf_mult(a[4], b[0]) ^ gf_mult(a[0], b[4]) ^ r[0] ^
                    gf_mult(a[4], b[1]) ^ gf_mult(a[1], b[4]))

    if gadget_name == "dom_indep":
        if Mask_ORD == 1:
            c[0] = gf_mult(a[0], b[0]) ^ gf_mult(a[0], b[1]) ^ r[0]
            c[1] = gf_mult(a[1], b[0]) ^ r[0] ^ gf_mult(a[1], b[1])
        if Mask_ORD == 2:
            c[0] = gf_mult(a[0], b[0]) ^ gf_mult(a[0], b[1]) ^ r[0] ^ gf_mult(a[0], b[2]) ^ r[1]
            c[1] = gf_mult(a[1], b[0]) ^ r[0] ^ gf_mult(a[1], b[1]) ^ gf_mult(a[1], b[2]) ^ r[2]
            c[2] = gf_mult(a[2], b[0]) ^ r[1] ^ gf_mult(a[2], b[1]) ^ r[2] ^ gf_mult(a[2], b[2])

        if Mask_ORD == 3:
            c[0] = gf_mult(a[0], b[0]) ^ gf_mult(a[0], b[1]) ^ r[0] ^ gf_mult(a[0], b[2]) ^ r[1] ^ gf_mult(a[0], b[3]) ^ \
                   r[3]
            c[1] = gf_mult(a[1], b[0]) ^ r[0] ^ gf_mult(a[1], b[1]) ^ gf_mult(a[1], b[2]) ^ r[2] ^ gf_mult(a[1], b[3]) ^ \
                   r[4]
            c[2] = gf_mult(a[2], b[0]) ^ r[1] ^ gf_mult(a[2], b[1]) ^ r[2] ^ gf_mult(a[2], b[2]) ^ gf_mult(a[2], b[3]) ^ \
                   r[5]
            c[3] = gf_mult(a[3], b[0]) ^ r[3] ^ gf_mult(a[3], b[1]) ^ r[4] ^ gf_mult(a[3], b[2]) ^ r[5] ^ gf_mult(a[3],
                                                                                                                  b[3])

        if Mask_ORD == 4:
            c[0] = gf_mult(a[0], b[0]) ^ gf_mult(a[0], b[1]) ^ r[0] ^ gf_mult(a[0], b[2]) ^ r[1] ^ gf_mult(a[0], b[3]) ^ \
                   r[3] ^ \
                   gf_mult(a[0], b[4]) ^ r[6]
            c[1] = gf_mult(a[1], b[0]) ^ r[0] ^ gf_mult(a[1], b[1]) ^ gf_mult(a[1], b[2]) ^ r[2] ^ gf_mult(a[1], b[3]) ^ \
                   r[4] ^ \
                   gf_mult(a[1], b[4]) ^ r[7]
            c[2] = gf_mult(a[2], b[0]) ^ r[1] ^ gf_mult(a[2], b[1]) ^ r[2] ^ gf_mult(a[2], b[2]) ^ gf_mult(a[2], b[3]) ^ \
                   r[5] ^ \
                   gf_mult(a[2], b[4]) ^ r[8]
            c[3] = gf_mult(a[3], b[0]) ^ r[3] ^ gf_mult(a[3], b[1]) ^ r[4] ^ gf_mult(a[3], b[2]) ^ r[5] ^ gf_mult(a[3],
                                                                                                                  b[
                                                                                                                      3]) ^ \
                   gf_mult(a[3], b[4]) ^ r[9]
            c[4] = gf_mult(a[4], b[0]) ^ r[6] ^ gf_mult(a[4], b[1]) ^ r[7] ^ gf_mult(a[4], b[2]) ^ r[8] ^ gf_mult(a[4],
                                                                                                                  b[
                                                                                                                      3]) ^ \
                   r[9] ^ gf_mult(a[4], b[4])

    if gadget_name == "hpc1_opt":
        if Mask_ORD == 1:
            ref_b = bytearray([(b[ele] ^ r[0]) for ele in range(0, Mask_ORD + 1)])

            if i % step == 0:
                print('- ref_b {}: {}'.format(i, ref_b.hex()))

            c[0] = gf_mult(a[0], ref_b[0]) ^ gf_mult(a[0], ref_b[1]) ^ r[1]
            c[1] = gf_mult(a[1], ref_b[0]) ^ r[1] ^ gf_mult(a[1], ref_b[1])

        if Mask_ORD == 2:
            x = [(b[ele] ^ r[ele]) for ele in range(0, Mask_ORD)]
            x.append((b[2] ^ (r[0] ^ r[1])))
            ref_b = bytearray(x)
            del x

            if i % step == 0:
                print('- ref_b: [{}] '.format(ref_b.hex()))

            c[0] = gf_mult(a[0], ref_b[0]) ^ gf_mult(a[0], ref_b[1]) ^ r[2] ^ gf_mult(a[0], ref_b[2]) ^ r[3]
            c[1] = gf_mult(a[1], ref_b[0]) ^ r[2] ^ gf_mult(a[1], ref_b[1]) ^ gf_mult(a[1], ref_b[2]) ^ r[4]
            c[2] = gf_mult(a[2], ref_b[0]) ^ r[3] ^ gf_mult(a[2], ref_b[1]) ^ r[4] ^ gf_mult(a[2], ref_b[2])

        if Mask_ORD == 3:
            ref_b = bytearray([0 for j in range(0, Mask_ORD + 1)])

            ref_b[0] = b[0] ^ (r[0] ^ r[3])
            ref_b[1] = b[1] ^ (r[1] ^ r[0])
            ref_b[2] = b[2] ^ (r[2] ^ r[1])
            ref_b[3] = b[3] ^ (r[3] ^ r[2])

            c[0] = (gf_mult(a[0], ref_b[0]) ^ gf_mult(a[0], ref_b[1]) ^ r[4]) ^ (gf_mult(a[0], ref_b[2]) ^ r[5]) ^ (
                    gf_mult(a[0], ref_b[3]) ^ r[7])
            c[1] = (gf_mult(a[1], ref_b[0]) ^ r[4]) ^ gf_mult(a[1], ref_b[1]) ^ (gf_mult(a[1], ref_b[2]) ^ r[6]) ^ (
                    gf_mult(a[1], ref_b[3]) ^ r[8])
            c[2] = (gf_mult(a[2], ref_b[0]) ^ r[5]) ^ (gf_mult(a[2], ref_b[1]) ^ r[6]) ^ gf_mult(a[2], ref_b[2]) ^ (
                    gf_mult(a[2], ref_b[3]) ^ r[9])
            c[3] = (gf_mult(a[3], ref_b[0]) ^ r[7]) ^ (gf_mult(a[3], ref_b[1]) ^ r[8]) ^ (
                    gf_mult(a[3], ref_b[2]) ^ r[9]) ^ gf_mult(a[3], ref_b[3])

    if gadget_name == "pini1":
        if Mask_ORD == 1:
            c[0] = gf_mult(a[0], b[0]) ^ gf_mult((a[0] ^ 1), r[0]) ^ gf_mult(a[0], (b[1] ^ r[0]))
            c[1] = gf_mult(a[1], b[1]) ^ gf_mult((a[1] ^ 1), r[0]) ^ gf_mult(a[1], (b[0] ^ r[0]))
        if Mask_ORD == 2:
            c[0] = gf_mult(a[0], b[0]) ^ gf_mult(a[0] ^ 1, r[0]) ^ gf_mult(a[0], (b[1] ^ r[0])) ^ \
                   gf_mult(a[0] ^ 1, r[1]) ^ gf_mult(a[0], (b[2] ^ r[1]))
            c[1] = gf_mult(a[1], b[1]) ^ gf_mult(a[1] ^ 1, r[0]) ^ gf_mult(a[1], (b[0] ^ r[0])) ^ \
                   gf_mult(a[1] ^ 1, r[2]) ^ gf_mult(a[1], (b[2] ^ r[2]))
            c[2] = gf_mult(a[2], b[2]) ^ gf_mult(a[2] ^ 1, r[1]) ^ gf_mult(a[2], (b[0] ^ r[1])) ^ \
                   gf_mult(a[2] ^ 1, r[2]) ^ gf_mult(a[2], (b[1] ^ r[2]))

    if gadget_name == "pini2":
        if Mask_ORD == 1:
            s01 = r[0] ^ r[1]
            c[0] = gf_mult(a[0], b[0]) ^ r[2] ^ \
                   gf_mult(a[0], s01) ^ gf_mult(a[0], (b[1] ^ s01)) ^ \
                   gf_mult(b[0], s01) ^ gf_mult(b[0], (a[1] ^ s01))
            c[1] = gf_mult(a[1], b[1]) ^ r[2]
        if Mask_ORD == 2:
            s01 = r[0] ^ r[1]
            s02 = r[0] ^ r[2]
            s12 = r[1] ^ r[2]
            p0_01 = gf_mult(a[0], s01)
            p1_01 = gf_mult(a[0], (b[1] ^ s01))
            p2_01 = gf_mult(b[0], s01)
            p3_01 = gf_mult(b[0], (a[1] ^ s01))
            p0_02 = gf_mult(a[0], s02)
            p1_02 = gf_mult(a[0], (b[2] ^ s02))
            p2_02 = gf_mult(b[0], s02)
            p3_02 = gf_mult(b[0], (a[2] ^ s02))
            p0_12 = gf_mult(a[1], s12)
            p1_12 = gf_mult(a[1], (b[2] ^ s12))
            p2_12 = gf_mult(b[1], s12)
            p3_12 = gf_mult(b[1], (a[2] ^ s12))

            c[0] = gf_mult(a[0], b[0]) ^ (r[3] ^ p0_02 ^ p1_02 ^ p2_02 ^ p3_02 ^ r[4] ^ p0_01 ^ p1_01 ^ p2_01 ^ p3_01)
            c[1] = gf_mult(a[1], b[1]) ^ (r[5] ^ p0_12 ^ p1_12 ^ p2_12 ^ p3_12) ^ r[4]
            c[2] = gf_mult(a[2], b[2]) ^ r[5] ^ r[3]

    if gadget_name == "dom_dep":
        X = bytearray([(b[ele] ^ r[ele]) for ele in range(0, Mask_ORD + 1)])
        x = decode_x = reduce(lambda xx, y: xx ^ y, X)
        if Mask_ORD == 2:
            c[0] = gf_mult(a[0], x) ^ (gf_mult(a[0], r[0]) ^ gf_mult(a[0], r[1]) ^ r[3] ^ gf_mult(a[0], r[2]) ^ r[4])
            c[1] = gf_mult(a[1], x) ^ (gf_mult(a[1], r[0]) ^ r[3] ^ gf_mult(a[1], r[1]) ^ gf_mult(a[1], r[2]) ^ r[5])
            c[2] = gf_mult(a[2], x) ^ (gf_mult(a[2], r[0]) ^ r[4] ^ gf_mult(a[2], r[1]) ^ r[5] ^ gf_mult(a[2], r[2]))

        if Mask_ORD == 3:
            c[0] = gf_mult(a[0], x) ^ (gf_mult(a[0], r[0]) ^ gf_mult(a[0], r[1]) ^ r[4] ^
                                       gf_mult(a[0], r[2]) ^ r[5] ^ gf_mult(a[0], r[3]) ^ r[7])
            c[1] = gf_mult(a[1], x) ^ (gf_mult(a[1], r[0]) ^ r[4] ^ gf_mult(a[1], r[1]) ^
                                       gf_mult(a[1], r[2]) ^ r[6] ^ gf_mult(a[1], r[3]) ^ r[8])
            c[2] = gf_mult(a[2], x) ^ (gf_mult(a[2], r[0]) ^ r[5] ^ gf_mult(a[2], r[1]) ^
                                       r[6] ^ gf_mult(a[2], r[2]) ^ gf_mult(a[2], r[3]) ^ r[9])
            c[3] = gf_mult(a[3], x) ^ (gf_mult(a[3], r[0]) ^ r[7] ^ gf_mult(a[3], r[1]) ^
                                       r[8] ^ gf_mult(a[3], r[2]) ^ r[9] ^ gf_mult(a[3], r[3]))

        if Mask_ORD == 4:
            c[0] = gf_mult(a[0], x) ^ (gf_mult(a[0], r[0]) ^ gf_mult(a[0], r[1]) ^ r[5] ^
                                       gf_mult(a[0], r[2]) ^ r[6] ^ gf_mult(a[0], r[3]) ^ r[8] ^ gf_mult(a[0], r[4]) ^
                                       r[11])
            c[1] = gf_mult(a[1], x) ^ (gf_mult(a[1], r[0]) ^ r[5] ^ gf_mult(a[1], r[1]) ^
                                       gf_mult(a[1], r[2]) ^ r[7] ^ gf_mult(a[1], r[3]) ^ r[9] ^ gf_mult(a[1], r[4]) ^
                                       r[12])
            c[2] = gf_mult(a[2], x) ^ (gf_mult(a[2], r[0]) ^ r[6] ^ gf_mult(a[2], r[1]) ^
                                       r[7] ^ gf_mult(a[2], r[2]) ^ gf_mult(a[2], r[3]) ^ r[10] ^ gf_mult(a[2], r[4]) ^
                                       r[13])
            c[3] = gf_mult(a[3], x) ^ (gf_mult(a[3], r[0]) ^ r[8] ^ gf_mult(a[3], r[1]) ^
                                       r[9] ^ gf_mult(a[3], r[2]) ^ r[10] ^ gf_mult(a[3], r[3]) ^ gf_mult(a[3], r[4]) ^
                                       r[14])
            c[4] = gf_mult(a[4], x) ^ (gf_mult(a[4], r[0]) ^ r[11] ^ gf_mult(a[4], r[1]) ^ r[12]
                                       ^ gf_mult(a[4], r[2]) ^ r[13] ^ gf_mult(a[4], r[3]) ^ r[14] ^ gf_mult(a[4], r[4]))

    for j in range(0, Mask_ORD + 1):
        if c[j] != shares_c[j]:
            print("i=", i, ":", c[j], "!=", shares_c[j])
            raise Exception(("ERROR: c[{}] != output[{}]".format(j, j)))

    if gf_mult(input_a, input_b) != out_c:
        raise Exception("ERROR: gmul(in_b, in_a) != output of gadget")


step = 10


def uart(ser, num_repeat, n_share, gadget_name):
    """ This function enables the serial_port, and transmits tx_data
        from the PC to the device connected with the PC and receives
        rx_data from the device to the PC. Also, it repeats the TX and RX
        transactions num_repeat times"""
    Mask_ORD = n_share - 1
    valid_gadget(gadget_name)
    n_rnd_gadget = n_rand_in_gadget(gadget_name, Mask_ORD)
    in_len_gadget = 2 * n_share + n_rnd_gadget
    if ser.is_open:
        print("\n ********************* START ********************* \n")
    for i in range(num_repeat):

        # Generating random inputs and randomness (a, b, r)
        # input_a and input_b are sampled in "int" type for
        # being convinced to use in masking function and gf_mult function

        input_a = secrets.randbits(8)  # type: int
        input_b = secrets.randbits(8)  # type: int
        # Converting input_a and input_b to "byte" type, in order to store in trs file
        in_a = input_a.to_bytes(1, sys.byteorder)
        in_b = input_b.to_bytes(1, sys.byteorder)

        # Masking inputs
        mask_a = masking(input_a, Mask_ORD)  # type: bytearray
        a = mask_a
        mask_b = masking(input_b, Mask_ORD)  # type: bytearray
        b = mask_b
        # Randomness needed in gadget
        rnd_gadget = bytearray([secrets.randbits(8) for j in range(0, n_rnd_gadget)])
        r = rnd_gadget
        # The input data
        inputs_of_gadget = mask_a + mask_b + rnd_gadget

        # Check
        if len(inputs_of_gadget) != in_len_gadget:  # length in bytes
            print("ERROR INPUT LENGTH")

        # Wait
        # tx: Transmitting input data serially from the PC to the SCALE_Board by UART Serial Port
        sleep(0.08)
        ser.write(inputs_of_gadget)
        # print("[+] Inputs are sent")
        # rx: Receiving output data serially from the SCALE_Board to the PC by UART Serial Port
        shares_c = bytearray(ser.read(n_share))

        all_data = in_a + in_b + mask_a + mask_b + rnd_gadget + shares_c

        correctness_gadget(Mask_ORD, gadget_name, input_a, input_b, a, b, r, shares_c, step, i)

        if i % step == 0:
            print('- in_data {}: {}'.format(i, (all_data + shares_c).hex()))
    print('\n\nSerial port: {}'.format(ser.name))
    print('___________________________________________________________________')

    # Disabling the serial port
    ser.close()

    if not ser.is_open:
        print("\n ********************* END ********************* \n")
    return


if __name__ == '__main__':
    # Serial port communication: look this up in 'device manager'
    port = '/dev/ttyUSB0'  # Serial port
    # Initialized random generator for generating inputs and randomness
    ##################################################
    random.seed()
    # Open serial port
    ##################################################
    ser = serial.Serial(port)
    # The number of running the program
    num = 100
    # uart(ser, num_repeat, Mask_ORD, gadget_name)
    # gadget_name = ["isw", "bbpp", "dom_indep", "hpc1_opt", "pini1", "pini2", "dom_dep"]
    uart(ser, num, 4, "hpc1_opt")
