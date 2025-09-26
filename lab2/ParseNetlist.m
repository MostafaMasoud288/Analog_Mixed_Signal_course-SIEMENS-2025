function [Node_1 Node_2 Node_3 Node_4 Values Names] = ParseNetlist(netlist, instances_key)

%{
Part 1: We loop on the netlist lines to search for the given instances' key
For each hit (instance found) we save the fist, and second nodes, value,
and name
Part 2: Evaluating prefixes
%}

Node_1 = {};
Node_2 = {};
Node_3 = {};
Node_4 = {};
Values = {};
Names  = {};

%__Part 1__
%We loop starting from line_number = 2 to skip the title (the first line)
for line_number = 2:1:numel(netlist)
    line = netlist{line_number};
    %Check if the first letter in the line matches the key
    if line(1) == upper(instances_key)
        %Split the line at spaces
        splitted_line = strsplit(line);
        %Remove the empty cells due to strsplit function
        splitted_line = splitted_line(~cellfun('isempty',splitted_line));
        %Splitted_line = 'Name' 'Node_1' 'Node_2' 'Value'
        %Append each cell to its vector
        if length(splitted_line) > 4 
        Node_1 = [Node_1 splitted_line(2)];
        Node_2 = [Node_2 splitted_line(3)];
        Node_3 = [Node_3 splitted_line(4)];
        Node_4 = [Node_4 splitted_line(5)];
        Values = [Values splitted_line(6)];
        Names = [Names splitted_line(1)];
        else 
        Node_1 = [Node_1 splitted_line(2)];
        Node_2 = [Node_2 splitted_line(3)];
        Node_3 = [Node_3 ""];
        Node_4 = [Node_4 ""];
        Values = [Values splitted_line(4)];
        Names = [Names splitted_line(1)];
        end
    end
end

%__Part 2__

%Prefixes map
symbols = {'f', 'p', 'n', 'u', 'm', 'k', 'meg', 'g', 't'};
factors = [1e-15 1e-12 1e-9 1e-6 1e-3 1e3 1e6 1e9 1e12];
for value_number = 1:1:numel(Values)
    value  = Values{value_number};
    strrep(value, 'A', '');
    strrep(value, 'V', '');
    strrep(value, 'ohm', '');
    %Add 000 to avoid errors in the checking processes
    value = strcat('000', value);
    %check if it's meg
    checked_prefix = ismember(symbols, lower(value(end-2:end)));
    if any(checked_prefix)
        value = str2num(value(1:end-3)) * factors(checked_prefix);
        value = num2str(value);
    end
    
    %check if it's any prefix else
    checked_prefix = ismember(symbols, lower(value(end)));
    if any(checked_prefix)
        value = str2num(value(1:end-1)) * factors(checked_prefix);
        value = num2str(value);
    end
    Values(value_number) = cellstr(value);
end
end