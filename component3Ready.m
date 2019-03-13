%Contains the method for processing a C3Ready event, which occurs when 
%inspector two finishes inspecting a component three. The component needs
%to be placed in the queue, we must check if we can now make
%any products, and we must start inspecting the next component 2 or 3
function component3Ready()
    global queueC1W3 queueC3W3 inspectorTwoBlocked FEL;
    global P3InProduction;
    
    if queueC3W3 == 2%cannot place component in queue if queue is full
        inspectorTwoBlocked = true;
    else %there is space to place the component
        if ~isQueueEmpty(queueC1W3) && ~P3InProduction 
            %start building a product if we have other components and a product
            %is not currently being produced
            queueC1W3 = queueC1W3 - 1;
            P3InProduction = true;
            %TO DO: clear workstation idle bit, generate P3BuiltEvent
        else
            queueC3W3 = queueC3W3 + 1;
        end  
        e = getNextInspector2Event();
        FEL = FEL.addEvent(e);
    end
end