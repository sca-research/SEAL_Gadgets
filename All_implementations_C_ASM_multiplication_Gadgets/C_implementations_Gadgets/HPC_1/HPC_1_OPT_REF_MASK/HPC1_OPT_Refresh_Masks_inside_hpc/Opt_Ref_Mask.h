#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include "time.h"

#ifndef Mask_ORD
#define Mask_ORD 2
#endif

void  opt_refresh_mask(uint8_t* a, uint8_t* rnd, uint8_t* out);
int rnd_number(int Mask_order); // The number of randomness in Optimized RefreshMask
