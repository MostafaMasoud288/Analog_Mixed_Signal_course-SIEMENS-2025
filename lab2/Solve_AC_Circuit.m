function [symbolic_ans, numeric_ans ,frequencies] = Solve_AC_Circuit(netlist_directory, points_per_decade , start_freq , stop_freq)

%{
Part 1: reading the netlist
Part 2: parsing the netlist
Part 3: creating the matrices
Part 4: solving the matrices
%}

%__Part 1__


frequencies = logspace(log10(start_freq), log10(stop_freq), round(log10(stop_freq/start_freq) * points_per_decade) + 1);


%loading netlist
raw_netlist = fopen(netlist_directory);
raw_netlist = fscanf(raw_netlist, '%c');

%Deleting multiple spaces, etc. using regular expressions
netlist = regexprep(raw_netlist,' *',' ');
netlist = regexprep(netlist,' I','I');
netlist = regexprep(netlist,' R','R');
netlist = regexprep(netlist,' V','V');
netlist = regexprep(netlist,' C','C');
netlist = regexprep(netlist,' L','L');
netlist = regexp(netlist,'[^\n]*','match');

%__Part 2__
[R_Node_1, R_Node_2, R_Values, R_Names] = ParseNetlist(netlist, 'R');
[V_Node_1, V_Node_2, V_Values, V_Names] = ParseNetlist(netlist, 'V');
[I_Node_1, I_Node_2, I_Values, I_Names] = ParseNetlist(netlist, 'I');
[C_Node_1, C_Node_2, C_Values, C_Names] = ParseNetlist(netlist, 'C');
[L_Node_1, L_Node_2, L_Values, L_Names] = ParseNetlist(netlist, 'L');

%Counting nodes
nodes_list = [R_Node_1 R_Node_2 V_Node_1 V_Node_2 I_Node_1 I_Node_2 C_Node_1 C_Node_2 L_Node_1 L_Node_2];
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

symbolic_ans = sym(zeros(matrices_size, 1)); % placeholder
numeric_ans = zeros(numel(frequencies), matrices_size); % each row = solution at a frequency

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

for C = 1:1:numel(C_Names)
    eval([C_Names{C} ' = ' num2str(C_Values{C}) ';']);
end

for L = 1:1:numel(L_Names)
    eval([L_Names{L} ' = ' num2str(L_Values{L}) ';']);
end

%%%%%%%%%%%%%%%%%add C L STAMP IN ALOOP WITH FREQUENCIES%%%%%%%%%%%%%%%%%%
% A matrix - G part
for freq_x = 1:numel(frequencies)

            current_freq = frequencies(freq_x) ;
            current_omega = 2 * pi * current_freq ;
            G = repmat(unit_matrix(1:nodes_number), 1, nodes_number);
            %% R stamp %%
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
            
            
            for C = 1:numel(C_Names)
                current_node_1 = str2double(C_Node_1(C));
                current_node_2 = str2double(C_Node_2(C));
                current_name = C_Names{C};
                admittance = ['1i*' num2str(current_omega) '*' current_name];
                if current_node_1 ~= 0
                    G{current_node_1, current_node_1} = [G{current_node_1, current_node_1} '+' admittance];
                end
                if current_node_2 ~= 0
                    G{current_node_2, current_node_2} = [G{current_node_2, current_node_2} '+' admittance];
                end
                if current_node_1 ~= 0 && current_node_2 ~= 0
                    G{current_node_1, current_node_2} = [G{current_node_1, current_node_2} '-' admittance];
                    G{current_node_2, current_node_1} = [G{current_node_2, current_node_1} '-' admittance];
                end
            end


            for L = 1:numel(L_Names)
                current_node_1 = str2double(L_Node_1(L));
                current_node_2 = str2double(L_Node_2(L));
                current_name = L_Names{L};
                admittance = ['1/(1i*' num2str(current_omega) '*' current_name ')'];
                if current_node_1 ~= 0
                    G{current_node_1, current_node_1} = [G{current_node_1, current_node_1} '+' admittance];
                end
                if current_node_2 ~= 0
                    G{current_node_2, current_node_2} = [G{current_node_2, current_node_2} '+' admittance];
                end
                if current_node_1 ~= 0 && current_node_2 ~= 0
                    G{current_node_1, current_node_2} = [G{current_node_1, current_node_2} '-' admittance];
                    G{current_node_2, current_node_1} = [G{current_node_2, current_node_1} '-' admittance];
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

             %% Rebuild full A matrix
                a = [G; C(:,1:nodes_number)];
                a = [a B];
                A = cellfun(@str2sym, a);

                %% Solve at this frequency
                current_numeric = subs(A \ Z);
                numeric_ans(freq_x, :) = double(current_numeric);

end



%__Part 4__
% Symbolic solution
% symbolic_ans = A \ Z;


% Substitute symbolic values with numerical
%numeric_ans = subs(symbolic_ans);

% Print final frequency response (magnitude of selected output, e.g., V_2)
fprintf('\nAC frequency response (magnitude):\n');
for i = 1:length(frequencies)
    fprintf('Freq = %.2f Hz, ', frequencies(i));
    for k = 1:matrices_size
        fprintf('%s = %.4f + %.4fj, ', char(X(k)), real(numeric_ans(i,k)), imag(numeric_ans(i,k)));
    end
    fprintf('\n');
end

end
