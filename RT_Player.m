function RT_Player

clear global;                                                               %Clear out any pre-existing global variables.

global run                                                                  %Create a global run variable to control playback.
run = 0;                                                                    %Set the initial value of the run variable to zero.

handles = Make_GUI;                                                         %Call the subfunction to make the GUI.
set(handles.playbutton,'callback',@PlayStop);                               %Set the callback for the play button.
set(handles.syncbutton,'callback',@SyncVideo);                              %Set the callback for the synching button.
set(handles.loadbutton,'callback',@LoadVideo);                              %Set the callback for the load video button.
set(handles.slider,'callback',@SliderClick);                                %Set the callback for action on the slider.

guidata(handles.fig,handles);                                               %Pin the handles structure to the GUI.


%% This function executes whenever the user presses the play/stop button.
function PlayStop(hObject,~)
global run                                                                  %Create a global run variable to control playback.
global curframe                                                             %Create a global variable to track the current frame.
if run == 1                                                                 %If the video is currently playing...
    run = 0;                                                                %Set the run variable to zero.
elseif run == 3                                                             %Otherwise, if the run variable equals 3...
    run = 0;                                                                %Set the run variable to zero.
    pause(0.05);                                                            %Pause for 50 milliseconds.
else                                                                        %Otherwise...
    handles = guidata(hObject);                                             %Grab the handles structure from the main figure.
    set(handles.playbutton,'string','STOP','foregroundcolor',[0.5 0 0]);    %Set the play/stop button string to "STOP".
    run = 1;                                                                %Set the run variable to 1.
    if curframe == handles.vid.NumberOfFrames                               %If the current frame is the very last frame...
        curframe = 1;                                                       %Reset the current frame to 1.
    end
    intervals = diff(handles.frame_time);                                   %Find the intervals between frames.
    tic;                                                                    %Start a timer.
    nextframe = intervals(curframe);                                        %Set the timing of the next frame.
    while run ~= 0                                                          %Loop until the user presses stop.        
        if run == 2                                                         %If the run variable equals 2...
            curframe = round(get(handles.slider,'value'));                  %Set the current frame to the position indicated on the slider.
            run = 1;                                                        %Reset the run variable to 1.
        else                                                                %Otherwise...
            set(handles.slider,'value',curframe);                           %Update the slider to show the current frame of the video.
        end
        curframe = curframe + 1;                                            %Increment the current frame.
        im = read(handles.vid,curframe);                                    %Read in the current frame from the video object.
        set(handles.im,'cdata',im);                                         %Update the 'CData' property of the image to the new frame.
        drawnow;                                                            %Update all plots.
        if curframe == handles.vid.NumberOfFrames                           %If we've reached the end of the video.
            run = 0;                                                        %Set the run variable to zero.
        else                                                                %Otherwise...
        while toc < nextframe                                               %Loop until it's time to show the next frame.
            pause(0.001);                                                   %Pause for 1 millisecond.
        end
        nextframe = nextframe + intervals(curframe);                        %Set the time to show the next frame.
        end
    end
    set(handles.playbutton,'string','PLAY','foregroundcolor',[0 0.5 0]);    %Reset the play/stop button string to "PLAY".
    guidata(handles.fig,handles);                                           %Pin the handles structure back to the main figure.
end


%% This function executes when the user interacts with the slider.
function SliderClick(hObject,~)
global curframe                                                             %Create a global variable to track the current frame.
global run                                                                  %Create a global run variable to control playback.
if run == 0                                                                 %If the video isn't currently playing...
    handles = guidata(hObject);                                             %Grab the handles structure from the main figure.
    curframe = round(get(hObject,'value'));                                 %Set the current frame to the position indicated on the slider.
    im = read(handles.vid,curframe);                                        %Read in the current frame from the video object.
    set(handles.im,'cdata',im);                                             %Update the 'CData' property of the image to the new frame.
