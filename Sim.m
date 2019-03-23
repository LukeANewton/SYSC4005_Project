%Main control flow for the queuing system simulation.
clc; clear; %clear workspace and command window

%variables which affect program control flow
global alternativeStrategy alternativePriority maxSimulationTime seed verbose;
filename = 'SimResults.txt'; %change to set the filename/path for the simulaiton output
maxSimulationTime = 500; %change to set the length of time the simulation runs
seed = 420; %change to set the seed used in random number generation
alternativeStrategy = false; %set true to use alternative round-robin C1 scheduling
alternativePriority = false; %set true to use alternative C1 queue priorities
verbose = true; %set true to have information on the status of the program displayed in the console window

%initialize model
if verbose
    fprintf('initailizing variables...\n');
end
%number value representing the amount of time passed in the simulation
global clock;
%six distributiuon objects for service times of each inspector/workstation
global C1Dist C2Dist C3Dist W1Dist W2Dist W3Dist;
%the future event list for the simulation
global FEL;
%number values representing how long each inspector/workstation has spent idle
global Inspector1IdleTime Inspector2IdleTime;
global Workstation1IdleTime Workstation2IdleTime Workstation3IdleTime;
%integer values indicating the number of each product that has been produced
global P1Produced P2Produced P3Produced;
%integer values indicating the number of each component that has been inspected
global C1Inspected C2Inspected C3Inspected;
%integer indicating the last queue a C1 was placed in
global lastQueueC1PlacedIn;
%integer (2 or 3) defining the type of component inspector 2 most recently
%insepceted/is inspecting
global lastComponentInspector2Held;
%six integers representing the size of each queue in the system
global queueC1W1 queueC1W2 queueC1W3 queueC2W2 queueC3W3;
%boolean values indicating if a product is currently in production
global P1InProduction P2InProduction P3InProduction;
%boolean values which indicate if each inpector is blocked
global inspectorOneBlocked inspectorTwoBlocked;
%boolean values which indicate if each workstation is idle
global workstationOneIdle workstationTwoIdle workstationThreeIdle;
%six integers representing start/stop times for each workstation being idle
global idleStartW1 idleEndW1 idleStartW2 idleEndW2 idleStartW3 idleEndW3;
%six integers representing start/stop times for each inspector being idle
global idleStartI1 idleEndI1 idleStartI2 idleEndI2; 
%boolean value which indicates if clock has reached max simulation time
global timeToEndSim;
%independent random number streams for each of the 6 distriutions
global rngC1 rngC2 rngC3 rngW1 rngW2 rngW3
initializeGlobals();
initializeRandomNumberStreams();
initializeDistributions();
initializeFEL();

%main program loop - while FEL not empty, process the next event
if verbose
    fprintf('begining main program loop...\n');
end
while FEL.listSize > 0 && ~timeToEndSim
    if verbose
        fprintf('\n');
        FEL.printList();
    end
   [nextEvent, FEL] = FEL.getNextEvent();
    processEvent(nextEvent);
    if verbose
        fprintf('queue C1W1: %d components\n', queueC1W1);
        fprintf('queue C1W2: %d components\n', queueC1W2);
        fprintf('queue C1W3: %d components\n', queueC1W3);
        fprintf('queue C2W2: %d components\n', queueC2W2);
        fprintf('queue C3W3: %d components\n', queueC3W3);
    end
end
%processed all events - write statistics to file
updateIdleTimes();
if verbose
    fprintf('\n');
    fprintf('printing results...\n');
