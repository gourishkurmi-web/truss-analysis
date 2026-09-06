%% ROOF TRUSS MEMBER FORCE ANALYSIS
% -------------------------------------------------------------------------
% This MATLAB script calculates the member forces and support reactions
% of a simple 2D roof truss using the method of joints.
%
% Positive member force  -> Tension
% Negative member force  -> Compression
%
% The truss is assumed to be:
%   - Pin supported at Joint A
%   - Roller supported at Joint B
%   - Loaded at the joints
%
% Author  : Gourish Kurmi
% Date    : September 2026
% -------------------------------------------------------------------------

clc;
clear;
close all;

%% 1. INPUT DATA
% -------------------------------------------------------------------------

% Joint coordinates [x, y] in metres
%
%        C
%       / \
%      /   \
%     /     \
%    A-------B
%
% Joint numbering:
% 1 = A
% 2 = B
% 3 = C

coordinates = [0  0;      % Joint A
               6  0;      % Joint B
               3  4];     % Joint C

% Member connectivity
% Each row represents [start_joint, end_joint]
%
% Member 1 = AC
% Member 2 = BC
% Member 3 = AB

members = [1 3;
           2 3;
           1 2];

% External loads at each joint [Fx, Fy] in Newtons
%
% Joint A = [0, 0]
% Joint B = [0, 0]
% Joint C = [0, -10000]  -> 10 kN downward

loads = [0       0;
         0       0;
         0  -10000];

%% 2. BASIC INFORMATION
% -------------------------------------------------------------------------

numberOfJoints  = size(coordinates, 1);
numberOfMembers = size(members, 1);

% Number of support reactions:
% Joint A -> Ax, Ay
% Joint B -> By
numberOfReactions = 3;

% Total number of unknowns
numberOfUnknowns = numberOfMembers + numberOfReactions;

% Each joint gives two equilibrium equations:
%   Sum Fx = 0
%   Sum Fy = 0
numberOfEquations = 2 * numberOfJoints;

%% 3. INITIALIZE EQUATION MATRIX
% -------------------------------------------------------------------------

% The system of equations has the form:
%
%             [K]{X} = {F}
%
% where:
% K = coefficient matrix
% X = unknown member forces and support reactions
% F = applied load vector

K = zeros(numberOfEquations, numberOfUnknowns);
F = zeros(numberOfEquations, 1);

%% 4. CALCULATE MEMBER CONTRIBUTIONS
% -------------------------------------------------------------------------

for m = 1:numberOfMembers

    % Get the starting and ending joints of the member
    startJoint = members(m, 1);
    endJoint   = members(m, 2);

    % Coordinates of starting joint
    x1 = coordinates(startJoint, 1);
    y1 = coordinates(startJoint, 2);

    % Coordinates of ending joint
    x2 = coordinates(endJoint, 1);
    y2 = coordinates(endJoint, 2);

    % Difference in coordinates
    dx = x2 - x1;
    dy = y2 - y1;

    % Member length
    length = sqrt(dx^2 + dy^2);

    % Direction cosines
    cosTheta = dx / length;
    sinTheta = dy / length;

    % -------------------------------------------------------------
    % Equilibrium contribution at starting joint
    % -------------------------------------------------------------

    K(2*startJoint - 1, m) =  cosTheta;
    K(2*startJoint,     m) =  sinTheta;

    % -------------------------------------------------------------
    % Equilibrium contribution at ending joint
    % -------------------------------------------------------------

    K(2*endJoint - 1, m) = -cosTheta;
    K(2*endJoint,     m) = -sinTheta;

end

%% 5. ADD SUPPORT REACTIONS
% -------------------------------------------------------------------------
%
% Unknown vector arrangement:
%
% X = [Member Forces, Ax, Ay, By]'
%
% Therefore:
% Column numberOfMembers + 1 -> Ax
% Column numberOfMembers + 2 -> Ay
% Column numberOfMembers + 3 -> By

AxColumn = numberOfMembers + 1;
AyColumn = numberOfMembers + 2;
ByColumn = numberOfMembers + 3;

% Joint A: Pin support
% Ax acts in the x-direction
% Ay acts in the y-direction

K(1, AxColumn) = 1;
K(2, AyColumn) = 1;

