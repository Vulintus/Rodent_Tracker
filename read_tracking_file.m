function data = read_tracking_file(file)

fid = fopen(file,'r');                                                      %Open the text file for reading.
text = textscan(fid,'%s');                                                  %Read in the file with the textscan function.
text = text{1};                                                             %Convert the textscan output to a cell matrix.
fclose(fid);                                                                %Close the text file.

if any(strcmpi('LENGTH_(cm)',text))                                         %If the file is of the new 5-column format...
    a = find(strcmp('LENGTH_(cm)',text));                                   %Find the last column label.
    step = 5;                                                               %Read the data in 5-column steps.
else                                                                        %Otherwise, if the file is in the original format...
    a = find(strcmp('Y_POSITION_(cm)',text));                               %Find the last column label.
    step = 3;                                                               %Read the data in 3-columnn steps.
end
n = floor((length(text)-a)/step);                                           %Find the number of datapoints.
data = nan(n,step);                                                         %Pre-allocate a matrix to hold the datapoints.
c = 0;                                                                      %Create a counter variable.
for i = a+1:step:length(text)                                               %Step the each datapoint.
    c = c + 1;                                                              %Increment the counter.
    for j = 0:(step-1)                                                      %Step through each column.
        data(c,j+1) = str2double(text{i+j});                                %Convert each string to a number.
    end
end
