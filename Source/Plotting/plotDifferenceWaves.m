function plotDifferenceWaves(differenceWaves, sampleTimePoints, usedCount)

globals;
loadFilteringConstants;
loadRejectionConstants;
loadICAConstants;

waveColors = [0.45 0 0.6; 0 0.45 0.7];
waveNames = {'GA bin5 (RL-RH)', 'GA bin6 (NL-NH)'};
plotLimitsMs = [-200 800];
figureDpi = 130;
figureFile = fullfile(figureDir, sprintf('minimal_%s.png', roiName));

set(groot, 'DefaultFigureVisible', 'off');
figureHandle = figure('Color', 'w', 'Position', [40 40 1000 650]);
axisHandle = axes(figureHandle);
hold(axisHandle, 'on');
grid(axisHandle, 'on');
set(axisHandle, 'FontSize', 10);
plotRange = sampleTimePoints >= plotLimitsMs(1) & sampleTimePoints <= plotLimitsMs(2);
plottedValues = differenceWaves(:, plotRange);
yLimits = [min(plottedValues(:)) max(plottedValues(:))];
yLimits = yLimits + [-0.15 0.15] * diff(yLimits);
lineHandles = gobjects(1, 2);
for waveIndex = 1:2
    lineHandles(waveIndex) = plot(axisHandle, sampleTimePoints, differenceWaves(waveIndex, :), 'Color', waveColors(waveIndex, :), 'LineWidth', 1.6);
end
xline(axisHandle, 0, 'k-');
yline(axisHandle, 0, 'k-');
xlim(axisHandle, plotLimitsMs);
ylim(axisHandle, yLimits);
xlabel(axisHandle, 'ms');
ylabel(axisHandle, '\muV');
legend(axisHandle, lineHandles, waveNames, 'Location', 'northwest');
% title(axisHandle, sprintf('minimal.m: %s GA bin5 and bin6, 0.1-40 Hz, baseline -100..0, n=%d', roiName, usedCount), 'FontWeight', 'bold', 'FontSize', 14, 'Interpreter', 'none');
% subtitle(axisHandle, sprintf('Eye-only ICA (ICLabel Eye > %.1f, seeded); Autoreject channel x epoch labels mask the ROI mean. 40 Hz LP Butterworth order %d on trials.', eyeProbabilityMin, lowPassOrder), 'FontSize', 9, 'Interpreter', 'none');
exportgraphics(figureHandle, figureFile, 'Resolution', figureDpi);
close(figureHandle);
butterflyLog('FIGURE: %s', figureFile);
end
