%% SANS radial integration fitting

clear;

% Selects the directory and reduced 2D .DAT files to plot

% asks the user to select a folder with the spectra files
directory = uigetdir(pwd, 'Please select a folder');
% loads all the .dat files
files = dir(fullfile(directory, 'COSO_*.DAT')); % Add name filter
number_of_files = length(files);
n_bins = 100;
npixels = 192;

% Uses a gaussian profile to fit the data peaks
% i = a*exp(-((q-q0)/gamma)^2) where a is amplitude, q0 the peak center and
% sigma is the half width at half maximum

% Stores the calculated fitting coefficients
fitting_results = zeros(number_of_files, 6);
fitting_curve = '(a1/(w1*sqrt(pi/2)))*exp(-2*((q-q1)/w1)^2) + (a2/(w2*sqrt(pi/2)))*exp(-2*((q-q2)/w2)^2) + (a3/(w3*sqrt(pi/2)))*exp(-2*((q-q3)/w3)^2) + m + n*q';
%                 1     3    5               7      9      11     13      15      17
% Fit Parameters: a1,   a2,  a3,   m,    n,  q1,    q2,    q3,    w1,     w2,     w3
starting_point = [5000  3000 1000 1000   0   0.008  0.011  0.021  4.2e-3  2.0e-3  4.4e-3];
upper_limit =    [Inf   Inf  Inf  Inf    1   10e-3  14e-3  22e-3  6.0e-3  6.0e-3  6.0e-3];
lower_limit =    [0      0    0    0    -1   07e-3  10e-3  14e-3  1.0e-3  1.0e-3  1.0e-3];

excluded_angle1 = -100; %045; % set to -100 if no region is excluded
excluded_angle2 = -100; %135; % set to -100 if no region is excluded
excluded_angle3 = -100; %225; % set to -100 if no region is excluded
excluded_angle4 = -100; %315; % set to -100 if no region is excluded
dangle = 12.5; % excluded-angles half width in degrees

% cut off field
cut_temp = 200; % I have not found a good H-field cut off value;
% stores the temperatures of each measurement
temp = zeros(number_of_files, 1);
% stores the q bins
q_bins = zeros(n_bins, 1);
% stores the i(q) bin data
int_bins = zeros(n_bins, number_of_files);

% Loads the PM data from the .DAT file
pm_file = 'PM.DAT';
fullFileName = [directory, '/', pm_file];
pm = readmatrix(fullFileName, 'FileType', 'text', 'NumHeaderLines', 19, 'Delimiter', '\t'); % dlmread(fullFileName, '\t', 19, 0);
x = pm(:,1);
y = pm(:,2);
z = pm(:,3);

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

pm_int = zeros(npixels, npixels);
for i = 1:npixels
    for j = 1:npixels
        pm_int(j,i) = z(i+npixels*(j-1));
    end
end



