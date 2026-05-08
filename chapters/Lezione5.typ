#import "../template.typ": *

= Bayes Filter

== Probability Basics

We can define the probability of an event $A$ as a number between $0$ and $1$: $0 <= P(A) <= 1$. It measures the *likelihood* of the event happening.

- *Joint probability*: $P(A,B)$, it is the probability of events $A$ and $B$ happening together.
- *Union probability*: $P(A or B)$ = P(A) + P(B) - P(A,B). At least one among $A$ and $B$ happens.
- *Negation*: $P(not A) = 1 - P(A)$

#note()[
  The events $A$ and $B$ are *independent* if:
  $
    P(A,B) = P(A)P(B)
  $
  Having information about one of the two events does not change the probability of the other one.
]

A random variable $X$ is a variable whose value is not determined by the outcome of a random event. It can be *discrete* or *continuous*.

- *discrete*: in this case, the values that the variable can take are countable, and they belong to a limited set:
  $
    X in {x_1, x_2, dots, x_n}
  $
  $P(x_i)$ is the probability that the variable takes the value $x_i$.
  $P(dot)$ is the probability mass function (PMF) of the variable; it is a function that maps each value of the variable to its probability:
  $
    P: X -> [0,1], sum_(i=1)^n P(x_i) = 1
  $
  #warning()[
    The sum of the probabilities of all the possible values of a discrete random variable *must be equal to $1$*, because one of the values must happen.
  ]

- *continuous*: in this case, the values that the variable can take are uncountable; they form an infinite set:
  $
    X in R "(or any continuous set)"
  $
  $p(x)$ is called the *probability density function* (PDF) of the variable. It's *not a probability* but a density, it can take values greater than 1:
  $
    P: (a <= X <= b) -> integral_(a)^(b) p(x) d x
  $

=== Conditional probability

$P(A|B)$ is the probability of A given B, it is defined as:
$
  P(A|B) = P(A,B)/P(B)
$
If $A$ and $B$ are independent, then $P(A|B) = P(A)$.

=== Marginal probability
The marginal probability is the probability of an event $A$, without any condition on other events. By changing one variable while keeping the other fixed, we can get the marginal probability of the variable we are changing.

Discrete case:
- $P(X) = sum_y P(X,Y)$
- $P(X) = sum_y P(X | Y)P(Y)$

Continuous case:
- $P(X) = integral P(X,Y) d y$
- $P(X) = integral P(X | Y)P(Y) d y$

//todo add example of marginal probability
#example()[
  In this example, the probability of a door and no detection is a false negative, while the probability of no door and detection is a false positive.

  In this case, the sensor is not very good.
]

=== Conditional independence

Imagine that we have two events $A$ and $B$, and a third event $E$. We say that $A$ and $B$ are *conditionally independent* given $E$ (evidence) iff the evidence $E$ explains both $A$ and $B$. If I know $E$, then knowing $A$ does not give me any information about $B$, and vice versa. In this case, we can say that $E$ *d-separates* $A$ and $B$.

#informally()[
  It means that $E$ perfectly explains the correlation between $A$ and $B$: if we know $E$, then knowing $A$ does not give us any information about $B$, and vice versa.
]

#example()[
  Suppose that a robot has a lidar. Consider two measurements $z_1$ and $z_2$, and let $x$ be the distance to an obstacle.

  - Imagine that $x$ is unknown. Does knowing $z_1$ give us any information about $z_2$? Yes, because if we know that $z_1$ is very small, then we can infer that $x$ is very small and therefore $z_2$ is also very small (we can place a bet on $z_2$, saying that it is also small). In this case, $z_1$ and $z_2$ are not independent.

  - If we already know the position of the obstacle $x$, then knowing $z_1$ does not give us any information about $z_2$, and vice versa. In this case, $z_1$ and $z_2$ are conditionally independent given $x$. In this case, I can precompute the probability of the distance of the obstacle given the measurements of the two sensors.

  #note()[
    $z$'s are effects and $x$ is the cause. If I already know the cause, then the first effect does not give me any information about the second effect, and vice versa.
  ]
]

