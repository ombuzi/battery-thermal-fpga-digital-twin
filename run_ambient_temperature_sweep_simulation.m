%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STAGE 1D AND STAGE 1E MATLAB CODE PACKAGE
% Project: FPGA-Accelerated Battery Thermal Digital Twin for Real-Time
%          Safety Prediction
% Author: Frank Ouma
% Contact: +254725582132
%
% This package contains two separate MATLAB scripts:
%
%   1. matlab/run_ambient_temperature_sweep_simulation.m
%   2. matlab/run_dynamic_current_profile_simulation.m
%
% Required existing file:
%   matlab/baseline_thermal_model.m
%
% Stage 1D studies the effect of ambient temperature.
% Stage 1E studies the effect of realistic dynamic battery current loading.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FILE 1: matlab/run_ambient_temperature_sweep_simulation.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%RUN_AMBIENT_TEMPERATURE_SWEEP_SIMULATION Executes Stage 1D ambient sweep.
%
% This script runs the Stage 1 lumped battery thermal model while keeping
% current and cooling strength fixed, then varying ambient temperature.
% The aim is to document how environmental temperature affects thermal
% margin, final battery temperature, and risk status.
%
% To run:
%   cd battery-thermal-fpga-digital-twin/matlab
%   run_ambient_temperature_sweep_simulation

clear;
clc;
close all;

fprintf('Stage 1D: MATLAB Ambient Temperature Sweep Simulation\n');
fprintf('Project: FPGA-Accelerated Battery Thermal Digital Twin\n');
fprintf('Author: Frank Ouma\n');
fprintf('Contact: +254725582132\n\n');

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

base_params = define_base_parameters_stage_01d();

fixed_current_A = 160;
fixed_cooling_hA_W_per_K = 8;
ambient_temperature_sweep_C = [0, 10, 20, 30, 40, 50];

all_results_table = table();
summary_table = table();
simulation_results = cell(length(ambient_temperature_sweep_C), 1);

for case_index = 1:length(ambient_temperature_sweep_C)
    case_ambient_temp_C = ambient_temperature_sweep_C(case_index);

    params = base_params;
    params.current_profile_A = fixed_current_A;
    params.cooling_hA_W_per_K = fixed_cooling_hA_W_per_K;
    params.ambient_temp_C = case_ambient_temp_C;
    params.initial_temp_C = case_ambient_temp_C;

    results = baseline_thermal_model(params);
    simulation_results{case_index} = results;

    case_table = create_ambient_case_output_table(results, case_index, fixed_current_A, fixed_cooling_hA_W_per_K, case_ambient_temp_C);
    all_results_table = [all_results_table; case_table];

    case_summary = create_ambient_case_summary_table(results, case_index, fixed_current_A, fixed_cooling_hA_W_per_K, case_ambient_temp_C);
    summary_table = [summary_table; case_summary];

    fprintf('Case %d completed: Ambient = %.2f degC | Final Temp: %.2f degC | Max Temp: %.2f degC | Final State: %s\n', ...
        case_index, ...
        case_ambient_temp_C, ...
        results.summary.final_temp_C, ...
        results.summary.max_temp_C, ...
        string(results.thermal_state(end)));
end

csv_output_file = fullfile(output_dataset_dir, 'ambient_temperature_sweep_results.csv');
summary_csv_file = fullfile(output_dataset_dir, 'ambient_temperature_sweep_summary.csv');
summary_output_file = fullfile(output_report_dir, 'stage_01D_ambient_temperature_sweep_summary.txt');

writetable(all_results_table, csv_output_file);
writetable(summary_table, summary_csv_file);
write_ambient_sweep_summary_report(summary_output_file, base_params, fixed_current_A, fixed_cooling_hA_W_per_K, ambient_temperature_sweep_C, summary_table);

plot_ambient_sweep_temperature(simulation_results, ambient_temperature_sweep_C, base_params, output_figure_dir);
plot_ambient_sweep_heat_removed(simulation_results, ambient_temperature_sweep_C, output_figure_dir);
plot_ambient_sweep_net_heat(simulation_results, ambient_temperature_sweep_C, output_figure_dir);
plot_final_temperature_vs_ambient(summary_table, output_figure_dir);
plot_max_temperature_vs_ambient(summary_table, output_figure_dir);
plot_temperature_margin_vs_ambient(summary_table, base_params, output_figure_dir);

