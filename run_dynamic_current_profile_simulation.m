
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FILE 2: matlab/run_dynamic_current_profile_simulation.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%RUN_DYNAMIC_CURRENT_PROFILE_SIMULATION Executes Stage 1E dynamic load cases.
%
% This script runs the Stage 1 lumped battery thermal model using dynamic
% current profiles. Real battery systems rarely operate under one constant
% current. This stage introduces more realistic current behavior such as
% step loading, pulse loading, ramp loading, and mixed duty-cycle loading.
%
% To run:
%   cd battery-thermal-fpga-digital-twin/matlab
%   run_dynamic_current_profile_simulation

clear;
clc;
close all;

fprintf('Stage 1E: MATLAB Dynamic Current Profile Simulation\n');
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

base_params = define_base_parameters_stage_01e();

time_s = (0:base_params.time_step_s:base_params.total_time_s)';
current_profiles = build_dynamic_current_profiles(time_s);

all_results_table = table();
summary_table = table();
simulation_results = cell(length(current_profiles), 1);

for case_index = 1:length(current_profiles)
    profile = current_profiles(case_index);

    params = base_params;
    params.current_profile_A = profile.current_A;

    results = baseline_thermal_model(params);
    simulation_results{case_index} = results;

    case_table = create_dynamic_case_output_table(results, case_index, profile.name, profile.description);
    all_results_table = [all_results_table; case_table];

    case_summary = create_dynamic_case_summary_table(results, case_index, profile.name, profile.description);
    summary_table = [summary_table; case_summary];

    fprintf('Case %d completed: %s | Final Temp: %.2f degC | Max Temp: %.2f degC | Final State: %s\n', ...
        case_index, ...
        profile.name, ...
        results.summary.final_temp_C, ...
        results.summary.max_temp_C, ...
        string(results.thermal_state(end)));
end

csv_output_file = fullfile(output_dataset_dir, 'dynamic_current_profile_results.csv');
summary_csv_file = fullfile(output_dataset_dir, 'dynamic_current_profile_summary.csv');
summary_output_file = fullfile(output_report_dir, 'stage_01E_dynamic_current_profile_summary.txt');

writetable(all_results_table, csv_output_file);
writetable(summary_table, summary_csv_file);
write_dynamic_profile_summary_report(summary_output_file, base_params, summary_table);

plot_dynamic_current_profiles(simulation_results, current_profiles, output_figure_dir);
plot_dynamic_temperature_response(simulation_results, current_profiles, base_params, output_figure_dir);
plot_dynamic_heat_generated(simulation_results, current_profiles, output_figure_dir);
plot_dynamic_net_heat(simulation_results, current_profiles, output_figure_dir);
plot_dynamic_final_temperature(summary_table, output_figure_dir);
plot_dynamic_max_temperature(summary_table, output_figure_dir);

fprintf('\nStage 1E dynamic current profile simulation completed successfully.\n');
fprintf('Full dynamic dataset: %s\n', csv_output_file);
fprintf('Summary CSV: %s\n', summary_csv_file);
fprintf('Summary report: %s\n', summary_output_file);
fprintf('Figures folder: %s\n', output_figure_dir);


function params = define_base_parameters_stage_01e()
%DEFINE_BASE_PARAMETERS_STAGE_01E Defines base assumptions for dynamic profiles.

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


