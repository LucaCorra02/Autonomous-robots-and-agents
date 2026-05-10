#import "../template.typ": *

= Bayes Filter

== Probability Basics

We can define the probability of an event $A$ as a number between $0$ and $1$: $0 <= P(A) <= 1$. It measures the *likelihood* of the event happening.

- *Joint probability*: $P(A,B)$, it is the probability of events $A$ and $B$ happening together.
- *Union probability*: $P(A or B) = P(A) + P(B) - P(A,B)$. At least one among $A$ and $B$ happens.
- *Negation*: $P(not A) = 1 - P(A)$

#note()[
  The events $A$ and $B$ are *independent* if:
  $
    P(A,B) = P(A)P(B)
  $
  Having information about one of the two events does not change the probability of the other one.
]

=== Random variables

A random variable $X$ is a variable whose *value is not determined* by the outcome of a random event. It can be *discrete* or *continuous*.

- *Discrete*: in this case, the values that the variable can take are countable, and they belong to a limited set:
  $
    X in {x_1, x_2, dots, x_n}
  $
  - $P(x_i)$ is the probability that the variable $X$ takes the value $x_i$.
  - $P(dot)$ is the *probability mass function* (PMF) of the variable; it is a function that maps each value of the variable to its probability:
  $
    P: X -> [0,1], sum_(i=1)^n P(x_i) = 1
  $
  #warning()[
    The sum of the probabilities of all the possible values of a discrete random variable *must be equal to $1$*, because one of the values must happen.
  ]

- *Continuous*: in this case, the values that the variable can take are uncountable; they form an infinite set:
  $
    X in R "(or any continuous set)"
  $
  $p(x)$ is called the *probability density function* (PDF) of the variable, it's *not a probability* but a density (it can take values greater than 1):
  $
    P: (a <= X <= b) -> integral_(a)^(b) p(x) d x
  $

  #note()[
    The density function $p(x)$ should be integrable and the integral of the density function over the entire space should be equal to $1$:
    $
      integral p(x) d x = 1
    $
  ]

=== Conditional probability

$P(A|E)$ is the probability of $A$ given $E$, it is defined as:
$
  P(A|E) = P(A,E)/P(E)
$
If $A$ and $E$ are *independent events*, then $P(A|E) = P(E)$.

=== Marginal probability
The marginal probability is the probability of one variable irrespective (without considering) of the value of the other. By changing one variable while keeping the other fixed, we can get the *marginal probability* of the variable we are changing:

- *Discrete case*:
  - $P(X) = sum_y P(X,Y)$
  - $P(X) = sum_y P(X | Y)P(Y)$

- *Continuous case*:
  - $p(x) = integral p(x,y) d y$
  - $p(x) = integral p(x | y)P(y) d y$

#example()[
  Suppose that we have a binary sensor that detects whether there is a door in front of it or not. The proprieties of the sensor are:

  #table(
    columns: 4,
    [*-*], [$e_1$ (door detected)], [$e_2$ (no door detected)], [Marginals],
    [$a_1$ (at door)], [0.08 = TP], [0.02 = FN], [$p(a_1) = sum_E P(a_1, E) = 0.1$],
    [$a_2$ (not at door)], [0.09 = FP], [0.81 = TN], [$p_(a_2) = sum_E P(a_2, E) = 0.9$],
    [Marginals], [$p(e_1) = sum_A P(A, e_1) = 0.17$], [$p(e_2) = sum_A P(A, e_2) = 0.83$], [1],
  )
  The sensor can make two types of errors:
  - it can report a door when there is no door (*false positive*)
  - it can report no door when there is a door (*false negative*).

  In this case, the sensor is not very good.
]

=== Conditional independence

Imagine that we have two events $A$ and $B$, and a third event $E$.\
We say that $A$ and $B$ are *conditionally independent* given $E$ (*evidence*) iff the evidence $E$ explains both $A$ and $B$. If I know $E$, then knowing $A$ does not give me any information about $B$, and vice versa. In this case, we can say that $E$ *d-separates* $A$ and $B$.

#informally()[
  It means that *$E$* perfectly *explains the correlation between $A$ and $B$*: if we know $E$, then knowing $A$ does not give us any information about $B$, and vice versa.
]

