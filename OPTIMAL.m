function solve_large_gap()
    % Open output file for storing results
    resultFile = fopen('gap_ilp_result.txt', 'w');
    if resultFile == -1
        error('Error opening output file.');
    end

    % Iterate through gap1 to gap12
    for datasetIndex = 1:12
        fileName = sprintf('gap%d.txt', datasetIndex);
        fileId = fopen(fileName, 'r');
        if fileId == -1
            fprintf(resultFile, 'Error opening file %s.\n', fileName);
            continue;
        end

        % Read the number of problem sets
        numProblems = fscanf(fileId, '%d', 1);

        % Write dataset header to result file
        fprintf(resultFile, '\n========= Dataset: GAP %d =========\n', datasetIndex);

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

            % Prepare result line
            resultStr = sprintf('Problem c%03d-%d | Total Cost: %6d\n', ...
                numServers * 100 + numUsers, problemIndex, round(totalCost));

            % Print results to console and file
            fprintf('%s', resultStr);           % Print to console
            fprintf(resultFile, '%s', resultStr);  % Write to result file
        end
        
        fclose(fileId);
    end

    fclose(resultFile);  % Close result file after writing all results
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
