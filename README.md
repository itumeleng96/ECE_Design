# ECE_Design
This repo contains all Code developed during the project and is established as per the requirements 

Authors:
IJ Malemela 
Mpooa Moeketsi 
Mapulane 

Process for single SONAR Pinger Implementation By Group 8(Demo) 
Saved in the (Demo) 1D-Sonar Pinger folder
 
_Transmit a chirp pulse_

- Chirp pulse configured with requirements-with Known length
- Send the chirp through the serial port 
- Configure the Teensy to recieve the chirp and transmit to DAC1

_Recieve the  sampled signal_ 

- Use 16 Bit resolution with DMA and send over serial port Buffer 
- Not sure about the 

Direction Finder  Implementation
Milestone 4 -Project intitiation at 30 September
To meet the requirements of this milestone ,the previous milestone is modified to accomodate two recieving channels.

Process for the Direction Finder system
Saved in the (Direction Finder) folder


_Transmit a chirp pulse_

- Chirp pulse configured with requirements-with Known length
- Send the chirp through the serial port from the PC (Julia environment)
- The Teensy waits to recieve the chirp and transmit to DAC1

_Recieve the  sampled signal(Echoes from objects)_ 

- 2-16 Bit resolution ADC's with 2-DMA's are used to sample the echoes recieved and saved in buffer arrays. 
- The Teensy sends the data in the buffer array to the serial Buffer.

_Signal Processing_ 

-The sampled data recieved is processed through a match filter .
-The matched filter output is converted to analytical signal and furthermore to baseband to allow for complex signal analysis.
-Using the Baseband signal ,the phase difference between the two signals is compared and used to calculate the angle of arrival.
-The angle of arrival is used to determine the X and Y positions of the objects detected.
