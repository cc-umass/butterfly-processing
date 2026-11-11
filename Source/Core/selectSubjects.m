function subjects = selectSubjects(subjects)

requested = getenv('BUTTERFLY_SUBJECTS');
if isempty(requested)
    return
end
requestedIds = strsplit(requested, ',');
subjects = subjects(ismember({subjects.id}, requestedIds));
end
