#import "../template.typ": *

=== Robotic perspective

Usually a state $x$ encodes some features of the robot or of the environment we want to reason about. A state can be static or dynamic, fully observable or partially observable, discrete or continuous, $dots$.

In mobile robotics one common state is the *$mr("pose")$* of the robot:
$
  p = <(hat(x), hat(y)), theta>
$
it encodes the position on the plane with respect to some fixed frame of reference and the orientation $theta$

#figure(
  cetz.canvas({
    import cetz.draw: *

    // Canvas scale and robot parameters
    let cx = 1.8
    let cy = 1.2
    let theta = 0.65 // robot orientation in radians
    let rw = 1.4 // robot width
    let rl = 1.0 // robot length

    // helper: rotate a local point (x,y) by theta and translate to (cx,cy)
    let rot = p => {
      let x = p.at(0)
      let y = p.at(1)
      let rx = cx + calc.cos(theta) * x - calc.sin(theta) * y
      let ry = cy + calc.sin(theta) * x + calc.cos(theta) * y
      (rx, ry)
    }

    // Draw global axes
    line((0, 0), (4.2, 0), stroke: black + 1.4pt)
    line((0, 0), (0, 3.6), stroke: black + 1.4pt)
    // axis arrowheads
    line((4.0, -0.06), (4.2, 0), stroke: black + 1.4pt)
    line((4.0, 0.06), (4.2, 0), stroke: black + 1.4pt)
    line((-0.06, 3.45), (0, 3.6), stroke: black + 1.4pt)
    line((0.06, 3.45), (0, 3.6), stroke: black + 1.4pt)

    // dashed reference lines (blue)
    let dash = (a, b) => line(a, b, dash: (0.06, 0.06), stroke: rgb("5fa6e6") + 0.9pt)
    dash((cx, 0), (cx, cy))
    dash((0, cy), (cx, cy))

    // robot body corners in local robot frame (centered)
    let hw = rw / 2
    let hl = rl / 2
    let c1 = rot((-hw, -hl))
    let c2 = rot((hw, -hl))
    let c3 = rot((hw, hl))
    let c4 = rot((-hw, hl))

    // robot main body (diamond/rectangle rotated) — outline using lines
    line(c1, c2, stroke: black + 1.6pt)
    line(c2, c3, stroke: black + 1.6pt)
    line(c3, c4, stroke: black + 1.6pt)
    line(c4, c1, stroke: black + 1.6pt)

    // central red circle (robot center)
    circle((cx, cy), radius: 0.22, fill: rgb("c94141"), stroke: none)

    // wheels: two small rectangles on left/right sides (local offsets)
    let wheel = (dx, dy) => {
      let ww = 0.18
      let wl = 0.55
      let p1 = rot((dx - ww / 2, dy - wl / 2))
      let p2 = rot((dx + ww / 2, dy - wl / 2))
      let p3 = rot((dx + ww / 2, dy + wl / 2))
      let p4 = rot((dx - ww / 2, dy + wl / 2))
      line(p1, p2, stroke: luma(120))
      line(p2, p3, stroke: luma(120))
      line(p3, p4, stroke: luma(120))
      line(p4, p1, stroke: luma(120))
    }

    wheel(-hw - 0.06, 0.0)
    wheel(hw + 0.06, 0.0)

    // sensors (yellow) near the front corners
    let sensor = (dx, dy) => {
      let s = 0.14
      let p1 = rot((dx - s / 2, dy - s / 2))
      let p2 = rot((dx + s / 2, dy - s / 2))
      let p3 = rot((dx + s / 2, dy + s / 2))
      let p4 = rot((dx - s / 2, dy + s / 2))
      line(p1, p2, stroke: black + 0.6pt)
      line(p2, p3, stroke: black + 0.6pt)
      line(p3, p4, stroke: black + 0.6pt)
      line(p4, p1, stroke: black + 0.6pt)
    }

    sensor(0.45, hl - 0.14)
    sensor(0.85, 0.0)

    // orientation wedge (field of view) in translucent blue
    let fov = 1.5
    let ang = 0.65
    let pA = (cx + fov * calc.cos(theta + ang), cy + fov * calc.sin(theta + ang))
    let pB = (cx + fov * calc.cos(theta - ang), cy + fov * calc.sin(theta - ang))
    // field-of-view triangle outline
    line((cx, cy), pA, stroke: rgb("9fc9ee") + 1.2pt)
    line((cx, cy), pB, stroke: rgb("9fc9ee") + 1.2pt)
    line(pA, pB, stroke: rgb("9fc9ee") + 1.2pt)

    // filled theta wedge at robot center (green)
    let a1 = theta - 0.28
    let a2 = theta + 0.02
    let wr = 0.42
    let ar1 = (cx + wr * calc.cos(a1), cy + wr * calc.sin(a1))
    let ar2 = (cx + wr * calc.cos(a2), cy + wr * calc.sin(a2))

    // axis labels
    content((1.75, -0.3), $hat(x)$, font: ("New Computer Modern", 10pt))
    content((-0.22, 1.25), $hat(y)$, font: ("New Computer Modern", 10pt))
  }),
  caption: "Robot pose (schematic)",
)

