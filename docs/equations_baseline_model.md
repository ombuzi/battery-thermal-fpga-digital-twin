# Baseline Thermal Model Equations

## Author

Frank Ouma

## Purpose of This Document

This document records the mathematical foundation of the Stage 1 MATLAB baseline thermal model. The purpose is to define the equations used to represent battery heat generation, cooling heat removal, temperature evolution, and basic thermal status classification.

The equations documented here form the first physics reference for the battery thermal digital twin project. Later COMSOL simulations, surrogate machine learning models, quantized models, and FPGA outputs will be compared against this baseline understanding.

## Modeling Approach

The Stage 1 model uses a lumped thermal approach. The battery is represented as a single thermal mass with one average temperature. This means the entire battery is assumed to heat and cool uniformly.

This is a simplifying assumption. It removes internal geometry, cell-to-cell variation, temperature gradients, and hot spots from the first model. The simplification is useful because it allows the fundamental energy balance to be studied clearly before moving to higher-fidelity simulation.

## Conservation of Energy

The core principle is conservation of energy.

The rate of thermal energy stored in the battery is equal to the heat generated inside the battery minus the heat removed from the battery.

In word form:

```text
Rate of thermal energy storage = heat generation - heat removal
```

In mathematical form:

```text
mCp dT/dt = Qgen - Qcool
```

Where:

| Symbol | Meaning | Unit |
|---|---|---|
| m | Battery mass | kg |
| Cp | Specific heat capacity | J/kgK |
| T | Battery temperature | degrees Celsius or kelvin |
| t | Time | seconds |
| Qgen | Heat generated inside battery | W |
| Qcool | Heat removed from battery | W |

The product mCp is the thermal capacity of the battery. It represents how much energy is required to raise the battery temperature by one degree.

A high value of mCp means the battery temperature changes slowly. A low value means the battery temperature changes quickly.

## Electrical Heat Generation

The first heat generation model is based on Joule heating.

```text
Qgen = I^2R
```

Where:

| Symbol | Meaning | Unit |
|---|---|---|
| Qgen | Heat generated | W |
| I | Battery current | A |
| R | Internal resistance | ohm |

This equation states that electrical losses inside the battery are converted into heat.

The most important feature of this equation is the squared current term. If current increases, heat generation increases strongly.

For example, if the current doubles and resistance remains constant, the generated heat becomes four times larger.

This explains why high-power discharge and fast charging can create serious thermal stress in battery systems.

## Cooling Heat Removal

The first cooling model uses a convection-style heat removal equation.

```text
Qcool = hA(T - Tamb)
```

Where:

| Symbol | Meaning | Unit |
|---|---|---|
| Qcool | Heat removed by cooling | W |
| h | Convective heat transfer coefficient | W/m2K |
| A | Effective cooling surface area | m2 |
| T | Battery temperature | degrees Celsius or kelvin |
| Tamb | Ambient temperature | degrees Celsius or kelvin |

The temperature difference T - Tamb drives heat transfer. If the battery is hotter than the environment, heat leaves the battery. If the battery temperature is close to ambient temperature, less heat is removed.

The product hA is often treated as an effective cooling strength in the simplified model.

A larger hA value means stronger cooling. A smaller hA value means weaker cooling.

## Full Baseline Equation

Substituting heat generation and cooling into the conservation equation gives:

```text
mCp dT/dt = I^2R - hA(T - Tamb)
```

Solving for the temperature rate of change gives:

```text
dT/dt = [I^2R - hA(T - Tamb)] / mCp
```

This equation is the central baseline equation for Stage 1.

It shows that battery temperature rises when I2R is greater than hA(T - Tamb). It also shows that battery temperature falls or stabilizes when cooling becomes equal to or greater than heat generation.

## Numerical Time-Stepping Equation

For MATLAB implementation, the continuous equation can be approximated using a discrete time step.

```text
T_next = T_current + dt * [I^2R - hA(T_current - Tamb)] / mCp
```

Where:

| Symbol | Meaning |
|---|---|
| T_next | Battery temperature at the next time step |
| T_current | Battery temperature at the current time step |
| dt | Time step |

This equation allows MATLAB to update the battery temperature second by second or using any selected time step.

## Steady-State Temperature

At steady state, temperature stops changing. Therefore:

```text
dT/dt = 0
```

Using the baseline equation:

```text
0 = I^2R - hA(Tsteady - Tamb)
```

Solving for steady-state temperature:

```text
Tsteady = Tamb + I^2R / hA
```

This equation gives the final temperature the battery approaches if current, resistance, ambient temperature, and cooling strength remain constant.

The steady-state expression is useful for checking simulation results. If the MATLAB time simulation approaches this value, the numerical model is behaving correctly.

