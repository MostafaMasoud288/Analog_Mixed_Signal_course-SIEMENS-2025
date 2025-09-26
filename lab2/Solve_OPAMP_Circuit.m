function [symbolic_ans, numeric_ans, frequencies] = Solve_OPAMP_Circuit(netlist_directory, points_per_decade, start_freq, stop_freq)
%{
Enhanced AC circuit solver with support for:
- Resistors (R), Capacitors (C), Inductors (L)
- Voltage sources (V), Current sources (I)
- Voltage-controlled voltage sources (E)
- Voltage-controlled current sources (G)
%}

% Generate frequency sweep
frequencies = logspace(log10(start_freq), log10(stop_freq), round(log10(stop_freq/start_freq) * points_per_decade) + 1);

%__Part 1: Netlist Loading and Preprocessing__
raw_netlist = fopen(netlist_directory);
raw_netlist = fscanf(raw_netlist, '%c');

% Deletion of multiple spaces, etc. using regular expressions
netlist = regexprep(raw_netlist,' *',' ');
netlist = regexprep(netlist,' I','I');
netlist = regexprep(netlist,' R','R');
netlist = regexprep(netlist,' V','V');
netlist = regexprep(netlist,' C','C');
netlist = regexprep(netlist,' L','L');
netlist = regexprep(netlist,' E','E');
netlist = regexprep(netlist,' G','G');
netlist = regexp(netlist,'[^\n]*','match');

%__Part 2: Netlist Parsing__
[R_Node_1, R_Node_2, ~, ~, R_Values, R_Names] = ParseNetlist(netlist, 'R');
[V_Node_1, V_Node_2, ~, ~, V_Values, V_Names] = ParseNetlist(netlist, 'V');
[I_Node_1, I_Node_2, ~, ~, I_Values, I_Names] = ParseNetlist(netlist, 'I');
[C_Node_1, C_Node_2, ~, ~, C_Values, C_Names] = ParseNetlist(netlist, 'C');
[L_Node_1, L_Node_2, ~, ~, L_Values, L_Names] = ParseNetlist(netlist, 'L');
[E_Node_1, E_Node_2, E_Node_3, E_Node_4, E_Values, E_Names] = ParseNetlist(netlist, 'E');
[G_Node_1, G_Node_2, G_Node_3, G_Node_4, G_Values, G_Names] = ParseNetlist(netlist, 'G');

% Counting nodes
nodes_list = [R_Node_1 R_Node_2 V_Node_1 V_Node_2 I_Node_1 I_Node_2 ...
              C_Node_1 C_Node_2 L_Node_1 L_Node_2 E_Node_1 E_Node_2 E_Node_3 E_Node_4 ...
              G_Node_1 G_Node_2 G_Node_3 G_Node_4];
valid_nodes = ~cellfun('isempty', nodes_list);
nodes_number = max(str2double(nodes_list(valid_nodes)));

%__Part 3: Matrix Construction__
matrices_size = nodes_number + numel(V_Names) + numel(E_Names);

% Initialize Z matrix (right-hand side vector)
z = repmat({'0'}, matrices_size, 1);

% Stamp current sources
for I = 1:numel(I_Names)
    current_node_1 = str2double(I_Node_1{I});
    current_node_2 = str2double(I_Node_2{I});
    current_name = I_Names{I};
    if current_node_1 ~= 0
    z{current_node_1} = [z{current_node_1} '+' current_name]; 
    end
    if current_node_2 ~= 0
        z{current_node_2} = [z{current_node_2} '-' current_name]; 
    end
end

% Stamp voltage sources
for V = 1:numel(V_Names)
    z{nodes_number + V} = V_Names{V};
end

% Stamp VCVS (E sources)
for E = 1:numel(E_Names)
    z{nodes_number + numel(V_Names) + E} = '0';
end

% Convert to symbolic
Z = sym(zeros(matrices_size, 1));
for i = 1:matrices_size
    Z(i) = str2sym(z{i});
end