elseif run == 3                                                             %Otherwise, if the run variable equals 3...
    run = 0;                                                                %Set the run variable to zero.
    pause(0.05);                                                            %Pause for 50 milliseconds.
else                                                                        %Otherwise...
    run = 2;                                                                %Set the run variable to 2 to indicate the loop should adjust the current frame.
end


%% This function is called when the user clicks on the load video button.
function LoadVideo(hObject,~)
global curframe                                                             %Create a global variable to track the current frame.
global run                                                                  %Create a global run variable to control playback.
if run ~= 0                                                                 %If the video is running...
    run = 0;                                                                %Set the run variable to zero.
    pause(0.05);                                                            %Pause for 50 milliseconds.
end
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
[vidfile, path] = uigetfile('*.mp4','Select A Video');                      %Have the user select a video file.
if vidfile(1) == 0                                                          %If the user clicked "cancel"...
    return                                                                  %Skip execution of the rest of the function.
end
handles.vid_file = [path, vidfile];                                         %Save the video file name.
handles.txt_file = [path, vidfile(1:end-4) '.txt'];                         %Create the expected data file name.
if ~exist(handles.txt_file,'file')                                          %If the expected data file isn't found...
    [txtfile, path] = uigetfile([path '*.txt'],...
        'Select the Paired Data File');                                     %Have the user select the paired data file.
    if txtfile(1) == 0                                                      %If the user clicked "cancel"...
        return                                                              %Skip execution of the rest of the function.
    end
    handles.txt_file = [path, txtfile];                                     %Save the unexpected data file name.
end
data = read_tracking_file(handles.txt_file);                                %Read in the data from the tracking file.
data(:,1) = data(:,1) - data(1,1);                                          %Save the frame times to the handles structure.
data(:,4:end) = [];                                                         %Kick out the rotation and area measurements.
handles.logdata = data;                                                     %Save the log data in the handles structure.
handles.vid = VideoReader(handles.vid_file);                                %Open the video file for reading.
if size(data,1) > handles.vid.NumberOfFrames                                %If there's more datapoints than video frames...
    errordlg('The video and data files do not match.','File Error');        %Show an error.
end
curframe = 1;                                                               %Set the current frame to 1.
cla(handles.vid_axes);                                                      %Clear the top axes.
im = read(handles.vid,curframe);                                            %Read in the current frame from the video object.
handles.im = image(im,'parent',handles.vid_axes);                           %Create a new image object.
set(handles.vid_axes,'dataaspectratio',[1 1 1]);                            %Square up the axes.
set(handles.vid_axes,'xtick',[],'ytick',[],'box','on');                     %Remove any x- and y-tick labels.
x = mean(get(handles.vid_axes,'xlim'));                                     %Calculate the x-coordinates for a text label.
y = mean(get(handles.vid_axes,'ylim'));                                     %Calculate the x-coordinates for a text label.
txt = text(x,y,['Loading "' vidfile '"...'],...
    'horizontalalignment','center',...
    'verticalalignment','middle',...
    'fontsize',20*handles.fontscale,...
    'fontweight','bold',...
    'parent',handles.vid_axes,...
    'interpreter','none',...
    'color','r');                                                           %Create a text object to show that the video is being loaded.
drawnow;                                                                    %Update the plot immediately.
if size(data,1) == handles.vid.NumberOfFrames                               %If there's the same number of frames as data points...
    handles.frame_time = data(:,1);                                         %Set the frame time to the data point times.
    set(handles.syncbutton,'enable','off');                                 %Disable the sync video button.
