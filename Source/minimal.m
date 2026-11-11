function minimal()

globals;
loadEpochingConstants;
initialize();

manifest = loadManifest();
subjects = selectSubjects(manifest.Subjects);
subjectCount = numel(subjects);

for subjectIndex = 1:subjectCount
    % Processing order follows Luck, "Order of processing steps", https://erpinfo.org/order-of-steps

    subjectId = subjects(subjectIndex).id;
    subjectFile = subjects(subjectIndex).file;
    itemsToExclude = subjects(subjectIndex).excludedItems;
    resultFile = fullfile(intermediateDir, [subjectId '_result.mat']);
    if exist(resultFile, 'file')
        butterflyLog('================ %s: result cached ================', subjectId);
        continue
    end
    butterflyLog('================ %s (%s) ================', subjectId, subjectFile);

    subjectEEG = pop_loadcurry(subjectFile);
    channels = {subjectEEG.chanlocs.labels};
    butterflyLog('  loaded: %d ch, %g Hz, %d pnts (%.1f min), %d events', subjectEEG.nbchan, subjectEEG.srate, subjectEEG.pnts, subjectEEG.pnts / subjectEEG.srate / 60, numel(subjectEEG.event));

    subjectEEG = sanitizeEvents(subjectEEG);

    sections = findSectionBadChannels(subjectEEG, subjectId, subjectFile);
    mastoidIndices = find(ismember(upper(channels), mastoidChannels));
    if any(sections.badChannels(mastoidIndices, :), 'all')
        butterflyLog('  EXCLUDED: mastoid bad in a section');
        result = struct('excluded', true, 'sections', sections);
        save(resultFile, '-struct', 'result');
        clear subjectEEG
        continue
    end

    subjectEEG = excludeItems(subjectEEG, itemsToExclude);

    % Luck step 1: high-pass filter the continuous data
    subjectEEG = doHighPassFilter(subjectEEG);

    % Luck step 3: re-reference
    subjectEEG = doMastoidReferencing(subjectEEG);

    % Luck step 4: epoch the continuous data
    epochedEEG = doEpoching(subjectEEG);
    % Apply baseline correction
    epochedEEG = pop_rmbase(epochedEEG, baselineWindowMs);

    epochSection = getEpochSections(subjectEEG, epochedEEG, sections, itemsToExclude);

    icaExcludedChannels = find(any(sections.badChannels, 2))';
    [epochedEEG, icaInfo] = doICACleaning(subjectEEG, epochedEEG, icaExcludedChannels);

    clear subjectEEG

    rejectionEEG = interpolateSectionBadCells(epochedEEG, sections.badChannels, epochSection);
    badChannelEpochs = getAutorejectMask(rejectionEEG, subjectId);
    clear rejectionEEG

    epochedEEG = doLowPassFilter(epochedEEG);

    epochCount = epochedEEG.trials;
    epochBins = zeros(1, epochCount);
    for epochIndex = 1:epochCount
        epochBins(epochIndex) = getEpochBin(epochedEEG, epochIndex);
    end

    keptLabels = unique([roiChannels electrodeLabels], 'stable');
    keptIndices = cellfun(@(label) find(strcmpi(channels, label), 1), keptLabels);

    result = struct();
    result.excluded = false;
    result.sections = sections;
    result.channelLabels = keptLabels;
    result.bins = epochBins;
    result.epochSection = epochSection;
    result.data = single(epochedEEG.data(keptIndices, :, :));
    result.badCells = badChannelEpochs(keptIndices, :);
    result.sectionBad = sections.badChannels(keptIndices, :);
    result.sampleTimePoints = epochedEEG.times;
    result.icaInfo = icaInfo;
    save(resultFile, '-struct', 'result');
    butterflyLog('  epochs %d; Autoreject cells bad on kept channels %.1f%%', epochCount, 100 * mean(result.badCells, 'all'));
    butterflyLog('  %s done', subjectId);
    butterflyLog('');
    clear epochedEEG
end

butterflyLog('minimal.m done %s', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
end
