
% Specify the conductance values (in nS) and diffusion constant values (in
% nS^2/ms).
g_shunt = 3.0;
g_HCN = 1.27;
g_Na = 35.223;
m_OU_exc = 2.10;
D_OU_exc = 2.02; 
m_OU_inh = 4.071;
D_OU_inh = 2.01;
g_EPSC = 1.2234; 

% Put them together in one variable to send out through the USB port. Convert the
% numbers to single-point (32-bit) precision. (Matlab's default precision 
% is double = 64 bit.) Convert the single point numbers to byte arrays.
out = [g_shunt; g_HCN; g_Na; m_OU_exc; D_OU_exc; m_OU_inh; D_OU_inh; g_EPSC];
out = single(out);
out = typecast(out, 'uint8');

% Open the USB port. In this example, we assume that the Teensy
% microcontroller is connected to COM3.
port = serial('COM3','BaudRate',115200);
fopen(port);

% Send the numbers to the Teensy microcontroller.
fwrite(port, out);

% Close and delete the serial port when done.
fclose(port);
delete(port);