else                                                                        %Otherwise, if there's not the same number of frames as datapoints...
    handles.frame_time = zeros(handles.vid.NumberOfFrames,1);               %Create a matrix to hold the expected frame time for all frames.
    f = 2;                                                                  %Create a frame counter.
    d = 2;                                                                  %Create a datapoint counter.
    while f <= handles.vid.NumberOfFrames && d <= size(data,1)              %Loop until we run out of frames in the video or in the log file.
        i = d + (-3:3);                                                     %Set the indices for measuring the interframe intervals.
        i(i <= 0 | i > size(data,1)) = [];                                  %Kick out an nonexistant datapoints.
        interval = diff(data(i,1));                                         %Find all of the interframe intervals.
        interval = min(interval);                                           %Find the minimum interframe interval.
        int = data(d,1) - data(d-1,1);                                      %Find the interval since the previous datapoint.
        n = floor(int/interval);                                            %Calculate how many frames are expected between the two datapoints.
        int = int/n;                                                        %Calulate the time-step between frames.
        for i = 1:n                                                         %Step through the expected frames.
            handles.frame_time(f) = data(d-1,1) + (i-1)*int;                %Set frame times for each expected frame.
            f = f + 1;                                                      %Increment the frame dounter.
        end
        d = d + 1;                                                          %Increment the datapoint counter.
    end
    if f <= handles.vid.NumberOfFrames                                      %If there's still frames left...
        for i = f:handles.vid.NumberOfFrames                                %Step though the remaining frames.
            handles.frame_time(i) = handles.frame_time(i-1) + int;          %Set the frame time based on the last interframe interval.
        end
    end
    set(handles.syncbutton,'enable','on');                                  %Enable the sync video button.
    handles.vidpath = [];                                                   %Create an empty field to hold the video path.
end
delete(txt);                                                                %Delete the "Loading..." text object.
set(handles.slider,'min',1,...
    'max',handles.vid.NumberOfFrames,...
    'value',curframe,...
    'enable','on');                                                         %Set the properties of the slider.
set(handles.playbutton,'enable','on');                                      %Enable the play button.
guidata(handles.fig,handles);                                               %Save the handles structure to the main figure.


%% This function is called when the user clicks on the sync video button.
function SyncVideo(hObject,~)
global run                                                                  %Create a global run variable to control playback.
global curframe                                                             %Create a global variable to track the current frame.
if run ~= 0                                                                 %If the video is running...
    run = 0;                                                                %Set the run variable to zero.
    pause(0.05);                                                            %Pause for 50 milliseconds.
end
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
curframe = 1;                                                               %Set the current frame to 1.
cla(handles.vid_axes);                                                      %Clear the top axes.
im = read(handles.vid,curframe);                                            %Read in the current frame from the video object.
handles.im = image(im,'parent',handles.vid_axes);                           %Create a new image object.
set(handles.vid_axes,'dataaspectratio',[1 1 1]);                            %Square up the axes.
set(handles.vid_axes,'xtick',[],'ytick',[],'box','on');                     %Remove any x- and y-tick labels.
x = mean(get(handles.vid_axes,'xlim'));                                     %Calculate the x-coordinates for a text label.
y = mean(get(handles.vid_axes,'ylim'));                                     %Calculate the x-coordinates for a text label.
txt = text(x,y,'Building Background Reference...',...
    'horizontalalignment','center',...
    'verticalalignment','middle',...
    'fontsize',20*handles.fontscale,...
    'fontweight','bold',...
    'parent',handles.vid_axes,...
    'interpreter','none',...
    'color','r');                                                           %Create a text object to show that the video is being loaded.
