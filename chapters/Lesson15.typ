#import "../template.typ" : *

= Motion Planning

#note[
  Motion planning is a highly active field of research in robotics. It can be seen as a generalization of deterministic planning, but applied to much more complex, continuous scenarios.
]

When planning on a discrete space, we operate on an *abstract level*. For example, if we command a robot to move from node $i$ to node $j$, we implicitly assume the robot has the physical capability to execute that action. The presence of obstacles and the geometry of the world are abstracted away and simply encoded in the topology of the graph (i.e., if an edge exists, we assume the motion is feasible without worrying about "how").

However, in reality, a planning layer must reason about *how* to physically move from $i$ to $j$. 
- The motion might not be kinematically possible.
- It might be possible, but computing the sequence of commands or the continuous trajectory is difficult.
- A graph might show a straight line connection, but the actual feasible trajectory could be completely different to avoid collisions.

Therefore, we need to lower the level of abstraction and incorporate into the planning problem the lower-level aspects that actually determine the robot's *motion*.

#figure(
  image("/assets/motion_planning.png", width: 60%),
  caption: [Motion Planning: From abstract graph topology to continuous space]
)

== Terminology

#warning[
  There is no uniform consensus in literature regarding notation, so it is important to focus on the underlying concepts rather than just the specific symbols.
]

- *Workspace ($cal(W)$)*: The physical space where the robot moves, works, and lives (e.g., $RR^2$ for a planar mobile robot, $RR^3$ for aerial drones or manipulators).
- *Configuration ($q$)*: A complete specification of the position of every point of the robot.
  #note[
    While this sounds like it requires tracking infinite points, we only need a minimal set of parameters (like position coordinates and orientation angles). This minimal description implicitly defines the position of the entire rigid body of the robot!
  ]
- *Configuration Space ($cal(C)$-space)*: The set of all possible configurations (poses) of the robot. It can often be described as a vector of angles (e.g., each angle describes the inclination of one joint of a manipulator).
- *Configuration Space Dimension*: The number of degrees of freedom (DoF) of the robot.

=== Constraints
Constraints limit the configurations a robot can assume or how it can move between them.

- *Holonomic Constraints*: Constraints strictly on the configuration itself, typically expressed as an equation $g(q) = 0$. If this equation is not satisfied, the configuration is illegal/invalid. Each linearly independent holonomic constraint reduces the degrees of freedom of the robot by 1.
  #example[
    Consider a mobile robot moving freely on a flat floor; its configuration is $q = (x, y, theta)$, so DoF = 3. 
    If we force the robot to move *only* on a fixed rail, we introduce physical constraints on $x$ and $y$. The configuration is still represented by the same variables, but they cannot be chosen freely, meaning the actual dimension of the reachable $cal(C)$-space is reduced.
  ]

- *Non-Holonomic Constraints*: Constraints that involve the derivatives of the configuration (velocity, $dot(q)$) but *cannot* be integrated to yield a constraint purely on the configuration $q$. 
  #warning[
    A velocity constraint implies certain directions of movement are forbidden at any given instant (e.g., a car cannot move directly sideways). However, because it cannot be integrated into $g(q) = 0$, it does *not* reduce the reachable $cal(C)$-space dimension—it only restricts the valid paths/trajectories to get to those configurations.
  ]

=== Spaces

- *Obstacle Space ($cal(O)$)*: The set of all configurations that result in a collision with an obstacle. Collision checking can be tricky. A common technique is to treat the robot as a single point and "inflate" the physical obstacles by the robot's volume to map them into the $cal(C)$-space.
- *Free Space ($cal(C)_"free"$)*: The set of all configurations where the robot does not collide. Defined as $cal(C)_"free" = {cal(C) backslash cal(O)}$

#figure(
  grid(
    columns: (1fr, 1fr, 1fr),
    gutter: 10pt,
    image("/assets/image-1.png"),
    image("/assets/image-2.png"),
    image("/assets/image-3.png"),
  ),
  caption: [Workspace vs Configuration Space ($cal(C)$-Space)]
)

== Problem Definition

We can now formally define the motion planning problem:
Find a continuous function (trajectory) $tau: [0, 1] -> cal(C)_"free"$, such that:
- $tau(0) = q_"start"$
- $tau(1) = q_"goal"$

Here, the argument of $tau$ represents the percentage of completeness of the path. 

The trajectory $tau$ must respect both:
1. *Collision avoidance*: staying strictly within $cal(C)_"free"$.
2. *Kinematic/Dynamic constraints*: complying with higher-order non-holonomic constraints of the form $u(q)dot(q) = 0$, which constrain the velocity of the trajectory without reducing the $cal(C)$-space dimension.