function current_profiles = build_dynamic_current_profiles(time_s)
%BUILD_DYNAMIC_CURRENT_PROFILES Creates realistic current loading profiles.

    n = length(time_s);

    profile_1 = 80 * ones(n, 1);

    profile_2 = zeros(n, 1);
    profile_2(time_s < 120) = 40;
    profile_2(time_s >= 120 & time_s < 300) = 120;
    profile_2(time_s >= 300 & time_s < 450) = 160;
    profile_2(time_s >= 450) = 80;

    profile_3 = 60 * ones(n, 1);
    for k = 1:n
        if mod(time_s(k), 120) < 30
            profile_3(k) = 180;
        end
    end

    profile_4 = 40 + (140 - 40) * (time_s / max(time_s));

    profile_5 = zeros(n, 1);
    profile_5(time_s < 100) = 50;
    profile_5(time_s >= 100 & time_s < 200) = 140;
    profile_5(time_s >= 200 & time_s < 280) = 80;
    profile_5(time_s >= 280 & time_s < 380) = 180;
    profile_5(time_s >= 380 & time_s < 500) = 100;
    profile_5(time_s >= 500) = 60;

    current_profiles = struct([]);

    current_profiles(1).name = "Constant_80A";
    current_profiles(1).description = "Constant medium load reference case";
    current_profiles(1).current_A = profile_1;

    current_profiles(2).name = "Step_Load";
    current_profiles(2).description = "Step increase and decrease in battery load";
    current_profiles(2).current_A = profile_2;

    current_profiles(3).name = "Pulse_Load";
    current_profiles(3).description = "Short high-current pulses on moderate base load";
    current_profiles(3).current_A = profile_3;

    current_profiles(4).name = "Ramp_Load";
    current_profiles(4).description = "Gradual increase in current over the simulation window";
    current_profiles(4).current_A = profile_4;

    current_profiles(5).name = "Mixed_Duty_Cycle";
    current_profiles(5).description = "Mixed operating duty cycle with multiple load levels";
    current_profiles(5).current_A = profile_5;
end


function case_table = create_dynamic_case_output_table(results, case_index, profile_name, profile_description)
%CREATE_DYNAMIC_CASE_OUTPUT_TABLE Converts one dynamic case into a table.

    number_of_rows = length(results.time_s);

    case_table = table();
    case_table.case_index = repmat(case_index, number_of_rows, 1);
    case_table.profile_name = repmat(string(profile_name), number_of_rows, 1);
    case_table.profile_description = repmat(string(profile_description), number_of_rows, 1);
    case_table.time_s = results.time_s;
    case_table.current_A = results.current_A;
    case_table.temperature_C = results.temperature_C;
    case_table.heat_generated_W = results.heat_generated_W;
    case_table.heat_removed_W = results.heat_removed_W;
    case_table.net_heat_W = results.net_heat_W;
    case_table.temperature_rate_C_per_s = results.temperature_rate_C_per_s;
    case_table.thermal_state = results.thermal_state;
end


function case_summary = create_dynamic_case_summary_table(results, case_index, profile_name, profile_description)
%CREATE_DYNAMIC_CASE_SUMMARY_TABLE Creates summary for one dynamic profile.

    case_summary = table();
    case_summary.case_index = case_index;
    case_summary.profile_name = string(profile_name);
    case_summary.profile_description = string(profile_description);
    case_summary.average_current_A = mean(results.current_A);
    case_summary.max_current_A = max(results.current_A);
    case_summary.rms_current_A = sqrt(mean(results.current_A.^2));
    case_summary.average_heat_generated_W = mean(results.heat_generated_W);
    case_summary.max_heat_generated_W = max(results.heat_generated_W);
    case_summary.initial_temp_C = results.params.initial_temp_C;
    case_summary.final_temp_C = results.summary.final_temp_C;
    case_summary.max_temp_C = results.summary.max_temp_C;
    case_summary.temperature_rise_C = results.summary.final_temp_C - results.params.initial_temp_C;
    case_summary.max_temperature_rate_C_per_s = results.summary.max_temperature_rate_C_per_s;
    case_summary.final_heat_removed_W = results.heat_removed_W(end);
    case_summary.final_net_heat_W = results.net_heat_W(end);
    case_summary.time_to_warning_s = results.summary.time_to_warning_s;
    case_summary.time_to_critical_s = results.summary.time_to_critical_s;
    case_summary.final_thermal_state = string(results.thermal_state(end));
end