drawnow;                                                                    %Update the plot immediately.
data = handles.logdata;                                                     %Pull the log data out of the handles structure
if isempty(handles.vidpath)                                                 %If the video path hasn't yet been calculated...
    ref_im = zeros(size(im));                                               %Create a matrix to hold the reference image.
    a = size(im);                                                           %Grab the image size.
    counter = zeros(a(1),a(2));                                             %Create a matrix to count the number of samples per pixel.
    curframe = 1;                                                           %Set the current frame to 1.
    prev_im = im;                                                           %Save the first frame as the first previously-read image.
    rand_frames = randperm(handles.vid.NumberOfFrames);                     %Randomize the frame order.
    while curframe < handles.vid.NumberOfFrames && any(counter(:) < 10)     %Loop until the reference image is completely created or we've run out of frames.
        curframe = curframe + 1;                                            %Increment the frame counter.
        im = read(handles.vid,rand_frames(curframe));                       %Read in the current frame.
        temp = imabsdiff(im,prev_im);                                       %Find the difference between frames.
        set(handles.im,'cdata',temp);                                       %Update the 'CData' property of the image to the new frame.
        temp = mean(temp,3);                                                %Convert the RGB image to grayscale.
        drawnow;                                                            %Update the plot immediately.     
        a = (temp <= 1);                                                    %Find all pixels that didn't change between the two images.
        a = repmat(a,[1,1,3]);                                              %Expand the logical array to cover all RGB components.
        ref_im(a) = ref_im(a) + double(im(a));                              %Add the static pixels to the reference image.
        counter(a(:,:,1)) = counter(a(:,:,1)) + 1;                          %Increment the counter for the affected pixels.
        prev_im = im;                                                       %Save the current frame as the previous frame for the next loop.
    end
    for i = 1:3                                                             %Step through the RGB components of the reference image.
        ref_im(:,:,i) = ref_im(:,:,i)./counter;                             %Divide the reference image sums by the pixel count to find the average reference image.
    end
    ref_im = uint8(ref_im);                                                 %Convert the reference image to unsigned integer.
    set(handles.im,'cdata',ref_im);                                         %Update the 'CData' property of the image to the new frame.
    pause(5);                                                               %Pause for 1 second.
    set(txt,'string','Tracing Path...');                                    %Change the label to show we're tracing the rodent's path. 
    curframe = 0;                                                           %Set the current frame to 1.
    vidpath = nan(handles.vid.NumberOfFrames,2);                            %Pre-allocate a matrix to hold the path, as determined by the video.
    plotpath = nan(100,2);                                                  %Create a matrix to show the last 100 datapoints of the rat's path.
    ln = line(mean(xlim),mean(ylim),'color','m','linestyle','--');          %Create a line to show the rat's path.
    while curframe < handles.vid.NumberOfFrames                             %Loop until we've gone through all the frames.
        curframe = curframe + 1;                                            %Increment the frame counter.
        im = read(handles.vid,curframe);                                    %Read in the current frame.
        im = imabsdiff(im,ref_im);                                          %Subtract the image from the reference image.
        set(handles.im,'cdata',im);                                         %Update the 'CData' property of the image to the new frame.
        thresh = graythresh(im);                                            %Calculate an appropriate grayscale threshold.
        im = im2bw(im,thresh);                                              %Convert the  image to black and white using that grayscale level.
        im = medfilt2(im,[2 2]);                                            %Filter the image to remove noise pixels.
        im = bwareaopen(im,10);                                             %Remove small objects less than 10 pixels.
        objs = regionprops(im,'Centroid','Area');                           %Find the centroid and area for each object.
        if ~isempty(objs)                                                   %If any objects are detected...
            [~,j] = sort([objs.Area],'descend');                            %Sort the found objects by descending area.
            objs = objs(j);                                                 %Resort the objects in the stats structure.
            vidpath(curframe,:) = objs(1).Centroid;                         %Grab the x- and y-coordinates of the animal centroid.
            plotpath(1:end-1,:) = plotpath(2:end,:);                        %Shift the samples in the plot coordinates down one.
            plotpath(end,:) = objs(1).Centroid;                             %Add the new centroid to the plot coordinates.
            set(ln,'xdata',plotpath(:,1),'ydata',plotpath(:,2));            %Update the line position.
        end
        if rem(curframe,30) == 0                                            %If the current frame is a multiple of 10...
            drawnow;                                                        %Update the plot immediately.
        end
    end 
    handles.vidpath = vidpath;                                              %Save the video path in the handles structure.
else                                                                        %Otherwise...
    vidpath = handles.vidpath;                                              %Grab the video path from the handles structure.
