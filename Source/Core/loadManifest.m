function manifest = loadManifest()

globals;

manifest = jsondecode(fileread(manifestFile));
if ~any(strcmp(manifest.RejectionStrategy, {'ChannelInEpoch', 'WholeEpoch'}))
    error('RejectionStrategy must be ChannelInEpoch or WholeEpoch, not %s', manifest.RejectionStrategy);
end

subjectCount = numel(manifest.Subjects);
for subjectIndex = 1:subjectCount
    items = manifest.Subjects(subjectIndex).excludedItems(:);
    manifest.Subjects(subjectIndex).excludedItems = items;
end

butterflyLog('%d subjects: %s; rejection strategy %s', subjectCount, strjoin({manifest.Subjects.id}, ' '), manifest.RejectionStrategy);
end