function write_dynamic_profile_summary_report(summary_file, base_params, summary_table)
%WRITE_DYNAMIC_PROFILE_SUMMARY_REPORT Writes Stage 1E summary report.

    fid = fopen(summary_file, 'w');

    if fid == -1
        error('Unable to create summary report: %s', summary_file);
    end

    cleanup_object = onCleanup(@() fclose(fid));

    fprintf(fid, 'Stage 1E Dynamic Current Profile Simulation Summary\n');
    fprintf(fid, 'Project: FPGA-Accelerated Battery Thermal Digital Twin for Real-Time Safety Prediction\n');
    fprintf(fid, 'Author: Frank Ouma\n');
    fprintf(fid, 'Contact: +254725582132\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Purpose\n');
    fprintf(fid, 'This stage evaluates the battery thermal response under dynamic current profiles instead of a single constant-current load.\n');
    fprintf(fid, 'The analysis is closer to real operation because battery loads change during acceleration, startup, pulsed demand, duty-cycle variation, and recovery periods.\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Model Basis\n');
    fprintf(fid, 'The model uses the lumped heat balance: m * Cp * dT/dt = I^2 * R - hA * (T - Tamb).\n');
    fprintf(fid, 'The heat generation term changes at every time step because current changes with the selected profile.\n');
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

    fprintf(fid, 'Results Summary\n');
    fprintf(fid, '%-8s %-22s %-16s %-16s %-18s %-18s %-18s\n', ...
        'Case', 'Profile', 'Avg_Current_A', 'RMS_Current_A', 'Final_Temp_C', 'Max_Temp_C', 'Final_State');

    for row = 1:height(summary_table)
        fprintf(fid, '%-8d %-22s %-16.4f %-16.4f %-18.4f %-18.4f %-18s\n', ...
            summary_table.case_index(row), ...
            char(summary_table.profile_name(row)), ...
            summary_table.average_current_A(row), ...
            summary_table.rms_current_A(row), ...
            summary_table.final_temp_C(row), ...
            summary_table.max_temp_C(row), ...
            char(summary_table.final_thermal_state(row)));
    end

    fprintf(fid, '\n');
    fprintf(fid, 'Engineering Interpretation\n');
    fprintf(fid, 'Dynamic current profiles produce time-varying heat generation because Qgen = I^2 * R.\n');
    fprintf(fid, 'Short high-current pulses can create strong heat spikes even when the average current appears moderate.\n');
    fprintf(fid, 'RMS current is useful because heat generation depends on current squared, not only arithmetic average current.\n');
    fprintf(fid, 'The thermal mass of the battery smooths rapid current changes, but repeated or sustained high-current sections increase final temperature and risk.\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Relevance to Later Project Stages\n');
    fprintf(fid, 'Dynamic profiles are closer to real operating behavior than constant-current cases.\n');
    fprintf(fid, 'The future surrogate model must learn from both steady and dynamic operating conditions to predict future thermal response reliably.\n');
    fprintf(fid, 'The FPGA implementation will eventually receive live changing sensor values and produce fast thermal-risk predictions.\n');
end


function plot_dynamic_current_profiles(simulation_results, current_profiles, output_figure_dir)
%PLOT_DYNAMIC_CURRENT_PROFILES Plots all current profiles.

    figure('Name', 'Dynamic Current Profiles');
    hold on;

    for i = 1:length(simulation_results)
        results = simulation_results{i};
        plot(results.time_s, results.current_A, 'LineWidth', 2, ...
            'DisplayName', char(current_profiles(i).name));
    end

    hold off;
    grid on;
    xlabel('Time (s)');
    ylabel('Current (A)');
    title('Stage 1E Dynamic Current Profiles');
    legend('Location', 'northwest');

    saveas(gcf, fullfile(output_figure_dir, 'dynamic_current_profiles.png'));
end