end
set(txt,'string','Reconciling Video and Log File...');                      %Change the label to show we're reconciling the video with the log file.
handles.frame_time = zeros(handles.vid.NumberOfFrames,1);                   %Create a matrix to hold the expected frame time for all frames.
f = 2;                                                                      %Create a frame counter.
d = 2;                                                                      %Create a datapoint counter.
while f <= handles.vid.NumberOfFrames && d <= size(data,1)                  %Loop until we run out of frames in the video or in the log file.
    i = d + (-3:3);                                                         %Set the indices for measuring the interframe intervals.
    i(i <= 0 | i > size(data,1)) = [];                                      %Kick out an nonexistant datapoints.
    interval = diff(data(i,1));                                             %Find all of the interframe intervals.
    interval = min(interval);                                               %Find the minimum interframe interval.
    int = data(d,1) - data(d-1,1);                                          %Find the interval since the previous datapoint.
    n = floor(int/interval);                                                %Calculate how many frames are expected between the two datapoints.
    int = int/n;                                                            %Calulate the time-step between frames.
    for i = 1:n                                                             %Step through the expected frames.
        handles.frame_time(f) = data(d-1,1) + (i-1)*int;                    %Set frame times for each expected frame.
        f = f + 1;                                                          %Increment the frame dounter.
    end
    d = d + 1;                                                              %Increment the datapoint counter.
end
if f <= handles.vid.NumberOfFrames                                          %If there's still frames left...
    for i = f:handles.vid.NumberOfFrames                                    %Step though the remaining frames.
        handles.frame_time(i) = handles.frame_time(i-1) + int;              %Set the frame time based on the last interframe interval.
    end
end
for i = 1:2                                                                 %Step through the x- and y-coordinates of both the log and video paths.
    vidpath(:,i) = ...
        (vidpath(:,i) - min(vidpath(:,i)))/range(vidpath(:,i));             %Normalize the video path.
    data(:,i+1) = ...
        (data(:,i+1) - min(data(:,i+1)))/range(data(:,i+1));                %Normalize the log file path.
end
l_dist = sqrt(data(:,2).^2 + data(:,3).^2);                                 %Find the euclidean distance from the origin in the log file.
v_dist = sqrt(vidpath(:,1).^2 + vidpath(:,2).^2);                           %Find the euclidean distance from the origin in the video path.
cla(handles.vid_axes);                                                      %Clear the top axes.
hold on;                                                                    %Hold the axes for multiple plots.
p = plot(handles.frame_time,v_dist,'color',[0 0 0.5],'linewidth',2,...
    'marker','.','markersize',5);                                           %Plot the video path profile.
plot(data(:,1),l_dist,'color',[0 0.5 0],'linewidth',2,...
    'marker','.','markersize',5);                                           %Plot the log file path profile.
hold off;                                                                   %Release the plot hold.
axis tight;                                                                 %Tighten the axes.
xlim(xlim + [-0.05,0.05]*range(xlim));                                      %Relax the x-axis limits.
ylim(ylim + [-0.05,0.05]*range(ylim));                                      %Relax the y-axis limits.
text(min(xlim),min(ylim),[' Right-click on matching points to '...
    'align them, left-click to set and exit.'],...
    'horizontalalignment','left',...
    'verticalalignment','top',...
    'fontsize',12,...
    'fontweight','bold',...
    'parent',handles.vid_axes,...
    'interpreter','none',...
    'color','k');                                                           %Create a text object to show that the video is being loaded.
