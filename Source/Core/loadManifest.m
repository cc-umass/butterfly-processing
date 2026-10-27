function manifest = loadManifest()

globals;

manifest = jsondecode(fileread(manifestFile));
subjectCount = numel(manifest);
for subjectIndex = 1:subjectCount
    items = manifest(subjectIndex).excludedItems(:)';
    assert(all(items == round(items)) && all(items >= 1 & items <= 120), '%s: excludedItems must be integers 1-120', manifest(subjectIndex).id);
    assert(numel(unique(items)) == numel(items), '%s: duplicate excludedItems', manifest(subjectIndex).id);
    manifest(subjectIndex).excludedItems = items;
end
assert(numel(unique({manifest.id})) == subjectCount, 'duplicate ids in manifest');
butterflyLog('%d subjects: %s', subjectCount, strjoin({manifest.id}, ' '));
end
