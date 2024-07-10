#include <stdio.h>
#include <stdint.h>
#include "stdlib.h" //srand()
#include "time.h"
#include "mask_f2.h"



// Testing Mask func for different inputs
int main()
{
    time_t t;
    srand((unsigned) time(&t));

    uint32_t  masked_out;

    for(int j =0; j<1000; j++) {
        printf("\nj  %d +++++++++++++++++++++++++++++++++++++  ", j);

        // Random input
        int unmasked_in=rand()%2;
        printf("\n unmask_input: %d ", unmasked_in);

        masked_out = Mask(unmasked_in);
        printf("\n masked_out:  %02x \n", masked_out);

        // Verifying the mask func
        int d = 0;
        for (int i = Mask_ORD; i >= 0; i--) {
            printf("%d", (masked_out >> i) & 1);
            d ^= (masked_out >> i) & 1;
        }
        if (d != unmasked_in) {
            printf("\n error ");
            break;
        }
    }
    return 0;
}