fprintf('\nStage 1D ambient temperature sweep completed successfully.\n');
fprintf('Full sweep dataset: %s\n', csv_output_file);
fprintf('Summary CSV: %s\n', summary_csv_file);
fprintf('Summary report: %s\n', summary_output_file);
fprintf('Figures folder: %s\n', output_figure_dir);


function params = define_base_parameters_stage_01d()
%DEFINE_BASE_PARAMETERS_STAGE_01D Defines base assumptions for ambient sweep.

    params = struct();

    params.mass_kg = 2.50;
    params.specific_heat_J_per_kgK = 900;
    params.internal_resistance_ohm = 0.015;

    params.time_step_s = 1;
    params.total_time_s = 600;

    params.safe_limit_C = 45;
    params.warning_limit_C = 60;
    params.critical_limit_C = 75;
end


function ensure_directory(directory_path)
%ENSURE_DIRECTORY Creates an output directory if it does not already exist.

    if ~exist(directory_path, 'dir')
        mkdir(directory_path);
    end
end


function case_table = create_ambient_case_output_table(results, case_index, fixed_current_A, fixed_cooling_hA_W_per_K, case_ambient_temp_C)
%CREATE_AMBIENT_CASE_OUTPUT_TABLE Converts one ambient case into a table.

    number_of_rows = length(results.time_s);

    case_table = table();
    case_table.case_index = repmat(case_index, number_of_rows, 1);
    case_table.fixed_current_A = repmat(fixed_current_A, number_of_rows, 1);
    case_table.fixed_cooling_hA_W_per_K = repmat(fixed_cooling_hA_W_per_K, number_of_rows, 1);
    case_table.ambient_temp_C = repmat(case_ambient_temp_C, number_of_rows, 1);
    case_table.time_s = results.time_s;
    case_table.current_A = results.current_A;
    case_table.temperature_C = results.temperature_C;
    case_table.heat_generated_W = results.heat_generated_W;
    case_table.heat_removed_W = results.heat_removed_W;
    case_table.net_heat_W = results.net_heat_W;
    case_table.temperature_rate_C_per_s = results.temperature_rate_C_per_s;
    case_table.thermal_state = results.thermal_state;
end


function case_summary = create_ambient_case_summary_table(results, case_index, fixed_current_A, fixed_cooling_hA_W_per_K, case_ambient_temp_C)
%CREATE_AMBIENT_CASE_SUMMARY_TABLE Creates a compact summary for one case.

    case_summary = table();
    case_summary.case_index = case_index;
    case_summary.fixed_current_A = fixed_current_A;
    case_summary.fixed_cooling_hA_W_per_K = fixed_cooling_hA_W_per_K;
    case_summary.ambient_temp_C = case_ambient_temp_C;
    case_summary.heat_generated_W = fixed_current_A^2 * results.params.internal_resistance_ohm;
    case_summary.initial_temp_C = results.params.initial_temp_C;
    case_summary.final_temp_C = results.summary.final_temp_C;
    case_summary.max_temp_C = results.summary.max_temp_C;
    case_summary.temperature_rise_C = results.summary.final_temp_C - results.params.initial_temp_C;
    case_summary.safe_margin_C = results.params.safe_limit_C - results.summary.max_temp_C;
    case_summary.warning_margin_C = results.params.warning_limit_C - results.summary.max_temp_C;
    case_summary.critical_margin_C = results.params.critical_limit_C - results.summary.max_temp_C;
    case_summary.max_temperature_rate_C_per_s = results.summary.max_temperature_rate_C_per_s;
    case_summary.final_heat_removed_W = results.heat_removed_W(end);
    case_summary.final_net_heat_W = results.net_heat_W(end);
    case_summary.time_to_warning_s = results.summary.time_to_warning_s;
    case_summary.time_to_critical_s = results.summary.time_to_critical_s;
    case_summary.final_thermal_state = string(results.thermal_state(end));
end


