/*
DOM-dep: Algorithm2 in  "Glitch-Resistant Masking Revisited or Why Proofs in the Robust Probing Model are Needed"
Based on the description in "Domain-oriented  masking:Compact masked hardware implementations with arbitrary protection order""
*/

#include <stdio.h>
#include <stdlib.h>
#include "dom_dep_3_b.h"


// The shares of input_a and input_b and also random numbers are sent through python code.
// Then just the multiplication is done by the Cortex-M3
// and it's corresponding power is measured via PicoScope


/*The number of shares: Mask_order+1: 1+1=2*/
int  share_n = 3;

/*The number of randomness for gadget: DOM-dep:
The number of randomness for Dom_dep: Mask_ORD+1 + Mask_order*(Mask_order + 1)/2*/
int rnd_n = 6;

int main( int argc, char* argv[]){
    if( !scale_init(&SCALE_CONF)){
        return -1;
    }


    uint8_t shares_a[share_n];
    uint8_t shares_b[share_n];
    uint8_t shares_ab[share_n];
    uint8_t rnd[rnd_n];
    while(true) {

        // Receiving shares of a
        for (int i = 0; i < share_n; i++) {
            shares_a[i] = (uint8_t) scale_uart_rd(SCALE_UART_MODE_BLOCKING);
        }

        // Receiving shares of b
        for (int i = 0; i < share_n; i++) {
            shares_b[i] = (uint8_t) scale_uart_rd(SCALE_UART_MODE_BLOCKING);
        }

        // Receiving random numbers
        for (int i = 0; i < rnd_n; i++) {
            rnd[i] = (uint8_t) scale_uart_rd(SCALE_UART_MODE_BLOCKING);
        }

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        //scale_delay_ms( 0.01 );

    //   scale_gpio_wr( SCALE_GPIO_PIN_TRG, true  );

        Dom_dep_3(shares_a, shares_b, rnd, shares_ab);

    //   scale_gpio_wr( SCALE_GPIO_PIN_TRG, false );
        //scale_delay_ms( 0.01 );
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // Sending shares of c (c = a * b)
        for (int i = 0; i < share_n; i++) {
            scale_uart_wr(SCALE_UART_MODE_BLOCKING, ((char) shares_ab[i]));
        }
    }
    return 0;
}



