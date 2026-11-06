%% ========================================================================
% DISTRIBUTION TEMPLATES
%% ========================================================================

% NORMAL DISTRIBUTION
%
% mean = mu
% sigma = standard deviation
%
% Example:
%
% speed_dist = makedist( ...
%     'Normal', ...
%     'mu', 30, ...
%     'sigma', 5);


% UNIFORM DISTRIBUTION
%
% Lower = minimum
% Upper = maximum
%
% Example:
%
% speed_dist = makedist( ...
%     'Uniform', ...
%     'Lower', 20, ...
%     'Upper', 40);


% TRIANGULAR DISTRIBUTION
%
% A = lower bound
% B = most likely value (peak)
% C = upper bound
%
% Example:
%
% speed_dist = makedist( ...
%     'Triangular', ...
%     'A', 20, ...
%     'B', 30, ...
%     'C', 40);


% COMMON FUNCTIONS
%
% mean(dist)
% std(dist)
% random(dist)
%
% Example:
%
% x = random(speed_dist);


%% ========================================================================
% Normal Input Template
%% ========================================================================

Inputs(n).Name = 'Variable Name';

Inputs(n).Units = 'ft';

Inputs(n).Dist = variable_dist;

Inputs(n).ScaleFactor = 1;

Inputs(n).NominalValue = ...
    mean(variable_dist) * Inputs(n).ScaleFactor;

Inputs(n).Sigma = ...
    std(variable_dist) * Inputs(n).ScaleFactor;

Inputs(n).Range = ...
    6*std(variable_dist) * Inputs(n).ScaleFactor;

%% ========================================================================
%  Uniform Input Template
%% ========================================================================
Inputs(n).Name = 'Speed';

Inputs(n).Units = 'fps';

Inputs(n).Dist = speed_dist;

Inputs(n).ScaleFactor = mph_to_fps;

Inputs(n).NominalValue = ...
    mean(speed_dist) * Inputs(n).ScaleFactor;

Inputs(n).Sigma = ...
    std(speed_dist) * Inputs(n).ScaleFactor;

Inputs(n).Range = ...
    (Upper-Lower) * Inputs(n).ScaleFactor;

%% ========================================================================
% Triangular Input Template
%% ========================================================================

Inputs(n).Name = 'Perception Response Time';

Inputs(n).Units = 's';

Inputs(n).Dist = prt_dist;

Inputs(n).ScaleFactor = 1;

Inputs(n).NominalValue = ...
    mean(prt_dist);

Inputs(n).Sigma = ...
    std(prt_dist);

Inputs(n).Range = ...
    (C-A);

A = lower limit;
B = mode;
C = upper limit;