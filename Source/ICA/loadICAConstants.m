globals;

% Filter settings for the ICA training copy, from Luck, Applied Event-Related Potential Data Analysis, 2022
icaTrainingHighPassHz = 1;
icaTrainingLowPassHz = 30;
icaTrainingFilterOrder = 8;

% After trial and error, the hand-picked ICLabel Eye probability above which a component is removed
eyeProbabilityMin = 0.8;
