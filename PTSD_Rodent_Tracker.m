function PTSD_Rodent_Tracker

global plot_type                                                            %Create a global variable to control the plot type.
global run                                                                  %Create a global variable to indicate when the analysis is running.

handles = Make_GUI;                                                         %Call the subfunction to make the GUI.

handles.vidfiles = {};                                                      %Create a field to hold the video filenames.
handles.filter_size = 10;                                                   %Set the filtersize for blurring the image.

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
colormap(handles.axes,'gray');                                              %Set the axes' colormap to gray.
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
    set(hObject,'string','Start Tracking Analysis');                        %Change the string on the start analysis button.
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
    
    %Extract the audio.
    file = horzcat(handles.vidfiles{handles.curvid,:});                     %Concatenate the video file with it's path.
    wav_file = [file(1:end-4) '.wav'];                                      %Specify a wave file name.
    dos_str{5} = sprintf('"%s"',wav_file);                                  %Grab the wave filename.
    dos_str{6} = sprintf(' "%s" ',file);                                    %Grab the filename.
    dos(horzcat(dos_str{:}),'-echo');                                       %Call VLC player from the DOS command line.
    [signal, fs] = audioread(wav_file);                                     %Read in the session audio file.
    signal(:,2) = [];                                                       %Kick out the second channel of audio.
    N = length(signal);                                                     %Grab the number of samples.
    x = (1:N)/fs;                                                           %Find timestamps for each sample.
    signal = abs(signal);                                                   %Convert the signal to absolute value.
    j = [0; signal(2:end-1) >= signal(1:end-2) & ...
        signal(2:end-1) > signal(3:end); 0];                                %Find all peaks in the signal.
    signal = signal(j == 1);                                                %Grab only the signal envelop.
    x = x(j == 1);                                                          %Grab only the peak signals.
    j = find(x > 60,1,'first');                                             %Find the first timepoint after the first minute.
    temp = sort(abs(signal(j:end)));                                        %Sort the samples of the signal.
    a = temp(round(0.90*length(temp)));                                     %Find the 90th percentile.    
    signal = signal - a;                                                    %Subtract the 90th percentile from the signal.
    j = signal <= 0;                                                        %Find all points below zero.
    signal(j) = [];                                                         %Kick out all negative points.
    x(j) = [];                                                              %Kick out the same points from the timepoints.
    signal = signal/max(signal(:));                                         %Normalize the signal to the maximum.
    j = find(x > 60,1,'first');                                             %Find the first timepoint after the first minute.
    temp = sort(abs(signal(j:end)));                                        %Sort the samples of the signal.
    temp = 3*temp(round(0.95*length(temp)));                                %Set a threshold to three times the value of the 95th percentile.
    w = 10;                                                                 %Set the figure width, in inches.
    h = 4;                                                                  %Set the figure height, in inches.
    set(0,'units','inches');                                                %Set the default system units to inches.
    pos = get(0,'screensize');                                              %Grab the current screensize.
    pos = [pos(3)/2-w/2,pos(4)/2-2*h/3,w,h];                                %Set the position of a new figure.
    fig = figure('units','inches',...
        'position',pos,...
        'color','w',...
        'MenuBar','none',...
        'name',file,...
        'paperpositionmode','auto',...
        'inverthardcopy','off',...
        'paperunits','inches',...
        'papersize',[w,h],...                                               %Create a new figure.
        'numbertitle','off');                                               %Set the properties of the figure.
    ax = axes('parent',fig,'position',[0.05 0.1 0.94 0.86]);                %Create axes on the figure.
    hold(ax);                                                               %Hold the axes.
    plot(x,signal,'color','k','parent',ax);                                 %Plot the signal.                  
    xlim(ax,[0,N/fs]);                                                      %Set the axes limits.
    line([0,N/fs],temp*[1,1],'color','r','linestyle','--','parent',ax);     %Draw a line to show the threshold.     
    set(ax,'fontsize',8);                                                   %Set the fontsize for the axes.
    ylim(ax,2*temp*[0,1]);                                                  %Set the y-axis limits.
    j = [0; (signal(1:end-1) < temp & signal(2:end) >= temp)];              %Find all points where the signal passed upward through the threshold.
    times = x(j == 1);                                                      %Find the timepoint for each crossing.
    j = [0, times(2:end) - times(1:end-1) < 2];                             %Find all times that are less than 2 seconds from the preceding times.
    times(j == 1) = [];                                                     %Kick out all sounds that are less than 20 seconds from the preceding time.
    plot(times,temp*ones(size(times)),'color','b','marker','.',...
        'markersize',20,'linestyle','none','parent',ax);                    %Plot the times as blue asterixes.
    xlabel(ax,'Time (s)','fontsize',8);                                     %Label the x-axis.
    ylabel(ax,'Relative Sound Amplitude','fontsize',8);                     %Label the y-axis.
    pause(1);                                                               %Pause for 1 second.
    file = [file(1:end-4) '_audio.png'];                                    %Create a filename for the audio trace image.
    print(fig,file,'-dpng','-r150');                                        %Save the audio images as a PNG file.
    close(fig);                                                             %Close the figure.
   
    %Create a data file and write the sound times to it.
    file = horzcat(handles.vidfiles{c,:});                                  %Grab the video file name.
    a = find(file == '.',1,'last') - 1;                                     %Find the beginning of the file extension.
    filename = [file(1:a) '_PTSD_ACTIVITY.txt'];                            %Create the text file name.
    fprintf(1,'Saving data to: %s\n',filename);                             %Show the user the data file destination.
    fid = fopen(filename,'wt');                                             %Open a new text file to recieve tracking information.
    fprintf(fid,'BEGIN SOUND ONSETS\n');                                    %Print the sound onsets start label to the file.
    fprintf(fid,'%1.3f\n',times);                                           %Print the sound onset times.
    fprintf(fid,'END SOUND ONSETS\n\n');                                    %Print the sound onsets end label to the file.
    
    %Track the rat through the whole video file.
    set(txt,'string',{handles.vidfiles{c,2},['Analyzing Movement '...
        '(Frame 1/' num2str(handles.vid.NumberOfFrames) ')...']});          %Change the label to show we're tracing the rodent's path. 
    curframe = 0;                                                           %Set the current frame to 1.
    uistack(txt,'top');                                                     %Move the text label to the top.
    prev_im_rgb = [];                                                       %Create a matrix to hold the previous RGB image.
    prev_im_gray = [];                                                      %Create a matrix to hold the previous grayscale image.
    fprintf(fid,'BEGIN PIXEL COUNTS\n');                                    %Print the pixel counts start label.
    while curframe < handles.vid.NumberOfFrames && run == 1                 %Loop until we've gone through all the frames.
        curframe = curframe + 1;                                            %Increment the frame counter.
        im_rgb = read(handles.vid,curframe);                                %Read in the current frame.
        if plot_type == 0                                                   %If the plot type is zero...
            set(handles.im,'cdata',im_rgb,'cdatamapping','direct');         %Update the 'CData' property of the image to show the normalized image.            
        end
        im_gray = mean(double(im_rgb),3);                                   %Calculate the grayscale image as the mean.
        if plot_type == 1                                                   %If the plot type is one...
            set(handles.im,'cdata',im_gray,'cdatamapping','scaled');        %Update the 'CData' property of the image to show the filtered image.
            colormap(handles.axes,'gray');                                  %Set the axes' colormap to gray.
        end