function write_ambient_sweep_summary_report(summary_file, base_params, fixed_current_A, fixed_cooling_hA_W_per_K, ambient_temperature_sweep_C, summary_table)
%WRITE_AMBIENT_SWEEP_SUMMARY_REPORT Writes Stage 1D summary report.

    fid = fopen(summary_file, 'w');

    if fid == -1
        error('Unable to create summary report: %s', summary_file);
    end

    cleanup_object = onCleanup(@() fclose(fid));

    fprintf(fid, 'Stage 1D Ambient Temperature Sweep Simulation Summary\n');
    fprintf(fid, 'Project: FPGA-Accelerated Battery Thermal Digital Twin for Real-Time Safety Prediction\n');
    fprintf(fid, 'Author: Frank Ouma\n');
    fprintf(fid, 'Contact: +254725582132\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Purpose\n');
    fprintf(fid, 'This stage evaluates how environmental temperature affects battery thermal response under the same current and cooling condition.\n');
    fprintf(fid, 'The analysis shows how ambient temperature reduces or increases thermal safety margin.\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Model Basis\n');
    fprintf(fid, 'The model uses the lumped heat balance: m * Cp * dT/dt = I^2 * R - hA * (T - Tamb).\n');
    fprintf(fid, 'Current and cooling strength are fixed while ambient temperature is swept across multiple operating environments.\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Fixed Conditions\n');
    fprintf(fid, 'Battery mass: %.4f kg\n', base_params.mass_kg);
    fprintf(fid, 'Specific heat capacity: %.4f J/kg.K\n', base_params.specific_heat_J_per_kgK);
    fprintf(fid, 'Internal resistance: %.6f ohm\n', base_params.internal_resistance_ohm);
    fprintf(fid, 'Fixed current: %.4f A\n', fixed_current_A);
    fprintf(fid, 'Fixed cooling hA: %.4f W/K\n', fixed_cooling_hA_W_per_K);
    fprintf(fid, 'Simulation duration: %.4f s\n', base_params.total_time_s);
    fprintf(fid, 'Time step: %.4f s\n', base_params.time_step_s);
    fprintf(fid, '\n');

    fprintf(fid, 'Ambient Temperature Cases\n');
    for i = 1:length(ambient_temperature_sweep_C)
        fprintf(fid, 'Case %d: Ambient temperature = %.4f degC\n', i, ambient_temperature_sweep_C(i));
    end
    fprintf(fid, '\n');

    fprintf(fid, 'Results Summary\n');
    fprintf(fid, '%-8s %-16s %-18s %-18s %-18s %-18s\n', ...
        'Case', 'Ambient_C', 'Final_Temp_C', 'Max_Temp_C', 'Safe_Margin_C', 'Final_State');

    for row = 1:height(summary_table)
        fprintf(fid, '%-8d %-16.2f %-18.4f %-18.4f %-18.4f %-18s\n', ...
            summary_table.case_index(row), ...
            summary_table.ambient_temp_C(row), ...
            summary_table.final_temp_C(row), ...
            summary_table.max_temp_C(row), ...
            summary_table.safe_margin_C(row), ...
            char(summary_table.final_thermal_state(row)));
    end

    fprintf(fid, '\n');
    fprintf(fid, 'Engineering Interpretation\n');
    fprintf(fid, 'For the same current and cooling strength, higher ambient temperature shifts the entire battery temperature response upward.\n');
    fprintf(fid, 'This reduces the margin between operating temperature and safety limits.\n');
    fprintf(fid, 'The same battery loading condition can be acceptable in a cool environment and unsafe in a hot environment.\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Relevance to Later Project Stages\n');
    fprintf(fid, 'Ambient temperature becomes a necessary input feature for the surrogate model.\n');
    fprintf(fid, 'It is also important for the final embedded controller because environmental conditions affect the cooling action required to maintain safe operation.\n');
end


function plot_ambient_sweep_temperature(simulation_results, ambient_temperature_sweep_C, base_params, output_figure_dir)
%PLOT_AMBIENT_SWEEP_TEMPERATURE Plots temperature response for all ambient cases.

    figure('Name', 'Ambient Sweep Temperature Response');
    hold on;

    for i = 1:length(simulation_results)
        results = simulation_results{i};
        plot(results.time_s, results.temperature_C, 'LineWidth', 2, ...
            'DisplayName', sprintf('Tamb %.0f degC', ambient_temperature_sweep_C(i)));
    end

    yline(base_params.safe_limit_C, '--', 'Safe Limit', 'HandleVisibility', 'off');
    yline(base_params.warning_limit_C, '--', 'Warning Limit', 'HandleVisibility', 'off');
    yline(base_params.critical_limit_C, '--', 'Critical Limit', 'HandleVisibility', 'off');

    hold off;
    grid on;
    xlabel('Time (s)');
    ylabel('Battery Temperature (degC)');
    title('Stage 1D Ambient Sweep: Battery Temperature vs Time');
    legend('Location', 'northwest');

    saveas(gcf, fullfile(output_figure_dir, 'ambient_sweep_temperature.png'));
