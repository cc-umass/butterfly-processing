function test = runStudy(manifestFile)

manifest = jsondecode(fileread(manifestFile));
subjects = manifest.Subjects;
subjectCount = numel(subjects);

for subjectIndex = 1:subjectCount
    subject = subjects(subjectIndex);
    result = processSubject(subject.file, subject.listMapFile);
    conditionWavesBySubject(subjectIndex, :, :) = averageSubject(result, subject.incorrectItems);
end

test = testInteraction(conditionWavesBySubject, result.sampleTimePoints);
plotDifferenceWaves(conditionWavesBySubject, result.sampleTimePoints);
end

function plotDifferenceWaves(conditionWavesBySubject, sampleTimePoints)
grandAverage = squeeze(mean(conditionWavesBySubject, 1));
frequencyEffectWithReadjustment = grandAverage(2, :) - grandAverage(1, :);
frequencyEffectWithoutReadjustment = grandAverage(4, :) - grandAverage(3, :);

plot(sampleTimePoints, frequencyEffectWithReadjustment);
hold on
plot(sampleTimePoints, frequencyEffectWithoutReadjustment);
xline(0);
yline(0);
xlim([-200 800]);
xlabel('ms');
ylabel('µV');
legend({'readjust: low - high', 'no readjust: low - high'});
end
