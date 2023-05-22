function PTSD_Analysis

rootpath = 'C:\Users\Andrew\Google Drive\PTSD Videos\';                     %Set the root path.
popdata = struct([]);                                                       %Create a population data structure.
p = 0;                                                                      %Create a subject counter.
len = 10;

files = dir([rootpath '*_ACTIVITY.txt']);                                   %Grab all activity files.
for i = 1:length(files)                                                     %Step through each wav file.
    soundfile = [rootpath files(i).name(1:end-13) '_SOUND_ONSETS.txt'];     %Create the expected sound onset name.
    if ~exist(soundfile,'file')                                             %If the sound onsets don't exist...
        continue                                                            %Skip to the next file.
    end    
    onsets = load(soundfile);                                               %Load the onsets.
    keepers = ones(size(onsets));                                           %Create a matrix to check the onsets.
    for j = 1:length(onsets)                                                %Step through the onsets.
        if sum(onsets(j:end) - onsets(j) <= 60) < 4                         %If there's not a total of 4 onsets in the next minute...
            keepers(j) = 0;                                                 %Kick out that onset.
        end
    end
    onsets(keepers == 0) = [];                                              %Kick out the redundant onsets.    
    data = read_tracking_file([rootpath files(i).name]);                    %Read in the data from the tracking file.
    if isempty(data)                                                        %If there's no data to read...
        continue                                                            %Skip to the next file.
    end
    onsets(onsets > max(data(:,1))) = [];                                   %Kick out any onsets greater than the farthest frame.
    if isempty(onsets)                                                      %If there's no more onsets left...
        continue                                                            %Skip to the next file.
    end
    p = p + 1;                                                              %Increment the subject counter.
    fs = 1/median(diff(data(:,1)));                                         %Calculate the framerate.
    t = data(2:end,1);                                                      %Grab the timestamps.
    v = euclid_dist(data(1:end-1,2:3),data(2:end,2:3));                     %Find the Euclidean distance between frames.
    v = v./diff(data(:,1));                                                 %Find the velocity, in pixels per second.
    temp = sort(v);                                                         %Sort the samples.
%     v = (v > temp(round(0.5*length(temp))));                                %Convert the velocities to logical, greater than 5th percentile.
    N = ceil(fs*len);                                                       %Calculate the number of samples to grab before and after the sound.
    
    trace = nan(length(onsets),2*N+1);                                      %Pre-allocate a matrix to hold the trace.
    for j = 1:length(onsets)                                                %Step through each onset.
        s = find(t >= onsets(j),1,'first');                                 %Find the sample at the start of the sound.
        if s > N                                                            %If the velocity signal is at least this long...
            a = N;                                                          %Grab all of the signal.
        else                                                                %Otherwise...
            a = s - 1;                                                      %Grab as much of the signal as there is.
        end
        trace(j,(N-a+1):N+1) = v((s-a):s);                                  %Grab the velocity before the onset.
        if length(v) >= s + N                                               %If the velocity signal is at least this long.
            a = N;                                                          %Grab all the signal
        else                                                                %Otherwise...
            a = length(v) - s;                                              %Grab only what signal there is.
        end
        trace(j,N+1:(N+1+a)) = v(s:(s+a));                                  %Grab the velocity after the onset.
    end
    popdata(p).freeze = zeros(size(trace,1),1);                             %Create a field to hold the freeze ratio.
    for j = 1:size(trace,1)                                                 %Step through each trace.
        temp = nanmedian(trace(j,N+1:end))/nanmedian(trace(j,1:N+1));       %Calculate the freeze ratio.
        popdata(i).freeze(j) = temp;                                        %Save the freeze ratio.
        temp = trace(j,1:N+1);                                              %Grab the first half of the trace.
        temp = sort(temp);                                                  %Sort the velocities.
        temp = temp(round([0.25,0.75]*length(temp)));                       %Find the 10th and 90th percentiles.
        k = trace(j,:) < temp(1) & (1:(2*N+1) <= N+1);                      %Find the indices for samples below the 10th percentile.
        trace(j,k) = NaN;                                                   %Kick out those samples.
        k = trace(j,:) > temp(2) & (1:(2*N+1) <= N+1);                      %Find the indices for samples below the 10th percentile.
        trace(j,k) = NaN;                                                   %Kick out those samples.
        temp = trace(j,N+1:end);                                            %Grab the second half of the trace.
        temp = sort(temp);                                                  %Sort the velocities.
        temp = temp(round([0.25,0.75]*length(temp)));                       %Find the 10th and 90th percentiles.
        k = trace(j,:) < temp(1) & (1:(2*N+1) >= N+1);                      %Find the indices for samples below the 10th percentile.
        trace(j,k) = NaN;                                                   %Kick out those samples.
        k = trace(j,:) > temp(2) & (1:(2*N+1) >= N+1);                      %Find the indices for samples below the 10th percentile.
        trace(j,k) = NaN;                                                   %Kick out those samples.
        trace(j,:) = trace(j,:)/nanmean(trace(j,1:N));                      %Normalize each trace to the pre-sound.
    end
    trace = boxsmooth(trace,[1,round(fs)]);                                 %Smooth the traces with a 1-second trace.
    trace = nanmean(trace,1);                                               %Find the mean trace.
    temp = nan(1,20);                                                       %Pre-allocate a matrix to hold a smoothed trace.
    for j = 1:N/10:(2*N+1-N/10);                                            %Step through the timepoints.
        temp(ceil(j/(N/10))) = nanmean(trace(round(j):round(j+N/10)));      %Save the mean signal over each tenth of a second.
    end
    popdata(p).trace = temp;                                                %Save the trace.
    popdata(p).file = files(i).name(1:end-13);                              %Save the filename.             
