function Offline_Radial_Arm_Tracker

global plot_type                                                            %Create a global variable to control the plot type.
global run                                                                  %Create a global variable to indicate when the analysis is running.

handles = Make_GUI;                                                         %Call the subfunction to make the GUI.

handles.min_pixels = 10;                                                    %Set the default minimum pixel size.
handles.max_speed = 100;                                                    %Set the maximum expected speed, in centimeters/s.
handles.vidfiles = {};                                                      %Create a field to hold the video filenames.
handles.scale = {};                                                         %Create a field to hold the pixel-to-centimeters scale.
handles.scale_line = {};                                                    %Create a field to hold the scale line handles.
handles.bounds = {};                                                        %Create a field to hold the experimental space boundaries.
handles.bounds_line = [];                                                   %Create a field to hold the boundary line handles.
handles.thresh = [];                                                        %Create a field to hold the threshold for each video.
handles.min_pixels = [];                                                    %Create a field to hold the minimum pixel size for each video.
handles.max_speed = 100;                                                    %Set the maximum expected speed, in centimeters/s.
temp = userpath;                                                            %Grab the Matlab UserPath.
i = find(temp == '\' | temp == '/');                                        %Find all forward or backward slashes in the UserPath.
handles.videos_dir = [temp(1:i(end-1)) 'Videos\'];                          %Set the default folder to save videos to.

plot_type = 0;                                                              %Set the plot type to zero.
run = 0;                                                                    %Set the run variable to zero.

set(handles.loadbutton,'callback',@SelectVideos);                           %Set the callback for the load video button.
set(handles.trackbutton,'callback',@AnalyzeVideos);                         %Set the callback for the tracking analysis button.
set(handles.slider,'callback',@SliderClick);                                %Set the callback for action on the slider.
set(handles.listbox,'callback',@ListClick);                                 %Set the callback for clicking on the listbox.
setKeyPressFcns(handles.fig,@KeyPress);                                     %Enable the KeyPress commands for adjusting the plot type.

handles.txt = Centered_Text('Load a video file to get started.',...
    handles.fontsize,handles.axes);                                         %Show a start message on the main axes.

guidata(handles.fig,handles);                                               %Pin the handles structure to the GUI.


%% This function executes when the user interacts with the slider.
function SliderClick(hObject,~)
handles = guidata(hObject);                                                 %Grab the handles structure from the main figure.
f = round(get(hObject,'value'));                                            %Set the current frame to the position indicated on the slider.
ShowFrame(handles,f);                                                       %Call the subfunction to show the frame.


%% This function displays the current frame of the video.
function ShowFrame(handles,f)
global plot_type                                                            %Create a global variable to control the plot type.
im = read(handles.vid,f);                                                   %Read in the current frame from the video object.
set(handles.thresh_txt,'string',...
    ['Threshold: ' num2str(handles.thresh(handles.curvid)) ' ']);           %Update the threshold label.
if plot_type == 0                                                           %If the plot type equals zero...
    set(handles.im,'cdata',im,'cdatamapping','direct');                     %Update the 'CData' property of the image to the new frame.
    return                                                                  %Skip execution of the rest of the function.
end
im = mean(double(im),3);                                                    %Calculate the grayscale image.
if ~isempty(handles.bounds{handles.curvid})                                 %If a boundary is set...
    a = size(im);                                                           %Grab the image size.
    bounds = handles.bounds{handles.curvid};                                %Grab any set boundary for this video.
    bounds = [min(bounds(:,1)),max(bounds(:,1)),...
        min(bounds(:,2)),max(bounds(:,2))];                                 %Find the edges of the boundary.
    bounds = round(bounds);                                                 %Round the boundary edges to the nearest pixel.
    bounds(bounds == 0) = 1;                                                %Set any zeros to ones.
    if bounds(2) > a(2)                                                     %If the right edge is larger than the image size...
        bounds(2) = a(2);                                                   %Set the right edge to the last pixel column.
    end
    if bounds(4) > a(1)                                                     %If the bottom edge is larger than the image size...
        bounds(4) = a(1);                                                   %Set the bottom edge to the last pixel row.
    end
    temp = im(bounds(3):bounds(4),bounds(1):bounds(2));                     %Grab only the image within the boundary.
else                                                                        %Otherwise...
    temp = im;                                                              %Grab the whole image.
end
im = double(im - min(temp(:)));                                             %Subtract the minimum from the image.
im = im/max(temp(:));                                                       %Normalize the image.
if plot_type == 1                                                           %If the plot_type == 1
    set(handles.im,'cdata',im,'cdatamapping','scaled');                     %Update the 'CData' property of the image to the new frame.
else                                                                        %Otherwise...
    im = (im < handles.thresh(handles.curvid));                             %Convert the  image to black and white using the current grayscale level.
    im = bwareaopen(im,handles.min_pixels(handles.curvid));                 %Remove small objects less than 10 pixels.
    set(handles.im,'cdata',im);                                             %Show the thresholded image.
    if any(im(:) > 0)                                                       %Update the 'CData' property of the image to show the difference.
        set(handles.im,'cdatamapping','scaled');                            %Set the 'cdatamapping' property to 'scaled'.
    else                                                                    %Otherwise..
        set(handles.im,'cdatamapping','direct');                            %Set the 'cdatamapping' property to 'direct'.
    end
end



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
if ~iscell(vidfile)                                                         %If the user only selected one video file...
    vidfile = {vidfile};                                                    %Convert the video file to a cell array.
end
temp = vidfile{1};                                                          %Grab the first selected video name.
for i = 1:length(vidfile)                                                   %Step through each selected video.
    handles.vidfiles(end+1,:) = {path, vidfile{i}};                         %Save the current video file name.
    handles.scale{end+1} = [];                                              %Create an entry to hold the pixels-to-centimeters scale.
    handles.scale_line{end+1} = [];                                         %Create a new entry to hold the scale line handles.
    handles.bounds{end+1} = [];                                             %Create an entry to hold the bounds of the monitored image.
    handles.bounds_line{end+1} = [];                                        %Create a new entry to hold the scale line handles.
    handles.thresh(end+1) = 0.5;                                            %Create a new entry to hold the threshold for this video.
    handles.min_pixels(end+1) = 10;                                         %Create a new entry to hold the minimimum pixel size for this video.
end
[~,i] = unique(handles.vidfiles(:,2));                                      %Find all unique videos.
handles.vidfiles = handles.vidfiles(i,:);                                   %Kick out any duplicates.
handles.scale = handles.scale(i);                                           %Kick out the duplicates' pixels-to-centimeters scale values.
handles.scale_line = handles.scale_line(i);                                 %Kick out the duplicates' scale line handles.
handles.bounds = handles.bounds(i);                                         %Kick out the duplicates' boundary values.
handles.bounds_line = handles.bounds_line(i);                               %Kick out the duplicates' boundary line handles.
handles.thresh = handles.thresh(i);                                         %Kick out the duplicates' thresholds.
handles.min_pixels = handles.min_pixels(i);                                 %Kick out the duplicates' minimum pixel sizes.
handles.curvid = find(strcmpi(handles.vidfiles(:,2),temp));                 %Set the current video index to the first selected file.
temp = handles.vidfiles(:,2);                                               %Grab all of the file names.
for i = 1:length(temp)                                                      %Step through each filename.
    if isempty(handles.scale{i})                                            %If the scale hasn't been set for any video.
        temp{i} = [temp{i} ' (scale not set)'];                             %Show that the scale isn't yet set next to the filename.
    end
end
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
text(min(get(handles.axes,'xlim')),min(get(handles.axes,'ylim')),...
    {' Left-click and drag to set the scale.',...
    ' Right-click and drag to set bounds.'},...
    'parent',handles.axes,'horizontalalignment','left',...
    'verticalalignment','top','fontsize',handles.fontsize,...
    'fontweight','bold','color','c');                                       %Create a top-left text object explaining how to calibrate the scale.
set(handles.axes,'dataaspectratio',[1 1 1]);                                %Square up the axes.
set(handles.axes,'xtick',[],'ytick',[],'box','on');                         %Remove any x- and y-tick labels.
if ~isempty(handles.scale{handles.curvid})                                  %If a scale line is established for this video...
    handles.scale_line{handles.curvid} = ...
        line(handles.scale{handles.curvid}(1:2),...
        handles.scale{handles.curvid}(3:4),...
        'color','y','linewidth',2,'marker','o','markerfacecolor','y');      %Create a scale line.
    x = get(handles.scale_line{handles.curvid},'xdata');                    %Grab the scale line's x-coordinates.
    y = get(handles.scale_line{handles.curvid},'ydata');                    %Grab the scale line's y-coordinates.
    handles.scale_line{handles.curvid}(2) = text(mean(x),mean(y),...
        [num2str(handles.scale{handles.curvid}(5)) ' cm'],'color','y',...
        'fontsize',handles.fontsize,'fontweight','bold',...
        'verticalalignment','bottom','horizontalalignment','center',...
        'rotation',-atand((y(2)-y(1))/(x(2)-x(1))));                        %Show the length of the line.
end
if ~isempty(handles.bounds{handles.curvid})                                 %If there are bounds around the experimental space...
	handles.bounds_line{handles.curvid} = ...
        line(handles.bounds{handles.curvid}(:,1),...
        handles.bounds{handles.curvid}(:,2),'color','r',...
        'linewidth',2);                                                     %Create a line showing the experimental space boundary..
end
handles.thresh_txt = text(max(get(handles.axes,'xlim')),...
    max(get(handles.axes,'ylim')),...
    ['Threshold: ' num2str(handles.thresh(handles.curvid)) ' '],...
    'parent',handles.axes,'horizontalalignment','right',...
    'verticalalignment','bottom','fontsize',handles.fontsize,...
    'fontweight','bold','color','c');                                       %Create a bottom right text object to display the current threshold.
set(handles.slider,'min',1,...
    'max',handles.vid.NumberOfFrames,...
    'value',1,...
    'enable','on');                                                         %Set the properties of the slider.
if run == 0                                                                 %If we're not currently running analysis...
    set([handles.trackbutton, handles.listbox, handles.slider],...
        'enable','on');                                                     %Enable the tracking analysis button.
end
set(handles.fig,'WindowButtonDownFcn',@MouseDown);                          %Set the MouseButtonDown function for the figure.
guidata(handles.fig,handles);                                               %Save the handles structure to the main figure.


%% This function is called when the user clicks anywhere on the figure during idle mode.
function MouseDown(hObject,~)
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
xy = get(handles.axes,'currentpoint');                                      %Grab the current x-y coordinates on the axes.
temp = [xlim(handles.axes), ylim(handles.axes)];                            %Grab the x- and y-axis limits of the axes.
if xy(1,1) > temp(1) && xy(1,1) < temp(2) && ...
        xy(1,2) > temp(3) && xy(1,2) < temp(4)                              %If the user clicked within the axes.
    if strcmpi(get(handles.fig,'SelectionType'),'normal')                   %If the user left-clicked on the figure...
        if any(ishandle(handles.scale_line{handles.curvid}))                %If there's any existing scale markers.
            delete(handles.scale_line{handles.curvid});                     %Delete any existing scale markers.
        end
        ln = line(xy(1,1),xy(1,2),'parent',handles.axes,...
            'color','y','linewidth',2,'marker','o','markerfacecolor','y');  %Create a scale line.
        set(handles.fig,'WindowButtonUpFcn',{@MouseUpScale,ln},...
            'WindowButtonMotionFcn',{@MouseMotionScale,handles.axes,ln});   %Set the mouse motion and mouse button up functions.
    else strcmpi(get(handles.fig,'SelectionType'),'alt')                    %Otherwise, if the user right-clicked on the figure...
        if any(ishandle(handles.bounds_line{handles.curvid}))               %If there's any existing boundary markers.
            delete(handles.bounds_line{handles.curvid});                    %Delete any existing boundary line.
        end
        ln = line(xy(1,1),xy(1,2),'parent',handles.axes,'color','r',...
            'linewidth',2);                                                 %Create a boundary line.
        set(handles.fig,'WindowButtonUpFcn',{@MouseUpBounds,ln},...
            'WindowButtonMotionFcn',{@MouseMotionBounds,handles.axes,ln});  %Set the mouse motion and mouse button up functions.
    end
end


%% This function is called while the user drags the mouse across the figure while setting the scale.
function MouseMotionScale(~,~,ax,ln)
xy = get(ax,'currentpoint');                                                %Grab the current location of the mouse pointer on the axes.
temp = [xlim(ax), ylim(ax)];                                                %Grab the x- and y-axis limits of the axes.
if xy(1,1) > temp(1) && xy(1,1) < temp(2) && ...
        xy(1,2) > temp(3) && xy(1,2) < temp(4)                              %If the user clicked within the axes.
    temp = get(ln,'xdata');                                                 %Grab the current x-coordinates of the line.
    xy(1,1) = temp(1);                                                      %Set the starting x-coordinate to the origin position.
    temp = get(ln,'ydata');                                                 %Grab the current y-coordinates of the line.
    xy(1,2) = temp(1);                                                      %Set the starting y-coordinate to the origin position.
    set(ln,'xdata',xy(:,1),'ydata',xy(:,2));                                %Update the coordinates of the line.
end


%% This function is called while the user drags the mouse across the figure while setting the boundary.
function MouseMotionBounds(~,~,ax,ln)
xy = get(ax,'currentpoint');                                                %Grab the current location of the mouse pointer on the axes.
temp = [xlim(ax), ylim(ax)];                                                %Grab the x- and y-axis limits of the axes.
if xy(1,1) > temp(1) && xy(1,1) < temp(2) && ...
        xy(1,2) > temp(3) && xy(1,2) < temp(4)                              %If the user clicked within the axes.
    xy = vertcat(zeros(2,2), xy(1,1:2), zeros(2,2));                        %Create a set of 5 coordinates.
    temp = get(ln,'xdata');                                                 %Grab the current x-coordinates of the line.
    xy([1:2,5],1) = temp(1);                                                %Set 2 corners to the  x-coordinate to the origin position.
    temp = get(ln,'ydata');                                                 %Grab the current y-coordinates of the line.
    xy([1,4:5],2) = temp(1);                                                %Set the starting y-coordinate to the origin position.
    xy(4,1) = xy(3,1);                                                      %Match the 4th corner's x-coordinate to the mouse position.
    xy(2,2) = xy(3,2);                                                      %Match the 2nd corner's y-coordinate to the mouse position.
    set(ln,'xdata',xy(:,1),'ydata',xy(:,2));                                %Update the coordinates of the line.
end


%% This function is called when the user releases the mouse button after dragging on the figure while setting the scale.
function MouseUpScale(hObject,~,ln)
set(hObject,'WindowButtonUpFcn',[],'WindowButtonMotionFcn',[]);             %Cancel the mouse motion and mouse button up functions.
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
handles.scale_line{handles.curvid} = ln;                                    %Save the line handle as the scale line.
val = inputdlg(['How long is the selected reference line, in '...
    'centimeters?'],'Set Scale');                                           %Ask the user how long the reference line is, in centimeters.
if isempty(val)                                                             %If the user didn't enter a length...
    delete(handles.scale_line{handles.curvid});                             %Delete the scale markers.
    return;                                                                 %Skip execution of the rest of the function.
end
val = str2double(val{1});                                                   %Convert the entered string to a number.
x = get(handles.scale_line{handles.curvid},'xdata');                        %Grab the scale line's x-coordinates.
y = get(handles.scale_line{handles.curvid},'ydata');                        %Grab the scale line's y-coordinates.
handles.scale_line{handles.curvid}(2) = text(mean(x),mean(y),...
    [num2str(val) ' cm'],'color','y','fontsize',handles.fontsize,...
    'fontweight','bold','verticalalignment','bottom',...
    'horizontalalignment','center',...
    'rotation',-atand((y(2)-y(1))/(x(2)-x(1))));                            %Show the length of the line.
handles.scale{handles.curvid} = [x,y,val];                                  %Save the scale values.
temp = handles.vidfiles(:,2);                                               %Grab all of the file names.
for i = 1:length(temp)                                                      %Step through each filename.
    if isempty(handles.scale{i})                                            %If the scale hasn't been set for any video.
        temp{i} = [temp{i} ' (scale not set)'];                             %Show that the scale isn't yet set next to the filename.
    end
end
set(handles.listbox,'string',temp,'value',handles.curvid);                  %Show the currently loaded videos in the listbox.
objs = get(handles.axes,'children');                                        %Grab all children of the axes.
objs(~strcmpi(get(objs,'type'),'text')) = [];                               %Kick out all non-text objects.
uistack(objs,'top');                                                        %Move all text objects to the top layer.
guidata(handles.fig,handles);                                               %Save the handles structure to the main figure.


%% This function is called when the user releases the mouse button after dragging on the figure while setting the boundary.
function MouseUpBounds(hObject,~,ln)
set(hObject,'WindowButtonUpFcn',[],'WindowButtonMotionFcn',[]);             %Cancel the mouse motion and mouse button up functions.
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
x = get(ln,'xdata');                                                        %Grab the boundary line's x-coordinates.
y = get(ln,'ydata');                                                        %Grab the boundary line's y-coordinates.
if length(x) < 5 || x(1) == x(3) || y(1) == y(3)                            %If the user didn't select a rectangle...
    delete(ln);                                                             %Delete the boundary line.
    handles.bounds{handles.curvid} = [];                                    %Kick out any existing boundary for this video.
    handles.bounds_line{handles.curvid} = [];                               %Kick out any existing boundary line handle.
else                                                                        %Otherwise...
	handles.bounds_line{handles.curvid} = ln;                               %Save the line handle as the boundary line.
    handles.bounds{handles.curvid} = [x; y]';                               %Save the boundary corners.
end
objs = get(handles.axes,'children');                                        %Grab all children of the axes.
objs(~strcmpi(get(objs,'type'),'text')) = [];                               %Kick out all non-text objects.
uistack(objs,'top');                                                        %Move all text objects to the top layer.
guidata(handles.fig,handles);                                               %Save the handles structure to the main figure.


%% This function is called when the user clicks on the sync video button.
function AnalyzeVideos(hObject,~)
global plot_type                                                            %Create a global variable to control the plot type.
global run                                                                  %Create a global variable to indicate when the analysis is running.
if run == 1                                                                 %If the analysis is currently running.
    run = 0;                                                                %Set the run variable to zero.
    return                                                                  %Skip execution of the rest of the function.
end
plot_type = 0;                                                              %Set the plot type to zero.
run = 1;                                                                    %Set the run variable to one to indicate analysis is happening.
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
for i = 1:size(handles.vidfiles,1)                                          %Step through each video.
    if isempty(handles.scale{i})                                            %If the scale hasn't been set for any video.
        warndlg(['You must first set a length reference for all the '...
            'videos!'],'Set Scales First!');                                %Show a warning dialog.
        return                                                              %Skip execution of the rest of the function.
    end
end
prompt = {['Minimum distance (centimeters) the rat/mouse must move '...
    'between recorded points (set to zero to record every frame):'],...
    'Maximum allowable speed (centimeters/second):'};                       %Create prompts for the user to enter values.
dlg_title = 'Set Tracking Properties';                                      %Set the dialog title for the following input dialog box.
num_lines = 1;                                                              %Set the number of lines to return for each question.
def = {'0.5',num2str(handles.max_speed)};                                   %Set the default answers.
temp = inputdlg(prompt,dlg_title,num_lines,def);                            %Have the user set the dimensions with an input dialog box.
if isempty(temp)                                                            %If the user pressed cancel...
    return;                                                                 %Skip execution of the rest of the function.
end
for i = 1:length(temp)                                                      %Step through each value.
    temp{1}(temp{1} < 46 |temp{1} > 57) = [];                               %Kick out all non-number characters.
end
if str2double(temp(2)) <= 0                                                 %If all of the entered values aren't positive numbers...
    warndlg('The maximum speed must be positive, non-zero number!',...
        'Invalid Value!');                                                  %Show a warning that not all values are valid.
    return                                                                  %Skip execution of the rest of the function.
end
min_dist = str2double(temp{1});                                             %Convert the entered string to a number.
handles.max_speed = str2double(temp{2});                                    %Grab the user-set maximum speed.
set(handles.trackbutton,'string','Stop Analysis');                          %Change the string on the start analysis button.
set([handles.loadbutton,handles.listbox,handles.slider],'enable','off');    %Disable the other uicontrols.
for c = 1:size(handles.vidfiles,1)                                          %Step through each video.
    handles.curvid = c;                                                     %Set the current video index to that selected.
    set(handles.listbox,'value',c);                                         %Show which video is currently being analyzed in the listbox.
    handles = LoadVideo(handles,1);                                         %Load the currently selected video for viewing.
    set(handles.fig,'WindowButtonDownFcn',[]);                              %Turn off the MouseButtonDown function for the figure.
    set(handles.slider,'enable','off');                                     %Disable the slider.
    delete(handles.scale_line{c});                                          %Delete any existing scale markers.
    delete(handles.bounds_line{c});                                         %Delete any existing boundary line.
    objs = get(handles.axes,'children');                                    %Grab all children of the main axes.
    delete(objs(strcmpi(get(objs,'type'),'text')));                         %Delete any text objects.  
    scale = euclid_dist(handles.scale{c}([1,3]),...
        handles.scale{c}([2,4]))/handles.scale{c}(5);                       %Calculate the pixels-to-centimeters scale.
        
    %Check to see if the user set bounds.
    im = read(handles.vid,1);                                               %Read in the first frame from the video object.    
    a = size(im);                                                           %Grab the image size.
    bounds = handles.bounds{c};                                             %Grab any set boundary for this video.
    if ~isempty(bounds)                                                     %If a boundary was set for this video..
        bounds = [min(bounds(:,1)),max(bounds(:,1)),...
            min(bounds(:,2)),max(bounds(:,2))];                             %Find the edges of the boundary.
        bounds = round(bounds);                                             %Round the boundary edges to the nearest pixel.
        bounds(bounds == 0) = 1;                                            %Set any zeros to ones.
        if bounds(2) > a(2)                                                 %If the right edge is larger than the image size...
            bounds(2) = a(2);                                               %Set the right edge to the last pixel column.
        end
        if bounds(4) > a(1)                                                 %If the bottom edge is larger than the image size...
            bounds(4) = a(1);                                               %Set the bottom edge to the last pixel row.
        end
    else                                                                    %Otherwise, if no boundary was set...
        bounds = [1,1,a([2,1])];                                            %Set the boundaries to the perimeter of the entire image.
    end
   
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
    fprintf(fid,'%1.4f\n',scale);                                           %Write the pixels/centimeters scale.
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
    fprintf(fid,'%s\t','X_POSITION_(cm)');                                  %Write a label for the animal's centroid x-coordinates.
    fprintf(fid,'%s\t','Y_POSITION_(cm)');                                  %Write a label for the animal's centroid y-coordinates.
    fprintf(fid,'%s\t','ORIENTATION_(degrees)');                            %Write a label for the animal's orientation.
    fprintf(fid,'%s\n','LENGTH_(cm)');                                      %Write a label for the animal's length.
    
    %Track the rat through the whole video file.
    txt = Centered_Text({handles.vidfiles{c,2},['Tracing Path '...
        '(Frame 1/' num2str(handles.vid.NumberOfFrames) ')...']},...
        0.75*handles.fontsize,handles.axes);                                %Show a start message on the main axes.
    set(txt,'position',[min(xlim) + 0.05*range(xlim),...
        min(ylim) + 0.05*range(ylim)],'horizontalalignment','left',...
        'verticalalignment','top');                                         %Move the text to the upper left corner.
    curframe = 0;                                                           %Set the current frame to 1.
    prev_pos = [-Inf,-Inf];                                                 %Set the previous position to infinite to make sure the first frame is written.
    plotpath = nan(500,2);                                                  %Create a matrix to show the last 500 datapoints of the rat's path.
    plot_obj = zeros(1,4);                                                  %Create a matrix to hold plot objects.
    circ_size = min_dist*scale;                                             %Set the size of the minimum distance circle.
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
        if plot_type == 0                                                   %If the plot type is zero...
            set(handles.im,'cdata',im,'cdatamapping','direct');             %Update the 'CData' property of the image to show the original image.
        end
        im = mean(im,3);                                                    %Convert the image to a 16-bit integer for analysis.
        temp = im(bounds(3):bounds(4),bounds(1):bounds(2));                 %Grab only the image within the boundary.
        im = double(im - min(temp(:)));                                     %Subtract the minimum from the image.
        im = im/max(temp(:));                                               %Normalize the image.
        if plot_type == 1                                                   %If the plot type is one...
            set(handles.im,'cdata',im,'cdatamapping','scaled');             %Update the 'CData' property of the image to show the normalized image.
        end
        im = (im < handles.thresh(handles.curvid));                         %Convert the  image to black and white using the current grayscale level.
        im = bwareaopen(im,handles.min_pixels(handles.curvid));             %Remove small objects less than 10 pixels.
        if plot_type == 2                                                   %If the plot type is three...
            set(handles.im,'cdata',im,'cdatamapping','scaled');             %Update the 'CData' property of the image to show the filtered, thresholded image.
        end
        objs = regionprops(im,'Centroid','Area','Orientation',...
            'MajorAxisLength','BoundingBox');                               %Find the centroid and area for each object.
        if ~isempty(objs)                                                   %If any objects are detected...
            temp = vertcat(objs.BoundingBox);                               %Concatenate all of the object bounding boxes into one matrix.
            temp(:,3:4) = temp(:,1:2) + temp(:,3:4);                        %Calculate the top and right edges of the bounding boxes.
            a = (temp(:,1) < bounds(1) | temp(:,3) > bounds(2) |...
                temp(:,2) < bounds(3) | temp(:,4) > bounds(4));             %Find all objects outside of the cage borders.
            objs(a) = [];                                                   %Kick out all of the objects outside of the cage borders.
        end
        if ~isempty(objs)                                                   %If any objects are detected...
            [~,j] = sort([objs.Area],'descend');                            %Sort the found objects by descending area.
            objs = objs(j);                                                 %Resort the objects in the stats structure.
            xy = objs(1).Centroid;                                          %Grab the x- and y-coordinates of the animal centroid.
            rot = objs(1).Orientation;                                      %Grab the long-axis orientation of the animal.
            len = objs(1).MajorAxisLength;                                  %Grab the length of the long-axis of the animal.
            d = euclid_dist(xy,prev_pos);                                   %Calculate the Euclidean distance to the previous centroid.
            s = handles.vid.FrameRate*d/scale;                              %Calculate the frame-to-frame speed of the rat.
            if prev_pos(1) < 0                                              %If there is no previous position...
                s = 0;                                                      %Set the speed to zero.
            end
            if d > min_dist*scale && s < handles.max_speed                  %If the rat has moved more than the minimum distance from their previous centroid...
                fprintf(fid,'%1.3f\t',...
                    (curframe-1)/handles.vid.FrameRate);                    %Write the sample time, in seconds.
                fprintf(fid,'%1.2f\t',xy(1)/scale);                         %Write the x coordinate, in centimeters.
                fprintf(fid,'%1.2f\t',xy(2)/scale);                         %Write the y coordinate, in centimeters.
                fprintf(fid,'%1.2f\t',rot);                                 %Write the orientation, in degress.
                fprintf(fid,'%1.2f\n',len/scale);                           %Write the major axis length, in centimeters.  
                fprintf(1,'%1.3f\t',...
                    (curframe-1)/handles.vid.FrameRate);                    %Write the sample time to the command line, in seconds.
                fprintf(1,'%1.2f\t',xy(1)/scale);                           %Write the x coordinate to the command line, in centimeters.
                fprintf(1,'%1.2f\t',xy(2)/scale);                           %Write the y coordinate to the command line, in centimeters.
                fprintf(1,'%1.2f\t',rot);                                   %Write the orientation to the command line, in degress.
                fprintf(1,'%1.2f\n',len/scale);                             %Write the major axis length to the command line, in centimeters.
                prev_pos = xy;                                              %Save the new centroid location as the previous location.
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
set(handles.fig,'WindowButtonDownFcn',@MouseDown);                          %Re-set the MouseButtonDown function for the figure.
run = 0;                                                                    %Set the run variable to zero to indicate idle mode.
guidata(handles.fig,handles);                                               %Save the handles structure to the main figure.


%% This function is called when the user presses a key while the main figure during analysis mode focus.
function KeyPress(hObject,eventdata)
global plot_type                                                            %Create a global variable to control the plot type.
global run                                                                  %Create a global variable to indicate when the analysis is running.
temp = plot_type;                                                           %Grab the current plot type and save the value to a temporary variable.
if strcmpi(eventdata.Key,'space')                                           %If the user pressed the spacebar...
    temp = temp + 1;                                                        %Increment the plot type variable.
end
if temp > 2                                                                 %If the plot type is greater than 2...
    temp = 0;                                                               %Reset the plot type to zero.
end
plot_type = temp;                                                           %Set the plot type to the temporary matrix.
if run == 0                                                                 %If the program is in idle mode...
    handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
    if strcmpi(eventdata.Key,'uparrow')                                     %If the user pressed down arrow...
        handles.thresh(handles.curvid) = ...
            handles.thresh(handles.curvid) + 0.01;                          %Add 0.01 to the current threshold.
    elseif strcmpi(eventdata.Key,'downarrow')                               %If the user pressed the up arrow...
        handles.thresh(handles.curvid) = ...
            handles.thresh(handles.curvid) - 0.01;                          %Subtract 0.01 from the current threshold.
    elseif strcmpi(eventdata.Key,'rightarrow')                              %If the user pressed the right arrow...
        handles.min_pixels(handles.curvid) = ...
            handles.min_pixels(handles.curvid) + 1;                         %Add 1 pixel to the current minimum object size.
    elseif strcmpi(eventdata.Key,'leftarrow')                               %If the user pressed the left arrow...
        handles.min_pixels(handles.curvid) = ...
            handles.min_pixels(handles.curvid) - 1;                         %Subtract 1 pixel from the current minimum object size.
    end
    if handles.min_pixels(handles.curvid) < 0                               %If the minimum object size is less than zero...
        handles.min_pixels(handles.curvid) = 1;                             %Set the minimum object size to one.
    elseif handles.min_pixels(handles.curvid) > 200                         %If the minimum object size is greater than 200...
        handles.min_pixels(handles.curvid) = 200;                           %Set the minimum object size to 200.
    end
    if handles.thresh(handles.curvid) <= 0                                  %If the threshold is less than or equal to zero...
        handles.thresh(handles.curvid) = 0.01;                              %Set the threshold size to 0.01.
    elseif handles.thresh(handles.curvid) >= 1                              %If the threshold is greater than or equal to 1...
        handles.thresh(handles.curvid) = 0.99;                              %Set the threshold to 0.99.
    end
    guidata(handles.fig,handles);                                           %Save the handles structure to the main figure.
    f = round(get(handles.slider,'value'));                                 %Grab the current frame indicated on the slider.
    ShowFrame(handles,f);                                                   %Show the current frame with the indicated plot type.
end



%% This subfunction creates the GUI.
function handles = Make_GUI
set(0,'units','centimeters');                                               %Set the system units to centimeters.
pos = get(0,'screensize');                                                  %Grab the screen size.
handles.fontsize = 10;                                                      %Set the font scaling factor based on the figure size.
handles.fig = figure('MenuBar','none',...
    'numbertitle','off',...
    'name','Offline AMTS Analysis',...
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
set(handles.fig,'ResizeFcn',@Resize);                                       %Set the resize function for the main figure.
pos(1:2) = pos(3:4)/2;                                                      %Calculate the middle of the screen.
pos(4) = 0.9*pos(4);                                                        %Calculate a maximal height for the GUI.
pos(3) = (16.2/12.9)*pos(4);                                                %Scale the width to the height.
pos(1:2) = pos(1:2) - pos(3:4)/2;                                           %Adjust the left and bottom edges to center the GUI.
set(handles.fig,'position',pos);                                            %Reset the GUI's position.


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
objs(~strcmpi(get(objs,'type'),'text')) = [];                               %Kick out all non-text objects.
for i = 1:length(objs)                                                      %Step through each object.
    set(objs(i),'fontsize',ratio*get(objs(i),'fontsize'));                  %Scale the font size accordingly.
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


%% This function sets the KeyPress function for all chilren of a figure to the same function.
function setKeyPressFcns(hObject,fcn)
set(hObject,'KeyPressFcn',fcn);                                             %Set the KeyPress function for the main figure.
c = get(hObject,'children');                                                %Grab all of the children of the main figure.
i = 0;                                                                      %Create a counter to step through the uicontrols.
while i < length(c)                                                         %Loop until we've set the KeyPress function for all children.
    i = i + 1;                                                              %Increment the counter.
    if strcmpi(get(c(i),'type'),'uicontrol')                                %If the child is a uicontrol...
        set(c(i),'KeyPressFcn',fcn);                                        %Set the KeyPress function for all uicontrols.
    else                                                                    %Otherwise, if the child isn't a uicontrol...
        c = [c; get(c(i),'children')];                                      %Add the children of this object to the list to check.
    end
end