function [symbolic_ans, numeric_ans] = Solve_Circuit(netlist_directory)

%{
Part 1: reading the netlist
Part 2: parsing the netlist
Part 3: creating the matrices
Part 4: solving the matrices
%}

%__Part 1__

%loading netlist
raw_netlist = fopen(netlist_directory);
raw_netlist = fscanf(raw_netlist, '%c');

%Deleting multiple spaces, etc. using regular expressions
netlist = regexprep(raw_netlist,' *',' ');
netlist = regexprep(netlist,' I','I');
netlist = regexprep(netlist,' R','R');
netlist = regexprep(netlist,' V','V');
netlist = regexp(netlist,'[^\n]*','match');

%__Part 2__
[R_Node_1, R_Node_2, R_Values, R_Names] = ParseNetlist(netlist, 'R');
[V_Node_1, V_Node_2, V_Values, V_Names] = ParseNetlist(netlist, 'V');
[I_Node_1, I_Node_2, I_Values, I_Names] = ParseNetlist(netlist, 'I');

%Counting nodes
nodes_list = [R_Node_1 R_Node_2 V_Node_1 V_Node_2 I_Node_1 I_Node_2];
nodes_number = max(str2double(nodes_list));

%__Part 3__
matrices_size = nodes_number + numel(V_Names);

% Z matrix
unit_matrix = cell(matrices_size, 1);
for i = 1:1:numel(unit_matrix)
    unit_matrix{i} = ['0'];
end
z = unit_matrix;

% Stamping I sources
for I = 1:1:numel(I_Names)
    current_node_1 = str2double(I_Node_1(I));
    current_node_2 = str2double(I_Node_2(I));
    current_name = I_Names{I};
    if current_node_1 ~= 0
        z{current_node_1} = [z{current_node_1} '-' current_name];
    end
    if current_node_2 ~= 0
        z{current_node_2} = [z{current_node_2} '+' current_name];
    end
end

% Stamping V sources
for V = 1:1:numel(V_Names)
    z{nodes_number + V} = [V_Names{V}];
end
Z = cellfun(@str2sym, z);



% X matrix
x = cell(matrices_size, 1);
for node = 1:1:nodes_number
    x{node} = ['V_' num2str(node)];
end
for V = 1:1:numel(V_Names)
    x{nodes_number + V} = ['I_' V_Names{V}];
end
X = cellfun(@str2sym, x);


% A matrix - G part
G = repmat(unit_matrix(1:nodes_number), 1, nodes_number);
for R = 1:1:numel(R_Names)
    current_node_1 = str2double(R_Node_1(R));
    current_node_2 = str2double(R_Node_2(R));
    current_name = R_Names{R};
    if current_node_1 ~= 0
        G{current_node_1, current_node_1} = [G{current_node_1, current_node_1} '+1/' current_name];
    end
    if current_node_2 ~= 0
        G{current_node_2, current_node_2} = [G{current_node_2, current_node_2} '+1/' current_name];
    end
    if current_node_1 ~= 0 && current_node_2 ~= 0
        G{current_node_1, current_node_2} = [G{current_node_1, current_node_2} '-1/' current_name];
        G{current_node_2, current_node_1} = [G{current_node_2, current_node_1} '-1/' current_name];
    end
end

% B matrix
B = repmat(unit_matrix, 1, numel(V_Names));
for V = 1:1:numel(V_Names)
    current_node_1 = str2double(V_Node_1(V));
    current_node_2 = str2double(V_Node_2(V));
    if current_node_1 ~= 0
        B{current_node_1, V} = ['1'];
    end
    if current_node_2 ~= 0
        B{current_node_2, V} = ['-1'];
    end
end

% C matrix
C = B.';

% A matrix (final)
a = [G; C(:,1:nodes_number)];
a = [a B];
A = cellfun(@str2sym, a);


%__Part 4__
% Symbolic solution
symbolic_ans = A \ Z;

% Assign numerical values
for R = 1:1:numel(R_Names)
    eval([R_Names{R} ' = ' num2str(R_Values{R}) ';']);
end

for V = 1:1:numel(V_Names)
    eval([V_Names{V} ' = ' num2str(V_Values{V}) ';']);
end

for I = 1:1:numel(I_Names)
    eval([I_Names{I} ' = ' num2str(I_Values{I}) ';']);
end

% Substitute symbolic values with numerical
numeric_ans = subs(symbolic_ans);

% Print the results
for i = 1:1:numel(symbolic_ans)
    fprintf('%s = %f\n', char(X(i)), double(numeric_ans(i)));
end

end
