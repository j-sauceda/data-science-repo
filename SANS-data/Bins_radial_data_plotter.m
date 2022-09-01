%% SANS radial data plotter - personalized bin length

clear;

%% declaration of variables

% Selects the directory and reduced 2D .DAT files to plot

% asks the user to select a folder with the spectra files
directory = uigetdir(pwd, 'Please select a folder');
% loads all the .dat files
files = dir(fullfile(directory, 'COSO_*.DAT')); % Add name filter
number_of_files = length(files);

% defines the QxQy regions of interest
innerRing = 0.0050;
outerRing = 0.0420;

cut = 0.000; % signal below this percentage of the max intensity is neglected
cut_temp = 60.0;

npixels = 192; % stores the number of pixels in QUOKKA's detector

xCoords = zeros(1,npixels,number_of_files);
yCoords = zeros(npixels,1,number_of_files);
zValues = zeros(npixels,npixels,number_of_files);

% Stores the scattered intensity in different QxQy regions
bin_length = 0.001;
q_bins = transpose(innerRing: bin_length: outerRing);
n_bins = length(q_bins);
int_bins = zeros(number_of_files, n_bins);

% stores the temperatures of each measurement
temp = zeros(1,number_of_files);

% scan_type is 1 for temperature scans and 2 for field scans
scan_type = 2;
% stores the field of each measurement
field = zeros(1,number_of_files);


%% Loads the data from the .AVE files
for currentFileNumber = 1:number_of_files
    
    currentFileName = files(currentFileNumber).name;
    fullFileName = [directory, '/', currentFileName];
    % gets the temperature of each T-scan measurement
    temp(currentFileNumber) = str2double(strrep(strtok(fliplr(strtok(fliplr(currentFileName),'_')),'K'),',','.'));
    % gets the field of each H-scan measurement
    field(currentFileNumber) = str2double(strrep(strtok(fliplr(strtok(fliplr(currentFileName),'_')),'mT'),',','.'));
    % dlmread reads a data file, excluding its header
    raw = dlmread(fullFileName, '\t', 19, 0);
    % loads the qx,qy,reduced_intensity data in separate column vectors
    qx = raw(:,1);
    qy = raw(:,2);
    reduced_int = raw(:,3);
    
    %% Organizes the data for a time-efficient analysis
    for i = 1:npixels
        xCoords(1,i,currentFileNumber) = qx(i);
    end

    for i = 0:npixels - 1
        yCoords(i+1,1,currentFileNumber) = qy(1 + i*npixels);
    end

    for i = 1:npixels
        for j = 1:npixels
            zValues(j,i,currentFileNumber) = reduced_int(i+npixels*(j-1));
        end
    end
end


%% calculates the values of interest in the QxQy regions defined above
for currentFileNumber = 1:number_of_files
    bin_pixels = zeros(n_bins,1);
    for i = 1:npixels
        for j = 1:npixels
            [angle, q] = cart2pol(xCoords(1,i,currentFileNumber),yCoords(j,1,currentFileNumber));
            if q >= innerRing && q <= outerRing && zValues(i,j,currentFileNumber) > 0
                bin_number = floor((q-innerRing)/bin_length) + 1;
                bin_pixels(bin_number,1) = bin_pixels(bin_number,1) + 1;
                int_bins(currentFileNumber,bin_number) = int_bins(currentFileNumber,bin_number) + zValues(i,j,currentFileNumber);
            end
        end
    end
    int_bins(currentFileNumber,:) = int_bins(currentFileNumber,:)./transpose(bin_pixels);
end


%% Plots the results
for currentFileNumber = 1:number_of_files
    % lines 91-109 define a single figure window with multiple tabs, each
    % with 8 subplots containing exp. data and the corresponding fitting.
    desktop = com.mathworks.mde.desk.MLDesktop.getInstance;
    clear radialGroup;
    radialGroup = desktop.addGroup('radialGroup');
    desktop.setGroupDocked('radialGroup', 0);
    myDim = java.awt.Dimension(1, 1);
    desktop.setDocumentArrangement('radialGroup', 2, myDim)
    obsPropertyWarn = warning('off', 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
    total_figures = ceil(number_of_files/8);
    figH = zeros(1, total_figures);
    
    figNumber = 10 + (currentFileNumber - 1)/8;
    if mod(currentFileNumber - 1,8) == 0
        figH(figNumber) = figure('WindowStyle', 'docked', ...
           'Name', sprintf('Figure %d', figNumber), ...
           'NumberTitle', 'off');
        %clf(figNumber);
        set(get(handle(figH(figNumber)), 'javaframe'), 'GroupName','radialGroup');
    end
    warning(obsPropertyWarn);
    
    subplot(2,4,1 + mod(currentFileNumber - 1,8));
    plot(q_bins, int_bins(currentFileNumber,:), 'ks-', 'MarkerSize', 6);
    xlim([0 0.043]);
    xlabel(strcat('|Q| (',strcat(char(8491),'^{-1})')));
    ylabel('intensity (a.u.)');
    %set(gca, 'YScale', 'log');
    if scan_type == 1
        title("("+currentFileNumber+") " + strcat('T=', num2str(temp(currentFileNumber)), ' K'));
    else
        title("("+currentFileNumber+") " + strcat('H=', num2str(field(currentFileNumber)), ' mT'));
    end
end