%% Loads the data from the .DAT files
for currentFileNumber = 1:number_of_files
    currentFileName = files(currentFileNumber).name;
    fullFileName = [directory, '/', currentFileName];
    % gets the temperature of each measurement
    temp(currentFileNumber, 1) = str2double(strrep(strtok(fliplr(strtok(fliplr(currentFileName),'_')),'K'),',','.'));
    % dlmread reads a data file, excluding its header
    %raw = dlmread(fullFileName, '\t', 19, 0);
    raw = readmatrix(fullFileName, 'FileType', 'text', 'NumHeaderLines', 19, 'Delimiter', '\t');
    
    % Selects the column vectors for q and intensity
    % since they are too close to the beam stop
    qx = raw(:,1);
    qy = raw(:,2);
    raw_int = raw(:,3);
    
    % Organizes the data for a time-efficient analysis
    for i = 1:npixels
        xCoords(1,i) = qx(i);
    end

    for i = 0:npixels - 1
        yCoords(i+1,1) = qy(1 + i*npixels);
    end

    for i = 1:npixels
        for j = 1:npixels
            zValues(j,i) = max(raw_int(i+npixels*(j-1)) - pm_int(j, i), 0);
        end
    end
    
    %% Stablishes the fitting options
    
    % stablishes the fitting type
    ft = fittype(fitting_curve, 'independent', 'q', 'dependent', 'y'); % ft = fittype('', 'independent', 'x', 'dependent', 'y');
    % stablishes the fitting options
    opts = fitoptions('Method', 'NonlinearLeastSquares');
    opts.Display = 'Off';
    opts.StartPoint = starting_point;
    if currentFileNumber == 36
        opts.StartPoint = [5000  3000 1000 1000   0   0.008  0.011  0.021  4.2e-3  2.0e-3  4.4e-3];
        opts.Upper =      [Inf   Inf  Inf  Inf    1   10e-3  14e-3  22e-3  6.0e-3  6.0e-3  6.0e-3];
        opts.Lower =      [0      0    0    0    -1   06e-3  10e-3  14e-3  1.0e-3  1.0e-3  1.0e-3];
    end
    opts.Lower = lower_limit;
    opts.Upper = upper_limit;
    
    %% calculates the values of q, int(q)
    a = min(min(sqrt(xCoords.^2 + yCoords.^2)));
    b = max(max(sqrt(xCoords.^2 + yCoords.^2)));
    h = (b-a)/n_bins;
    for i = 1:n_bins
        q_bins(i, 1) = a + (i+0.5)*h;
    end
    
    for i = 1:npixels
        for j = 1:npixels
            [angle, q] = cart2pol(xCoords(1,i), yCoords(j,1));
            bin_i = max(round(abs(q - a - 0.0*h)/h), 1);
            
            if (angle < 0)
                angle = angle + 2*pi;
            end
            angle = rad2deg(angle);
            if angle >= 360 - dangle
                angle = angle - 360;
            end

            region1 = angle >= excluded_angle1-dangle && angle <= excluded_angle1+dangle;
            region2 = angle >= excluded_angle2-dangle && angle <= excluded_angle2+dangle;
            region3 = angle >= excluded_angle3-dangle && angle <= excluded_angle3+dangle;
            region4 = angle >= excluded_angle4-dangle && angle <= excluded_angle4+dangle;
            if ~(region1 || region2 || region3 || region4)
                int_bins(bin_i, currentFileNumber) = int_bins(bin_i, currentFileNumber) + zValues(i,j);
            end
        end
    end
    
    %% Fit model to data.
    fitresult = fit(q_bins(14:58), int_bins(14:58, currentFileNumber), ft, opts);
    coefficients = coeffvalues(fitresult);
    
    if temp(currentFileNumber) < cut_temp
        fitting_results(currentFileNumber, 1) = coefficients(1); % a1
        fitting_results(currentFileNumber, 3) = coefficients(2); % a2
        fitting_results(currentFileNumber, 5) = coefficients(3); % a3
        fitting_results(currentFileNumber, 7) = coefficients(6); % q1
        fitting_results(currentFileNumber, 9) = coefficients(7); % q2
        fitting_results(currentFileNumber, 11) = coefficients(8); % q3
        fitting_results(currentFileNumber, 13) = sqrt(log(4))*coefficients(9); % w1
        fitting_results(currentFileNumber, 15) = sqrt(log(4))*coefficients(10); % w2
        fitting_results(currentFileNumber, 17) = sqrt(log(4))*coefficients(11); % w3
        
        intervals = confint(fitresult);
        
        fitting_results(currentFileNumber,2) = 0.5*abs(intervals(1,1) - intervals(2,1)); % da1
        fitting_results(currentFileNumber,4) = 0.5*abs(intervals(1,2) - intervals(2,2)); % da2
        fitting_results(currentFileNumber,6) = 0.5*abs(intervals(1,3) - intervals(2,3)); % da3
        fitting_results(currentFileNumber,8) = 0.5*abs(intervals(1,6) - intervals(2,6)); % dq1
        fitting_results(currentFileNumber,10) = 0.5*abs(intervals(1,7) - intervals(2,7)); % dq2
        fitting_results(currentFileNumber,12) = 0.5*abs(intervals(1,8) - intervals(2,8)); % dq3
        fitting_results(currentFileNumber,14) = 0.5*sqrt(log(4))*abs(intervals(1,9) - intervals(2,9)); % dw1
        fitting_results(currentFileNumber,16) = 0.5*sqrt(log(4))*abs(intervals(1,10) - intervals(2,10)); % dw2
        fitting_results(currentFileNumber,18) = 0.5*sqrt(log(4))*abs(intervals(1,11) - intervals(2,11)); % dw3
    end
    
    %% Plots the experimental data and fitting results
    % lines 95-115 define a single figure window with multiple tabs, each
    % with 8 subplots containing exp. data and the corresponding fitting.
    desktop = com.mathworks.mde.desk.MLDesktop.getInstance;
    clear myGroup;
    myGroup = desktop.addGroup('myGroup');
    desktop.setGroupDocked('myGroup', 0);
    myDim = java.awt.Dimension(1, 1);
    desktop.setDocumentArrangement('myGroup', 2, myDim)
    obsPropertyWarn = warning('off', 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
    total_figures = ceil(number_of_files/8);
    figH = zeros(1, total_figures);
    
    figNumber = 1 + (currentFileNumber - 1)/8;
    if mod(currentFileNumber - 1,8) == 0
        figH(figNumber) = figure('WindowStyle', 'docked', ...
           'Name', sprintf('Figure %d', figNumber), ...
           'NumberTitle', 'off');
        clf(figNumber);
        set(get(handle(figH(figNumber)), 'javaframe'), 'GroupName','myGroup');
    end
    warning(obsPropertyWarn);
    
    
    subplot(2,4,1 + mod(currentFileNumber - 1,8));
    plot(q_bins, int_bins(:, currentFileNumber), 'ks', 'MarkerSize', 8);
    hold on;
    plot(fitresult, 'b-');
    plot(q_bins, zeros(n_bins), 'r--');
    legend('off');
    hold off;
    %xlim([0.005 0.043]);
    title("("+currentFileNumber+") " + strcat('T=', num2str(temp(currentFileNumber)), ' K'));
    
    % sets the newly acquired fitting coefficients as the starting point
    % for the next curve fitting
    starting_point = coefficients;
end


%% saves the fitting coefficients and their uncertainties into a .txt file
writematrix(fitting_results, 'fitting_results.txt', 'Delimiter', '\t');


%% plots the fitting coefficients
figure(23);
subplot(3, 3, 1);
%errorbar(temp, log(fitting_results(:, 1)), log(fitting_results(:, 2)), 'Marker', 'square', 'LineStyle','-', 'Color', 'blue');
plot(temp, fitting_results(:, 1), 'Marker', 'square', 'LineStyle','-', 'Color', 'red');
xlabel('Temperature (K)');
ylabel('Integrated intensity (a.u.)');
ylim([0 1.1*max(fitting_results(:, 1))]);

subplot(3, 3, 2);
%errorbar(temp, log(fitting_results(:, 3)), log(fitting_results(:, 4)), 'Marker', 'square', 'LineStyle','-', 'Color', 'blue');
plot(temp, fitting_results(:, 3), 'Marker', 'square', 'LineStyle','-', 'Color', 'red');
xlabel('Temperature (K)');
ylabel('Integrated intensity 2 (a.u.)');
ylim([0 1.1*max(fitting_results(:, 3))]);

subplot(3, 3, 3);
%errorbar(temp, log(fitting_results(:, 5)), log(fitting_results(:, 6)), 'Marker', 'square', 'LineStyle','-', 'Color', 'blue');
plot(temp, fitting_results(:, 5), 'Marker', 'square', 'LineStyle','-', 'Color', 'red');
xlabel('Temperature (K)');
ylabel('Integrated intensity 3 (a.u.)');
ylim([0 1.1*max(fitting_results(:, 5))]);

subplot(3, 3, 4);
%errorbar(temp, fitting_results(:, 7), fitting_results(:, 8), 'Marker', 'diamond', 'LineStyle','-', 'Color', 'blue');
plot(temp, fitting_results(:, 7), 'Marker', 'diamond', 'LineStyle','-', 'Color', 'green');
xlabel('Temperature (K)');
ylabel(strcat('|Q1| (',strcat(char(8491),'^{-1})')));
ylim(1e-3*[6 12.5]);

subplot(3, 3, 5);
%errorbar(temp, fitting_results(:, 9), fitting_results(:, 10), 'Marker', 'diamond', 'LineStyle','-', 'Color', 'blue');
plot(temp, fitting_results(:, 9), 'Marker', 'diamond', 'LineStyle','-', 'Color', 'green');
xlabel('Temperature (K)');
ylabel(strcat('|Q2| (',strcat(char(8491),'^{-1})')));
ylim(1e-3*[8 16.5]);

subplot(3, 3, 6);
%errorbar(temp, fitting_results(:, 11), fitting_results(:, 12), 'Marker', 'diamond', 'LineStyle','-', 'Color', 'blue');
plot(temp, fitting_results(:, 11), 'Marker', 'diamond', 'LineStyle','-', 'Color', 'green');
xlabel('Temperature (K)');
ylabel(strcat('|Q3| (',strcat(char(8491),'^{-1})')));
ylim(1e-3*[12 20.5]);

subplot(3, 3, 7);
%errorbar(temp, fitting_results(:, 13), fitting_results(:, 14), 'Marker', 'o', 'LineStyle','-', 'Color', 'blue');
plot(temp, fitting_results(:, 13), 'Marker', 'o', 'LineStyle','-', 'Color', 'blue');
xlabel('Temperature (K)');
ylabel(strcat('FWHM 1 (',strcat(char(8491),'^{-1})')));
ylim(1e-3*[0 12.5]);

subplot(3, 3, 8);
%errorbar(temp, fitting_results(:, 15), fitting_results(:, 16), 'Marker', 'o', 'LineStyle','-', 'Color', 'blue');
plot(temp, fitting_results(:, 15), 'Marker', 'o', 'LineStyle','-', 'Color', 'blue');
xlabel('Temperature (K)');
ylabel(strcat('FWHM 2 (',strcat(char(8491),'^{-1})')));
ylim(1e-3*[0 12.5]);

subplot(3, 3, 9);
%errorbar(temp, fitting_results(:, 17), fitting_results(:, 18), 'Marker', 'o', 'LineStyle','-', 'Color', 'blue');
plot(temp, fitting_results(:, 17), 'Marker', 'o', 'LineStyle','-', 'Color', 'blue');
xlabel('Temperature (K)');
ylabel(strcat('FWHM 3 (',strcat(char(8491),'^{-1})')));
ylim(1e-3*[0 12.5]);