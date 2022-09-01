%% SANS timestamp reader - reads '/end_time' from .HDF raw data files

clear;

%% declaration of variables

% Selects the directory and raw .HDF files to read

% asks the user to select a folder with the spectra files
directory = uigetdir(pwd, 'Please select a folder');
% loads all the .HDF files
files = dir(fullfile(directory, '*.hdf')); % Add name filter
number_of_files = length(files);

% defines the HDF H-field variable to read
hdf_time_variable = '/end_time';
% defines the HDF temperature variable to read
temp_sensor = '/data/T1S2';
% defines the HDF H-field variable to read
field_sensor = '/data/B01SP01';

% stores the end time of each measurement
timestamps = datetime(1, 1, number_of_files);
relative_times = zeros(number_of_files, 1);
% stores the temperatures of each measurement
real_temp = zeros(number_of_files,1);
% stores the H-field of each measurement
real_field = zeros(number_of_files,1);



%% Loads the data from the .HDF files

for currentFileNumber = 1:number_of_files
    currentFileName = files(currentFileNumber).name;
    shortName = strtok(currentFileName,'.');
    
    % reads the timestamp
    datasetName = strcat(strcat('/',strtok(currentFileName, '.')), hdf_time_variable);
    % gets the time of each SANS measurement
    if currentFileNumber == 1
        start_time = h5read(currentFileName, strcat(strcat('/',strtok(currentFileName, '.')), '/start_time'));
        start_time = datetime(start_time{1});
    end
    end_time = h5read(currentFileName, datasetName);
    timestamps(1,1,currentFileNumber) = datetime(end_time{1});
    
    % reads the temperature sensor data
    datasetName = strcat(strcat('/',strtok(currentFileName, '.')), temp_sensor);
    % gets the temperature of each T-scan measurement
    real_temp(currentFileNumber) = h5read(currentFileName, datasetName);
    
    % reads the field sensor data
    datasetName = strcat(strcat('/',strtok(currentFileName, '.')), field_sensor);
    % gets the field of each H-scan measurement
    real_field(currentFileNumber) = h5read(currentFileName, datasetName)/10;
end

% calculates the relative times wrt first file
for i = 1:number_of_files
    relative_times(i) = minutes(timestamps(1,1,i) - start_time);
end



%% Plots the results

figure(2);
clf(2);

subplot(1,3,1);
plot(1:number_of_files, relative_times, 'ro');
xlabel('File number');
ylabel('Measurement end time (min)');

subplot(1,3,2);
plot(1:number_of_files, real_temp, 'ro');
xlabel('File number');
ylabel('Effective temperature (K)');

subplot(1,3,3);
plot(1:number_of_files, real_field, 'ro');
xlabel('File number');
ylabel('Effective H field (mT)');