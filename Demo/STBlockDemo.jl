using SerialPorts
using PyPlot

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
	len=length(x)
	if len<1
		sleep(0.005)
		if len<1
			break
		end
	end
	b=x
	a=string(a,b)
	i+=1
end


adc=split(a,"\r\n")

len=length(adc)-1
v=Vector{Int64}(undef,len)

for i=1:len
           global v
           global adc
           v[i]=parse(Int64,adc[i])
       end
println("The recieved and TRansmitted ECHOES")
#Plot the two signals on one axis
#figure();
plot(v);
println("The target location")
#matched filter signal Processing



