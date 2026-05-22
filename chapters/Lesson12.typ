#import "../template.typ": *

When something like an obstacle enter in the fov of the robot, the probability to get an higher mesurament than $z^*$ should be zero, at least the mesurament is lower than $z^*$. Measuring a larger value similar to $z^*$ should be less probable than measuring a smaller value. For that reason we have an exponential distribution.

== Likelihood field

We are not reasoning about the probability of the mesurament $z$ given the pose of the robot, but we are reasoning about the probability of the mesurament $z$ given the position of the obstacle.

The map is computed in this way:
- I don't care about the pose and orentation of the robot.
- I suppose that the robot sensor measures combine with his position and orientation give a mesurament $z$ (green dot)
- I need to compute how probable is to get that mesurament $z$ given the position of the nearest obstacle (the responsible for that mesurament).

=== Proprioceptive sensors

#informally()[
  it's something with come form the robot
]

An example it's the wheel encoder, that measure the rotation of the wheel, and from that we can compute the distance traveled by the robot.

Another sensor is the *IMU* (Internal Measurment Unit), it can measure the linear acceleration, angular velocity, and magnetic field stenght. Resturns linear acceleration and angular velocity, that can be used to compute the pose of the robot (quaternions, roll, pitch, yaw).

We can also have system health sensors, that measure the temperature of the robot, the battery level, etc.

=== Exteroceptive sensors

#informally()[
  it's something with come from the environment
]

An example it's the sonar, that measure the distance to the nearest obstacle in a certain direction.
#note()[
  They have a wide fov and short range. They not suitable for localization feature in the environment or builiding a map of the environment, but they are good for obstacle avoidance (tehy not tell us were the obstacle is).
]

If the robot has a constrait on the valocity that we can apply to the robot (the robot can move anywhere in the space, but with a contstrain on the way to reach that position), its a non holominic robot. the robot pi it's a holominic robot

Also *Laser RangeFinder* are in this category. They measure distances along a set of directions, very often along a plane. They are more expencive than the sonar, but they are more accurate and have a longer range. They are suitable for localization and mapping, but they are not good for obstacle avoidance (they tell us were the obstacle is, but they not tell us how to avoid it).


There are also *3d rangefinder*. They give us a 3d point cloud of the environment, for example a set of points coordinates referred to a reference frame placed on the sensor.

ALso *cameras* are in this category. They give us a 2d image of the environment, that we can use to extract features, or to build a 3d model of the environment. We can also have bumpers, they are used to determine if the robot it's toching something, (they are like a binary switch).

== Bayer Filter Implementation

In reality we can only use a continuois bias filter where the belief its a simplify version (like a function).

the first part is the perceptional model, the secon part is the motion model. We need a way to compute that probability, then we can only need to integrate them.

if the two part are very complex form , solving the prediction step and the correction step can be very complex. We introduce the *Kalmn Filter*: I assume that motion and sensing model are very simple, enough that the prediction step becomes analytically tractable, we will get a formula to solve the integral.

=== Gaussian distribution

we can use a Gaussian distribution, a gaussian can represent a simple belif (with only a local maximum), and it can be easily manipulated mathematically.

If we represent the belief as a Gaussian, with two numbers we can represent the belief over a milion of possible states.

Kalmar filter has a lot of assumptions:

1. The belief is represented as a Gaussian distribution $"Bell"(s_0) tilde N(mu_0, sigma_0^2)$. We can't choose the form of the prior, but we can *choose the parameters* of the prior (the mean and the variance). Initially the parameters are set to represent a very uncertain belief (a Gaussian with a very large variance).

2. The *motion model* is a linera trasformation plus a Gaussian noise.
  #note()[
    It's a very strong assumption, because motion models are often non linear. In the reality it's not like that.
  ]
  The next pose of the robot $s_t$ it's a linear combination of the previous pose $s_{t-1}$ and the control input $u_t$, plus a Gaussian noise with zero mean and covariance $R_t$:
  $
    s_t = A_t s_(t-1) + B_t u_t + epsilon_t tilde N(0, r_t)
  $
  where $A_t$ and $B_t$ are matrices that depend on the time step $t$.\
  The all thing are rappresented with a Gaussian with mean $A_t s_(t-1) + b_t u_t$ and variance $R_t$ (the noise variance).

