#import "../template.typ": *

We will consider two main probabilistic motion models used in mobile robotics to describe the state transition probability $p(s_t | s_(t-1), u_t)$.

#note(title: "The Role of Motion Models")[
  In the context of a Bayes Filter, the motion model represents the *Prediction Step*. It embodies the *Markov Assumption*: the future state $s_t$ depends only on the current state $s_(t-1)$ and the control action $u_t$, and is conditionally independent of all past states and measurements.
]

We categorize these models based on the nature of the control input $u_t$:
- *Odometry-based motion models* (driven by sensor readings).
- *Velocity-based motion models* (driven by motor commands).

== Odometry Motion Model (Popular)

This model takes information from internal sensors and uses it to understand how the robot has moved. It is generally highly accurate over short distances but accumulates drift over long trajectories.

The sensor we will mostly talk about is the *wheel encoder*: it measures exactly how much the wheel has rotated in a given time step. 
By considering the radius of the wheels and the distance between them (the wheelbase), we can compute the linear distance each wheel traveled. From this, we can derive the overall arc-like motion of the robot.

#example[
  Suppose we have a differential drive robot in an initial pose $s_(t-1) = (x, y, theta)$, and it performed a control action $u_t$. From its internal odometry readings (physical rotations of the wheels), it computes where it thinks it should be now: $hat(s)_t = (hat(x), hat(y), hat(theta))$.

  How can we describe this movement mathematically? The most obvious way is to provide a total translation ($Delta T r$) and a total rotation ($Delta R o t$) unfolding concurrently.
  
  But are we missing something? Is this enough?
  Yes, it is geometrically complete! We can always describe the transition between two reference frames with these parameters, derived entirely from the kinematics of the robot.
]

#note[
  However, dealing with concurrent translation and rotation in a probabilistic framework results in highly complex non-linear equations and coupled covariances. To simplify the math, the odometry model utilizes a mathematically different, but geometrically equivalent, description.
]

Instead of concurrent motion, we are going to imagine that the movement unfolded in a sequence of three distinct phases: *rot-trans-rot*. It's a mathematically convenient way to think about the movement that decomposes a complex 2D curve into three independent 1D steps.

- *First rotation*: rotate the robot *on the spot*, without translating, around the initial coordinates $(x, y)$, until it faces the destination point $(hat(x), hat(y))$.
- *Translation*: move straight, traveling a given distance along the direction of the new heading.
- *Final rotation*: adjust with another rotation *on the spot* until it reaches the final orientation $hat(theta)$.

#note[
  Maybe this is not what really happened physically (the robot likely drove in a curve), but we don't care because this description is geometrically equivalent: the final position of the robot will be exactly the same, and it allows us to treat the noise of each step independently.
]

This representation is simpler because we can easily calculate these three parameters using inverse kinematics, given the starting pose and the odometry destination pose:

- $hat(delta)_1 = "atan2"(hat(y) - y, hat(x) - x) - theta$ (First in-place rotation)
- $hat(d) = sqrt((hat(x) - x)^2 + (hat(y) - y)^2)$ (Straight line distance)
- $hat(delta)_2 = hat(theta) - theta - hat(delta)_1$ (Final rotation to reach orientation $hat(theta)$)

Here, these three computed parameters are treated as our measured control action $u_t = (hat(delta)_1, hat(d), hat(delta)_2)$.

#warning[
  Crucially, these numbers are collected *after* the robot has physically moved. This makes the odometry model an *a posteriori* model.
]

=== Evaluation

The evaluation algorithm is used to compute the scalar probability of a specific pose. 
Consider an arbitrary hypothesized pose $s_t$ (different from the exact one we calculated from the odometry parameters $hat(s)_t$). What is the probability that the robot actually ended up there instead?

Due to a chain of events like slipping wheels, uneven floors, or sensor quantization errors, the true pose might differ from the pure odometry one. Therefore, our "measured" odometry parameters are different from the "ideal" ones required to perfectly reach the hypothesized pose $s_t$.

How can I use the ideal parameters with the ones of the pose I want to evaluate?

#note[
  The goal is to formally compute the probability $p(s_t | s_(t-1), u_t)$. This is heavily used in grid-based Markov Localization, where we must evaluate the probability of every cell in the grid.
]

So, let's suppose the hypothesized pose $s_t$ is reachable exactly via $delta_1, d, delta_2$. The position calculated from odometry is instead reachable via $hat(delta)_1, hat(d), hat(delta)_2$.

We have to compare the numbers: the larger the difference between them, the smaller the probability.
We will basically compute the deltas (the errors):

- $Delta_1 = hat(delta)_1 - delta_1$ 
- $Delta_2 = hat(d) - d$
- $Delta_3 = hat(delta)_2 - delta_2$

Then, for every displacement, I will compute a probability score by feeding the error into a Probability Density Function (PDF) $p_sigma$ (usually a zero-mean Gaussian) with variance $sigma^2$.

#note[
  A higher $sigma$ means that our motion is more noisy, making it more probable that large discrepancies happened. With a low variance, large errors are basically impossible. So the choice of $sigma$ is very important, because it describes the physical environment the robot is moving in (e.g., ice vs. dry asphalt).
]

There are three scenarios regarding how to choose the $sigma$:
- *Scenario 1 (Static)*: Choose $sigma$ once and keep it forever. Is it good? It depends. It's good if the environment doesn't change (e.g., a uniform hospital floor). I can properly identify $sigma$ offline.
- *Scenario 2 (Adaptive)*: Adapt the value at runtime. Necessary if the environment changes dynamically (e.g., transitioning from tile to a thick carpet).
- *Scenario 3 (Motion-Dependent)*: A realistic derivation of the first. The noise depends on the motion itself.

