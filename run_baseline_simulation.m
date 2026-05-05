
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FILE 2: matlab/run_baseline_simulation.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%RUN_BASELINE_SIMULATION Executes the Stage 1 battery thermal baseline model.
%
% This script defines the physical parameters, runs the baseline thermal
% model, plots the results, and exports the outputs to CSV and image files.
%
% Expected repository location:
%
%   battery-thermal-fpga-digital-twin/matlab/run_baseline_simulation.m
%
% Required companion files:
%
%   matlab/baseline_thermal_model.m
%   matlab/export_baseline_results.m
%
% Generated outputs:
%
%   dataset/baseline/matlab_baseline_results.csv
%   figures/matlab_baseline/temperature_vs_time.png
%   figures/matlab_baseline/heat_generated_vs_time.png
%   figures/matlab_baseline/heat_removed_vs_time.png
%   figures/matlab_baseline/net_heat_vs_time.png
%   reports/stage_01_baseline_summary.txt

clear;
clc;
close all;

fprintf('Stage 1: MATLAB Baseline Battery Thermal Model\n');
fprintf('Project: FPGA-Accelerated Battery Thermal Digital Twin\n');
fprintf('Author: Frank Ouma\n\n');

current_file_path = mfilename('fullpath');
[matlab_dir, ~, ~] = fileparts(current_file_path);
project_root = fileparts(matlab_dir);

if isempty(project_root)
    project_root = pwd;
end

addpath(matlab_dir);

output_dataset_dir = fullfile(project_root, 'dataset', 'baseline');
output_figure_dir = fullfile(project_root, 'figures', 'matlab_baseline');
output_report_dir = fullfile(project_root, 'reports');

ensure_directory(output_dataset_dir);
ensure_directory(output_figure_dir);
ensure_directory(output_report_dir);

params = struct();

% Battery physical assumptions for the first baseline model.
% These are initial engineering assumptions for modeling purposes.
% They must be refined later using cell datasheets, laboratory measurements,
% or validated literature values.
params.mass_kg = 2.50;
params.specific_heat_J_per_kgK = 900;
params.internal_resistance_ohm = 0.015;
params.cooling_hA_W_per_K = 8.0;

% Environmental and initial conditions.
params.ambient_temp_C = 30;
params.initial_temp_C = 30;

% Simulation setup.
params.time_step_s = 1;
params.total_time_s = 600;

% Thermal status limits.
% These values are conservative demonstration limits for the baseline model.
% Final limits should be aligned with selected battery chemistry and product
% safety requirements.
params.safe_limit_C = 45;
params.warning_limit_C = 60;
params.critical_limit_C = 75;

% Current profile.
% For the first simulation, use constant current.
% Later versions can replace this with a dynamic drive-cycle profile.
params.current_profile_A = 80;

results = baseline_thermal_model(params);

fprintf('Simulation completed.\n');
fprintf('Maximum temperature: %.2f degC\n', results.summary.max_temp_C);
fprintf('Final temperature: %.2f degC\n', results.summary.final_temp_C);
fprintf('Maximum temperature rise rate: %.5f degC/s\n', results.summary.max_temperature_rate_C_per_s);

if isnan(results.summary.time_to_warning_s)
    fprintf('Warning threshold was not reached.\n');
else
    fprintf('Time to warning threshold: %.2f s\n', results.summary.time_to_warning_s);
end

if isnan(results.summary.time_to_critical_s)
    fprintf('Critical threshold was not reached.\n');
else
    fprintf('Time to critical threshold: %.2f s\n', results.summary.time_to_critical_s);
end

csv_file = fullfile(output_dataset_dir, 'matlab_baseline_results.csv');
summary_file = fullfile(output_report_dir, 'stage_01_baseline_summary.txt');

export_baseline_results(results, csv_file, summary_file);

plot_temperature(results, params, output_figure_dir);
plot_heat_generated(results, output_figure_dir);
plot_heat_removed(results, output_figure_dir);
plot_net_heat(results, output_figure_dir);
plot_current_profile(results, output_figure_dir);

fprintf('\nGenerated files:\n');
fprintf('CSV dataset: %s\n', csv_file);
fprintf('Summary report: %s\n', summary_file);
fprintf('Figures folder: %s\n', output_figure_dir);


function ensure_directory(directory_path)
%ENSURE_DIRECTORY Creates a directory if it does not already exist.

    if ~exist(directory_path, 'dir')
        mkdir(directory_path);
    end
end


function plot_temperature(results, params, output_figure_dir)
%PLOT_TEMPERATURE Saves temperature versus time plot.

    figure('Name', 'Battery Temperature vs Time');
    plot(results.time_s, results.temperature_C, 'LineWidth', 2);
    hold on;
    yline(params.safe_limit_C, '--', 'Safe Limit');
    yline(params.warning_limit_C, '--', 'Warning Limit');
    yline(params.critical_limit_C, '--', 'Critical Limit');
    hold off;

    grid on;
    xlabel('Time (s)');
    ylabel('Battery Temperature (degC)');
    title('Stage 1 Baseline Model: Battery Temperature vs Time');

    saveas(gcf, fullfile(output_figure_dir, 'temperature_vs_time.png'));
end


function plot_heat_generated(results, output_figure_dir)
%PLOT_HEAT_GENERATED Saves heat generation plot.

    figure('Name', 'Heat Generated vs Time');
    plot(results.time_s, results.heat_generated_W, 'LineWidth', 2);
    grid on;
    xlabel('Time (s)');
    ylabel('Heat Generated (W)');
    title('Electrical Heat Generated by Battery');

    saveas(gcf, fullfile(output_figure_dir, 'heat_generated_vs_time.png'));
end


function plot_heat_removed(results, output_figure_dir)
%PLOT_HEAT_REMOVED Saves cooling heat removal plot.

    figure('Name', 'Heat Removed vs Time');
    plot(results.time_s, results.heat_removed_W, 'LineWidth', 2);
    grid on;
    xlabel('Time (s)');
    ylabel('Heat Removed (W)');
    title('Heat Removed by Lumped Cooling Model');

    saveas(gcf, fullfile(output_figure_dir, 'heat_removed_vs_time.png'));
end


function plot_net_heat(results, output_figure_dir)
%PLOT_NET_HEAT Saves net heat plot.

    figure('Name', 'Net Heat vs Time');
    plot(results.time_s, results.net_heat_W, 'LineWidth', 2);
    grid on;
    xlabel('Time (s)');
    ylabel('Net Heat (W)');
    title('Net Heat Stored in Battery Thermal Mass');

    saveas(gcf, fullfile(output_figure_dir, 'net_heat_vs_time.png'));
end


function plot_current_profile(results, output_figure_dir)
%PLOT_CURRENT_PROFILE Saves current profile plot.

    figure('Name', 'Current Profile vs Time');
    plot(results.time_s, results.current_A, 'LineWidth', 2);
    grid on;
    xlabel('Time (s)');
    ylabel('Current (A)');
    title('Battery Current Profile Used in Baseline Simulation');

    saveas(gcf, fullfile(output_figure_dir, 'current_profile_vs_time.png'));
end
