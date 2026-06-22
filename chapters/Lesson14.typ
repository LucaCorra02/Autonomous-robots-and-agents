#import "../template.typ" : *

= Planning in Robotics and AI

#informally(title: "What is Planning?")[
  Remember that there is not a single, universally accepted definition of *planning*. Substantially, it can be viewed as one of the primary contact points between the fields of Robotics and Artificial Intelligence (AI). Planning is where AI meets Robotics, and it's also where the boundaries between robots and agents blur. It is the problem of selecting a sequence of actions to achieve an assigned goal, and it is often formulated in terms of state spaces. A plan can be defined as a sequence of actions or a function determining which action to take (e.g., based on current state, current time, uncertainty, etc...).
]

== Deterministic Planning

In a deterministic planning scenario, the problem is defined by three main components:
- An *Initial State*
- A *Goal State* (or a set of goal states)
- A *Transition Model*

In *deterministic planning*, the transition model is completely deterministic. This means that if the robot applies a specific action in a specific state, the next state is known with absolute certainty. There is no noise or uncertainty in the transition.

Thanks to this assumption, we can represent the transition model simply as a mathematical function: $T: S times A -> S$. There is no randomness involved. It relies on a deterministic transition function $f(x,u)$, where the next state is fully predictable given the current state and action. The goal is to determine a sequence of (control) actions $u_1, u_2, ..., u_n$ that bring the robot from an initial state $x_s$ to a goal state $x_g$:

$x_s -> x_1 = f(x_0, u_1) -> x_2 = f(x_1, u_2) -> ... -> x_g = f(x_(n-1), u_n)$

#align(center)[
  #image("/assets/deterministic_maze.png", width: 60%)
]


#note(title: "Why use deterministic models?")[
  Sometimes it is highly convenient to assume that the world is deterministic. This assumption massively simplifies the planning process and works surprisingly well in many real-world robotic problems. In robotics, very often reasoning in these terms is helpful, e.g., computing a global navigation plan.
]

*How do we solve a deterministic problem formulated in these terms?*
Usually, the solution relies on a *Search Algorithm*. These algorithms historically come from the AI domain rather than pure robotics, and they explore the state space to find a valid sequence of actions reaching the goal.

== Feedback Planning (Stochastic Planning)

Basically, in this paradigm, we relax the deterministic assumption: *actions are NOT deterministic*. 

The transition model can no longer be described by deterministic functions. If the agent is in a certain state and takes an action, the next state is only known in probability. The transition model now generates a *probability distribution* over the possible next states: $P(s' | s, a)$.

If we represent this as a directed graph:
- Each *node* is a state.
- Each *arc* represents an action/transition.

#align(center)[
  #image("/assets/mdp_feedback_planning.png", width: 70%)
]

#note()[
  In this way, we can effectively capture and model the *uncertainty* of the real world.
]

In deterministic planning, the resolution is a simple *sequence of actions* (a plan). But in this case, since we are not sure about the exact effect of every single action, a static sequence will fail. 

Therefore, the real resolution is not a plan, but a *Policy* ($pi: X -> U$) that, given a state $x in X$, returns the action to execute when the robot is in that specific state $pi(s)$. The agent must constantly check the current state (feedback) before acting, because the state is not calculated solely by the previous actions but is influenced by stochasticity. This approach assumes that the current state can always be observed.

To solve these types of problems, we typically use *Markov Decision Processes (MDPs)*.

= Path Search Algorithms

== The A\* Algorithm

#note(title: "Historical Context")[
  In 1968, Nilsson, Hart and Raphael were faced with a practical problem with Shakey (one of the ancestors of today's mobile robots). The problem was calculating the shortest route to a destination on a grid map. The solution that the three scientists proposed is known as A\* (pronounced "A star"). It is an informed, best-first search algorithm.
]

#align(center)[
  #image("/assets/a_star.png", width: 40%)
]

