%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STAGE 1B MATLAB CURRENT SWEEP CODE PACKAGE
% Project: FPGA-Accelerated Battery Thermal Digital Twin for Real-Time
%          Safety Prediction
% Author: Frank Ouma
% Contact: +254725582132
%
% Purpose:
% This code extends Stage 1A from one constant-current case to a structured
% current sweep. The objective is to study how battery temperature response
% changes as electrical load increases. The output becomes the first
% multi-scenario baseline dataset for later comparison with COMSOL,
% surrogate modeling, quantization, and FPGA inference.
%
% Required existing file:
%   matlab/baseline_thermal_model.m
%
% New file created in this package:
%   matlab/run_current_sweep_simulation.m
%
% Expected generated outputs:
%   dataset/baseline/current_sweep_results.csv
%   reports/stage_01B_current_sweep_summary.txt
%   figures/matlab_baseline/current_sweep_temperature.png
%   figures/matlab_baseline/current_sweep_heat_generated.png
%   figures/matlab_baseline/current_sweep_heat_removed.png
%   figures/matlab_baseline/current_sweep_net_heat.png
%   figures/matlab_baseline/current_sweep_final_temperature.png
%   figures/matlab_baseline/current_sweep_max_temperature.png
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FILE: matlab/run_current_sweep_simulation.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%RUN_CURRENT_SWEEP_SIMULATION Executes Stage 1B current sweep simulations.
%
% This script runs the Stage 1 lumped battery thermal model for several
% constant-current operating conditions. The aim is to confirm the expected
% thermal trend: higher current produces higher heat generation and higher
% temperature rise when cooling conditions remain unchanged.
%
% The model remains intentionally simplified. It assumes the battery behaves
% as a single thermal mass with one average temperature. The current sweep is
% used to build physical understanding, generate a baseline dataset, and
% document the first load-sensitivity analysis for the project repository.
%
% To run:
%   cd battery-thermal-fpga-digital-twin/matlab
%   run_current_sweep_simulation

clear;
clc;
close all;

fprintf('Stage 1B: MATLAB Current Sweep Baseline Simulation\n');
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

current_sweep_A = [40, 80, 120, 160, 200];

all_results_table = table();
summary_table = table();
simulation_results = cell(length(current_sweep_A), 1);

for case_index = 1:length(current_sweep_A)
    case_current_A = current_sweep_A(case_index);

    params = base_params;
    params.current_profile_A = case_current_A;

    results = baseline_thermal_model(params);
    simulation_results{case_index} = results;

    case_table = create_case_output_table(results, case_index, case_current_A);
    all_results_table = [all_results_table; case_table];

    case_summary = create_case_summary_table(results, case_index, case_current_A);
    summary_table = [summary_table; case_summary];

    fprintf('Case %d completed: %.0f A | Final Temp: %.2f degC | Max Temp: %.2f degC | Final State: %s\n', ...
        case_index, ...
        case_current_A, ...
        results.summary.final_temp_C, ...
        results.summary.max_temp_C, ...
        string(results.thermal_state(end)));
end

csv_output_file = fullfile(output_dataset_dir, 'current_sweep_results.csv');
summary_output_file = fullfile(output_report_dir, 'stage_01B_current_sweep_summary.txt');
summary_csv_file = fullfile(output_dataset_dir, 'current_sweep_summary.csv');

writetable(all_results_table, csv_output_file);
writetable(summary_table, summary_csv_file);
write_current_sweep_summary_report(summary_output_file, base_params, current_sweep_A, summary_table);

plot_current_sweep_temperature(simulation_results, current_sweep_A, base_params, output_figure_dir);
plot_current_sweep_heat_generated(simulation_results, current_sweep_A, output_figure_dir);
plot_current_sweep_heat_removed(simulation_results, current_sweep_A, output_figure_dir);
plot_current_sweep_net_heat(simulation_results, current_sweep_A, output_figure_dir);
plot_final_temperature_vs_current(summary_table, output_figure_dir);
plot_max_temperature_vs_current(summary_table, output_figure_dir);

