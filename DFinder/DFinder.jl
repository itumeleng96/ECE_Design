@time using SerialPorts
@time using PyPlot
@time using FFTW;
sp = SerialPort(list_serialports()[1], 9600) # port of the Teensy if connected

#create a chirp Pulse to be sent to the Teensy and plot
B=1715					                     #Bandwidth of the chirp signal
f=40000					                     #Center Frequency
T=6E-3 					                     # Chirp Pulse length
K=B/T 					                     # Chirp rate
fs=2000000
dt=1/fs                                                      # The  sampling rate was found to be 2Msamples/second
t_max=20/343                                                 #max time to reach 10 meters and back is 58 miliseconds
t_d=T/2;
t_max_pulse=T;
t = collect(0:dt:t_max_pulse);

rect(t)=(abs.(t) .<=0.5)*1.0;
v_tx = UInt8.(round.((cos.(2*pi*(f*(t.-t_d).+0.5*K*(t.-t_d).^2)).*rect((t .-t_d)/T).+1).*127));

#Reading from the serial ADC clear the serial buffer
s=readavailable(sp)  #clear the serial buffer
PyPlot.show()
while true
write(sp,'s')	     #to send and recieve something back
write(sp,v_tx)
while bytesavailable(sp)<1
	continue
	sleep(0.05)
end

s = readavailable(sp)   		#print the time for conversion
println("Reading and Transmitting...")
#Get the Values 
write(sp,'p')
while bytesavailable(sp)<1
	continue        
end 
a=""
i=0
while true
#	global i
#	global a
	x=readavailable(sp)
	
	if bytesavailable(sp)<1
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
#           global v
#           global adc
           v[i]=parse(Int64,adc[i])
	 end

#make another transmit signal at the same frequnecy as recieved
T=6E-3                                                       # Chirp Pulse length
K=B/T                                                        # Chirp rate
fs=500000
dt=1/fs                                                      # The  sampling rate was found to be 2Msamples/second
t_max=(20/343) +10E-3                                        # max time to reach 10 meters and back is 58 miliseconds
t_d=T/2;
t_max_pulse=T;

rect(t)=(abs.(t) .<=0.5)*1.0;

t_match=collect(0:dt:t_max);
v_tx_match = cos.(2*pi*(f*(t_match.-t_d).+0.5*K*(t_match.-t_d).^2)).*rect((t_match .-t_d)/T);

r=(343 .*t_match)/2


#recieved signal  processing
v= (v/65535).-0.62
len2=length(r)-length(v)
b=zeros(len2)

append!(v,b)

len3=length(v)-length(v_tx_match)
c=zeros(len3)

append!(v_tx_match,c)


#matched filter signal Processing

V_TX=fft(v_tx_match);
V_RX=fft(v);
H = conj(V_TX);
# Apply Matched Filter to the simulated returns in Frequency Domain
V_MF = H.*V_RX;
v_mf = ifft(V_MF);
v_mf = real(v_mf);

#Plot the time domain outputs of matched filter

PyPlot.clf()
subplot(2,1,1)
PyPlot.plot(r,v_mf)
title("Matched filter output")
PyPlot.draw()
xlim([0,10]);

#Do analytical signal 

V_ANAL= 2*V_MF;                      # make a copy and double the values
N = length(V_MF);
if mod(N,2)==0 # case N even
	neg_freq_range = Int(N/2):N; # Define range of “neg-freq” components
else # case N odd
	neg_freq_range = Int((N+1)/2):N;
end

V_ANAL[neg_freq_range] .= 0; # Zero out neg components in 2nd half of
v_anal = ifft(V_ANAL);
subplot(2,1,2)
PyPlot.plot(r,abs.(v_anal) .* (0:(length(t_match)-1)).^2 )
#PyPlot.plot(r,abs.(v_anal))
xlim([0,10]);

xlabel("Range in meters");
PyPlot.draw()
PyPlot.sleep(0.02)
end