Formally:
$
  P(A|E) = P(A | E,B) "" \
  "and"\
  P(B|E) = P(B | E,A)
$
Knowing $E$ and also $B$ does not give us any information about $A$ and vice versa.

#example()[
  Suppose that a robot has a lidar (it's like a sonar). Consider two measurements $z_1$ and $z_2$, and let $x$ be the distance to an obstacle.

  - Imagine that *$x$ is unknown*. Does knowing $z_1$ give us any information about $z_2$? $mg("Yes")$, because if we know that $z_1$ is very small, then we can *infer* that the obstacle $x$ is nearby. Therefore the next measurement $z_2$ it will maybe be also very small (we can place a bet on $z_2$, saying that it is also small). In this case, *$z_1$ and $z_2$ are not independent*.

  - If we *already know* the position of the *obstacle $x$*, then knowing $z_1$ does not give us any information about $z_2$, and vice versa. In this case, *$z_1$ and $z_2$ are conditionally independent given $x$*. In this case.\
    We can precompute the probability of the distance of the obstacle given the measurements of the two sensors.

  #note()[
    $z$'s are *effects* and $x$ is the *cause*. If I already know the cause, then the first effect does not give me any information about the second effect, and vice versa.

    For example, if we already know that the patient has a fever (cause) and a cough (effect), then knowing that the patient has also a headache (effect) does not give us any information about the cough, and vice versa. In this case, the fever is the cause that explains both the cough and the headache, and the cough and the headache are conditionally independent given the fever.
  ]
]


#note()[
  In the case of conditional independence, we can simplify the joint probability of $A$ and $B$ given $E$:
  $
    P(A,E) = P(A|E)P(E) = P(E|A)P(A)
  $
]





== Bayes' theorem

Suppose that we have a robot with a sensor that can detect an obstacle in front of it. Suppose that the events:
- $A$: there is an obstacle in front of the robot. The *state of the world* that we want to estimate.
- $E$: the sensor reports the presence of an obstacle ahead

Formally, we want to compute *$P(A|E)$*, the probability that there is an obstacle in front of the robot given the evidence that the sensor has reported. This probability is called the *$mr("posterior")$* probability: It is our *belief about the state of the world* after seeing the evidence.\
Bayes' theorem allows us to compute it in a beautiful way:

#theorem()[
  $
    mr(P(A|E)) = (mg(P(E|A))P(A)) / P(E)
  $
  where:
  - $mr(P(A|E))$ is a *diagnostic* question about the cause given the effect; It is the probability of the cause given the effects.

  - $mg(P(E|A))$ is a *casual* question about the effect given the cause; It is the probability of the effects given the cause.

  The most difficult question is the first one
]

#informally()[
  The Bayes theorem says that we can compute the probability of the difficult question (diagnostic) by using the probability of the easy question (generative) and the *prior probability* of the cause.
]

Analyzing the right part of the formula:
- $mg(P(E|A))$: it is the *likelihood* of the evidence given the cause; it is the probability that the sensor reports $E$ given my assumptions about the state of the world $A$. It is a *generative question*, and it is easy to answer.

  #note()[
    It's a *feature of the sensor* that we can estimate by doing a lot of experiments and collecting data.
  ]

- $P(A)$: it is the *prior* probability of the cause; it is our *belief* about the state of the world *before* seeing the evidence. It is a *diagnostic* question, it is difficult to answer because we don't have any information about the state of the world.

  #note()[
    This probability is what the robot thinks about the state of the world *before doing any measurement*.

    For example, if we have a robot that infers $P(A)=1$, it is very _optimistic_. If we have a robot that infers $P(A)=0$, it is very _pessimistic_.

    The worst case is when we have a robot that infers $P(A)=0.5$; it is very _uncertain_, and it thinks that the state of the world is $A$ with probability $0.5$ and not $A$ with probability $0.5$.
  ]



  #informally()[
    We can see the probability $P(A)$ as a bias that the robot has about the state of the world.
  ]

- $mr(P(A|E))$: it's the *posterior* probability of the cause given the evidence, it is our belief about the state of the world *after taking the data into account*.

