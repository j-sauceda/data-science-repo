%% SANS spectrum contour plotter

clear;

% Selects the directory and reduced 2D .DAT files to plot

% asks the user to select a folder with the spectra files
directory = uigetdir(pwd, 'Please select a folder');
% loads all the .dat files
files = dir(fullfile(directory, 'COSO*.DAT'));
pm_file = 'PM.DAT';
number_of_files = length(files);

npixels = 192; % stores the number of pixels in the detector
intensity = zeros(npixels, npixels, number_of_files); % stores the intensity of each measurement
pm_int = zeros(npixels,npixels); % stores the Paramagnetic pattern

% scan_type is (1) temperature-, (2) field-, (3) or time-scans
scan_type = 1;
% stores the temperatures of each measurement
temp = zeros(1,number_of_files);
% stores the field of each measurement
field = zeros(1,number_of_files);
% stores the nominal time of each measurement
time = zeros(1, number_of_files);

% binary variable to save images (1) or not (0)
save = 0;
% format = 1 (SVG) | 2 (PNG)
format = 2;
% binary variable to add title or not
print_title = 1;


%% Loads the PM data from the .DAT file
fullFileName = [directory, '/', pm_file];
raw = dlmread(fullFileName, '\t', 19, 0);
x = raw(:,1);
y = raw(:,2);
z = raw(:,3);

% Organizes the PM data
xCoords = zeros(1,npixels);
yCoords = zeros(npixels,1);
zValues = zeros(npixels,npixels);

for i = 1:npixels
    xCoords(i) = x(i);
end

for i = 0:npixels - 1
    yCoords(i+1,1) = y(1 + i*npixels);
end

for i = 1:npixels
    for j = 1:npixels
        pm_int(j,i) = z(i+npixels*(j-1));
    end
end

% corrects the negative values in the PM data
for i = 1:npixels
    for j = 1:npixels
        if pm_int(i,j) < 0
            pm_int(i,j) = 0;
        end
    end
end


%% Loads the data from the .DAT files
for currentFileNumber = 1:1 %number_of_files
    currentFileName = files(currentFileNumber).name;
    fullFileName = [directory, '/', currentFileName];
    % gets the temperature of each T-scan measurement
    temp(currentFileNumber) = str2double(strrep(strtok(fliplr(strtok(fliplr(currentFileName),'_')),'K'),',','.'));
    % gets the field of each H-scan measurement
    field(currentFileNumber) = str2double(strrep(strtok(fliplr(strtok(fliplr(currentFileName),'_')),'mT'),',','.'));
    % sets the nominal time of each measurement
    time(currentFileNumber) = currentFileNumber - 1;
    raw = dlmread(fullFileName, '\t', 19, 0);
    x = raw(:,1);
    y = raw(:,2);
    z = raw(:,3);
    
    
    %% Organizes the data for plotting
    xCoords = zeros(1,npixels);
    yCoords = zeros(npixels,1);
    zValues = zeros(npixels,npixels);

    for i = 1:npixels
        xCoords(i) = x(i);
    end

    for i = 0:npixels - 1
        yCoords(i+1,1) = y(1 + i*npixels);
    end

    for i = 1:npixels
        for j = 1:npixels
            zValues(j,i) = z(i+npixels*(j-1));
        end
    end
    
    % corrects the negative values in the reduced data
    contourZ = zeros(npixels, npixels);

    for i = 1:npixels
        for j = 1:npixels
            if zValues(i,j) >= 0
                contourZ(i,j) = zValues(i,j);
            end
        end
    end
    
    
    %% subtracts the PM data
    for i = 1:npixels
        for j = 1:npixels
            intensity(i, j, currentFileNumber) = contourZ(i,j) - pm_int(i,j);
            if intensity(i, j, currentFileNumber) < 0
                intensity(i, j, currentFileNumber) = 0;
            end
        end
    end
    
    
    %% Creates the contour plot
    fig = figure(30);
    %fig = figure(currentFileNumber);
    colormap(jet);

    % intensity alias for easier plotting
    contourZ = intensity(:, :, currentFileNumber);
    
    levels = linspace(0, log(max(max(1.0*contourZ+1))), 50);
    [C,h] = contourf(xCoords, yCoords, log(1.0*contourZ+1), levels);
    
    xlabel(strcat('q_{x} (',strcat(char(8491),'^{-1})')));
    ylabel(strcat('q_{y} (',strcat(char(8491),'^{-1})')));
    if print_title == 1
        if scan_type == 1
            title("("+currentFileNumber+") " + strcat('T=', num2str(temp(currentFileNumber)), ' K'));
        elseif scan_type == 2
            title("("+currentFileNumber+") " + strcat('H=', num2str(field(currentFileNumber)), ' mT'));
        elseif scan_type == 3
            title("("+currentFileNumber+") "); %title("("+currentFileNumber+") " + strcat(num2str(time(currentFileNumber)), ' min'));
        end
    end
    set(gca,'FontSize',20);
    grid on;
    grid minor;
    ax = gca;
    ax.GridColor = 'w';
    ax.MinorGridColor = 'w';
    h.LineStyle = 'none';

    %minInt = min(min(zValues));
    %zValues = zValues - minInt;
    
    cb = colorbar();
    cb.Ruler.MinorTick = 'on';
    cb.Label.String = 'Log(Intensity) (a.u.)';
    cb.FontSize = 12;
    
    % saves each plot as image
    if save == 1
        % saves in SVG format
        if format == 1
            imageName = strcat(strtok(currentFileName,'.'), '.svg');
            saveas(fig, imageName, 'svg');
        elseif format == 2
        % saves in PNG format
            imageName = strcat(strtok(currentFileName,'.'), '-log.png');
            saveas(fig, imageName, 'png');
        end
    end
end