## Thermal Time Constant

The baseline model also has a thermal time constant.

```text
tau = mCp / hA
```

Where tau represents how quickly the battery responds thermally.

A large tau means the battery heats and cools slowly. A small tau means the battery responds quickly to changes in heat generation or cooling.

The thermal time constant helps explain why battery temperature does not instantly jump when current changes. The battery has thermal inertia.

## Analytical Temperature Response for Constant Current

For constant current, constant resistance, constant ambient temperature, and constant cooling strength, the temperature response approaches steady state exponentially.

```text
T(t) = Tamb + I^2R/hA + [T0 - Tamb - I^2R/hA] exp(-t/tau)
```

Where:

| Symbol | Meaning |
|---|---|
| T(t) | Temperature at time t |
| T0 | Initial battery temperature |
| tau | Thermal time constant |

This analytical expression is useful for verifying the numerical MATLAB implementation.

## Temperature Rise Rate

The temperature rise rate is:

```text
dT/dt = [Qgen - Qcool] / mCp
```

This value is useful because the temperature itself may still be within safe limits while the rise rate indicates that the battery is moving toward a dangerous condition.

A high positive dT/dt means temperature is increasing quickly. A near-zero dT/dt means the battery is approaching thermal equilibrium. A negative dT/dt means the battery is cooling.

## Net Heat

Net heat is defined as:

```text
Qnet = Qgen - Qcool
```

If Qnet is positive, the battery gains heat and temperature rises.

If Qnet is zero, the battery is in thermal balance.

If Qnet is negative, the battery loses heat and temperature falls.

This value is important for interpreting the model because temperature change depends directly on net heat.

## Basic Thermal Status Classification

The first model can define basic thermal status from predicted temperature.

A simple first-stage classification is:

| Condition | Classification |
|---|---|
| T < 45 degrees Celsius | Safe |
| 45 degrees Celsius <= T < 60 degrees Celsius | Warning |
| T >= 60 degrees Celsius | Critical |

This classification is not final. It is a first-stage engineering placeholder. Later stages should refine these limits based on battery chemistry, manufacturer data, literature, and application-specific safety requirements.

## Predictive Interpretation

The MATLAB baseline model is not only a present-temperature calculator. It can predict future temperature under assumed operating conditions.

If the current, resistance, ambient temperature, and cooling strength are known, the model can estimate the temperature trajectory for the next several seconds or minutes.

This is the foundation of the full project. The high-fidelity COMSOL model and later surrogate model will extend this same idea with greater physical detail.

## Relevance to Surrogate Modeling

The baseline equation shows that thermal behavior is a mapping from input conditions to output temperature behavior.

The inputs include current, resistance, ambient temperature, cooling strength, battery thermal capacity, and time.

The outputs include temperature, heat generated, heat removed, net heat, rise rate, and thermal status.

Later, COMSOL will generate a more detailed input-output map using geometry, materials, cooling flow, and boundary conditions. Python will then train a surrogate model to approximate that high-fidelity map. The FPGA will implement the optimized surrogate model for real-time prediction.

## Relevance to FPGA Implementation

The baseline model also shows why FPGA implementation may become useful. The final system is expected to process sensor values and produce predictions quickly. For a simple single-equation threshold system, a microcontroller is enough. However, for a multi-input surrogate model evaluating many arithmetic operations in real time, FPGA hardware can provide low-latency deterministic computation.

The equations in this document therefore form the starting point of the engineering path from thermal physics to hardware-accelerated prediction.

## Assumptions

The Stage 1 baseline model assumes:

1. The battery has one uniform average temperature.
2. Internal resistance is constant.
3. Current is constant during the first simulation case.
4. Ambient temperature is constant.
5. Cooling strength is represented by a single hA value.
6. Heat generation is approximated by I2R.
7. Radiation heat transfer is neglected.
8. Thermal runaway chemistry is not included.
9. Cell-to-cell variation is not included.
10. Cooling fluid dynamics are not included.

These assumptions are acceptable for the first baseline model but must be expanded in later stages.

## Limitations

The model cannot predict hot spots, internal gradients, cooling channel pressure drop, cell imbalance, local thermal runaway initiation, complex electrochemical heat generation, or detailed three-dimensional thermal behavior.

The model is therefore not a replacement for COMSOL. It is a first-principles reference model used to build understanding and create a structured foundation.

## Summary

The Stage 1 model is built on a simple energy balance. Electrical current generates heat through internal resistance. Cooling removes heat through a convection-style mechanism. The difference between generated heat and removed heat determines how battery temperature changes over time.

The central equation is:

```text
mCp dT/dt = I^2R - hA(T - Tamb)
```

This equation establishes the first scientific baseline for the full battery thermal digital twin project.
