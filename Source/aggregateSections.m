function aggregateSections()

globals;
initialize();

manifest = loadManifest();
subjects = manifest.Subjects;
subjectCount = numel(subjects);
electrodeCount = numel(electrodeLabels);

sampleTimePoints = [];
roiMeans = [];
electrodeMeans = [];
roiTrialCounts = zeros(subjectCount, 4);
electrodeTrialCounts = zeros(subjectCount, electrodeCount, 4);
subjectStatus = repmat({''}, subjectCount, 1);

for subjectIndex = 1:subjectCount
    subjectId = subjects(subjectIndex).id;
    resultFile = fullfile(intermediateDir, [subjectId '_result.mat']);
    if ~exist(resultFile, 'file')
        subjectStatus{subjectIndex} = 'missing';
        butterflyLog('  %-4s missing result', subjectId);
        continue
    end
    result = load(resultFile);
    if result.excluded
        subjectStatus{subjectIndex} = 'excluded (mastoid)';
        butterflyLog('  %-4s excluded: mastoid bad in a section', subjectId);
        continue
    end
    if isempty(sampleTimePoints)
        sampleTimePoints = result.sampleTimePoints;
        sampleCount = numel(sampleTimePoints);
        roiMeans = nan(4, sampleCount, subjectCount);
        electrodeMeans = nan(electrodeCount, 4, sampleCount, subjectCount);
    end

    roiPositions = cellfun(@(label) find(strcmpi(result.channelLabels, label), 1), roiChannels);
    electrodePositions = cellfun(@(label) find(strcmpi(result.channelLabels, label), 1), electrodeLabels);
    epochCount = numel(result.bins);
    roiKeep = false(1, epochCount);
    roiData = nan(epochCount, sampleCount);
    electrodeKeep = false(electrodeCount, epochCount);
    for epochIndex = 1:epochCount
        sectionIndex = result.epochSection(epochIndex);
        if sectionIndex >= 1
            sectionBad = result.sectionBad(:, sectionIndex);
        else
            sectionBad = false(numel(result.channelLabels), 1);
        end
        usableROIPositions = roiPositions(~sectionBad(roiPositions));
        roiClean = ~isempty(usableROIPositions) && ~any(result.badCells(usableROIPositions, epochIndex));
        roiKeep(epochIndex) = roiClean;
        if roiClean
            roiData(epochIndex, :) = mean(double(result.data(usableROIPositions, :, epochIndex)), 1);
        end
        for electrodeIndex = 1:electrodeCount
            position = electrodePositions(electrodeIndex);
            electrodeKeep(electrodeIndex, epochIndex) = roiClean && ~sectionBad(position) && ~result.badCells(position, epochIndex);
        end
    end

    roiTrialCounts(subjectIndex, :) = histcounts(result.bins(roiKeep), 1:5);
    if all(roiTrialCounts(subjectIndex, :) >= minimumTrialsPerBin)
        for binIndex = 1:4
            roiMeans(binIndex, :, subjectIndex) = mean(roiData(roiKeep & result.bins == binIndex, :), 1);
        end
    end
    for electrodeIndex = 1:electrodeCount
        keep = electrodeKeep(electrodeIndex, :);
        electrodeTrialCounts(subjectIndex, electrodeIndex, :) = histcounts(result.bins(keep), 1:5);
        if all(electrodeTrialCounts(subjectIndex, electrodeIndex, :) >= minimumTrialsPerBin)
            for binIndex = 1:4
                selected = keep & result.bins == binIndex;
                electrodeMeans(electrodeIndex, binIndex, :, subjectIndex) = mean(double(reshape(result.data(electrodePositions(electrodeIndex), :, selected), sampleCount, [])), 2);
            end
        end
    end
    subjectStatus{subjectIndex} = 'used';
    sectionText = cell(1, sectionCount);
    for sectionIndex = 1:sectionCount
        sectionText{sectionIndex} = strjoin(result.sections.channelLabels(result.sections.badChannels(:, sectionIndex)), '+');
    end
    butterflyLog('  %-4s ROI trials per bin %s of %d epochs; section-bad channels %s; ICA excluded %s; eye [%s]', subjectId, mat2str(roiTrialCounts(subjectIndex, :)), epochCount, ...
        strjoin(sectionText, ' | '), strjoin(result.icaInfo.excludedChannels, ' '), int2str(result.icaInfo.eyeComponents));
end

usedROI = squeeze(all(isfinite(roiMeans(:, 1, :)), 1));
roiGrandAverage = mean(roiMeans(:, :, usedROI), 3);
roiWaves = [roiGrandAverage(2, :) - roiGrandAverage(1, :); roiGrandAverage(4, :) - roiGrandAverage(3, :)];
butterflyLog('ROI %s: n=%d, trials %d', roiName, sum(usedROI), sum(roiTrialCounts(usedROI, :), 'all'));

electrodeWaves = zeros(electrodeCount, 2, numel(sampleTimePoints));
electrodeUsedCounts = zeros(1, electrodeCount);
for electrodeIndex = 1:electrodeCount
    means = squeeze(electrodeMeans(electrodeIndex, :, :, :));
    used = squeeze(all(isfinite(means(:, 1, :)), 1));
    electrodeUsedCounts(electrodeIndex) = sum(used);
    grandAverage = mean(means(:, :, used), 3);
    electrodeWaves(electrodeIndex, :, :) = [grandAverage(2, :) - grandAverage(1, :); grandAverage(4, :) - grandAverage(3, :)];
    butterflyLog('%-3s n=%d, trials %d', electrodeLabels{electrodeIndex}, sum(used), sum(electrodeTrialCounts(used, electrodeIndex, :), 'all'));
end

plotSectionFigures(roiWaves, electrodeWaves, sampleTimePoints);

if ~exist(waveDir, 'dir'), mkdir(waveDir); end
subjectIds = {subjects.id};
save(fullfile(waveDir, 'SECTION_CHANNELS.mat'), 'roiWaves', 'electrodeWaves', 'electrodeUsedCounts', 'roiTrialCounts', 'electrodeTrialCounts', ...
    'sampleTimePoints', 'electrodeLabels', 'subjectIds', 'subjectStatus', 'usedROI', '-v7');
butterflyLog('aggregateSections done %s', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
end
