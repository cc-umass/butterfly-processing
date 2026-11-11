function sectionDryRun()

globals;
initialize();

manifest = loadManifest();
subjects = selectSubjects(manifest.Subjects);
if ~exist(sectionDir, 'dir'), mkdir(sectionDir); end

for subjectIndex = 1:numel(subjects)
    subjectId = subjects(subjectIndex).id;
    subjectFile = subjects(subjectIndex).file;
    butterflyLog('================ %s (%s) ================', subjectId, subjectFile);
    subjectEEG = pop_loadcurry(subjectFile);
    subjectEEG = sanitizeEvents(subjectEEG);
    sections = findSectionBadChannels(subjectEEG, subjectId, subjectFile);
    clear subjectEEG
    writeSectionTable(sections, fullfile(sectionDir, [subjectId '_sections.csv']));
end

butterflyLog('sectionDryRun done %s', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
end

function writeSectionTable(sections, tableFile)
globals;
labels = sections.channelLabels(:);
sectionTable = table(labels, 'VariableNames', {'channel'});
for sectionIndex = 1:sectionCount
    sectionTable.(sprintf('section%d', sectionIndex)) = double(sections.badChannels(:, sectionIndex));
end
writetable(sectionTable, tableFile);
end
