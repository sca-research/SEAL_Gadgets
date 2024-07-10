/*Here the correctness of the RefreshMasks is checked with random inputs.*/
#include "Ref_Mask.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "time.h"
#include "math.h"

void Mask(uint8_t* y, uint8_t x);

//////////////////////////////////////////////////////////////////////
int main(void)
{
// The number of randomness in RefresfMasks
    int rnd_n = ((Mask_ORD+1) * log(Mask_ORD+1)) +1 ;

    time_t t;
    srand((unsigned) time(&t));

    for (int n = 0; n < 3; n++) {

        // random inputs
        uint8_t input_a = rand() % 256;
        uint8_t mask_in[Mask_ORD+1];
        uint8_t d[Mask_ORD + 1];

        // Random number: on_the_fly
        uint8_t rnd_f[rnd_n];
        for (int k = 0; k <rnd_n; k++){
            rnd_f[k] = rand() % 256;
            //printf( "  %02x  ", rnd_f[k]);
        }

        Mask(mask_in, input_a);

        // Calling RefreshMasks
        refresh_mask(mask_in, 0, Mask_ORD, rnd_f, d);


        // Verifying the RefreshMasks
        uint8_t output = 0;
        for (int i = 0; i <= Mask_ORD; i++) {
            output ^= d[i];
        }
        printf("\nOUT %02x", output);

        printf("\nin %02x", input_a);
        printf("\n++++++++++++++++++++++\n");


    }
}

void Mask(uint8_t* y, uint8_t x)
{
    y[0] = x;
    for(int i = 1; i <= Mask_ORD; i++)
    {
        y[i]=  rand() % 256;
        y[0] = y[0] ^ y[i];
    }
}
