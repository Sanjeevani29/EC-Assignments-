This MATLAB code reads 12 benchmark GAP datasets (gap1.txt to gap12.txt) and solves each problem instance using integer linear programming (intlinprog).

For each instance, it:

Reads the number of servers, users, cost, resource requirements, and server capacities.

Solves the assignment of users to servers to maximize total profit (or minimize cost),
while ensuring that each user is assigned to exactly one server and server capacity is not exceeded.
