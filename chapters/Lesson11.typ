#import "../template.typ": *

== Sensors

Sensors are broadly classified into two categories: those measuring the robot's internal state (*proprioceptive*) and those measuring the environment (*exteroceptive*).

=== Proprioceptive Sensors

Proprioceptive sensors measure values internal to the robot itself (robot introspection).\
An example of this sensors are:
- *Wheel encoders* (odometry): Measure the angular position and velocity of the wheels using optical or magnetic sensors. They provide low-level motor control and allow us to estimate the robot's pose (position and orientation) through odometry.

  #warning[
    Odometry measurements should not be blindly trusted over long distances. They work under the assumption of *no noise* (no wheel slip, exact wheel diameter).

    This is known as the *dead reckoning* problem: if we rely solely on odometry, our pose estimate will diverge significantly from reality over time (errors accumulate over time).
  ]




- *Inertial Measurement Units* (IMU): Measure linear acceleration, angular velocity, and orientation. IMUs are frequently fused with encoders to mitigate dead reckoning drift.


- *System health diagnostics*: Monitor battery level, temperature, and other internal states




=== Exteroceptive Sensors

Exteroceptive sensors measure information from the robot's environment. An example of this sensors are:

- *Sonar* (ultrasonic) sensors: They measure distance to the *nearest obstacle* in a given direction using sound waves. Some properties are:
  - Very noisy and inexpensive
  - Wide FOV but short range (a few meters)
  - Good for obstacle avoidance (reactive tasks)
  - Poor for localizing features or building high-resolution maps

  #note()[
    Sonar sensors don't tell us *where* obstacles are, just that they exist
  ]

- *Laser rangefinders* (Lidar): They use light beams to measure distances with high precision:
  - Much more accurate and faster than sonar
  - Traditionally more expensive than sonar (costs have decreased recently)
  - Excellent for *mapping* and *localization*

- *3D range finders* (3D Lidar): These sensors extend laser rangefinders to three dimensions by reading multiple beams across a solid angle, returning a *3D point cloud* of the environment (a set of coordinate points in the sensor's reference frame).

- *GPS* (Global Positioning System): Provides *global coordinates* (latitude and longitude) for outdoor localization:
  - Requires clear line of sight to multiple satellites
  - *Not guaranteed* in urban canyons (surrounded by tall buildings), under tree canopies, or with irregular walls
  - Often unavailable or unreliable indoors

- *Cameras* (RGB): Capture visual information in 2D images.

- *Contact sensors* (bumpers): Detect physical collisions with objects, essentially acting as binary switches.


#note()[
  Different sensors provide different types of information with varying accuracy, range, and cost. Effective robotic systems often combine multiple sensor types.
]

= Gaussian Filters for State Estimation

To estimate a robot's pose in a continuous environment, we need a *continuous Bayes filter*. This probabilistic approach:
1. Represents the robot's belief (confidence) about its current pose
2. Uses motion models to predict pose changes
3. Uses sensor models to correct predictions with measurements
4. Recursively propagates this belief over time

Formally, the Bayes filter consists of two steps:
$
  "Prediction:" space overline("Bel"(s_t)) & = integral mr(p(s_t | u_t, s_(t-1))) "Bel"(s_(t-1)) d s_(t-1) \
            "Correction:" space "Bel"(s_t) & = eta dot mr(p(z_t | s_t)) space overline("Bel"(x_t))
$
the prediction step integrates over all possible previous states, while the correction step applies Bayes' rule to update the belief based on new measurements.

#note()[
  If $mr(p(s_t | u_t, s_(t-1)))$ and $mr(p(z_t|s_t))$ have arbitrary/complex forms, solving the prediction step turns out to be *analytically intractable*.

  for that reason, we need to make *simplifying assumptions* about the motion and perception models to make the Bayes filter tractable.
]

== Gaussian Filters

This leads us to the *Gaussian filters*, which are a family of algorithms that implement the Bayes filter under specific assumptions about the noise and system dynamics.

=== Gaussian Distributions

We model *noise using Gaussian* (Normal) distributions because they have unique mathematical properties:
- $A times "Gaussian" -> "Gaussian"$
- $"Gaussian" times "Gaussian" -> "Gaussian"$
- Defined by just two parameters: if we represent a belief as a Gaussian, we only need *two* numbers (mean $mu$ and variance $sigma^2$) to represent the entire probability distribution over millions of possible states.

