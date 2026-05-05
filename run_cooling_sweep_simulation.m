%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STAGE 1C MATLAB COOLING STRENGTH SWEEP CODE PACKAGE
% Project: FPGA-Accelerated Battery Thermal Digital Twin for Real-Time
%          Safety Prediction
% Author: Frank Ouma
% Contact: +254725582132
%
% Purpose:
% This code extends the Stage 1 baseline thermal model by studying the
% effect of cooling strength on battery temperature response. Stage 1B
% showed that higher current increases heat generation through I^2R losses.
% Stage 1C now investigates whether stronger cooling can control the same
% electrical load and reduce the risk of excessive temperature rise.
%
% Required existing file:
%   matlab/baseline_thermal_model.m
%
% New file created in this package:
%   matlab/run_cooling_sweep_simulation.m
%
% Expected generated outputs:
%   dataset/baseline/cooling_sweep_results.csv
%   dataset/baseline/cooling_sweep_summary.csv
%   reports/stage_01C_cooling_sweep_summary.txt
%   figures/matlab_baseline/cooling_sweep_temperature.png
%   figures/matlab_baseline/cooling_sweep_heat_removed.png
%   figures/matlab_baseline/cooling_sweep_net_heat.png
%   figures/matlab_baseline/cooling_sweep_final_temperature.png
%   figures/matlab_baseline/cooling_sweep_max_temperature.png
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FILE: matlab/run_cooling_sweep_simulation.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%RUN_COOLING_SWEEP_SIMULATION Executes Stage 1C cooling strength sweep.
%
% This script runs the Stage 1 lumped battery thermal model while keeping
% battery current fixed and varying the lumped cooling strength hA. The
% objective is to document how stronger cooling affects heat removal, net
% heat storage, final temperature, and thermal status.
%
% The model remains intentionally simplified. The battery is treated as a
% single thermal mass with one average temperature. The cooling term is
% represented by hA, where h is the heat transfer coefficient and A is the
% effective cooling area. In this baseline model, hA is treated as a single
% combined cooling-strength parameter.
%
% To run:
%   cd battery-thermal-fpga-digital-twin/matlab
%   run_cooling_sweep_simulation

clear;
clc;
close all;

fprintf('Stage 1C: MATLAB Cooling Strength Sweep Simulation\n');
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

base_params = define_base_parameters();

% Fixed current selected from Stage 1B as a demanding operating case.
% This value intentionally creates significant heat so that the effect of
% cooling strength becomes visible.
fixed_current_A = 160;

% hA sweep values represent different cooling capability levels.
% Low hA represents weak natural cooling or poor thermal contact.
% High hA represents improved forced-air or liquid-cooling behavior.
cooling_hA_sweep_W_per_K = [2, 5, 8, 12, 20, 30];

all_results_table = table();
summary_table = table();
simulation_results = cell(length(cooling_hA_sweep_W_per_K), 1);

for case_index = 1:length(cooling_hA_sweep_W_per_K)
    case_hA_W_per_K = cooling_hA_sweep_W_per_K(case_index);

    params = base_params;
    params.current_profile_A = fixed_current_A;
    params.cooling_hA_W_per_K = case_hA_W_per_K;

    results = baseline_thermal_model(params);
    simulation_results{case_index} = results;

    case_table = create_case_output_table(results, case_index, fixed_current_A, case_hA_W_per_K);
    all_results_table = [all_results_table; case_table];

    case_summary = create_case_summary_table(results, case_index, fixed_current_A, case_hA_W_per_K);
    summary_table = [summary_table; case_summary];

    fprintf('Case %d completed: hA = %.2f W/K | Final Temp: %.2f degC | Max Temp: %.2f degC | Final State: %s\n', ...
        case_index, ...
        case_hA_W_per_K, ...
        results.summary.final_temp_C, ...
        results.summary.max_temp_C, ...
        string(results.thermal_state(end)));
end

csv_output_file = fullfile(output_dataset_dir, 'cooling_sweep_results.csv');
summary_csv_file = fullfile(output_dataset_dir, 'cooling_sweep_summary.csv');
summary_output_file = fullfile(output_report_dir, 'stage_01C_cooling_sweep_summary.txt');

writetable(all_results_table, csv_output_file);
writetable(summary_table, summary_csv_file);
write_cooling_sweep_summary_report(summary_output_file, base_params, fixed_current_A, cooling_hA_sweep_W_per_K, summary_table);

