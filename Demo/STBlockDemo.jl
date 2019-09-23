using SerialPorts
using PyPlot
using FFTW;
sp = SerialPort(list_serialports()[1], 9600)  # port of the Teensy if connected

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

println("Length of chirp pulse:",length(v_tx));


#Reading from the serial ADC clear the serial buffer
s=readavailable(sp)  #clear the serial buffer

write(sp,'s')	     #to send and recieve something back
write(sp,v_tx)
while bytesavailable(sp)<1
	continue
	sleep(0.05)
end

s = readavailable(sp)   		#print the time for conversion
println("Reading ADC...")
#Get the Values 
write(sp,'p')
while bytesavailable(sp)<1
	continue        
end 
a=""
i=0
while true
	global i
	global a
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
           global v
           global adc
	   #v[i] = string(adc, base = 16)
           v[i]=parse(Int64,adc[i])
	 end
#make another transmit signal at the same frequnecy as recieved
T=6E-3                                                       # Chirp Pulse length
K=B/T                                                        # Chirp rate
fs=500000
dt=1/fs                                                      # The  sampling rate was found to be 2Msamples/second
t_max=(20/343) +10E-3                                                 #max time to reach 10 meters and back is 58 miliseconds
t_d=T/2;
t_max_pulse=T;

rect(t)=(abs.(t) .<=0.5)*1.0;

t_match=collect(0:dt:t_max);
v_tx_match = cos.(2*pi*(f*(t_match.-t_d).+0.5*K*(t_match.-t_d).^2)).*rect((t_match .-t_d)/T);

r=(343 .*t_match)/2

println("length of r:",length(r))
#recieved signal 
v= (v/65535).-0.62
len2=length(r)-length(v)
b=zeros(len2)

append!(v,b)

len3=length(v)-length(v_tx_match)
c=zeros(len3)

append!(v_tx_match,c)

println("The recieved and Transmitted ECHOES")
#Plot the two signals on one axis
#figure();
#plot(v);
#figure();
println("Length of recieved signal:",length(v));
#plot(v_tx_match);
println("Length of transmitted signal:",length(v_tx_match));
println("The target location")

#matched filter signal Processing
V_TX=fft(v_tx_match);
V_RX=fft(v);
H = conj(V_TX);
# Apply Matched Filter to the simulated returns in Frequency Domain
V_MF = H.*V_RX;
v_mf = ifft(V_MF);
v_mf = real(v_mf);

#Plot the time domain outputs of matched filter
#figure();
plot(r,v_mf)
xlabel("Range in meters");
xlim([0,10]);
#close(sp)