end


function plot_ambient_sweep_heat_removed(simulation_results, ambient_temperature_sweep_C, output_figure_dir)
%PLOT_AMBIENT_SWEEP_HEAT_REMOVED Plots heat removal for all ambient cases.

    figure('Name', 'Ambient Sweep Heat Removed');
    hold on;

    for i = 1:length(simulation_results)
        results = simulation_results{i};
        plot(results.time_s, results.heat_removed_W, 'LineWidth', 2, ...
            'DisplayName', sprintf('Tamb %.0f degC', ambient_temperature_sweep_C(i)));
    end

    hold off;
    grid on;
    xlabel('Time (s)');
    ylabel('Heat Removed (W)');
    title('Stage 1D Ambient Sweep: Heat Removed vs Time');
    legend('Location', 'southeast');

    saveas(gcf, fullfile(output_figure_dir, 'ambient_sweep_heat_removed.png'));
end


function plot_ambient_sweep_net_heat(simulation_results, ambient_temperature_sweep_C, output_figure_dir)
%PLOT_AMBIENT_SWEEP_NET_HEAT Plots net heat for all ambient cases.

    figure('Name', 'Ambient Sweep Net Heat');
    hold on;

    for i = 1:length(simulation_results)
        results = simulation_results{i};
        plot(results.time_s, results.net_heat_W, 'LineWidth', 2, ...
            'DisplayName', sprintf('Tamb %.0f degC', ambient_temperature_sweep_C(i)));
    end

    yline(0, '--', 'Thermal Balance', 'HandleVisibility', 'off');

    hold off;
    grid on;
    xlabel('Time (s)');
    ylabel('Net Heat (W)');
    title('Stage 1D Ambient Sweep: Net Heat Stored in Battery');
    legend('Location', 'northeast');

    saveas(gcf, fullfile(output_figure_dir, 'ambient_sweep_net_heat.png'));
end


function plot_final_temperature_vs_ambient(summary_table, output_figure_dir)
%PLOT_FINAL_TEMPERATURE_VS_AMBIENT Plots final temperature against ambient.

    figure('Name', 'Final Temperature vs Ambient Temperature');
    plot(summary_table.ambient_temp_C, summary_table.final_temp_C, '-o', 'LineWidth', 2);
    grid on;
    xlabel('Ambient Temperature (degC)');
    ylabel('Final Temperature after 600 s (degC)');
    title('Stage 1D Ambient Sweep: Final Temperature vs Ambient Temperature');

    saveas(gcf, fullfile(output_figure_dir, 'ambient_sweep_final_temperature.png'));
end


function plot_max_temperature_vs_ambient(summary_table, output_figure_dir)
%PLOT_MAX_TEMPERATURE_VS_AMBIENT Plots maximum temperature against ambient.

    figure('Name', 'Maximum Temperature vs Ambient Temperature');
    plot(summary_table.ambient_temp_C, summary_table.max_temp_C, '-o', 'LineWidth', 2);
    grid on;
    xlabel('Ambient Temperature (degC)');
    ylabel('Maximum Temperature (degC)');
    title('Stage 1D Ambient Sweep: Maximum Temperature vs Ambient Temperature');

    saveas(gcf, fullfile(output_figure_dir, 'ambient_sweep_max_temperature.png'));
end


function plot_temperature_margin_vs_ambient(summary_table, base_params, output_figure_dir)
%PLOT_TEMPERATURE_MARGIN_VS_AMBIENT Plots margin to safety limit.

    figure('Name', 'Safe Temperature Margin vs Ambient Temperature');
    plot(summary_table.ambient_temp_C, summary_table.safe_margin_C, '-o', 'LineWidth', 2);
    yline(0, '--', 'Safe Limit Boundary');
    grid on;
    xlabel('Ambient Temperature (degC)');
    ylabel('Margin to Safe Limit (degC)');
    title('Stage 1D Ambient Sweep: Temperature Margin vs Ambient Temperature');

    saveas(gcf, fullfile(output_figure_dir, 'ambient_sweep_safe_margin.png'));
end


