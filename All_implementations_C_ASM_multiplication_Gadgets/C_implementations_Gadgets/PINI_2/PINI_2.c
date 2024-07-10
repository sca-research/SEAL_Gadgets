// Algorithm 4 : Towards Globally Optimized Masking: From Low Randomness to Low Noise Rate or Probe Isolating Multiplications with Reduced Randomness
//and Security against Horizontal Attacks

#include "stdint.h"
#include "stdlib.h" //rand()
#include "PINI_2.h"
#include "stdio.h" //printf


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

void pini_2(uint8_t* a, uint8_t* b, uint8_t* c) {
    bool correctness = true;
    int i, j = 0;
    uint8_t r1[Mask_ORD + 1];                // r: one dimensional array
    uint8_t s1[Mask_ORD + 1];                // s: one dimensional array
    uint8_t r2[Mask_ORD + 1][Mask_ORD + 1];  // r: two dimensional array
    uint8_t s2[Mask_ORD + 1][Mask_ORD + 1];  // s: two dimensional array
    uint8_t p0[Mask_ORD + 1][Mask_ORD + 1];
    uint8_t p1[Mask_ORD + 1][Mask_ORD + 1];
    uint8_t p2[Mask_ORD + 1][Mask_ORD + 1];
    uint8_t p3[Mask_ORD + 1][Mask_ORD + 1];
    uint8_t c2[Mask_ORD + 1][Mask_ORD + 1];  // c: two dimensional array
    uint8_t t[Mask_ORD + 1][Mask_ORD + 1];


    // init_cprod
    //##############################################################
    for (i = 0; i < Mask_ORD + 1; i++) {
        s1[i] = rand() % 256;
    }
    for (i = 0; i < Mask_ORD + 1; i++) {
        for (j = i + 1; j < Mask_ORD + 1; j++) {
            s2[i][j] = s1[i] ^ s1[j];
            p0[i][j] = gfMul(a[i], s2[i][j]);
            p1[i][j] = gfMul(a[i], (b[j] ^ s2[i][j]));
            p2[i][j] = gfMul(b[i], s2[i][j]);
            p3[i][j] = gfMul(b[i], (a[j] ^ s2[i][j]));
        }
    }

//#######################################################################
    for (i = 0; i < Mask_ORD + 1; i++) {
        for (j = 0; j < (Mask_ORD-i-1)+1; j += 2) {
            r2[i][Mask_ORD - j] = rand() % 256;
        }
    }

    for (j = Mask_ORD - 1; j >= 1; j -= 2) {
        r1[j] = rand() % 256;
    }


//        for (i = 0; i < Mask_ORD + 1; i++) {
    i = 0;
    while((i <Mask_ORD+1) && (correctness))
    {
        c2[i][Mask_ORD] = gfMul(a[i], b[i]);

        for (j = Mask_ORD; j >= i + 2; j -= 2) {
            //### tij = cprod(i, j)
            t[i][j] = r2[i][j] ^ p0[i][j] ^ p1[i][j] ^ p2[i][j] ^ p3[i][j] ^
                      r1[j - 1] ^ p0[i][j - 1] ^ p1[i][j - 1] ^ p2[i][j - 1] ^ p3[i][j - 1];

        //Ensure:
        // ################################################################################################
          if ((t[i][j]) == ((r2[i][j]) ^ gfMul(a[i], b[j]) ^ gfMul(a[j], b[i]) ^
                          (r1[j - 1]) ^ gfMul(a[i], b[j - 1]) ^ gfMul(a[j - 1], b[i]))) {
              correctness = true;
          } else {
            printf("\n  ERROR:i,j: %0d,%0d ", i, j);
              correctness = false;}

          c2[i][j - 2] = c2[i][j] ^ t[i][j];
        }

        if ((i % 2) != (Mask_ORD % 2)) {
            //### tij = cprod'(i, i+1)

            t[i][j] = r2[i][i + 1] ^ p0[i][i + 1] ^ p1[i][i + 1] ^ p2[i][i + 1] ^ p3[i][i + 1];

            //Ensure:
            // ################################################################################################
                if ((t[i][i + 1]) == ((r2[i][i + 1]) ^ gfMul(a[i], b[i + 1]) ^ gfMul(a[i + 1], b[i]))) {
                    correctness = true;
                } else {
                    printf("\n  ERROR:i,j: %0d,%0d ", i, j);
                    correctness = false;
                }

            c2[i][i] = c2[i][i + 1] ^ t[i][i + 1];

            if ((i % 2) & 1) {
                c2[i][0] = c2[i][i] ^ r1[i];
            } else {
                c2[i][0] = c2[i][i];
            }

        } else {
            for (j = i - 1; j >= 0; j--) {
                c2[i][j] = c2[i][j + 1] ^ r2[j][i];
            }
        }

        c[i] = c2[i][0];

        printf("\n c[%d]: %02x", i, c[i]);
    i++;

    }

}
