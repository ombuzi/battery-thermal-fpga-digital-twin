# Project Description

## Project Title

FPGA-Accelerated Battery Thermal Digital Twin for Real-Time Safety Prediction

## Author

Frank Ouma

## Purpose of the Project

This project is a model-based hardware engineering portfolio project focused on battery thermal prediction, simulation-driven surrogate modeling, and FPGA-based real-time deployment. The project investigates how a battery thermal system can be understood from first principles, simulated under different operating conditions, approximated using a trained surrogate model, and implemented as a low-latency hardware inference system.

The project is designed to demonstrate the complete engineering path from concept to a physical solution. It begins with a simplified mathematical model, advances into high-fidelity multiphysics simulation, generates data for machine learning, converts the learned model into an FPGA-friendly numerical form, and finally defines the embedded electronics required for a physical battery thermal prediction controller.

The project is not limited to software simulation. The final direction is a deployable controller that can receive measured battery signals, estimate thermal behavior, predict future risk, and trigger visible or functional outputs such as indicators, cooling control, warning signals, and safety actions.

## Engineering Motivation

Battery systems are widely used in electric vehicles, hybrid vehicles, drones, robotics, industrial backup power systems, grid storage, portable equipment, and defense power systems. In these applications, battery safety and performance depend heavily on temperature control.

During charging and discharging, a battery generates heat. This heat is influenced by current, internal resistance, state of charge, cell condition, ambient temperature, cooling effectiveness, material properties, and operating time. If heat is generated faster than it is removed, battery temperature rises. If the rise is not controlled, the battery can experience accelerated degradation, reduced performance, cell imbalance, hot-spot formation, and in severe cases thermal runaway.

A basic monitoring system can measure present temperature using sensors. However, present temperature alone is not sufficient for predictive safety. A battery may appear safe at the current moment while its future temperature trajectory is moving toward a dangerous condition. The hidden internal thermal response and future thermal evolution are not directly available from raw sensor readings alone.

The central engineering motivation of this project is therefore to move from simple monitoring to predictive thermal intelligence.

## Main Engineering Question

The main question investigated in this project is:

Can measured battery operating conditions be used to predict future battery temperature and thermal risk in real time using a physics-informed surrogate model deployed on FPGA hardware?

This question connects physics, simulation, data generation, machine learning, digital hardware design, and embedded product architecture.

## Concept-to-Physical-Solution Direction

The project follows a full concept-to-physical-solution methodology.

The concept begins with a battery system that may experience unsafe thermal behavior under load. The first task is to understand the physical behavior using mathematical heat-balance modeling. The second task is to improve the physical understanding through high-fidelity simulation. The third task is to generate a dataset that maps operating conditions to thermal outputs. The fourth task is to train a surrogate model that approximates the high-fidelity simulation. The fifth task is to optimize this model for deterministic low-latency inference. The sixth task is to implement the model on FPGA hardware. The final task is to define the embedded electronics and PCB architecture needed to connect sensors, processing hardware, communication interfaces, and control outputs.

The final physical solution is a battery thermal prediction controller. This controller would receive input signals from sensors, process them through a trained model, predict thermal behavior, and produce outputs for warning, cooling, communication, or safety control.

## System Being Studied

The physical system is a simplified battery module with electrical heat generation and thermal interaction with its environment. In the first stage, the battery is treated as a single lumped thermal body with one average temperature. This assumption is acceptable for a baseline model because it allows the basic energy balance to be studied clearly.

Later stages will increase fidelity by including geometry, material layers, multiple cells, cooling channels, temperature gradients, hot-spot behavior, and fluid cooling effects.

## Stage-Based Development Strategy

The project will be developed in stages.

Stage 1 establishes a MATLAB baseline model. This stage focuses on the fundamental heat-balance relationship between electrical heat generation, cooling heat removal, and battery temperature rise.

Stage 2 improves the MATLAB model by introducing variable current profiles, multiple operating cases, and early safety classification.

Stage 3 develops a high-fidelity COMSOL model to study three-dimensional thermal behavior, temperature gradients, cooling effects, and hot-spot formation.

Stage 4 generates a parametric simulation dataset from COMSOL and MATLAB.

Stage 5 uses Python to clean the dataset, engineer features, train a surrogate model, and validate prediction accuracy.

Stage 6 converts the trained surrogate model into a fixed-point or integer representation suitable for FPGA implementation.

Stage 7 implements the optimized model on FPGA hardware using Vitis HLS, Verilog, or a combined approach.

Stage 8 defines the embedded electronics and PCB architecture required to connect sensors, ADCs, actuators, and communication systems.

Stage 9 validates the full chain by comparing the mathematical model, COMSOL simulation, surrogate model, quantized model, FPGA output, and physical demonstration behavior.

## Role of MATLAB in the Project

MATLAB is used first because it is effective for engineering mathematics, quick numerical simulation, plotting, and system-level analysis. In this project, MATLAB provides the first scientific baseline.

The MATLAB model does not attempt to represent every physical detail. Its role is to establish the basic thermal behavior of the system using a transparent equation. This gives the project a defensible starting point before moving to more complex tools.

The MATLAB stage also provides early results that can be stored, plotted, exported, and compared against future COMSOL and FPGA outputs.

## Role of COMSOL in the Project

COMSOL will later be used for high-fidelity multiphysics modeling. Its role is to model geometry, material behavior, heat transfer, cooling structures, thermal gradients, and hot-spot formation. COMSOL provides a more detailed approximation of the physical system than the MATLAB baseline model.

In the project methodology, COMSOL acts as the high-fidelity physics reference from which simulation datasets can be generated.

## Role of Python in the Project

Python will be used after simulation data becomes available. Its role is to clean datasets, normalize variables, engineer features, train surrogate machine learning models, validate prediction accuracy, perform quantization experiments, and prepare model parameters for FPGA implementation.

Python connects simulation results to machine learning and hardware deployment.

## Role of FPGA Hardware in the Project

The FPGA is used to implement the trained surrogate model as deterministic low-latency hardware. The FPGA is not used merely to turn indicators on and off. Simple threshold logic could be handled by an Arduino or basic microcontroller.

The FPGA becomes justified when the system performs repeated real-time prediction using a model that contains many arithmetic operations. The FPGA can execute these operations in parallel, with predictable timing and low latency. The visible outputs such as LEDs, buzzers, fans, relays, or dashboard signals are only the physical demonstration of the prediction result.

## Expected Final Demonstration

The final demonstration may use a safe battery test setup or simulated sensor inputs. The system will receive measurements such as temperature, current, voltage, coolant flow, and ambient temperature. The FPGA-based model will estimate current thermal condition, future temperature, and risk level. The output may be shown through indicators, fan control, relay logic, serial communication, CAN message, or dashboard display.

The important achievement is that the control action is based on predictive thermal modeling rather than simple temperature threshold monitoring.

## Professional Relevance

This project is relevant to several engineering domains, including battery management systems, electric vehicles, hybrid vehicles, robotics, aerospace systems, industrial power systems, energy storage systems, embedded artificial intelligence, FPGA acceleration, predictive maintenance, and digital twin development.

It demonstrates competence in physics-based modeling, numerical simulation, data generation, surrogate modeling, fixed-point numerical design, FPGA implementation, embedded systems architecture, and technical documentation.

## Stage 1 Deliverable Summary

The first deliverables are:

1. Project description document.
2. MATLAB baseline modeling document.
3. Baseline equation document.
4. Initial repository README.
5. MATLAB script plan.
6. Baseline simulation output plan.
7. GitHub-ready documentation structure.

These documents establish the technical foundation for the rest of the project.
