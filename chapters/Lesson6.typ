#import "../template.typ": *

=== Robotic Perspective

Usually a state $x$ encodes some features of the robot or of the environment we want to reason about. A state can be static or dynamic, fully observable or partially observable, discrete or continuous, $dots$.

In mobile robotics one common state is the *$mr("pose")$* of the robot:
$
  p = chevron.l (hat(x), hat(y)), theta chevron.r
$
It encodes the position on the plane with respect to some fixed frame of reference and the orientation $theta$.

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

The robot can exchange information with the environment:
- *From the environment to the robot*: sensor measurements $z$ typically do *not modify* the environment; they acquire information and reduce the uncertainty about the state of the world.

- *From the robot to the environment*: *control actions* $u$ typically *modify* the environment (the robot physically acts in the environment); they change the state of the world and increase the uncertainty about the state of the world.

The robot needs to *estimate* the state of the world $X$ by using the sensor measurements $z$ and the control actions $u$. This is called a *belief* about the state of the world, and it is denoted as $"Bel"(x_t)$:
$
  "Bel"(x_t) = p(x_t | z_1, dots, z_t, u_1, dots, u_t) = p(x_t | z_(1:t), u_(1:t)) \
  "where" x_t "is the state of the world at time" t
$
The belief is a *probability distribution* over the state of the world. It is a function that maps each possible state of the world ($x_t$) to a probability:
- if $x$ is a continuous variable, the belief is a *probability density function* (PDF)
- if $x$ is a discrete variable, the belief is a *probability mass function* (PMF)

#warning()[
  The order of the measurements and the control actions does not matter. We can change the sequence of the specific measurements $z_i$ without changing the final belief.
]

#example()[
  Suppose that we have a robot with a camera that can look at a plant and determine whether the plant is healthy or not. \
  The state of the world $X$ is a *binary variable* that can take two values: $0$ (healthy plant) and $1$ (diseased plant). The robot needs to estimate the probability that the plant is healthy given the measurements that it has made:

  - The robot takes multiple measurements of the plant, for example by looking at it from different angles. The measurements are denoted as $z_1, z_2, z_3, dots, z_t$.

  - We want to compute the probability that the plant is diseased given the measurements, $"Bel"(x)$:
  $
    "Bel"(x) &= p(x|mb(z_1), mb(z_2), mb(z_3), dots, mr(z_t)) \
    &= (p(mr(z_t) | x, mb(z_1), dots, mb(z_(t-1))) dot p(x | mb(z_1), dots, mb(z_(t-1)))) / p(mr(z_t) | mb(z_1), dots, mb(z_(t-1)))
  $
  The $mb("blue")$ measurements act as background knowledge: they are the past measurements that we have already seen, while the $mr("red")$ measurement is the new measurement that we have just acquired.\
  $p(x | z_1, dots, z_(t-1))$ is what we believe about the plant *before* the last measurement *$z_t$*. It is a sort of recursive definition of the belief.
  #note()[
    I can correct the previous belief about the plant by using the new measurement $z_t$ and Bayes' theorem.
  ]

  We can't just use a simple average of the measurements because that wouldn't account for the specific properties of the sensor (like false positive and false negative rates). Furthermore, a simple average ignores our *prior* knowledge (the context we knew before taking any measurements).
]

== The Markov Assumption

In the previous example, we can ask ourselves what $z_t$ depends on. If we apply the *Markov assumption*, we can say that $z_t$ *depends only on the current state of the world* $x_t$, and not on the previous measurements $z_1, dots, z_(t-1)$ or actions. Formally, we can compute the belief as:
$
  "Bel"(x) & = p(x|mb(z_1), mb(z_2), mb(z_3), dots, mr(z_t)) \
           & = (p(mr(z_t) | x) dot p(x | mb(z_1), dots, mb(z_(t-1)))) / p(mr(z_t) | mb(z_1), dots, mb(z_(t-1)))
$

#informally()[
  This means that the present state $x_t$ is a *complete summary of the past measurements and control actions*, so we can ignore the past history when we evaluate the likelihood of the new reading.
]

Does $z_t$ depend on $z_(1:t-1)$? The answer depends on whether we know the true state:

- If the state of the world *$x$* is *known*, then the past measurements $z_1, dots, z_(t-1)$ do not give us any new information about $z_t$. $z_t$ is *independent* of the past measurements.\
  _Example: Knowing what the sensor saw a minute ago doesn't help us predict the current reading if we already know with absolute certainty whether the plant is diseased or not._

