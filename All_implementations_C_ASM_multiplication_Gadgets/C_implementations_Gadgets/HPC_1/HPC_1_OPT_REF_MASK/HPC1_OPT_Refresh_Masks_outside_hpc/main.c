/*Here the correctness of the gadget is checked with random inputs (a and b).*/
#include "HPC_1.h"
#include "stdio.h" //printf
#include "stdlib.h" //srand()
#include "time.h"
#include "Opt_Ref_Mask.h"


uint8_t gmul(uint8_t a, uint8_t b);
void Mask(uint8_t x, uint8_t* rnd, uint8_t* y);


//////////////////////////////////////////////////////////////////////
int main(void) {
    time_t t;
    srand((unsigned) time(&t));

    for (int n = 0; n < 1000; n++) {

        // Inputs
        uint8_t input_a = rand() % 256;
        uint8_t input_b = rand() % 256;

        // Input shares of the Gadget (a=a_0,a_1,...,a_d and b=b_0,b_1,...,b_d)
        static uint8_t a[Mask_ORD+1];
        static uint8_t b[Mask_ORD+1];

        // Output of the Gadget is c_0, c_1, ..., c_d such that c_0 + c_1 + ... + c_d = c (c=a*b)
        uint8_t c[Mask_ORD + 1];

/*      Number of randomness:
        DOM_indep: Mask_ORD * (Mask_ORD+1) /2;
        Optimized Refresf Masks: rnd_number(int Mask_order)
        Total randoms in HPC_1: rnd_n(DOM_indep) + rnd_number
        */
        int rnd_n_OPT_Refresh = rnd_number(Mask_ORD); // Number of randomness for Optimized RefreshMasks
        int rnd_n_DOM = Mask_ORD * (Mask_ORD+1) /2; // The number of randomness in DOM_indep multiplication gadget
        int total_rnd_n = rnd_n_OPT_Refresh + rnd_n_DOM;
        static uint8_t rnd_Dom_indep[Mask_ORD * (Mask_ORD+1) /2]; // Random number for Dom_Indep multiplication
               uint8_t rnd_OPT_Refresh[rnd_n_OPT_Refresh];


        static uint8_t rnd_a[Mask_ORD]; // Random number for masking input a
        static uint8_t rnd_b[Mask_ORD]; // Random number for masking input b

        for (int k = 0; k <Mask_ORD; k++) {
            rnd_a[k] = rand() % 256;
            rnd_b[k] = rand() % 256;
        }

        for (int k = 0; k < rnd_n_OPT_Refresh; k++) {
            rnd_OPT_Refresh[k] = rand() % 256;
        }

        for (int k = 0; k < rnd_n_DOM; k++) {
            rnd_Dom_indep[k] = rand() % 256;
        }
//////////////////////////////////////////////////////////////////////////////////
        // Input shares of the Gadget (a=a_0,a_1,...,a_d and b=b_0,b_1,...,b_d)
        Mask(input_a, rnd_a, a);
        Mask(input_b, rnd_b, b);

        uint8_t all_zero_input[Mask_ORD+1] = {0x00}; //a=a_0,a_1,...,a_d, such as a_i =0 --> a_0 +...+ a_d = 0
        static uint8_t share_0_mask[Mask_ORD + 1]; // The output of refresh_mask

        // Computing share_0_mask in advance
        opt_refresh_mask(all_zero_input, rnd_OPT_Refresh, share_0_mask);


        // Calling the HPC_1 gadget
        hpc1(a, b, share_0_mask, rnd_Dom_indep, c);

        // Verifying the gadget
        uint8_t output = 0;
        for (int i = 0; i <= Mask_ORD; i++) {
            output ^= c[i];
        }
        //printf("\nOUT  %02x", output);
        //printf("\ngmul %02x", gmul(input_a, input_b));
        //printf(" \n  a = %02x , b = %02x and Num_shares: %0d \n", input_a, input_b, Mask_ORD + 1);

        if (output != gmul(input_a, input_b)) {
            printf(" \n Error: a = %02x , b = %02x and Num_shares: %0d \n", input_a, input_b, Mask_ORD + 1);
            break;
        }
        else {
            printf(" CORRECT ");
        }
    }

}






void Mask(uint8_t x, uint8_t* rnd, uint8_t* y)
{
    y[Mask_ORD] = x;
    for(int i = 0; i < Mask_ORD; i++)
    {
        y[i]=  rnd[i];
        y[Mask_ORD] ^= y[i];
    }
}




// Cite https://en.wikipedia.org/wiki/Finite_field_arithmetic
    /*
    Multiplication of two numbers (a and b) in the GF(2^8) with the polynomial x^8 + x^4 + x^3 + x + 1
    x^8 + x^4 + x^3 + x + 1---> in binary format:10001011 = 11b
    */
    uint8_t gmul(uint8_t a, uint8_t b) {
        uint8_t p = 0; /* the product of the multiplication */
        while (a && b) {
            if (b &
                1) /* if b is odd, then add the corresponding a to p (final product = sum of all a's corresponding to odd b's) */
                p ^= a; /* since we're in GF(2^m), addition is an XOR */

            if (a & 0x80) /* GF modulo: if a >= 128, then it will overflow when shifted left, so reduce */
                a = (a << 1) ^
                    0x11b; /* XOR with the primitive polynomial x^8 + x^4 + x^3 + x + 1 (0b1_0001_1011) – you can change it but it must be irreducible */
            else
                a <<= 1; /* equivalent to a*2 */
            b >>= 1; /* equivalent to b // 2 */
        }
        return p;
    }
