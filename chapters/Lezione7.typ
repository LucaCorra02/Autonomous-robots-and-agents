#import "../template.typ": *

= Lesson 7

Even if the $"TNR" = 0.5$, the sensor still converges with the bias filter (maybe slower); that's the power of the formula.

#warning()[
  The only case when the formula can't help us is when even the $"TPR"$ is $0.5$. In this case, the sensor is completely random and we can't do anything to improve it.
]

We can estimate a quantity with multiple sensors, where each sensor has its likelihood. The formula is the same, but we need to consider all the sensors together.

== Control Action

The bias filter can consider only measurements, but we can use the same formula to also consider the control action.

The real robotics part is to generalize the setup to consider also the control action and not only the belief about the true state of the system.

A control action can change the state of the system $x$; that's a completely different problem. We need to extend the bias filter.

#note()[
  Just like the information collected by a sensor is uncertain, also the effect of a control action is uncertain. We can use the same formula to also consider the control action.
]

How can we describe the effect of taking action $u$ on the state $x$? We can use a function $f(x,u)$ that takes the state $x$ and the action $u$ and returns the new state of the system. This function is called the *transition function*.\
But in a robotic scenario, this function introduces a problem: we are assuming that the *world is deterministic*; a function can return only one value. In reality, the world is not deterministic: the same action can have different effects (there is always some noise even in the actuation).

We can use a *probability distribution* over the possible states of the world:
$
  p(x_t | x_(t-1), u_(t))
$
This probability is a fancy way to describe a three-parameter function $f(x_t, x_(t-1), u_t)$. But in the first notation we can say that:
- $u_t$ are the effects
- $x_t$ is the hypothesis
- $x_(t-1)$ is the previous state

#note()[
  We don't need to think that the action $u_t$ is committed during the state $x_t$; rather, it is the action that takes us to the final state $x_t$.

  This notation works even for continuous descriptions of the world. There is always a before and after that connects the action.
]

//add graph img

Let's suppose a stochastic world. That's a representation of a conditional probability in a discrete case. If I have many states this representation is very hard to draw.
The explicit representation of the graph is very inefficient: we would need to write for every triplet the possible outcomes, each with its own probability.
$
  p(x_t = x_2 | x_(t-1)=x_4, u_t = y_1)
$
For example: $O=x+1$ is a formula for every possible input $x$; we don't need to write a big table for every input and output.

If the space is continuous or we have too many variables we *need a formula*. We need to choose a representation of the probability distribution which is: simple, well-behaved (operations need to work), and needs to represent well the world.

We can choose a normal distribution. The highest point in the Gaussian distribution is the expected value; also, if we operate on a Gaussian distribution we obtain another Gaussian distribution. We also only need two parameters to define this distribution
$
  omega = (mu, sigma)
$
mean and standard deviation.

== Markov Assumption revised

If we have a state $x_t$ representing the current state of the robot. We are going to draw the arrow (with its own direction):
$
  A -> B, "A contributes to cause B"\
  B <- A, "B depends on A; A influences B"
$
$x_t$ depends on action and current state:
- $u_t -> x_t$ $u_t$ influences the final state

We don't need to consider the previous action $u_(t-1)$ if we consider the current state $x_(t-1)$. The purple path is true only when the state is a complete summary of the past. If the state is missing some part of the history, the past state is not sufficient. Despite this, we use the Markov assumption so the current state contains all the relevant information to determine a transition.

The state $x_t$ influences the observation $z_t$ of the world.

I can apply the Markov assumption over and over. Since we adopt the Markov assumption we can reduce the formula:
$
  "Sensor Model": p(z_t | x_(1:t), z_(1:t), u_(1:t)) = p(z_t| x_t) "is model the sensor accuracy /noise with respect to the true state"\
  "Actual Model": p(x_t | x_(0:t-1), z_(0:t), u_(1:t)) = p(x_t | x_(t-1),u_t)
$

Assumption:
- The only changing factor in the world is the robot's actions. It's an assumption so it's not perfect; for example the robot can move in an unintended and uncontrolled way. This problem in literature is called the *kidnapped robot problem*: it's like turning on the robot and moving it around the space.

- The noise that is added at any time step is independent from the noise at another time step.