- $P(E)$: it's the *marginal* probability of the evidence. It is the probability that the sensor reports $E$ *regardless of the state of the world*. It is a normalizing constant, it is used to make sure that the posterior probability is a valid probability distribution.

  It can be computed by:
  $
    P(E) = sum_A P(E|A)P(A)
  $
  Probability of observing this specific sensor data ($E$) across all possible states.
  #example()[
    $P(E)$ is the probability of measuring 1 meter ($E$) independently of the state of the world.
  ]
  #note()[
    A very low $P(E)$ is a critical warning  that your sensor data contradict your entire model.
  ]

Bayes' theorem can also accommodate *background knowledge* $mb(Z)$; _for example_: if we have a robot that has a map of the environment, we can use the map as background knowledge to compute the posterior probability of the state of the world given the evidence. Formally:
$
  P(A| E, mb(Z)) = (P(E|A,mb(Z))P(A|mb(Z))) / P(E|mb(Z))
$

=== Robotic perspective

Usually a state $x$ encodes some features of the robot or of the environment we want to reason about. A state can be static or dynamic, fully observable or partially observable, discrete or continuous, $dots$.

In mobile robotics one common state is the *$mr("pose")$* of the robot:
$
  p = <(hat(x), hat(y)), theta>
$
it encodes the position on the plane with respect to some fixed frame of reference and the orientation $theta$







#example()[
  The robot has a camera. The robot needs to look more closely at a plant and determine whether the plant is healthy or not (it is like a binary sensor).

  I make multiple observations (I can look at the plant from different angles). The measurements are:
  $
    z_1,z_2,z_3, dots, z_n
  $
  We want the probability that the plant is healthy given the measurements: $"Bel"(X)$
  If I set $x = 1$, I see a diseased plant; if I set $x = 0$, I see a healthy plant. I want to compute:
  $
    P(x|mb(z_1), mb(z_2), mb(z_3), dots, mr(z_t)) = p(z_t | x, z_1, dots, z_(t-1)) dot p(x | z_1, dots, z_(t-1)) / p(z_t | z_1, dots, z_(t-1))
  $
  The blue measurements are background knowledge: they are the measurements that we have already seen, while the red measurement is the new measurement that we have just seen.

  $p(x | z_1, dots, z_(t-1))$ is what I believe about the plant before the last measurement $z_t$; it is a sort of recursive definition of the belief.

  #note()[
    I can correct the previous belief about the plant by using the new measurement $z_t$ and the bayes theorem.
  ]

  #warning()[
    In this example, I cannot simplify $z_t$ when the state $x$ is changing from the measurements that I made.
  ]
]

=== Markov assumption

In the previous example, this means that in $p(z_t|x,z_1, dots, z_(t-1))$, the measurements $z_1,dots,z_(t-1)$ do not give us any information about the new measurement $z_t$ *once we know the state of the world $x$*. This is called the *Markov assumption*.

#warning()[
  In the case of $p(z_t | z_1, dots, z_(t-1))$, *I cannot simplify because I do not have $x$*. These measurements tell me something about the new measurement $z_t$ because they are all measurements and they are all correlated.
]


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

    // small beta angle wedge at robot center (green)
    let a1 = theta
    let a2 = theta
    let ar1 = (cx + 1.32 * calc.cos(a1), cy + 0.32 * calc.sin(a1))
    let ar2 = (cx + 0.32 * calc.cos(a2), cy + 1.32 * calc.sin(a2))
    line((cx, cy), ar1, stroke: rgb("8fcf9d") + 1pt, fill: rgb("8fcf9d"))
    line((cx, cy), ar2, stroke: rgb("8fcf9d") + 1pt, fill: rgb("8fcf9d"))
    line(ar1, ar2, stroke: rgb("8fcf9d") + 1pt, fill: rgb("8fcf9d"))

    // axis labels
    content((1.75, -0.3), $hat(x)$, font: ("New Computer Modern", 10pt))
    content((-0.22, 1.25), $hat(y)$, font: ("New Computer Modern", 10pt))
  }),
  caption: "Robot pose (schematic)",
)