end
fd = fopen(filename, 'w');
fprintf(fd, 'Total simulation time: %f seconds\n\n', clock);
fprintf(fd, 'Number of product 1 produced: %d\n', P1Produced);
fprintf(fd, 'Number of product 2 produced: %d\n', P2Produced);
fprintf(fd, 'Number of product 3 produced: %d\n\n', P3Produced);
fprintf(fd, 'Total number of component 1 used in production: %d\n', P1Produced + P2Produced + P3Produced);
fprintf(fd, 'Total number of component 2 used in production: %d\n', P2Produced);
fprintf(fd, 'Total number of component 3 used in production: %d\n\n', P2Produced);
fprintf(fd, 'Total number of component 1 used in production or in queues at end of simulation: %d\n', P1Produced + P2Produced + P3Produced + queueC1W1 + queueC1W2 + queueC1W3 + P1InProduction);
fprintf(fd, 'Total number of component 2 used in production or in queues at end of simulation: %d\n', P2Produced + queueC2W2 + P2InProduction);
fprintf(fd, 'Total number of component 2 used in production or in queues at end of simulation: %d\n\n', P3Produced + queueC3W3 + P3InProduction);
fprintf(fd, 'Number of component 1 inspected: %d\n', C1Inspected);
fprintf(fd, 'Number of component 2 inspected: %d\n', C2Inspected);
fprintf(fd, 'Number of component 3 inspected: %d\n\n', C3Inspected);
fprintf(fd, 'Time inspector one spent idle: %f minutes\n', Inspector1IdleTime);
fprintf(fd, 'Time inspector two spent idle: %f minutes\n', Inspector2IdleTime);
fprintf(fd, 'Time workstation one spent idle: %f minutes\n', Workstation1IdleTime);
fprintf(fd, 'Time workstation two spent idle: %f minutes\n', Workstation2IdleTime);
fprintf(fd, 'Time workstation three spent idle: %f minutes\n', Workstation3IdleTime);
fclose(fd);
if verbose
    fprintf('simulation complete!\n');
end
%END OF MAIN CONTROL FLOW

%creates the 6 distribution functions with parameters determined through 
%input modelling in deliverable 1
function initializeDistributions()
    global C1Dist C2Dist C3Dist W1Dist W2Dist W3Dist;
    C1Dist = makedist('Exponential', 'mu', 10.35791);
    C2Dist = makedist('Exponential', 'mu', 15.537);
    C3Dist = makedist('Exponential', 'mu', 20.63276);
    W1Dist = makedist('Exponential', 'mu', 4.604417);
    W2Dist = makedist('Exponential', 'mu', 11.093);
    W3Dist = makedist('Exponential', 'mu', 8.79558);
end

function initializeRandomNumberStreams()
    global seed;
    global rngC1 rngC2 rngC3 rngW1 rngW2 rngW3;

    [rngC1, rngC2, rngC3, rngW1, rngW2, rngW3] = RandStream.create('mrg32k3a', 'Seed', seed, 'NumStreams', 6);
end

%initializes the FEL with the first events for the simulation
function initializeFEL()
    global FEL verbose maxSimulationTime;
    %create first ready event for Inspector 1
    e1 = getNextInspector1Event();
    %create first ready event for Inspector 2
    e2 = getNextInspector2Event();
    %create FEL
    FEL = FutureEventList(e1);
    FEL = FEL.addEvent(e2);
    FEL = FEL.addEvent(Event(maxSimulationTime, EventType.endOfSimulation));
    if verbose
        fprintf('initial ');
        FEL.printList();
    end
end

