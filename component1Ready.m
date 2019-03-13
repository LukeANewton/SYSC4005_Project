%Contains the method for processing a C1Ready event, which occurs when 
%inspector one finishes inspecting a component one. The component needs
%to be placed in the appropriate queue, we must check if we can now make
%any products, and we must start inspecting the next component one
function component1Ready()
    global queueC1W1 queueC1W2 queueC1W3 queueC2W2 queueC3W3 inspectorOneBlocked FEL;
    global alternativeStrategy alternativePriority lastQueueC1PlacedIn;
    global P1InProduction P2InProduction P3InProduction;
    
    if queueC1W1 == 2 && queueC1W2 == 2 && queueC1W3 == 2
        %all queues full, block inspector one
        inspectorOneBlocked = true;
    else
        %there is space for a component 1 somewhere, we must figure out
        %which queue to place the component in
        componentPlaced = false;
        if alternativeStrategy %use alternative round-robin approach
            if lastQueueC1PlacedIn == 0 || lastQueueC1PlacedIn == 3
                componentPlaced = attemptC1W1Placement(componentPlaced);
                componentPlaced = attemptC1W2Placement(componentPlaced);
                componentPlaced = attemptC1W3Placement(componentPlaced);
            elseif lastQueueC1PlacedIn == 1
                componentPlaced = attemptC1W2Placement(componentPlaced);
                componentPlaced = attemptC1W3Placement(componentPlaced);
                componentPlaced = attemptC1W1Placement(componentPlaced);
            elseif lastQueueC1PlacedIn == 2
                componentPlaced = attemptC1W3Placement(componentPlaced);
                componentPlaced = attemptC1W1Placement(componentPlaced);
                componentPlaced = attemptC1W2Placement(componentPlaced);
            end
        else %use original place in smallest queue approach
            if queueC1W1 < queueC1W2 && queueC1W1 < queueC1W3 %C1 queue is smallest
                componentPlaced = attemptC1W1Placement(componentPlaced);
            elseif queueC1W2 < queueC1W1 && queueC1W2 < queueC1W3 %C2 queue is smallest
                componentPlaced = attemptC1W2Placement(componentPlaced);
            elseif queueC1W3 < queueC1W2 && queueC1W3 < queueC1W1 %C3 queue is smallest
                componentPlaced = attemptC1W3Placement(componentPlaced);
            else %two queue have the same size
                if alternativePriority %use alternative priority of workstations 3, then 2, then 1
                    if queueC1W1 == queueC1W2 && queueC1W1 == queueC1W3 %all queues the same size
                        componentPlaced = attemptC1W3Placement(componentPlaced);
                    elseif queueC1W1 == queueC1W2 %workstation 1 and 2 have same queue length
                        componentPlaced = attemptC1W2Placement(componentPlaced);
                    elseif queueC1W1 == queueC1W3 %workstation 1 and 3 have same queue length
                        componentPlaced = attemptC1W3Placement(componentPlaced);
                    elseif queueC1W3 == queueC1W2 %workstation 3 and 2 have same queue length
                        componentPlaced = attemptC1W3Placement(componentPlaced);
                    end
                else %use original priority of workstations 1, then 2, then 3
                    if queueC1W1 == queueC1W2 && queueC1W1 == queueC1W3 %all queues the same size
                        componentPlaced = attemptC1W1Placement(componentPlaced);
                    elseif queueC1W1 == queueC1W2 %workstation 1 and 2 have same queue length
                        componentPlaced = attemptC1W1Placement(componentPlaced);
                    elseif queueC1W1 == queueC1W3 %workstation 1 and 3 have same queue length
                        componentPlaced = attemptC1W1Placement(componentPlaced);
                    elseif queueC1W3 == queueC1W2 %workstation 3 and 2 have same queue length
                        componentPlaced = attemptC1W2Placement(componentPlaced);
                    end
                end
            end
        end
        %by now, a component should have been placed, we can verify
        %this by uncommenting the following 2 lines:
        fprintf("component one placed = %d\n", componentPlaced);
        fprintf("component one last placed in workstation %d queue\n", lastQueueC1PlacedIn);
        
        %we know a component has been placed in a queue, can we now make a product?
        if lastQueueC1PlacedIn == 1 && ~P1InProduction%we can make a product 1
            queueC1W1 = queueC1W1 - 1;
            P1InProduction = true;
            %TO DO: clear workstation idle bit, generate P1BuiltEvent
        elseif lastQueueC1PlacedIn == 2 && queueC2W2 > 0 && P2InProduction%we can make a product 2
            queueC1W2 = queueC1W2 - 1;
            queueC2W2 = queueC2W2 - 1;
            P2InProduction = true;
            %TO DO: clear workstation idle bit, generate P2BuiltEvent
        elseif lastQueueC1PlacedIn == 2 && queueC3W3 > 0 && ~P3InProduction%we can make a product 3
            queueC1W3 = queueC1W3 - 1;
            queueC3W3 = queueC3W3 - 1;
            P3InProduction = true;
            %TO DO: clear workstation idle bit, generate P3BuiltEvent
        end 
        %at this point, we have started building any products that can be
        %built, all that is left to do is begin inspecting the next
        %component one
        e = getNextInspector1Event();
        FEL = FEL.addEvent(e);
    end
end

% function place a component one in workstation 1 queue if there is space
function componentPlaced = attemptC1W1Placement(componentPlaced) 
    global queueC1W1 lastQueueC1PlacedIn;
    if queueC1W1 < 2 && ~componentPlaced
        queueC1W1 = queueC1W1 + 1;
        componentPlaced = true;
        lastQueueC1PlacedIn = 1;
    end
end

% function place a component one in workstation 2 queue if there is space
function componentPlaced = attemptC1W2Placement(componentPlaced) 
    global queueC1W2 lastQueueC1PlacedIn;
    if queueC1W2 < 2 && ~componentPlaced
        queueC1W2 = queueC1W2 + 1;
        componentPlaced = true;
        lastQueueC1PlacedIn = 2;
    end
end

% function place a component one in workstation 1 queue if there is space
function componentPlaced = attemptC1W3Placement(componentPlaced) 
    global queueC1W3 lastQueueC1PlacedIn;
    if queueC1W3 < 2 && ~componentPlaced
        queueC1W3 = queueC1W3 + 1;
        componentPlaced = true;
        lastQueueC1PlacedIn = 3;
    end
end