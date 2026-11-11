function result = interpolateSectionBadCells(epochedEEG, badChannels, epochSection)

globals;

scalpIndices = getScalpChannelsWithLocations(epochedEEG);
result = epochedEEG;
for sectionIndex = 1:sectionCount
    badIndices = find(badChannels(:, sectionIndex))';
    epochIndices = find(epochSection == sectionIndex);
    if isempty(badIndices) || isempty(epochIndices)
        continue
    end
    goodIndices = setdiff(scalpIndices, badIndices, 'stable');
    subsetEEG = pop_select(epochedEEG, 'trial', epochIndices);
    result.data(badIndices, :, epochIndices) = interpolateChannels(subsetEEG, goodIndices, badIndices);
end
end
