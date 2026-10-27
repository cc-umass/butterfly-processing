function minimal()

globals;
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
    % Here we do ...; this workflow aligns with ... citation ...

    subjectId = manifest(subjectIndex).id;
    subjectFile = manifest(subjectIndex).file;
    itemsToExclude = manifest(subjectIndex).excludedItems;
    butterflyLog('================ %s (%s) ================', subjectId, subjectFile);

    subjectEEG = pop_loadcurry(subjectFile);
    channels = {subjectEEG.chanlocs.labels};
    butterflyLog('  loaded: %d ch, %g Hz, %d pnts (%.1f min), %d events', subjectEEG.nbchan, subjectEEG.srate, subjectEEG.pnts, subjectEEG.pnts / subjectEEG.srate / 60, numel(subjectEEG.event));

    subjectEEG = sanitizeEvents(subjectEEG);

    subjectEEG = excludeItems(subjectEEG, itemsToExclude);

    subjectEEG = doHighPassFilter(subjectEEG);

    subjectEEG = doMastoidReferencing(subjectEEG);

    epochedEEG = doEpoching(subjectEEG);

    % Now that we have the epochs, we can free subjectEEG
    clear subjectEEG

    epochCount = epochedEEG.trials;
    sampleTimePoints = epochedEEG.times;

    [ptpRejected, maskedChannels] = doPeakToPeakRejection(epochedEEG);
    rejectedEpochs = doStepRejection(epochedEEG) | ptpRejected;
    butterflyLog('  rejected %d of %d epochs (%.1f%%)', sum(rejectedEpochs), epochCount, 100 * sum(rejectedEpochs) / epochCount);

    epochedEEG = doLowPassFilter(epochedEEG);

    % Extract data for just the ROI channels that are not masked for this subject
    usedRoiChannels = setdiff(upper(roiChannels), upper(maskedChannels), 'stable');
    butterflyLog('  ROI channels used %d of %d', numel(usedRoiChannels), numel(roiChannels));
    roiIndices = cellfun(@(label) find(strcmpi(channels, label), 1), usedRoiChannels);
    roiData = squeeze(mean(epochedEEG.data(roiIndices, :, :), 1))';

    % Bin number 1-4 of every epoch
    epochBins = zeros(1, epochCount);
    for epochIndex = 1:epochCount
        epochBins(epochIndex) = getEpochBin(epochedEEG, epochIndex);
    end

    % Keep an epoch when neither rejection test flagged it and its ROI data samples are all finite
    keepEpoch = ~rejectedEpochs & all(isfinite(roiData), 2)';

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
grandAverage = mean(subjectMeans, 3);

% Calculate the difference waves
differenceWaves = [grandAverage(2, :) - grandAverage(1, :); grandAverage(4, :) - grandAverage(3, :)];

% Plot the difference waves
plotDifferenceWaves(differenceWaves, sampleTimePoints, usedCount);

butterflyLog('minimal.m done %s', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
end