The goal of A\* is to find a path that satisfies two main criteria:
1. It must bring the agent to the goal state.
2. It must minimize a specific cost function (e.g., distance, time, energy).

The idea behind A\* is simple: perform a Uniform Cost Search (UCS), but instead of just looking at the accumulated costs $g$, consider the function $f(s) = g(s) + h(s)$. The algorithm selects for expansion the nodes on the border that minimize the function $f$.

#align(center)[ 
  #image("/assets/astar_expansion_grid.png", width: 80%)
]

Let's distinguish the components of $f(s)$:
- $g(s)$: Indicates the exact accumulated cost along the path that arrives in state $s$ from the start.
- $h(s)$: Indicates an estimate of the cost still to be spent to get to the goal along the optimal path: the *heuristic*.

== Heuristics: Admissibility and Consistency

To guarantee that A\* finds the optimal solution, the heuristic must possess certain mathematical properties.

#theorem(title: "Admissibility")[
  A fundamental property that a good heuristic must have is admissibility. A heuristic $h$ is admissible if for each possible state $s$, $h(s)$ does not overestimate the cost of the minimum path from $s$ to the goal. 
  
  In practice: the estimate must be optimistic!
  $h(n) <= h^*(n)$
  where $h^*(n)$ is the true optimal cost from $n$ to the goal. If this property does not hold, the search algorithm may not recognize the optimal path! A degenerate case (always admissible) is when the heuristic is always equal to 0, reducing A\* to a standard UCS.
]

#align(center)[
  #image("/assets/heuristic_example.png", width: 90%)
]

*State Space vs. Search Tree:*
It is a very important distinction to make when visualizing the algorithm:
- *On the left (State Space):* We have the actual states of the environment. We cannot have duplicate states here.
- *On the right (Search Tree/Trace):* We have the trace of the algorithm solving the problem. Here, we can have multiple copies (nodes) representing the same state reached via different paths.

This distinction introduces the need for *pruning* (keeping a "closed list" of visited states so we don't explore them again). However, pruning introduces a risk: if we discard a path to a state, we might miss the optimal path.

#grid(
  columns: (1fr, 1fr),
  gutter: 1em,
  image("/assets/admissibility_tree_example.png", width: 100%),
  image("/assets/admissibility_tree_example2.png", width: 100%)
)

#theorem(title: "Consistency")[
  To solve the problems arising from pruning, we must ask the heuristic for a more stringent property than admissibility: consistency. Let $V$ and $U$ be two states connected by one action $a$. A heuristic $h$ is consistent if for every possible pair of states the following triangular inequality holds:
  $h(V) <= c(V, a, U) + h(U)$
  A consistent heuristic is also automatically admissible.
]

#align(center)[
  #image("/assets/consistency_triangle.png", width: 40%)
]

#align(center)[
  #image("/assets/consistency_triangle2.png", width: 70%)
]

#warning(title: "Consistency and Pruning")[
  If we work with an Expanded List (EXL) to avoid duplicates (which is highly desired for efficiency), admissibility alone does not guarantee optimality! We might fail due to the EXL pruning.
  - If the heuristic is *consistent*, the algorithm will *always* find the optimal solution, even if we use a pruning rule (closed list).
  - If it is admissible but *not* consistent, applying the EXL risks prematurely cutting off the path to the optimal solution, as shown in the graphic example with the scissors on slide 11.
]

#align(center)[
  #image("/assets/astar_exl_scissors.png", width: 70%)
]

== Other Search Algorithms
Within the family of state-space search algorithms, the slides summarize the following variants:
- *Hill Climbing:* A DFS that breaks ties using the heuristic $h$.
- *Beam Search:* A BFS, but once it has expanded all the nodes at depth $k$, it keeps at depth $k+1$ only the $w$ best nodes according to $h$.
- *Iterative Deepening:* A DFS limiting the maximum depth sequentially to 1, then 2, then 3, etc.
- *$"IDA"^*$ (Iterative Deepening A\*):* Uses the Iterative Deepening approach, but uses the $f$ value as a threshold instead of the depth.
- *$D^*$*: An A\* algorithm executed backwards starting from the goal node, looking for a path to the initial node.
- *Greedy Search:* Similar to A\* but adopts a simplified evaluation function based solely on the heuristic: $f(n) = h(n)$.

