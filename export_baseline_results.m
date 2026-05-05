%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FILE 3: matlab/export_baseline_results.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function export_baseline_results(results, csv_file, summary_file)
%EXPORT_BASELINE_RESULTS Exports simulation results and summary report.
%
%   export_baseline_results(results, csv_file, summary_file)
%
%   This function writes the Stage 1 baseline thermal model outputs into a
%   CSV dataset and creates a text summary file for documentation.
%
%   Inputs:
%       results       Structure returned by baseline_thermal_model
%       csv_file      Full path to output CSV file
%       summary_file  Full path to output summary text file
%
%   CSV output columns:
%       time_s
%       current_A
%       temperature_C
%       heat_generated_W
%       heat_removed_W
%       net_heat_W
%       temperature_rate_C_per_s
%       thermal_state
%
%   The exported CSV becomes the first dataset artifact in the GitHub
%   project and provides a reference for later COMSOL and surrogate model
%   validation.

    output_table = table();
    output_table.time_s = results.time_s;
    output_table.current_A = results.current_A;
    output_table.temperature_C = results.temperature_C;
    output_table.heat_generated_W = results.heat_generated_W;
    output_table.heat_removed_W = results.heat_removed_W;
    output_table.net_heat_W = results.net_heat_W;
    output_table.temperature_rate_C_per_s = results.temperature_rate_C_per_s;
    output_table.thermal_state = results.thermal_state;

    writetable(output_table, csv_file);

    write_summary_report(results, summary_file);
end


function write_summary_report(results, summary_file)
%WRITE_SUMMARY_REPORT Writes a professional text summary of the run.

    fid = fopen(summary_file, 'w');

    if fid == -1
        error('Unable to create summary file: %s', summary_file);
    end

    cleanup_object = onCleanup(@() fclose(fid));

    fprintf(fid, 'Stage 1 Baseline Thermal Model Summary\n');
    fprintf(fid, 'Project: FPGA-Accelerated Battery Thermal Digital Twin for Real-Time Safety Prediction\n');
    fprintf(fid, 'Author: Frank Ouma\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Model Purpose\n');
    fprintf(fid, 'This simulation represents the first simplified thermal baseline for the project.\n');
    fprintf(fid, 'The battery is treated as a single lumped thermal mass with one average temperature.\n');
    fprintf(fid, 'The model estimates temperature rise from electrical heat generation and heat removal through cooling.\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Governing Heat Balance\n');
    fprintf(fid, 'm * Cp * dT/dt = I^2 * R - hA * (T - Tamb)\n');
    fprintf(fid, '\n');

    fprintf(fid, 'Main Parameter Values\n');
    fprintf(fid, 'Battery mass: %.4f kg\n', results.params.mass_kg);
    fprintf(fid, 'Specific heat capacity: %.4f J/kg.K\n', results.params.specific_heat_J_per_kgK);
    fprintf(fid, 'Internal resistance: %.6f ohm\n', results.params.internal_resistance_ohm);
    fprintf(fid, 'Cooling hA: %.4f W/K\n', results.params.cooling_hA_W_per_K);
    fprintf(fid, 'Ambient temperature: %.4f degC\n', results.params.ambient_temp_C);
    fprintf(fid, 'Initial temperature: %.4f degC\n', results.params.initial_temp_C);
    fprintf(fid, 'Simulation time step: %.4f s\n', results.params.time_step_s);
    fprintf(fid, 'Total simulation time: %.4f s\n', results.params.total_time_s);
    fprintf(fid, '\n');

    fprintf(fid, 'Simulation Results\n');
    fprintf(fid, 'Maximum temperature: %.4f degC\n', results.summary.max_temp_C);
    fprintf(fid, 'Time of maximum temperature: %.4f s\n', results.summary.time_of_max_temp_s);
    fprintf(fid, 'Final temperature: %.4f degC\n', results.summary.final_temp_C);
    fprintf(fid, 'Maximum temperature rise rate: %.8f degC/s\n', results.summary.max_temperature_rate_C_per_s);
    fprintf(fid, 'Average heat generated: %.4f W\n', results.summary.average_heat_generated_W);
    fprintf(fid, 'Average heat removed: %.4f W\n', results.summary.average_heat_removed_W);

    if isnan(results.summary.time_to_warning_s)
        fprintf(fid, 'Time to warning threshold: Not reached\n');
    else
        fprintf(fid, 'Time to warning threshold: %.4f s\n', results.summary.time_to_warning_s);
    end

    if isnan(results.summary.time_to_critical_s)
        fprintf(fid, 'Time to critical threshold: Not reached\n');
    else
        fprintf(fid, 'Time to critical threshold: %.4f s\n', results.summary.time_to_critical_s);
    end

    fprintf(fid, '\n');
    fprintf(fid, 'Engineering Interpretation\n');
    fprintf(fid, 'The result provides the first reference trend for battery temperature evolution.\n');
    fprintf(fid, 'If heat generation exceeds heat removal, temperature rises.\n');
    fprintf(fid, 'If cooling becomes strong enough to balance heat generation, temperature approaches a steady value.\n');
    fprintf(fid, 'This baseline result will later be compared with high-fidelity COMSOL simulation data and surrogate model predictions.\n');
end