
/*
 Optimized RefreshMasks: Fig.4  in "Hardware Private Circuits: From Trivial Composition to Full Verification"
*/
#include "Opt_Ref_Mask.h"


void  si_xor_rotated_si(int d_sh, int r, uint8_t* rnd_vec, int ind_start, int ind_end, uint8_t* t);
//////////////////////////////////////////////////////////////////////
void opt_refresh_mask(uint8_t* a, uint8_t* rnd, uint8_t* d){

    static uint8_t t_reg_rnd0[Mask_ORD+1]; // Register for new randomness
    static uint8_t t_reg_rnd1[Mask_ORD+1]; // Register for new randomness when 13<= d_sh <= 16


    int d_shares = Mask_ORD +1; // Number of shares

    if (d_shares == 2){
        //  uint8_t* rnd: 2 elements
        t_reg_rnd0[0] = rnd[0];
        t_reg_rnd0[1] = rnd[0];
    }

    if (d_shares == 3){
        //  uint8_t* rnd: 3 elements
        t_reg_rnd0[0] = rnd[0];
        t_reg_rnd0[1] = rnd[1];
        t_reg_rnd0[2] = rnd[0] ^ rnd[1];
    }

    if (d_shares == 4 | d_shares == 5) {
        //  uint8_t* rnd: 4 , 5 elements
        si_xor_rotated_si(d_shares,1, rnd,0, d_shares, t_reg_rnd0);
    }

    if (d_shares == 6) {
        //  uint8_t* rnd: 7 elements --> s^0 = rnd[0:5], r_i = rnd[7]

        si_xor_rotated_si(d_shares, 1, rnd,0, d_shares, t_reg_rnd0);
        t_reg_rnd0[0] ^= rnd[d_shares];
        //t_reg_rnd0[1]
        //t_reg_rnd0[2]
        t_reg_rnd0[3] ^= rnd[d_shares];
        //t_reg_rnd0[4]
        //t_reg_rnd0[5]
    }

    if (d_shares == 7) {
        //  uint8_t* rnd: 9 elements --> s^0 = rnd[0:6], r_i = rnd[7:8]
        si_xor_rotated_si(d_shares, 1, rnd,0, d_shares, t_reg_rnd0);
        t_reg_rnd0[0] ^= rnd[d_shares];
        //t_reg_rnd0[1]
        t_reg_rnd0[2] ^= rnd[d_shares+1];
        //t_reg_rnd0[3]
        t_reg_rnd0[4] ^= rnd[d_shares];
        //t_reg_rnd0[5]
        t_reg_rnd0[6] ^= rnd[d_shares+1];
    }

    if (d_shares == 8) {
        //  uint8_t* rnd: 11 elements --> s^0 = rnd[0:7], r_i = rnd[8:10]
        si_xor_rotated_si(d_shares, 1, rnd,0, d_shares, t_reg_rnd0);
        t_reg_rnd0[0] ^= rnd[d_shares];
        t_reg_rnd0[1] ^= rnd[d_shares+1];
        t_reg_rnd0[2] ^= rnd[d_shares+2];
        //t_reg_rnd0[3]
        t_reg_rnd0[4] ^= rnd[d_shares];
        t_reg_rnd0[5] ^= rnd[d_shares+1];
        t_reg_rnd0[6] ^= rnd[d_shares+2];
        //t_reg_rnd0[7]
    }

    if (d_shares == 9) {
        //  uint8_t* rnd: 12 elements --> s^0 = rnd[0:8], r_i = rnd[9:11]
        si_xor_rotated_si(d_shares, 1, rnd,0, d_shares, t_reg_rnd0);
        t_reg_rnd0[0] ^= rnd[d_shares];
        t_reg_rnd0[1] ^= rnd[d_shares+1];
        //t_reg_rnd0[2]
        t_reg_rnd0[3] ^= rnd[d_shares+2];
        t_reg_rnd0[4] ^= rnd[d_shares];
        //t_reg_rnd0[5]
        t_reg_rnd0[6] ^= rnd[d_shares+1];
        t_reg_rnd0[7] ^= rnd[d_shares+2];
        //t_reg_rnd0[8]
    }

    if (d_shares == 10) {
        //  uint8_t* rnd: 15 elements --> s^0 = rnd[0:9], r_i = rnd[10:14]
        si_xor_rotated_si(d_shares, 1, rnd,0, d_shares, t_reg_rnd0);
        t_reg_rnd0[0] ^= rnd[d_shares];
        t_reg_rnd0[1] ^= rnd[d_shares+1];
        t_reg_rnd0[2] ^= rnd[d_shares+2];
        t_reg_rnd0[3] ^= rnd[d_shares+3];
        t_reg_rnd0[4] ^= rnd[d_shares+4];
        t_reg_rnd0[5] ^= rnd[d_shares];
        t_reg_rnd0[6] ^= rnd[d_shares+1];
        t_reg_rnd0[7] ^= rnd[d_shares+2];
        t_reg_rnd0[8] ^= rnd[d_shares+3];
        t_reg_rnd0[9] ^= rnd[d_shares+4];
    }


    if (d_shares == 11) {
        //  uint8_t* rnd: 17 elements --> s^0 = rnd[0:10], r_i = rnd[10:16]
        si_xor_rotated_si(d_shares, 1, rnd,0, d_shares, t_reg_rnd0);
        t_reg_rnd0[0]  ^= rnd[d_shares];
        t_reg_rnd0[1]  ^= rnd[d_shares+1];
        t_reg_rnd0[2]  ^= rnd[d_shares+2];
        t_reg_rnd0[3]  ^= rnd[d_shares+3];
        t_reg_rnd0[4]  ^= rnd[d_shares+4];
        t_reg_rnd0[5]  ^= rnd[d_shares];
        t_reg_rnd0[6]  ^= rnd[d_shares+1];
        t_reg_rnd0[7]  ^= rnd[d_shares+2] ^ rnd[d_shares+5];
        t_reg_rnd0[8]  ^= rnd[d_shares+3];
        t_reg_rnd0[9]  ^= rnd[d_shares+4];
        t_reg_rnd0[10] ^= rnd[d_shares+5];
    }

    if (d_shares == 12) {
        //  uint8_t* rnd: 20 elements --> s^0 = rnd[0:11], r_i = rnd[12:19]
        si_xor_rotated_si(d_shares, 1, rnd,0, d_shares, t_reg_rnd0);
        t_reg_rnd0[0]  ^= rnd[d_shares];
        t_reg_rnd0[1]  ^= rnd[d_shares+1];
        t_reg_rnd0[2]  ^= rnd[d_shares+2] ^ rnd[d_shares+6];
        t_reg_rnd0[3]  ^= rnd[d_shares+3];
        t_reg_rnd0[4]  ^= rnd[d_shares+4];
        t_reg_rnd0[5]  ^= rnd[d_shares+5] ^ rnd[d_shares+6];
        t_reg_rnd0[6]  ^= rnd[d_shares];
        t_reg_rnd0[7]  ^= rnd[d_shares+1];
        t_reg_rnd0[8]  ^= rnd[d_shares+2] ^ rnd[d_shares+7];
        t_reg_rnd0[9]  ^= rnd[d_shares+3];
        t_reg_rnd0[10] ^= rnd[d_shares+4];
        t_reg_rnd0[11] ^= rnd[d_shares+5] ^ rnd[d_shares+7];
    }

    if (12 < d_shares && d_shares < 17) {
        //  uint8_t* rnd: 2*d_shares elements --> s^0 = rnd[0:d_shares -1], r_i = s^1 = rnd[d_shares:2*d_shares -1]
        si_xor_rotated_si(d_shares, 1, rnd, 0, d_shares, t_reg_rnd0);
        si_xor_rotated_si(d_shares, 3, rnd, d_shares, (2*d_shares) , t_reg_rnd1);
        for (int i=0; i< d_shares; i++){
            t_reg_rnd0[i] ^= t_reg_rnd1[i];
        }
    }



    for (int i=0; i< d_shares; i++){
        d[i] = a[i] ^ t_reg_rnd0[i];
    }

}


