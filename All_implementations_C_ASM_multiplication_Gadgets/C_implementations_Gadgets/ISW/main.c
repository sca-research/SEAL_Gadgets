/*Here the correctness of the gadget is checked with random inputs.*/

#include "stdio.h" //printf
#include "stdlib.h" //srand()
#include "time.h"
#include "ISW.h"

uint8_t gmul(uint8_t a, uint8_t b);
void Mask(uint8_t x, uint8_t* rnd, uint8_t* y);
int rnd_n = Mask_ORD * (Mask_ORD+1) /2; // The number of randomness in ISW multiplication gadget
//////////////////////////////////////////////////////////////////////
int main(void)
{
    time_t t;
    srand((unsigned) time(&t));

    for (int i = 0; i < 100; i++) {

        // Inputs
        uint8_t input_a = rand() % 256;
        uint8_t input_b = rand() % 256;

        // Input shares of the Gadget (a=a_0,a_1,...,a_d and b=b_0,b_1,...,b_d)
        static uint8_t a[Mask_ORD+1];
        static uint8_t b[Mask_ORD+1];

        // Output of the Gadget is c_0, c_1, ..., c_d such that c_0 + c_1 + ... + c_d = c (c=a*b)
        uint8_t c[Mask_ORD + 1];

        static uint8_t rnd_a[Mask_ORD]; // Random number for masking input a
        static uint8_t rnd_b[Mask_ORD]; // Random number for masking input b
        static uint8_t rnd_isw[Mask_ORD * (Mask_ORD+1) /2]; // Random number for isw multiplication

        for (int k = 0; k <Mask_ORD; k++) {
            rnd_a[k] = rand() % 256;
            rnd_b[k] = rand() % 256;
        }

        for (int k = 0; k <rnd_n; k++){
            rnd_isw[k] = rand() % 256;
        }

        // Input shares of the Gadget (a=a_0,a_1,...,a_d and b=b_0,b_1,...,b_d)
        Mask(input_a, rnd_a, a);
        Mask(input_b, rnd_b, b);

        /*
        Seminal_ISW(INPUT: a[Mask_ORD+1], INPUT: b[Mask_ORD+1], INPUT: rnd[Mask_ORD * (Mask_ORD+1)/2], OUTPUT: c[Mask_ORD])
        c = a * b
        rnd_isw: random numbers (on_the_fly)*/
        Seminal_ISW(a, b, rnd_isw, c);

        // Verifying the Gadget
        // Comparing the output of the Gadget with the unmasked multiplication
        uint8_t output = 0;
        for (int i = 0; i <= Mask_ORD; i++) {
            output ^= c[i];
        }

        printf("\n____________________________________________________________");
        printf(" \n a: %02x  \n b: %02x", input_a, input_b );
        printf(" \nUnmasked_c = a * b: %02x\nMask_c = a * b: %02x ",gfMul(input_a,input_b) , output);
        if (output != gmul(input_a, input_b)) {
            printf(" \n Error: a = %02x , b = %02x and Num_shares: %0d \n", input_a, input_b, Mask_ORD+1);
            break;
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
        if (b & 1) /* if b is odd, then add the corresponding a to p (final product = sum of all a's corresponding to odd b's) */
            p ^= a; /* since we're in GF(2^m), addition is an XOR */

        if (a & 0x80) /* GF modulo: if a >= 128, then it will overflow when shifted left, so reduce */
            a = (a << 1) ^ 0x11b; /* XOR with the primitive polynomial x^8 + x^4 + x^3 + x + 1 (0b1_0001_1011) – you can change it but it must be irreducible */
        else
            a <<= 1; /* equivalent to a*2 */
        b >>= 1; /* equivalent to b // 2 */
    }
    return p;
}

