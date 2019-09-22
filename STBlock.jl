using SerialPorts
using PyPlot

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

#clear the serial buffer
s=readavailable(sp)  #clear the serial buffer

write(sp,'c')	     #start conversion 
while bytesavailable(sp)<1
	continue
	sleep(0.05)
end

s = readavailable(sp)
print(s)	    		#print the time for conversion

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
	println(len)
	if len<1
		sleep(0.005)
		if len<1
			break
		end
	end
	b=x
	a=string(a,b)
	i+=1
	println("a",length(a))
end

adc=split(a,"\r\n")

len=length(adc)
v=Vector{Int64}(undef,len)

for i=1:len
           global v
           global adc
           v[i]=parse(Int64,adc[i])
       end
plot(v)

