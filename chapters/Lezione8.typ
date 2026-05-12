#import "../template.typ": *

= Bayeses Filter

Partical filter is a sample of the belief that we want to manteine, instead of representing the belief with a formula.
#warning()[
  In this case the real bottlekenck is the number of particles that we can mantain, and the more particles we have the better the approximation of the belief is.
]

== Robot Motion componet

In our bayes filter we need to predict the action of the robot. We need a model for the prediction of the next state.

Let's considera a differential drive robot: two wheeels that can rotato at different speed. By applying a difference in the speed of the two wheels we can make the robot turn.

=== Differntial drive

//aggiungre immagine

We can represent the robot with a pose $((x,y), theta)$ in a global frame of reference. We can't see the $z$ because we are in a 2D world. We also have a red frame of reference that is attached to the robot.

*Skid steering*: is when we apply different angular velocity to the two wheels, the robot rotate. We are only consider an exampel with two wheels, but we can have more than two wheels.

We only need two parameters to describe the movement of the robot:
- $R$: is the radius of the wheel, $2 R$ is the width of the robot.
- $L$: separation of the two wheels, $L$ is the width of the robot.

The *controls* allow us to control the robot:
- $omega_r, omega_l$: are the angular velocity of the right and left wheel, respectively.

- $v_r, v_l$: is the linera velocity of the right and left wheel, respectively. We can compute the linear velocity of the wheel as $v = R * omega$.

#note()[
  Angular velocity and linear velocity are different, but they are related by the radius of the wheel. We can control the robot by controlling the angular velocity of the wheels, or by controlling the linear velocity of the wheels.
]

Possibile motions:
- forward / backward
- turn in place
- motion alog an arc

We can rapresents the postion of the robot in the global frame of reference with the pose $((x',y'),theta)$. Suppose that we have a plane, we chose a red point that is the pose. It's not only $x, y$ but also $theta$, the red point lives in a $3 D$ point, it represent a possibile configuration. Given another point the question is if we can *compute the velocity between the two points*?\
The velocity is a vector with a magnitude and a direction but *i can't chose a random velocity*:
- The robot has a maximum velocity, so we can't go faster than that.

- The robot can't move in any direction for some physical constraints, for example a car can't move sideways, it can only move forward and backward. This depends on the *differential drive model*, if we have a different model we can move in different ways.\
  #note()[
    This contraints is what velocity i can apply to the root in a particular configuration.
  ]

- When we integrate a velocity we obtain the position. This constraint about velocity can not integrate to obtain a configuration constraint, that is called a *non-holonomic constraint*.

  #informally()[
    The robot can be anywhere in the plane but the way i reach a particular position can't be any.
  ]

if we have a holonomic robot, it can be move in any direction and way in the space, but they are very difficult to build. For example a drone is a holonomic robot, it can move in any direction and way in the space.

Formally if i want to describe an object that change in time i can use the *derivative*. I can compute the derevative of $x,y,theta$ as a function of the controls $theta_r, theta_l$ given this simple trigonometric formula:
$
  dot(x) = R/2 * (omega_r + omega_l) * cos(theta) \
  dot(y) = R/2 * (omega_r + omega_l) * sin(theta) \
  dot(theta) = R/L * (omega_r - omega_l)
$
The $dot(x)$ it says: if i change the controls for a small amount of time how much i change the position of the robot. If i want to use this equation to predict the position of the robot after a small time a need to introduce the time concept:
$
  x(t + delta t) = x(t) + dot(x) * delta t \
  y(t + delta t) = y(t) + dot(y) * delta t \
  theta(t + delta t) = theta(t) + dot(theta) * delta t
$
I can use the variation integrate over time. $dot(x)$ is in meter at second, if i multiply it for the time (seconds) i obtain the variation of the position in meter.

#informally()[
  If i want to predict the position of the robot after a certain time i need:
  - The current pose of the robot
  - The controls that i want to apply to the robot
  - The time that i want to apply the controls
  - And the kimematic model of the robot, that is the equation that i have just written. Also they consider the movement constraint of the robot, that is the non-holonomic constraint.
]

== Motion model

The previous model can't describe the robot. *It's note consider the noise*, when the robot has wheels that rotate are not perfect, they can slip, they can have a different radius, the robot can be on a surface that is not flat, etc.