Formally:
$
  P(A|E) = P(A|E,B) "and" P(B|E) = P(B | E,A)
$
This means that if we know $E$, then knowing $B$ does not give us any information about $A$, and vice versa.

#note()[
  $
    P(A,E) = P(A|E)P(E) = P(E|A)P(A)
  $
]

Bayes' theorem says:
#theorem()[
  $
    P(A|E) = (P(E|A)P(A)) / P(E)
  $
]

Event $E$ is something reported by the sensor, while $A$ is the state of the world that we want to estimate.

$P(A|E)$ is the probability that there is an obstacle in front of the sensor, given the evidence that the sensor has reported. It is called the *posterior* probability; it is our belief about the state of the world after seeing the evidence.\
*Bayes' theorem* allows us to compute it in a beautiful way.

Suppose that $A$ is the cause, while $E$ is the effect (the evidence that the sensor has reported). For $P(A|E)$, given the evidence $E$, we want to calculate the probability of the cause:
$
  mr(P(A|E)) = (mg(P(E|A))P(A)) / P(E)
$
where:
- $mr(P(A|E))$ is a *diagnostic* question about the cause given the effect; it is the probability of the cause given the evidence.
- $mg(P(E|A))$ is a *generative* question about the effect given the cause, it is the probability of the evidence given the cause.

#note()[
  The most difficult question is the first one. The theorem says that I can compute the probability of the difficult question (diagnostic) by using the probability of the easy question (generative) and the prior probability of the cause.
]

Analyzing the right part of the formula:
- $mg(P(E|A))$: it is the *likelihood* of the evidence given the cause; it is the probability that the sensor reports $E$ given that the state of the world is $A$. It is a generative question, and it is easy to answer because we can do experiments and collect data to estimate this probability.

  #note()[
    It's a *feature of the sensor*, it is a property of the sensor that we can estimate by doing a lot of experiments and collecting data.
  ]

- $P(A)$: it is the *prior* probability of the cause; it is our belief about the state of the world before seeing the evidence.
  #note()[
    This probability is what the robot thinks about the state of the world *before doing any measurement*; it is the belief of the robot about the state of the world before seeing any evidence.

    For example, if we have a robot that infers $P(A)=1$, it is very _optimistic_; it thinks that the state of the world is always $A$. If we have a robot that infers $P(A)=0$, it is very _pessimistic_; it thinks that the state of the world is never $A$.

    The worst case is when we have a robot that infers $P(A)=0.5$; it is very _uncertain_, and it thinks that the state of the world is $A$ with probability $0.5$ and not $A$ with probability $0.5$.
  ]

  It is a diagnostic question, it is difficult to answer because we don't have any information about the state of the world.

  #informally()[
    We can see the probability $P(A)$ as a bias that the robot has about the state of the world.
  ]

- $P(A|E)$: it's the *posterior* probability of the cause given the evidence, it is our belief about the state of the world *after taking the data into account*.

- $P(E)$: it's the *marginal* probability of the evidence, it is the probability that the sensor reports $E$ regardless of the state of the world. It is a normalizing constant, it is used to make sure that the posterior probability is a valid probability distribution.

  It can be computed by:
  $
    P(E) = sum_A P(E|A)P(A)
  $
  #example()[
    $P(E)$ is the probability of measuring 1 meter ($E$) independently of the state of the world.
  ]
  #note()[
    A very low $P(E)$ is a critical warning  that your sensor data contradict your entire model.
  ]

Bayes' theorem can also accommodate *background knowledge*; _for example_, if we have a robot that has a map of the environment, we can use the map as background knowledge to compute the posterior probability of the state of the world given the evidence. Formally:
$
  P(A| E, mb(Z)) = (P(E|A,mb(Z))P(A|mb(Z))) / P(E|mb(Z))
$

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

