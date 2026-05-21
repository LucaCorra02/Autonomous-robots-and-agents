#import "../template.typ": *

= Bayes Filter

== Probability Basics

We can define the probability of an event $A$ as a number between $0$ and $1$: $0 <= P(A) <= 1$. It measures the *likelihood* of the event happening.

- *Joint probability*: $P(A,B)$, it is the probability of events $A$ and $B$ happening together simultaneously.
- *Union probability*: $P(A "or" B) = P(A) + P(B) - P(A,B)$. At least one among $A$ and $B$ happens.
- *Negation*: $P(not A) = 1 - P(A)$, $A$ does not happen.

#note()[
  The events $A$ and $B$ are *independent* if:
  $
    P(A,B) = P(A)P(B)
  $
  Having information about one of the two events tells nothing about the other one.
]

=== Random Variables

A random variable $X$ is a variable whose *value is determined* by the outcome of a random event. It can be *discrete* or *continuous*.

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

- *Continuous*: in this case, the values that the variable can take are uncountable; they form an infinite continuous set:
  $
    X in R "(or any other continuous set of values)"
  $
  $p(x)$ is called the *probability density function* (PDF) of the variable at $x$. It's *not a probability* but a density (it can take values greater than 1). It is non-negative and integrable:
  $
    P(a <= X <= b) = integral_(a)^(b) p(x) d x
  $

  #note()[
    The integral of the density function over the entire space must be equal to $1$:
    $
      integral p(x) d x = 1
    $
  ]

=== Conditional Probability

$P(A|E)$ is the probability of $A$ given that we observed the evidence $E$. It is defined as:
$  P(A|E) = P(A,E)/P(E)$
In general, this also means $P(A,E) = P(A|E)P(E)$.

=== Marginal Probability
The marginal probability is the probability of one variable irrespective (without considering) of the value of the other. By summing or integrating over the variable we want to marginalize out, we can get the *marginal probability* of the variable we are keeping:

- *Discrete case*:
  - $P(X) = sum_y P(X,Y)$
  - $P(X) = sum_y P(X | Y)P(Y)$ (Law of Total Probability)

- *Continuous case*:
  - $p(x) = integral p(x,y) d y$
  - $p(x) = integral p(x | y)p(y) d y$ (Law of Total Probability)

#example()[
  Suppose that we have a binary sensor that detects whether there is a door in front of it or not. The properties of the sensor are:

  #table(
    columns: 4,
    [*-*], [$e_1$ (door detected)], [$e_2$ (no door detected)], [Marginals],
    [$a_1$ (at door)], [0.08 = TP], [0.02 = FN], [$P(a_1) = sum_E P(a_1, E) = 0.1$],
    [$a_2$ (not at door)], [0.09 = FP], [0.81 = TN], [$P(a_2) = sum_E P(a_2, E) = 0.9$],
    [Marginals], [$P(e_1) = sum_A P(A, e_1) = 0.17$], [$P(e_2) = sum_A P(A, e_2) = 0.83$], [1],
  )
  The sensor can make two types of errors:
  - it can report a door when there is no door (*false positive* / $0.09$)
  - it can report no door when there is a door (*false negative* / $0.02$).

  We can compute conditionals using these values:
  - $P(a_1 | e_1) = P(a_1, e_1) / P(e_1) = 0.08 / 0.17 = 0.4705$
  - $P(a_1 | e_2) = P(a_1, e_2) / P(e_2) = 0.02 / 0.83 = 0.024$
]

=== Conditional Independence

Imagine that we have two events $A$ and $B$, and a third event $E$.\
We say that $A$ and $B$ are *conditionally independent given $E$* iff the evidence $E$ explains both $A$ and $B$. If I know $E$, observing also $A$ adds nothing about $B$, and vice versa. 

#informally()[
  It means that *$E$* perfectly *explains the correlation between $A$ and $B$*: if we know $E$, then knowing $A$ does not give us any extra information about $B$, and vice versa. (In Bayesian networks, $E$ *d-separates* $A$ and $B$).
]

Formally:
$
  P(A|E) = P(A | E,B) \
  "and" \
  P(B|E) = P(B | E,A)
$Or, equivalently:$
  P(A,B | E) = P(A|E)P(B|E)
$

