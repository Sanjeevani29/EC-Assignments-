
function solve_large_gap()
    % Iterate through gap1 to gap12
    for datasetIndex = 1:12
        fileName = sprintf('gap%d.txt', datasetIndex);
        fileId = fopen(fileName, 'r');
        if fileId == -1
            error('Error opening file %s.', fileName);
        end

        % Read the number of problem sets
        numProblems = fscanf(fileId, '%d', 1);
        
        % Print dataset name
        fprintf('\n========= Dataset: GAP %d =========\n', datasetIndex);
        
        for problemIndex = 1:numProblems
            % Read problem parameters
            numServers = fscanf(fileId, '%d', 1);
            numUsers = fscanf(fileId, '%d', 1);
            
            % Read cost and resource matrices
            costMatrix = fscanf(fileId, '%d', [numUsers, numServers])';
            resourceMatrix = fscanf(fileId, '%d', [numUsers, numServers])';
            
            % Read server capacities
            serverCapacities = fscanf(fileId, '%d', [numServers, 1]);
            
            % Solve the GAP using integer programming
            assignmentMatrix = solve_gap_max(numServers, numUsers, costMatrix, resourceMatrix, serverCapacities);
            totalCost = sum(sum(costMatrix .* assignmentMatrix));
            
            % Print results nicely
            fprintf('Problem c%03d-%d | Total Cost: %6d\n', ...
                numServers * 100 + numUsers, problemIndex, round(totalCost));
        end
        
        fclose(fileId);
    end
end

function assignmentMatrix = solve_gap_max(numServers, numUsers, costMatrix, resourceMatrix, serverCapacities)
    f = -costMatrix(:); % Negative for maximization

    % Constraint 1: Each user assigned to exactly one server
    Aeq_users = kron(eye(numUsers), ones(1, numServers));
    beq_users = ones(numUsers, 1);

    % Constraint 2: Server capacity not exceeded
    Aineq_servers = zeros(numServers, numServers * numUsers);
    for i = 1:numServers
        for j = 1:numUsers
            Aineq_servers(i, (j-1)*numServers + i) = resourceMatrix(i, j);
        end
    end
    bineq_servers = serverCapacities;

    % Variable bounds (binary variables)
    lb = zeros(numServers * numUsers, 1);
    ub = ones(numServers * numUsers, 1);
    intcon = 1:(numServers * numUsers);

    % Solve with intlinprog
    options = optimoptions('intlinprog', 'Display', 'off');
    x = intlinprog(f, intcon, Aineq_servers, bineq_servers, Aeq_users, beq_users, lb, ub, options);

    % Reshape to assignment matrix
    assignmentMatrix = reshape(x, [numServers, numUsers]);
end
