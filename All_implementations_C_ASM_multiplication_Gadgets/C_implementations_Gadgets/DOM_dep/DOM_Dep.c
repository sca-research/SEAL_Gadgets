//DOM-dep: Algorithm2 in  "Glitch-Resistant Masking Revisited or Why Proofs in the Robust Probing Model are Needed"
// Based on the description in "Domain-oriented  masking:Compact masked hardware implementations with arbitrary protection orde"
#include "stdint.h"
#include "DOM_Dep.h"
#include "stdio.h" //printf

void DOM_dependent(uint8_t* a, uint8_t* b, uint8_t* rnd, uint8_t* c)
{
    int i = 0;
    uint8_t out_Dom_indep[Mask_ORD+1];
    uint8_t z[Mask_ORD+1]; // Randomness for masking  the input b (b0-bd)
    uint8_t rnd_dom_indep[Mask_ORD * (Mask_ORD+1) /2]; // Randomness for DOM_independent function
    uint8_t x[Mask_ORD+1]; // Masked b (x0-xd)
    uint8_t x_sum = 0;


    // The first d (Mask_ORD) randomnesses in rnd is z[Mask_ORD+1] = rnd[0:Mask_ORD],
    // and is used for computing x[i] = b[i] ^ z[i]
    for (i = 0; i < Mask_ORD+1; i++)
    {
        x[i] = b[i] ^ rnd[i];
        z[i] = rnd[i];
    }

    x_sum = decode(x);

    // The last (Mask_ORD * (Mask_ORD+1) /2) randomnesses in rnd is rnd_dom_indep[    uint8_t rnd_dom_indep[Mask_ORD * (Mask_ORD+1) /2];
    // and is used in DOM_independent function
    int rnd_n_dom = Mask_ORD * (Mask_ORD+1)/2;

    for (i = 0; i < rnd_n_dom; i++)
    {
        rnd_dom_indep[i] = rnd[Mask_ORD+1+i];
    }
    DOM_independent(a, z, rnd_dom_indep, out_Dom_indep);

    for (i = 0; i < Mask_ORD+1; i++)
    {
        c[i] = out_Dom_indep[i] ^ (gfMul(a[i] , x_sum));
    }
}

void DOM_independent(uint8_t* a, uint8_t* b, uint8_t* rnd, uint8_t* c)
{
    int i, j = 0;
    // The number of randomness in DOM_indep multiplication gadget
    int rand_n = Mask_ORD * (Mask_ORD+1)/2;

    uint8_t cross_product[2*rand_n];

    for (i = 0; i < Mask_ORD + 1; i++)
    {
        uint8_t output = 0;
        for (j = 0; j < Mask_ORD + 1; j++)
        {
            int p = (Mask_ORD ) * i + j;
            if (i == j)
            {
                // Inner_products
                output = output ^  gfMul(a[i], b[j]);
            }
            else if (j > i)
            {
                cross_product[p] = (gfMul(a[i], b[j])) ^ rnd[i + (j*(j-1)/2)];
            }
            else
            {
                cross_product[p] = (gfMul(a[i], b[j])) ^ rnd[j + (i*(i-1)/2)];
            }
            if (i!=j)
            {
                output = output ^ cross_product[p];
            }
        }
        c[i] = output;
    }
}

// x=[x0, x1, ..., xd], sum=x0 + x1 +...+ xd
uint8_t decode(uint8_t* x)
{
    uint8_t sum = 0;
    for(int i=0; i< Mask_ORD+1; i++)
    {
        sum ^= x[i];
    }
    return sum;
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