- If the state of the world *$x$* is *unknown*, then the past measurements $z_1, dots, z_(t-1)$ give us some information about the new measurement $z_t$; $z_t$ *depends* on the past measurements.\
  _Example: Past measurements tell you something about the plant's true state, which in turn tells you something about what the sensor should measure now._

#note()[
  Under the Markov assumption, past and present measurements are *conditionally independent* given the current state of the world. 

  If the Markov assumption does *not hold*, then:
  $
    p(z_t | x) != p(z_t | x, z_1, dots, z_(t-1))
  $
]

== Recursive Bayes Filter

Given the formula of the belief at time $t$:
$
  p(x| z_1, dots, z_t) = (p(z_t | x) dot mb(p(x | z_1, dots, z_(t-1)))) / p(z_t | z_1, dots, z_(t-1))
$
we can see that the $mb("blue")$ part is exactly the belief that we computed at time $t-1$:
$
  (p(z_(t-1)| x) mr(p(x | z_1, dots, z_(t-2)))) / p(z_(t-1) | z_1, dots, z_(t-2))
$
where the $mr("red")$ part is the belief at time $t-2$. We can recursively substitute the belief at time $t-1$ with the belief at time $t-2$, and so on, until we reach the belief at time $0$, which is the *prior* belief $mb(p(x))$ (the initial belief without any measurements).

By substitution, we can write the formula of the belief at time $t$ as:
$
  p(x| z_1, dots, z_t) = mg(eta_(1 dots t)) product_(i=1)^t mr(p(z_i|x)) mb(p(x))
$
where:
- $mb(p(x))$ is the *prior* about $x$. The probability of the state being $x$ before taking any measurements.
- $mr(p(z_i|x))$ is the *likelihood* of the measurements given the state $x$. The probability of getting the measurement $z_i$ if the state is $x$.
- $mg(eta_(1 dots t))$ is a *normalization factor* that ensures that the posterior belief is a valid probability distribution (i.e., it sums or integrates to 1 over all possible states $x$).

We can apply the recursive Bayes filter to a binary sensor to estimate its behavior. Suppose the state can only be $0$ (healthy) or $1$ (diseased):
- Suppose $x = 0$ (healthy plant):
  - $p(z_t = 1 | 0)$ = *false positive rate* (FPR)
  - $p(z_t = 0 | 0)$ = *true negative rate* (TNR)
- Suppose $x = 1$ (diseased plant):
  - $p(z_t = 1 | 1)$ = *true positive rate* (TPR)
  - $p(z_t = 0 | 1)$ = *false negative rate* (FNR)

We can compute the recursive probabilities for both cases:
$
  p(1| z_1, dots, z_t) &= eta_(1 dots t) product_(i=1)^t mr(p(z_i|1)) p(1) \
  p(0| z_1, dots, z_t) &= eta_(1 dots t) product_(i=1)^t mr(p(z_i|0)) p(0)
$

#example()[
  Suppose a robot has a sensor that can detect if a patient is healthy or not. The state can be:
  - $x = 0$ (healthy patient)
  - $x = 1$ (sick patient)
  We want to predict the real state of the patient given the measurements of the sensor. Especially, we want to compute the belief that the patient is sick over time.

  The initial condition (prior) is that the patient is sick with probability $0.9$ ($90%$). The sensor is not perfect, so we need to take into account its properties:
  - *TPR* (true positive rate): The probability that the sensor reports that the patient is sick when the patient is really sick.
  - *TNR* (true negative rate): The probability that the sensor reports that the patient is healthy when the patient is really healthy.

  Based on these properties we can have different scenarios:

  - $"TPR" = 0, "TNR" = 0$: The sensor is a "perfect liar". In this case, we can *reverse the sensor readings* to get the correct belief, obtaining a perfect sensor.

  - $"TPR" = 0.99, "TNR" = 0.5$: The sensor is very reliable at detecting sick patients, but it has a random behavior when the patient is healthy:
    - If the patient is really sick ($x=1$), the sensor is basically always correct, so the belief quickly converges to $1$.
    - If the patient is really healthy ($x=0$), the sensor is correct only $50%$ of the time. The filter will recognize the asymmetry in the sensor's performance (seeing roughly equal amounts of 0s and 1s), realize this matches the uniform distribution expected for healthy patients, and the belief will drop to $0$ after a sufficient number of measurements.

  - $"TPR" = 0.6, "TNR" = 0.6$ (with strong wrong prior): The sensor is not very good, but it is better than random. In this case, the algorithm has a very *slow convergence*, and it takes a lot of measurements to overcome the strong initial bias.

  - $"TPR" = 0.5, "TNR" = 0.5$: The sensor is completely blind; any reading is a random guess. In this case, *the belief does not change over time*; it remains constant at the prior ($0.9$).
]