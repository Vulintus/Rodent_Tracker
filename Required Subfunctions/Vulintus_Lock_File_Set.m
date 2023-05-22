function result = Vulintus_Lock_File_Set(file_or_dir)

%
%Vulintus_Lock_File_Set.m - Vulintus, Inc.
%
%   This function creates a *.VLOCK placeholder file in the specified
%   directory to place a "lock" on the specified file or to place a lock on
%   the entire directory if a directory is specified. The file contains a
%   single 'float64' value containing the serial date number for when the
%   placeholder was created.
%   
%   UPDATE LOG:
%   06/20/2019 - Drew Sloan - Function first created.
%   06/21/2019 - Drew Sloan - Updated to include a specific file to "lock",
%       as opposed to putting a placeholder on the entire directory.
%

result = 0;                                                                 %Set a default return value of zero.

if exist(file_or_dir,'dir') == 7                                            %If the specified input is a directory.
    lock_filename = fullfile(file_or_dir,['DIRECTORY.VLOCK']);              %Create a *.VLOCK file specifying the directory.
else                                                                        %Otherwise, if the specified input is a file...
    [path, file, ~] = fileparts(file_or_dir);                               %Strip off any extension from the specified filename.
    if ~exist(path,'dir') == 7                                              %If the path specified in the file doesn't exist...
        return                                                              %Skip execution of the rest of the function.
    end
    lock_filename = fullfile(path,[file,'.VLOCK']);                         %Create a file with the same name, but with the *.VLOCK extension.
end

fid = fopen(lock_filename,'w');                                             %Open the placeholder file for writing.
fwrite(fid,now,'float64');                                                  %Write the current serial date number to the placeholder file.
fclose(fid);                                                                %Close the placeholder file.
result = 1;                                                                 %Return a result of 1.