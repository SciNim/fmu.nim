# Sequence

1. fmi2Instantiate: This function creates an instance of the FMU and returns a handle that can be used to access the FMU's functions and data.

2. fmi2SetupExperiment: This function sets up the initial experiment conditions, such as the start time and stop time of the simulation.

3. fmi2EnterInitializationMode: This function puts the FMU into initialization mode, allowing it to perform any necessary initialization tasks.

4. fmi2ExitInitializationMode: This function takes the FMU out of initialization mode and puts it into continuous-time mode, allowing it to start the simulation.

5. fmi2DoStep: This function performs a single step of the simulation. It takes the current simulation time and step size as input, and returns the next simulation time and a status flag indicating whether the simulation should continue or stop.

6. fmi2Terminate: This function terminates the simulation and cleans up any resources used by the FMU.