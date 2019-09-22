# ECE_Design
This repo will contain all Code developed during the project as per the requirements 

Authors:
IJ Malemela 
Mpooa Moeketsi 
Mapulane 
Tlotlisang Lekena 

__The following steps are followed to implement the Single Sonar Pinger__ 

_Transmit chirp pulse in Julia_

- chirp pulse generated according to the requirements 
- sent over serial Port to the Teensy 
- Recieved signal is transmitted with the DAC0 on pin A21 
- Goes through amplifier circuit
 
_Recieve the chirp Echoe on Teensy ADC pin A14_

- A conversion character "write(sp,'c')" is sent from the Julia to start sampling
- The recieved signal is printed on the serialPort with write(sp,"p")
- The recieved signal is converted to values and to be processed


_Process the recieved signal in Julia using FFT()_

- Ensure that the recieved signal and transmitted are on the same axis 
- Do FFT()
- Show the output with PyPlot() and do axis adjustments 

_Implement Proper Logic_ to allow interaction with the User