fprintf('\nStage 1B current sweep completed successfully.\n');
fprintf('Full sweep dataset: %s\n', csv_output_file);
fprintf('Summary CSV: %s\n', summary_csv_file);
fprintf('Summary report: %s\n', summary_output_file);
fprintf('Figures folder: %s\n', output_figure_dir);


function params = define_base_parameters()
%DEFINE_BASE_PARAMETERS Defines baseline physical and simulation assumptions.
%
% These values are initial engineering assumptions for first-order thermal
% behavior analysis. They are not final battery datasheet values. They will
% later be refined using cell manufacturer data, published battery thermal
% literature, calorimetry references, COMSOL model calibration, and physical
% testing.

    params = struct();

    params.mass_kg = 2.50;
    params.specific_heat_J_per_kgK = 900;
    params.internal_resistance_ohm = 0.015;
    params.cooling_hA_W_per_K = 8.0;

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


function case_table = create_case_output_table(results, case_index, case_current_A)
%CREATE_CASE_OUTPUT_TABLE Converts one simulation case into a table.

    number_of_rows = length(results.time_s);

    case_table = table();
    case_table.case_index = repmat(case_index, number_of_rows, 1);
    case_table.case_current_A = repmat(case_current_A, number_of_rows, 1);
    case_table.time_s = results.time_s;
    case_table.current_A = results.current_A;
    case_table.temperature_C = results.temperature_C;
    case_table.heat_generated_W = results.heat_generated_W;
    case_table.heat_removed_W = results.heat_removed_W;
    case_table.net_heat_W = results.net_heat_W;
    case_table.temperature_rate_C_per_s = results.temperature_rate_C_per_s;
    case_table.thermal_state = results.thermal_state;
end


function case_summary = create_case_summary_table(results, case_index, case_current_A)
%CREATE_CASE_SUMMARY_TABLE Creates a compact summary for one current case.

    case_summary = table();
    case_summary.case_index = case_index;
    case_summary.current_A = case_current_A;
    case_summary.heat_generated_W = case_current_A^2 * results.params.internal_resistance_ohm;
    case_summary.initial_temp_C = results.params.initial_temp_C;
    case_summary.final_temp_C = results.summary.final_temp_C;
    case_summary.max_temp_C = results.summary.max_temp_C;
    case_summary.temperature_rise_C = results.summary.final_temp_C - results.params.initial_temp_C;
    case_summary.max_temperature_rate_C_per_s = results.summary.max_temperature_rate_C_per_s;
    case_summary.average_heat_removed_W = results.summary.average_heat_removed_W;
    case_summary.time_to_warning_s = results.summary.time_to_warning_s;
    case_summary.time_to_critical_s = results.summary.time_to_critical_s;
    case_summary.final_thermal_state = string(results.thermal_state(end));
end