The robot can change information the environment:
- *From the environment to the robot*: sensor measurements $z$ typically do *not modify* the environment, they acquire information and reduce the uncertainty about the state of the world.

- *From the robot to the environment*: *control actions* $u$ typically *modify* the environment (the robot physically acts int he environment), they change the state of the world and increase the uncertainty about the state of the world.

The robot needs to *estimate* the state of the world $X$ by using the sensor measurements $z$ and the control actions $u$, this is called a *belief* about the state of the world, and it is denoted as $"Bel"(x_t)$:
$
  "Bel"(x_t) = p(x_t | z_1, dots, z_t, u_1, dots, u_(t)) = p(x_t | z_(1:t), u_(1:t)) \
  "where" x_t "is the state of the world at time" t
$
The belief is a *probability distribution* over the state of the world, it is a function that maps each possible state of the world ($x_T$) to a probability:
- if $x$ is a continuous variable, the belief is a *probability density function* (PDF)
- if $x$ is a discrete variable, the belief is a *probability mass function* (PMF)




#warning()[
  The order of the measurements and the control actions does not matter, we can change the order of the measurements and the control actions without changing the belief.
]


#example()[
  Suppose that we have a robot with a camera that can look at a plant and determine whether the plant is healthy or not. \
  The state of the world $X$ is a *binary variable* that can take two values: $0$ (healthy plant) and $1$ (diseased plant). The robot needs to estimate the probability that the plant is healthy given the measurements that it has made:

  - The robot take multiple measurements of the plant, for example by looking at the plant from different angles. The measurements are denoted as $z_1, z_2, z_3, dots, z_n$.

  - We want to compute the probability that the plant is healthy given the measurements: $"Bel"(X)$ (if we have set $x = 1$, we see a diseased plant):
  $
    "Bel"(x) &= p(x|mb(z_1), mb(z_2), mb(z_3), dots, mr(z_t)) \
    &= (p(mr(z_t) | x, mb(z_1), dots, mb(z_(t-1))) dot p(x | mb(z_1), dots, mb(z_(t-1)))) / p(mr(z_t) | mb(z_1), dots, mb(z_(t-1)))
  $
  The $mb("blue")$ measurements are background knowledge: they are the measurements that we have already seen, while the $mr("red")$ measurement is the new measurement that we have just seen.\
  $p(x | z_1, dots, z_(t-1))$ is what we believe about the plant *before* the last measurement *$z_t$*. It is a sort of recursive definition of the belief.
  #note()[
    I can correct the previous belief about the plant by using the new measurement $z_t$ and the bayes theorem.
  ]

  We can't use the mean of the distribution because we don't take into account the proprieties of the sensor (False positivi and false negative rate). Also, with the avarege of the observation we don't consider the context of the experiment (*the prior*). It's something i know before taking the measurment.


]

== Markov assumption

In the previous example, we can ask ourselves on what does $z_t$  depend on. If we assume the *Markov assumption*, we can say that $z_t$ *depends only on the current state of the world* $x_t$ and not on the previous measurements $z_1, dots, z_(t-1)$ and actions. Formally, in the previous example, we can compute the belief as:
$
  "Bel"(x) & = p(x|mb(z_1), mb(z_2), mb(z_3), dots, mr(z_t)) \
           & = (p(mr(z_t) | x) dot p(x | mb(z_1), dots, mb(z_(t-1)))) / p(mr(z_t) | mb(z_1), dots, mb(z_(t-1)))
$

#informally()[
  This means that the present state $x_t$ is a *complete summary of the past measurements and control actions*, so we can ignore the past measurements and control actions when we want to compute the belief at time $t$.
]



In the formula we assume the Markov assumption. As we can see there is a distinction if the dependency with the past measurements its valid or not:

- If the state of the world *$x$* is *known*, then the past measurements $z_1, dots, z_(t-1)$ do not give us any information about the new measurement $z_t$; $z_t$ is *indipendent* of the past measurements $z_1, dots, z_(t-1)$.\
  example: _Knowing what a sensors saw a minute ago dosen't help us to predict the current reading if we already know the state of the plant_.


