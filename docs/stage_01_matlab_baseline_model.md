# Stage 1: MATLAB Baseline Thermal Model

## Author

Frank Ouma

## Stage Objective

The objective of Stage 1 is to create the first mathematical and computational baseline for the battery thermal prediction project. This stage uses MATLAB to model the battery as a single lumped thermal body and simulate how its temperature changes over time under electrical loading and cooling.

This stage is intentionally simple. It does not attempt to model three-dimensional geometry, detailed internal cell structure, hot spots, cooling channel flow, or cell-to-cell temperature variation. Those effects will be introduced later through COMSOL high-fidelity modeling.

The purpose of the Stage 1 MATLAB model is to establish the first scientific reference point for the project. It provides a transparent, explainable, and repeatable model that can be used to understand the basic thermal behavior before moving into more advanced simulation and hardware deployment.

## Reason for Starting With MATLAB

The project begins with MATLAB because the first requirement is to understand the governing thermal behavior in a controlled and transparent way. Before using COMSOL, machine learning, or FPGA tools, the project must show that the basic heat-generation and heat-removal process is understood.

MATLAB is suitable for this stage because it supports numerical simulation, matrix operations, plotting, engineering calculations, and clean result export. It allows the thermal equation to be implemented directly and reviewed easily.

The baseline model also provides an independent reference for later comparison. If the COMSOL simulation produces results that are physically unreasonable, the MATLAB model can help identify whether the issue comes from boundary conditions, material values, solver settings, or modeling assumptions.

## Physical Assumption

The first model assumes that the battery behaves as a lumped thermal mass. This means the battery is treated as if it has one uniform average temperature at each point in time.

This assumption is acceptable for a first-stage model when the goal is to understand average temperature rise rather than local hot-spot behavior.

The assumption simplifies the battery from a distributed three-dimensional system into a single thermal node.

The model therefore studies average thermal response, not internal temperature distribution.

## Engineering Question for Stage 1

Stage 1 answers the following question:

Given battery current, internal resistance, ambient temperature, battery thermal capacity, and cooling strength, how does the average battery temperature change over time?

The model also supports early safety classification by comparing predicted temperature with defined safe, warning, and critical limits.

## Model Inputs

The first MATLAB model will use the following inputs.

| Parameter | Description | Typical Unit |
|---|---|---|
| Initial battery temperature | Battery temperature at the beginning of simulation | degrees Celsius |
| Ambient temperature | Surrounding air or environment temperature | degrees Celsius |
| Battery current | Current flowing through the battery | amperes |
| Internal resistance | Equivalent internal electrical resistance of the battery | ohms |
| Battery mass | Effective thermal mass of the battery | kilograms |
| Specific heat capacity | Energy required to raise temperature of the battery material | joules per kilogram kelvin |
| Cooling coefficient | Effective convection coefficient | watts per square meter kelvin |
| Cooling area | Effective heat transfer area | square meters |
| Simulation duration | Total modeled time | seconds |
| Time step | Numerical update interval | seconds |

These inputs are enough to study the first-order thermal behavior.

## Model Outputs

The MATLAB model should produce the following outputs.

| Output | Description | Typical Unit |
|---|---|---|
| Battery temperature | Predicted average battery temperature over time | degrees Celsius |
| Heat generated | Electrical heat generated inside the battery | watts |
| Heat removed | Heat removed by cooling | watts |
| Net heat | Difference between generated and removed heat | watts |
| Temperature rise rate | Rate of temperature change | degrees Celsius per second |
| Thermal status | Safe, warning, or critical condition | text or integer class |

## Governing Equation

The model is based on conservation of energy.

The thermal energy stored in the battery changes according to the difference between heat generated inside the battery and heat removed to the surrounding environment.

The governing equation is:

```text
mCp dT/dt = I^2R - hA(T - Tamb)
```

Where:

| Symbol | Meaning |
|---|---|
| m | Battery mass |
| Cp | Specific heat capacity |
| T | Battery temperature |
| t | Time |
| I | Battery current |
| R | Internal resistance |
| h | Convective heat transfer coefficient |
| A | Effective cooling surface area |
| Tamb | Ambient temperature |

This equation states that temperature increases when heat generation is greater than cooling heat removal. Temperature stabilizes when generated heat and removed heat become equal.

## Heat Generation Model

The first heat generation model uses Joule heating:

```text
Qgen = I^2R
```

This represents electrical power loss converted into heat inside the battery.

The current term is squared. This means that increasing current has a strong nonlinear effect on heat generation. For example, doubling current increases heat generation by a factor of four if resistance remains constant.

This is one reason high-current charging and discharging can rapidly increase battery temperature.

## Cooling Model

Cooling is represented by a convection-based heat removal model:

```text
Qcool = hA(T - Tamb)
```

This means that heat removal depends on the difference between battery temperature and ambient temperature. If the battery is hotter than the environment, heat leaves the battery. If cooling effectiveness increases, the model removes heat faster.

