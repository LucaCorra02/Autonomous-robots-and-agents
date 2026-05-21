#import "../template.typ": *


When checking if a sensor is reliable, even if the True Negative Rate ($"TNR"$) is $0.5$, the system still gets to the true state using the Bayes/bias filter, just a bit slower. This shows how powerful the formula is.

#warning()[
  But there's a hard limit: the only time the formula can't help us is when both the $"TNR"$ and the True Positive Rate ($"TPR"$) are $0.5$. In this case, the sensor is just giving us random noise, so it's mathematically impossible to get anything useful out of it to improve our guess.
]

Luckily, real robots rarely use just one sensor. We can guess a value using multiple sensors at the same time, each with its own likelihood. The formula is the same, but we expand it to include all the sensors together.

= Modeling Control Actions

The standard Bayes filter works great for sensor measurements, but just looking at the world doesn't change it. To build a real robot, we need to update our math to include *control actions*, because when a robot does something, it changes the environment.

Since an action $u$ modifies the state of the system $x$, we have a totally different problem: we need to write down the math for how an action affects a state so we can add it to the Bayes filter.

#note()[
  This is super important because, just like the information collected by a measurement is uncertain, the physical effects that an action produces on the state are uncertain too.
  Actually, actions are even worse: differently from measurements, they *increase the uncertainty* about the state (e.g., because of mechanical noise like wheels slipping). Luckily, we can use conditional probability to model these actions too.
]

To describe the effect of taking an action $u$ on the state $x$, we could start by thinking of a *transition function* $f(x, u)$. This function takes the current state $x$ and the action $u$, and gives us the next state of the system.

#warning()[
  In the real world, using a simple deterministic function has a big problem. A normal math function always gives back one specific value. But in reality, the world is random (stochastic): doing the exact *same action* can lead to *different results* because of noise.
]

To fix this issue, we swap the simple function with a *probability distribution* of all the possible future states, also called a *motion model* in mobile robotics:
$
  p(x_t | x_(t-1), u_t)
$
This conditional probability is just a smart way to write a function with three parameters. Here we mean:
- $u_t$: the action we took (the command that caused the change).
- $x_(t-1)$: the previous state (where the robot started).
- $x_t$: the arrival state (the new state we are checking).

We can represent this as a *graph*, where the nodes are states and the edges are probabilities e.g:
$
  p(x_t = x_2 | x_(t-1)=x_4, u_t = u_1)
$
but this approach is highly $mr("inefficient")$ and impossible to keep in memory for continuous spaces.

In practice, this is implicitly expressed by action/motion equations with some noise added to them. To compress it, we have to pick a probability shape that is simple, works well with math, and does a good job representing real-world noise. The best choice is the *Gaussian distribution* (or Normal distribution), which is a bell-shaped curve defined by its mean $mu$ and standard deviation $sigma$. Gaussians are really nice to work with: if you do math on a Gaussian, you almost always get another Gaussian out. Plus, it saves a ton of memory, because we *only need two parameters* to define the whole thing: mean $mu$ and standard deviation $sigma$.

== The Revised Markov Assumption

To make things even simpler, it helps to draw out the dependencies between all the variables in our problem:
$
  A -> B, "A influences B"\
  B <- A, "B depends on A"
$
Looking at the current state $x_t$, we know it depends on the action we just took and the state right before it ($u_t -> x_t$). If our state doesn't include everything, just knowing the last state $x_(t-1)$ wouldn't be enough to guess $x_t$. To fix this without having to remember the whole history of the robot, we use the *Markov Assumption*. This implies that the *current state* is a *perfect summary* of everything that happened in the past. Given the past state $mg(x_(t-1))$:
$
  u_(t-1) -> mg(x_(t-1)) -> z_(t-1)
$
with the assumption, we can say that the current state $mg(x_t)$ it's only influenced by the previous state $x_(t-1)$ and the action $u_t$ we just took:
$
  u_t, x_(t-1) -> mg(x_t) -> z_t
$

By using this Markov assumption over and over, we can drop all the useless history and make our formulas way simpler:

- *Sensor Model*: Models the sensor accuracy/noise looking only at the current true state.
  $ p(z_t | x_(1:t), z_(1:t-1), u_(1:t)) "becomes" p(z_t| x_t) $

- *Action/Motion Model*: Models the new position based only on the action we just did and the last state.
  $ p(x_t | x_(0:t-1), z_(1:t), u_(1:t)) "becomes" p(x_t | x_(t-1),u_t) $

Even though these simplifications are great, they rely on a couple of implied assumptions:
- The only change factor in the world is the robot's action. If something else moves the robot, we get the *Kidnapped Robot Problem*.
- The noise that is added at any time step is independent from the noise of another time step (both in sensing and in actuation).

