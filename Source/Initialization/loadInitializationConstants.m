% Bin labels written to the BDF file, one per bin code, same order
binNames = {'readjust-high', 'readjust-low', 'no-readjust-high', 'no-readjust-low'};
binCodes = [201 202 203 204];

% Functions we need to make sure EEGLab makes available
requiredFunctions = {'pop_basicfilter', 'pop_loadcurry'};
