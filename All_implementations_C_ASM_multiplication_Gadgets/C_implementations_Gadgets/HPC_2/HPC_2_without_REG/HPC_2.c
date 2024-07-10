/*
 HPC_2: Fig.5 in "Hardware Private Circuits: From Trivial Composition to Full Verification"
//*/
#include "stdint.h"
#include "stdlib.h" //rand()
#include "HPC_2.h"
#include "string.h" // memcpy func
#include "stdio.h" //printf

/*
    hpc2(INPUT: input_a[Mask_ORD+1], INPUT: input_b[Mask_ORD+1], INPUT: uint8_t* rnd_Ref,INPUT: uint8_t * rnd_DOM, OUTPUT: c[Mask_ORD+1])
    c = a * b
    * works for any field : this program is for field: 2
    * all elements are {0,1}
        The number of randomness: Mask_ORD * (Mask_ORD+1) /2;
        */

////////////////////////////////////////////////
void hpc2(int* input_a, int* input_b, int* rnd, int* c) {

    /* Expanding randomness vector:
    Here the 1-dimension vector (rnd[rand-n]) (r0,r1,r2, ..., r(rand_n-1)) became to a vector[Mask+ORD+1][Mask+ORD+1]
    as below: example for 3-dimension
                                              0   r0   r1
            input: (r0,r1,r2) ---> output:    r0   0   r2
                                              r1  r2    0
    Also, regarding the HPC_2 algorithm:
    u[i][j] = ~a[i] * Reg[r[i][j]];
    v[i][j] = b[j] + r[i][j];
    The randomness is used in two ways:
    1) r[i][j]
    2) Reg[r[i][j]]
    From 1-dimension vector rnd, we have to produce:
     r[Mask_ORD+1][Mask_ORD+1] and Reg[r[Mask_ORD+1][Mask_ORD+1]]
    Where Reg is using a register
    */

    int i, j;
    static int r[Mask_ORD + 1][Mask_ORD + 1]; //r[i][j]

    for (i = 0; i < Mask_ORD + 1; i++) {
        r[i][i] = 0;
        for (j = i + 1; j < Mask_ORD + 1; j++) {
            // index variable is for producing numbers 0 to rand_n = Mask_ORD * (Mask_ORD+1)/2;
            int index = (i * (Mask_ORD + 1)) - (i * (i + 1) / 2) + j - i - 1;
            r[i][j] = rnd[index];
            r[j][i] = rnd[index];
        }
    }


    static int ai_bi[Mask_ORD + 1]; // a[i] * Reg[b[i]]
    static int u[Mask_ORD + 1][Mask_ORD + 1]; //u[i][j]
    static int v[Mask_ORD + 1][Mask_ORD + 1]; //v[i][j]
    static int ai_vij[Mask_ORD + 1][Mask_ORD + 1]; // a[i] * Reg[v[i][j]]
    static int sum_uij_ai_vij; // Sum (Reg[u[i][j]] + Reg[a[i] * Reg[v[i][j]]])


    for(i = 0; i < Mask_ORD+1; i++){
        for(j = 0; j < Mask_ORD+1; j++){
            if(j != i) {
                u[i][j] = !input_a[i] & r[i][j];
                v[i][j] = input_b[j] ^ r[i][j];
            }
        }
    }

    for(i = 0; i < Mask_ORD+1; i++){
        sum_uij_ai_vij =0;
        for(j = 0; j < Mask_ORD+1; j++){
            if(j != i) {
                sum_uij_ai_vij ^= u[i][j] ^ (input_a[i] & v[i][j] ) ;
            }
        }
        c[i] = (input_a[i] & input_b[i]) ^ sum_uij_ai_vij;
    }

}