plot_cooling_sweep_temperature(simulation_results, cooling_hA_sweep_W_per_K, base_params, output_figure_dir);
plot_cooling_sweep_heat_removed(simulation_results, cooling_hA_sweep_W_per_K, output_figure_dir);
plot_cooling_sweep_net_heat(simulation_results, cooling_hA_sweep_W_per_K, output_figure_dir);
plot_final_temperature_vs_cooling(summary_table, output_figure_dir);
plot_max_temperature_vs_cooling(summary_table, output_figure_dir);

fprintf('\nStage 1C cooling strength sweep completed successfully.\n');
fprintf('Full sweep dataset: %s\n', csv_output_file);
fprintf('Summary CSV: %s\n', summary_csv_file);
fprintf('Summary report: %s\n', summary_output_file);
fprintf('Figures folder: %s\n', output_figure_dir);


function params = define_base_parameters()
%DEFINE_BASE_PARAMETERS Defines baseline physical and simulation assumptions.
%
% These values are initial engineering assumptions used for first-order
% thermal behavior analysis. They are not final validated battery values.
% The values will be refined later using datasheets, literature references,
% COMSOL calibration, and experimental measurements.

    params = struct();

    params.mass_kg = 2.50;
    params.specific_heat_J_per_kgK = 900;
    params.internal_resistance_ohm = 0.015;

    params.ambient_temp_C = 30;
    params.initial_temp_C = 30;

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


function case_table = create_case_output_table(results, case_index, fixed_current_A, case_hA_W_per_K)
%CREATE_CASE_OUTPUT_TABLE Converts one cooling sweep case into a table.

    number_of_rows = length(results.time_s);

    case_table = table();
    case_table.case_index = repmat(case_index, number_of_rows, 1);
    case_table.fixed_current_A = repmat(fixed_current_A, number_of_rows, 1);
    case_table.cooling_hA_W_per_K = repmat(case_hA_W_per_K, number_of_rows, 1);
    case_table.time_s = results.time_s;
    case_table.current_A = results.current_A;
    case_table.temperature_C = results.temperature_C;
    case_table.heat_generated_W = results.heat_generated_W;
    case_table.heat_removed_W = results.heat_removed_W;
    case_table.net_heat_W = results.net_heat_W;
    case_table.temperature_rate_C_per_s = results.temperature_rate_C_per_s;
    case_table.thermal_state = results.thermal_state;
end


function case_summary = create_case_summary_table(results, case_index, fixed_current_A, case_hA_W_per_K)
%CREATE_CASE_SUMMARY_TABLE Creates a compact summary for one cooling case.

    case_summary = table();
    case_summary.case_index = case_index;
    case_summary.fixed_current_A = fixed_current_A;
    case_summary.cooling_hA_W_per_K = case_hA_W_per_K;
    case_summary.heat_generated_W = fixed_current_A^2 * results.params.internal_resistance_ohm;
    case_summary.initial_temp_C = results.params.initial_temp_C;
    case_summary.final_temp_C = results.summary.final_temp_C;
    case_summary.max_temp_C = results.summary.max_temp_C;
    case_summary.temperature_rise_C = results.summary.final_temp_C - results.params.initial_temp_C;
    case_summary.max_temperature_rate_C_per_s = results.summary.max_temperature_rate_C_per_s;
    case_summary.average_heat_removed_W = results.summary.average_heat_removed_W;
    case_summary.final_heat_removed_W = results.heat_removed_W(end);
    case_summary.final_net_heat_W = results.net_heat_W(end);
    case_summary.time_to_warning_s = results.summary.time_to_warning_s;
    case_summary.time_to_critical_s = results.summary.time_to_critical_s;
    case_summary.final_thermal_state = string(results.thermal_state(end));
end


