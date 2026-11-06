%% ========================================================================
% FINITE DIFFERENCE + MONTE CARLO FRAMEWORK
%
% EDIT ONLY:
%   1) CONSTANTS
%   2) INPUT DEFINITIONS
%   3) MODEL FUNCTION
%
% FEATURES:
%   - First-order sensitivity analysis
%   - Second-order sensitivity analysis
%   - Relative perturbation based on uncertainty range
%   - Monte Carlo uncertainty propagation
%   - Variable importance ranking
%   - Correlation ranking
%   - Automatic unit conversion via ScaleFactor
%   - Units carried into tables and reporting
%
%% ========================================================================

clear
clc
close all

%% ========================================================================
% CONSTANTS
%% ========================================================================

da = 96.3;                    % Available Distance in ft

u_mph = 10;                   % Initial Velocity in mph

mph_to_fps = 22/15;           % mph to fps conversion constant

u = u_mph * mph_to_fps;       % Initial Velocity in fps

g = 32.2;                     % G in ft/s^2

%% ========================================================================
% FINITE DIFFERENCE SETTINGS
%% ========================================================================

fd_percent = 0.01;
% Perturbation size = 1% of uncertainty range

%% ========================================================================
% MONTE CARLO SETTINGS
%% ========================================================================

N_MC = 10000;  

% Number of Monte Carlo Variables

%% ========================================================================
% INPUT DISTRIBUTIONS
%% ========================================================================

f_dist = makedist( ...
    'Normal', ...
    'mu', 0.3, ...
    'sigma', 0.06);

v_dist = makedist( ...
    'Uniform', ...
    'Lower', 18, ...
    'Upper', 22);

%% ========================================================================
% INPUT DEFINITIONS
%
% ADD / REMOVE VARIABLES HERE
%
%% ========================================================================

Inputs(1).Name = 'Deceleration Factor';
Inputs(1).Units = '-';
Inputs(1).Dist = f_dist;
Inputs(1).ScaleFactor = 1;
Inputs(1).NominalValue = mean(f_dist)* Inputs(1).ScaleFactor;
Inputs(1).Sigma = std(f_dist)*Inputs(1).ScaleFactor;
Inputs(1).Range = 6*std(f_dist)*Inputs(1).ScaleFactor;

Inputs(2).Name = 'Final Speed';
Inputs(2).Units = 'fps';
Inputs(2).Dist = v_dist;
Inputs(2).ScaleFactor = mph_to_fps;
Inputs(2).NominalValue = mean(v_dist)*Inputs(2).ScaleFactor;
Inputs(2).Sigma = std(v_dist)*Inputs(2).ScaleFactor;
Inputs(2).Range = (22-18)*Inputs(2).ScaleFactor;

%% ========================================================================
% BUILD NOMINAL CASE
%% ========================================================================

for i = 1:length(Inputs)

    Inputs(i).Value = Inputs(i).NominalValue;

end


%% ========================================================================
% BASELINE / NOMINAL EVALUATION
%% ========================================================================

Y0 = model_function(Inputs,u,da,g);

%% Build Nominal Input Table

NominalInputs = table( ...
    string({Inputs.Name})',...
    string({Inputs.Units})',...
    [Inputs.Value]',...
    [Inputs.Sigma]',...
    'VariableNames',...
    {'Variable',...
    'Units',...
    'NominalValue',...
    'Sigma'});

fprintf('\n')
fprintf('=================================================\n')
fprintf('NOMINAL INPUT CONDITIONS\n')
fprintf('=================================================\n')

disp(NominalInputs)

%% Nominal Output

OutputName  = 'Available Distance';
OutputUnits = 'ft';

fprintf('\n')
fprintf('=================================================\n')
fprintf('NOMINAL OUTPUT\n')
fprintf('=================================================\n')

fprintf('%s = %.4f %s\n', ...
    OutputName,...
    Y0,...
    OutputUnits);

%% Optional Output Table

NominalOutput = table( ...
    string(OutputName),...
    string(OutputUnits),...
    Y0,...
    'VariableNames',...
    {'Output',...
    'Units',...
    'NominalValue'});

