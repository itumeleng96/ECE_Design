function chirp()
        #create a chirp Pulse to be sent to the Teensy and plot
        B=1715                                                       #Bandwidth of the chirp signal
        f=40000                                                      #Center Frequency
        T=6E-3                                                       # Chirp Pulse length
        K=B/T                                                        # Chirp rate
        fs=2000000
        dt=1/fs                              # The  sampling rate was found to be 2Msamples/second
        t_max=20/343                         #max time to reach 10 meters and back is 58 miliseconds
        t_d=T/2;
        t_max_pulse=T;
        t = collect(0:dt:t_max_pulse);
        rect(t)=(abs.(t) .<=0.5)*1.0;
        return  UInt8.(round.((cos.(2*pi*(f*(t.-t_d).+0.5*K*(t.-t_d).^2)).*rect((t .-t_d)/T).+1).*127));
end

function chirpMatch()
        f=40000
	      T=6E-3                                                       # Chirp Pulse length
        B= 1715
	      K=B/T                                                        # Chirp rate
        fs=500000
        dt=1/fs                                                      # The  sampling rate was found to be 2Msamples/second
        t_max=(20/343) +10E-3                                        # max time to reach 10 meters and back is 58 miliseconds
        t_d=T/2;
        t_max_pulse=T;
        rect(t)=(abs.(t) .<=0.5)*1.0;
        t_match=collect(0:dt:t_max);
        return cos.(2*pi*(f*(t_match.-t_d).+0.5*K*(t_match.-t_d).^2)).*rect((t_match .-t_d)/T);
end

function convertBuffer(sp)
  a=""
  i=0
  #Getting the ADC data
  while true
	 x=readavailable(sp)      #read from the buffer
	  if bytesavailable(sp)<1 #check if there is still data in the buffer
		    sleep(0.05)
		    if bytesavailable(sp)<1
			     break
		    end
	  end
	  a=string(a,x)
  end
  adc=split(a,"\r\n")
  len=length(adc)-1
  v=Vector{Int64}(undef,len)
  for i=1:len
           v[i]=parse(Int64,adc[i])
  end
  return v
end

@time using SerialPorts
@time using FFTW;
@time using PyPlot;
sp = SerialPort(list_serialports()[1], 9600)  # USB port of the Teensy board for serial to connect

v_tx=chirp() 	                    			      #returns chirp pulse according to specs
s=readavailable(sp)  			                    #clear the serial buffer
PyPlot.show()


#START THE LOOP

@time while true

#command to send  a chirp and save two ADC arrays
write(sp,'s')
write(sp,v_tx)
while bytesavailable(sp)<1
	continue
	sleep(0.005)
end

#Print the Time conversion of the ADC
s = readavailable(sp)

#Get the Values with command 'p'
write(sp,'p')
while bytesavailable(sp)<1
	continue
end

#GET THE CONVERTED DATA FROM THE BUFFER
v = convertBuffer(sp)

#GET THE DATA FROM ADC2 ARRAY
write(sp,'q')
while bytesavailable(sp)<1
	continue
end
v2= convertBuffer(sp)

#make another transmit signal at the same frequency as recieved
dt=1/500000
t_max=(20/343) +10E-3
t_match=collect(0:dt:t_max);
v_tx_match =chirpMatch()
r=(343 .*t_match)/2


#RECIEVED  signal1  processing
v= (v/65535).-0.62 		     #signal has to be converted to same scale as transmitted chirp
len2=length(r)-length(v)	 #length of recieved minus the recieved to make arrays same length
b=zeros(len2)

append!(v,b)			         #add zeros to the recieved data

len3=length(v)-length(v_tx_match)
c=zeros(len3)

append!(v_tx_match,c)		#add zeros to the created chirp that is same frequency as recieved

#MATCHED FILTER  signal Processing

V_TX=fft(v_tx_match);
V_RX=fft(v);
H = conj(V_TX);

# APPLY MATCHED  Filter to the simulated returns in Frequency Domain
V_MF = H.*V_RX;
v_mf = ifft(V_MF);
v_mf = real(v_mf);

#RECIEVED SIGNAL2 PROCESSING
v2= (v2/65535).-0.62 		     #signal has to be converted to same scale as transmitted chirp
len2=length(r)-length(v2)	 #length of recieved minus the recieved to make arrays same length
b=zeros(len2)


append!(v2,b)			         #add zeros to the recieved data
v_tx_match =chirpMatch()
len3=length(v2)-length(v_tx_match)
c=zeros(len3)

append!(v_tx_match,c)		#add zeros to the created chirp that is same frequency as recieved

#MATCHED FILTER  signal Processing

V_TX=fft(v_tx_match);
V_RX_2=fft(v2);
H = conj(V_TX);

# APPLY MATCHED  Filter to the simulated returns in Frequency Domain
V_MF_2 = H.*V_RX_2;
v_mf_2 = ifft(V_MF_2);
v_mf_2 = real(v_mf_2);

#Plot the time domain outputs of matched filter

#PyPlot.clf()
#subplot(2,1,1)
#PyPlot.plot(r,v_mf)
#title("Matched filter output")
#PyPlot.draw()
#xlim([0,10]);

#Create analytical signal of the 2 ADC's

V_ANAL= 2*V_MF; # make a copy and double the values
N = length(V_MF);
if mod(N,2)==0 # case N even
	neg_freq_range = Int(N/2):N; # Define range of “neg-freq” components
else # case N odd
	neg_freq_range = Int((N+1)/2):N;
end

V_ANAL[neg_freq_range] .= 0; # Zero out neg components in 2nd half of
v_anal = ifft(V_ANAL);

#2nd RECIEVER

V_ANAL_2= 2*V_MF_2; # make a copy and double the values
N = length(V_MF_2);
if mod(N,2)==0 # case N even
	neg_freq_range = Int(N/2):N; # Define range of “neg-freq” components
else # case N odd
	neg_freq_range = Int((N+1)/2):N;
end

V_ANAL_2[neg_freq_range] .= 0; # Zero out neg components in 2nd half of
v_anal2 = ifft(V_ANAL_2);


#Baseband calculations
j=im;
f0=40000;
v_bb_1=v_anal.*exp.(-j*2*pi*f0*t_match);
v_bb_2=v_anal2.*exp.(-j*2*pi*f0*t_match);

#Wrapped phase difference
delta_psi = angle.( v_bb_1 .* conj(v_bb_2))

PyPlot.clf()
subplot(2,2,1)
PyPlot.plot(r,abs.(v_anal) .* (0:(length(t_match)-1)).^2 )
title("Reciever 1")
ylim([0,0.5e9]);
xlim([0,10]);
PyPlot.draw()


subplot(2,2,2)
PyPlot.plot(r,abs.(v_anal2) .* (0:(length(t_match)-1)).^2 )
title("Reciever 2")
#PyPlot.plot(r,abs.(v_anal))  without range compensation -
xlim([0,10]);
ylim([0,0.5e9]);
xlabel("Range in meters");
PyPlot.draw()

subplot(2,2,3)
PyPlot.plot(r,angle.(v_bb_1))
title("Reciever 1")
xlim([0,10]);
PyPlot.draw()

subplot(2,2,4)
PyPlot.plot(r,angle.(v_bb_2))
title("Reciever 2")
xlim([0,10]);
PyPlot.draw()
println("reading and transmitting...")
#PyPlot.sleep(0.05)
end