/*
 * d_shares = Mask_ORD+1
 * Func for computing  s^i + (s^i >> r)
 *  s^i >> r, rotates to the right the s^i vector in the way that first element goes to r+1 th element
 *  Using FOR LOOP in this func: the input s^i is an array and array are stored in memory continuously
 *  void  si_xor_rotated_si(int Num_shares: d_sh, int num_rotation: r, uint8_t* rnd: random_vector, int ind_start: index start, int ind_end: index end,uint8_t* t: output);
 *  uint8_t* rnd has rnd_n elements, that the first d_shares elements [0: d_shares-1] are used in s^0
 *  an the rest are used as r_i
 *  For 13<= d_sh <= 16 : there are s^0 and s^1. rnd_vector has 2*d_shares elements, that the first d_shares elements [0: d_shares-1] are used in s^0
 *  and the second  d_shares elements [d_shares : 2*d_shares] are used as s^1
 *
 *  For s^0: r = 1 ---> si_xor_rotated_si(d_shares, 1, rnd, 0, d_shares, t_reg_rnd0);
 *  For s^1: r = 3 ---> si_xor_rotated_si(d_shares, 3, rnd, d_shares, (2*d_shares) , t_reg_rnd1);
*/
void  si_xor_rotated_si(int d_sh, int r, uint8_t* rnd_vec, int ind_start, int ind_end, uint8_t* t) {
    for (int j=0; j<r; j++){
        t[j] = rnd_vec[ind_start+j] ^ rnd_vec[ind_end - 1 -j];
    }
    for (int i=r; i<= (d_sh+r-1); i++){
        t[i] = rnd_vec[i+ind_start] ^ rnd_vec[i + ind_start -r];
    }
}





// The number of randomness in Optimized RefreshMask
int rnd_number(int Mask_order) {
    int d = Mask_order + 1;
    if (d <= 3) {
        return (d - 1);
    }
    if (d <= 5) {
        return d;
    }
    if (d <= 11) {
        return (2 * d - 5);
    }
    if (d == 12) {
        return (d + 8);
    }
    if (d <= 16) {
        return (2 * d);
    }
}
