CON

  PIN_COUNT  = 32

VAR

  long PWMTable[PIN_COUNT]

PUB Start
  
  cognew(@hires, @PWMTable)



PUB analogWrite(pin, value)

  PWMTable[pin] := value

PUB setPWM(pin, percent)

  PWMTable[pin] := constant((2**32)/100)*percent
                
DAT
' 32-bit PWM with 151.5 kHz switching frequency
' Method uses the carry flag to proportion the on-time of the duty cycles
' Each cycle, the duty cycle of the pin is added to a counter for that
' pin. When this generates a carry, the pin is set to high, otherwise it is low.
' This means the a true duty cycle, that accurately represents the value of the
' signal takes whatever number of cycles it takes to accurately represent that
' the value in fractional form.

' Ex.
' If you write 50% to a pin, the smallest fractional representation is 1/2
' meaning that every two cycles will be a complete duty cycle, with 1 on, and 
' one off, resulting in a PWM frequency of ~75 kHz. If, however, you write
' the value 52%, the smallest accurate representation is 26/50. This means
' That the pin will be on for 26 cycles, and off for 25 cycles. But unlike the
' time proportioning method, this method won't spend 26 steps straight high,
' and then 25 steps low. It will instead distribute these steps evenly to form
' baby-duty cycles, which closely represent 52%. For a perfect representation,
' the duty cycle would be after 50 actual switches and have a frequency of 3 kHz.
' It will appear to be 50%, as it is very close to that value, and after the extra
' 2% has added up enough, it will lengthen the time spent high for one step,
' changing the average time spent high to 52%.

                        org     0
hires
                        mov     counter,#32                  ' Counter used to generate the table of pin HUBRAM addresses
                        mov     pinTableBase,par             ' Move in the HUBRAM address of the pin values table
                        
' Initializes a table containing the HUBRAM address of every pin
' in order to avoid having to increment a reference address each
' time we have to access the table, thus increasing speed.
setup
                        mov     dutyReg,#pinAddresses        ' Move the base pin COGRAM address to the dutyReg (sorry for meaningless name, recycled register)
                        add     dutyReg,#32                  ' Go to end of table
                        sub     dutyReg,counter              ' Index backwards based on counter
                        movd    tableSet,dutyReg             ' Move the register number into the destination for the next instruction
tableSet
                        mov     0000,pinTableBase            ' Store current HUBRAM address
                        add     pinTableBase,#4              ' Increment to next 32-bit int
                        djnz    counter,#setup               ' continue making table       
                        
dutyStart               
                        rdlong  dutyReg,pinAddresses         ' Read the value of the zero-th pin into the dutyReg
                        add     dutyTable,dutyReg       wc   ' Add to the accumulator
              if_c      or      buffer,pinMask00             ' If a carry was generated, set the pin to high
              
                        rdlong  dutyReg,pinAddresses+1       ' repeat this process, each time going to the next pin, and next 
                        add     dutyTable+1,dutyReg       wc
              if_c      or      buffer,pinMask01 

                        rdlong  dutyReg,pinAddresses+2       ' This goes on 32 times. Once per pin.
                        add     dutyTable+2,dutyReg       wc
              if_c      or      buffer,pinMask02 

                        rdlong  dutyReg,pinAddresses+3
                        add     dutyTable+3,dutyReg       wc
              if_c      or      buffer,pinMask03 

                        rdlong  dutyReg,pinAddresses+4
                        add     dutyTable+4,dutyReg       wc
              if_c      or      buffer,pinMask04 

                        rdlong  dutyReg,pinAddresses+5
                        add     dutyTable+5,dutyReg       wc
              if_c      or      buffer,pinMask05 

                        rdlong  dutyReg,pinAddresses+6
                        add     dutyTable+6,dutyReg       wc
              if_c      or      buffer,pinMask06 

                        rdlong  dutyReg,pinAddresses+7
                        add     dutyTable+7,dutyReg       wc
              if_c      or      buffer,pinMask07 

                        rdlong  dutyReg,pinAddresses+8
                        add     dutyTable+8,dutyReg       wc
              if_c      or      buffer,pinMask08 

                        rdlong  dutyReg,pinAddresses+9
                        add     dutyTable+9,dutyReg       wc
              if_c      or      buffer,pinMask09 

                        rdlong  dutyReg,pinAddresses+10
                        add     dutyTable+10,dutyReg       wc
              if_c      or      buffer,pinMask0A 

                        rdlong  dutyReg,pinAddresses+11
                        add     dutyTable+11,dutyReg       wc
              if_c      or      buffer,pinMask0B 

                        rdlong  dutyReg,pinAddresses+12
                        add     dutyTable+12,dutyReg       wc
              if_c      or      buffer,pinMask0C 

                        rdlong  dutyReg,pinAddresses+13
                        add     dutyTable+13,dutyReg       wc
              if_c      or      buffer,pinMask0D 

                        rdlong  dutyReg,pinAddresses+14
                        add     dutyTable+14,dutyReg       wc
              if_c      or      buffer,pinMask0E 

                        rdlong  dutyReg,pinAddresses+15
                        add     dutyTable+15,dutyReg       wc
              if_c      or      buffer,pinMask0F 

                        rdlong  dutyReg,pinAddresses+16
                        add     dutyTable+16,dutyReg       wc
              if_c      or      buffer,pinMask10 

                        rdlong  dutyReg,pinAddresses+17
                        add     dutyTable+17,dutyReg       wc
              if_c      or      buffer,pinMask11 

                        rdlong  dutyReg,pinAddresses+18
                        add     dutyTable+18,dutyReg       wc
              if_c      or      buffer,pinMask12 

                        rdlong  dutyReg,pinAddresses+19
                        add     dutyTable+19,dutyReg       wc
              if_c      or      buffer,pinMask13 

                        rdlong  dutyReg,pinAddresses+20
                        add     dutyTable+20,dutyReg       wc
              if_c      or      buffer,pinMask14 

                        rdlong  dutyReg,pinAddresses+21
                        add     dutyTable+21,dutyReg       wc
              if_c      or      buffer,pinMask15 

                        rdlong  dutyReg,pinAddresses+22
                        add     dutyTable+22,dutyReg       wc
              if_c      or      buffer,pinMask16 

                        rdlong  dutyReg,pinAddresses+23
                        add     dutyTable+23,dutyReg       wc
              if_c      or      buffer,pinMask17 

                        rdlong  dutyReg,pinAddresses+24
                        add     dutyTable+24,dutyReg       wc
              if_c      or      buffer,pinMask18 

                        rdlong  dutyReg,pinAddresses+25
                        add     dutyTable+25,dutyReg       wc
              if_c      or      buffer,pinMask19 

                        rdlong  dutyReg,pinAddresses+26
                        add     dutyTable+26,dutyReg       wc
              if_c      or      buffer,pinMask1A 

                        rdlong  dutyReg,pinAddresses+27
                        add     dutyTable+27,dutyReg       wc
              if_c      or      buffer,pinMask1B 

                        rdlong  dutyReg,pinAddresses+28
                        add     dutyTable+28,dutyReg       wc
              if_c      or      buffer,pinMask1C 

                        rdlong  dutyReg,pinAddresses+29
                        add     dutyTable+29,dutyReg       wc
              if_c      or      buffer,pinMask1D 

                        rdlong  dutyReg,pinAddresses+30
                        add     dutyTable+30,dutyReg       wc
              if_c      or      buffer,pinMask1E 

                        rdlong  dutyReg,pinAddresses+31
                        add     dutyTable+31,dutyReg       wc
              if_c      or      buffer,pinMask1F 

                        mov     dira,buffer                     ' Set those pins to output                       
                        mov     outa,buffer                     ' Write high to the pins set      
                        xor     buffer,buffer                   ' Clear buffer for next cycle
                        jmp     #dutyStart                      ' Go to next cycle

