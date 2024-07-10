/*
Paper: Randomness Complexity of Private Circuits for Multiplication, Algorithm 6
*/
#include "stdint.h"
#include "BBPP_4.h"

/*
    ISW_Belaid_4_Mult(INPUT: input_a[Mask_ORD+1], INPUT: input_b[Mask_ORD+1],INPUT: uint8_t * rnd, OUTPUT: c[Mask_ORD+1])
    c = a * b
        The number of randomness: 5
        */

void Bbpp_4_Mult(uint8_t* a, uint8_t* b,uint8_t* rnd, uint8_t* c)
{

// Computing c[0]
    c[0] =  gfMul(a[0], b[0]) ^
            rnd[0] ^
            gfMul(a[0], b[1]) ^
            gfMul(a[1],b[0]) ^
            rnd[1] ^
            gfMul(a[0], b[2]) ^
            gfMul(a[2], b[0]);

// Computing c[1]
    c[1] =  gfMul(a[1], b[1]) ^
            rnd[1] ^
            gfMul(a[1], b[2]) ^
            gfMul(a[2], b[1]) ^
            rnd[2] ^
            gfMul(a[1], b[3]) ^
            gfMul(a[3], b[1]);



// Computing c[2]
    c[2] =  gfMul(a[2], b[2]) ^
            rnd[2] ^
            gfMul(a[2], b[3]) ^
            gfMul(a[3], b[2]) ^
            rnd[3] ^
            gfMul(a[2], b[4]) ^
            gfMul(a[4], b[2]);


// Computing c[3]
    c[3] =  gfMul(a[3], b[3]) ^
            rnd[3] ^
            gfMul(a[3], b[4]) ^
            gfMul(a[4], b[3]) ^
            rnd[4] ^
            gfMul(a[3], b[0]) ^
            gfMul(a[0], b[3]);

// Computing c[4]
    c[4] =  gfMul(a[4], b[4]) ^
            rnd[4] ^
            gfMul(a[4], b[0]) ^
            gfMul(a[0], b[4]) ^
            rnd[0] ^
            gfMul(a[4], b[1]) ^
            gfMul(a[1], b[4]);
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
