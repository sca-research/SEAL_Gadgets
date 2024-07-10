/*Here the correctness of the gadget is checked with random inputs (a and b).*/

#include "stdio.h" //printf
#include "stdlib.h" //srand()
#include "time.h"
#include "HPC_2.h"


void Mask(int* y, int x);

//////////////////////////////////////////////////////////////////////
int main(void)
{
    time_t t;
    srand((unsigned) time(&t));

    for (int i = 0; i < 1000; i++) {

        // Different and random inputs
        int input_a = rand() % 2;
        int input_b = rand() % 2;

        static int a[Mask_ORD+1];
        static int b[Mask_ORD+1];
        static int c[Mask_ORD+1];

        // Input shares of the Gadget (a=a_0,a_1,...,a_d and b=b_0,b_1,...,b_d)
        Mask(a, input_a);
        Mask(b, input_b);

        // Random number: on_the_fly
       static int rnd_f[Mask_ORD * (Mask_ORD+1) /2];
        for (int k = 0; k <(Mask_ORD * (Mask_ORD+1) /2); k++){
            rnd_f[k] = rand() % 2;
        }

        // Calling the HPC_2 gadget
        hpc2(a,b , rnd_f, c);

        // Verifying the gadget
        int output = 0;
        for (int i = 0; i <= Mask_ORD; i++) {
            output ^= c[i];
        }
        printf(" \n Unmasked_c = a * b: %0d \n     Mask_c = a * b: %0d\n",(input_a & input_b) , output);

        if (output != (input_a & input_b)) {
            printf(" \n Error for inputs : a = %d , b = %d and Num_shares: %0d \n", input_a, input_b, Mask_ORD+1);
            break;
        }
        else{
            printf(" \n  a = %d , b = %d and Num_shares: %0d \n", input_a, input_b, Mask_ORD+1);
            printf("  CORRECT  ");
        }
    }
}

void Mask(int* y, int x) {
    y[0] = x;
    for (int i = 1; i <= Mask_ORD; i++) {
        y[i] = rand() % 2;
        y[0] = y[0] ^ y[i];
    }
}