% Initialize X matrix (solution vector)
X = sym(zeros(matrices_size, 1));
for node = 1:nodes_number
    X(node) = sym(['V_' num2str(node)]);
end
for V = 1:numel(V_Names)
    X(nodes_number + V) = sym(['I_' V_Names{V}]);
end
for E = 1:numel(E_Names)
    X(nodes_number + numel(V_Names) + E) = sym(['I_' E_Names{E}]);
end

% Create symbolic variables for all components
component_vars = {};
component_vals = [];
for R = 1:numel(R_Names)
    component_vars{end+1} = sym(R_Names{R});
    component_vals(end+1) = str2double(R_Values{R});
end
for V = 1:numel(V_Names)
    component_vars{end+1} = sym(V_Names{V});
    component_vals(end+1) = str2double(V_Values{V});
end
for I = 1:numel(I_Names)
    component_vars{end+1} = sym(I_Names{I});
    component_vals(end+1) = str2double(I_Values{I});
end
for C = 1:numel(C_Names)
    component_vars{end+1} = sym(C_Names{C});
    component_vals(end+1) = str2double(C_Values{C});
end
for L = 1:numel(L_Names)
    component_vars{end+1} = sym(L_Names{L});
    component_vals(end+1) = str2double(L_Values{L});
end
for E = 1:numel(E_Names)
    component_vars{end+1} = sym(E_Names{E});
    component_vals(end+1) = str2double(E_Values{E});
end
for G = 1:numel(G_Names)
    component_vars{end+1} = sym(G_Names{G});
    component_vals(end+1) = str2double(G_Values{G});
end

% Initialize output variables
symbolic_ans = X;
numeric_ans = zeros(numel(frequencies), matrices_size);

%__Part 4: Frequency Domain Solution__
for freq_x = 1:numel(frequencies)
    current_freq = frequencies(freq_x);
    current_omega = 2 * pi * current_freq;
    
    % Initialize G matrix (conductance part)
    G = sym(zeros(nodes_number, nodes_number));
    
    % Stamp resistors
    for R = 1:numel(R_Names)
        node1 = str2double(R_Node_1{R});
        node2 = str2double(R_Node_2{R});
        conductance = 1/sym(R_Names{R});
        if node1 ~= 0
            G(node1, node1) = G(node1, node1) + conductance;
        end
        if node2 ~= 0
            G(node2, node2) = G(node2, node2) + conductance;
        end
        if node1 ~= 0 && node2 ~= 0
            G(node1, node2) = G(node1, node2) - conductance;
            G(node2, node1) = G(node2, node1) - conductance;
        end
    end
    
    % Stamp capacitors
    for C = 1:numel(C_Names)
        node1 = str2double(C_Node_1{C});
        node2 = str2double(C_Node_2{C});
        admittance = 1i*current_omega*sym(C_Names{C});
        if node1 ~= 0
            G(node1, node1) = G(node1, node1) + admittance;
        end
        if node2 ~= 0
            G(node2, node2) = G(node2, node2) + admittance;
        end
        if node1 ~= 0 && node2 ~= 0
            G(node1, node2) = G(node1, node2) - admittance;
            G(node2, node1) = G(node2, node1) - admittance;
        end
    end
    
    % Stamp inductors
    for L = 1:numel(L_Names)
        node1 = str2double(L_Node_1{L});
        node2 = str2double(L_Node_2{L});
        admittance = 1/(1i*current_omega*sym(L_Names{L}));
        if node1 ~= 0
            G(node1, node1) = G(node1, node1) + admittance;
        end
        if node2 ~= 0
            G(node2, node2) = G(node2, node2) + admittance;
        end
        if node1 ~= 0 && node2 ~= 0
            G(node1, node2) = G(node1, node2) - admittance;
            G(node2, node1) = G(node2, node1) - admittance;
        end
    end
    
    % Stamp VCCS (G sources)