#warning[
  If the robot does a short rotation, the absolute chance of error is small. If it does a big rotation, the probability of error increases. So the *amount* of the movement is key. I have to consider how big $hat(delta)_1, hat(d), hat(delta)_2$ are when defining $sigma$.
]

Basically, $sigma$ must be a function of the odometry parameters!
Note: the rotation noise depends *also* on the length of the translation distance.

#warning[
  This is because once the robot has rotated, it starts the translation phase. During a long translation, there is noise (like one wheel slipping slightly more than the other). The longer the translation, the more probable it is that this noise can alter the rotational heading of the robot!
]

So we calculate the independent probabilities:
- $p_1 = p_(sigma_1)(Delta_1)$
- $p_2 = p_(sigma_2)(Delta_2)$
- $p_3 = p_(sigma_3)(Delta_3)$

Finally, we can return the joint probability $p_1 * p_2 * p_3$ (assuming that the three sources of noise are independent).

So with the odometry model, I give the robot a way to understand the probability of where it is based purely on information taken from internal odometry data.

Remember that the motion model is used for *prediction*, not perception.
Correction/perception uses data coming from the external environment (like lasers or cameras matching a map). This is not the case here, because I only use internal proprioceptive data.

=== Sampling

While evaluation computes a probability for a given pose, *sampling* generates a new random pose.
Given the previous pose $s_(t-1) = (x, y, theta)$ and the odometry reading $u_t$, generate a random future pose $s_t$ distributed according to $p(s_t | s_(t-1), u_t)$.

Regarding the method:
- Compute the nominal odometry parameters from $u_t : (hat(delta)_1, hat(d), hat(delta)_2)$.
- Add random noise to each parameter (sampled from their respective $sigma$ distributions).
- Generate the new pose $s_t$ by running forward kinematics using these noisy parameters.

This operation is heavily used to implement Bayes filters that represent beliefs with discrete samples, most notably the *Particle Filter* (Monte Carlo Localization).

#warning[
  Limits of the Odometry motion model:
  1. I have to have a differential drive robot (or wheel encoders).
  2. It is an *a posteriori* approach. It cannot be used for trajectory planning because you cannot read encoders for a movement you haven't made yet.
]

== Velocity Model

Because of the limitations of the odometry model, we need an *a priori* approach. There is no need to use the odometry parameters. I want to reason about the motion *before* it actually happens, predicting the outcome based entirely on the mathematical commands sent to the motors.

#note[
  I have a control action I want to execute, described by linear and angular velocities:
  - *Linear velocity* ($v$): speed along the straight movement direction.
  - *Angular velocity* ($omega$): rate of rotation.

  $u_t = (v, omega)$

  It is like steering a boat or driving a car with a fixed steering wheel: the robot translates and rotates at the exact same time.
]

=== Evaluation

Given that the robot was commanded to drive from pose $s_(t-1) = (x, y, theta)$, at speed $v$ and turn rate $omega$ for a time interval $Delta t$, how likely is it that it ended up exactly at pose $s_t = (x', y', theta')$?

Because we apply a constant translation and rotation simultaneously, the object will move in a circular trajectory. The radius of this trajectory is determined by $r = |v \/ omega|$.
This is a formal kinematics problem: same core goal as odometry, but different equations.

#note[
  Given two velocities, there is a unique geometric arc the robot will attempt to follow.
]

Method:
- Find the unique circular arc that connects the starting pose $s_(t-1)$ to the claimed ending coordinates $(x', y')$.
- Compute the specific, ideal velocities $hat(v)$ and $hat(omega)$ required to follow that specific arc in time $Delta t$.

The explanation of the movement is the difference between the two quantities (the ideal velocities needed to reach $s_t$ vs the velocities $v, omega$ actually commanded).
The discrepancy would be described in terms of:
- Error on the arc radius (linked to the linear velocity $v$).
- Error on the arc length (linked to the angular velocity $omega$).

This is the noise: the small difference in linear velocity $(v - hat(v))$ and angular velocity $(omega - hat(omega))$.

However, this explanation is geometrically incomplete:
The robot may not follow the perfect arc in real life. Even if the environment is ideal, there can be bumps, slips, or asymmetrical friction.

#warning[
  We are forgetting about the noise on the final orientation! An arc only perfectly explains how to get from $(x,y)$ to $(x',y')$, but it dictates a very strict final angle.
]

We are considering noise on the two velocities but not on the final orientation $theta'$. 
To fix this, we introduce $hat(gamma)$ (heading drift). It represents the extra rotation, the noise that we were missing, independent of the circular arc.

The final probability is the product of three Gaussian errors:
- Translation error: $p(v - hat(v))$
- Rotation error: $p(omega - hat(omega))$
- Heading drift: $p(hat(gamma))$

=== Sampling

Given the previous pose $s_(t-1) = (x, y, theta)$ and the control velocities $u_t = (v, omega)$, we want to generate a random future pose $s_t$. This is essential for predictive planning algorithms (like simulating paths to avoid obstacles).

Method:
1. *Add noise to the controls*: Generate noisy velocities by sampling from zero-mean Gaussians based on the commanded velocities:
   - $hat(v) = v + "sample"(sigma_v^2)$
   - $hat(omega) = omega + "sample"(sigma_omega^2)$
   - $hat(gamma) = "sample"(sigma_gamma^2)$ (sample the heading drift)
2. *Apply Forward Kinematics*: Compute the new coordinates $(x', y')$ assuming the robot moved perfectly along the circular arc dictated by the noisy $hat(v)$ and $hat(omega)$ for time $Delta t$.
3. *Apply the drift*: Calculate the final orientation $theta'$ by adding the exact orientation change derived from the arc kinematics, plus the extra noisy heading drift $hat(gamma)$.