set(gca,'xtick',[],'ytick',[],'DataAspectRatioMode','auto');                %Get rid of the x- and y- axis ticks.
set(handles.fig,'WindowButtonDownFcn',@MouseClick);                         %Set the callback for mouse clicks anywhere on the figure.
checker = nan(1,4);                                                         %Create a matrix to hold x- and y-coordinates.
set(handles.fig,'userdata',checker);                                        %Set the 'UserData' property on the main figure to the checker matrix.
set_times = nan(length(handles.frame_time),1);                              %Indicate which points are fixed.
run = 3;                                                                    %Set the run variable to 3.
while run == 3                                                              %Loop until a valid point is clicked...
    checker = get(handles.fig,'userdata');                                  %Grab the 'UserData' property from the main figure.
    if ~isempty(checker) && any(~isnan(checker))                            %If the user clicked on the axes...
        if all(~isnan(checker))                                             %If all points are plotted
            pause(0.5);                                                     %Pause for 0.5 seconds.
            objs = get(gca,'children');                                     %Grab all children of the axes.
            objs(~strcmpi(get(objs,'type'),'line')) = [];                   %Kick out all non-line objects.
            delete(objs(1:end-2));                                          %Delete all but the main lines.
            a = [(any(checker(1) == handles.frame_time) && ...
                any(checker(2) == v_dist)),...
                (any(checker(3) == handles.frame_time) && ...
                any(checker(4) == v_dist))];                                %Check to see if any of the point are on the video path line.
            b = [(any(checker(1) == data(:,1)) && ...
                any(checker(2) == l_dist)),...
                (any(checker(3) == data(:,1)) && ...
                any(checker(4) == l_dist))];                                %Check to see if any of the point are on the log path line.
            if any(a) && any(b)                                             %If theres at least one point on each line.
                a = find(a);                                                %Grab the index for the video path point.
                b = find(b);                                                %Grab the index for the video path point.
                if length(a) == 2 && length(b) == 1                         %If the two lines share a point and the vid path has both points.
                    a = setdiff(a,b);                                       %Kick out the common point.
                elseif length(b) == 2 && length(a) == 1                     %Otherwise, if the two lines share a point and the log file has both points.
                    b = setdiff(b,a);                                       %Kick out the common point.
                elseif length(a) == 2 && length(b) == 2                     %Otherwise, if both points are common.
                    a = 1;                                                  %Set a equal to the first point.
                    b = 2;                                                  %Set b equal to the second point.
                end
                checker = checker([1,3]);                                   %Grab only the point times.
                i = (handles.frame_time == checker(a));                     %Find the index for the selected video path point.
                set_times(i) = checker(b);                                  %Save the set frame time.
                a = find(~isnan(set_times));                                %Find the indices of all set_times.
                temp = set_times;                                           %Copy the set times.
                if a(1) ~= 1                                                %If the first frame isn't fixed...
                    temp(1:a(1)) = handles.frame_time(1:a(1)) - ...
                        handles.frame_time(a(1)) + temp(a(1));              %Shift all samples preceding the first fixed point.
                end
                for i = 1:length(a)-1                                       %Step through the fixed points.
                    b = (temp(a(i+1)) - temp(a(i)))/...
                        (handles.frame_time(a(i+1)) - ...
                        handles.frame_time(a(i)));                          %Calculate the adjustment ratio.
                    temp(a(i)+1:a(i+1)-1) = ...
                        b*(handles.frame_time(a(i)+1:a(i+1)-1) - ...
                        handles.frame_time(a(i))) + temp(a(i));             %Apply the adjustment ratio.
                end
                if a(end) ~= length(set_times)                              %If the last frame isn't fixed...
                    temp(a(end):end) = handles.frame_time(a(end):end) - ...
                        handles.frame_time(a(end)) + temp(a(end));          %Shift all samples following the last fixed point.
                end
                handles.frame_time = temp;                                  %Save the new frame times.
                set(p,'xdata',handles.frame_time);                          %Show the adjustment.
                axis tight;                                                 %Tighten the axes.
                xlim(xlim + [-0.05,0.05]*range(xlim));                      %Relax the x-axis limits.
                ylim(ylim + [-0.05,0.05]*range(ylim));                      %Relax the y-axis limits.
            end
            set(handles.fig,'userdata',nan(1,4));                           %Reset the points in the 'UserData' property.
        end
    end
    pause(0.05);                                                            %Pause for 50 milliseconds.
