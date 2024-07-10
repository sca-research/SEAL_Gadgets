#include <stdio.h>
#include <stdlib.h>
#include "gf_mul.h"

// The input_a and input_b are sent through TX serial port (python code).
// Then just the multiplication is done by the Cortex-M3
// and it's corresponding result (c = a * b) is sent via RX.


int main( int argc, char* argv[]){
    if( !scale_init(&SCALE_CONF)){
        return -1;
    }

    uint8_t in_a;
    uint8_t in_b;
    uint8_t out_c;   // c = a * b

    while(true) {
        bool t = scale_gpio_rd( SCALE_GPIO_PIN_GPI);
        scale_gpio_wr( SCALE_GPIO_PIN_GPO, t);

        in_a = (uint8_t) scale_uart_rd(SCALE_UART_MODE_BLOCKING);
        in_b = (uint8_t) scale_uart_rd(SCALE_UART_MODE_BLOCKING);

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        //scale_gpio_wr( SCALE_GPIO_PIN_TRG, true  );

        gfmul(&in_a, &in_b, &out_c);

        //scale_gpio_wr( SCALE_GPIO_PIN_TRG, false );
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////////////////////////////////////////////////////////////////////////////////////////

        scale_uart_wr(SCALE_UART_MODE_BLOCKING, ((char) out_c));

    }
    return 0;
}

