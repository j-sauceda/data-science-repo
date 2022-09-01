%% SANS spectrum contour plotter

clear;

% Selects the directory and reduced 2D .DAT files to plot

% asks the user to select a folder with the spectra files
directory = uigetdir(pwd, 'Please select a folder');
% loads all the .dat files
custom_filename = {'COSO_20doped_FFC_60mT_04K.DAT'; 'COSO_20doped_FFC_60mT_32K.DAT'; 'COSO_20doped_FFC_60mT_50K.DAT'};
pm_file = 'PM.DAT';
number_of_files = length(custom_filename);

npixels = 192; % stores the number of pixels in the detector
% stores the intensity of each measurement
intensity = zeros(npixels, npixels, number_of_files);
% stores the Paramagnetic pattern
pm_int = zeros(npixels,npixels);

% stores the temperatures of each measurement
temp = zeros(1,number_of_files);
% stores the field of each measurement
field = zeros(1,number_of_files);
% stores the optical-filter-edge of each measurement
filter = zeros(1,number_of_files);

% scan_type is 1: temperature scans, 2: field scans, 3: filter scans
scan_type = 1;
% (de)activates the title of the plot
show_title = 0;
% (de)activates saving the plot
savefiles = 1;



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
for currentFileNumber = 1:number_of_files
    currentFileName = custom_filename{currentFileNumber};
    fullFileName = [directory, '/', currentFileName];
    temp(currentFileNumber) = str2double(strrep(strtok(fliplr(strtok(fliplr(currentFileName),'_')),'K'),',','.'));
    field(currentFileNumber) = str2double(strrep(strtok(fliplr(strtok(fliplr(currentFileName),'_')),'mT'),',','.'));
    filter(currentFileNumber) = str2double(strrep(strtok(fliplr(strtok(fliplr(currentFileName),'_')),'nm'),',','.'));
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

    fig = figure(1001);
    %fig = figure(currentFileNumber);
    colormap(jet);

    % intensity alias for easier plotting
    contourZ = intensity(:, :, currentFileNumber);
    
    levels = linspace(0, log(max(max(1.0*contourZ+1))), 50);
    [C,h] = contourf(xCoords, yCoords, log(1.0*contourZ+1), levels);
    
    xlabel(strcat('q_{x} (',strcat(char(8491),'^{-1})')));
    ylabel(strcat('q_{y} (',strcat(char(8491),'^{-1})')));
    if show_title == 1
        if scan_type == 1
            title("("+currentFileNumber+") " + strcat('T=', num2str(temp(currentFileNumber)), ' K'));
        elseif scan_type == 2
            title("("+currentFileNumber+") " + strcat('H=', num2str(field(currentFileNumber)), ' mT'));
        else
            title("("+currentFileNumber+") " + strcat(strcat(char(955),'='), num2str(filter(currentFileNumber)), ' nm'));
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
    
    % saves each plot as a SVG file
%     imageName = strcat(strtok(currentFileName,'.'), '.svg');
%     saveas(fig, imageName, 'svg');
    
    % saves each plot as a PNG file
    if savefiles == 1
        imageName = strcat(strtok(currentFileName,'.'), '-log.png');
        saveas(fig, imageName, 'png');
    end

end