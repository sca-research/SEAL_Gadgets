// Mask Function
// Masking one bit

#include <stdio.h>
#include <stdint.h>
#include "stdlib.h" //srand()
#include "mask_f2.h"

uint32_t Mask( int input){
    uint32_t masked_in = 0;
    int last_share = input;
    for(int i = 1; i < Mask_ORD+1; i++){
        int rnd_share =  rand()%2;
        printf("\n rnd %d ", rnd_share);
        masked_in = masked_in<<1 | rnd_share ;
        last_share ^= rnd_share;
    }
     masked_in =  masked_in<<1 | last_share ;
    return masked_in;
}