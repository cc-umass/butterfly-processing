function subjectEEG = sanitizeEvents(subjectEEG)

globals;

assert(all(cellfun(@isnumeric, {subjectEEG.event.type})), 'non-numeric event code found');
eventCodes = [subjectEEG.event.type];

% Drop any events that are not in the validEventCodes global
keepEvent = ismember(eventCodes, validEventCodes);
subjectEEG.event = subjectEEG.event(keepEvent);
butterflyLog('  events: dropped %d non-experimental, kept %d', sum(~keepEvent), sum(keepEvent));

% Let EEGLab also do a run at sanitizing the dataset
subjectEEG = eeg_checkset(subjectEEG, 'eventconsistency');
end
