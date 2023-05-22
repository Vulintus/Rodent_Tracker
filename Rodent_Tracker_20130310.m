function Rodent_Tracker

handles = Make_GUI;                                                         %Call the subfunction to make the GUI.

%Show the user that the webcam is being initialized.
set(handles.mainfig,'currentaxes',handles.axes);                            %Set the current axes to the left-hand axes.
txt = Centered_Text(handles.axes,'Initializing webcam...',20,'w');          %Display a message that the webcam is being initialized.

%Initialize some variables and paths here where they'll be easier to find and change.
if isdeployed                                                               %If the program is running as a deployed application...
    handles.datapath = [pwd '\Session Records\'];                           %Specify a default subfolder or holding session data files.
    progpath = pwd;                                                         %Save the current path.
else                                                                        %Otherwise, if the program is running from Matlab...
    progpath = which('Rodent_Tracker');                                     %Grab the full path of the program.
    progpath(find(progpath == '\',1,'last')+1:end) = [];                    %Kick out the *.m file name from the path.   
    handles.datapath = [progpath 'Session Records\'];                       %Specify a default subfolder or holding session data files.
end
[~, local] = system('hostname');                                            %Grab the local computer name.
local(local < 33) = [];                                                     %Kick out any spaces and carriage returns from the computer name.
handles.min_dist = 1;                                                       %Specify the minimum distance, in centimeters, that the animal's centroid must move to be counted.
handles.tcolor = [];                                                        %Create a field for keeping track of the tracking color.
handles.cage_margin = 0.05;                                                 %Set the cage border margin for ignoring centroids.
run = [0, 2, NaN];                                                          %Set the run variable, the default image type, and the grayscale threshold.

%Connect to the webcam.
temp = dir([progpath '*_cal.32']);                                          %Check for calibration files in the current directory.
if ~isempty(temp)                                                           %If any calibration files were found.
    [~,i] = sort([temp(:).datenum],'descend');                              %Sort the calibration files in descending modification date.
    if ~isempty(i)                                                          %If the date numbers could be sorted...
        temp = temp(i);                                                     %Resort the files by modification date.
    end
    temp = temp(1).name;                                                    %Grab the most recent calibration file.
else                                                                        %Otherwise, if no calibration files were found.
    temp = [];                                                              %Set the calibration file name to an empty matrix.
end
handles.vid = Camera_Setup(temp);                                           %Create a video input object with the Camera_Setup function.
if isempty(handles.vid)                                                     %If no camera was connected...
    errordlg(['Could not connect to a camera! Check the camera '...
        'connections and restart this program.'],...
        'Camera Connection Error!');                                        %Show an error dialog box.
    close(handles.mainfig);                                                 %Close the main figure.
    return                                                                  %Skip execution of the rest of the function.
end
frame = getsnapshot(handles.vid);                                           %Grab a single frame from the video feed.
delete(txt);                                                                %Delete the "Initializing webcam..." text object.
prev_im = image(frame,'parent',handles.axes);                               %Show that frame in the left-hand axes.
set(handles.axes,'visible','off','DataAspectRatio',[1,1,1]);                %Make the axes invisible and square up the axes.
handles.prev = preview(handles.vid,prev_im);                                %Convert the image in the GUI axes to a live feed.

%Load the calibration file, if it exists.
handles.cal_file = [progpath '\' local '-' handles.vid.name '_cal.32'];     %Create the expected calibration filename for this video input.
if exist(handles.cal_file,'file')                                           %If a calibration file already exists...
    [handles.corners, handles.width, handles.height] = ...
        Load_Calibration(handles.cal_file);                                 %Load the calibration data from the calibration file.
    set(handles.startbutton,'enable','on');                                 %Enable the start/stop button.
    handles.bounds = rectangle('parent',handles.axes,...
        'position',handles.corners,...
        'edgecolor','r',...
        'linewidth',2,...
        'facecolor','none');                                                %Create a rectangle to show the cage boundaries.
    c = handles.corners;                                                    %Copy the cage corner corner locations into an easier-to-work-with matrix.
    m = handles.cage_margin;                                                %Copy the cage border margin into an easier-to-work-with matrix.
    handles.cage_border = [c(1)-m*c(3),c(2)-m*c(4),...
        c(1)+(1+m)*c(3),c(2)+(1+m)*c(4)];                                   %Set the cage border for ignoring erroneous centroids.
else                                                                        %Otherwise, if a calibration file doesn't already exist...
    handles.corners = [];                                                   %Create an empty field to hold the corner coordinates.
    handles.cage_border = [];                                               %Create an empty field to hold the cage border coordinates.
    handles.bounds = [];                                                    %Create an empty field to hold a bounding rectangle handle.
end

%Set the callbacks for the start/stop button and KeyPress events.            
set(handles.startbutton,'callback',@StartStop);                             %Set the callback for the start/stop button.
set(handles.calbutton,'callback',@Calibrate,'enable','on');                 %Set the callback for the calibrate button.
set(handles.threshbutton,'callback',@SetThreshold,'enable','on');           %Set the callback for the threshold button.

set(handles.mainfig,'userdata',run);                                        %Save the loop variables on the main GUI's UserData property.
guidata(handles.mainfig,handles);                                           %Pin the handles structure to the main figure.


%% This function is the main tracking loop.
function handles = Tracking_Loop(handles,save_option)

%Ask the user which color they'd like to track.
if isempty(handles.tcolor)                                                  %If the user hasn't yet specified a color...
    handles.tcolor = questdlg('Which color do you want to track?',...
        'Tracking Color','Green','White','Black','Green');                  %Ask the user to pick a color.
end

%Ask the user how long they'd like to track the rat.
if save_option == 1                                                         %If we're saving this data...
    temp = inputdlg('How long do you want to track, in minutes?',...
        'Session Time',1,{'60'});                                           %Ask the user how long they want to track the rodent.
    if isempty(temp)                                                        %If the user didn't enter any number of minutes...
        return                                                              %Skip execution of the rest of the function.
    end
    stop_time = str2double(temp{1});                                        %Convert the entered session time to a number.
else                                                                        %Otherwise, if we're not saving this data...
    stop_time = Inf;                                                        %Set the loop to run until stopped.
end

start_time = now;                                                           %Grab the current serial date number to save the session start time.
stop_time = start_time + stop_time/1440;                                    %Find the session stop time, in units of days.
total_dist = 0;                                                             %Keep track of the total distance the rodent moved.

%Write the header for the data file.
if save_option == 1                                                         %If we're saving this data...
    fid = fopen(handles.filename,'wt');                                     %Open a new text file to recieve tracking information.
    fprintf(fid,'%s ','SUBJECT:');                                          %Write a label for the subject's name.
    fprintf(fid,'%s\n',handles.rat);                                        %Write the subject's name.
    fprintf(fid,'%s ','DATE:');                                             %Write a label for the date.
    fprintf(fid,'%s\n\n',datestr(start_time,1));                            %Write the session date.
    fprintf(fid,'%s ','START TIME:');                                       %Write a label for the start time.
    fprintf(fid,'%s\n\n',datestr(start_time,13));                           %Write the start time.
    fprintf(fid,'%s ','TIME_(s):');                                         %Write a label for the start time.
    fprintf(fid,'%s\t','X_POSITION_(cm)');                                  %Write a label for the x-coordinates.
    fprintf(fid,'%s\n','Y_POSITION_(cm)');                                  %Write a label for the y-coordinates.
end

scale = mean([handles.corners(3)/handles.width,...
    handles.corners(4)/handles.height]);                                    %Calculate the average inches-to-pixels scale.
circ_size = handles.min_dist*scale;                                         %Set the size of the minimum distance circle.
circle_pts = circ_size*[cos(0:pi/100:2*pi)', sin(0:pi/100:2*pi)'];          %Create points for drawing circles.

%Set the properties of the video input object.
delete(handles.prev);                                                       %Delete the video preview object.
delete(handles.bounds);                                                     %Delete the bounding rectangle.
handles.vid.FramesPerTrigger = 1;                                           %Set the number of frames grabbed per trigger.
handles.vid.TriggerRepeat = Inf;                                            %Allow an infinite number of triggers.
handles.vid.FrameGrabInterval = 1;                                          %Grab every frame from the video feed, skipping none.
triggerconfig(handles.vid, 'manual');                                       %Set the trigger type to manual.

%Initialize variables for the main loop.
run = get(handles.mainfig,'userdata');                                      %Grab the run variable from the UserData property on the main GUI.
tc = 86400;                                                                 %Use this constant to convert timestamps to seconds.
path = nan(500,2);                                                          %Create a matrix to hold the last 500 unique rat positions.
prev_pos = [Inf,Inf];                                                       %Keep track of the previous position.     
setKeyPressFcns(handles.mainfig,{@KeyPress,handles.mainfig});               %Enable the KeyPress commands for adjusting the threshold.
plot_obj = nan(1,4);                                                        %Create a variable to hold the plot object handles.
frame_rate = nan(20,1);                                                     %Keep track of the framerate over the last 20 frames.

%Create the initial image object.
start(handles.vid);                                                         %Start buffering on the video input.
trigger(handles.vid);                                                       %Trigger video capture on the video input.
im = getdata(handles.vid);                                                  %Grab the captured frame.
axes(handles.axes);                                                         %Force focus onto the main GUI axes.
im_obj = imshow(im);                                                        %Show the initial color image.
rectangle('parent',handles.axes,...
    'position',handles.corners,...
    'edgecolor','r',...
    'linewidth',1,...
    'facecolor','none');                                                    %Create a rectangle to show the cage boundaries.


%Main Loop ****************************************************************************************************************************************************************************************
while run(1) ~= 0 && stop_time > now                                        %Loop until the run variable is set to zero.
    run = get(handles.mainfig,'userdata');                                  %Grab the run variable from the UserData property on the main GUI.
    trigger(handles.vid);                                                   %Trigger video capture on the video input.
    [im, ~, metadata] = getdata(handles.vid);                               %Grab the captured frame.
    frame_rate(1:end-1) = frame_rate(2:end);                                %Shift the values down one in the frame rate tracker.
    frame_rate(end) = (datenum(metadata.AbsTime)-start_time)*tc;            %Save the current frame time.
    if run(2) == 1                                                          %If the current plot type is just the color image.
    	set(im_obj,'cdata',im,'cdatamapping','direct');                     %Show the current color image.
        if ishandle(plot_obj(1))                                            %If the previous position circle is shown...
            set(plot_obj(1),'color','y');                                   %Color the circle yellow.
        end
    end
    if handles.tcolor(1) == 'G'                                             %If we're tracking a green object...
        im = imsubtract(im(:,:,2),rgb2gray(im));                            %Subtract the white level from the green component.                              
    elseif handles.tcolor(1) == 'B'                                         %If we're tracking a white object...
        im = imcomplement(im);                                              %Find the complement image.
    end
    if isnan(run(3))                                                        %If the grayscale threshold hasn't yet been set...
        run(3) = graythresh(im);                                            %Calculate an appropriate grayscale threshold.
        set(handles.mainfig,'UserData',run);                                %Save the plot type and the gray threshold to the axes' "UserData" property.
    end
    im = im2bw(im,run(3));                                                  %Convert the  image to black and white using that grayscale level.
    im = medfilt2(im,[10 10]);                                              %Filter the image to remove noise pixels.
    im = bwareaopen(im,10);                                                 %Remove small objects less than 10 pixels.
    if run(2) == 2                                                          %If the current plot type is the b&w blob image.
        if ~all(im(:) == 0) && ~all(im(:) == 1)                             %If there's variation in the image...
            set(im_obj,'cdata',im,'cdatamapping','scaled');                 %Show the current b&w blob image.
        else                                                                %Otherwise, if there's no variation in the image...
            set(im_obj,'cdata',255*im,'cdatamapping','direct');             %Show the current b&w blob image.
        end
        if ishandle(plot_obj(1))                                            %If the previous position circle is shown...
            set(plot_obj(1),'color','g');                                   %Color the circle green.
        end
    end
    data = regionprops(im,'BoundingBox','Centroid','Area','Orientation');   %Calculate a bounding box and the centroid for each object.
    temp = vertcat(data.Centroid);                                          %Concatenate all of the object centroids into one matrix.
    if ~isempty(data)                                                       %If there's any objects...
        a = (temp(:,1) < handles.cage_border(1) |...
            temp(:,1) > handles.cage_border(3) |...
            temp(:,2) < handles.cage_border(2) |...
            temp(:,2) > handles.cage_border(4));                            %Find all objects outside of the cage borders.
        data(a) = [];                                                       %Kick out all of the objects outside of the cage borders.
    end
    if ~isempty(data)                                                       %If any objects are left inside the cage...
        [~,j] = sort([data.Area],'descend');                                %Sort the found objects by descending area.
        data = data(j);                                                     %Resort the objects in the stats structure.
        xy = data(1).Centroid;                                              %Find the x- and y-coordinates of the animal centroid.
        temp = euclid_dist(xy,prev_pos);                                    %Calculate the Euclidean distance to the previous centroid.
        if temp > handles.min_dist*scale                                    %If the rat has moved more than the minimum distance from their previous centroid...
            if any(isnan(path(:)))                                          %If there's any NaNs left in the path buffer...
                i = find(isnan(path(:,1)),1,'first');                       %Find the first NaN row in the buffer.
                path(i,:) = xy;                                             %Put the new centroid location at the first free row in the buffer.
            else                                                            %Otherwise, if the path buffer is full...
                path(1:end-1,:) = path(2:end,:);                            %Shift all of the path points down one.
                path(end,:) = xy;                                           %Put the new centroid location at the end of the buffer.
            end
            total_dist = total_dist + temp;                                 %Add the distance moved to the total distance.
            if save_option == 1                                             %If we're saving this data...
                fprintf(fid,'%1.3f\t',...
                    (datenum(metadata.AbsTime)-start_time)*tc);             %Write the sample time, in seconds.
                fprintf(fid,'%1.2f\t',(xy(1)-handles.corners(1))/scale);    %Write the x coordinate, in centimeters.
                fprintf(fid,'%1.2f\n',(xy(2)-handles.corners(2))/scale);    %Write the y coordinate, in centimeters.
            end
            prev_pos = xy;                                                  %Save the new centroid location as the previous location.
        end                        
    end
    hold on;                                                                %Hold the axes for overlaying plots.
    if ~all(isnan(path(:)))                                                 %If there's any non-NaN points in the path buffer...
        target_cir(:,1) = circle_pts(:,1) + prev_pos(1);                    %Locate a movement-threshold circle's x-coordinates relative to the previous position.
        target_cir(:,2) = circle_pts(:,2) + prev_pos(2);                    %Locate a movement-threshold circle's x-coordinates relative to the previous position.
        if ~ishandle(plot_obj(1))                                           %If the plot objects haven't yet been created...
            plot_obj(1) = line(target_cir(:,1),target_cir(:,2),...
                'color','y','linewidth',2);                                 %Draw a circle around the previous position showing the movement threshold.
            plot_obj(2:3) = plot(xy(1),xy(2),'mo',...
                path(:,1),path(:,2),'m:',...
                'linewidth',2);                                             %Mark the centroid of the current object and draw it's historical path.
        else                                                                %Otherwise, if the plot objects already exist...
            set(plot_obj(1),'xdata',target_cir(:,1),...
                'ydata',target_cir(:,2));                                   %Update the position of the previous position circle.
            set(plot_obj(2),'xdata',xy(1),'ydata',xy(2));                   %Update the position of the rodent centroid.
            set(plot_obj(3),'xdata',path(:,1),'ydata',path(:,2));           %Update the rodent path.
        end
        drawnow;                                                            %Update the plot immediately.
    end
    if save_option == 1                                                     %If we're saving this data...
        if ~ishandle(plot_obj(4))                                           %If the timer text object hasn't yet been created...
            plot_obj(4) = text(0.02*max(xlim),0.02*max(ylim),...
                [datestr(now-start_time,'HH:MM:SS') ' (Framerate: ' ...
                num2str(1/nanmean(diff(frame_rate)),'%1.0f') ' fps)'],...
                'horizontalalignment','left','verticalalignment','top',...
                'margin',3,'edgecolor','k','backgroundcolor','w',...
                'fontsize',12);                                             %Show the session time as a text object.
        else                                                                %Otherwise, if the timer text object already exists.
            set(plot_obj(4),'string',...
                [datestr(now-start_time,'HH:MM:SS') ' (Framerate: ' ...
                num2str(1/nanmean(diff(frame_rate)),'%1.0f') ' fps)']);     %Update the string of the timer text object.
        end
    end
    hold off;                                                               %Release the plot hold.
end
set(handles.mainfig,'KeyPressFcn',[]);                                      %Set the KeyPress function for the main figure to nothing.      
if save_option == 1                                                         %If we're saving this data...
    fclose(fid);                                                            %Close the data file.
    temp = quick_track(handles.filename);                                   %Make a figure with the results from this session.
    if ishandle(temp)                                                       %If the figure is still open...
        saveas(temp,handles.filename(1:end-4),'png');                       %Save the figure as a PNG image.
    end
end

%Reset the webcam preview.
stop(handles.vid);                                                          %Stop acquisition through the video input.
flushdata(handles.vid);                                                     %Flush the memory buffer on the video input.
set(0,'currentfigure',handles.mainfig);                                     %Set focus to the main figure.
set(handles.mainfig,'currentaxes',handles.axes);                            %Set the current axes to the left-hand axes.
frame = getsnapshot(handles.vid);                                           %Grab a single frame from the video feed.
prev_im = image(frame);                                                     %Show that frame in the left-hand axes.
axis equal;                                                                 %Square up the axes.
set(handles.axes,'visible','off');                                          %Make the axes invisible.
handles.prev = preview(handles.vid,prev_im);                                %Convert the image in the GUI axes to a live feed.
handles.bounds = rectangle('parent',handles.axes,...
    'position',handles.corners,...
    'edgecolor','r',...
    'linewidth',2,...
    'facecolor','none');                                                    %Create a rectangle to show the cage boundaries.
run(1) = 0;                                                                 %Set the run variable to zero.
set(handles.mainfig,'userdata',run);                                        %Resave the loop variables on the main GUI's UserData property.
    

%% This function executes when the user presses the start/stop button.
function StartStop(hObject,~)           
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
run = get(handles.mainfig,'userdata');                                      %Grab the run variable from the userdata property on the main figure.
if run(1) == 0                                                              %If a game isn't currently running...
    handles.rat = inputdlg('What is this animal''s name?','Animal Name');   %Ask the user for the animal's name.
    if isempty(handles.rat)                                                 %If the user didn't enter an animal name...
        return                                                              %Skip the rest of the function.
    end
    for c = '/\?%*:|"<>.'                                                   %Step through all reserved characters.
        handles.rat{1}(handles.rat{1} == c) = [];                           %Kick out any reserved characters from the handles.rat name.
    end
    if isempty(handles.rat)                                                 %If the user didn't enter an animal name...
        return                                                              %Skip the rest of the function.
    end
    handles.rat = upper(handles.rat{1});                                    %Make the handles.rat name all upper-case.
    handles.rat(handles.rat == ' ') = '_';                                  %Replace all spaces in the handles.rat's name with underscores.
    filename = [handles.rat '_' datestr(now,30) '_ACTIVITY.txt'];           %Add the current timestamp to the filename.
    if ~exist(handles.datapath,'dir')                                       %If the session data subfolder doesn't exist yet...
        mkdir(handles.datapath);                                            %Create the directory.
    end
    [filename, path] = uiputfile('*.txt','Save Activity File',...
        [handles.datapath filename]);                                       %Ask the user to confirm the filename.
    if filename(1) == 0                                                     %If the user pressed cancel...
        return                                                              %Skip the rest of the function.
    end
    handles.filename = [path filename];                                     %Save the filename with the path included.
    set(handles.startbutton,'string','STOP TRACKING',...
        'foregroundcolor',[0.5 0 0]);                                       %Change the string and foreground color on the start/stop button.
    set(handles.calbutton,'enable','off');                                  %Disable the calibration button.
    set(handles.threshbutton,'enable','off');                               %Disable the threshold button.
    run(1) = 1;                                                             %Set the run variable to 1.
    set(handles.mainfig,'userdata',run);                                    %Resave the loop variables on the main GUI's UserData property.
    drawnow;                                                                %Update the GUI immediately.
    handles = Tracking_Loop(handles,1);                                     %Start the main tracking loop.
    set(handles.startbutton,'string','START TRACKING',...
        'foregroundcolor',[0 0.5 0]);                                       %Change the string and foreground color on the start/stop button.
    set(handles.calbutton,'enable','on');                                   %Enable the calibration button.
    set(handles.threshbutton,'enable','on');                                %Enable the threshold button.
    guidata(handles.mainfig,handles);                                       %Pin the handles structure back to the main figure.
else                                                                        %Otherwise, if the tracking loop is currently running...
    run(1) = 0;                                                             %Set the run variable to zero.
    set(handles.mainfig,'userdata',run);                                    %Resave the loop variables on the main GUI's UserData property.
end


%% This function executes when the user presses the threshold button.
function SetThreshold(hObject,~)           
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
run = get(handles.mainfig,'userdata');                                      %Grab the run variable from the userdata property on the main figure.
if run(1) == 0                                                              %If a game isn't currently running...
    temp = questdlg('Which color do you want to track?',...
        'Tracking Color','Green','White','Black','Green');                  %Ask the user to pick a color.
    if ~strcmpi(temp,handles.tcolor)                                        %If the user changed the current tracking color...
        handles.tcolor = temp;                                              %Save the new color as the current tracking color.
        run(3) = NaN;                                                       %Clear out the old threshold level for auto-setting.
    end
    set(handles.threshbutton,'string','DONE',...
        'foregroundcolor',[0.5 0 0]);                                       %Change the string and foreground color on the start/stop button.
    set(handles.calbutton,'enable','off');                                  %Disable the calibration button.
    set(handles.startbutton,'enable','off');                                %Disable the start/stop button.
    run(1) = 1;                                                             %Set the run variable to 1.
    set(handles.mainfig,'userdata',run);                                    %Resave the loop variables on the main GUI's UserData property.
    drawnow;                                                                %Update the GUI immediately.
    handles = Tracking_Loop(handles,0);                                     %Start the main tracking loop.
    set(handles.threshbutton,'string','CHECK THRESHOLD',...
        'foregroundcolor',[0 0.5 0]);                                       %Change the string and foreground color on the start/stop button.
    set(handles.calbutton,'enable','on');                                   %Enable the calibration button.
    if ~isempty(handles.corners)                                            %If the cage dimensions are entered...
        set(handles.startbutton,'enable','on');                             %Enable the start/stop button.
    end
    guidata(handles.mainfig,handles);                                       %Pin the handles structure back to the main figure.
else                                                                        %Otherwise, if the tracking loop is currently running...
    run(1) = 0;                                                             %Set the run variable to zero.
    set(handles.mainfig,'userdata',run);                                    %Resave the loop variables on the main GUI's UserData property.
end


%% This function creates the main figure and populates the uicontrols.
function handles = Make_GUI

%Set the common properties of subsequent uicontrols.
uheight = 1.5;                                                              %Set the height of all uicontrols, in centimeters

%Create the main figure.
set(0,'units','centimeters');                                               %Set the screensize units to centimeters.
pos = get(0,'ScreenSize');                                                  %Grab the screensize.
i = pos(3)/2;                                                               %Set the width of the camera selection figure to half the screen width.
j = 0.75*(i-0.2)+0.3+uheight;                                               %Set the height of the camera selection figure to get a 4:3 ratio in the axes.
pos = [pos(3)/2 - i/2,pos(4)/2 - j/2,i,j];                                  %Scale a figure position relative to the screensize.
handles.mainfig = figure('units','centimeter',...
    'Position',pos,...
    'MenuBar','none',...
    'numbertitle','off',...
    'resize','on',...
    'name','Vulintus Rodent Tracker (beta)');                               %Set the properties of the main figure.
fontsize = round(2*i/3);                                                    %Set the fontsize for all uicontrols.
    
%Create axes for displaying the webcam feed.
handles.axes = axes('parent',handles.mainfig,...
    'units','centimeters',...
    'position',[0.1 uheight+0.2 i-0.3 j-uheight-0.3],...
    'box','on',...
    'xtick',[],...
    'ytick',[]);                                                            %Create the web data axes.
set(handles.axes,'units','normalized');                                     %Make the axes resizable.

%Create a calibration and start/stop pushbutton.
w = (i-0.4)/3;                                                              %Calculate the button width.
handles.calbutton = uicontrol(handles.mainfig,'style','pushbutton',...
    'string','SET-UP',...
    'units','centimeters',...
    'position',[0.1, 0.1, w, uheight],...
    'fontweight','bold',...
    'fontsize',fontsize,...
    'horizontalalignment','right',...
    'foregroundcolor',[0 0.5 0],...
    'backgroundcolor',get(handles.mainfig,'color'),...
    'enable','off');                                                        %Make a calibration pushbutton.
set(handles.calbutton,'units','normalized');                                %Make the calibration pushbutton resizable.
handles.threshbutton = uicontrol(handles.mainfig,'style','pushbutton',...
    'string','CHECK THRESHOLD',...
    'units','centimeters',...
    'position',[w+0.2, 0.1, w, uheight],...
    'fontweight','bold',...
    'fontsize',fontsize,...
    'horizontalalignment','right',...
    'foregroundcolor',[0 0.5 0],...
    'backgroundcolor',get(handles.mainfig,'color'),...
    'enable','off');                                                        %Make a threshold pushbutton.
set(handles.threshbutton,'units','normalized');                             %Make the threshold pushbutton resizable.
handles.startbutton = uicontrol(handles.mainfig,'style','pushbutton',...
    'string','START TRACKING',...
    'units','centimeters',...
    'position',[2*w+0.3, 0.1, w, uheight],...
    'fontweight','bold',...
    'fontsize',fontsize,...
    'horizontalalignment','right',...
    'foregroundcolor',[0 0.5 0],...
    'backgroundcolor',get(handles.mainfig,'color'),...
    'enable','off');                                                        %Make a start/stop pushbutton.
set(handles.startbutton,'units','normalized');                              %Make the start/stop pushbutton resizable.
set(handles.mainfig,'ResizeFcn',{@ResizeMain,uheight});                     %Set the resize function for the main figure.


%% This function is called whenever the main figure is resized.
function ResizeMain(hObject,~,uheight)
pos = get(hObject,'position');                                              %Grab the figure position.
pos(3) = (pos(4)-uheight-0.3)/0.75+0.2;                                     %Adjust the figure width to keep the main axes at a 4:3 ratio.
set(hObject,'position',pos);                                                %Reset the figure's position.
fontsize = round(2*pos(3)/3);                                               %Set the fontsize for all uicontrols.
c = get(hObject,'children');                                                %Grab all of the children of the main figure.
for i = c                                                                   %Step through the figure's children.
    if strcmpi(get(i,'type'),'uicontrol')                                   %If the child is a uicontrol...
        set(i,'fontsize',fontsize);                                         %Adjust the fontsize on each uicontrol.
    end
end


%% This function is called when the user presses a key while the main figure has focus.
function KeyPress(~,eventdata,h)
run = get(h,'UserData');                                                    %Grab the loop variables from the "UserData" property of the main figure.
if strcmpi(eventdata.Key,'uparrow')                                         %If the key pressed was the up arrow...
    run(3) = run(3) - 0.01;                                                 %Increment the grayscale threshold up by 0.01.
elseif strcmpi(eventdata.Key,'downarrow')                                   %If the key pressed was the down arrow...
    run(3) = run(3) + 0.01;                                                 %Increment the grayscale threshold down by 0.01.
else                                                                        %Otherwise, for any other key...
    if run(2) == 1                                                          %If the current plot type is the color image...
        run(2) = 2;                                                         %Change the current plot type to the b&w blob image.
    else                                                                    %Otherwise, if the current plot type is the b&w blob image...
        run(2) = 1;                                                         %Change the current plot type to the color image.
    end
end
if run(3) > 1                                                               %If the grayscale threshold is greater than 1...
    run(3) = 1;                                                             %Set the grayscale threshold to 1.
elseif run(3) < 0                                                           %If the grayscale threshold is less than 0...
    run(3) = 0;                                                             %Set the grascale threshold to 0.
end
set(h,'UserData',run);                                                      %Resave the loop variables on the main GUI's UserData property.


%% This function allows the user to set the corners of the cage.
function Calibrate(hObject,~)
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
handles.vid = Camera_Setup;                                                 %Create a video input object with the Camera_Setup function.
if isempty(handles.vid)                                                     %If no camera was selected...
    return                                                                  %Skip execution of the rest of the function.
end
if ~isempty(handles.bounds) && ishandle(handles.bounds)                     %If the boundaries of the box are already marked...
    delete(handles.bounds);                                                 %Delete the box boundary rectangle.
end
handles.prev = preview(handles.vid,handles.prev);                           %Convert the image in the GUI axes to a live feed.
targets = {'top left corner',...
    'top right corner',...
    'bottom left corner',...
    'bottom right corner'};                                                 %List the targets that the user will click.
txt_labels = {'Top Left','Top Right','Bottom Left','Bottom Right'};         %Make labels for the objects the user will click on.
corners = zeros(4,2);                                                       %Create a matrix to hold the corner coordinates.
txt_h = nan(length(targets),1);                                             %Create a matrix to hold text handles.
axes(handles.axes);                                                         %Force focus to the GUI axes.
qstring = 'Are the cage corners marked correctly?';                         %Make a query string to ask the user to verify the corner positions.
temp = 'No';                                                                %Start with a default response of 'No'.
while strcmp(temp,'No')                                                     %Loop until the user's selected the 4 corners of the mat.
    if ~isnan(txt_h(1))                                                     %If text objects already exist labeling the corners...
        delete(txt_h(1:4));                                                 %Delete them.
    end
    for i = 1:4                                                             %Step through the 4 corners of the mat.
        Centered_Text(handles.axes,['Click the ' targets{i}],20,'w');       %Show the target to click in the central text label.
        axes(handles.axes);                                                 %Force focus to the GUI axes.
        xy = ginput(1);                                                     %Have the user click on the specified object.
        corners(i,:) = xy;                                                  %Save the x-y coordinates in the corners field.
        txt_h(i) = text(xy(1),xy(2),txt_labels{i},...
            'color','r',...
            'edgecolor','r',...
            'horizontalalignment','center',...
            'verticalalignment','middle',...
            'fontsize',10,...
            'fontweight','bold',...
            'margin',2);                                                    %Create a text object on the axes to label each clicked object.
    end
    temp = questdlg(qstring,'Mark Corners','Yes','No','Yes');               %Ask the user if the corners are correct.
end
Centered_Text(handles.axes,'Input cage dimensions',20,'w');                 %Change the string on the central text object.
prompt = {'Enter the width of the cage (cm):',...
    'Enter the height of the cage (cm):'};                                  %Create prompts for the user to enter dimensions.
dlg_title = 'Dimensions';                                                   %Set the dialog title for the following input dialog box.
num_lines = 1;                                                              %Set the number of lines to return for each question.
def = {'60','60'};                                                          %Set the default answers.
temp = inputdlg(prompt,dlg_title,num_lines,def);                            %Have the user set the dimensions with an input dialog box.
handles.width = str2double(temp{1});                                        %Save the entered mat width.
handles.height = str2double(temp{2});                                       %Save the entered mat height.
txt = Centered_Text(handles.axes,'Calibrated!',20,'w');                     %Change the string on the central text object to show that the video feed is calibrated.
fid = fopen(handles.cal_file,'w');                                          %Open a binary file for saving the calibration data.
for i = 1:4                                                                 %Step through the corners and objects on the mat.
    fwrite(fid,corners(i,:)','float32');                                    %Write the x-y coordinates of each corner/object with 32-bit precision.
end
fwrite(fid,handles.width,'float32');                                        %Write the mat width, in inches, to the binary file.
fwrite(fid,handles.height,'float32');                                       %Write the mat height, in inches, to the binary file.
fclose(fid);                                                                %Close the calibration binary file.
pause(1);                                                                   %Pause for 1 second.
delete(txt_h);                                                              %Delete all off the text objects.
delete(txt);                                                                %Delete all off the text objects.
handles.corners = [mean(corners([1,3],1)), mean(corners(1:2,2)),...
    mean(corners([2,4],1)), mean(corners(3:4,2))];                          %Find the position of a bounding box containing the cage.
handles.corners(3:4) = handles.corners(3:4) - handles.corners(1:2);         %Find the height and width, in pixels, from the top right corner.
handles.bounds = rectangle('parent',handles.axes,...
    'position',handles.corners,...
    'edgecolor','r',...
    'linewidth',2,...
    'facecolor','none');                                                    %Create a rectangle to show the cage boundaries.
c = handles.corners;                                                        %Copy the cage corner corner locations into an easier-to-work-with matrix.
m = handles.cage_margin;                                                    %Copy the cage border margin into an easier-to-work-with matrix.
handles.cage_border = [c(1)-m*c(3),c(2)-m*c(4),...
    c(1)+(1+m)*c(3),c(2)+(1+m)*c(4)];                                       %Set the cage border for ignoring erroneous centroids.
set(handles.startbutton,'enable','on');                                     %Enable the start/stop button.
guidata(handles.mainfig,handles);                                           %Pin the handles structure to the main figure.


%% This function reads in an existing calibration file.
function [corners, width, height] = Load_Calibration(filename)
corners = zeros(4,2);                                                       %Create a matrix to hold the corner coordinates.
fid = fopen(filename,'r');                                                  %Open the calibration file for reading.
for i = 1:4                                                                 %Step through the 4 corners.
    xy = double(fread(fid,2,'float32'));                                    %Read in the x-y coordinates for each corner/object
    corners(i,:) = xy';                                                     %Save the x-y coordinates in the appropriate field.
end
width = fread(fid,1,'float32');                                             %Read in the cage width.
height = fread(fid,1,'float32');                                            %Read in the cage height.
fclose(fid);                                                                %Close the binary file.
corners = [mean(corners([1,3],1)), mean(corners(1:2,2)),...
    mean(corners([2,4],1)), mean(corners(3:4,2))];                          %Find the position of a bounding box containing the cage.
corners(3:4) = corners(3:4) - corners(1:2);                                 %Find the height and width, in pixels, from the top right corner.