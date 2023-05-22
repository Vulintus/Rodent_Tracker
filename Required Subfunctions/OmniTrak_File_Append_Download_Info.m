function OmniTrak_File_Append_Download_Info(file,port)

[path, filename, ext] = fileparts(file);                                    %Grab the parts of the file.
if ~any(strcmpi(ext,{'.OTK','.OmniTrak'}))                                  %If the input file wasn't an *.OTK or *.OmniTrak file...
    warning(['WARNING FROM OMNITRAK_FILE_APPEND_DOWNLOAD_TIME: input '...
        'file ''' file ''' is not an *.OTK/*.OmniTrak file. Download '...
        'time will not be appended.']);                                     %Show a warning.
    return                                                                  %Skip execution of the rest of the function.
end

old_fid = fopen(file,'r');                                                  %Open the input file.
fseek(old_fid,0,'bof');                                                     %Rewind to the beginning of the file.

block = fread(old_fid,1,'uint16');                                          %Read in the first data block code.
if isempty(block) || block ~= hex2dec('ABCD')                               %If the first block isn't the expected OmniTrak file identifier...
    fclose(fid);                                                            %Close the input file.
    error(['ERROR IN ' upper(mfilename) ': The specified file doesn''t '...
        'start with the *.OmniTrak 0xABCD identifier code!\n\t%s'],file);   %Throw an error.
end

block = fread(old_fid,1,'uint16');                                          %Read in the second data block code.
if isempty(block) || block ~= 1                                             %If the second data block code isn't the format version...
    fclose(old_fid);                                                        %Close the input file.
    error(['ERROR IN ' upper(mfilename) ': The specified file doesn''t '...
        'specify an *.OmniTrak file version!\n\t%s'],file);                 %Throw an error.
end
file_version = fread(old_fid,1,'uint16');                                   %Read in the file version.

block_codes = Load_OmniTrak_File_Block_Codes(file_version);                 %Load the OmniTrak block code structure.

[~, local] = system('hostname');                                            %Grab the local computer name.
local(local < 33) = [];                                                     %Kick out any spaces and carriage returns from the computer name.

temp_filename = fullfile(path, [filename '.temp']);                         %Create a temporary file.
new_fid = fopen(temp_filename,'w');                                         %Open a new file for writing.
fwrite(new_fid, block_codes.OMNITRAK_FILE_VERIFY, 'uint16');                %Write the OmniTrak verification code.
fwrite(new_fid, block_codes.FILE_VERSION, 'uint16');                        %Write the file format version block code.
fwrite(new_fid, file_version, 'uint16');                                    %Write the file version.

fwrite(new_fid,block_codes.DOWNLOAD_TIME,'uint16');                         %Write the block code for the download time to the new file.
fwrite(new_fid,now,'float64');                                              %Write the timestamp to the file to the new file.

fwrite(new_fid,block_codes.DOWNLOAD_SYSTEM,'uint16');                       %Write the block code for the download system.
fwrite(new_fid,length(local),'uint8');                                      %Write the number of characters in the computer name.
fwrite(new_fid,local,'uchar');                                              %Write the characters of the computer name.
fwrite(new_fid,length(port),'uint8');                                       %Write the number of characters in the port name.
fwrite(new_fid,port,'uchar');                                               %Write the characters of the port name.

while ~feof(old_fid)                                                        %Loop until the end of the original file.
    fwrite(new_fid, fread(old_fid, 1, 'uint8'), 'uint8');                   %Copy each subsequent byte from the original file to the temporary file.
end

fclose(new_fid);                                                            %Close the temporary file.
fclose(old_fid);                                                            %Close the original file.

copyfile(temp_filename, file, 'f');                                         %Replace the original file with the new file.

delete(temp_filename);                                                      %Delete the *.temp file.