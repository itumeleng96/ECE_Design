#IJ Malemela 
#This is code for getting serial Data from the Teensy Board

#Using serial Ports to recieve data from Teensy

using SerialPorts
@show list_serialports()

#sp = SerialPort("/dev/ttyACM0", 9600) # Linux exaple
#write(sp, "Hello")	 	       # write a string to the port
#x = readavailable(sp) 		       # read from the port
#println(x)
#close(sp)			       # close the port
