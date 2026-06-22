#import "../template.typ": *

= Exam Questions & Solutions

== Exercise 1: Rotation Matrices Interpolation

#note(title: "Question")[
  - A manipulator needs to move its end effector from an initial orientation $R_i$ to a final orientation $R_f$.
  - To compute the effector trajectory, the robot executes a linear interpolation of the individual elements of the two rotation matrices: $ R(t) = (1-t)R_i + t R_f "for" t in [0,1] $
  - Discuss the disadvantages of this approach and propose a solution to fix it.
]

*Drawbacks of the proposed approach:*
The suggested algorithm performs a naive element-by-element linear interpolation of two rotation matrices. The primary flaw is that the resulting intermediate matrices will *not* be valid rotation matrices. They will lose their fundamental orthonormality properties (the determinant will not equal 1), resulting in impossible geometric deformations (skewing/scaling) of the robot arm instead of pure rotation. Furthermore, matrix and Euler angle parameterizations are susceptible to *Gimbal Lock* (loss of a degree of freedom causing inverse kinematic singularities).

*The Solution:*
The modern and mathematically robust approach is to use *Quaternions*. Quaternions completely avoid Gimbal Lock. To smoothly transition between two orientations, we use *SLERP* (Spherical Linear Interpolation) on the quaternions, which interpolates along the shortest path (geodesic) on a 4D sphere. This guarantees that every intermediate step yields a valid unit quaternion, representing a perfectly valid rotation at a constant angular velocity, which can then be safely converted back into a matrix for the manipulator.

#pagebreak()

== Exercise 2: TF Trees Transformations

#note(title: "Question")[
  - A robot perceives an object with its sensor $I$ at coordinates $""^I p$.
  - What are the coordinates of the object with respect to frame of reference $A$?

  #align(center)[
    #image("assets/image.png", width: 60%)
  ]
]

*Procedure & Solution:*
To find the coordinates of a perceived point $""^I p$ in the target frame $A$ using a TF Tree, we follow these steps:

1. *Path Identification:* Find the unique path in the directed graph connecting the source frame ($I$) to the target frame ($A$). In this scenario, the path is $I -> F -> C -> A$.
2. *Graph Traversal & Matrix Multiplication:* Traverse the tree and multiply the transformation matrices along the edges.
   - If you traverse an edge *against* the arrow (child to parent), you use the standard stored transformation matrix.
   - If you traverse *with* the arrow (parent to child), you must use the inverse matrix.
3. *Final Computation:* To transform the point $""^I p$ from the sensor frame $I$ to the base frame $A$, we chain the transformations from right to left:
  $ ""^A p = ""^A_C T dot ""^C_F T dot ""^F_I T dot ""^I p $

#pagebreak()

== Exercise 3: Kalman Filter and Non-Linear Models

#note(title: "Question")[
  - A differential-drive robot tracks its pose using wheel odometry as the prediction model and a fixed landmark tracker as the measurement update.
  - Explain why a standard Kalman filter cannot be applied in this case and how an Extended Kalman Filter could tackle the task instead.
]

*Why the standard Kalman Filter fails:*
The standard Kalman Filter strictly assumes that both the motion and perception models are *linear transformations*. A differential drive robot's kinematic model, however, relies heavily on trigonometric functions (sine and cosine) to compute heading and position, making it highly non-linear. If a Gaussian distribution (representing our uncertainty) is passed through a non-linear function, its shape distorts and becomes non-Gaussian. This completely breaks the mathematical foundations of the standard KF.

*How the Extended Kalman Filter (EKF) solves this:*
The EKF handles this by *locally linearizing* the non-linear motion and observation models around the current state estimate. It achieves this using a first-order Taylor series expansion, which requires computing the partial derivatives (the *Jacobians*) of the functions. By pretending the world is linear in a tiny region around the robot, the output uncertainty is forced to remain a perfect Gaussian, allowing the standard Kalman matrix algebra to be applied successfully.

#pagebreak()

== Exercise 4: Particle Filter for Localization

