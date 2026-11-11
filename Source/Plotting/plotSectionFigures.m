function plotSectionFigures(roiWaves, electrodeWaves, sampleTimePoints)

globals;

waveColors = [0.45 0 0.6; 0 0.45 0.7];
waveNames = {'GA bin5 (RL-RH)', 'GA bin6 (NL-NH)'};
plotLimitsMs = [-200 800];
plotRange = sampleTimePoints >= plotLimitsMs(1) & sampleTimePoints <= plotLimitsMs(2);
plottedValues = [reshape(roiWaves(:, plotRange), 1, []) reshape(electrodeWaves(:, :, plotRange), 1, [])];
yLimits = [min(plottedValues) max(plottedValues)];
yLimits = yLimits + [-0.05 0.05] * diff(yLimits);
set(groot, 'DefaultFigureVisible', 'off');

figureHandle = figure('Color', 'w', 'Position', [40 40 1000 650]);
axisHandle = axes(figureHandle);
drawWaves(axisHandle, roiWaves, sampleTimePoints, waveColors, waveNames, plotLimitsMs, yLimits, true);
title(axisHandle, sprintf('BIN 5 AND BIN 6 (%s ROI)', roiName), 'FontWeight', 'bold', 'FontSize', 14, 'Interpreter', 'none');
figureFile = fullfile(figureDir, sprintf('SECTIONS_%s_ROI.png', roiName));
exportgraphics(figureHandle, figureFile, 'Resolution', 130);
close(figureHandle);
butterflyLog('FIGURE: %s', figureFile);

figureHandle = figure('Color', 'w', 'Position', [40 40 1500 1050]);
layout = tiledlayout(figureHandle, 3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
for electrodeIndex = 1:numel(electrodeLabels)
    axisHandle = nexttile(layout, electrodeIndex);
    drawWaves(axisHandle, squeeze(electrodeWaves(electrodeIndex, :, :)), sampleTimePoints, waveColors, waveNames, plotLimitsMs, yLimits, electrodeIndex == 1);
    title(axisHandle, electrodeLabels{electrodeIndex}, 'FontWeight', 'bold', 'FontSize', 12, 'Interpreter', 'none');
end
title(layout, 'BIN 5 AND BIN 6 (SECTION CHANNELS)', 'FontWeight', 'bold', 'FontSize', 16, 'Interpreter', 'none');
figureFile = fullfile(figureDir, 'SECTIONS_COLLAGE.png');
exportgraphics(figureHandle, figureFile, 'Resolution', 130);
close(figureHandle);
butterflyLog('FIGURE: %s', figureFile);
end

function drawWaves(axisHandle, waves, sampleTimePoints, waveColors, waveNames, plotLimitsMs, yLimits, showLegend)
hold(axisHandle, 'on');
grid(axisHandle, 'on');
set(axisHandle, 'FontSize', 10);
lineHandles = gobjects(1, 2);
for waveIndex = 1:2
    lineHandles(waveIndex) = plot(axisHandle, sampleTimePoints, waves(waveIndex, :), 'Color', waveColors(waveIndex, :), 'LineWidth', 1.4);
end
xline(axisHandle, 0, 'k-');
yline(axisHandle, 0, 'k-');
xlim(axisHandle, plotLimitsMs);
ylim(axisHandle, yLimits);
xlabel(axisHandle, 'ms');
ylabel(axisHandle, '\muV');
if showLegend
    legend(axisHandle, lineHandles, waveNames, 'Location', 'northwest');
end
end