= Advanced Solution Techniques

== Multi-Robot Path Planning

Multi-robot path planning involves computing the path (or multiple paths) that one or more robots should follow to successfully complete a task. 

The core challenge is dictating the actions of the robots cooperatively. We want to give the robotic system the capability to dynamically or pre-emptively answer the question: *"Where to go next?"* while avoiding interference. 

A classic example is *Time-optimal multi-robot path planning (MRPP)* on grid environments. This problem is proven to be *NP-hard* when restricting the planar graph to a 2D grid graph with holes/obstacles.

== Multi-Agent Path Finding (MAPF)

The objective of MAPF is finding optimal, *non-interfering* paths for multiple agents, each one with a unique start and goal position in a known environment. It is a challenging problem with several applications in both physical (real multi-robot systems, automated warehouses) and virtual (gaming, RTS) settings.

*Formal MAPF Definition:*
Based on the standard definition by Stern et al. (2019), the problem consists of:
- $k$ agents.
- $k$ start locations.
- $k$ goal locations.
- An *Environment* represented as a generic graph $G = (V, E)$.

The objective is to calculate $k$ start $->$ goal paths ensuring the minimum sum of distances (optimality) and no vertex or edge collisions (no conflicts). The problem is inherently *NP-Hard* (J. Yu and S. LaValle, 2013).

#align(center)[
  #image("/assets/mapf_definition_grid.png", width: 70%)
]

There are two main objective functions to evaluate a MAPF solution:
1. *Sum of Costs (SOC):* The sum of the steps or time costs covered individually by each robot.
2. *Makespan:* The time taken by the last robot to complete its path (i.e., the maximum of the individual costs).

*Managing Conflicts:*
Considering time discretized into time steps ($t$), we define two basic types of conflicts:
1. *Vertex Conflict:* Two agents attempt to occupy the same vertex $v$ at the exact same time step $t$.
2. *Edge Conflict (Swapping):* Two agents attempt to traverse the same edge at the same time step proceeding in opposite directions (swapping places).

#informally(title: "Kinematic and Safety Constraints")[
  Depending on the specific problem, certain movements might be restricted. For example, sometimes it is forbidden for agents to move "like a little train" (following each other immediately edge-by-edge without a time-step buffer). These are specific safety or kinematic constraints that must be integrated into the collision-checking logic.
]

== Conflict-Based Search (CBS)

Conflict-Based Search (CBS) is the most popular exact method in the literature for solving MAPF problems completely and optimally. CBS operates by performing a *two-level search*:

1. *Low-Level Search:* Computes an optimal plan for each agent *individually*, considering the set of constraints imposed by the high level. Typically, it runs an A\* algorithm on the grid for the single robot.
2. *High-Level Search:* Runs a best-first search on a tree structure called the *Constraint Tree (CT)*, where each node represents a set of space-time interdictions (constraints) for the agents.

=== The Constraint Tree (CT)

In the high-level search, a *CT Node* contains:
- *A set of constraints:* A set of restrictions (initially empty at the root of the tree).
- *A joint plan with a cost:* A joint plan composed of the individual robot trajectories, calculated by the low-level planner respecting the node's constraints.

=== Node Expansion and Splitting Logic

When the high-level search selects a node to expand:
- *No conflicts?* If the current paths have no collisions, the algorithm is *Done* and has found the optimal solution.
- *Conflict detected?* If a conflict is detected between agent $a$ and agent $b$ on vertex $v$ at time $t$, the node is divided (*Split*), generating two new child branches.

#align(center)[
  #image("/assets/cbs_split_tree.png", width: 70%)
]

