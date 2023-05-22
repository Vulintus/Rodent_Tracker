function varargout = quick_track(varargin)

if nargin > 0                                                               %If there was at least one input argument.
    file = varargin;                                                        %The first input argument will be the file name.
    if ischar(file)                                                         %If the filename isn't a cell...
        file = {file};                                                      %Save the filename in a cell array.
    end
else                                                                        %Otherwise...
	[file, path] = uigetfile('*ACTIVITY.txt','multiselect','on');           %Have the user pick an activity file.
    if iscell(file)                                                         %If the user's picked multiple files...
        for i = 1:length(file)                                              %Step through each selected file.
            file{i} = [path file{i}];                                       %Insert the path into the file name.
        end
    elseif ischar(file)                                                     %If only one file is selected...
        file = {[path file]};                                               %Add the path to the filename.
    elseif isempty(file)                                                    %If no file is selected...
        error('ERROR IN QUICK_TRACK: No file selected!');                   %Show an error message.
    end
end

fig_handles = zeros(length(file),1);                                        %Create a matrix to hold the figure handles.

for f = 1:length(file)                                                      %Step through each file.
    data = read_tracking_file(file{f});                                     %Read in the data from the tracking file.
    fig_handles(f) = figure;                                                %Open a new figure for showing the activity data.
    pos = get(fig_handles(f),'position');                                   %Find the current position of the figure.
    set(fig_handles(f),'position',...
        [pos(1),pos(2)-0.5*pos(4),pos(3),1.5*pos(4)]);                      %Make the figure 50% taller than the default.
    set(fig_handles(f),'color','w');                                        %Set the background color on the figure to white.
    
    subplot(3,1,1:2);                                                       %Plot the historical path in the top 2/3rds of the figure.
    plot(data(:,2),data(:,3),'color','k','linewidth',2);                    %Plot the path as a thick, black line.
    temp = [min(data(:,2)),max(data(:,2))];                                 %Find the minimum and maximum x-coordinates.
    xlim(temp + [-0.1,0.1]*range(temp));                                    %Set the x-axis limits.
    temp = [min(data(:,3)),max(data(:,3))];                                 %Find the minimum and maximum y-coordinates.
    ylim(temp + [-0.1,0.1]*range(temp));                                    %Set the x-axis limits.
    ylabel('distance (cm)');                                                %Label the y-axis.
    xlabel('distance (cm)');                                                %Label the x-axis.
    i = [0,find(file{f} == '\')] + 1;                                       %Find all of the forward slashes in the filename.
    title(file{f}(max(i):end-4),'fontsize',10,'interpreter','none');        %Put a title on the plot.
    drawnow;                                                                %Finish drawing the current plot before starting another.
    set(fig_handles(f),'numbertitle','off','name',file{f}(max(i):end-4));   %Show the filename at the top of the figure.
    
    subplot(3,1,3);                                                         %Plot the histogram as the bottom 1/3rd of the figure.
    data = [data(2:end,1), euclid_dist(data(1:end-1,2:3),data(2:end,2:3))]; %Find the distance traveled for each movement.
    data(:,1) = data(:,1)/60;                                               %Convert time to minutes.
    t = ceil(data(end,1));                                                  %Find the session time, in minutes.
    act = zeros(t,1);                                                       %Create a histogram matrix.
    for i = 1:t                                                             %Step through each minute of activity.
        a = (data(:,1) >= i-1 & data(:,1) < i);                             %Find all samples within each minute.
        act(i) = sum(data(a,2));                                            %Sum the distance traveled in each minute.
    end
    b = bar(act);                                                           %Show the activity histogram as a bar chart.
    set(b,'facecolor','k','barwidth',1);                                    %Color the bars black and make them full width.
    xlim([0.5,t+0.5]);                                                      %Set the x-axis limits.
    ylim([0,1.2*max(act)]);                                                 %Set the y-axis limits.
    box off;                                                                %Turn off the plot box.
    ylabel('distance (cm)');                                                %Label the y-axis.
    xlabel('time (minutes)');                                               %Label the x-axis.
    data = sum(data(:,2));                                                  %Calculate the total distance traveled.
    text(max(xlim),max(ylim),...
        ['Total Distance = ' num2str(data,'%1.0f') ' cm'],...
        'horizontalalignment','right','verticalalignment','top',...
        'fontsize',10,'fontweight','bold');                                 %Show the total distance in the top right of the plot.
    drawnow;                                                                %Finish drawing the current plot before starting another.
end
varargout{1} = fig_handles;                                                 %Return the figure handles as the first output argument.