#figure(
  image("/assets/workspace_vs_configuration_space.png", width: 100%),
  caption: [Execution in Workspace vs C-Space trajectory]
)

== Roadmaps (RM)

How do we deal with planning in a continuous multidimensional space? We discretize it.
A trajectory is essentially a path, and we know how to find paths in discrete state spaces using standard search algorithms.

A *Roadmap (RM)* is a topological map (a graph) that supports our search procedure in the continuous space. Syntactically it's just a graph, but with a deeper interpretation:
- *Nodes* represent valid robot configurations.
- *Edges* represent feasible, collision-free trajectories between two configurations.

For a Roadmap to be useful, these three properties must hold:
1. *Accessibility*: Given a $q_"start"$, there exists a path from it to a node in the roadmap.
2. *Departability*: Given a $q_"goal"$, there exists a path from the roadmap to it.
3. *Connectivity*: The underlying graph is connected.

#figure(
  image("/assets/roadmap.png", width: 80%),
  caption: [Roadmap representation in C-Space]
)

=== Planning with a Roadmap
If we have a Roadmap, the planning problem is solved in three distinct steps:
1. Find a trajectory from $q_"start"$ to the closest RM node $s$.
2. Perform pathfinding on the RM graph from $s$ to a node $t$ in the vicinity of $q_"goal"$.
3. Find a trajectory from $t$ to $q_"goal"$.

Steps 1 and 3 are handled by a *Local Planner*, which must work its way through the multidimensional continuous space (a hard problem, but made tractable because the points are close). 
Step 2 carries out most of the search work on a normal graph, so it can be handled by any standard search algorithm (the *Global Planner*).

== Local Planners

Once a roadmap is generated (for example, using a Generalized Voronoi Diagram, which maximizes the distance from obstacles), an online local planner is employed to actually drive the robot.

Two popular local planners:

- *Dynamic Window Approach (DWA)*: A sampling-based velocity space search. It generates pairs of velocities $(v, omega)$ for a short local time window (e.g., the next 2 seconds), filters out those causing collisions, and ranks the rest using an objective function (evaluating velocity, heading alignment, and clearance). It is efficient but less optimal, best suited for simple grid-like configuration spaces.
- *Timed Elastic Bands (TEB)*: A more principled approach based on multi-objective non-linear trajectory optimization. It models the trajectory as a rubber band deformed by virtual forces: repulsive forces push away from obstacles, while internal forces enforce smoothness and kinematic limits. It yields closer-to-optimal solutions but is computationally intensive (suitable when the robot has more time to plan).

== Sampling-Based Motion Planning (SBMP)

*Problem:* Generating an explicit roadmap analytically can be completely intractable, especially when the graph comes from a high-dimensional space. 
*Idea:* Approximate $cal(C)_"free"$ via sampling-based methods instead of explicitly representing it.

Sampling-Based Motion Planning (SBMP) generally follows these macro-steps:
1. Sample a configuration $q in cal(C)$.
2. Compute a valid configuration $q' in cal(C)_"free"$ using $q$ (e.g., rejecting it if it collides).
3. Integrate $q'$ into the roadmap using a local planner and a distance function to connect it to nearby nodes.

There are many SBMP methods. The two most popular families are PRM and RRT.

=== Probabilistic Roadmaps (PRM)

PRM randomly samples configurations in the free space and connects them to form a comprehensive roadmap. It is generally a multi-query approach.
- *Learning phase*: Sample random configurations, verify they are in $cal(C)_"free"$, and use a local planner to connect them to their $k$ nearest neighbors in the graph.
- *Query phase*: Given start and goal configurations, connect them to the generated roadmap and use graph search to find the path.

=== Rapidly-exploring Random Trees (RRT)

RRTs are *single-query* planners that incrementally grow a tree rooted at the start configuration towards the goal.
1. Start with the initial configuration as the root of the tree.
2. Randomly sample a point in $cal(C)$.
3. Find the nearest existing node in the tree to this sample.
4. Extend the tree towards the sample from the nearest node by a fixed step size.
5. Repeat steps 2-4 until the goal is reached or a maximum number of iterations is met.

RRTs are particularly good at exploring high-dimensional spaces quickly due to their *Voronoi bias* (they naturally tend to pull towards large, unvisited areas of the state space).

#figure(
  image("/assets/3D_graph.png", width: 80%),
  caption: [Rapidly-exploring Random Trees (RRT)]
)