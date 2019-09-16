#IJ Malemela 
#This is code for getting serial Data from the Teensy Board

#Using serial Ports to recieve data from Teensy

using SerialPorts
using FFTW
using PyPlot
#@show list_serialports()

sp = SerialPort(list_serialports()[1], 9600)  # port of the Teensy if connected

#create a chirp Pulse to be sent to the Teensy and plot 
B=1715					      #Bandwidth of the chirp signal
f=40000					      #Center Frequency 
T=6E-3 					      # Chirp Pulse length
K=B/T 					      # Chirp rate
dt=1/44000;
t_max=20/343;

t = collect(0:dt:t_max);
rect(t)=(abs.(t) .<=0.5)*1.0;
v_tx = UInt8.(round.((cos.(2*pi*(f*t).+0.5*K*t.^2).+1).*127).*rect(t/T));

plot(v_tx);
write(sp, v_tx)	 	       	      # write a string to the port
x = readavailable(sp) 		              # read from the port
#println("Echo server response")	              # echo server response
v_rx=Vector{UInt8}(x);
plot(v_rx);

#close(sp)			              # close the port

# ADCvalue = x[n]*256 + x[n+1]