% Joint B: Roller support
% By acts in the y-direction

K(4, ByColumn) = 1;

%% 6. CREATE LOAD VECTOR
% -------------------------------------------------------------------------

for joint = 1:numberOfJoints

    % x-direction equilibrium equation
    F(2*joint - 1) = -loads(joint, 1);

    % y-direction equilibrium equation
    F(2*joint) = -loads(joint, 2);

end

%% 7. SOLVE THE SYSTEM OF EQUATIONS
% -------------------------------------------------------------------------

% Solve:
%
%       K * X = F

X = K \ F;

%% 8. EXTRACT MEMBER FORCES
% -------------------------------------------------------------------------

memberForces = X(1:numberOfMembers);

%% 9. DISPLAY MEMBER FORCE RESULTS
% -------------------------------------------------------------------------

fprintf('\n');
fprintf('====================================================\n');
fprintf('           ROOF TRUSS MEMBER FORCE ANALYSIS\n');
fprintf('====================================================\n');

fprintf('\nMEMBER FORCES\n');
fprintf('----------------------------------------------------\n');
fprintf('%-10s %-15s %-15s\n', ...
        'Member', 'Force (kN)', 'Nature');
fprintf('----------------------------------------------------\n');

for m = 1:numberOfMembers

    force = memberForces(m);

    if force > 0
        nature = 'Tension';
    elseif force < 0
        nature = 'Compression';
    else
        nature = 'Zero Force';
    end

    fprintf('%-10d %-15.3f %-15s\n', ...
            m, abs(force)/1000, nature);

end

%% 10. DISPLAY SUPPORT REACTIONS
% -------------------------------------------------------------------------

Ax = X(AxColumn);
Ay = X(AyColumn);
By = X(ByColumn);

fprintf('\nSUPPORT REACTIONS\n');
fprintf('----------------------------------------------------\n');

fprintf('Ax = %8.3f kN\n', Ax/1000);
fprintf('Ay = %8.3f kN\n', Ay/1000);
fprintf('By = %8.3f kN\n', By/1000);

fprintf('----------------------------------------------------\n');

%% 11. CHECK GLOBAL EQUILIBRIUM
% -------------------------------------------------------------------------

totalFx = sum(loads(:,1)) + Ax;
totalFy = sum(loads(:,2)) + Ay + By;

fprintf('\nEQUILIBRIUM CHECK\n');
fprintf('----------------------------------------------------\n');
fprintf('Sum Fx = %10.6f N\n', totalFx);
fprintf('Sum Fy = %10.6f N\n', totalFy);
fprintf('----------------------------------------------------\n');

if abs(totalFx) < 1e-6 && abs(totalFy) < 1e-6
    fprintf('Equilibrium check: PASSED\n');
else
    fprintf('Equilibrium check: FAILED\n');
end

%% 12. PLOT THE TRUSS
% -------------------------------------------------------------------------

figure('Name', '2D Roof Truss', 'NumberTitle', 'off');

hold on;
grid on;
axis equal;

% Plot each member
for m = 1:numberOfMembers

    startJoint = members(m, 1);
    endJoint   = members(m, 2);

    x = [coordinates(startJoint,1), coordinates(endJoint,1)];
    y = [coordinates(startJoint,2), coordinates(endJoint,2)];

    plot(x, y, 'b-', 'LineWidth', 2);

end

% Plot joints
plot(coordinates(:,1), coordinates(:,2), ...
     'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 8);

% Label joints
jointLabels = {'A', 'B', 'C'};

for joint = 1:numberOfJoints

    text(coordinates(joint,1) + 0.15, ...
         coordinates(joint,2) + 0.15, ...
         jointLabels{joint}, ...
         'FontSize', 12, ...
         'FontWeight', 'bold');

end

% Plot load at Joint C
quiver(3, 5.2, 0, -1, ...
       'r', 'LineWidth', 2, ...
       'MaxHeadSize', 0.5);

text(3.2, 4.8, '10 kN', ...
     'FontSize', 11);

xlabel('X-coordinate (m)');
ylabel('Y-coordinate (m)');
title('Simple 2D Roof Truss');

hold off;

%% END OF PROGRAM
