function minimal()

globals;
loadEpochingConstants;
initialize();

manifest = loadManifest();
subjectCount = numel(manifest);

subjectResults = struct( ...
    ... % Bin number 1-4 of each kept trial, as a row vector with one value per kept trial
    'bins', cell(1, subjectCount), ...
    ... % ROI-average waveform of each kept trial, as a matrix with one row per kept trial and one column per time sample
    'data', []);

% Number of kept trials for each subject and bin, as a matrix with one row per subject and one column per bin
trialCountsPerSubjectAndBin = zeros(subjectCount, 4);

for subjectIndex = 1:subjectCount
    % Processing order follows Luck, "Order of processing steps", https://erpinfo.org/order-of-steps

    subjectId = manifest(subjectIndex).id;
    subjectFile = manifest(subjectIndex).file;
    itemsToExclude = manifest(subjectIndex).excludedItems;
    butterflyLog('================ %s (%s) ================', subjectId, subjectFile);

    subjectEEG = pop_loadcurry(subjectFile);
    channels = {subjectEEG.chanlocs.labels};
    butterflyLog('  loaded: %d ch, %g Hz, %d pnts (%.1f min), %d events', subjectEEG.nbchan, subjectEEG.srate, subjectEEG.pnts, subjectEEG.pnts / subjectEEG.srate / 60, numel(subjectEEG.event));

    subjectEEG = sanitizeEvents(subjectEEG);

    subjectEEG = excludeItems(subjectEEG, itemsToExclude);

    % Luck step 1: high-pass filter the continuous data
    subjectEEG = doHighPassFilter(subjectEEG);

    % Luck step 3: re-reference
    subjectEEG = doMastoidReferencing(subjectEEG);

    % Luck step 4: epoch the continuous data
    epochedEEG = doEpoching(subjectEEG);
    % Apply baseline correction
    epochedEEG = pop_rmbase(epochedEEG, baselineWindowMs);

    % Attempt to remove eye-based artifacts using ICA. Luck step 2 applies ICA to the continuous data
    % before epoching. Instead, we train it on the epochs, resulting in a faster process.
    epochedEEG = doICACleaning(subjectEEG, epochedEEG);

    % Now that we have the epochs, we can free subjectEEG
    clear subjectEEG

    epochCount = epochedEEG.trials;
    sampleTimePoints = epochedEEG.times;

    % Reject data, at the granularity of a single channel in a single epoch, that seem noisy
    % or contaminated by artifacts, using the Autoreject package (Jas et al. 2017). This departs
    % from Luck step 5, which rejects whole epochs. However, this is only an exploratory study.
    badChannelEpochs = getAutorejectMask(epochedEEG, subjectId);

    epochedEEG = doLowPassFilter(epochedEEG);

    % Average the ROI channels that were not rejected in each epoch, so each epoch may use a different subset of channels
    roiIndices = cellfun(@(label) find(strcmpi(channels, label), 1), roiChannels);
    roiData = nan(epochCount, numel(sampleTimePoints));
    for epochIndex = 1:epochCount
        usableROIIndices = roiIndices(~badChannelEpochs(roiIndices, epochIndex));
        if ~isempty(usableROIIndices)
            roiData(epochIndex, :) = mean(double(epochedEEG.data(usableROIIndices, :, epochIndex)), 1);
        end
    end

    % Bin number 1-4 of every epoch
    epochBins = zeros(1, epochCount);
    for epochIndex = 1:epochCount
        epochBins(epochIndex) = getEpochBin(epochedEEG, epochIndex);
    end

    % Keep an epoch when its ROI mean has at least one usable channel at every sample
    keepEpoch = all(isfinite(roiData), 2)';

    subjectResults(subjectIndex).bins = epochBins(keepEpoch);
    subjectResults(subjectIndex).data = roiData(keepEpoch, :);
    trialCountsPerSubjectAndBin(subjectIndex, :) = histcounts(epochBins(keepEpoch), 1:5);
    butterflyLog('  trials kept %d of %d, per bin %s', sum(keepEpoch), epochCount, mat2str(trialCountsPerSubjectAndBin(subjectIndex, :)));
    butterflyLog('  %s done', subjectId);
    butterflyLog('');
    clear epochedEEG
end

butterflyLog('================ cohort n=%d ================', subjectCount);
for subjectIndex = 1:subjectCount
    butterflyLog('  %-4s per bin %s total %d', manifest(subjectIndex).id, mat2str(trialCountsPerSubjectAndBin(subjectIndex, :)), sum(trialCountsPerSubjectAndBin(subjectIndex, :)));
end
dropSubject = any(trialCountsPerSubjectAndBin < minimumTrialsPerBin, 2)';
for subjectIndex = find(dropSubject)
    butterflyLog('  WARNING: %s has a bin with fewer than %d trials %s and is dropped from the grand average', manifest(subjectIndex).id, minimumTrialsPerBin, mat2str(trialCountsPerSubjectAndBin(subjectIndex, :)));
end

usedSubjects = find(~dropSubject);
usedCount = numel(usedSubjects);
butterflyLog('  grand average over %d of %d subjects; minimum trials in any used subject x bin: %d', usedCount, subjectCount, min(min(trialCountsPerSubjectAndBin(usedSubjects, :))));

% Luck step 6: average the single-trial epochs into single-subject ERP waveforms
sampleCount = numel(sampleTimePoints);
subjectMeans = zeros(4, sampleCount, usedCount);
for usedIndex = 1:usedCount
    subjectIndex = usedSubjects(usedIndex);
    bins = subjectResults(subjectIndex).bins;
    data = subjectResults(subjectIndex).data;
    for binIndex = 1:4
        subjectMeans(binIndex, :, usedIndex) = mean(data(bins == binIndex, :), 1);
    end
end
% Luck step 10: grand average across subjects
grandAverage = mean(subjectMeans, 3);

% Luck step 8: difference waves
% Calculate the difference waves
differenceWaves = [grandAverage(2, :) - grandAverage(1, :); grandAverage(4, :) - grandAverage(3, :)];

% Plot the difference waves
plotDifferenceWaves(differenceWaves, sampleTimePoints, usedCount);

butterflyLog('minimal.m done %s', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
end