end
handles.frame_time = handles.frame_time - handles.frame_time(1);            %Make sure the frame times start at zero.
curframe = 1;                                                               %Set the current frame to 1.
cla(handles.vid_axes);                                                      %Clear the top axes.
im = read(handles.vid,curframe);                                            %Read in the current frame from the video object.
handles.im = image(im,'parent',handles.vid_axes);                           %Create a new image object.
set(handles.vid_axes,'dataaspectratio',[1 1 1]);                            %Square up the axes.
set(handles.vid_axes,'xtick',[],'ytick',[],'box','on');                     %Remove any x- and y-tick labels.
drawnow;                                                                    %Update the plot immediately.
set(handles.slider,'min',1,...
    'max',handles.vid.NumberOfFrames,...
    'value',curframe,...
    'enable','on');                                                         %Set the properties of the slider.
guidata(handles.fig,handles);                                               %Pin the handles structure back to the GUI.
    

%% This function is called whenever the user presses a mouse button over the figure while alignment points.
function MouseClick(hObject,~)
global run                                                                  %Create a global run variable to control playback.
temp = get(hObject,'SelectionType');                                        %Grab the selection type.           
if strcmpi(temp,'normal');                                                  %If the mouse click was with the left button.
    xy = get(gca,'CurrentPoint');                                           %Find the current point in the current axes.
    temp = [xlim, ylim];                                                    %Grab the current x- and y-axis limits.
    if xy(1,1) > temp(1) && xy(1,1) < temp(2) && ...
            xy(1,2) > temp(3) && xy(1,2) < temp(4)                          %If the user clicked within the axes bounds...
        objs = get(gca,'children');                                         %Grab the axes' children.
        objs(~strcmpi(get(objs,'type'),'line')) = [];                       %Kick out any non-line objects.
        x = get(objs,'xdata');                                              %Grab the x-coordinates of all lines.
        x = horzcat(x{:});                                                  %Horizontally concatenate all x-coordinates.
        y = get(objs,'ydata');                                              %Grab the y-coordinates of all lines.
        y = horzcat(y{:});                                                  %Horizontally concatenate all y-coordinates.
        temp = sqrt(((xy(1,1) - x)/range(x)).^2 + ...
            ((xy(1,2) - y)/range(y)).^2);                                   %Find the distance to all  x-y coordinates.
        i = find(temp == min(temp),1,'first');                              %Find the closest point.
        xy = [x(i), y(i)];                                                  %Set the xy-coordinates to the closest point.
        hold on;                                                            %Hold the axes for multiple plots.
        plot(xy(1),xy(2),'color','r',...
            'linestyle','none','marker','o','linewidth',2,...
            'markersize',10);                                               %Show the first point.
        hold off;                                                           %Release the plot hold.
        temp = get(hObject,'UserData');                                     %Grab the figure's UserData property.
        if isnan(temp(1))                                                   %If the first value is NaN...
            temp(1:2) = xy;                                                 %Save the point in the first 2 indices.
        else                                                                %Otherwise...
            temp(3:4) = xy;                                                 %Save the point in the second 2 indices.
        end
        set(hObject,'UserData',temp);                                       %Save the values back to the figure's UserData property.
    end
else                                                                        %Otherwise, if the mouseclick wasn't a left-click.
    run = 0;                                                                %Set the run variable to zero.
end


