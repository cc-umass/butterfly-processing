globals;

% Test window for rejection analysis borrowed from the UMD/Ellen Lau artifact_rejection.m script
testWindowMs = [-100 800];

% Used for determining whether data in an EOG channel for an epoch is usable for blink rejection
eogPtpMinUv = 5;
eogDiffMaxUv = 100;

% Step function thresholds and windows borrowed from the UMD/Ellen Lau artifact_rejection.m script
stepThresholdVeogUv = 40;
stepThresholdHeogUv = 25;
stepWindowMs = 200;
stepStepMs = 50;

% Peak-to-peak thresholds and windows borrowed from the UMD/Ellen Lau artifact_rejection.m script
ptpThresholdUv = 100;
ptpWindowMs = 200;
ptpStepMs = 100;

% A scalp channel flagged by the peak-to-peak test on more than this fraction of epochs is masked for the subject
badChannelFlagFraction = 0.5;