%         im_gray = medfilt2(im_gray,[1,1]*handles.filter_size);              %Filter the image to remove noise pixels.
        im_gray = boxsmooth(im_gray,[1,1]*handles.filter_size);             %Boxsmooth the image to re
        if plot_type == 2                                                   %If the plot type is one...
            set(handles.im,'cdata',im_gray,'cdatamapping','scaled');        %Update the 'CData' property of the image to show the filtered image.
            colormap(handles.axes,'gray');                                  %Set the axes' colormap to gray.
        end
        if isempty(prev_im_rgb)                                             %If no previous image is loaded...
            prev_im_rgb = double(im_rgb);                                   %Set the previous RGB image to the current RGB image.
            prev_im_gray = im_gray;                                         %Set the previous image to the current image.
        end
        temp = double(im_rgb) - prev_im_rgb;                                %Find the difference between this image and the previous image.
        prev_im_rgb = double(im_rgb);                                       %Save the current image as the previous image for the next iteration.
        im_rgb = abs(temp);                                                 %Find the absolute value of the changes between the images.
        if plot_type == 4                                                   %If the plot type is two...
            set(handles.im,'cdata',uint8(im_rgb),'cdatamapping','direct');  %Update the 'CData' property of the image to show the difference.
        end
        fprintf(fid,'%1.3f\t',(curframe-1)/handles.vid.FrameRate);          %Write the sample time, in seconds, to the file.
        fprintf(fid,'%1.0f\t',sum(im_rgb(:)));                              %Write the sum of the pixel changes, to the file.
        fprintf(1,'%1.3f\t',(curframe-1)/handles.vid.FrameRate);            %Write the sample time, in seconds, to the command line.
        fprintf(1,'%1.0f\t',sum(im_rgb(:)));                                %Write the sum of the pixel changes, to the command line.
        temp = im_gray - prev_im_gray;                                      %Find the difference between this image and the previous image.
        prev_im_gray = im_gray;                                             %Save the current image as the previous image for the next iteration.
        im_gray = abs(temp);                                                %Find the absolute value of the changes between the images.
        if plot_type == 3                                                   %If the plot type is two...
            set(handles.im,'cdata',im_gray,'cdatamapping','scaled');        %Update the 'CData' property of the image to show the difference.
            colormap(handles.axes,'jet');                                   %Set the axes' colormap to gray.
        end        
        fprintf(fid,'%1.0f\n',sum(im_gray(:)));                             %Write the sum of the pixel changes, to the file.
        fprintf(1,'%1.0f\n',sum(im_gray(:)));                               %Write the sum of the pixel changes, to the command line.
        set(txt,'string',{handles.vidfiles{c,2},['Analyzing Movement '...
            '(Frame ' num2str(curframe) '/' ...
            num2str(handles.vid.NumberOfFrames) ')...']});                  %Change the label to show the current frame.
        set(handles.slider,'value',curframe);                               %Set the slider position to show the video frame.
        drawnow;                                                            %Update the plot immediately.
    end
    fprintf(fid,'END PIXEL COUNTS\n');                                      %Print the pixel counts end label.
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
if temp > 4                                                                 %If the plot type is greater than 4...
    temp = 0;                                                               %Reset the plot type to zero.
elseif temp < 0                                                             %If the plot type is less than zero...
    temp = 4;                                                               %Set the plot type to 4.
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