The two child nodes will respectively contain the following additional constraints:
1. *Child 1:* Adds the constraint "$a$ cannot occupy vertex $v$ at time $t$". The low-level planner is re-run only for agent $a$.
2. *Child 2:* Adds the constraint "$b$ cannot occupy vertex $v$ at time $t$". The low-level planner is re-run only for agent $b$.

#note()[
  Many improvements have been built on top of the basic algorithm, such as Improved Conflict-Based Search (ICBS) and its heuristic variant ICBS-h, which represents the state-of-the-art for CBS solvers.
]

== Configurable MAPF (C-MAPF)

The C-MAPF framework extends the MAPF problem by introducing the configurability of the environment. Configurations capture the possibility of rearranging the topology of the environment itself, respecting certain constraints.

- *Typical Example:* A logistics warehouse where the shelves are placed on rails and can be moved to open or close aisles as needed.
- Instead of a single static graph, we reason over a family of configurable environments $G_1, G_2, G_3, ...$.

This introduces an additional dimension of complexity into the search space (C-MAPF simultaneously searches for an optimal map configuration and the $k$ collision-free paths within it).

== Multi-Agent Pickup and Delivery (MAPD)

In the MAPD scenario, the environment is modeled by a graph $G=(V,E)$ with agents $a_1, a_2, ..., a_m$ operating in *discrete time* (at each step an agent can move to an adjacent vertex or stay still). Unlike MAPF, the system manages a set of pending tasks $T = {tau_1, tau_2, ...}$ that arrive dynamically at runtime.

Each task $tau_i$ specifies:
- A pickup vertex $s_i$.
- A delivery (goal) vertex $g_i$.

#align(center)[
  #image("/assets/mapd_task_graph.png", width: 50%)
]

The system constantly monitors the operational state of the agents:
- *Free agent:* A free agent with no assigned task.
- *Busy agent:* An occupied agent that is executing an assigned task.

A task is executed when the assigned agent moves from its current position $v$ towards $s_i$, and subsequently from $s_i$ to $g_i$. The quality of a global solution is evaluated through:
- *Makespan:* The total number of steps required to complete all tasks in the list.
- *Service time:* The average time that elapses between the arrival of a task in the system and its complete execution.

#note()[
  MAPD represents a dynamic, online generalization of the classic MAPF problem.
]

== Solving MAPD Problems: Token Passing

The *Token Passing (TP)* algorithm is a state-of-the-art online method for solving MAPD problems. TP iteratively assigns free agents to tasks and adds their collision-free paths to a shared data structure (a partial solution) called a *token*.

The algorithm follows a decentralized protocol where the token is passed to one free agent at a time:
1. *Task Eligibility:* A task is considered eligible if its locations (both pickup and delivery) are not the final destinations of any other path already stored in the token.
2. *Assignment and busy state:* If there are eligible tasks, the agent assigns itself to the task $tau$ at the minimum (estimated) distance from its current location. It adds to the token the trajectory to reach the delivery via the pickup, ensuring the absence of collisions with the paths already reserved by other robots, and becomes *busy*.
3. *Safe Locations:* If there are no eligible tasks available, the agent plans a path to the nearest "safe location" to avoid blocking traffic or hindering the solutions of other operating agents, safely inserting this parking movement into the token.

== Discussion: Planning with LLMs

A topic of strong modern discussion concerns the possibility of performing deterministic planning coupled with Large Language Models (LLMs).

#warning(title: "Position on LLM Reasoning")[
  A clear and iconic academic position within the scientific community (shared by researchers at Arizona State University like S. Kambhampati) literally states: 
  
  *"POSITION: STOP ANTHROPOMORPHIZING INTERMEDIATE TOKENS AS REASONING/THINKING TRACES!"*.
  
  The autoregressive generation of text tokens (like the $A^*$ execution traces produced by models such as Searchformer) must not be confused with or anthropomorphized as a real reasoning process or algorithmic planning computation.
]