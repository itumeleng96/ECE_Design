# ECE_Design
This repo contains all Code developed during the project and is established as per the requirements 

Authors:
IJ Malemela, 
Mpooa Moeke,tsi,
Mapulane Makhaba

Process for single SONAR Pinger Implementation By Group 8(Demo) 
Saved in the (Demo) 1D-Sonar Pinger folder
 
_Transmit a chirp pulse_

- Chirp pulse configured with requirements-with Known length
- Send the chirp through the serial port 
- Configure the Teensy to recieve the chirp and transmit to DAC1

_Recieve the  sampled signal_ 

- Use 16 Bit resolution with DMA and send over serial port Buffer 
- Not sure about the 

_Direction Finder  Implementation_
_Milestone 4 -Project_
_The previous milestone is modified to accomodate two recieving channels_

Process for the Direction Finder system
Saved in the (Direction Finder) folder


_Transmit a chirp pulse_

- Chirp pulse is created in the julia environment with the specified requirements.
- The  chirp  pulse is sent through the serial port from the PC (Julia environment)
- The Teensy waits to recieve the chirp and transmit to DAC1

_Recieve the  sampled signal(Echoes from objects)_ 

- 2-16 Bit resolution ADC's with 2-DMA's are used to sample the echoes recieved and data is saved in buffer arrays. 
- The Teensy sends the data in the buffer array to the serial Buffer.
- The recieved data in the  Julia environment is used for signal processing 

_Signal Processing_ 

-The sampled data recieved is processed through a match filter .
-The matched filter output is converted to analytical signal and furthermore to baseband to allow for complex signal analysis.
-Using the Baseband signal ,the phase difference between the two signals is compared and used to calculate the angle of arrival.
-The angle of arrival is used to determine the X and Y positions of the objects detected.