- If the state of the world *$x$* is *unknown*, then the past measurements $z_1, dots, z_(t-1)$ give us some information about the new measurement $z_t$; $z_t$ is *depends* on the past measurements $z_1, dots, z_(t-1)$. \
  example: _Knowing what a sensors saw a minute ago helps us to predict the current reading if we don't know the state of the plant._


#note()[
  Under the Markov assumption, past and present measurements are *conditionally independent* given the current state of the world. This means that if we know the current state of the world, then knowing the past measurements does not give us any information about the new measurement, and vice versa.

  if the markov assumption does *not hold* we can say that:
  $
    p(z_t) != p(z_t | z_1, dots, z_(t-1))
  $
]


== Recursive Bayes filter

Given the formula of the belief at time $t$:
$
  p(x| z_1, dots, z_t) = (p(z_t | x) dot mb(p(x | z_1, dots, z_(t-1))) / p(z_t | z_1, dots, z_(t-1))
$
we can see that the $mb("blue")$ part is the belief that we have computed at time $t-1$:
$
  (p(z_(t-1)| x) mr(p(x | z_1, dots, z_(t-2)))) / p(z_(t-1) | z_1, dots, z_(t-2))
$
where the $mr("red")$ part is the belief at time $t-2$. We can recursively substitute the belief at time $t-1$ with the belief at time $t-2$, and so on, until we reach the belief at time $0$ that is the *prior* belief $mr(p(x))$; the initial belief without any measurements:
$
  (p(z_1| x)mr(p(x))) / p(z_1)
$
$p(x)$ the belief without no measurements.

By substiution we can write the formula of the belief at time $t$ as:
$
  p(x| z_1, dots, z_t) = mg(eta_(1 dots t)) product_(t=1)^z mr(p(z_i|x))mb(p(x))
$
where:
- $mb(p(x))$ is the *prior* about $x$. The probability of the state being $x$ before taking any measurements.

- $mr(p(z_i|x))$ is the *likelihood* of the measurements given the state $x$. The probability of getting the measurements $z_i$ if the state is $x$.

- $mg(eta_(1 dots t))$ is a *normalization factor* that ensures that the belief is a valid probability distribution (i.e., it sums to 1 over all possible states $x$).

We can apply the recurisve Bayes filter to a sensor to estiamate some properties of it. Suppose that we have a binary sensor: the state can only be $0$ or $1$:
- Suppose $x = 0$ so the plant is healthy:
  - $p(z_t = 1 | 0)$ = *false positive rate*
  - $p(z_t = 0 | 0)$ = *true negative rate*
- Suppose $x = 1$ so the plant is diseased:
  - $p(z_t = 1 | 1)$ = *true positive rate*
  - $p(z_t = 0 | 1)$ = *false negative rate*

If te true state of the plant is $1$ we use the true positive and false negative.:
$
  p(1| z_1, dots, z_t) = mu_(1 dots t) product_(t=1)^z mr(p(z_t|1)p(1))\
  p(0| z_1, dots, z_t) = mu_(1 dots t) product_(t=1)^z mr(p(z_t|0)p(0))
$

#example()[
  Suppose a robot wich has a sensor that can detect if a patient is healthy or not. The state can be:
  - $x = 0$ (healthy patient)
  - $x = 1$ (sick patient)
  We want to predict the real state of the patien given the measurement of the sensor. Especially, we want to compute the belief that the patient is sick.

  The initial condition (prior) is that the patient is sick with probability $0.9 = 90%$. The sensor is not perfect, so we need to take into account its properties:
  - *TPR* (true positive rate). The probability that the sensor reports that the patient is sick when the patient is really sick.

  - *TNR* (true negative rate). The probability that the sensor reports that the patient is healthy when the patient is really healthy.

  Based on these properties we can have different scenarios:

  - $"TRP" = 0, "TNR" = 0$: The sensor is always wrong. In this case we can *invert the sensor readings* to get the correct belief, by *obteining a perfect sensor*.

  - $"TPR" = 0.99, "TNR" = 0.5$: The sensor is very good at detecting sick patients, but it has a random behaivor when the patient is healthy:
    - If the patient is really sick, the sensor is always correct, so the belief that the patient is sick is always $1$.
    - If the patient is really healthy, the sensor is correct only $50%$ of the time, the *algorithm will recognize a random sequence*, so the belief decreases over time, reaching $0$ after some measurements.

  - $"TPR" = 0.6, "TNR" = 0.6$. The sensor is not very good, but it is better than random.  In this case the algorithm has a very *slow convergence*, and it takes a lot of measurements to reach a belief close to $0$ or $1$.

  - $"TPR" = 0.5, "TNR" = 0.5$. The sensor is random, it has no information about the state of the patient. In this case *the belief does not change over time*, it remains constant at $0.9$.
]