disp(NominalOutput)

%% ========================================================================
% FIRST ORDER SENSITIVITY ANALYSIS
%% ========================================================================

nVar = length(Inputs);

FirstOrder = zeros(nVar,1);
NormalizedSensitivity = zeros(nVar,1);

for i = 1:nVar

    h = fd_percent * Inputs(i).Range;

    Xplus = Inputs;
    Xminus = Inputs;

    Xplus(i).Value = Xplus(i).Value + h;
    Xminus(i).Value = Xminus(i).Value - h;

    Yplus = model_function(Xplus,u,da,g);
    Yminus = model_function(Xminus,u,da,g);

    FirstOrder(i) = (Yplus - Yminus)/(2*h);

    NormalizedSensitivity(i) = ...
        FirstOrder(i) * (Inputs(i).Value / Y0);

end

%% ========================================================================
% SECOND ORDER SENSITIVITY ANALYSIS
%% ========================================================================

SecondOrder = zeros(nVar,1);

for i = 1:nVar

    h = fd_percent * Inputs(i).Range;

    Xplus = Inputs;
    Xminus = Inputs;

    Xplus(i).Value = Xplus(i).Value + h;
    Xminus(i).Value = Xminus(i).Value - h;

    Yplus = model_function(Xplus,u,da,g);
    Yminus = model_function(Xminus,u,da,g);

    SecondOrder(i) = ...
        (Yplus - 2*Y0 + Yminus)/(h^2);

end

%% ========================================================================
% UNCERTAINTY CONTRIBUTION ESTIMATE
%% ========================================================================

Sigma = [Inputs.Sigma]';

Contribution = abs(FirstOrder .* Sigma);

ContributionPercent = ...
    100 * Contribution / sum(Contribution);

%% ========================================================================
% MONTE CARLO SIMULATION
%% ========================================================================

Outputs = zeros(N_MC,1);

Samples = zeros(N_MC,nVar);

for k = 1:N_MC

    MCInputs = Inputs;

    for j = 1:nVar

        sample = random(MCInputs(j).Dist);

        sample = sample * MCInputs(j).ScaleFactor;

        MCInputs(j).Value = sample;

        Samples(k,j) = sample;

    end

    Outputs(k) = ...
        model_function(MCInputs,u,da,g);

end

%% ========================================================================
% MONTE CARLO STATISTICS
%% ========================================================================

MC.mean = mean(Outputs);
MC.std  = std(Outputs);

MC.min  = min(Outputs);
MC.max  = max(Outputs);

MC.p01 = prctile(Outputs,1);
MC.p05 = prctile(Outputs,5);
MC.p50 = prctile(Outputs,50);
MC.p95 = prctile(Outputs,95);
MC.p99 = prctile(Outputs,99);

fprintf('\n')
fprintf('=================================================\n')
fprintf('MONTE CARLO RESULTS\n')
fprintf('=================================================\n')

disp(struct2table(MC))

%% ========================================================================
% CONFIDENCE INTERVALS
%% ========================================================================

CI90 = prctile(Outputs,[5 95]);

CI95 = prctile(Outputs,[2.5 97.5]);

fprintf('\n')
fprintf('=================================================\n')
fprintf('MONTE CARLO CONFIDENCE INTERVALS\n')
fprintf('=================================================\n')

fprintf('90%% CI : [%.4f , %.4f]\n', ...
    CI90(1),CI90(2));

fprintf('95%% CI : [%.4f , %.4f]\n', ...
    CI95(1),CI95(2));


%% ========================================================================
% INPUT / OUTPUT CORRELATION -- PEARSON CORRELATION
%% ========================================================================

Correlation = zeros(nVar,1);

for i = 1:nVar

    R = corrcoef(Samples(:,i),Outputs);

    Correlation(i) = R(1,2);

end

%% ========================================================================
% RESULTS TABLE
%% ========================================================================

VarNames = string({Inputs.Name})';
Units = string({Inputs.Units})';

