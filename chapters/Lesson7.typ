#import "../template.typ": *

= Lesson 7

When checking if a sensor is reliable, even if the True Negative Rate ($"TNR"$) is $0.5$, the system still gets to the true state using the Bayes/bias filter, just a bit slower. This shows how powerful the formula is.

#warning()[
  But there's a hard limit: the only time the formula can't help us is when both the $"TNR"$ and the True Positive Rate ($"TPR"$) are $0.5$. In this case, the sensor is just giving us random noise, so it's mathematically impossible to get anything useful out of it to improve our guess.
]

Luckily, real robots rarely use just one sensor. We can guess a value using multiple sensors at the same time, each with its own likelihood. The formula is the same, but we expand it to include all the sensors together.

== Control Action

The standard Bayes filter works great for sensor measurements, but just looking at the world doesn't change it. To build a real robot, we need to update our math to include *control actions*, because when a robot does something, it changes the environment.

Since an action changes the state of the system $x$, we have a totally different problem: we need to write down the math for how an action affects a state so we can add it to the Bayes filter.

#note()[
  This is super important because, just like sensor info is uncertain, the physical effect of an action is uncertain too. Actually, making a move usually makes us *less* sure about the robot's exact position because of mechanical noise (like wheels slipping). Luckily, we can use the same probability formulas to model these actions too.
]

To describe the effect of taking an action $u$ on the state $x$, we can start by thinking of a *transition function* $f(x, u)$. This function takes the current state $x$ and the action $u$, and gives us the next state of the system. 

#warning()[
  In the real world, using a simple function has a big problem: it assumes the world is *deterministic*. A normal math function always gives back one specific value. But in reality, the world is random (stochastic): doing the exact same action can lead to different results because of noise.
]

To fix this issue, we swap the simple function with a *probability distribution* of all the possible future states:
$
  p(x_t | x_(t-1), u_t)
$
This conditional probability is just a smart way to write a function with three parameters. Here we mean:
- $u_t$: the action we took (the command that caused the change).
- $x_(t-1)$: the previous state (where the robot started).
- $x_t$: the arrival state (the new state we are checking).

#note()[
  Just to be clear on the timeline: we don't mean that the action $u_t$ happens *during* the state $x_t$. Instead, $u_t$ is the action that brings us from the old state to the new state $x_t$. This makes sense even if time is continuous, because there's always a "before" and an "after" linked by an action.
]

//add graph img

In a random world, we could draw this conditional probability as a graph. But drawing every single node and connection gets messy very fast. For example, if we have 100 states and 50 actions, we'd need a huge table to save the probability of every single combination:
$
  p(x_t = x_2 | x_(t-1)=x_4, u_t = y_1)
$
If the space is continuous or there are too many variables, this table gets so big that it's impossible to keep in memory. So, we *need a formula* to compress all this information.

To compress it, we have to pick a probability shape that is simple, works well with math, and does a good job representing real-world noise. 

That's why everyone uses the *Normal (Gaussian) distribution*. Gaussians are really nice to work with: if you do math on a Gaussian, you almost always get another Gaussian out. Plus, it saves a ton of memory, because we only need two parameters to define the whole thing:
$
  omega = (mu, sigma)
$
where $mu$ is the mean (what we expect) and $sigma$ is the standard deviation (how uncertain we are).

== Markov Assumption Revised

To make things even simpler, it helps to draw out what causes what using arrows:
$
  A -> B, "A contributes to cause B"\
  B <- A, "B depends on A; A influences B"
$
Looking at the current state $x_t$, we know it depends on the action we just took and the state right before it:
- $u_t -> x_t$: the action directly affects the final state.

Of course, if our state doesn't include everything (like if we forget to track speed or battery), just knowing the last state $x_(t-1)$ wouldn't be enough to guess $x_t$. To fix this without having to remember the whole history of the robot since we turned it on, we use the *Markov Assumption*. This just means we assume the current state is a perfect summary of everything that happened in the past. Thanks to this, we can totally ignore past actions $u_(t-1)$ as long as we know the current state $x_(t-1)$. 

In the same way, the true state $x_t$ is the only thing that affects the current sensor reading $z_t$. By using this Markov assumption over and over, we can drop all the useless history and make our formulas way simpler:

- Sensor Model : Models the sensor accuracy/noise looking only at the current true state $ p(z_t | x_(1:t), z_(1:t-1), u_(1:t)) = p(z_t| x_t) $

- Action/Transition Model: Models the new position based only on the action we just did and the last state $ p(x_t | x_(0:t-1), z_(0:t-1), u_(1:t)) = p(x_t | x_(t-1),u_t) $

Even though these simplifications are great, they rely on a couple of big assumptions:
- We assume the robot's actions are the only things changing the world. Since that's almost never 100% true, if something else moves the robot, we get what's called the *Kidnapped Robot Problem* (like if someone picks up the robot and drops it in a new room).
- We assume the noise at any moment has nothing to do with the noise from the past.

