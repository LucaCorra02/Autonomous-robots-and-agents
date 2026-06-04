#import "../template.typ": *

= Probabilistic Motion Models

We will consider two main probabilistic motion models used in mobile robotics to describe the state transition probability:
$
  p(s_t | s_(t-1), u_t)
$

#note(title: "The Role of Motion Models")[
  In the context of a Bayes Filter, the motion model represents the *Prediction Step*. It embodies the *Markov Assumption*: the future state $s_t$ depends only on the current state $s_(t-1)$ and the control action $u_t$, and is conditionally independent of all past states and measurements.
]

We categorize these models based on the nature of the control input $u_t$:
- *Odometry-based motion models* (driven by sensor readings).
- *Velocity-based motion models* (driven by motor commands).

== Odometry-Based Motion Model

This model takes information from *internal sensors* and uses it to understand how the robot has moved. It is generally highly accurate over short distances but accumulates drift over long trajectories.

The sensor we will mostly talk about is the *wheel encoder*: it measures exactly how much the wheel has rotated in a given time step.
By considering the radius of the wheels and the distance between them (the wheelbase), we can compute the linear distance each wheel traveled. From this, we can derive the overall arc-like motion of the robot: total translation and total rotation.

#figure(
  image("/assets/odometry_wheel.png", width: 35%),
  caption: [Odometry and wheel encoders principles.],
)

#example[
  Suppose we have a differential drive robot in an initial pose $s_(t-1) = (x, y, theta)$, and it performed a control action $u_t$. From its internal odometry readings (physical rotations of the wheels), it computes where it thinks it should be now: $hat(s)_t = (hat(x), hat(y), hat(theta))$.

  How can we describe this movement mathematically? The most obvious way is to provide a *total translation* ($Delta T r$) and a *total rotation* ($Delta R o t$) unfolding concurrently.

  But are we missing something? Is this enough?
  Yes, it is geometrically complete! We can always describe the transition between two reference frames with these parameters, derived entirely from the kinematics of the robot.
]

#note[
  However, dealing with concurrent translation and rotation in a probabilistic framework results in highly complex non-linear equations and coupled covariances. To simplify the math, the odometry model utilizes a mathematically different, but *geometrically equivalent*, description.
]

Instead of concurrent motion, we are going to imagine that the movement unfolded in a sequence of three distinct phases:
$
  "Rotation" -> "Translation" -> "Rotation"
$
It's a mathematically convenient way to think about the movement that decomposes a complex 2D curve into three independent 1D steps.

- *First rotation*: rotate the robot *on the spot*, without translating, around the initial coordinates $(x, y)$, until it faces the destination point $(hat(x), hat(y))$.
- *Translation*: move straight, traveling a given distance along the direction of the new heading (untill its reach point $(hat(x), hat(y))$).
- *Final rotation*: adjust with another rotation *on the spot* until it reaches the final orientation $hat(theta)$.

#note[
  Maybe this description is *not* what really happened physically (the robot likely drove in a curve), but we don't care because this description is geometrically equivalent: the final position of the robot will be exactly the same, and it allows us to treat the noise of each step independently.
]

This representation is simpler because we can easily calculate these three parameters using inverse kinematics, given the starting pose and the odometry destination pose:

1. $hat(delta)_1 = "atan2"(hat(y) - y, hat(x) - x) - theta$ (First in-place rotation)
2. $hat(d) = sqrt((hat(x) - x)^2 + (hat(y) - y)^2)$ (Straight line distance)
3. $hat(delta)_2 = hat(theta) - theta - hat(delta)_1$ (Final rotation to reach orientation $hat(theta)$)

#figure(
  image("/assets/odometry_evaluation.png", width: 60%),
  caption: [Odometry model evaluation: Inverse kinematics and the rot-trans-rot representation.],
)

Here, these three computed parameters are treated as our *measured control action*
$
  u_t = (hat(delta)_1, hat(d), hat(delta)_2)
$

#warning[
  Crucially, these numbers are collected *after* the robot has physically moved. This makes the odometry model an *a posteriori* model.
]

=== Evaluation: Computing Pose Probabilities

The *evaluation algorithm* is used to *compute the scalar probability of a specific pose*.
Consider an arbitrary hypothesized pose $s_t$. What is the probability that the robot actually ended up there instead?

Due to a chain of events like: slipping wheels, uneven floors, or sensor quantization errors, the *true pose might differ* from the pure odometry one. Therefore, our _measured_ odometry parameters are different from the _ideal_ ones required to perfectly reach the hypothesized pose $s_t$.

