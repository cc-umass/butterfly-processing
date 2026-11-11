function sections = findSectionBadChannels(subjectEEG, subjectId, subjectFile)

globals;

cacheFile = fullfile(intermediateDir, [subjectId '_sections.mat']);
if exist(cacheFile, 'file')
    loaded = load(cacheFile);
    sections = loaded.sections;
    butterflyLog('  sections: loaded from cache');
    return
end

listName = regexp(subjectFile, 'List([A-D])', 'tokens', 'once');
listMap = readtable(fullfile(listMapDir, ['List' listName{1} '_v2.csv']));
positionOfItem = zeros(1, 120);
positionOfItem(listMap.itemTrigger) = listMap.position;

eventCodes = [subjectEEG.event.type];
eventLatencies = [subjectEEG.event.latency];
pictureIndices = find(ismember(eventCodes, pictureCodes));
pictureCount = numel(pictureIndices);
pictureItem = zeros(1, pictureCount);
for pictureIndex = 1:pictureCount
    nextIndex = pictureIndices(pictureIndex) + 1;
    if nextIndex <= numel(eventCodes) && eventCodes(nextIndex) >= 1 && eventCodes(nextIndex) <= 120
        pictureItem(pictureIndex) = eventCodes(nextIndex);
    end
end
pictureLatency = eventLatencies(pictureIndices);
picturePosition = zeros(1, pictureCount);
hasItem = pictureItem > 0;
picturePosition(hasItem) = positionOfItem(pictureItem(hasItem));
pictureSection = ceil(picturePosition / sectionSize);

orderBreaks = sum(diff(picturePosition(hasItem)) <= 0);
pictureGaps = diff(pictureLatency) / subjectEEG.srate;
boundaryGaps = nan(1, sectionCount - 1);
for boundaryIndex = 1:sectionCount - 1
    lastBefore = find(pictureSection == boundaryIndex, 1, 'last');
    if ~isempty(lastBefore) && lastBefore < pictureCount && pictureSection(lastBefore + 1) == boundaryIndex + 1
        boundaryGaps(boundaryIndex) = pictureGaps(lastBefore);
    end
end

scalpIndices = getScalpChannelsWithLocations(subjectEEG);
channelLabels = {subjectEEG.chanlocs.labels};
detectionEEG = pop_select(subjectEEG, 'channel', scalpIndices);
detectionEEG = pop_reref(detectionEEG, []);
detectionEEG = pop_basicfilter(detectionEEG, 1:detectionEEG.nbchan, ...
    'Filter', 'highpass', ...
    'Design', 'butter', ...
    'Cutoff', 1, ...
    'Order', 2, ...
    'RemoveDC', 'on', ...
    'Boundary', []);

badChannels = false(subjectEEG.nbchan, sectionCount);
sectionMinutes = zeros(1, sectionCount);
sectionTrials = zeros(1, sectionCount);
paddingSamples = round(sectionPaddingSeconds * subjectEEG.srate);
for sectionIndex = 1:sectionCount
    inSection = pictureSection == sectionIndex;
    sectionTrials(sectionIndex) = sum(inSection);
    if ~any(inSection)
        continue
    end
    firstSample = max(1, round(min(pictureLatency(inSection))) - paddingSamples);
    lastSample = min(subjectEEG.pnts, round(max(pictureLatency(inSection))) + paddingSamples);
    sectionMinutes(sectionIndex) = (lastSample - firstSample + 1) / subjectEEG.srate / 60;
    sectionEEG = pop_select(detectionEEG, 'point', [firstSample lastSample]);
    sectionEEG = clean_artifacts(sectionEEG, ...
        'FlatlineCriterion', 5, ...
        'ChannelCriterion', 0.8, ...
        'LineNoiseCriterion', 4, ...
        'Highpass', 'off', ...
        'BurstCriterion', 'off', ...
        'WindowCriterion', 'off', ...
        'BurstRejection', 'off');
    if isfield(sectionEEG.etc, 'clean_channel_mask')
        keptMask = sectionEEG.etc.clean_channel_mask(:)';
        badChannels(scalpIndices(~keptMask), sectionIndex) = true;
    end
end

sections = struct();
sections.channelLabels = channelLabels;
sections.badChannels = badChannels;
sections.sectionMinutes = sectionMinutes;
sections.sectionTrials = sectionTrials;
sections.pictureItem = pictureItem;
sections.pictureSection = pictureSection;
sections.orderBreaks = orderBreaks;
sections.boundaryGapSeconds = boundaryGaps;
sections.medianGapSeconds = median(pictureGaps);
save(cacheFile, 'sections');

for sectionIndex = 1:sectionCount
    butterflyLog('  section %d: %d trials, %.1f min, bad channels %s', sectionIndex, sectionTrials(sectionIndex), sectionMinutes(sectionIndex), strjoin(channelLabels(badChannels(:, sectionIndex)), ' '));
end
butterflyLog('  sections: order breaks %d, boundary gaps %s s, median gap %.1f s', orderBreaks, mat2str(round(boundaryGaps, 1)), sections.medianGapSeconds);
end
