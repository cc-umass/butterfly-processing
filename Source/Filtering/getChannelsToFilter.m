function result = getChannelsToFilter(eeg)

% We are going to do filtering on all of the channels except the one in which the events are sent
channels = {eeg.chanlocs.labels};
result = find(~strcmpi(channels, 'TRIGGER'));
end