#note[
  The goal is to formally *compute* the probability $p(s_t | s_(t-1), u_t)$. This is heavily used in grid-based Markov Localization, where we must evaluate the probability of every cell in the grid.
]

So, let's suppose the hypothesized pose $s_t$ corresponds to different odometry parameters $delta_1, d, delta_2$. The position calculated from odometry is instead reachable via $hat(delta)_1, hat(d), hat(delta)_2$.\
We compute the *displacement* between the ideal parameters and the ones we want to evaluate:

- $Delta_1 = hat(delta)_1 - delta_1$
- $Delta_2 = hat(d) - d$
- $Delta_3 = hat(delta)_2 - delta_2$

Then, for every displacement, we compute a score by feeding the error into a Probability Density Function (*PDF*) of a zero-mean *Gaussian* with variance $sigma^2$ (carefully defined as a function of the odometry parameters):
$
  p_sigma(x) = 1 / sqrt(2 pi sigma^2) e^(-x^2 / (2 sigma^2))\
$

#note[
  A *higher $sigma$* means that our *motion model is more noisy*, making it more probable that large discrepancies happened. With a low variance, large errors are basically impossible. So the choice of *$sigma$* is very important, because it *describes the physical environment* the robot is moving in (e.g., ice vs. dry asphalt).
]

#figure(
  image("/assets/gaussian_density_distribution.png", width: 90%),
  caption: [Zero-mean Gaussian density distributions. A low $sigma$ makes big displacements very unlikely, while a high $sigma$ makes them more likely.],
)



There are three scenarios regarding how to choose the $sigma$:
- *Scenario 1 (Static)*: Choose $sigma$ once and keep it forever. Is it good? It depends. It's good if the environment doesn't change (e.g., a uniform hospital floor). I can properly identify $sigma$ offline.
- *Scenario 2 (Adaptive)*: Adapt the value at runtime. Necessary if the environment changes dynamically (e.g., transitioning from tile to a thick carpet).
- *Scenario 3 (Motion-Dependent)*: A realistic derivation of the first. The noise depends on the motion itself.

#warning[
  If the robot does a short rotation, the absolute chance of error is small. If it does a big rotation, the probability of error increases. So the *amount* of the movement is key. I have to consider how big $hat(delta)_1, hat(d), hat(delta)_2$ are when defining $sigma$.

  So $sigma$ must be a function of the odometry parameters.
]

We calculate the independent probabilities using error parameters $alpha_1$ through $alpha_4$ (which are robot-specific constants reflecting motion noise):
$
  p_1 = p_sigma(Delta_1) & "with" sigma^2 = alpha_1 delta_1^2 + alpha_2 d^2 \
  p_2 = p_sigma(Delta_2) & "with" sigma^2 = a_1 delta_2^2 + a_2 d^2 \
  p_3 = p_sigma(Delta_3) & "with" sigma^2 = a_3 D^2 + a_4 delta_1 + a_4 delta_2
$

Finally, we return the *joint probability* $p_1 * p_2 * p_3$ (assuming that the three sources of noise are independent). Because rotation noise also depends on the length of the translation, long movements result in a probability distribution shaped like a "banana".

#figure(
  image("/assets/RotationNoise.png", width: 100%),
  caption: [Probability distributions for short vs long movements. Notice the "banana" shape for longer translations due to heading drift.],
)


#warning[
  The rotation noise depends *also* on the length of the translation distance.

  This is because once the robot has rotated, it starts the translation phase. During a long translation, there is noise (like one wheel slipping slightly more than the other). The longer the translation, the more probable it is that this noise can alter the rotational heading of the robot!
]

With the odometry model, I give the *robot* a way to *understand the probability of where it is* based purely on information taken from internal odometry data.

#note[
  Remember that the *motion model* is used for *prediction*, not perception.
  Correction/perception uses data coming from the external environment (like lasers or cameras matching a map). This is not the case here, because I only use internal proprioceptive data.
]

=== Sampling: Generating Random Poses

While evaluation computes a probability for a given pose, *sampling generates a random $s_t$* distributed according to:
$
  p(s_t | s_(t-1), u_t)
$
This is heavily used in the *Particle Filter* (Monte Carlo Localization).

Method:
1. Compute the nominal odometry parameters from $u_t : (hat(delta)_1, hat(d), hat(delta)_2)$.

2. Add random noise to each parameter:
  - $hat(delta)_1 = hat(delta)_1 - "Sample"(p_sigma())$ where $sigma^2 = alpha_1 hat(delta)_1^2 + alpha_2 hat(d)^2$
  - $hat(d) = hat(d) - "Sample"(p_sigma())$ where $sigma^2 = alpha_3 hat(d)^2 + alpha_4 hat(delta)_1^2 + alpha_4 hat(delta)_2^2$
  - $hat(delta)_2 = hat(delta)_2 - "Sample"(p_sigma())$ where $sigma^2 = alpha_1 hat(delta)_2^2 + alpha_2 hat(d)^2$