function write_cooling_sweep_summary_report(summary_file, base_params, fixed_current_A, cooling_hA_sweep_W_per_K, summary_table)
%WRITE_COOLING_SWEEP_SUMMARY_REPORT Writes the Stage 1C summary report.

    fid = fopen(summary_file, 'w');

    if fid == -1
        error('Unable to create summary report: %s', summary_file);
    end

    cleanup_object = onCleanup(@() fclose(fid));

    fprintf(fid, 'Stage 1C Cooling Strength Sweep Simulation Summary\n');
    fprintf(fid, 'Project: FPGA-Accelerated Battery Thermal Digital Twin for Real-Time Safety Prediction\n');
    fprintf(fid, 'Author: Frank Ouma\n');
    fprintf(fid, 'Contact: +254725582132\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Purpose\n');
    fprintf(fid, 'This stage evaluates how the simplified battery thermal model responds to different cooling strength values under the same electrical load.\n');
    fprintf(fid, 'The analysis demonstrates whether stronger cooling can reduce temperature rise and delay or prevent unsafe thermal conditions.\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Model Basis\n');
    fprintf(fid, 'The model uses the lumped heat balance: m * Cp * dT/dt = I^2 * R - hA * (T - Tamb).\n');
    fprintf(fid, 'The battery is treated as one thermal mass with one average temperature.\n');
    fprintf(fid, 'The cooling term is represented by hA, a combined cooling-strength parameter.\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Base Parameter Assumptions\n');
    fprintf(fid, 'Battery mass: %.4f kg\n', base_params.mass_kg);
    fprintf(fid, 'Specific heat capacity: %.4f J/kg.K\n', base_params.specific_heat_J_per_kgK);
    fprintf(fid, 'Internal resistance: %.6f ohm\n', base_params.internal_resistance_ohm);
    fprintf(fid, 'Ambient temperature: %.4f degC\n', base_params.ambient_temp_C);
    fprintf(fid, 'Initial temperature: %.4f degC\n', base_params.initial_temp_C);
    fprintf(fid, 'Simulation duration: %.4f s\n', base_params.total_time_s);
    fprintf(fid, 'Time step: %.4f s\n', base_params.time_step_s);
    fprintf(fid, 'Fixed current: %.4f A\n', fixed_current_A);
    fprintf(fid, '\n');

    fprintf(fid, 'Cooling Strength Cases\n');
    for i = 1:length(cooling_hA_sweep_W_per_K)
        fprintf(fid, 'Case %d: hA = %.4f W/K\n', i, cooling_hA_sweep_W_per_K(i));
    end
    fprintf(fid, '\n');

    fprintf(fid, 'Results Summary\n');
    fprintf(fid, '%-8s %-14s %-18s %-18s %-18s %-18s %-18s\n', ...
        'Case', 'hA_W_per_K', 'Heat_Gen_W', 'Final_Temp_C', 'Max_Temp_C', 'Final_Net_W', 'Final_State');

    for row = 1:height(summary_table)
        fprintf(fid, '%-8d %-14.2f %-18.4f %-18.4f %-18.4f %-18.4f %-18s\n', ...
            summary_table.case_index(row), ...
            summary_table.cooling_hA_W_per_K(row), ...
            summary_table.heat_generated_W(row), ...
            summary_table.final_temp_C(row), ...
            summary_table.max_temp_C(row), ...
            summary_table.final_net_heat_W(row), ...
            char(summary_table.final_thermal_state(row)));
    end

    fprintf(fid, '\n');
    fprintf(fid, 'Engineering Interpretation\n');
    fprintf(fid, 'The cooling sweep demonstrates the expected effect of stronger heat removal on battery thermal response.\n');
    fprintf(fid, 'When hA increases, the cooling term hA * (T - Tamb) becomes stronger for the same temperature difference.\n');
    fprintf(fid, 'As a result, final temperature and net stored heat should decrease as cooling strength increases.\n');
    fprintf(fid, 'This confirms the second side of the heat balance: current controls heat generation, while cooling strength controls heat removal.\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Relevance to Later Project Stages\n');
    fprintf(fid, 'This sweep supports the later control objective of the physical system.\n');
    fprintf(fid, 'A future FPGA-based controller can use predicted thermal risk to command stronger cooling or load reduction before the battery reaches unsafe temperature.\n');
    fprintf(fid, 'The cooling sweep also becomes part of the early input-output dataset for surrogate model development.\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Limitations\n');
    fprintf(fid, 'This baseline sweep does not model actual fan curves, pump curves, coolant pressure drop, cooling channel geometry, or spatial hot-spot distribution.\n');
    fprintf(fid, 'In the high-fidelity COMSOL stage, hA will be replaced or supported by geometry-based heat transfer and fluid-flow modeling.\n');
end


