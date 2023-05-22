function HabiTrak_Data_Dump_V1_1

clc;                                                                        %Clear the command window.
fprintf(1,'HabiTrak_Data_Dump_V1_0\n\n');                                   %Print the function name to the command line.
fprintf(1,'Checking serial ports...\n');                                    %Print a message to the serial line.

delete(instrfind);                                                          %Delete any open serial connections.

% temp = userpath;                                                            %Grab the userpath.
% a = find(temp == '\');                                                      %Find the folder markers in the search path name.
% temp = temp(a(2)+1:a(3)-1);                                                 %Pull the user name out of the search path name.
% datapath = ['C:\Users\' temp '\Google Drive\HabiTrak SBIR\'];               %Set the default path for data.
% if ~exist(datapath,'dir') == 7                                              %If the default path doesn't exist...
%     if isdeployed                                                           %If the function is running as compiled code...
%         datapath = pwd;                                                     %Use the current folder as the data path.
%     else                                                                    %Otherwise, if the function is running in MATLAB...
%         [datapath,~,~] = fileparts(which(mfilename));                       %Use the folder containing this function as the data path.        
%     end
% end
% i = strfind(datapath,'MATLAB Scripts');                                     %Check to see if the path contains a folder called "MATLAB Scripts".
% if ~isempty(i)                                                              %If the path does contain that folder...
%     datapath(i:end) = [];                                                   %Strip it out.
% end
% datapath = 'H:\My Drive\HabiTrak SBIR\HabiTrak - Kroener Lab Testing';      
% datapath = fullfile(datapath, 'Data - Unorganized\');                       %Add the unorganized data directory to the path.
% if ~exist(datapath,'dir')                                                   %If the unorganized data path folder doesn't exist yet...
%     mkdir(datapath);                                                        %Create it.
% end
datapath = uigetdir;

port = instrhwinfo('serial');                                               %Grab information about the available serial ports.
if isempty(port)                                                            %If no serial ports were found...
    errordlg(['ERROR: There are no available serial ports on this '...
        'computer.'],'No Serial Ports!');                                   %Show an error in a dialog box.
    return                                                                  %Skip execution of the rest of the function.
end
busyports = setdiff(port.SerialPorts,port.AvailableSerialPorts);            %Find all ports that are currently busy.
port = port.SerialPorts;                                                    %Save the list of all serial ports regardless of whether they're busy.

key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\';              %Set the registry query field.
[~, txt] = dos(['REG QUERY ' key ' /s /f "FriendlyName" /t "REG_SZ"']);     %Query the registry for all USB devices.
checker = zeros(numel(port),1);                                             %Create a check matrix to identify Arduino Unos.
for i = 1:numel(port)                                                       %Step through each port name.
    j = strfind(txt,['(' port{i} ')']);                                     %Find the port in the USB device list.
    if ~isempty(j)                                                          %If a matching port was found...
        if strcmpi(txt(j-12:j-2),'Arduino Uno') || ...
                strcmpi(txt(j-18:j-2),'USB Serial Device') || ...
                strcmpi(txt(j-13:j-2),'Arduino Zero')                       %If the device is an Arduino Uno or a SAMD21.    
            checker(i) = 1;                                                 %Mark the device for inclusion.
        end
    end
end
port(checker == 0) = [];                                                    %Kick out all non-Arduino devices from the ports list.

while ~isempty(port) && length(port) > 1                                    %If there's more than one serial port available, loop until a MotoTrak port is chosen.
    uih = 1.5;                                                              %Set the height for all buttons.
    w = 10;                                                                 %Set the width of the port selection figure.
    h = (numel(port))*(uih + 0.1) + 0.1;                                    %Set the height of the port selection figure.
    set(0,'units','centimeters');                                           %Set the screensize units to centimeters.
    pos = get(0,'ScreenSize');                                              %Grab the screensize.
    pos = [pos(3)/2-w/2, pos(4)/2-h/2, w, h];                               %Scale a figure position relative to the screensize.
    fig1 = figure('units','centimeters',...
        'Position',pos,...
        'resize','off',...
        'MenuBar','none',...
        'name','Select A Serial Port',...
        'numbertitle','off');                                               %Set the properties of the figure. 
    for i = 1:numel(port)                                                   %Step through each serial port.        
        uicontrol(fig1,'style','pushbutton',...
            'string',port{i},...
            'units','centimeters',...
            'position',[0.1 h-i*(uih+0.1) 9.8 uih],...
            'fontweight','bold',...
            'fontsize',14,...
            'callback',['guidata(gcbf,' num2str(i) '); uiresume(gcbf);']);  %Make a button for the port showing that it is busy.
    end
    uiwait(fig1);                                                           %Wait for the user to push a button on the pop-up figure.
    if ishandle(fig1)                                                       %If the user didn't close the figure without choosing a port...
        i = guidata(fig1);                                                  %Grab the index of chosen port name from the figure.
        close(fig1);                                                        %Close the figure.
        port = port(i);                                                     %Save only the port that the user selected. 
    else                                                                    %Otherwise, if the user closed the figure without choosing a port...
       return                                                               %Skip execution of the rest of the function.
    end
end

if ~isempty(port)                                                           %If a port was selected...
    port = port{1};                                                         %Convert the port cell array to a string.
    if strcmpi(busyports,port)                                              %If the selected serial port is busy...
        temp = instrfind('port',port);                                      %Grab the serial handle for the specified port.
        fclose(temp);                                                       %Close the busy serial connection.
        delete(temp);                                                       %Delete the existing serial connection.
    end
end

serialcon = serial(port,'baudrate',2000000);                                %Set up the serial connection on the specified port.
try                                                                         %Try to open the serial port for communication.
    fopen(serialcon);                                                       %Open the serial port.
catch err                                                                   %If no connection could be made to the serial port...
    delete(serialcon);                                                      %Delete the serial object.
    error(['ERROR IN HABITRAK_DATA_DUMP_V1_0: Could not open a serial '...
        'connection on port ''' port '''.']);                               %Show an error.
end
fprintf(1,'Connected: %s\n', port);                                         %Print the COM port to the serial line.

ardy = struct('port',port,'serialcon',serialcon,'version',1);               %Create the output structure for the serial communication.
ardy = OmniTrak_SerialCom_V1p0_SD_Functions(ardy);                          %Load the SD management functions.

pause(5);                                                                   %Pause for 5 seconds to let the device finish displaying status messages.

ardy.clear();                                                               %Clear the serial line.
str = ardy.com_port(port);                                                  %Send the port ID to the device.
fprintf(1,'Uploaded COM port ID: %s\n',str);                                %Print the reply to the serial line.

ardy.clear();                                                               %Clear the serial line.
mac = ardy.get_mac_addr();                                                  %Fetch the MAC address of the device.
if length(mac) > 6                                                          %If the MAC address is longer than six numbers...
    mac(1:end-6) = [];                                                      %Kick out everything but the last numbers.
end
mac_string = dec2hex(flipud(mac));                                          %Convert the MAC address to a hex character array string.
mac_string = reshape(mac_string',[1,12]);                                   %Reshape the MAC address character array to 1x12.

[~, local] = system('hostname');                                            %Grab the local computer name.
local(local < 33) = [];                                                     %Kick out any spaces and carriage returns from the computer name.
if length(mac) == 6                                                         %If a mac address was received...
    temp = [datestr(now,30) '_' mac_string '_' local '_' port];             %Create a folder for this data.
else                                                                        %Otherwise...
    temp = [datestr(now,30) '_' local '_' port];                            %Create a folder for this data.
end
datapath = [datapath temp];                                                 %Add the new folder name to the data path.
if ~exist(datapath,'dir')                                                   %If the directory doesn't yet exist...
    mkdir(datapath);                                                        %Create it.
end
fprintf(1,'\nCopying data to: %s\n\n',datapath);                            %Print the target directory to the command line.

fprintf(1,'Setting directory to: /HABITRAK/\n');                            %Print a message to the command line.
str = ardy.sd_set_cur_dir('HABITRAK');                                      %Set the current directory.
if ~strcmpi(str,'habitrak')                                                 %If the current directory couldn't be set...
    error(['ERROR IN HABITRAK_DATA_DUMP_V1_0: Could not set the current'...
        ' directory to ''HABITRAK''.']);                                    %Show an error.
end

try                                                                         %Try to complete all of the file transfers.
    ardy.clear();                                                           %Clear the serial line.
    ardy.sd_rewind_dir();                                                   %Rewind the directory.
    filename = ardy.sd_file_name();                                         %Fetch the first filename.
    while ~strcmpi(filename,char(0))                                        %Loop until the filename equals the null character.
        str = ardy.sd_file_isdir();                                         %Check to see if the file is a directory.
        if str2double(str) == 1                                             %If the file is a directory...
            fprintf(1,'DIRECTORY: %s\n', filename);                         %Print the filename with a directory label.
        elseif str2double(str) == 2                                         %If the file is actual a file...
            file_size = str2double(ardy.sd_file_size())/1000;               %Grab the file size. 
            fprintf(1,'\tDOWNLOADING: %s (%1.1fKB)',filename, file_size);   %Print the filename to the command line.
            start_time = now;                                               %Grab the current time when the file transfer starts.
            ardy.clear();                                                   %Clear the serial line.
            new_filename = fullfile(datapath, filename);                    %Set the copy filename.
            Vulintus_Lock_File_Set(new_filename);                           %Set a *.VLOCK placeholder for the file.
            fid = fopen(new_filename,'w');                                  %Create a copy of the binary file.
            outcome = ardy.sd_dump_file(fid);                               %Call the function to dump the file.
            fclose(fid);                                                    %Close the binary copy file.
            Vulintus_Lock_File_Delete(new_filename);                        %Delete the *.VLOCK placeholder for the file.
            if outcome == 1                                                 %If the file dump was successful...
                stop_time = now;                                            %Grab the current time when the file transfer finishes.
                stop_time = (stop_time - start_time)*86400;                 %Convert the file transfer time to seconds.
                fprintf(1,' - %1.1f KB/s\n',file_size/stop_time);           %Print the transfer rate.
            else                                                            %Otherwise...
                fprintf(1,' - DOWNLOAD FAILURE!\n');                        %Print an error message.
            end              
        end
        ardy.sd_next_file();                                                %Advance to the next file.
        [~,~,ext] = fileparts(filename);                                    %Get the extension from the file.
        if strcmpi(ext,'.OTK')                                              %If the file was an *.OTK file...
            str = ['/HABITRAK/' filename];                                  %Create the filename to delete from the SD card.
            fprintf(1,'\t\tDELETING FROM SD: %s\n',str);                    %Print a message to show the file is being deleted.
            ardy.sd_delete_file(str);                                       %Delete the file from the SD card.
            OmniTrak_File_Append_Download_Info(new_filename,port);          %Add the download time and system information to the downloaded file.
        end
        filename = ardy.sd_file_name();                                     %Fetch the next filename.
    end
catch err                                                                   %If an error occured...
    warning(['FILE TRANSFER ERROR IN HABITRAK_DATA_DUMP_V1_0: Error '...
        'occurred for file: \n\t%s\n\tERROR MESSAGE: %s'],filename,...
        err.message);                                                       %Show a warning.
end
fclose(serialcon);                                                          %Close the serial connection.
delete(serialcon);                                                          %Delete the serial connection object.