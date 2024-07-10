//Algorithm 2, Paper: Trivially and Efficiently Composing Masked Gadgets with Probe Isolating Non-Interference

#include "stdint.h"
#include "stdlib.h" //rand()
#include "PINI_1.h"
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



void pini_1(uint8_t* a, uint8_t* b, uint8_t* c) {
    bool correctness = true;
    int i, j;

    uint8_t r[Mask_ORD + 1][Mask_ORD + 1];
    uint8_t s[Mask_ORD + 1][Mask_ORD + 1];
    uint8_t p0[Mask_ORD + 1][Mask_ORD + 1];
    uint8_t p1[Mask_ORD + 1][Mask_ORD + 1];
    uint8_t z[Mask_ORD + 1][Mask_ORD + 1];


    for (i = 0; i < Mask_ORD + 1; i++) {
        for (j = i + 1; j < Mask_ORD + 1; j++) {
            r[i][j] = rand() % 256;
            r[j][i] = r[i][j];
        }
    }

//    for (i = 0; i < Mask_ORD + 1; i++) {
    i = 0;
    while((i <Mask_ORD+1) && (correctness)){
        for (j = 0; j < Mask_ORD + 1; j++) {
            if (i != j) {
                s[i][j] = b[j] ^ r[i][j];
                //r[i][j] ^ (a[i] * r[i][j]) = r[i][j] * (a[i] ^ 1) = r[i][j] *(a[i] ^ 0x01) = r[i][j]
                p0[i][j] = gfMul((a[i] ^ 0x01) , r[i][j]);
                p1[i][j] = gfMul(a[i], s[i][j]);
                z[i][j] = p0[i][j] ^ p1[i][j];

                //Ensure:
                if ((z[i][j]) == ((r[i][j]) ^ gfMul(a[i], b[j]))) {
                    continue;
                } else {

                    printf("\n The ensure step is not satisfied, \n (z[i][j]) != (r[i][j]) ^ gfMul(a[i], b[j])\n");
                    correctness = false;
                }
            }
        }
        i++;

    }

    for (i = 0; i < Mask_ORD + 1; i++) {
        c[i] = gfMul(a[i], b[i]);

        for (j = 0; j < Mask_ORD + 1; j++) {
            if (i != j) {
                c[i] ^= z[i][j];
            }
        }

    }
}