#warning()[
  $mr("Limitations")$: Gaussians are *unimodal*, they can only *represent a single hypothesis* or peak. They cannot represent multimodal beliefs (multiple distinct possibilities).
]


== Kalman Filter

The *Kalman Filter* is a Bayes filter assuming that motion and sensing models are simple enough.

#informally()[
  We pretend that *motion* and *sensing* models are the *simplest possible* ones (linear transformations). This is an approximation of reality, but it gives us mathematical tractability—we can solve the Bayes filter integral analytically instead of numerically.
]

For the Kalman filter to work, we make three assumptions:

1. *Gaussian Prior*: The initial belief must be a Gaussian distribution:
  $ "Bel"(x_0) ~ cal(N)(mu_0, sigma_0^2) $
  We cannot choose an arbitrary prior shape, but we can choose its parameters (mean and variance). If the initial state is completely unknown, we use a very wide Gaussian (large variance). If it's known, we use a narrow Gaussian.

2. *Linear Motion Model + Gaussian Noise*: The pose transitions linearly:
  $
    s_t = A_t s_(t-1) + B_t u_t + epsilon_t, quad epsilon_t ~ cal(N)(0, r_t) \
    p(s_t | u_t, s_(t-1)) = 1 / (sqrt(2 pi r_t)) e^(-(s t-mr((A_t s_(t-1)+B_t u_t))^2)/(2 r_t))
  $
  where $A_t$ and $B_t$ are transition matrices.
  #note()[
    This is a *strong assumption*: real robot kinematics are almost always non-linear.
  ]

3. *Linear Perception Model + Gaussian Noise*: Measurements relate linearly to the state:
  $
    z_t = C_t s_t + delta_t, quad delta_t ~ cal(N)(0, q_t) \
    p(z_t | s_(t)) = 1 / (sqrt(2 pi q_t)) e^(mb((z_t-C_t s_t))^2/(2 q^2_t))
  $
  where $C_t$ is the measurement matrix.

  #note()[
    This is also a strong assumption: real sensor models are typically non-linear.
  ]

With these assumptions, the Bayes filter integral becomes analytically tractable. The prediction and correction steps reduce to simple linear algebra (matrix multiplications). We get:

- *Input*: $"Bel"(s_(t-1)) = (u_(t-1), sigma^2_(t-1), u_t, z_t)$
- *Output*: $"Bel"(s_t) = (u_t, sigma^2_t)$

#note()[
  *The output belief is always strictly Gaussian.* We preserve the distribution's shape throughout the filtering process.
]

Tha main $mg("advantage")$ of the Kalman filter is that it provides a simple implementation of the Bayes filter (only matrix multiplications).\
The main $mr("disadvantage")$ is that the *assumptions are often unrealistic* for real-world robotics applications, which motivates the need for more advanced filters like the Extended Kalman Filter (EKF).

== Extended Kalman Filter (EKF)

The Extended Kalman Filter *addresses* the main limitation of the standard Kalman Filter: the *linearity assumption*.

#warning[
  In the real world, robot kinematics and sensor geometries are *almost never* linear. This makes the standard Kalman Filter's assumptions unrealistic for most practical applications.
]

=== Relaxing Linearity

The EKF keeps the three-part assumption structure but replaces the linear functions with non-linear ones:

1. *Non-linear Motion Model*: The motion model is a non-linear transformation plus a Gaussian noise term:
  $
    s_t = mr(g(s_(t-1), u_t)) + epsilon_t, quad epsilon_t ~ cal(N)(0, r_t)
  $
  where *$g$* is a non-linear function.

2. *Non-linear Perception Model*:
  $
    z_t = mb(h(s_t)) + delta_t, quad delta_t ~ cal(N)(0, q_t)
  $
  where *$h$* is a non-linear function.

#warning()[
  The problem is that pushing a Gaussian distribution through a non-linear function *distorts its shape*. The *result* is generally *not Gaussian*, so we cannot apply standard Kalman filter equations directly.
]

To solve this problem, we *linearize* the non-linear functions locally around our current best estimate (the current mean of the filter). We linearize $g$ around $mr(g(s_(t-1), u_t))$ and $h$ around $mb(h(s_t))$.

#informally()[
  The key insight: *We pretend the world is linear, but only in a small region around where the robot currently is.*
]

We use first-order Taylor expansion to compute the linear approximation. This requires computing derivatives of the functions with respect to state variables. The resulting matrices of partial derivatives are called *Jacobians*.

