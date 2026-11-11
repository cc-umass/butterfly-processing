function epochSection = getEpochSections(subjectEEG, epochedEEG, sections, itemsToExclude)

globals;

eventCodes = [subjectEEG.event.type];
pictureEventCodes = eventCodes(ismember(eventCodes, pictureCodes));
isKept = ~ismember(sections.pictureItem, itemsToExclude);
keptSections = sections.pictureSection(isKept);
if numel(keptSections) ~= numel(pictureEventCodes) || numel(keptSections) ~= epochedEEG.trials
    error('section mapping: %d kept pictures, %d picture events, %d epochs', numel(keptSections), numel(pictureEventCodes), epochedEEG.trials);
end
for epochIndex = 1:epochedEEG.trials
    if getEpochBin(epochedEEG, epochIndex) ~= pictureEventCodes(epochIndex) - 200
        error('section mapping: bin mismatch at epoch %d', epochIndex);
    end
end
epochSection = keptSections;
end
