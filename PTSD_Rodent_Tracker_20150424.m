function PTSD_Rodent_Tracker

global plot_type                                                            %Create a global variable to control the plot type.
global run                                                                  %Create a global variable to indicate when the analysis is running.

handles = Make_GUI;                                                         %Call the subfunction to make the GUI.

handles.vidfiles = {};                                                      %Create a field to hold the video filenames.
handles.thresh = 0.5;                                                       %Create a field to hold the detection threshold
handles.buffsize = 3;                                                       %Set the reference buffer to hold 5 seconds of reference frames.
handles.filter_size = 50;                                                   %Set the default filter size, in pixels.
handles.min_pixels = 25;                                                    %Set the default minimum pixel size.
handles.max_speed = 500;                                                    %Set the maximum expected speed, in pixels/s.

temp = userpath;                                                            %Grab the Matlab UserPath.
i = find(temp == '\' | temp == '/');                                        %Find all forward or backward slashes in the UserPath.
handles.videos_dir = [temp(1:i(end-1)) 'Videos\'];                          %Set the default folder to save videos to.

plot_type = 0;                                                              %Set the plot type to zero.
run = 0;                                                                    %Set the run variable to zero.

set(handles.loadbutton,'callback',@SelectVideos);                           %Set the callback for the load video button.
set(handles.trackbutton,'callback',@AnalyzeVideos);                         %Set the callback for the tracking analysis button.
set(handles.slider,'callback',@SliderClick);                                %Set the callback for action on the slider.
set(handles.listbox,'callback',@ListClick);                                 %Set the callback for clicking on the listbox.                                                        %Set the plot type to zero.
setKeyPressFcns(handles.fig,@KeyPress);                                     %Enable the KeyPress commands for adjusting the plot type.

handles.txt = Centered_Text('Load a video file to get started.',...
    handles.fontsize,handles.axes);                                         %Show a start message on the main axes.

guidata(handles.fig,handles);                                               %Pin the handles structure to the GUI.

pos = get(0,'screensize');                                                  %Grab the screen size.
set(handles.fig,'ResizeFcn',@Resize);                                       %Set the resize function for the main figure.
pos(1:2) = pos(3:4)/2;                                                      %Calculate the middle of the screen.
pos(4) = 0.9*pos(4);                                                        %Calculate a maximal height for the GUI.
pos(3) = (16.2/12.9)*pos(4);                                                %Scale the width to the height.
pos(1:2) = pos(1:2) - pos(3:4)/2;                                           %Adjust the left and bottom edges to center the GUI.
set(handles.fig,'position',pos);                                            %Reset the GUI's position.


%% This function executes when the user interacts with the slider.
function SliderClick(hObject,~)
handles = guidata(hObject);                                                 %Grab the handles structure from the main figure.
f = round(get(hObject,'value'));                                            %Set the current frame to the position indicated on the slider.
im = read(handles.vid,f);                                                   %Read in the current frame from the video object.
set(handles.im,'cdata',im);                                                 %Update the 'CData' property of the image to the new frame.


%% This function executes when the user clicks on the listbox.
function ListClick(hObject,~)
handles = guidata(hObject);                                                 %Grab the handles structure from the main figure.
val = get(hObject,'Value');                                                 %Grab the selected video index.
if val ~= handles.curvid                                                    %If the user selected a different video...
    handles.curvid = val;                                                   %Set the current video index to that selected.
    handles = LoadVideo(handles,0);                                         %Load the currently selected video for viewing.
    guidata(handles.fig,handles);                                           %Pin the handles structure back to the main figure.
end


%% This function is called when the user clicks on the load video button.
function SelectVideos(hObject,~)
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
[vidfile, path] = uigetfile({'*.mp4;*.avi;*.wmv',...
    'Video Files (*.mp4,*.avi,*.wmv)'},...
    'Select A Video File','Multiselect','on');                              %Have the user select a video file.
if ~iscell(vidfile) && vidfile(1) == 0                                      %If the user clicked "cancel"...
    return                                                                  %Skip execution of the rest of the function.
end
if ~ishandle(handles.txt)                                                   %If a text object doesn't already exist...
    handles.txt = Centered_Text('Loading video files...',...
        handles.fontsize,handles.axes);                                     %Create a centered text object.
else                                                                        %Otherwise...
    set(handles.txt,'string','Loading video files...');                     %Change the string on the existing text object.
end
set(handles.loadbutton,'enable','off');                                     %Disable the load button.
drawnow;                                                                    %Immediately update the text on the axes.
if ~iscell(vidfile)                                                         %If the user only selected one video file...
    vidfile = {vidfile};                                                    %Convert the video file to a cell array.
end
temp = vidfile{1};                                                          %Grab the first selected video name.
for i = 1:length(vidfile)                                                   %Step through each selected video.
    handles.vidfiles(end+1,:) = {path, vidfile{i}};                         %Save the current video file name.
end
[~,i] = unique(handles.vidfiles(:,2));                                      %Find all unique videos.
handles.vidfiles = handles.vidfiles(i,:);                                   %Kick out any duplicates.
handles.curvid = find(strcmpi(handles.vidfiles(:,2),temp));                 %Set the current video index to the first selected file.
temp = handles.vidfiles(:,2);                                               %Grab all of the file names.
set(handles.loadbutton,'enable','on');                                      %Re-enable the load button.
set(handles.listbox,'string',temp,'value',handles.curvid);                  %Show the currently loaded videos in the listbox.
handles = LoadVideo(handles,0);                                             %Load the currently selected video for viewing.
guidata(handles.fig,handles);                                               %Pin the handles structure back to the main figure.


%% This function loads the currently selected video for viewing.
function handles = LoadVideo(handles,run)
file = horzcat(handles.vidfiles{handles.curvid,:});                         %Concatenate the video file with it's path.
handles.vid = VideoReader(file);                                            %Open the video file for reading.
cla(handles.axes);                                                          %Clear the main axes.
im = read(handles.vid,1);                                                   %Read in the first frame from the video object.
handles.im = image(im,'parent',handles.axes);                               %Create a new image object.
set(handles.axes,'dataaspectratio',[1 1 1]);                                %Square up the axes.
set(handles.axes,'xtick',[],'ytick',[],'box','on');                         %Remove any x- and y-tick labels.
set(handles.slider,'min',1,...
    'max',handles.vid.NumberOfFrames,...
    'value',1,...
    'enable','on');                                                         %Set the properties of the slider.
if run == 0                                                                 %If we're not currently running analysis...
    set([handles.trackbutton, handles.listbox, handles.slider],...
        'enable','on');                                                     %Enable the tracking analysis button.
end
guidata(handles.fig,handles);                                               %Save the handles structure to the main figure.


%% This function is called when the user clicks on the sync video button.
function AnalyzeVideos(hObject,~)
global plot_type                                                            %Create a global variable to control the plot type.
global run                                                                  %Create a global variable to indicate when the analysis is running.
if run == 1                                                                 %If the analysis is currently running.
    run = 0;                                                                %Set the run variable to zero.
    return                                                                  %Skip execution of the rest of the function.
end
vlc_location = 'C:\Program Files (x86)\VideoLAN\VLC\vlc.exe';               %Set the VLC location.
if ~exist(vlc_location,'file')                                              %If VLC doesn't exist in the expected folder...
    [file, path] = uigetfile('vlc.exe','Locate VLC Media Player');          %Have the user locate VLC Media Player.
    if file(1) == 0                                                         %If the user clicked "cancel"...
        return                                                              %Skip execution of the rest of the program.
    end
    vlc_location = [path file];                                             %Otherwise, save the full path pointing to VLC.
end
vlc_location = vlc_location(1:end-4);                                       %Chop off the file extension from the VLC path.
dos_str{1} = sprintf('"%s" ',vlc_location);                                 %Create the first part of a DOS command.
dos_str{2} = ' --sout ';                                                    %Create the second part of the DOS command.
dos_str{3} = '#transcode{acodec=s16l,channels=2}';                          %Create the third part of the DOS command.
dos_str{4} = ':std{access=file,mux=wav,dst=';                               %Create the fourth part of the DOS command.
dos_str{7} = 'vlc://quit';                                                  %Create the fourth part of the DOS command.
plot_type = 0;                                                              %Set the plot type to zero.
run = 1;                                                                    %Set the run variable to one to indicate analysis is happening.
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
prompt = {['Minimum distance (pixels) the rat/mouse must move '...
    'between recorded points (set to zero to record every frame):'],...
    'Tracking threshold, in percent (0-100%):',...
    'Reference image buffer size, (seconds):',...
    'Image filter size (pixels):',...
    'Minimum tracked size (pixels):',...
    'Maximum allowable speed (pixels/second):'};                            %Create prompts for the user to enter values.
dlg_title = 'Set Tracking Properties';                                      %Set the dialog title for the following input dialog box.
num_lines = 1;                                                              %Set the number of lines to return for each question.
def = {'0.5',num2str(100*handles.thresh),num2str(handles.buffsize),...
    num2str(handles.filter_size),num2str(handles.min_pixels),...
    num2str(handles.max_speed)};                                            %Set the default answers.
temp = inputdlg(prompt,dlg_title,num_lines,def);                            %Have the user set the dimensions with an input dialog box.
if isempty(temp)                                                            %If the user pressed cancel...
    return;                                                                 %Skip execution of the rest of the function.
end
for i = 1:length(temp)                                                      %Step through each value.
    temp{1}(temp{1} < 46 |temp{1} > 57) = [];                               %Kick out all non-number characters.
end
if ~all(str2double(temp(2:end)) > 0)                                        %If all of the entered values aren't positive numbers...
    warndlg('All values must be positive, non-zero numbers!',...
        'Invalid Values!');                                                 %Show a warning that not all values are valid.
    return                                                                  %Skip execution of the rest of the function.
end
min_dist = str2double(temp{1});                                             %Convert the entered string to a number.
handles.thresh = str2double(temp{2});                                       %Grab the user-set tracking threshold.
if handles.thresh > 100                                                     %If the user set the threshold to more than 100%...
    warndlg('The tracking number must be betwee 0 and 100%!',...
        'Invalid Threshold Value!');                                        %Show a warning that not all values are valid.
    return                                                                  %Skip execution of the rest of the function.
end
handles.thresh = handles.thresh/100;                                        %Scale the threshold to between 0 and 1.
handles.buffsize = str2double(temp{3});                                     %Grab the user-set reference buffer size.
handles.filter_size = str2double(temp{4});                                  %Grab the user-set filter size, in pixels.
handles.min_pixels = str2double(temp{5});                                   %Grab the user-set minimum pixel size.
handles.max_speed = str2double(temp{6});                                    %Grab the user-set maximum speed.
set(handles.trackbutton,'string','Stop Analysis');                          %Change the string on the start analysis button.
set([handles.loadbutton,handles.listbox,handles.slider],'enable','off');    %Disable the other uicontrols.
for c = 1:size(handles.vidfiles,1)                                          %Step through each video.
    handles.curvid = c;                                                     %Set the current video index to that selected.
    set(handles.listbox,'value',c);                                         %Show which video is currently being analyzed in the listbox.
    handles = LoadVideo(handles,1);                                         %Load the currently selected video for viewing.
    objs = get(handles.axes,'children');                                    %Grab all children of the main axes.
    delete(objs(strcmpi(get(objs,'type'),'text')));                         %Delete any text objects.
    txt = Centered_Text({handles.vidfiles{c,2},...
        'Extracting Audio...'}, 0.75*handles.fontsize,...
        handles.axes);                                                      %Show a start message on the main axes.
    drawnow;                                                                %Immediately update the plot.
%     file = horzcat(handles.vidfiles{handles.curvid,:});                     %Concatenate the video file with it's path.
%     wav_file = [file(1:end-4) '.wav'];                                      %Specify a wave file name.
%     dos_str{5} = sprintf('"%s"',wav_file);                                  %Grab the wave filename.
%     dos_str{6} = sprintf(' "%s" ',file);                                    %Grab the filename.
%     dos(horzcat(dos_str{:}),'-echo');                                       %Call VLC player from the DOS command line.
%     [signal, fs] = audioread(wav_file);                                     %Read in the session audio file.
%     signal(:,2) = [];                                                       %Kick out the second channel of audio.
%     signal = signal/max(abs(signal));                                       %Normalize the signal scale.
%     times = find(signal(1:end-1) < 0.75 & signal(2:end) >= 0.75);           %Find all points where the signal passed upward through 75%.
%     times = times/fs;                                                       %Convert all times to seconds.
    
    
    
    txt = Centered_Text({handles.vidfiles{c,2},...
        'Building a background reference...'}, 0.75*handles.fontsize,...
        handles.axes);                                                      %Show a start message on the main axes.
    filter_size = round(handles.filter_size);                               %Calculate the filter size to use, in pixels.
        
    %Calculate a reference image.
    im = read(handles.vid,1);                                               %Read in the first frame from the video object.    
%     im = mean(im,3);                                                        %Convert the image to grayscale.
    im = im(:,:,2);                                                         %Grab just the green layer.
    set(handles.im,'cdatamapping','scaled');                                %Update the 'CDataMapping' property of the image to be scaled.
    colormap(handles.axes,'gray');                                          %Set the colormap to grayscale.
    a = size(im);                                                           %Grab the image size.
    ref_im = zeros(a(1),a(2));                                              %Create a matrix to hold a buffer of reference frames.
    curframe = 1;                                                           %Set the current frame to 1.
    rand_frames = randperm(handles.vid.NumberOfFrames);                     %Randomize all of the video frames.
    if handles.vid.NumberOfFrames > handles.buffsize*handles.vid.FrameRate  %If enough video to fill the buffer.
        rand_frames(handles.buffsize*handles.vid.FrameRate+1:end) = [];     %Kick out an extra frames.
    end
    while curframe < length(rand_frames)                                    %Loop until the reference image is completely created or we've run out of frames.
        curframe = curframe + 1;                                            %Increment the frame counter.
        set(txt,'string',{handles.vidfiles{c,2},...
            ['Building an initial background reference (Frame '...
            num2str(curframe) '/' num2str(length(rand_frames)) ...
            ')...']});                                                      %Change the label to show the current frame.
        set(handles.slider,'value',rand_frames(curframe));                  %Set the slider position to show the video frame.
        im = read(handles.vid,rand_frames(curframe));                       %Read in the current frame.
%         im = mean(im,3);                                                    %Convert the image to grayscale.
        im = im(:,:,2);                                                     %Grab only the green layer of the image.
        im = medfilt2(im,[1,1]*filter_size);                                %Filter the image to remove noise pixels.
        ref_im = ref_im + double(im);                                       %Add the current frame to the reference frame total.
        set(handles.im,'cdata',ref_im);                                     %Update the 'CData' property of the image to the new frame.
        drawnow;                                                            %Update the plot immediately.     
    end
    ref_im = ref_im/length(rand_frames);                                    %Calculate the average frame.
    ref_im = ref_im - min(ref_im(:));                                       %Subtract out the minimum value from the reference image.
    ref_im = ref_im/max(ref_im(:));                                         %Normalize the reference image.
    set(handles.im,'cdata',ref_im);                                         %Update the 'CData' property of the image to the new frame.
    pause(1);                                                               %Pause for 1 second.
   
    %Create the file header.
    rat = handles.vidfiles{c,2};                                            %Grab the video file name.
    rat(find(rat == '.',1,'last'):end) = [];                                %Kick out the file extension from the filename.
    filename = [handles.vidfiles{c,1}, rat, '_ACTIVITY.txt'];               %Create the text file name.
    fprintf(1,'Save path data to: %s\n',filename);                          %Show the user the data file destination.
    fid = fopen(filename,'wt');                                             %Open a new text file to recieve tracking information.
    fprintf(fid,'%s ','SUBJECT:');                                          %Write a label for the subject's name.
    fprintf(fid,'%s\n',rat);                                                %Write the subject's name.
    fprintf(fid,'%s ','DATE:');                                             %Write a label for the date.
    temp = dir(horzcat(handles.vidfiles{c,:}));                             %Grab the video file info.
    fprintf(fid,'%s\n\n',datestr(temp.datenum,1));                          %Write the session date.
    fprintf(fid,'%s ','START TIME:');                                       %Write a label for the start time.
    temp = temp.datenum - ...
        handles.vid.NumberOfFrames/(86400*handles.vid.FrameRate);           %Calculate the start time of the video.
    fprintf(fid,'%s\n\n',datestr(temp,13));                                 %Write the start time.
    fprintf(fid,'%s ','SCALE (pixels/cm):');                                %Write a label for the pixels/centimeters scale.
    fprintf(fid,'%1.4f\n',90);                                              %Write the pixels/centimeters scale.
    fprintf(fid,'%s ','RESOLUTION (pixels):');                              %Write a label for the pixels/centimeters scale.
    temp = num2str([handles.vid.Width,handles.vid.Height],'%1.0fx');        %Grab the video resolution and convert it to a string.
    fprintf(fid,'%s\n',temp(1:end-1));                                      %Write the pixels/centimeters scale.
    fprintf(fid,'%s ','BOUNDS (pixels):');                                  %Write a label for the bounding polygon vertices.
    fprintf(fid,'(%1.0f,%1.0f), ',[0,0]);                                   %Write the bottom left corner.
    fprintf(fid,'(%1.0f,%1.0f), ',[0,handles.vid.Height]);                  %Write the upper left corner.
    fprintf(fid,'(%1.0f,%1.0f), ',...
        [handles.vid.Width,handles.vid.Height]);                            %Write the upper right corner.
    fprintf(fid,'(%1.0f,%1.0f)\n\n',[handles.vid.Width,0]);                 %Write the lower right corner.
    fprintf(fid,'%s\t','TIME_(s)');                                         %Write a label for the start time.
    fprintf(fid,'%s\t','X_POSITION_(pixels)');                              %Write a label for the animal's centroid x-coordinates.
    fprintf(fid,'%s\t','Y_POSITION_(pixels)');                              %Write a label for the animal's centroid y-coordinates.
    fprintf(fid,'%s\t','ORIENTATION_(degrees)');                            %Write a label for the animal's orientation.
    fprintf(fid,'%s\n','LENGTH_(pixels)');                                  %Write a label for the animal's length.
    
    %Track the rat through the whole video file.
    set(txt,'string',{handles.vidfiles{c,2},['Tracing Path (Frame 1/' ...
        num2str(handles.vid.NumberOfFrames) ')...']});                      %Change the label to show we're tracing the rodent's path. 
    curframe = 0;                                                           %Set the current frame to 1.
    prev_pos = [-Inf,-Inf];                                                 %Set the previous position to infinite to make sure the first frame is written.
    prev_frame = 0;                                                         %Set the previous motion frame to zero.
    plotpath = nan(500,2);                                                  %Create a matrix to show the last 500 datapoints of the rat's path.
    plot_obj = zeros(1,4);                                                  %Create a matrix to hold plot objects.
    circ_size = min_dist;                                                   %Set the size of the minimum distance circle.
    circle_pts = circ_size*[cos(0:pi/25:2*pi)', sin(0:pi/25:2*pi)'];        %Create points for drawing circles.
    target_cir(:,1) = circle_pts(:,1);                                      %Locate a movement-threshold circle's x-coordinates relative to the previous position.
    target_cir(:,2) = circle_pts(:,2);                                      %Locate a movement-threshold circle's x-coordinates relative to the previous position.
    plot_obj(1) = line(target_cir(:,1),target_cir(:,2),...
        'parent',handles.axes,'color','y','linewidth',2);                   %Draw a circle around the previous position showing the movement threshold.
    plot_obj(2) = line(0,0,'parent',handles.axes,'color','m',...
        'marker','o','linestyle','none','markerfacecolor','w');             %Mark the centroid of the object with a magenta circle.
    plot_obj(3) = line(0,0,'parent',handles.axes,'color','m',...
        'linestyle',':','linewidth',2);                                     %Show the historical path of the object as a magenta line.
    plot_obj(4) = line(0,0,'parent',handles.axes,'color','c',...
        'linestyle','-','linewidth',2);                                     %Show the rat's orientation as a yellow line.
    uistack(txt,'top');                                                     %Move the text label to the top.
    while curframe < handles.vid.NumberOfFrames && run == 1                 %Loop until we've gone through all the frames.
        curframe = curframe + 1;                                            %Increment the frame counter.
        im = read(handles.vid,curframe);                                    %Read in the current frame.
%         im = mean(im,3);                                                    %Convert the image to a 16-bit integer for analysis.
        im = im(:,:,2);                                                     %Grab only the green layer of the image.
        if plot_type == 0                                                   %If the plot type is zero...
            set(handles.im,'cdata',im,'cdatamapping','scaled');             %Update the 'CData' property of the image to show the normalized image.
        end
        im = medfilt2(im,[1,1]*filter_size);                                %Filter the image to remove noise pixels.
        if plot_type == 1                                                   %If the plot type is one...
            set(handles.im,'cdata',im,'cdatamapping','scaled');             %Update the 'CData' property of the image to show the filtered image.
        end
        im = double(im - min(im(:)));                                       %Subtract the minimum from the image.
        im = im/double(max(temp(:)));                                       %Normalize the image.
        im = abs(im - ref_im);                                              %Find the absolute difference between the current frame and the reference.
        im = (im - min(im(:)))./(max(im(:)) - min(im(:)));                  %Normalize the difference between the reference and current image.
        if plot_type == 2                                                   %If the plot type is two...
            set(handles.im,'cdata',im,'cdatamapping','scaled');             %Update the 'CData' property of the image to show the difference.
        end        
        im = (im > handles.thresh);                                         %Convert the  image to black and white using that grayscale level.
        im = bwareaopen(im,handles.min_pixels);                             %Remove small objects less than 10 pixels.
        if plot_type == 3                                                   %If the plot type is three...
            set(handles.im,'cdata',im,'cdatamapping','scaled');             %Update the 'CData' property of the image to show the filtered, thresholded image.
        end
        objs = regionprops(im,'Centroid','Area','Orientation',...
            'MajorAxisLength','BoundingBox');                               %Find the centroid and area for each object.
        if ~isempty(objs)                                                   %If any objects are detected...
            [~,j] = sort([objs.Area],'descend');                            %Sort the found objects by descending area.
            objs = objs(j);                                                 %Resort the objects in the stats structure.
            xy = objs(1).Centroid;                                          %Grab the x- and y-coordinates of the animal centroid.
            rot = objs(1).Orientation;                                      %Grab the long-axis orientation of the animal.
            len = objs(1).MajorAxisLength;                                  %Grab the length of the long-axis of the animal.
            d = euclid_dist(xy,prev_pos);                                   %Calculate the Euclidean distance to the previous centroid.
            s = handles.vid.FrameRate*(d)/(curframe - prev_frame);          %Calculate the frame-to-frame speed of the rat.
            if prev_pos(1) < 0                                              %If there is no previous position...
                s = 0;                                                      %Set the speed to zero.
            end
            if d > min_dist && s < handles.max_speed                        %If the rat has moved more than the minimum distance from their previous centroid...
                fprintf(fid,'%1.3f\t',...
                    (curframe-1)/handles.vid.FrameRate);                    %Write the sample time, in seconds.
                fprintf(fid,'%1.2f\t',xy(1));                               %Write the x coordinate, in centimeters.
                fprintf(fid,'%1.2f\t',xy(2));                               %Write the y coordinate, in centimeters.
                fprintf(fid,'%1.2f\t',rot);                                 %Write the orientation, in degress.
                fprintf(fid,'%1.2f\n',len);                                 %Write the major axis length, in centimeters.  
                fprintf(1,'%1.3f\t',...
                    (curframe-1)/handles.vid.FrameRate);                    %Write the sample time to the command line, in seconds.
                fprintf(1,'%1.2f\t',xy(1));                                 %Write the x coordinate to the command line, in centimeters.
                fprintf(1,'%1.2f\t',xy(2));                                 %Write the y coordinate to the command line, in centimeters.
                fprintf(1,'%1.2f\t',rot);                                   %Write the orientation to the command line, in degress.
                fprintf(1,'%1.2f\n',len);                                   %Write the major axis length to the command line, in centimeters.
                prev_pos = xy;                                              %Save the new centroid location as the previous location.
                prev_frame = curframe;                                      %Save the current frame as the previous motion frame.
                plotpath(1:end-1,:) = plotpath(2:end,:);                    %Shift the samples in the plot coordinates down one.                
                plotpath(end,:) = xy;                                       %Add the new centroid to the plot coordinates.
                target_cir(:,1) = circle_pts(:,1) + prev_pos(1);            %Locate a movement-threshold circle's x-coordinates relative to the previous position.
                target_cir(:,2) = circle_pts(:,2) + prev_pos(2);            %Locate a movement-threshold circle's x-coordinates relative to the previous position.
                set(plot_obj(1),'xdata',target_cir(:,1),...
                    'ydata',target_cir(:,2));                               %Update the position of the previous position circle.
                set(plot_obj(3),'xdata',plotpath(:,1),...
                    'ydata',plotpath(:,2));                                 %Update the rodent path.
            end                
            set(plot_obj(2),'xdata',xy(1),'ydata',xy(2));                   %Update the position of the rodent centroid.
            set(plot_obj(4),'xdata',xy(1)+[-0.5,0.5]*len*cosd(rot),...
                'ydata',xy(2)+[-0.5,0.5]*len*sind(-rot));                   %Update the rodent orientation line.
        end
        set(txt,'string',{handles.vidfiles{c,2},['Tracing Path (Frame '...
            num2str(curframe) '/' num2str(handles.vid.NumberOfFrames) ...
            ')...']});                                                      %Change the label to show the current frame.
        set(handles.slider,'value',curframe);                               %Set the slider position to show the video frame.
        drawnow;                                                            %Update the plot immediately.
    end
    fclose(fid);                                                            %Close the data file.
    if run == 0                                                             %If the user canceled the tracking analysis...
        delete(filename);                                                   %Delete the last file.
        break                                                               %Break out of the or loop.
    end
end
handles.curvid = 1;                                                         %Set the current video index to that selected.
set(handles.im,'cdatamapping','direct');                                    %Update the 'CDataMapping' property of the image to be direct.
handles = LoadVideo(handles,0);                                             %Load the currently selected video for viewing.
set(handles.trackbutton,'string','Start Tracking Analysis');                %Change the string on the start analysis button.
set([handles.loadbutton,handles.listbox,handles.slider],'enable','on');     %Re-enable the other uicontrols.
run = 0;                                                                    %Set the run variable to zero to indicate idle mode.
guidata(handles.fig,handles);                                               %Save the handles structure to the main figure.


%% This function is called when the user presses a key while the main figure during analysis mode focus.
function KeyPress(~,eventdata)
global plot_type                                                            %Create a global variable to control the plot type.
if strcmpi(eventdata.Key,'downarrow')                                       %If the key pressed was the down arrow...
    temp = plot_type - 1;                                                   %Subtract one from the plot type.
else                                                                        %Otherwise, for any other key...
    temp = plot_type + 1;                                                   %Increment the plot type.
end
if temp > 3                                                                 %If the plot type is greater than 3...
    temp = 0;                                                               %Reset the plot type to zero.
elseif temp < 0                                                             %If the plot type is less than zero...
    temp = 3;                                                               %Set the plot type to 3.
end
plot_type = temp;                                                           %Set the plot type to the temporary matrix.


%% This subfunction creates the GUI.
function handles = Make_GUI
set(0,'units','centimeters');                                               %Set the system units to centimeters.
pos = get(0,'screensize');                                                  %Grab the screen size.
handles.fontsize = 10;                                                      %Set the font scaling factor based on the figure size.
handles.fig = figure('MenuBar','none',...
    'numbertitle','off',...
    'name','Rodent Tracker - Offline Analysis',...
    'units','centimeters',...
    'resize','on',...
    'Position',[pos(3)/2-8.1, pos(4)/2-6.7, 16.2, 12.9]);                   %Create a figure.
handles.pos = get(handles.fig,'position');                                  %Save the initial position of the figure.
handles.axes = axes('units','centimeters',...
    'position',[0.1, 3.8, 16, 9],...
    'box','on',...
    'xtick',[],...
    'ytick',[],...
    'linewidth',2,...
    'xlim',[-1,1],...
    'ylim',[-1,1]);                                                         %Create axes for showing the video.
handles.slider = uicontrol(handles.fig,'style','slider',...
    'units','centimeters',...
    'enable','off',...
    'position',[0.1, 3.2, 16, 0.5],...
    'backgroundcolor',[0.8 0.8 1]);                                         %Create a video position slider.
handles.listbox = uicontrol(handles.fig,'style','listbox',...
    'units','centimeters',...
    'enable','inactive',...
    'fontweight','bold',...
    'fontsize',0.75*handles.fontsize,...
    'position',[0.1, 0.1, 10, 3]);                                          %Create a listbox to show the loaded files.
handles.trackbutton = uicontrol(handles.fig,'style','pushbutton',...
    'units','centimeters',...
    'fontsize',handles.fontsize,...
    'fontweight','bold',...
    'position',[10.2, 0.1, 6, 1.45],...
    'string','Start Tracking Analysis',...
    'enable','off');                                                        %Create a start analysis button.
handles.loadbutton = uicontrol(handles.fig,'style','pushbutton',...
    'units','centimeters',...
    'fontsize',handles.fontsize,...
    'fontweight','bold',...
    'position',[10.2, 1.65, 6, 1.45],...
    'string','Load Video(s)',...
    'enable','on');                                                         %Create a load files button.
set(get(handles.fig,'children'),'units','normalized');                      %Set all children of the main figure to have normalized units.


%% This function is called whenever the main figure is resized.
function Resize(hObject,~)
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
ratio = handles.pos(3)/handles.pos(4);                                      %Calculate the original height to width ratio.
pos = get(handles.fig,'position');                                          %Grab the new figure position.
if handles.pos(4) ~= pos(4)                                                 %If the user changed the height.
    pos(3) = pos(4)*ratio;                                                  %Scale the width by the height.
else                                                                        %Otherwise...
    pos(4) = pos(3)/ratio;                                                  %Scale the height by the width.
end
set(handles.fig,'position',pos);                                            %Apply the scaled position to the figure.
ratio = pos(4)/handles.pos(4);                                              %Find the ratio of the previous figure height to the new.
handles.pos = pos;                                                          %Save the new position.
handles.fontsize = 0.75*pos(4);                                             %Set the font scaling factor based on the figure size.
objs = get(handles.fig,'children');                                         %Grab all children of the figure.
for i = 1:length(objs)                                                      %Step through each object.
    set(objs(i),'fontsize',ratio*get(objs(i),'fontsize'));                  %Scale the font size accordingly.
end
objs = get(handles.axes,'children');                                        %Grab all children of the main axes.
if ~isempty(objs)                                                           %If the axes had any children...
    objs(~strcmpi(get(objs,'type'),'text')) = [];                           %Kick out all non-text objects.
    for i = 1:length(objs)                                                  %Step through each object.
        set(objs(i),'fontsize',ratio*get(objs(i),'fontsize'));              %Scale the font size accordingly.
    end
end
guidata(handles.fig,handles);                                               %Pin the handles structure back to the GUI.


%% This function creates a centered text object on the specified axes.
function txt = Centered_Text(string,fontsize,ax)
txt = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),string,...
    'parent',ax,'horizontalalignment','center',...
    'verticalalignment','middle','fontsize',fontsize,...
    'fontweight','bold','margin',5,'backgroundcolor','w',...
    'edgecolor','k','interpreter','none');                                  %Create a centered text object.


%% This function calculates the euclidean distance between two points.
function d = euclid_dist(p1,p2)
d = sqrt(sum((p1-p2).^2,2));                                                %Calculate the euclidean distance between the two sets of coordinates.