function plot_dynamic_temperature_response(simulation_results, current_profiles, base_params, output_figure_dir)
%PLOT_DYNAMIC_TEMPERATURE_RESPONSE Plots temperature for dynamic profiles.

    figure('Name', 'Dynamic Temperature Response');
    hold on;

    for i = 1:length(simulation_results)
        results = simulation_results{i};
        plot(results.time_s, results.temperature_C, 'LineWidth', 2, ...
            'DisplayName', char(current_profiles(i).name));
    end

    yline(base_params.safe_limit_C, '--', 'Safe Limit', 'HandleVisibility', 'off');
    yline(base_params.warning_limit_C, '--', 'Warning Limit', 'HandleVisibility', 'off');
    yline(base_params.critical_limit_C, '--', 'Critical Limit', 'HandleVisibility', 'off');

    hold off;
    grid on;
    xlabel('Time (s)');
    ylabel('Battery Temperature (degC)');
    title('Stage 1E Dynamic Profiles: Battery Temperature vs Time');
    legend('Location', 'northwest');

    saveas(gcf, fullfile(output_figure_dir, 'dynamic_temperature_response.png'));
end


function plot_dynamic_heat_generated(simulation_results, current_profiles, output_figure_dir)
%PLOT_DYNAMIC_HEAT_GENERATED Plots heat generation for dynamic profiles.

    figure('Name', 'Dynamic Heat Generation');
    hold on;

    for i = 1:length(simulation_results)
        results = simulation_results{i};
        plot(results.time_s, results.heat_generated_W, 'LineWidth', 2, ...
            'DisplayName', char(current_profiles(i).name));
    end

    hold off;
    grid on;
    xlabel('Time (s)');
    ylabel('Heat Generated (W)');
    title('Stage 1E Dynamic Profiles: Heat Generation vs Time');
    legend('Location', 'northwest');

    saveas(gcf, fullfile(output_figure_dir, 'dynamic_heat_generated.png'));
end


function plot_dynamic_net_heat(simulation_results, current_profiles, output_figure_dir)
%PLOT_DYNAMIC_NET_HEAT Plots net heat for dynamic profiles.

    figure('Name', 'Dynamic Net Heat');
    hold on;

    for i = 1:length(simulation_results)
        results = simulation_results{i};
        plot(results.time_s, results.net_heat_W, 'LineWidth', 2, ...
            'DisplayName', char(current_profiles(i).name));
    end

    yline(0, '--', 'Thermal Balance', 'HandleVisibility', 'off');

    hold off;
    grid on;
    xlabel('Time (s)');
    ylabel('Net Heat (W)');
    title('Stage 1E Dynamic Profiles: Net Heat Stored in Battery');
    legend('Location', 'northwest');

    saveas(gcf, fullfile(output_figure_dir, 'dynamic_net_heat.png'));
end


function plot_dynamic_final_temperature(summary_table, output_figure_dir)
%PLOT_DYNAMIC_FINAL_TEMPERATURE Plots final temperature by profile.

    figure('Name', 'Dynamic Final Temperature by Profile');
    bar(categorical(summary_table.profile_name), summary_table.final_temp_C);
    grid on;
    xlabel('Current Profile');
    ylabel('Final Temperature after 600 s (degC)');
    title('Stage 1E Dynamic Profiles: Final Temperature by Profile');

    saveas(gcf, fullfile(output_figure_dir, 'dynamic_final_temperature_by_profile.png'));
end


function plot_dynamic_max_temperature(summary_table, output_figure_dir)
%PLOT_DYNAMIC_MAX_TEMPERATURE Plots maximum temperature by profile.

    figure('Name', 'Dynamic Maximum Temperature by Profile');
    bar(categorical(summary_table.profile_name), summary_table.max_temp_C);
    grid on;
    xlabel('Current Profile');
    ylabel('Maximum Temperature (degC)');
    title('Stage 1E Dynamic Profiles: Maximum Temperature by Profile');

    saveas(gcf, fullfile(output_figure_dir, 'dynamic_max_temperature_by_profile.png'));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GITHUB COMMIT NOTE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% After both scripts run successfully, commit the code and outputs:
%
%   git add matlab dataset figures reports
%   git commit -m "Add Stage 1D ambient sweep and Stage 1E dynamic current profiles"
%   git push
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%