3. Generate the new pose $s_t = (x', y', theta')$ by applying forward kinematics:
  - $x' = x + hat(d) cos(theta + hat(delta)_1)$
  - $y' = y + hat(d) sin(theta + hat(delta)_1)$
  - $theta' = theta + hat(delta)_1 + hat(delta)_2$

#figure(
  image("/assets/odometry_sampling.png", width: 60%),
  caption: [Odometry model sampling process and histograms of sampled values.],
)

#warning[
  Limits of the Odometry motion model:
  1. I have to have a *differential drive robot* (or wheel encoders).
  2. It is an *a posteriori* approach. It cannot be used for trajectory planning because you cannot read encoders for a movement you haven't made yet.
]

== Velocity-Based Motion Model

Because of the limitations of the odometry model, we need an *a priori approach*. We want to reason about the motion *before* doing the action, or use it when our robot simply does not have wheel encoders (e.g., drones, boats).

#note[
  A velocity model assumes that the control action is described by linear and *angular velocities*:
  $u_t = (v, omega)$. It is like steering a car with a fixed steering wheel: the robot translates and rotates at the exact same time.
]

=== Evaluation: The Circular Arc Assumption

Given that the robot was commanded to drive from pose $s_(t-1) = (x, y, theta)$, at speed $v$ and turn rate $omega$ for a time interval $Delta t$, how likely is it that it ended up exactly at pose $s_t = (x', y', theta')$?

Because we apply a constant translation and rotation simultaneously, the robot attempts to move in a *circular trajectory*:
- Find the *unique circular arc* that connects the starting pose $s_(t-1)$ to the claimed ending coordinates $(x', y')$.

- Compute the *ideal velocities* $(hat(v), hat(omega))$ required to follow that specific arc in time $Delta t$.

The discrepancy would be described in terms of the linear and angular velocities:
- Error on the arc radius (linked to $v$).
- Error on the arc length (linked to $omega$).

#figure(
  image("/assets/velocity_evaluation.png", width: 40%),
  caption: [Velocity model evaluation: the model dictates a perfect circular arc, which is not fully consistent with reality without an error buffer.],
)

#warning[
  The model explanation is *not* fully consistent with reality.

  The robot in the reality is not perfectly following the circular arc. It is trying to follow it, but there is noise that causes it to deviate from the ideal path. This deviation is especially evident in the final heading, which can drift significantly due to small errors in translation and rotation during the movement.

  Without an _error buffer_ (an error margin), the model would assign a probability of $0$ to almost all actual transitions because real-world noise always causes heading drift.
]

To fix this, we introduce *$hat(gamma)$* (*heading drift*), the _error buffer_. It represents the *extra rotation* needed to explain why the robot's nose isn't pointing exactly tangent to the circle.

The final probability is the product of three Gaussian "grades":
- *Translation error*: $p(v - hat(v))$
- *Rotation error*: $p(omega - hat(omega))$
- *Heading drift*: $p(hat(gamma))$

#figure(
  image("/assets/probability_density_cloud.png", width: 60%),
  caption: [Probability density clouds for the velocity model (final pos $x = 1, y = 0.5$) showing the inclusion of heading drift to reflect real-world noise.],
)

The plot show a drop shape probability density cloud for the velocity model. The highest probability is around the ideal velocities. Near the starting point ($x,y=0$) the accumulated uncertainty is low, but as we move further away, the probability density spreads out due to the increasing uncertainty in the final pose caused by noise in both translation and rotation.


=== Sampling: Applying Noisy Controls

Given the previous pose $s_(t-1)$ and the control velocities $u_t = (v, omega)$, we want to *generate* a random future pose *$s_t$*. Sampling works analogously to the odometry model.

Method:
1. *Add random noise* and compute random final heading drift:
$
      v & = v + "Sample"(p_sigma())     & "with" sigma^2 = alpha_1 v^2 + alpha_2 omega^2 \
  omega & = omega + "Sample"(p_sigma()) & "with" sigma^2 = alpha_3 v^2 + alpha_4 omega^2 \
  gamma & = "Sample"(p_sigma())         & "with" sigma^2 = alpha_5 v^2 + alpha_6 omega^2 \
$

2. *Generate the new pose $s_t$* by feeding the above noisy parameters into the forward kinematics equations.