#example()[
  Suppose that a robot has a lidar (it's like a sonar). Consider two adjacent distance measurements $z_1$ and $z_2$, and let $x$ be the actual distance to the obstacle.

  - *Case 1*: *$x$ is unknown*. Does knowing $z_1$ give us any information about $z_2$? $mg("Yes")$, because if we know that $z_1$ is very small, then we can *infer* that the obstacle $x$ is nearby. Therefore, the next measurement $z_2$ will likely also be very small. In this case, *$z_1$ and $z_2$ are NOT independent*.

  - *Case 2*: *$x$ is known*. Does knowing $z_1$ tell me something new about $z_2$? $mg("No")$. If we *already know* the exact position of the obstacle $x$, then the noise in measurement $z_1$ does not give us any information about the noise in measurement $z_2$. In this case, *$z_1$ and $z_2$ are conditionally independent given $x$*.

  #note()[
    The $z$'s are *effects* and $x$ is the *cause*. If I already know the cause, then the first effect does not give me any information about the second effect, and vice versa.

    For example, if we already know that the patient has a fever (cause) and a cough (effect), then knowing that the patient also has a headache (effect) does not give us any information about the cough. The fever is the cause that explains both.
  ]
]

#note()[
  In general, recalling the definition of conditional probability, we can write the joint probability of $A$ and $E$ as:
  $
    P(A,E) = P(A|E)P(E) = P(E|A)P(A)
  $
]

== Bayes' Theorem

Suppose a mobile robot is navigating in an open area, equipped with a cheap obstacle sensor. It must stop before hitting obstacles.
The robot's task: *my sensor just detected an obstacle, is the path blocked?*

Let's better formalize the problem:
- $A$: "I detect an obstacle in front of me that blocks my path" (The *state of the world* / cause).
- $E$: "The sensor reports the presence of an obstacle ahead" (The *evidence* / effect).

Formally, we want to compute *$P(A|E)$*, the probability that the path is actually blocked given the evidence that the sensor fired. 
Bayes' theorem provides a clever way to compute it:

#theorem()[
  $
    mr(P(A|E)) = (mg(P(E|A))P(A)) / P(E)
  $
  where:
  - $mr(P(A|E))$ is a *diagnostic* question. It poses a question about the *causes given the effects*. It is difficult to answer directly.

  - $mg(P(E|A))$ is a *causal* question. It poses a question about the *effects given the causes*. It is easier to answer.

  The Bayes theorem tells us that we can answer the difficult diagnostic question by answering the easier causal one!
]

Analyzing the terms of the formula:
- $mg(P(E|A))$ is the *likelihood*: it tells how plausible what I observed is with respect to my assumptions about reality. If the path was actually blocked, how probable is it to have the sensor detecting it? 
  #note()[
    It's a *feature of the sensor*; it comes with it! We can estimate it by doing experiments and collecting data.
  ]

- $P(A)$ is the *prior*: what I believe about $A$ *before* using my sensor. It is a diagnostic question, it is difficult to answer because we don't have any information about the state of the world.
  #note()[
    This probability is what the robot thinks about the state of the world *before doing any measurement*.

    For example, if we have a robot that infers $P(A)=1$, it is very _optimistic_. If we have a robot that infers $P(A)=0$, it is very _pessimistic_.

    The worst case is when we have a robot that infers $P(A)=0.5$; it is very _uncertain_, and it thinks that the state of the world is $A$ with probability $0.5$ and not $A$ with probability $0.5$.
  ]
  #informally()[
    We can see the probability $P(A)$ as a bias that the robot has about the state of the world.
  ]

- $mr(P(A|E))$ is the *posterior*: our updated belief about the state of the world *after* taking the evidence into account.

- $P(E)$ is the *evidence* (or marginal probability of the evidence). It is the probability that the sensor reports $E$ *regardless of the state of the world*. It is a normalizing constant used to make sure that the posterior probability is a valid probability distribution.
  
  It can be computed by:
  $
    P(E) = sum_A P(E|A)P(A)
  $
  Probability of observing this specific sensor data ($E$) across all possible states.
  #example()[
    $P(E)$ is the probability of measuring 1 meter ($E$) independently of the state of the world.
  ]
  #note()[
    A very low $P(E)$ is a critical warning that your sensor data contradicts your entire model.
    In practice, and for computational reasons, it is often handled simply as a normalization constant.
  ]

=== Background Knowledge

The Bayes theorem can also accommodate *background knowledge* $mb(Z)$. For example, if we have a robot that has a prior map of the environment, we can use the map as background knowledge $Z$ to compute the posterior probability:
$  P(A| E, mb(Z)) = (P(E|A,mb(Z))P(A|mb(Z))) / P(E|mb(Z))$