//capire il grafico con i cerchi e colori
Each point on the plane is dependent on two coordinates and the angle is fixed. The probability of ending in the intended location is very high. The farther you are, it's impossible (ending up in the blue part of the graphic is impossible). This chart is a motion model, given the uncertainty.

I also need a prior: $p(x)$, the belief about the world before taking any measurements.
The task is to compute the posterior:
$
  "Bel"(x_t) = p(x_t | u_(1:t), z_(1:t))
$

== Bayes filter derivation // non in esame

The probelem is:
$
  "Bel"(x_t) = p(x_t | u_(1:t), z_(1:t))
$
belief of state $x_t$ given the measurements and actions. I have a diagnostical question, i can use the Bayes theoreme inverting the last state and measurements:
$
  mu mr(p(z_t| x_t, u_(1:t), z_(1:t-1))) p(x_t | u_(1_t),z_(1:t-1))
$
the red part it's only infuendec by the last state, the actions do not infouenced the last measurements. The state explaun $z_t$. So for the markov assumntion:
$
  mu p(z_t | mr(x_t)) mb(p(x_t | u_(1:t), z_(1:t-1)))
$
The blue part is just a sum of the possibile $x_(t-1)$ we can have any $u_t$ actions that leads to $x_t$ form $x_(t-1)$ with different probability. In the continuos case is an integral:
$
  mu p(z_t | z_t) integral mr(p(x_t | x_(t-1),u_(1:t))), z_(1:t-1)) p(x_(t-1)|u_(1:t), z_(1:t-1)) d x_(t-1)
$
- the red part can be semplified by markov assumption
- In the right part the $u_t$ action is in the past, so we cante remove it, because we are considering the $x_(t-1)$ state.
$
  mu p(z_t | x_t) integral p(x_t | x_(t-1),u_t)p(x_(t-1)|u_(1:t-1),z_(1:t-1)) d x_(t-1)
$

the final formula is:
$
  "Bel"(x_t) = mu p(z_y | x_t) integral p(x_t | x_(t-1), u_t) "Bel"(x_(t-1)) d x_(t-1)
$

#example()[
  suppose that we are in the state $x_t = 5$. The firt part i need to compute is:
  - $p(z_t | x_t)$ thats' teel me the probability to see a red light when we are in the room $5$ (it's the likelihood at time $5$)

  - The integral part says (suppose that i move from room $1$ to $5$):
    - The belife i was in the room $1$
    - I need to take the action $x_t$ (the action is next, move to the next room). If a took the action next and i was in $1$ what's the probability of hanggig up in $5$? The probability is determinated by the motion model

  - Finally i have to normalize $mu$, so every number are sum up to $1$.
]

I need the shape of the function, to compute the integral, in that case the product between p and the belief. In practise the shape of p and the belief it's a *non linear* function, it's complex to compute. As a conseguence the belief has a very complex shape.

The best shape of the belief it's a campana function. The maximum will be the best probability value, then the probability decrease after that point. Around the guess the probability decrease.

If we have a bimodal (two hypotesis), this shape it's more complex. In this case there is no magic formula to integrate the formula.

But we can decide that the motion model is a gautian distribution (so we can have a linear belief), this hypotesis it's not perfect but is good enought. Even the prior will be a gausian.

#warning()[
  The product of two gausian it's a gausian. And we know how to integrate a gausian, it's can be easilly integrate.
]

The *calman filter* it's just a byas filter where everything it's a Gaussian. In the robotic field, this assumption it's good enough.

=== Bayesfilter algo

In the discrete versione we iterate for all $x_t$ possible state. fro each one of those i need to compute a belief. In the discrete world i only have a sum (it's like a table).

with the for loop i calculate only a part of the formula, for each $x_t$ then i compute $"Bell"(x_t)$ and calculate the product with the summatory.

In this case the two part can be enterpered in two different part:
- $hat("Bell"(x_t))$ it's the belief i'm in the state $x_t$ i compute them whitout considering the measurements. It's like a prediction we belive to be in the $x_t$ state.
#note()[
  I only use the motion mdoel
]

- the last part it's the corection. I use the sensor and apply i correction on the belief where i am, based on the measurements on the sensor





