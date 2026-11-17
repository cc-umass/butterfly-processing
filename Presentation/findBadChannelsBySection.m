function sections = findBadChannelsBySection(continuousEEG, listMapFile)

constants;

listMap = readtable(listMapFile);
positionOfItem = zeros(1, 120);
positionOfItem(listMap.itemTrigger) = listMap.position;

eventCodes = [continuousEEG.event.type];
eventSamples = [continuousEEG.event.latency];
pictureEvents = find(ismember(eventCodes, pictureCodes));
pictureItem = eventCodes(pictureEvents + 1);
pictureSample = eventSamples(pictureEvents);
pictureSection = ceil(positionOfItem(pictureItem) / trialsPerSection);

scalpIndices = scalpChannels(continuousEEG);
detectionEEG = pop_select(continuousEEG, 'channel', scalpIndices);
detectionEEG = pop_reref(detectionEEG, []);
detectionEEG = pop_basicfilter(detectionEEG, 1:detectionEEG.nbchan, ...
    'Filter', 'highpass', ...
    'Design', 'butter', ...
    'Cutoff', 1, ...
    'Order', 2, ...
    'RemoveDC', 'on');

badChannels = false(continuousEEG.nbchan, sectionCount);
paddingSamples = round(sectionPaddingSeconds * continuousEEG.srate);
for sectionIndex = 1:sectionCount
    inSection = pictureSection == sectionIndex;
    firstSample = max(1, min(pictureSample(inSection)) - paddingSamples);
    lastSample = min(continuousEEG.pnts, max(pictureSample(inSection)) + paddingSamples);
    sectionEEG = pop_select(detectionEEG, 'point', [firstSample lastSample]);
    sectionEEG = clean_artifacts(sectionEEG, ...
        'FlatlineCriterion', 5, ...
        'ChannelCriterion', 0.8, ...
        'LineNoiseCriterion', 4, ...
        'Highpass', 'off', ...
        'BurstCriterion', 'off', ...
        'WindowCriterion', 'off', ...
        'BurstRejection', 'off');
    channelWasKept = sectionEEG.etc.clean_channel_mask(:)';
    badChannels(scalpIndices(~channelWasKept), sectionIndex) = true;
end

sections = struct();
sections.badChannels = badChannels;
sections.pictureItem = pictureItem;
sections.pictureSection = pictureSection;
end

function indices = scalpChannels(eeg)
constants;
hasLocation = ~cellfun(@isempty, {eeg.chanlocs.X});
isPeripheral = ismember(upper({eeg.chanlocs.labels}), peripheralChannels);
indices = find(hasLocation & ~isPeripheral);
end