The combined term hA represents the total cooling strength. In the first MATLAB model, hA can be treated as a single effective cooling parameter.

## Temperature Update Method

The continuous differential equation can be solved numerically using a time-stepping approach.

At each time step, MATLAB calculates:

1. Heat generated by the battery.
2. Heat removed by cooling.
3. Net heat stored in the battery.
4. Temperature change during the time step.
5. Updated battery temperature.

The numerical update can be written as:

```text
T_next = T_current + dt * (Qgen - Qcool) / (mCp)
```

Where dt is the time step.

This method is simple and sufficient for the first model. Later stages may use more advanced solvers if the model becomes nonlinear or multi-node.

## Safety Classification

The first model can include a basic thermal status classification.

A possible classification is:

| Temperature Range | Status |
|---|---|
| Below 45 degrees Celsius | Safe |
| 45 to 60 degrees Celsius | Warning |
| Above 60 degrees Celsius | Critical |

These values are placeholders for the first engineering model. Later, the limits should be refined based on selected cell chemistry, manufacturer recommendations, literature values, and experimental safety requirements.

## First Simulation Scenario

The first simulation should use one constant-current case.

Recommended initial values:

| Parameter | Starting Value |
|---|---:|
| Initial temperature | 25 degrees Celsius |
| Ambient temperature | 25 degrees Celsius |
| Current | 80 amperes |
| Internal resistance | 0.005 ohms |
| Battery mass | 2 kilograms |
| Specific heat capacity | 900 joules per kilogram kelvin |
| Cooling coefficient | 10 watts per square meter kelvin |
| Cooling area | 0.08 square meters |
| Simulation duration | 600 seconds |
| Time step | 1 second |

The expected result is a temperature curve that rises quickly at first and then approaches a steady-state value if cooling is sufficient.

## MATLAB Files Required

The first MATLAB stage should contain three scripts.

### baseline_thermal_model.m

This file should contain the function or main calculation block for the thermal model. It should define the heat-generation equation, cooling equation, temperature update equation, and status classification.

### run_baseline_simulation.m

This file should define input parameters and call the baseline model. It should run the simulation and generate plots.

### export_baseline_results.m

This file should export simulation results to CSV so the data can be stored and used later for comparison with Python, COMSOL, and FPGA outputs.

## Expected Figures

The MATLAB stage should generate the following figures.

| Figure | Purpose |
|---|---|
| temperature_vs_time.png | Shows battery temperature evolution |
| heat_generated_vs_time.png | Shows heat generated by electrical loading |
| heat_removed_vs_time.png | Shows cooling heat removal over time |
| net_heat_vs_time.png | Shows whether the battery is heating or stabilizing |
| thermal_status_vs_time.png | Shows safe, warning, and critical zones |

## Expected Dataset Export

The exported CSV should include at least the following columns.

| Column | Description |
|---|---|
| time_s | Simulation time |
| temperature_C | Battery temperature |
| ambient_temperature_C | Ambient temperature |
| current_A | Battery current |
| internal_resistance_ohm | Battery internal resistance |
| heat_generated_W | Heat generated |
| heat_removed_W | Heat removed |
| net_heat_W | Heat generated minus heat removed |
| dTdt_C_per_s | Temperature rise rate |
| thermal_status | Safe, warning, or critical |

## GitHub Documentation Requirements

Every result from Stage 1 should be documented in the repository.

The Stage 1 documentation should include:

1. The purpose of the MATLAB baseline model.
2. The assumptions made.
3. The governing equation.
4. The selected input values.
5. The simulation duration and time step.
6. The generated plots.
7. The exported CSV file.
8. A short interpretation of the results.
9. The limitations of the model.
10. The next planned improvement.

## Model Limitations

The Stage 1 model has deliberate limitations.

It does not model internal cell geometry. It does not show local hot spots. It does not distinguish between individual cells. It does not calculate cooling channel flow. It does not include state of charge, temperature-dependent resistance, degradation, electrochemical effects, or thermal runaway chemistry.

These limitations are acceptable because the purpose of Stage 1 is not high-fidelity battery simulation. The purpose is to establish the first physical baseline and prepare the project for structured development.

## Stage 1 Success Criteria

Stage 1 is complete when the following items are available:

1. A written project description.
2. A documented baseline equation.
3. A MATLAB model that calculates temperature over time.
4. At least one temperature-versus-time plot.
5. Heat-generation and heat-removal plots.
6. A CSV export of simulation results.
7. A short written interpretation of the results.
8. A documented list of assumptions and limitations.
9. A clear plan for the next stage.

## Next Stage

After the first constant-current simulation works, the next stage should introduce multiple scenarios. These scenarios may include low current, medium current, high current, weak cooling, strong cooling, high ambient temperature, and changing current profiles.

This will prepare the project for larger parameter sweeps and later COMSOL high-fidelity modeling.