#align(center)[
  #image("/assets/KalmanFilter.png", width: 50%)
]

As we can see from the figure:
- *Bottom-Right Panel* $p(x)$: Displays the initial state estimation. It shows a shaded Gaussian probability density function centered around a mean $mu$ (marked with an "x"). This represents the input uncertainty.

- *Top-Right Panel* $y = g(x)$: Illustrates the transformation space mapping the input to the output.
  - The solid black curve represents the true, non-linear system or observation model, $g(x)$.
  - The dashed straight line is the *Taylor approximation*, representing the linearization of $g(x)$ tangent at the specific point of the estimated mean $mu$.

- *Top-Left Panel* $p(y)$: Shows the resulting probability distributions mapped onto the y-axis.
  - The *shaded, irregularly shaped area* represents the true probability density, $p(y)$. Because the function $g(x)$ is non-linear, this true output is geometrically distorted and is no longer a Gaussian bell shape.
  - The *dashed Gaussian curve* represents the EKF approximation. By mathematically passing the input through the linear Taylor approximation instead of the actual non-linear curve, the EKF forces the output to remain a perfect, manageable Gaussian.


The diagram visually highlights the fundamental compromise of the EKF:
- $mg("pros")$: It simplifies complex, non-linear realities into manageable Gaussian models by linearizing around the current estimate
- $mr("cons")$: Introduces an *approximation error*, which is clearly visible as the geometric discrepancy between the exact shaded distribution and the dashed EKF Gaussian.

#example()[
  The example aim to show the *Dead Reckoing Problem*, if we rely only on the motion model uncertainty grows over time, and our pose estimate diverges from reality. The EKF prediction step uses the motion model to move the belief forward, but we absolutely need the *correction step* with exteroceptive sensors (e.g., GPS, Lidar) to reduce uncertainty back down.

  *Demonstration scenario*:
  - Robot: Differential drive with wheel encoders and GPS sensor

  - We apply a sequence of control actions: go straight, turn left, curve right

  - The velocity model is non-linear (e.g., due to wheel slip, non-ideal kinematics), and the GPS measurements are noisy. To avoid the non-linearity of the velocity model, we use the EKF to linearize it around the current estimate.

  *Dead reckoning alone* (black line): The pose estimate continuously diverges from the $mg("true position")$ because we only use the motion model and ignore the GPS measurements.

  *EKF with GPS fusion* ($mb("blue")$ line): By combining the wheel encoders (motion model) with $mr("GPS")$ measurements (correction), the EKF estimate stays very close to the true position. The sensor noise is handled appropriately, and the estimate remains reliable.

  #align(center)[
    #image("/assets/KalmanExample.png", width: 90%)
  ]
]

== Particle Filter

They are a *non parmaetric* approach: instead of represent the posterior as a parametric distribution (like a Gaussian), we represent it as a set of discrete samples (*particles*). Particles are a set of random state samples form the posterior distribution, each with an associated weight representing its importance:
$
  {s_t^1,s_t^2, dots, s_t^n} tilde p(s_t | z_(1:t), u_(0:t))
$

Their main $mg("advantage")$ is that they can represent *arbitrary distributions*, including multimodal ones, without making strong assumptions about the underlying noise or system dynamics.

Pseudocode for the particle filter algorithm:
#pseudocode(
  [*for* $i in {1,dots,n}$],
  indent(
    [$s_t^i <- "Sample"(p(s_t | s_(t-1), u_t))$ sample from the motion model],
    [Compute the importance weight: $s_t^i : w_t^i = p(z_t | s_t^i)$],
    [Add $<s_t^i, w_t^i>$ to the particle set],
  ),
  [Perform importance resampling: $s_t^i$ is selected with probability proportional to $w_t^i$],
)

By analyzing its steps:
1. *Sample*: We generate new particles by sampling from the motion model distribution, which predicts how the state evolves based on the previous state and control input.

2. *Weight*: For each particle, we compute an *importance weight* $w_t^i$ based on how well the predicted state explains the new measurement. This is done by evaluating the likelihood of the measurement given the particle's state $p(z_t | s_t^i)$.

3. *Resample*: We perform importance resampling to focus on the most likely particles. Particles with higher weights are more likely to be selected for the next iteration, while those with low weights may be discarded.

The final result is a new set of particles that approximates the posterior distribution after incorporating the latest measurement.