Results = table( ...
    VarNames,...
    Units,...
    [Inputs.Value]',...
    [Inputs.Sigma]',...
    [Inputs.Range]',...
    FirstOrder,...
    NormalizedSensitivity,...
    SecondOrder,...
    ContributionPercent,...
    Correlation,...
    'VariableNames',...
    {'Variable',...
     'Units',...
     'NominalValue',...
     'Sigma',...
     'Range',...
     'FirstDerivative',...
     'NormalizedSensitivity',...
     'SecondDerivative',...
     'ContributionPercent',...
     'Correlation'});

fprintf('\n')
fprintf('=================================================\n')
fprintf('SENSITIVITY RESULTS\n')
fprintf('=================================================\n')

disp(Results)

%% ========================================================================
% VARIABLE SUMMARY TABLE
%% ========================================================================

InputSummary = table( ...
    VarNames,...
    Units,...
    [Inputs.Value]',...
    [Inputs.Sigma]',...
    [Inputs.Range]',...
    'VariableNames',...
    {'Variable',...
     'Units',...
     'NominalValue',...
     'Sigma',...
     'Range'});

fprintf('\n')
fprintf('=================================================\n')
fprintf('INPUT SUMMARY\n')
fprintf('=================================================\n')

disp(InputSummary)

%% ========================================================================
% IMPORTANCE RANKING
%% ========================================================================

[~,idx] = sort( ...
    abs(NormalizedSensitivity), ...
    'descend');

fprintf('\n')
fprintf('=================================================\n')
fprintf('VARIABLE IMPORTANCE RANKING\n')
fprintf('=================================================\n')

for i = 1:nVar

    fprintf('%2d) %-25s (%s)\n', ...
        i, ...
        Inputs(idx(i)).Name, ...
        Inputs(idx(i)).Units);

end

%% ========================================================================
% PLOTS
%% ========================================================================

figure('Name','Sensitivity Results')

subplot(2,2,1)

bar(NormalizedSensitivity)

grid on

xticks(1:nVar)
xticklabels(VarNames)
xtickangle(20)

ylabel('Normalized Sensitivity')

title('First-Order Sensitivity')

subplot(2,2,2)

bar(SecondOrder)

grid on

xticks(1:nVar)
xticklabels(VarNames)
xtickangle(20)

ylabel('Second Derivative')

title('Second-Order Sensitivity')

subplot(2,2,3)

bar(ContributionPercent)

grid on

xticks(1:nVar)
xticklabels(VarNames)
xtickangle(20)

ylabel('Contribution (%)')

title('Estimated Uncertainty Contribution')

subplot(2,2,4)

bar(Correlation)

grid on

xticks(1:nVar)
xticklabels(VarNames)
xtickangle(20)

ylabel('Correlation Coefficient')

title('Monte Carlo Correlations')

%% ========================================================================
% MONTE CARLO HISTOGRAM
%% ========================================================================

figure('Name','Monte Carlo Output Distribution')

histogram(Outputs,50)

grid on

xlabel('Model Output')
ylabel('Count')

title('Monte Carlo Output Distribution')

xline(MC.mean,'r','LineWidth',2)

%% ========================================================================
% TORNADO PLOT
%% ========================================================================

figure('Name','Tornado Plot')

[sortedSens,idx] = ...
    sort(abs(NormalizedSensitivity), ...
    'descend');

barh(sortedSens)

grid on

yticks(1:nVar)

RankLabels = strings(nVar,1);

for i=1:nVar
    RankLabels(i) = sprintf('%s (%s)', ...
        Inputs(idx(i)).Name, ...
        Inputs(idx(i)).Units);
end

yticklabels(RankLabels)

xlabel('|Normalized Sensitivity|')

title('Variable Importance')

%% ========================================================================
% MODEL FUNCTION
%
% EDIT THIS FUNCTION FOR NEW PROBLEMS
%
%% ========================================================================

function Y = model_function(Inputs,u,da,g)

f = Inputs(1).Value;      % -
v = Inputs(2).Value;      % fps

StoppingDistance = ...
    ((v.^2) - (u.^2))/(2*g*f);

AvailableDistance = ...
    da - StoppingDistance;

Y = AvailableDistance;

end
