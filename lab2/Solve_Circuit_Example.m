% cleaning the workspace, and cmd window
clear all;
clc;

% running the first SPICE netlist
fprintf('the first netlist:\n');
[sum,num]=Solve_Circuit('circuit_1.txt');



fprintf('the second netlist:\n');
% add a line here to run the second netlist
[sum,num]=Solve_Circuit('circuit_2.txt');