' Pin mask table used to set pins                        
pinMask00     long      %0000_0000_0000_0000_0000_0000_0000_0001
pinMask01     long      %0000_0000_0000_0000_0000_0000_0000_0010
pinMask02     long      %0000_0000_0000_0000_0000_0000_0000_0100
pinMask03     long      %0000_0000_0000_0000_0000_0000_0000_1000
pinMask04     long      %0000_0000_0000_0000_0000_0000_0001_0000
pinMask05     long      %0000_0000_0000_0000_0000_0000_0010_0000
pinMask06     long      %0000_0000_0000_0000_0000_0000_0100_0000
pinMask07     long      %0000_0000_0000_0000_0000_0000_1000_0000
pinMask08     long      %0000_0000_0000_0000_0000_0001_0000_0000
pinMask09     long      %0000_0000_0000_0000_0000_0010_0000_0000
pinMask0A     long      %0000_0000_0000_0000_0000_0100_0000_0000
pinMask0B     long      %0000_0000_0000_0000_0000_1000_0000_0000
pinMask0C     long      %0000_0000_0000_0000_0001_0000_0000_0000
pinMask0D     long      %0000_0000_0000_0000_0010_0000_0000_0000
pinMask0E     long      %0000_0000_0000_0000_0100_0000_0000_0000
pinMask0F     long      %0000_0000_0000_0000_1000_0000_0000_0000
pinMask10     long      %0000_0000_0000_0001_0000_0000_0000_0000
pinMask11     long      %0000_0000_0000_0010_0000_0000_0000_0000
pinMask12     long      %0000_0000_0000_0100_0000_0000_0000_0000
pinMask13     long      %0000_0000_0000_1000_0000_0000_0000_0000
pinMask14     long      %0000_0000_0001_0000_0000_0000_0000_0000
pinMask15     long      %0000_0000_0010_0000_0000_0000_0000_0000
pinMask16     long      %0000_0000_0100_0000_0000_0000_0000_0000
pinMask17     long      %0000_0000_1000_0000_0000_0000_0000_0000
pinMask18     long      %0000_0001_0000_0000_0000_0000_0000_0000
pinMask19     long      %0000_0010_0000_0000_0000_0000_0000_0000
pinMask1A     long      %0000_0100_0000_0000_0000_0000_0000_0000
pinMask1B     long      %0000_1000_0000_0000_0000_0000_0000_0000
pinMask1C     long      %0001_0000_0000_0000_0000_0000_0000_0000
pinMask1D     long      %0010_0000_0000_0000_0000_0000_0000_0000
pinMask1E     long      %0100_0000_0000_0000_0000_0000_0000_0000
pinMask1F     long      %1000_0000_0000_0000_0000_0000_0000_0000

dutyReg       res       1    ' Register that duty cycle gets read into
counter       res       1    ' Counter for generating the address table
pinTableBase  res       1    ' HUBRAM address of pin addresses
buffer        res       1    ' Bitmask buffer
pinAddresses  res       32   ' Table of HUBRAM addresses
dutyTable     res       32   ' Table of accumulators for each pins duty cycle     
                        FIT
                        