//capire il grafico con i cerchi e colori
If we try to draw a motion model with this uncertainty, each point on the plane depends on coordinates and an angle. The probability of landing exactly where we want is high (it's the peak of the bell). The further away you go, the probability drops fast, until you reach an area where ending up there is basically impossible. 

To put it all together, we also need a *prior*: $p(x)$, which is just what we believe about the world before we take any new measurements. 
Our main goal is to compute the *posterior*—our updated belief after everything happens:
$
  "Bel"(x_t) = p(x_t | u_(1:t), z_(1:t))
$

== Bayes Filter Derivation // non in esame

The main problem is figuring out the belief of state $x_t$, knowing the whole history of measurements and actions:
$
  "Bel"(x_t) = p(x_t | u_(1:t), z_(1:t))
$
Since we're trying to figure out the state by looking at observations, this is basically a diagnostic problem. We can use Bayes' Theorem to split the newest measurement $z_t$ from the rest of the history:
$
  mu mr(p(z_t| x_t, u_(1:t), z_(1:t-1))) p(x_t | u_(1_t),z_(1:t-1))
$

#note()[
  Important reminder: Here, $mu$ is used as the normalization factor to make sure all probabilities sum up to 1. Be careful not to confuse it with the $mu$ used earlier for the mean of a Gaussian distribution!
]

If we apply the Markov assumption to the first part, we know the current measurement only depends on the current state, which simplifies it down to our normal sensor model:
$
  mu p(z_t | mr(x_t)) mb(p(x_t | u_(1:t), z_(1:t-1)))
$
For the second part, we have to consider how we got to $x_t$. We use the Law of Total Probability to sum up (or integrate, if we're in continuous space) all the possible previous states $x_(t-1)$ that could have brought us to $x_t$ after taking action $u_t$:
$
  mu p(z_t | z_t) integral mr(p(x_t | x_(t-1),u_(1:t))), z_(1:t-1)) p(x_(t-1)|u_(1:t), z_(1:t-1)) d x_(t-1)
$
Applying the Markov assumption one more time to the integral, we can say that the action $u_t$ is all we need to know to go from $x_(t-1)$ to $x_t$. This gives us the final recursive formula for the Bayes Filter:
$
  "Bel"(x_t) = mu p(z_y | x_t) integral p(x_t | x_(t-1), u_t) "Bel"(x_(t-1)) d x_(t-1)
$

#example()[
  To give a real example, let's say we want to find the probability that the robot is in state $x_t = 5$ (Room 5). 
  - The part $p(z_t | x_t)$ tells us the likelihood of getting the current sensor reading (like seeing a red light) if the robot is actually in Room 5. 
  - The integral handles the motion: based on our previous belief that we were in Room 1, and knowing we did action $u_t$ (move to the next room), what's the probability we actually ended up in Room 5? 
  - Finally, we multiply everything together and normalize it with $mu$ so the total probability is exactly $1$.
]

Even though the formula looks nice, solving it is actually a huge pain: when you multiply the probability distribution and the prior belief, you usually get a really messy, non-linear shape. Because of this, calculating the exact belief is basically impossible (you end up with weird shapes with multiple peaks).

Luckily, there's a great trick. Nobody forces us to use a messy non-linear belief. If we decide that both our prior and our motion model are Gaussian distributions, the final posterior belief will automatically be a Gaussian too!

#warning()[
  The product of two Gaussians is always a Gaussian. By using this trick, we force the math into a shape we can easily integrate and work with, which gives us a fast and clean solution.
]

This specific version—where the whole Bayes filter just becomes a bunch of Gaussians—is called the *Kalman Filter*. In most robotics stuff, this Gaussian assumption is a perfect sweet spot between computing speed and being accurate enough for the real world.

=== Bayes Filter Algorithm

If we turn this math into code, we get a recursive, two-step process that keeps updating our belief about the world: *Prediction* and *Correction (Update)*.

In a discrete world, the scary integral just becomes a simple sum (basically multiplying matrices) over all the possible states $x_t$. The logic runs in a loop:

1. *Prediction Step* ($overline("Bel")$ or "Bel-bar"):
$
  overline("Bel")(x_t) = sum_(x_(t-1)) p(x_t | x_(t-1), u_t) "Bel"(x_(t-1))
$
#note()[
  The $overline("Bel")$ is our blind prediction: it calculates the probability of being in $x_t$ using *only* the motion model, completely ignoring what the sensors are saying right now.
]

2. *Correction Step* (Update):
$
  "Bel"(x_t) = mu p(z_t | x_t) overline("Bel")(x_t)
$
In this last step, we finally open our "eyes". We use the actual sensor reading $z_t$ to fix our blind prediction. We multiply the prediction ($overline("Bel")$) by the sensor's likelihood, and scale it with $mu$ to get our new, final belief.