function write_current_sweep_summary_report(summary_file, base_params, current_sweep_A, summary_table)
%WRITE_CURRENT_SWEEP_SUMMARY_REPORT Writes the Stage 1B text summary.

    fid = fopen(summary_file, 'w');

    if fid == -1
        error('Unable to create summary report: %s', summary_file);
    end

    cleanup_object = onCleanup(@() fclose(fid));

    fprintf(fid, 'Stage 1B Current Sweep Baseline Simulation Summary\n');
    fprintf(fid, 'Project: FPGA-Accelerated Battery Thermal Digital Twin for Real-Time Safety Prediction\n');
    fprintf(fid, 'Author: Frank Ouma\n');
    fprintf(fid, 'Contact: +254725582132\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Purpose\n');
    fprintf(fid, 'This stage evaluates how the simplified battery thermal model responds to different constant-current loading conditions.\n');
    fprintf(fid, 'The analysis is used to confirm first-order thermal behavior before moving to higher-fidelity COMSOL simulation.\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Model Basis\n');
    fprintf(fid, 'The model uses the lumped heat balance: m * Cp * dT/dt = I^2 * R - hA * (T - Tamb).\n');
    fprintf(fid, 'The battery is treated as one thermal mass with one average temperature.\n');
    fprintf(fid, 'This is not a final high-fidelity representation of the battery pack. It is a baseline physical reference model.\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Base Parameter Assumptions\n');
    fprintf(fid, 'Battery mass: %.4f kg\n', base_params.mass_kg);
    fprintf(fid, 'Specific heat capacity: %.4f J/kg.K\n', base_params.specific_heat_J_per_kgK);
    fprintf(fid, 'Internal resistance: %.6f ohm\n', base_params.internal_resistance_ohm);
    fprintf(fid, 'Cooling hA: %.4f W/K\n', base_params.cooling_hA_W_per_K);
    fprintf(fid, 'Ambient temperature: %.4f degC\n', base_params.ambient_temp_C);
    fprintf(fid, 'Initial temperature: %.4f degC\n', base_params.initial_temp_C);
    fprintf(fid, 'Simulation duration: %.4f s\n', base_params.total_time_s);
    fprintf(fid, 'Time step: %.4f s\n', base_params.time_step_s);
    fprintf(fid, '\n');

    fprintf(fid, 'Current Cases\n');
    for i = 1:length(current_sweep_A)
        fprintf(fid, 'Case %d: %.4f A\n', i, current_sweep_A(i));
    end
    fprintf(fid, '\n');

    fprintf(fid, 'Results Summary\n');
    fprintf(fid, '%-8s %-12s %-18s %-18s %-18s %-18s %-18s\n', ...
        'Case', 'Current_A', 'Heat_Gen_W', 'Final_Temp_C', 'Max_Temp_C', 'Temp_Rise_C', 'Final_State');

    for row = 1:height(summary_table)
        fprintf(fid, '%-8d %-12.2f %-18.4f %-18.4f %-18.4f %-18.4f %-18s\n', ...
            summary_table.case_index(row), ...
            summary_table.current_A(row), ...
            summary_table.heat_generated_W(row), ...
            summary_table.final_temp_C(row), ...
            summary_table.max_temp_C(row), ...
            summary_table.temperature_rise_C(row), ...
            char(summary_table.final_thermal_state(row)));
    end

    fprintf(fid, '\n');
    fprintf(fid, 'Engineering Interpretation\n');
    fprintf(fid, 'The current sweep demonstrates the expected nonlinear heating effect caused by I^2R losses.\n');
    fprintf(fid, 'When current increases, heat generation increases with the square of current.\n');
    fprintf(fid, 'Because the cooling coefficient remains fixed in this sweep, higher current cases produce higher final and maximum temperatures.\n');
    fprintf(fid, 'This result confirms that the baseline model follows the expected first-order thermal trend.\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Relevance to Later Project Stages\n');
    fprintf(fid, 'The current sweep dataset will support early comparison against COMSOL simulations.\n');
    fprintf(fid, 'It also introduces the first input-output mapping required for later surrogate model training.\n');
    fprintf(fid, 'The current value acts as a controlled input, while temperature, heat removal, net heat, and thermal state act as model outputs.\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Limitations\n');
    fprintf(fid, 'This model does not capture cell geometry, hot spots, cooling channel flow, contact resistance, or material-layer temperature gradients.\n');
    fprintf(fid, 'The parameter values are initial modeling assumptions and must be refined using datasheets, literature, COMSOL calibration, and experimental measurement.\n');
end


function plot_current_sweep_temperature(simulation_results, current_sweep_A, base_params, output_figure_dir)
%PLOT_CURRENT_SWEEP_TEMPERATURE Plots temperature response for all current cases.

    figure('Name', 'Current Sweep Temperature Response');
    hold on;

    for i = 1:length(simulation_results)
        results = simulation_results{i};
        plot(results.time_s, results.temperature_C, 'LineWidth', 2, ...
            'DisplayName', sprintf('%.0f A', current_sweep_A(i)));
    end

    yline(base_params.safe_limit_C, '--', 'Safe Limit', 'HandleVisibility', 'off');
    yline(base_params.warning_limit_C, '--', 'Warning Limit', 'HandleVisibility', 'off');
    yline(base_params.critical_limit_C, '--', 'Critical Limit', 'HandleVisibility', 'off');

    hold off;
    grid on;
    xlabel('Time (s)');
    ylabel('Battery Temperature (degC)');
    title('Stage 1B Current Sweep: Battery Temperature vs Time');
    legend('Location', 'northwest');

    saveas(gcf, fullfile(output_figure_dir, 'current_sweep_temperature.png'));
