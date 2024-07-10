#include "stdint.h"
#include "ISW.h"

/*
    Seminal_ISW(INPUT: input_a[Mask_ORD+1], INPUT: input_b[Mask_ORD+1],INPUT: uint8_t * rnd, OUTPUT: c[Mask_ORD+1])
    c = a * b
        The number of randomness: Mask_ORD * (Mask_ORD+1) /2;
        */

////////////////////////////////////////////////
    void Seminal_ISW(uint8_t* input_a, uint8_t* input_b,uint8_t* rnd, uint8_t* c)
    {
/* Expanding randomness vector:
    Here the 1-dimension vector (rnd[rand-n]) (r0,r1,r2, ..., r(rand_n-1)) become to a vector[Mask+ORD+1][Mask+ORD+1]
    as below: example for 3-dimension
                                              0   r0   r1
            input: (r0,r1,r2) ---> output:    r0   0   r2
                                              r1  r2    0
    */

        int i, j;
        static int r[Mask_ORD + 1][Mask_ORD + 1]; //r[i][j]

        for (i = 0; i < Mask_ORD + 1; i++) {
            r[i][i] = 0;
            for (j = i + 1; j < Mask_ORD + 1; j++) {

                // index variable is for producing numbers 0 to rand_n = Mask_ORD * (Mask_ORD+1)/2;
                int index = (i * (Mask_ORD + 1)) - (i * (i + 1) / 2) + j - i - 1;
                r[i][j] = rnd[index];

                // The order is important
                r[j][i] = (r[i][j] ^ gfMul(input_a[i], input_b[j])) ^ gfMul(input_a[j], input_b[i]);
            }
        }

        for (i = 0; i < Mask_ORD+1; i++){
            c[i]= gfMul(input_a[i], input_b[i]);
            
            for (j = 0; j < Mask_ORD+1; j++){
                if (i != j){
                    c[i] ^=r[i][j];
                }
            }
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

/*
uint8_t gfMul(uint8_t a, uint8_t b)
{
    int s = 0;
    s = table[a] + table[b];
    int q;
    */
/* Get the antilog *//*

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
}
*/
