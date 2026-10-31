"""Autoreject (Jas et al. 2017) channel x epoch labels for one subject."""
import sys
import numpy as np
import mne
from scipy.io import loadmat, savemat
from autoreject import compute_thresholds

inputFile, outputFile, randomState = sys.argv[1], sys.argv[2], int(sys.argv[3])
matFile = loadmat(inputFile)

# Convert EEGLAB data in microvolts to volts
channelData = matFile["channelData"].astype(float) * 1e-6
# Get a list of channel labels as a list of strings
channelLabels = [str(label[0]) for label in matFile["channelLabels"].ravel()]
sampleRate = float(matFile["sampleRate"].ravel()[0])
epochStartSeconds = float(matFile["epochStartSeconds"].ravel()[0])

# Convert EEGLAB channel positions to a form MNE accepts
channelPositions = matFile["channelPositions"].astype(float)
channelPositionsMNE = np.column_stack([-channelPositions[:, 1], channelPositions[:, 0], channelPositions[:, 2]]) / 1000.0

# Build the MNE epochs object that Autoreject takes
montage = mne.channels.make_dig_montage(ch_pos=dict(zip(channelLabels, channelPositionsMNE)), coord_frame="head")
info = mne.create_info(channelLabels, sampleRate, ch_types="eeg")
epochs = mne.EpochsArray(np.transpose(channelData, (2, 0, 1)), info, tmin=epochStartSeconds, verbose="error")
epochs.set_montage(montage)

# Learn a peak-to-peak threshold for each channel (Jas et al. 2017)
thresholdByLabel = compute_thresholds(epochs.copy(), method="bayesian_optimization", random_state=randomState, picks=None, augment=True, verbose=False, n_jobs=1)
thresholdsInChannelOrder = np.array([thresholdByLabel[label] for label in channelLabels])
thresholdsUv = thresholdsInChannelOrder * 1e6

# Apply the threshold to determine the bad channel x epoch cells
peakToPeak = np.ptp(epochs.get_data(), axis=-1).T
badCells = (peakToPeak > thresholdsInChannelOrder[:, np.newaxis]).astype(float)

savemat(outputFile, {"badCells": badCells, "thresholdsUv": thresholdsUv})
print(f"autoreject: thresholds {thresholdsUv.min():.0f}-{thresholdsUv.max():.0f} uV, {np.mean(badCells > 0) * 100:.1f}% cells bad")
