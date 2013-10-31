Port-Runner
===========

Master-slave microcontroller communication protocol

Protocol for a strict master-slave communication between any two CPUs. This protocol will essentially give the master full control over all I/O ports and PWM outputs on the slave CPU. Hardware will consist of:
 - 2n + 1 pins of communication between CPUs
 - One pin is used to signal an interrupt to the slave
 - Remaining pins (minimum of 1) will be used to send data once per interrupt 

The master first has a buffer of the data that will be transmitted to the slave. The master sets the data bus to the highest order bits of the buffer, and then sets the interrupt pin to high. The interrupt pin is held high for 5 milliseconds while the slave reads the data on the bus to a buffer. The interrupt pin is then set low. This process is repeated until the master buffer is empty. The whole protocol revolves around virtual ports, which are essentially containers used to group physical pins. When a parallel write is issued to a virtual port, each sequential physical pin takes the state of the next bit of the value. If a PWM write is issued, then all pins associated with that virtual port are assigned that PWM value, if they support PWM. 

The commands that can be sent are as followed:

Setup Command
Bits: 1  L1  L0  V4  V3  V2  V1  V0      2*(L+1) number of bytes

The setup command tells the slave to link the following physical pins to the virtual output specified by V0-V4. L0 and L1 make up a two bit number which is incremented to specify how many bytes follow the command. Up to 256 physical pins can be specified, on 32 virtual outputs. (physical pins can be referenced by more than one virtual port). 

PWM Write Command
Bits: 0  1  P   V4  V3  V2  V1  V0      Value8

Outputs the 8-bit value to virtual output specified by V0-V4. If the port does not support PWM (strictly DIO) then it is set to the value of P, 1 being high, 0 being low.

Multi-bit (parallel) Write Command
Bits: 0  0  P   V4  V3  V2  V1  V0      Value16

Outputs the 16-bit value to the virtual output specified by V0-V4. This command sets each physical pin in the virtual output to precisely one bit in the following 16-bit value. If P is set, the most significant bit of the value is set to the first physical pin in the virtual output. If P is not set, the least significant bit of the value is set to the first physical pin in the virtual output.
