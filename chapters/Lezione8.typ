#import "../template.typ": *

== Bayes Filter

For an arbitrary probability distribution, it is hard to find a closed mathematical formula. 
Why do we often use a Gaussian distribution? Because it emerges naturally from many real-world scenarios and is mathematically convenient: the integral problem turns into simple linear algebra.

#note()[
  *Parametric method*: representing the belief using a synthetic description given by mathematical parameters (e.g., mean and variance of a Gaussian). Examples include the Kalman Filter and the Extended Kalman Filter (EKF).
]

Another method, instead of the standard parametric Bayes filter, is the *Particle Filter* (a non-parametric method).
The idea is to use a finite set of samples (called particles) to represent the belief. Instead of representing the belief with a rigid equation, we represent it with, for example, 100 empirical examples of possible states.

#warning()[
  In this case, the real bottleneck is the number of particles we can maintain. The more particles we have, the better the approximation of the belief, but the higher the computational cost.
]

Extended Kalman Filters and Particle Filters are two representative implementations for solving the integral problem in Bayes Filters.

== Robot Motion Component

We talked about action models, but what does that imply in practice? 
In a Bayes filter, we need to predict the effect of the actions of the robot. Here, actions are motions. We need a model to predict the next state.

Let's consider a *differential drive robot*: a robot with two wheels that can rotate at different speeds. By applying a difference in the speed of the two wheels, we can make the robot turn or describe circumferences.
- *Linear velocity*: represented as a vector.
- *Angular velocity*: represented as a circled arrow.

=== Differential Drive Kinematics

//aggiungere immagine

We represent the position of the robot with a pose $s = (x, y, theta)$ in a global frame of reference. We don't consider the $z$-axis because we are operating in a 2D world. We also have a local frame of reference attached to the robot itself.

*Skid steering*: when we apply different angular velocities to the two wheels, the robot rotates.
We only need a few parameters to describe the geometry and movement of the robot:
- $R$: the radius of the wheel.
- $L$: the separation distance between the two wheels (width of the robot).

The *controls* allow us to move the robot:
- $omega_r, omega_l$: angular velocities of the right and left wheel, respectively.
- $v_r, v_l$: linear velocities of the right and left wheel. We can compute the linear velocity of a wheel as $v = R * omega$.

#note()[
  Angular velocity and linear velocity are physically different, but they are related by the radius of the wheel. We can control the robot equivalently by controlling either the angular or the linear velocities of its wheels.
]

Possible motions include:
- Forward / backward
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
Formally, to describe an object that changes over time, we use the *derivative*. We can compute the derivative of $x, y, theta$ (denoted as $dot(x), dot(y), dot(theta)$) as a function of the controls $omega_r, omega_l$ given these simple trigonometric formulas:

$
  dot(x) = R/2 * (omega_r + omega_l) * cos(theta) \
  dot(y) = R/2 * (omega_r + omega_l) * sin(theta) \
  dot(theta) = R/L * (omega_r - omega_l)
$

The $dot(x)$ tells us: if we apply the controls, how much does the position change in that instant? 
If we want to use this equation to predict where the robot will be after a small time step $Delta t$, we need to integrate it over time:

$
  x(t + Delta t) = x(t) + dot(x) * Delta t \
  y(t + Delta t) = y(t) + dot(y) * Delta t \
  theta(t + Delta t) = theta(t) + dot(theta) * Delta t
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

There are two main instances of kinematics:
- *Forward kinematics*: Given $s_(t-1)$ and $u_t$, compute $s_t$. It's a relatively easy problem.
- *Inverse kinematics*: Given $s_(t-1)$ and $s_t$, compute $u_t$. It's a hard problem because of non-holonomic constraints (we can't just draw a straight line between two poses). However, it's very interesting because it's required for motion planning (telling the robot what to do to reach a goal).

=== Intuition: Forward Kinematics vs Probabilistic Evaluation

Suppose the robot assumes it is in a pose $s_(t-1)$ and executes a control action $u_t$. *How likely is it that it ends up in an arbitrary pose $s_t$?*

The answer is a score (e.g., from 0 to 1), which we can normalize to get a probability distribution. The algorithm must provide an answer for *every* possible $s_t$.

If we rigidly use pure forward kinematics:
- The model predicts the robot should be exactly in $s_t^*$.
- Is the evaluated pose $s_t$ equal to $s_t^*$? If no $-> 0$. If yes $-> 1$.
This approach is too sharp and rigid. It doesn't represent reality, so it's practically useless in modern robotics.

*Forward kinematics with noise:*
It is possible that, due to noise, the command $u_t$ places the robot in $s_t$ instead of the ideal $s_t^*$. How can we assign a probability to this?

We must measure the discrepancy (the distance) between the evaluated pose $s_t$ and the ideal predicted pose $s_t^*$. Let's call this discrepancy $Delta$:
- If $Delta$ is small, the probability should be high.
- If $Delta$ is big, the probability should be low, because very large errors are unlikely.

How can we compute this? We feed $Delta$ into a probability density function $p(Delta)$ that has its maximum at $0$ and decreases as we get further away. This naturally points to a *Gaussian distribution*.

#note()[
  The core task of the motion model is to build an explanation of the movement that is consistent with reality!
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