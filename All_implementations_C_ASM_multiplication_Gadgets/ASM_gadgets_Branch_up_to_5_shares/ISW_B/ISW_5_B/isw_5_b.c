#include <stdio.h>
#include <stdlib.h>
#include "isw_5_b.h"

// The shares of input_a and input_b and also random numbers are sent through python code.
// Then just the multiplication is done by the Cortex-M3
// and it's corresponding power is measured via PicoScope


/*The number of shares: Mask_order+1: 1+1=2*/
int  share_n = 5;

/*The number of randomness for gadget: ISW: share_n *(share_n - 1)/2 */
// int rnd_gadget = share_n *(share_n - 1)/2;
int rnd_n = 10;

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

        Isw_5(shares_a, shares_b, rnd, shares_ab);

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