%initializes each global to starting values
function initializeGlobals()
    global clock Inspector1IdleTime Inspector2IdleTime timeToEndSim;
    global Workstation1IdleTime Workstation2IdleTime Workstation3IdleTime;
    global P1Produced P2Produced P3Produced;
    global C1Inspected C2Inspected C3Inspected
    global P1InProduction P2InProduction P3InProduction;
    global lastQueueC1PlacedIn;
    global queueC1W1 queueC1W2 queueC1W3 queueC2W2 queueC3W3;
    global inspectorOneBlocked inspectorTwoBlocked;
    global workstationOneIdle workstationTwoIdle workstationThreeIdle;
    global idleStartW1 idleEndW1 idleStartW2 idleEndW2 idleStartW3 idleEndW3;
    global idleStartI1 idleEndI1 idleStartI2 idleEndI2;
    %simulation time starts at 0
    clock = 0;
    %all queues start empty
    queueC1W1 = 0;
    queueC1W2 = 0; 
    queueC1W3 = 0; 
    queueC2W2 = 0;
    queueC3W3 = 0; 
    %at begining, have not placed at C1 yet
    lastQueueC1PlacedIn = 0;
    %time starts at zero, so idle times start at 0
    Inspector1IdleTime = 0;
    Inspector2IdleTime = 0;
    Workstation1IdleTime = 0;
    Workstation2IdleTime = 0;
    Workstation3IdleTime = 0;
    %inspectors start unblocked
    inspectorOneBlocked = false;
    inspectorTwoBlocked = false;
    %not producing anything at start of simulation
    P1InProduction = false;
    P2InProduction = false;
    P3InProduction = false;
    %at begining of simulation we have not finished producing any products yet
    P1Produced = 0;
    P2Produced = 0;
    P3Produced = 0;
    %at begining of simulation we have not finished inspecting any components yet
    C1Inspected = 0;
    C2Inspected = 0;
    C3Inspected = 0;
    %workstations start as idle since they at time 0 they are not producing
    workstationOneIdle = true;
    workstationTwoIdle = true;
    workstationThreeIdle = true;
    %at time zero, all idle times start at zero
    idleStartW1 = 0;
    idleEndW1 = 0;
    idleStartW2 = 0;
    idleEndW2 = 0;
    idleStartW3 = 0;
    idleEndW3 = 0;
    idleStartI2 = 0;
    idleEndI2 = 0;
    idleStartI1 = 0;
    idleEndI1 = 0;
    timeToEndSim = false;
end

%after processing events we need to update the total idle times of each
%entity. This is only updated elsewhere when an entity stops being idle, so
%if the simulation ends with an entity idle its idle time value will be
%inaccurate.
function updateIdleTimes()
    global clock;
    global inspectorOneBlocked Inspector1IdleTime idleStartI1;
    global inspectorTwoBlocked Inspector2IdleTime idleStartI2;
    global workstationOneIdle Workstation1IdleTime idleStartW1;
    global workstationTwoIdle Workstation2IdleTime idleStartW2;
    global workstationThreeIdle Workstation3IdleTime idleStartW3;
    
    if inspectorOneBlocked
        Inspector1IdleTime = Inspector1IdleTime + clock - idleStartI1;
    end
    if inspectorTwoBlocked
        Inspector2IdleTime = Inspector2IdleTime + clock - idleStartI2;
    end
    if workstationOneIdle
        Workstation1IdleTime = Workstation1IdleTime + clock - idleStartW1;
    end
    if workstationTwoIdle
        Workstation2IdleTime = Workstation2IdleTime + clock - idleStartW2;
    end
    if workstationThreeIdle
        Workstation3IdleTime = Workstation3IdleTime + clock - idleStartW3;
    end
end

%performs some action in the simulation depending on the type of the event
function processEvent(e)
    global clock verbose timeToEndSim;
    
    if(clock > e.time) %program will terminate if events are not chronological
        error('next event occurs before current simulation time.');
    end  
    clock = e.time;

    if verbose
        fprintf('clock time: %f\n', clock);
        fprintf('processing %s event\n', e.type);
    end
    if e.type == EventType.C1Ready
        component1Ready();
    elseif e.type == EventType.C2Ready
        component2Ready();
    elseif e.type == EventType.C3Ready
        component3Ready();
    elseif e.type == EventType.P1Built
        productOneBuilt();
    elseif e.type == EventType.P2Built
        productTwoBuilt();
    elseif e.type == EventType.P3Built
        productThreeBuilt();
    elseif e.type == EventType.endOfSimulation
        timeToEndSim = true;
    else
        error('Invalid event type');
    end
end