#note(title: "Question")[
  A mobile robot is localizing itself using a Particle Filter.

  - Suppose the robot is stationary (not moving), but the prediction step is still executed using a motion model that includes a small amount of odometry noise. Describe what happens to the spatial spread (cloud) of the particles before any sensor measurement is taken.
  - When a sensor measurement is finally taken, explain how individual particle weights are calculated. If a specific particle is located very far from what the sensor actually observes, what happens to its weight, and what happens to the particle in the subsequent steps of the algorithm?
]

*Prediction Step (No sensory measurement):*
Even if the robot is stationary, the prediction step continuously samples from the motion model. Because the motion model incorporates zero-mean Gaussian noise to account for uncertainty, the particles will randomly drift and scatter over time. Visually, the particle cloud will expand and diffuse, representing the robot's growing uncertainty about its exact position due to the unreliability of dead reckoning.

*Correction Step (Sensory measurement applied):*
Each particle's weight $w_t^i$ is calculated based on how closely the actual sensor measurement matches the *expected* measurement from that particle's hypothetical pose ($p(z_t | s_t^i)$). If a particle is located where a wall should be expected, but the actual sensor reads "free space", its weight drops to near zero. 
During the subsequent *resampling* phase, particles are drawn with a probability proportional to their weight. Highly inaccurate particles will likely "die" (be eliminated) and be replaced by copies of high-weight particles that accurately predict the sensor reading.

#pagebreak()

== Exercise 5: Odometry-based vs Velocity-based Motion Models

#note(title: "Question")[
  - When modeling the motion of a mobile robot for state estimation, developers can use either a Velocity-based motion model or an Odometry-based motion model.
  - Why is the odometry-based motion model generally much more accurate and widely preferred over the velocity-based motion model during the prediction step of a filter?
  - Describe a scenario where the odometry-based motion model completely fails and a velocity-based model would be more reliable.
]

*Why Odometry is preferred for state estimation:*
The odometry-based model uses data gathered *after* the physical movement has occurred (via wheel encoders). Because it is an *a posteriori* measurement, it inherently captures the actual physical distance traveled by the chassis, naturally accounting for minor mechanical imperfections, inertia, and exact execution that raw, ideal velocity commands cannot capture.

*When Odometry fails (and Velocity is needed):*
1. *Planning:* Odometry cannot be used by a path planner to simulate future states because the physical movement hasn't happened yet. Velocity models are strictly required to predict future trajectories.
2. *Severe Wheel Slip:* In environments with mud or ice, the wheels may spin without the robot actually moving. Encoders will falsely report movement, causing odometry to induce massive localization errors (the robot thinks it moved, but it didn't).

#pagebreak()

== Exercise 6: Multi-Agent Path Finding (CBS vs Token Passing)

#note(title: "Question")[
  - In a warehouse grid environment, multiple automated guided vehicles (AGVs) need to route simultaneously without colliding. Two primary algorithms are evaluated for this Multi-Agent Path Finding (MAPF) problem: Conflict-Based Search (CBS) and Token Passing.
  - Describe the distinct responsibilities of the low-level search versus the high-level search in CBS. How are conflicts between agents explicitly resolved when moving from the low level to the high level?
  - Contrast CBS with Token Passing regarding computational scalability and solution quality.
]

*Roles in Conflict-Based Search (CBS):*
- *Low-Level Search:* Finds the optimal path for a single agent independently, respecting a specific set of space-time constraints given to it by the High-Level.
- *High-Level Search:* Manages global agent interactions by searching a Constraint Tree. If a conflict occurs (e.g., agent $a$ and agent $b$ want to occupy vertex $v$ at time $t$), it resolves it by splitting the node into two branches: one adding the constraint "$a$ cannot be at $v(t)$", and the other adding "$b$ cannot be at $v(t)$".

*Comparison (CBS vs Token Passing):*
- *Solution Quality:* CBS guarantees optimal (or near-optimal) solutions by systematically resolving all conflicts globally. Token Passing is a greedy, decentralized approach where agents plan sequentially, avoiding paths already claimed in the shared "token". This yields highly sub-optimal global paths.
- *Computational Scalability:* CBS scales very poorly as the number of agents increases due to the exponential explosion of the constraint tree in crowded environments. Token Passing, conversely, has excellent scalability and is used for massive fleets, as it completely avoids global conflict-search and resolves paths in a rapid, sequential manner.