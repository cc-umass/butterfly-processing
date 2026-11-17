function test = testInteraction(conditionWavesBySubject, sampleTimePoints)

constants;

inWindow = sampleTimePoints >= analysisWindowMs(1) & sampleTimePoints <= analysisWindowMs(2);
windowMeans = squeeze(mean(conditionWavesBySubject(:, :, inWindow), 3));

readjustHigh = windowMeans(:, 1);
readjustLow = windowMeans(:, 2);
noReadjustHigh = windowMeans(:, 3);
noReadjustLow = windowMeans(:, 4);

frequencyEffectWithReadjustment = readjustLow - readjustHigh;
frequencyEffectWithoutReadjustment = noReadjustLow - noReadjustHigh;
interaction = frequencyEffectWithReadjustment - frequencyEffectWithoutReadjustment;

[~, pValue, ~, statistics] = ttest(interaction);

test = struct();
test.meanMicrovolts = mean(interaction);
test.t = statistics.tstat;
test.degreesOfFreedom = statistics.df;
test.p = pValue;
test.subjectsWithPositiveInteraction = sum(interaction > 0);
end
