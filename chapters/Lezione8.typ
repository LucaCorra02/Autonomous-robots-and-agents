#import "../template.typ": *

#informally()[
  The Bayes filter allows a robot to estimate the state of a dynamical system while considering evidence from sensor measurements. In practice, the continuous Bayes filter is a theoretical abstraction: computing the exact posterior requires evaluating an integral over a continuous state space, which lacks a closed-form solution for arbitrary probability distributions.
]

To implement this on actual hardware, we must *restrict the representation of the belief*. To achive this, we can have two main approaches:
- *Parametric methods*: We assume that the belief can be represented by a specific family of probability distributions (e.g., Gaussian), and we only need to estimate the parameters of that distribution (e.g., mean $mu$ and covariance $Sigma$). Examples include the Kalman Filter and the Extended Kalman Filter (EKF).

- *Particle Filter* (a non-parametric method): The idea is to *approximate* the continuous probability *density function* using a finite set of samples (called particles). The algorithm simulates the motion $p(x_t| u_t, x_(t-1))$ for each particle and assigns weights using the measurement model $p(z_t | x_t)$.

  #warning()[
    In this case, the real bottleneck is the number of *particles* we can maintain. The more particles we have, the better the approximation of the belief, but the higher the computational cost.
  ]

  Other notable implementations include: Unscented Kalman Filter (UKF), Information Filter, Histogram Filter, Partially Observable Markov Decision Processes (POMDP), and Hidden Markov Models (HMM).

== Robot Motion Component

We talked about action models, but what does that imply in practice?
In a Bayes filter, we need to predict the effect of the actions of the robot. Here, actions are motions. We need a model to predict the next state.

Let's consider a *differential drive robot*: a robot with two wheels that can rotate at different speeds. By applying a difference in the speed of the two wheels, we can make the robot turn or describe circumferences.

- *Linear velocity*: represented as a vector.
- *Angular velocity*: represented as a circled arrow.

=== Differential Drive Kinematics

We represent the position of the robot with a pose $s = (x, y, theta)$ in a global frame of reference. We don't consider the $z$-axis because we are operating in a 2D world. We also have a local frame of reference attached to the robot itself.

#figure(
  image("/assets/differential_drive_robot.png", width: 50%),
  caption: [Geometric parameters and controls of a differential drive robot.],
)

*Skid steering*: when two or four actuated wheels on the same side are coupled (they receive the exact same control), allowing the robot to rotate.
We only need a few parameters to describe the geometry and movement of the robot:
- $R$: the radius of the wheels.
- $L$: the separation distance between the wheels.

The *controls* allow us to move the robot:
- $omega_R, omega_L$: angular velocities for the right and left wheel, respectively.
- $v_R, v_L$: linear velocities for the right and left wheel. We can compute the linear velocity of a wheel as $v = R * omega$.

#note()[
  Angular velocity and linear velocity are physically different, but they are related by the radius of the wheel. We can control the robot equivalently by controlling either the angular or the linear velocities of its wheels.
]

Possible motions include:
- Forward / backward straight
- Turn in place
- Motion along an arc

=== Velocity Constraints and Non-Holonomic Systems

Given a specific configuration, can we choose to apply an *arbitrary* velocity to the robot?
*NO!*

1. The robot has a maximum velocity (physical motor limits).
2. Imagine a car: you cannot apply a velocity that starts from the side door. The vehicle is constrained by its physical structure; it cannot move sideways.

What happens if we integrate a velocity? We obtain a position. But can this constraint on velocity be integrated into a strict constraint on the final configuration?
No, the constraint on velocity cannot be integrated to reduce the reachable workspace. This is called a *non-holonomic constraint*.

#informally()[
  The robot can reach basically anywhere in the 2D plane, but the *way* it reaches a particular position cannot be arbitrary. It cannot move freely like a geometric point (e.g., a car cannot move sideways to parallel park instantly).
]

Most wheeled robots are non-holonomic (e.g., cars with Ackermann steering). If we have a holonomic robot (like a drone), it can move in any direction in space, but these are generally more difficult to build on the ground.

=== Transition Equations

How does the pose change in time?
Formally, to describe an object that changes over time, we use the *derivative*. We can compute the derivative of $x, y, theta$ (denoted as $dot(x), dot(y), dot(theta)$) as a function of the controls $omega_R, omega_L$ given these simple trigonometric formulas:

$
  dot(x) = R/2 * (omega_R + omega_L) * cos(theta) \
  dot(y) = R/2 * (omega_R + omega_L) * sin(theta) \
  dot(theta) = R/L * (omega_R - omega_L)
$

The $dot(x)$ tells us: if we apply the controls, how much does the position change in that instant?
If we want to use this equation to predict where the robot will be after a small time step $Delta t$, we approximate it using a discrete time model:

$
  x(t + Delta t) approx x(t) + dot(x) * Delta t \
  y(t + Delta t) approx y(t) + dot(y) * Delta t \
  theta(t + Delta t) approx theta(t) + dot(theta) * Delta t
$

#informally()[
  To predict the position of the robot after a certain time, we need:
  - The current pose of the robot.
  - The controls applied.
  - The duration $Delta t$ of the action.
  - The kinematic model of the robot (the equations above).
]