A motion model it describe the relation between the current pose $s_(t-1)$ the control action $u_t$ and next pose $s_t$.It teels us how the are correlated and consider the noise.
#note()[
  The state or the pose is called now $s$, instead of $x$ as in previous lectures.
]

we could use kinematics:
- *Forward kinematics*: Given $s_(t-1)$ and $u_t$ compute $s_t$ it's an easy problem
- *Inverse kinematics*: Given $s_(t-1)$ and $s_t$ compute $u_t$ it's a hard problem, because we have the non-holonomic constraint, we can't move in any way to reach a particular configuration.\
  It's a more interesting problem, because we want to now the control to tell at the robot to reach a particular configuration.

Suppose a robot that teels us:
- The current pose $s_(t-1)$
- The control that we want to apply $u_t$


=== Forward kinematics

The motion models want to predict how confident we are about the next pose of the robot $s_t$.
- The answer is a *score of confidence*, how plausible is that the robot is in a particular pose $s_t$ given the current pose and the control.
  #note()[
    We can use a score because we can renormalize it, we can make it a probability distribution.
  ]

- In the reality we want to give this answer to every possible pose $s_t$ and not only for a specific $s_t$.

Using the forward kinematics we can say that the robot should be in $s_t^*$, the point predicted by the kinematic model. It's $s_t^*$ equal to $s_t$?:
- No $->$ the answer is zero
- Yes $->$ the answer is one

it's seem that with this kind of knimetics *we are to confident about the next pose* of the robot, we can see that the final score of the robot is not a probability distribution.

#note()[
  This type of model is not very useful in robotics
]

=== Forward kinematics with noise

The question and parameters are the same of the previous model, but we want to consider the noise. We can use a *probability distribution* to represent the noise, for example a Gaussian distribution.

- Using forward kinematics we can predict if the robot was in $s_(t-1)$ and we apply the control $u_t$ the robot should be in $s_t^*$.

- It's possible that due to the noise the comand $u_t$ made the robot is not in $s_t^*$ but in a different pose, for example $s_t$.

- How can assign a probability to $s_t$? We can measure the descrepancy (or the distance) between $s_t$ and $s_t^*$. Let's call this distance *$Delta$*:
  - $Delta = 0$ if the distance between $s_t$ and $s_t^*$ is zero, so the robot is in the predicted pose, so we are very confident that the robot is in $s_t$.

  - $Delta$ is bigger if the distance between $s_t$ and $s_t^*$ is bigger, so we are less confident that the robot is in $s_t$.

If $Delta$ is small the probability should be high, if $Delta$ is big the probability should be low. The bigger is the descrepancy between $s_t$ and $s_t^*$ the less confident we are that the robot is in $s_t$. To compute this we need to calculate:
$
  p(Delta)
$

//riguardare
#example()[
  Suppose that the robot is snaped with the grid, it can move right or left. The robot can move right in the next cell.

  The robot has a distance sensore, it tells the distance between itself and a landmark in the plane. The distance is given in number of cells to simplify the prolem.

  In our demo we try to simulate the reality, we add a gausian noise, most of the time the robot is moved by 1 cell the next cell, but sometimes the robot is moved by 0 cell or by 2 cells. The avarege is zero but it will still be errors with some probability that affect the avarage.


  the gaussian always have a mean of zero, but i can choose the standard deviation, if i choose a small standard deviation the robot is more confident about the next pose, if i choose a big standard deviation the robot is less confident about the next pose.

  The robot in reality we do $mu = 1$ plus a random number that is sampled from a gaussian with mean zero and standard deviation $sigma$.

  the black lane is before taking measurements, the blue lane is after taking measurements.

  the green vertical line is the real postion of the robot. The blue curve is the prostirior.

  - In the first row we can see that the sensore is pretty accurate, the robot belief it can be anywere. The black lane become the blue line beacuse of the correction that the filter has made.

  - at step twenty the robot was able to track how the position changes

  In the second example the robot has a huge noise that seems is a kindnapped robot. THe movement is not tell me any clue, the sensor even if it is very perfect can't tell me anything about the position of the robot, so the belief is pretty much the same as before taking measurements.

  In the third example we have a blind robot, as a perfect motion model but a very bad sensor, the robot is pretty much lost, the belief is pretty much the same as before taking measurements:
  - The model after two step can predict the correct side in which the robot is

  - But the sensor is not able to give us any clue about the position of the robot, so the belief is pretty much the same as before taking measurements.








]