3. The *perception model* is a linear trasformation plus a Gaussian noise.
  #note()[
    It's a very strong assumption, because perception models are often non linear. In the reality it's not like that.
  ]
  The mesurament $z_t$ it's a linear combination of the pose of the robot $s_t$, plus a Gaussian noise with zero mean and covariance $Q_t$:
  $
    z_t = C_t s_t + delta_t tilde N(0, q_t)
  $
  where $C_t$ is a matrix that depend on the time step $t$.\
  The all thing are rappresented with a Gaussian with mean $C_t s_t$ and variance $q_t$ (the noise variance).

=== Kalman Filter

Kalmar filter now become a trivial linear algebra problem in repsect of intefral, we can solve the prediction step and the correction step with a simple formula.

THe belif filter admit a solution that we can compute basic some matric moltiplication. The final belif it's also a Gaussian distribution, with mean and variance that we can compute with a simple formula. The result change the shape from the prior, but it's still a Gaussian distribution.

== Extended Kalman Filter

The EKF relaxes the assumption of linearity, we can have a non linear motion model and a non linear perception model.

The first assumption remain, the prior belief is represented as a Gaussian distribution.But:

1. The motion model it a non linear trasformation plus a Gaussian noise. $g$ its a non linear function:
$
  S_t = g(s_(t-1), u_t) + epsilon_t tilde N(0, r_t)
$
#warning()[
  In this case we can't model the distribution probability $p(s_t | u_t, s_(t-1))$ as a gaussian distribution, because the non linear function $g$ can change the shape of the distribution.
]
2. The perception model it a non linear trasformation plus a Gaussian noise. $h$ its a non linear function:
$
  z_t = h(s_t) + delta_t tilde N(0, q_t)
$

Singe $g$ and $h$ are non linear, the bayes filter does not admit an analytical solution. We need to *linearize* g and h around the points that we want to evaluete the function consider in the filter. In this case:
- Linearize $g$ around $g(s_(t-1), u_t)$
- Linearize $h$ around $h(s_t)$

When we linearize stuff we need to compute the derivative of the function, meaning that the math become more complex.

*Unicycle model*: its when we describe the motion of a robot with two wheels, we can use the EKF to estimate the pose of the robot given the control input and the mesurament.


#example()[

  //ricontrolalre
  If i have a differential drive robot, if we have a direction $v$ and linear velocity $w$, we need to convert $v$ and $w$ to an angular velocity for each wheel.

  We suppose that robot have a gps sensor that tell the $x$ and $y$ of the robot in the plane.

  Given $v$ and $w$ (the current pose) we need to compute the ideal next pose. THis is a non linear function (cosine and sine). The linear sensing model is a real pose + a noise gaussian.

  In the example the sensing noise and the motion noise are represented as a matrix. Each dimension of the matrix affects a specific coordinates on the plane (x,y, $theta$).

  At each temporal step an hardcoded control action will be applied to the robot. The robot go straight, go left and curve right for a certain amount of time.

  in the simulation loop i compute the true coordinates of the robot (it don't know them). They are compute as the equation in the previous slide.

  The robot its going to recive a the real measuremtn plut a gaussian noise (we simulate the mesurament that come from the gps sensor).

  Dead reckoning: i compute the current position of the robot. It assume an ideal enviroment (no slippage) and we are not considering the gps mesurament (only the internal mesurament will be considered).
  #note()[
    This exstimation continue to diverge form the real position of the robot, because we are not considering the gps mesurament, and we are assuming an ideal enviroment (no slippage). The error accumulate over time, and the estimation become more and more wrong.
  ]
  The blue curve its what we get when we combine the dead reckoning with the gps mesurament, using the EKF. The estimation is very close to the real position of the robot, because we are considering the gps mesurament, and we are not assuming an ideal enviroment (we are considering the noise).

]

#warning()[
  The previus example show usa that we can't realay only on the internal mesurament of the robot, because the error accumulate over time. We need to combine the internal mesurament with the external mesurament, even if they are noisy, to get a good estimation of the pose of the robot.
]