end


function plot_current_sweep_heat_generated(simulation_results, current_sweep_A, output_figure_dir)
%PLOT_CURRENT_SWEEP_HEAT_GENERATED Plots heat generation for all current cases.

    figure('Name', 'Current Sweep Heat Generated');
    hold on;

    for i = 1:length(simulation_results)
        results = simulation_results{i};
        plot(results.time_s, results.heat_generated_W, 'LineWidth', 2, ...
            'DisplayName', sprintf('%.0f A', current_sweep_A(i)));
    end

    hold off;
    grid on;
    xlabel('Time (s)');
    ylabel('Heat Generated (W)');
    title('Stage 1B Current Sweep: Electrical Heat Generation');
    legend('Location', 'northwest');

    saveas(gcf, fullfile(output_figure_dir, 'current_sweep_heat_generated.png'));
end


function plot_current_sweep_heat_removed(simulation_results, current_sweep_A, output_figure_dir)
%PLOT_CURRENT_SWEEP_HEAT_REMOVED Plots cooling heat removal for all current cases.

    figure('Name', 'Current Sweep Heat Removed');
    hold on;

    for i = 1:length(simulation_results)
        results = simulation_results{i};
        plot(results.time_s, results.heat_removed_W, 'LineWidth', 2, ...
            'DisplayName', sprintf('%.0f A', current_sweep_A(i)));
    end

    hold off;
    grid on;
    xlabel('Time (s)');
    ylabel('Heat Removed (W)');
    title('Stage 1B Current Sweep: Cooling Heat Removal');
    legend('Location', 'northwest');

    saveas(gcf, fullfile(output_figure_dir, 'current_sweep_heat_removed.png'));
end


function plot_current_sweep_net_heat(simulation_results, current_sweep_A, output_figure_dir)
%PLOT_CURRENT_SWEEP_NET_HEAT Plots net heat for all current cases.

    figure('Name', 'Current Sweep Net Heat');
    hold on;

    for i = 1:length(simulation_results)
        results = simulation_results{i};
        plot(results.time_s, results.net_heat_W, 'LineWidth', 2, ...
            'DisplayName', sprintf('%.0f A', current_sweep_A(i)));
    end

    yline(0, '--', 'Thermal Balance', 'HandleVisibility', 'off');

    hold off;
    grid on;
    xlabel('Time (s)');
    ylabel('Net Heat (W)');
    title('Stage 1B Current Sweep: Net Heat Stored in Battery');
    legend('Location', 'northeast');

    saveas(gcf, fullfile(output_figure_dir, 'current_sweep_net_heat.png'));
end


function plot_final_temperature_vs_current(summary_table, output_figure_dir)
%PLOT_FINAL_TEMPERATURE_VS_CURRENT Plots final temperature against current.

    figure('Name', 'Final Temperature vs Current');
    plot(summary_table.current_A, summary_table.final_temp_C, '-o', 'LineWidth', 2);
    grid on;
    xlabel('Current (A)');
    ylabel('Final Temperature after 600 s (degC)');
    title('Stage 1B Current Sweep: Final Temperature vs Current');

    saveas(gcf, fullfile(output_figure_dir, 'current_sweep_final_temperature.png'));
end


function plot_max_temperature_vs_current(summary_table, output_figure_dir)
%PLOT_MAX_TEMPERATURE_VS_CURRENT Plots maximum temperature against current.

    figure('Name', 'Maximum Temperature vs Current');
    plot(summary_table.current_A, summary_table.max_temp_C, '-o', 'LineWidth', 2);
    grid on;
    xlabel('Current (A)');
    ylabel('Maximum Temperature (degC)');
    title('Stage 1B Current Sweep: Maximum Temperature vs Current');

    saveas(gcf, fullfile(output_figure_dir, 'current_sweep_max_temperature.png'));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GITHUB COMMIT NOTE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% After running the script successfully, commit the code and outputs:
%
%   git add matlab dataset figures reports
%   git commit -m "Add Stage 1B current sweep thermal baseline"
%   git push
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
