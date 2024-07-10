/*
Paper: Randomness Complexity of Private Circuits for Multiplication, Algorithm 3
*/
#include "stdint.h"
#include "BBPP.h"

/*
    Bbpp_Mult(INPUT: input_a[Mask_ORD+1], INPUT: input_b[Mask_ORD+1],INPUT: uint8_t * rnd, OUTPUT: c[Mask_ORD+1])
    c = a * b
        The number of randomness: Even Mask_ORD: (Mask_ORD * (Mask_ORD)) /4 + Mask_ORD;
                                  Odd  Mask_ORD: ( (Mask_ORD * (Mask_ORD)) -1) /4 + Mask_ORD;
        */

void Bbpp_Mult(uint8_t* input_a, uint8_t* input_b,uint8_t* rnd, uint8_t* c)
{

    int i, j;

    uint8_t r2[Mask_ORD+1][Mask_ORD+1];
    uint8_t r1[Mask_ORD+1];
    uint8_t temp[Mask_ORD+1][Mask_ORD+1];

    // Constructing r1 and r2 from the 1-dimension vector (rnd[rand-n]) (r0,r1,r2, ..., r(rand_n-1)):
    // Counting elements of rnd
    int rnd_i = 0;
    for (i = 0; i <= Mask_ORD; i++){
        for (j = 0; j <= Mask_ORD-i-1; j+=2){
            r2[i][Mask_ORD-j] = rnd[rnd_i];
            rnd_i++;
        }
    }
    for (j = Mask_ORD-1; j >= 1; j-=2){
        r1[j] = rnd[rnd_i];
        rnd_i++;
    }


    for (i = 0; i <=Mask_ORD; i++){
        c[i] = gfMul(input_a[i], input_b[i]);

        for (j = Mask_ORD; j >= i + 2; j-=2){
            temp[i][j] = r2[i][j] ^ (gfMul(input_a[i], input_b[j])) ^ (gfMul(input_a[j], input_b[i]))^
                         r1[j-1] ^ (gfMul(input_a[i], input_b[j-1])) ^ (gfMul(input_a[j-1], input_b[i]));
            c[i] ^= temp[i][j];
        }

        if ((i%2) != (Mask_ORD%2)) {
            temp[i][i+1] = r2[i][i+1] ^ (gfMul(input_a[i], input_b[i+1])) ^ (gfMul(input_a[i+1], input_b[i]));
            c[i] ^=temp[i][i+1];

            if ((i%2)&1){
                c[i] ^= r1[i];
            }
        }

        else{
            for (j = i-1; j >= 0; j--){
                c[i] ^= r2[j][i];
            }
        }

    }
}
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

/* uint8_t gfMul(uint8_t a, uint8_t b)
   {
       int s = 0;
       s = table[a] + table[b];
       int q;
       *//* Get the antilog *//*
        s = table[s+256];
        uint8_t z = 0;
        q = s;
        if(a == 0) {
            s = z;
        } else {
            s = q;
        }
        if(b == 0) {
            s = z;
        } else {
            q = z;
        }
        return s;
    }*/