end

figure;                                                                     %Create a figure.
axes('position',[0.1,0.2,0.85,0.7]);                                        %Create axes.
temp = zeros(length(popdata),1);                                            %Create a matrix to hold mean freeze ratios.
for i = 1:length(popdata)                                                   %Step through the population data.
    temp(i) = nanmean(popdata(i).freeze);                                   %Find the mean freeze ratio.
end
str = {popdata.file};                                                       %Grab all of the filenames.
clc;
for i = 1:length(temp)                                                      %Step through each session
    fprintf(1,'%s\t',str{i});                                               %Print the session name.
    fprintf(1,'%1.3f\n',temp(i));                                           %Print the freeze value.
end
[temp, i] = sort(temp);                                                     %Sort the freeze ratios.
str = str(i);                                                               %Sort the filenames by the same order.
area(temp,'basevalue',1);                                                   %Plot the freeze ratios.
title(['Freeze Ratio (' num2str(len) ' s post/ ' num2str(len) ' pre)']);    %Put a title on the plot.
ylabel('POST/PRE RATIO');                                                   %Label the y-axis.
set(gca,'xtick',1:length(temp),'xticklabel',str);                           %Label the x-axis.
xlim([0,length(temp) + 1]);                                                 %Set the x-axis limits.
ylim([temp(1),temp(end)] + [-0.05,0.05]*(temp(end)-temp(1)));               %Set the y-axis limits.
xticklabel_rotate(90);                                                      %Rotate the x-tick labels.
i = find(temp >= 1,1,'first');                                              %Find the first session with a ratio over 1.
line((i-0.5)*[1,1],ylim,'color','k','linestyle','--');                      %Plot a line to show freeze and unfreeze.

figure;                                                                     %Create a figure.
axes('position',[0.1,0.1,0.85,0.85]);                                       %Create axes.
temp = vertcat(popdata.trace);                                              %Concatenate all of the traces.
plot(temp','linewidth',2);                                                  %Plot the activity traces.
title(['Activity Traces (' num2str(len) ' s)']);                           %Put a title on the plot.
str = {popdata.file};                                                       %Grab all of the filenames.
legend(str,'location','northwest');                                         %Show a legend.
xlim([0,size(temp,2)+1]);                                                   %Set the x-axis coordinates.
set(gca,'xtick',1:1:19,'xticklabel',len/10*(-9:9));                         %Set the xaxis tick labels.
ylabel('NORMALIZED ACTIVITY');                                              %Label the y-axix.
xlabel('TIME (S)');                                                         %Lable the x-axis.


