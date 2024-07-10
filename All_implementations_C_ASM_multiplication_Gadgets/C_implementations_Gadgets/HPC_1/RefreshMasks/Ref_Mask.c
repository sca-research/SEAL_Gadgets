/*RefreshMasks: Algorithm 7 in "Horizontal Side-Channel Attacks and Countermeasures on the ISW Masking Scheme" */

#include "Ref_Mask.h"

int count_rnd =0;

//////////////////////////////////////////////////////////////////////
uint8_t refresh_mask(uint8_t* a, int index_start, int index_end, uint8_t* rnd, uint8_t* d){
    
    static uint8_t b[Mask_ORD+1];
    static uint8_t c[Mask_ORD+1];

    int n = index_end - index_start+1;
    
    if (n == 1){
        d[index_start] = a[index_start];
        return d[index_start];
    }
    
    if (n == 2){
        d[index_start] = a[index_start] ^ rnd[count_rnd];
        d[index_start+1] = a[index_start+1] ^ rnd[count_rnd];
        count_rnd++;
        return d[index_start], d[index_start+1];
    }

    for(int i = 0; i < n/2; i++){
        b[i+index_start] = a[i+index_start] ^ rnd[count_rnd];
        int j = (int)(n/2)+i+index_start;
        b[j] = a[j] ^ rnd[count_rnd];
        count_rnd++;
    }
    
    if ((n % 2) == 1){
        b[n-1] = a[n-1];
    }

    refresh_mask(b, index_start, index_start+(int)(n/2)-1 ,rnd, c);

    refresh_mask(b, index_start + (int)(n/2), index_start + n-1 ,rnd, c);

    for(int i = 0; i < n/2; i++){
        d[i] = c[i] ^ rnd[count_rnd];
        int j =(int) (n/2)+i;
        d[j] = c[j] ^ rnd[count_rnd];
        count_rnd++;
    }
    
    if ((n % 2) == 1){
        d[n-1] = c[n-1];
    }
}
