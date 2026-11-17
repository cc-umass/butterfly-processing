# Presentation version of the workflow

Condensed for reading. It is not meant to run; logging, caching, file paths and error checks are removed. The working code is in `Source/`.

| Step | File |
|---|---|
| Study loop: every subject, then the test and the figure | `runStudy.m` |
| One subject: load, filter, reference, epoch, clean, reject | `processSubject.m` |
| Bad channels in each of the five experiment sections | `findBadChannelsBySection.m` |
| ICA and removal of eye components | `removeEyeComponents.m` |
| Autoreject threshold for each channel | `autorejectThresholds.py` |
| Condition averages at the CP region, correct trials only | `averageSubject.m` |
| Interaction test in the analysis window | `testInteraction.m` |
| Settings | `constants.m` |

Order of operations for one subject:

1. Load the Curry recording; keep the experiment events.
2. Find bad channels in each section.
3. High-pass filter, 0.1 Hz.
4. Re-reference to the mean of the mastoids.
5. Epoch around the picture, -700 to 1300 ms; baseline -100 to 0 ms.
6. ICA on all trials; remove eye components.
7. Autoreject on all trials: mark bad channel-by-epoch cells.
8. Low-pass filter, 40 Hz.
9. Average the correct trials for each condition at the CP region. An epoch is dropped when any CP channel is marked bad in it.
10. Test (readjust low - readjust high) - (no readjust low - no readjust high) in the window.
