/*Here the correctness of the gadget is checked with random inputs (a and b).*/

#include "stdio.h" //printf
#include "stdlib.h" //srand()
#include "time.h"
#include "PINI_2.h"
uint8_t gmul(uint8_t a, uint8_t b);

//////////////////////////////////////////////////////////////////////
int main(void)
{
    time_t t;
    srand((unsigned) time(&t));
//    int share_n = Mask_ORD + 1;
    int counter = 0;
    static uint8_t shares_a[Mask_ORD + 1];
    static uint8_t shares_b[Mask_ORD + 1];
    static uint8_t shares_ab[Mask_ORD + 1];
    uint8_t in_a = 0;
    uint8_t in_b = 0;

    bool correctness = true;
    while ((counter < 1000) && correctness){

        in_a = rand() % 256;
        in_b = rand() % 256;


        Mask(in_a, shares_a, Mask_ORD);
        Mask(in_b, shares_b, Mask_ORD);

        pini_2(shares_a, shares_b, shares_ab);

        uint8_t output = 0;
        for (int j = 0; j <= Mask_ORD; j++) {
            output ^= shares_ab[j];
        }

        if (output != gmul(in_a, in_b)) {
            printf(" \n i = %0d Error for inputs : a = %02x , b = %02x and Num_shares: %0d \n",counter, in_a, in_b, Mask_ORD+1);
            correctness = false;
        }
        else{
            printf("\n  CORRECT: output: %02x", output);
        }

        printf("\n [+] counter = %0d --------------------------------------------------------------\n", counter);
        counter++;

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

void Mask(uint8_t x, uint8_t* y, int M_ORD)
{
    y[0] = x;
    for(int i = 1; i <= M_ORD; i++)
    {
        y[i]=  rand() % 256;
        y[0] = y[0] ^ y[i];
    }
}
