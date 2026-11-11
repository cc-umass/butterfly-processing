%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Directories
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rootDir = fileparts(fileparts(mfilename('fullpath')));
eeglabDir = 'C:\Users\ccooley\eeglab2026.0.0';

buildDir = fullfile(rootDir, 'Build');
intermediateDir = fullfile(buildDir, 'Intermediate');
figureDir = fullfile(buildDir, 'Figures');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Contains the location of each .cdt file and the trials we want to exclude
manifestFile = fullfile(rootDir, 'Data', 'manifest.json');
runName = getenv('BUTTERFLY_RUN');
if isempty(runName), runName = 'minimal'; end
% Where we will write the BDF file needed for our analysis
binDescriptorFile = fullfile(intermediateDir, ['Butterfly_BDF_' runName '.txt']);
logFile = fullfile(buildDir, [runName '.log']);
listMapDir = 'D:\butterfly-eeg\Config\list_maps';
sectionDir = fullfile(buildDir, 'SectionChannels');
waveDir = fullfile(buildDir, 'Waves');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ERP data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

validEventCodes = [1:120, 201:204, 210, 220, 230, 240];
pictureCodes = [201 202 203 204];
minimumTrialsPerBin = 1;
sectionSize = 24;
sectionCount = 5;
sectionPaddingSeconds = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Channel groups
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

peripheralChannels = {'VEOG', 'HEOG', 'EKG', 'EMG', 'TRIGGER'};
mastoidChannels = {'M1', 'M2'};
excludeSubjectsWithBadMastoid = false;
roiName = 'CP';
roiChannels = {'CPZ', 'PZ', 'CP3', 'CP4', 'P3', 'P4'};
electrodeLabels = {'F3', 'FZ', 'F4', 'C3', 'CZ', 'C4', 'P3', 'PZ', 'P4'};
