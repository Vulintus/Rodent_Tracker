function result = Vulintus_Lock_File_Delete(file_or_dir)

%
%Vulintus_Lock_File_Delete.m - Vulintus, Inc.
%
%   This function deletes any *.VLOCK placeholder files associated with a
%   specified file or deletes all *.VLOCK placeholder files in a specified
%   directory.
%   
%   UPDATE LOG:
%   06/21/2019 - Drew Sloan - Function first created.
%

result = 0;                                                                 %Set a default return value of zero.

if exist(file_or_dir,'file') == 2                                           %If the specified input is a file...
    [path, file, ~] = fileparts(file_or_dir);                               %Strip off any extension from the specified filename.
    lock_filename = fullfile(path,[file,'.VLOCK']);                         %Create a file with the same name, but with the *.VLOCK extension.
    if exist(lock_filename,'file')                                          %If the placeholder file exists...
        delete(lock_filename);                                              %Delete it.
        result = 1;                                                         %Return a result of 1.    
    end
elseif exist(file_or_dir,'dir') == 7                                        %If the specified input is a directory.
    files = dir(file_or_dir);                                               %Find all files in the directory.
    for f = 1:length(files)                                                 %Step through the files.
        [~,~,ext] = fileparts(files(f).name);                               %Grab the extension from each file.
        if strcmpi(ext,'.VLOCK')                                            %If the file is a *.VLOCK file...
            delete(fullfile(file_or_dir,files(f).name));                    %Delete the file.
        end
    end
    result = 1;                                                             %Return a result of 1.    
end