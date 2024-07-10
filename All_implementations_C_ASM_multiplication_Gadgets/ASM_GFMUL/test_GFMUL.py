import serial
import secrets
import sys
from time import sleep


def gf_mult(a, b):
    """ Multiplication in the Galois field GF(2^8) """
    p = 0  # The product of the multiplication
    over_f = 0
    for i in range(8):
        # if b is odd, then add the corresponding a to p (final product = sum of all a's corresponding to odd b's)
        if b & 1 == 1:
            p ^= a  # since we're in GF(2^m), addition is an XOR

        over_f = a & 0x80
        a <<= 1
        if over_f == 0x80:
            a ^= 0x1b  # GF modulo: if a >= 128, then it will overflow when shifted left, so reduce
        b >>= 1
    return p % 256


def uart(ser_port, num_repeat):
    """ This function enables the serial_port, and transmits tx_data
        from the PC to the device connected with the PC and receives
        rx_data from the device to the PC. Also it repeats the TX and RX
        transactions num_repeat times"""

    # The length of the TX data in Byte (B)
    # The TX data is: input_a and input_b
    ##################################################
    inputs_len = 2  # input_a: 1B, input_b: 1B

    # The length of the RX data in Byte (B)
    # The RX data is: output_c (output_c = input_a * input_b)
    ##################################################
    output_len = 1 # output_c

    print("Input length:  ", inputs_len)
    print("Output length: ", output_len)

    # Enabling the serial port
    ##################################################
    serial_p = serial.Serial(ser_port)

    if serial_p.is_open:
        print("\n ********************* START ********************* \n")

    for i in range(num_repeat):

        # Generating random inputs (input_a, input_b)
        in_a = secrets.randbits(8)  # type: int
        in_b = secrets.randbits(8)  # type: int

        input_a = in_a.to_bytes(1, sys.byteorder)
        input_b = in_b.to_bytes(1, sys.byteorder)

        inputs = input_a + input_b
        # Wait
        # tx: Transmitting input data serially from the PC to the Board by UART Serial Port
        sleep(0.08)
        serial_p.write(inputs)

        # rx: Receiving output data serially from the Board to the PC  by UART Serial Port
        output_c = (serial_p.read(output_len))

        # Checking the correctness of the Multiplication and printing on the screen
        #################################################
        # Checking the output of gfmulASSEMBLY  with the output of gfmulPYTHON
        gfmul = (gf_mult(in_a, in_b)).to_bytes(1, sys.byteorder)
        #  Checking the output of gadget with the output of gf_mult
        if gfmul != output_c:
            print("ERROR: gmul(in_b, in_a) != output of gadget")
            break
        # Printing the data on screen after "step" times executions

        print('- a: {}'.format(input_a.hex()))
        print('- b: {}'.format(input_b.hex()))
        print('- c: {}'.format(output_c.hex()))
        print('- gfm: {}'.format((gf_mult(in_a, in_b)).to_bytes(1, sys.byteorder).hex()))
        print('___________________________________________________________________')

    print('Serial port: {}'.format(serial_p.name))
    print('___________________________________________________________________')

    # Disabling the serial port
    serial_p.close()

    if not serial_p.is_open:
        print("\n ********************* END ********************* \n")

    return


if __name__ == '__main__':
    serial_port = '/dev/ttyUSB0'

    # The number of running the program
    num = 100
    uart(serial_port, num)
