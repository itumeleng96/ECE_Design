
sp = SerialPort(list_serialports()[1], 9600)  # port of the Teensy if connected

#create a chirp Pulse to be sent to the Teensy and plot
B=1715					                     #Bandwidth of the chirp signal
f=40000					                     #Center Frequency
T=6E-3 					                     # Chirp Pulse length
K=B/T 					                     # Chirp rate
dt=1/2000000                                                 # The  sampling rate was found to be 2Msamples/second
t_max=20/343                                                 #max time to reach 10 meters and back is 58 miliseconds
t_d=T/2;
t_max_pulse=T;
t = collect(0:dt:t_max_pulse);
rect(t)=(abs.(t) .<=0.5)*1.0;
v_tx = UInt8.(round.((cos.(2*pi*(f*(t.-t_d).+0.5*K*(t.-t_d).^2)).*rect((t .-t_d)/T).+1).*127));

#plot(t,v_tx)
s = readavailable(sp)
write(sp,'c')	 	         	            # write an array of Uint8 to the port
s = readavailable(sp) 		                # read ADC string values from the port