for Gs = 1:numel(G_Names)
    out_node1 = str2double(G_Node_1{Gs});
    out_node2 = str2double(G_Node_2{Gs});
    in_node1 = str2double(G_Node_3{Gs});
    in_node2 = str2double(G_Node_4{Gs});
    value = sym(G_Names{Gs}); % This is gm

    % Current flows from out_node1 to out_node2, controlled by (V_in_node1 - V_in_node2)
    % KCL at out_node1: -gm*(Vin1 - Vin2) ...
    if out_node1 ~= 0
        if in_node1 ~= 0
            G(out_node1, in_node1) = G(out_node1, in_node1) - value; % -gm
        end
        if in_node2 ~= 0
            G(out_node1, in_node2) = G(out_node1, in_node2) + value; % +gm
        end
    end

    % KCL at out_node2: +gm*(Vin1 - Vin2) ...
    if out_node2 ~= 0
        if in_node1 ~= 0
            G(out_node2, in_node1) = G(out_node2, in_node1) + value; % +gm
        end
        if in_node2 ~= 0
            G(out_node2, in_node2) = G(out_node2, in_node2) - value; % -gm
        end
    end
end
    
    % B matrix (voltage sources)
    B = sym(zeros(nodes_number, numel(V_Names) + numel(E_Names)));
    
    % Stamp independent voltage sources
    for V = 1:numel(V_Names)
        node1 = str2double(V_Node_1{V});
        node2 = str2double(V_Node_2{V});
        if node1 ~= 0
            B(node1, V) = 1;
        end
        if node2 ~= 0
            B(node2, V) = -1;
        end
    end
    
    % Stamp VCVS (E sources) in B matrix
    for E = 1:numel(E_Names)
        out_node1 = str2double(E_Node_1{E});
        out_node2 = str2double(E_Node_2{E});
        col = numel(V_Names) + E;
        
        if out_node1 ~= 0
            B(out_node1, col) = 1;
        end
        if out_node2 ~= 0
            B(out_node2, col) = -1;
        end
    end
    
    % C matrix
    C = sym(zeros(numel(V_Names) + numel(E_Names), nodes_number));
    
    % Stamp independent voltage sources in C matrix
    for V = 1:numel(V_Names)
        node1 = str2double(V_Node_1{V});
        node2 = str2double(V_Node_2{V});
        if node1 ~= 0
            C(V, node1) = 1;
        end
        if node2 ~= 0
            C(V, node2) = -1;
        end
    end
    
    % Stamp VCVS (E sources) in C matrix
    % Stamp VCVS (E sources) in C matrix
for E = 1:numel(E_Names)
    out_node1 = str2double(E_Node_1{E}); % Added from your B matrix stamping
    out_node2 = str2double(E_Node_2{E}); % Added from your B matrix stamping
    in_node1 = str2double(E_Node_3{E});
    in_node2 = str2double(E_Node_4{E});
    gain = sym(E_Names{E});
    row = numel(V_Names) + E;

    % Constraint equation: V_out1 - V_out2 - gain*(V_in1 - V_in2) = 0
    if out_node1 ~= 0
        C(row, out_node1) = 1; % Coefficient for V_out1
    end
    if out_node2 ~= 0
        C(row, out_node2) = -1; % Coefficient for V_out2
    end
    if in_node1 ~= 0
        C(row, in_node1) = C(row, in_node1) + gain; % Coefficient for V_in1 (from -gain*V_in1)
    end
    if in_node2 ~= 0
        C(row, in_node2) = C(row, in_node2) - gain; % Coefficient for V_in2 (from +gain*V_in2)
    end
end
    
    % D matrix
    D = sym(zeros(numel(V_Names) + numel(E_Names)));
    
    % Combine into full A matrix
    A = [G, B; C, D];
    disp(A);
    % Substitute component values before solving
    A_subs = subs(A, component_vars, component_vals);
    Z_subs = subs(Z, component_vars, component_vals);
    
    % Solve at this frequency
    current_numeric = double(A_subs \ Z_subs);
    numeric_ans(freq_x, :) = current_numeric;
end
end