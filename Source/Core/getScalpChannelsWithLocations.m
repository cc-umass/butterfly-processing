function result = getScalpChannelsWithLocations(eeg)

globals;

channels = {eeg.chanlocs.labels};
isLocated = ~cellfun(@isempty, {eeg.chanlocs.X});
isPeripheral = ismember(upper(channels), peripheralChannels);
result = find(isLocated & ~isPeripheral);
end
