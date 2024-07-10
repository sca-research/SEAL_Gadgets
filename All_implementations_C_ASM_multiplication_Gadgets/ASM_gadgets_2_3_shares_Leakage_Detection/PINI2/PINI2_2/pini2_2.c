
//Algorithm 4, Paper: Towards Globally Optimized Masking: From Low Randomness to Low Noise Rate
//or Probe Isolating Multiplications with Reduced Randomness and Security against Horizontal Attacks

#include <stdio.h>
#include <stdlib.h>
#include "pini2_2.h"

// The shares of input_a and input_b and also random numbers are sent through python code.
// Then just the multiplication is done by the Cortex-M3
// and it's corresponding power is measured via PicoScope


/*The number of shares: Mask_order+1: 1+1=2*/
int  share_n = 2;

/*The number of randomness for gadget: (d = Mask_order) pini2: [d*d/4] + 2d + 1*/
// int rnd_gadget = [1*1/4] + 2*1 + 1 = 0 + 2 + 1 = 3
int rnd_n = 3;

int main( int argc, char* argv[]){
    if( !scale_init(&SCALE_CONF)){
        return -1;
    }

    uint8_t shares_a[4*share_n];
    uint8_t shares_b[4*share_n];
    uint8_t shares_ab[4*share_n];
    uint8_t rnd[4*rnd_n];
    while(true) {

        // Receiving shares of a
        for (int i = 0; i < share_n; i++) {
            shares_a[4*i] = (uint8_t) scale_uart_rd(SCALE_UART_MODE_BLOCKING);
            shares_a[4*i+1]=0;
            shares_a[4*i+2]=0;
            shares_a[4*i+3]=0;
        }

        // Receiving shares of b
        for (int i = 0; i < share_n; i++) {
            shares_b[4*i] = (uint8_t) scale_uart_rd(SCALE_UART_MODE_BLOCKING);
            shares_b[4*i+1]=0;
            shares_b[4*i+2]=0;
            shares_b[4*i+3]=0;
        }

        // Receiving random numbers
        for (int i = 0; i < rnd_n; i++) {
            rnd[4*i] = (uint8_t) scale_uart_rd(SCALE_UART_MODE_BLOCKING);
            rnd[4*i+1]=0;
            rnd[4*i+2]=0;
            rnd[4*i+3]=0;
        }

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        //scale_delay_ms( 0.01 );

//       scale_gpio_wr( SCALE_GPIO_PIN_TRG, true  );

        Pini2_2(shares_a, shares_b, rnd, shares_ab);
        
//       scale_gpio_wr( SCALE_GPIO_PIN_TRG, false );
        //scale_delay_ms( 0.01 );
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // Sending shares of c (c = a * b)
        for (int i = 0; i < share_n; i++) {
            scale_uart_wr(SCALE_UART_MODE_BLOCKING, ((char) shares_ab[4*i]));
            shares_ab[4*i+1]=0;
            shares_ab[4*i+2]=0;
            shares_ab[4*i+3]=0;
        }

    }
    return 0;
}