function plot_cooling_sweep_temperature(simulation_results, cooling_hA_sweep_W_per_K, base_params, output_figure_dir)
%PLOT_COOLING_SWEEP_TEMPERATURE Plots temperature response for all cooling cases.

    figure('Name', 'Cooling Sweep Temperature Response');
    hold on;

    for i = 1:length(simulation_results)
        results = simulation_results{i};
        plot(results.time_s, results.temperature_C, 'LineWidth', 2, ...
            'DisplayName', sprintf('hA %.0f W/K', cooling_hA_sweep_W_per_K(i)));
    end

    yline(base_params.safe_limit_C, '--', 'Safe Limit', 'HandleVisibility', 'off');
    yline(base_params.warning_limit_C, '--', 'Warning Limit', 'HandleVisibility', 'off');
    yline(base_params.critical_limit_C, '--', 'Critical Limit', 'HandleVisibility', 'off');

    hold off;
    grid on;
    xlabel('Time (s)');
    ylabel('Battery Temperature (degC)');
    title('Stage 1C Cooling Sweep: Battery Temperature vs Time');
    legend('Location', 'northeast');

    saveas(gcf, fullfile(output_figure_dir, 'cooling_sweep_temperature.png'));
end


function plot_cooling_sweep_heat_removed(simulation_results, cooling_hA_sweep_W_per_K, output_figure_dir)
%PLOT_COOLING_SWEEP_HEAT_REMOVED Plots heat removal for all cooling cases.

    figure('Name', 'Cooling Sweep Heat Removed');
    hold on;

    for i = 1:length(simulation_results)
        results = simulation_results{i};
        plot(results.time_s, results.heat_removed_W, 'LineWidth', 2, ...
            'DisplayName', sprintf('hA %.0f W/K', cooling_hA_sweep_W_per_K(i)));
    end

    hold off;
    grid on;
    xlabel('Time (s)');
    ylabel('Heat Removed (W)');
    title('Stage 1C Cooling Sweep: Heat Removed vs Time');
    legend('Location', 'southeast');

    saveas(gcf, fullfile(output_figure_dir, 'cooling_sweep_heat_removed.png'));
end


function plot_cooling_sweep_net_heat(simulation_results, cooling_hA_sweep_W_per_K, output_figure_dir)
%PLOT_COOLING_SWEEP_NET_HEAT Plots net heat for all cooling cases.

    figure('Name', 'Cooling Sweep Net Heat');
    hold on;

    for i = 1:length(simulation_results)
        results = simulation_results{i};
        plot(results.time_s, results.net_heat_W, 'LineWidth', 2, ...
            'DisplayName', sprintf('hA %.0f W/K', cooling_hA_sweep_W_per_K(i)));
    end

    yline(0, '--', 'Thermal Balance', 'HandleVisibility', 'off');

    hold off;
    grid on;
    xlabel('Time (s)');
    ylabel('Net Heat (W)');
    title('Stage 1C Cooling Sweep: Net Heat Stored in Battery');
    legend('Location', 'northeast');

    saveas(gcf, fullfile(output_figure_dir, 'cooling_sweep_net_heat.png'));
end


function plot_final_temperature_vs_cooling(summary_table, output_figure_dir)
%PLOT_FINAL_TEMPERATURE_VS_COOLING Plots final temperature against hA.

    figure('Name', 'Final Temperature vs Cooling Strength');
    plot(summary_table.cooling_hA_W_per_K, summary_table.final_temp_C, '-o', 'LineWidth', 2);
    grid on;
    xlabel('Cooling Strength hA (W/K)');
    ylabel('Final Temperature after 600 s (degC)');
    title('Stage 1C Cooling Sweep: Final Temperature vs Cooling Strength');

    saveas(gcf, fullfile(output_figure_dir, 'cooling_sweep_final_temperature.png'));
end


function plot_max_temperature_vs_cooling(summary_table, output_figure_dir)
%PLOT_MAX_TEMPERATURE_VS_COOLING Plots maximum temperature against hA.

    figure('Name', 'Maximum Temperature vs Cooling Strength');
    plot(summary_table.cooling_hA_W_per_K, summary_table.max_temp_C, '-o', 'LineWidth', 2);
    grid on;
    xlabel('Cooling Strength hA (W/K)');
    ylabel('Maximum Temperature (degC)');
    title('Stage 1C Cooling Sweep: Maximum Temperature vs Cooling Strength');

    saveas(gcf, fullfile(output_figure_dir, 'cooling_sweep_max_temperature.png'));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GITHUB COMMIT NOTE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% After running the script successfully, commit the code and outputs:
%
%   git add matlab dataset figures reports
%   git commit -m "Add Stage 1C cooling strength baseline sweep"
%   git push
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
