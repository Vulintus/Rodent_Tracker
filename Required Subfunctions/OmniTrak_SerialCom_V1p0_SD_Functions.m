function ardy = OmniTrak_SerialCom_V1p0_SD_Functions(ardy)

%OmniTrak_SerialCom_V1p0_SD_Functions.m - Vulintus, Inc., 2019
%
%   OmniTrak_SerialCom_V1p0_SD_Functions defines and adds the OmniTrak SD
%   card interface functions to the "ardy" structure, so that MATLAB can
%   download and manage files on SD cards in OmniTrak devices.
%
%   UPDATE LOG:
%   06/19/2019 - Drew Sloan - Function first created, adapted from
%       MotoTrak_Controller_V2pX_Serial_Functions.m.
%


serialcon = ardy.serialcon;                                                 %Grab the handle for the serial connection.
serialcon.Timeout = 2;                                                      %Set the timeout for serial read/write operations, in seconds.
s = Load_OmniTrak_SerialCom_Block_Codes(ardy.version);                      %Load the serial block codes for the specified sketch version.

%Serial line management functions.
ardy.clear = @()v1p0_clear_serial(serialcon);                               %Set the function for clearing the serial line.
ardy.com_port = @(str)v1p0_get_string(serialcon,s.COM_PORT,str);            %Set the function for sending the COM port ID to the device.

%OmniTrak device information functions.
ardy.get_mac_addr = @()v1p0_get_bytes(serialcon,s.GET_MAC_ADDR);            %Set the function for returning the device's MAC address.

%SD card management functions.
ardy.sd_set_cur_dir = @(str)v1p0_get_string(serialcon,s.SET_CUR_DIR,str);   %Set the function for setting the current directory.
ardy.sd_get_cur_dir = @()v1p0_get_string(serialcon,s.GET_CUR_DIR,[]);       %Set the function for returning the current directory.
ardy.sd_rewind_dir = @()v1p0_send_char(serialcon,s.REWIND_DIR);             %Set the function for rewinding the directory.
ardy.sd_next_file = @()v1p0_send_char(serialcon,s.NEXT_FILE);               %Set the function for rewinding the directory.
ardy.sd_file_name = @()v1p0_get_string(serialcon,s.CUR_FILE_NAME,[]);       %Set the function for returning the current file name.
ardy.sd_file_size = @()v1p0_get_string(serialcon,s.CUR_FILE_SIZE,[]);       %Set the function for returning the current file size.
ardy.sd_file_isdir = @()v1p0_get_string(serialcon,s.CUR_FILE_ISDIR,[]);     %Set the function for returning the current file size.
ardy.sd_dump_file = @(fid)v1p0_dump_file(serialcon,s.DUMP_FILE,fid);        %Set the function for quickly dumping all of the contents of the current file.
ardy.sd_delete_file = @(str)v1p0_get_string(serialcon,s.DELETE_FILE,str);   %Set the function for deleting a file.
ardy.sd_delete_dir = @(str)v1p0_get_string(serialcon,s.DELETE_DIR,str);     %Set the function for deleting a directory.


%% This function clears any values from the serial line.
function v1p0_clear_serial(serialcon)
timeout = now + 25/8640000;                                                 %Set the reply timeout duration (0.25 seconds).
while now < timeout                                                         %Loop for the timeout duration or until there's bytes available on the serial line.
    while serialcon.BytesAvailable > 0                                      %Loop as long as there's bytes available on the serial line...
        fread(serialcon,1,'uint8');                                         %Read each byte and discard it.
    end
    pause(0.001);                                                           %Pause for 1 millisecond to keep from overwhelming the processor.
end


%% This function sends a byte command without an expected reply.
function v1p0_send_char(serialcon,cmd)     
fwrite(serialcon,cmd,'uint8');                                              %Send the command to the controller.


%% This function sends a byte command and receives a bytes reply.
function output = v1p0_get_bytes(serialcon,cmd)
fwrite(serialcon,cmd,'uint8');                                              %Send the command to the controller.
timeout = now + 1/86400;                                                    %Set the reply timeout duration (1 second).
while serialcon.BytesAvailable < 6 && now < timeout                         %Loop until there's a reply or the operating times out.
    pause(0.001);                                                           %Pause for 1 millisecond.
end
output = fread(serialcon,serialcon.BytesAvailable,'uint8');                 %Check the serial line for a reply.


%% This function sends a byte command and a character string (optional) and receives a character string reply.
function output = v1p0_get_string(serialcon,cmd,str)
fwrite(serialcon,cmd,'uint8');                                              %Send the command to the controller.
if ~isempty(str)                                                            %If an input string was specified...
    fwrite(serialcon,str,'uchar');                                          %Write the string to the serial line.
    fwrite(serialcon,0,'uint8');                                            %Write a null terminator to the serial line.
end
timeout = now + 1/86400;                                                    %Set the reply timeout duration (1 second).
while serialcon.BytesAvailable < 1 && now < timeout                         %Loop until there's a reply or the operating times out.
    pause(0.001);                                                           %Pause for 1 millisecond.
end
output = fscanf(serialcon,'%s');                                            %Check the serial line for a reply.


%% This function sends the byte command to start a data dump and dumps all incoming bytes into the specified file.
function output = v1p0_dump_file(serialcon,cmd,fid)
fwrite(serialcon,cmd,'uint8');                                              %Send the command to the controller.
timeout = now + 1/86400;                                                    %Set the reply timeout duration (100 milliseconds).
while serialcon.BytesAvailable == 0 && now < timeout                        %Loop until there's a reply or the operating times out.
    pause(0.001);                                                           %Pause for 1 millisecond.
end
if serialcon.BytesAvailable > 0                                             %If the device replied...
   inbytes = fread(serialcon,1,'uint8');                                    %Read in one byte.
   if inbytes == 0                                                          %If the first byte equals zero...
       output = 0;                                                          %Set the output to zero.
       return                                                               %Skip execution of the rest of the function.
   end
end
serial_timeout = now + 5/864000;                                            %Set the reply timeout duration (500 milliseconds).
while now < serial_timeout                                                  %Loop until a serial timeout...
    N = serialcon.BytesAvailable;                                           %Grab the number of bytes available on the serial line.
    if N > 0                                                                %If there are bytes available...        
        inbytes = fread(serialcon,N,'uint8');                               %Read the bytes off the serial line.
        fwrite(fid,inbytes,'uint8');                                        %Write the bytes to the file.
        serial_timeout = now + 5/864000;                                    %Update the reply timeout duration (500 milliseconds).
    end
    pause(0.001);                                                           %Pause for 1 millisecond.
end
output = 1;                                                                 %Set the output to 1.