This geometric description is mathematically sound, but one crucial aspect of reality is missing: *the errors! The noise!* When a real robot moves, wheel rotations are not perfect, they can slip, radii might slightly differ, and the floor is not perfectly flat. We are not in a videogame.

== Motion Models (Probabilistic)

To address real-world physics, we enrich the previous model. A probabilistic motion model describes the relations between the current pose $s_(t-1)$, the control action $u_t$, and the next pose $s_t$, considering the noise.

#note()[
  Notation change: The state/pose is now called $s$ (e.g., $s_(t-1), s_t$), instead of $x$ as in previous lectures. The control action is $u_t$.
]

We could try to use pure kinematics:
- *Forward kinematics*: Determine $s_t$ by feeding $s_(t-1)$ and $u_t$ into motion equations.
- *Inverse kinematics*: Determine $u_t$ by feeding $s_(t-1)$ and $s_t$ into "inverse" motion equations.

#warning()[
  *The flaw of pure kinematics:* It assumes a deterministic world. For example, if a robot at $(0,0,0)$ is commanded to move straight for 5 meters, the model assumes it will land exactly at $(5,0,0)$. This is doomed to fail in reality.
]

=== Intuition: Forward Kinematics vs Probabilistic Evaluation

Suppose the robot assumes it is in a pose $s_(t-1)$ and executes a control action $u_t$. *How likely is it that it ends up in an arbitrary pose $s_t$?*

The answer is a score (e.g., from 0 to 1), which we can normalize to get a probability distribution. The algorithm must provide an answer for *every* possible $s_t$.

If we rigidly use pure forward kinematics:
- The model predicts the robot should be exactly in a specific theoretical pose $s_t^*$.
- Is the evaluated pose $s_t$ equal to $s_t^*$?
  - If NO $-> 0$ (Impossible)
  - If YES $-> 1$ (Certain)
This approach is too sharp and rigid. It doesn't represent reality, so it's practically useless in modern robotics.

*Forward kinematics with noise:*
It is possible that, due to noise, the command $u_t$ places the robot in $s_t$ instead of the ideal $s_t^*$. How can we assign a probability to this?

We must measure the discrepancy (the distance) between the evaluated pose $s_t$ and the ideal predicted pose $s_t^*$. Let's call this discrepancy $Delta$:
- If $Delta$ is small, the probability should be high. Small discrepancies are frequent (that's what the robot intended to do via $u_t$).
- If $Delta$ is big, the probability should be low, because huge discrepancies are exceptional.

How can we compute this? We feed $Delta$ into a probability density function $p(Delta)$ that has its maximum at $0$ and decreases as we get further away. This naturally points to a *Gaussian distribution*.

#note()[
  *The core task:* The motion model must build an explanation of the events that could have brought the robot to $s_t$. The explanation must be consistent with reality, which might be tricky!
]

#example()[
  Suppose the robot operates on a 1D grid. It can move right to the next cell.
  In our simulation, we try to mimic reality by adding Gaussian noise: most of the time the robot moves exactly 1 cell as commanded, but sometimes it moves 0 cells or 2 cells. The average error is zero, but errors will still happen with a certain probability.

  The Gaussian always has a mean of zero ($mu = 0$), but we can choose the standard deviation ($sigma$):
  - If we choose a small standard deviation, the model is very confident about the next pose.
  - If we choose a large standard deviation, the model is less confident (high uncertainty).

  In reality, the robot executes: movement = $1 + "sample"(N(0, sigma^2))$.

  During a Bayes Filter update (predict + correct with a sensor):
  - *Good Sensor:* If the sensor is accurate, the posterior belief (blue curve) will sharply peak around the true position, correcting the uncertainty of the motion model. By step 20, the robot perfectly tracks its position.
  - *Kidnapped Robot (Huge Noise):* If the motion is completely random/unreliable, the motion model gives us no clues. Even with a perfect sensor, recovering the position is difficult.
  - *Blind Robot:* If the robot has a perfect motion model but a very bad sensor, the belief just shifts forward following the prediction, but gradually flattens out because there are no sensor measurements to correct the accumulated uncertainty.
]

=== Building the Probabilistic Transition Model

We already know the answer from the Bayes filter: use a probabilistic transition model $p(s_t | s_(t-1), u_t)$.
To build it, the simple idea is combining *kinematics + noise*.

What does it actually mean to "build" $p(s_t | s_(t-1), u_t)$? Substantially, it means being able to execute these two tasks:
1. *Evaluation:* given $s_(t-1)$, $u_t$ and $s_t$, compute the scalar value of $p(s_t | s_(t-1), u_t)$ (that is, evaluate the transition model).
2. *Sampling:* given $s_(t-1)$ and $u_t$, generate a random sample from $p(s_t | s_(t-1), u_t)$ (that is, generate a possible $s_t$ from the transition model).

Why exactly these two tasks? Because that is exactly how the transition model is utilized in Bayes filter implementations:
- Extended Kalman Filters (EKF) heavily use *evaluation*.
- Particle Filters heavily use *sampling*.

To achieve this, we will dive into two classical motion models: the Odometry-based motion model and the Velocity-based motion model.