#figure(
  image("/assets/gaussian_motion_heatmap.png", width: 50%),
  caption: [A 2D visualization of the motion model $p(x_t | x_(t-1), u_t)$. The probability of landing exactly where intended is high (the yellow peak). The further away you go, the probability drops fast.],
)

To put it all together, we also need a *prior*: $p(x)$, which is just what we believe about the world before we take any new measurements.
Our main goal is to compute the *posterior*—our updated belief after everything happens:
$
  "Bel"(x_t) = p(x_t | u_(1:t), z_(1:t))
$

=== Formal Bayes Filter Derivation

The main problem is figuring out the belief of state $x_t$, knowing the whole history of measurements and actions:
$
  "Bel"(x_t) = p(x_t | u_(1:t), z_(1:t))
$

We can use *Bayes' Theorem* to split the newest measurement $z_t$ from the rest of the history:
$
  = eta * p(z_t | x_t, u_(1:t), z_(1:t-1)) * p(x_t | u_(1:t), z_(1:t-1))
$

#note()[
  Important correction: We use $eta$ (eta) as the normalization factor to make sure all probabilities sum up to 1. We avoid using $mu$ here, so we don't confuse it with the $mu$ used for the mean of a Gaussian distribution!
]

If we apply the *Markov assumption* to the first part, we know the current measurement only depends on the current state:
$
  = eta * p(z_t | x_t) * p(x_t | u_(1:t), z_(1:t-1))
$

For the second part, we use the *Law of Total Probability* to integrate all the possible previous states $x_(t-1)$ that could have brought us to $x_t$:
$
  = eta * p(z_t | x_t) integral p(x_t | x_(t-1), u_(1:t), z_(1:t-1)) * p(x_(t-1) | u_(1:t), z_(1:t-1)) d x_(t-1)
$

Applying the *Markov assumption* one more time to the integral, we can say that the action $u_t$ is all we need to know to go from $x_(t-1)$ to $x_t$. This gives us the final recursive formula for the Bayes Filter:
$
  = eta * p(z_t | x_t) integral p(x_t | x_(t-1), u_t) * "Bel"(x_(t-1)) d x_(t-1)
$

#example()[
  To give a real example, let's say we want to find the probability that the robot is in state $x_t = 5$ (Room 5).
  - The part $p(z_t | x_t)$ tells us the likelihood of getting the current sensor reading if the robot is actually in Room 5.
  - The integral handles the motion: based on our previous belief that we were in Room 1, and knowing we did action $u_t$ (move to the next room), what's the probability we actually ended up in Room 5?
  - Finally, we multiply everything together and normalize it with $eta$ so the total probability is exactly $1$.
]

Even though the formula looks nice, calculating the exact belief with complex shapes is basically impossible. Luckily, there's a trick: if we decide that both our prior and our motion model are Gaussian distributions, the final posterior belief will automatically be a Gaussian too!

#warning()[
  The product of two Gaussians is always a Gaussian. By using this trick, we force the math into a shape we can easily integrate and work with, which gives us a fast and clean solution.
]

This specific version is called the *Kalman Filter*. In most robotics, this Gaussian assumption is a perfect sweet spot between computing speed and being accurate enough for the real world.

== Bayes Filter Algorithm

If we turn this math into code, we get a recursive, two-step process that keeps updating our belief about the world: *Prediction* and *Correction (Update)*.

#note()[
  In a discrete world, the scary integral just becomes a simple sum over all the possible states $x_t$.
]

#pseudocode(
  [*Input*: $"Bel"(x_(t-1)), u_t, z_t$],
  [*Output*: $"Bel"(x_t)$],
  [*for* all $x_t$ do _$mo("Prediction step")$_],
  indent(
    [$overline("Bel")(x_t) = sum_(x_(t-1)) p(x_t | x_(t-1), u_t) * "Bel"(x_(t-1))$],
  ),
  [*for* all $x_t$ do _$mb("Correction step")$_],
  indent(
    [$"Bel"(x_t) = eta * p(z_t | x_t) * overline("Bel")(x_t)$],
  ),
  [*return* $"Bel"(x_t)$],
)

Where the:
1. *$mo("Prediction Step")$* ($overline("Bel")$): computes what is the belief about the current state considering *only* the action the robot has just taken. In the context of mobile robotics, this is essentially *probabilistic dead reckoning*. It calculates the probability of being in $x_t$ using only the motion model, ignoring sensors.

2. *$mb("Correction Step")$* (Update): In this last step, we ask: how does such a belief change when the observation at time $t$ is factored in? We multiply the prediction ($overline("Bel")$) by the sensor's likelihood, and scale it with $eta$ to get our new, final belief.
