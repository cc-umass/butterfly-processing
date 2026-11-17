pictureCodes = [201 202 203 204];
binNames = {'readjust-high', 'readjust-low', 'no-readjust-high', 'no-readjust-low'};

sectionCount = 5;
trialsPerSection = 24;
sectionPaddingSeconds = 3;

peripheralChannels = {'VEOG', 'HEOG', 'EKG', 'EMG', 'TRIGGER'};
mastoidChannels = {'M1', 'M2'};
roiChannels = {'CPZ', 'PZ', 'CP3', 'CP4', 'P3', 'P4'};

% Luck, "Order of processing steps," https://erpinfo.org/order-of-steps
highPassHz = 0.1;
highPassOrder = 2;

% Setting borrowed from the UMD/Ellen Lau compute_erp.m script
lowPassHz = 40;
lowPassOrder = 2;

epochWindowMs = [-700 1300];
baselineWindowMs = [-100 0];

% Filter settings for the ICA training copy, from Luck, Applied Event-Related Potential Data Analysis, 2022
icaTrainingBandHz = [1 30];
icaTrainingFilterOrder = 8;
eyeProbabilityMin = 0.8;

autorejectRandomState = 0;

analysisWindowMs = [300 350];
