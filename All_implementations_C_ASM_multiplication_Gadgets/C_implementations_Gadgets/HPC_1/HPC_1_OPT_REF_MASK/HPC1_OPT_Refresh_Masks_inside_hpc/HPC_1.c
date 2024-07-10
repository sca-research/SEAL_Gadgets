/*
 HPC_1: Fig.2 (c)  in "Hardware Private Circuits: From Trivial Composition to Full Verification"
*/

//In this implementation the OPT_Ref_Mask is considered to be a part of the body of HPC1
#include "HPC_1.h"
#include "Opt_Ref_Mask.h"
/*
    hpc1(INPUT: input_a[Mask_ORD+1], INPUT: input_b[Mask_ORD+1], INPUT: uint8_t* rnd, OUTPUT: c[Mask_ORD+1])
    c = a * b
    * works for any field : this program is for field: 2^3=8
    *
        rnd_Ref: Func --> rnd_number(int Mask_order);
        rnd_DOM: Mask_ORD * (Mask_ORD+1) /2;
        Total rnd = rnd_Ref + rnd_DOM
        */

////////////////////////////////////////////////

 void hpc1(uint8_t* input_a, uint8_t* input_b, uint8_t * rnd, uint8_t* c) {


     int rnd_n_OPT_Refresh = rnd_number(Mask_ORD); // Number of randomness for Optimized RefreshMasks
     int rnd_n_DOM = Mask_ORD * (Mask_ORD+1) /2; // The number of randomness in DOM_indep multiplication gadget

         uint8_t rnd_OPT_Refresh[rnd_n_OPT_Refresh]; // Random number for optimized refreshing
     static uint8_t rnd_DOM[Mask_ORD * (Mask_ORD+1) /2]; // Random number for Dom_Indep multiplication
     static uint8_t ref_b[Mask_ORD + 1]; // Refreshed input_b: Adding input_b and share_0_mask

     // Random number for optimized refreshing
     for (int i = 0; i < rnd_n_OPT_Refresh; i++) {
         rnd_OPT_Refresh[i] = rnd[i];
     }

     // Random number for Dom_Indep multiplication
     for (int i = 0; i <= rnd_n_DOM; i++) {
         rnd_DOM[i] = rnd[i+ rnd_n_OPT_Refresh];
     }

    /*Refresh part:*/
    ////////////////////////////////////////////////////////////////////

    opt_refresh_mask(input_b, rnd_OPT_Refresh, ref_b);


    /*Multiplication part:*/
    ////////////////////////////////////////////////////////////////////
    DOM_independent(input_a, ref_b, rnd_DOM, c);
}


// DOM-indep Eq.6 in "An Efficient Side-Channel Protected AES Implementation with Arbitrary Protection Order"

/*
    DOM_independent(INPUT: input_a[Mask_ORD+1], INPUT: input_b[Mask_ORD+1], INPUT: rnd[Mask_ORD * (Mask_ORD+1)/2], OUTPUT: c[Mask_ORD+1])
    c = a * b
    rnd: random numbers (on_the_fly)*/
void DOM_independent(uint8_t* a, uint8_t* b, uint8_t* rnd, uint8_t* c){
    int i, j;
    // The number of randomness in DOM_indep multiplication gadget
    int rand_n = Mask_ORD * (Mask_ORD+1)/2;

    uint8_t cross_product[2*rand_n];

    for (i = 0; i < Mask_ORD + 1; i++){
        uint8_t output = 0;
        for (j = 0; j < Mask_ORD + 1; j++){
            int p = (Mask_ORD ) * i + j;
            if (i == j){
                // Inner_products
                output = output ^  gfMul(a[i], b[j]);
            }
            else if (j > i){
                cross_product[p] = (gfMul(a[i], b[j])) ^ rnd[i + (j*(j-1)/2)];
            }
            else{
                cross_product[p] = (gfMul(a[i], b[j])) ^ rnd[j + (i*(i-1)/2)];
            }
            if (i!=j){

                output = output ^ cross_product[p];
            }
        }
        c[i] = output;
    }
}



uint8_t gfMul(uint8_t a, uint8_t b)
{
    int s = 0;
    s = table[a] + table[b];
    /* Get the antilog */
    s = table[s+256];
/*
    Checking a=0 or b=0, without conditional branch: if (a==0 or b==0){return 0;} else{return s;}
     Countermeasure for Power analysis attacks
*/
    uint8_t tmp = 0;
    tmp = b & (-a >> 8);
    s = s & (-tmp >> 8);
    return s;
}
/* uint8_t gfMul(uint8_t a, uint8_t b)
   {
       int s = 0;
       s = table[a] + table[b];
       int q;
       *//* Get the antilog *//*
        s = table[s+256];
        uint8_t z = 0;
        q = s;
        if(a == 0) {
            s = z;
        } else {
            s = q;
        }
        if(b == 0) {
            s = z;
        } else {
            q = z;
        }
        return s;
    }*/
