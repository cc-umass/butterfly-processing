function result = getEpochBin(epochedEEG, epochIndex)

epoch = epochedEEG.epoch(epochIndex);
latencies = epoch.eventlatency;
if iscell(latencies), latencies = cell2mat(latencies); end
bins = epoch.eventbini;
if ~iscell(bins), bins = {bins}; end
result = bins{latencies == 0}(1);
end