%% This subfunction creates the GUI.
function handles = Make_GUI
set(0,'units','centimeters');                                               %Set the system units to centimeters.
pos = get(0,'screensize');                                                  %Grab the screen size.
h = 0.9*pos(4);                                                             %Calculate the height of the figure.
w = (16/9)*(0.81)*h + 0.02*h;                                               %Set the figure width based on a 16:9 width:height ratio for the screen.
handles.fig_ratio = w/h;                                                    %Save the expected width to height ratio.
handles.fontscale = h/22;                                                   %Set the font scaling factor based on the figure size.
handles.fig = figure('MenuBar','none',...
    'numbertitle','off',...
    'name','Rodent Tracker Video Player',...
    'units','centimeters',...
    'resize','on',...
    'ResizeFcn',@Resize,...
    'Position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h]);                         %Create a figure.
w = w - 0.02*h;                                                             %Set the width of the video axes.
handles.vid_axes = axes('units','centimeters',...
    'position',[0.01*h, 0.18*h, w, 0.81*h],...
    'box','on',...
    'xtick',[],...
    'ytick',[],...
    'linewidth',2,...
    'xlim',[-1,1],...
    'ylim',[-1,1]);                                                         %Create axes for showing the video.
handles.slider = uicontrol(handles.fig,'style','slider',...
    'units','centimeters',...
    'enable','off',...
    'position',[0.01*h,0.12*h,w,0.05*h]);                                   %Create a video position slider.
w = w - 0.02*h;                                                             %Set the width of the video axes.
handles.loadbutton = uicontrol(handles.fig,'style','pushbutton',...
    'units','centimeters',...
    'fontsize',20*handles.fontscale,...
    'fontweight','bold',...
    'position',[0.01*h,0.01*h,w/3,0.1*h],...
    'string','LOAD VIDEO',...
    'enable','on');                                                         %Create a play/stop button.
handles.syncbutton = uicontrol(handles.fig,'style','pushbutton',...
    'units','centimeters',...
    'fontsize',20*handles.fontscale,...
    'fontweight','bold',...
    'position',[0.02*h+w/3,0.01*h,w/3,0.1*h],...
    'string','SYNC VIDEO',...
    'enable','off');                                                        %Create a play/stop button.
handles.playbutton = uicontrol(handles.fig,'style','pushbutton',...
    'units','centimeters',...
    'fontsize',20*handles.fontscale,...
    'fontweight','bold',...
    'position',[0.03*h+2*w/3,0.01*h,w/3,0.1*h],...
    'string','PLAY',...
    'enable','off',...
    'foregroundcolor',[0 0.5 0]);                                           %Create a play/stop button.
set(get(handles.fig,'children'),'units','normalized');                      %Set all children of the main figure to have normalized units.


%% This function is called whenever the main figure is resized.
function Resize(hObject,~)
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
pos = get(handles.fig,'position');                                          %Grab the figure position.
temp = pos(3)/pos(4);                                                       %Find the current ratio.
if temp > handles.fig_ratio                                                 %If the width is overly long...
    pos(3) = handles.fig_ratio*pos(4);                                      %Scale the width to the height.
else                                                                        %Otherwise, if the height is overly high...
    pos(4) = pos(3)/handles.fig_ratio;                                      %Scale the height to the width.
end
set(handles.fig,'position',pos);                                            %Reset the figure's position.
r = handles.fontscale;                                                      %Grab the previous font scaling factor.
handles.fontscale = pos(4)/22;                                              %Set the new font scaling factor based on the figure size.
r = handles.fontscale/r;                                                    %Calculate the font adjustment factor.
objs = get(handles.fig,'children')';                                        %Grab all of the children of the main figure.
for i = objs                                                                %Step through all children of the main figure.
    set(i,'fontsize',r*get(i,'fontsize'));                                  %Adjust the fontsize for each object.
    if strcmp(get(i,'type'),'axes')                                         %If the object is an axes...
        temp = get(i,'children');                                           %Grab all the children of the axes.
        temp = temp(strcmp(get(temp,'type'),'text'))';                      %Find all text objects within the axes.
        for j = temp                                                        %Step through all text objects within the axes.
            set(j,'fontsize',r*get(j,'fontsize'));                          %Adjust the fontsize for each text object.
        end
    end
end
guidata(handles.fig,handles);                                               %Pin the handles structure to the main figure.