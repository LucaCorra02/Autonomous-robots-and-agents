#import "../template.typ": *

= Lesson 7

Even if the $"TNR" = 0.5$ the sensor still converge with the bias filter (maybe slower), that's is the power of the formula.

#warning()[
  The only case when the formula can't help us is when even the $"TPR"$ is $0.5$. In this case the sensor is completely random and we can't do anything to improve it.
]

We can estimate a quantity with multiple sensor, where each sensor has is likehood. The formula is the same, but we need to consider all the sensor together.

= Control Action

The bias filter can considers only measurements, but we can use the same formula to consider also the control action.

The real robitcs part is to generalize the setup to consider also the control action and not only the belief about the true state of the system.

A control action can change the state of the system $x$, that's a compleat different problem. We need to extend the bias filter.

#note()[
  Just like the information collected by a sensor are uncertain, also the effect of a control action is uncertain. We can use the same formula to consider also the control action.
]

How we can describe the effect of taking action $u$ in the state $x$? We can use a function $f(x,u)$ that take the state $x$ and the action $u$ and return the new state of the system. This function is called the *transition function*.\
But in a robotic scenario, this function introdoces a problem: we are assuming that the *word is deterministic*, a function can return only one value. But in reality, the word is not deterministic, the same action can have different effects (there is always some noise even in the actuation).

We can use a *probability distribution* over the possibile state of the word:
$
  p(x_t | x_(t-1), u_(t))
$
this probability it's a fancy way to describe a three parameters function $f(x_t, x_(t-1), u_t)$. But in the first notation we can say that:
- $u_t$ are he effects
- $x_t$ is the hypotesis
- $x_(t-1)$ is the ...

#note()[
  We don't need to think that the action $u_t$ is commited during the state $x_t$, but is the action that take us to the final state $x_t$.

  This notation works even for continuos description of the word. There is always a before and after that connecting the action.
]

//add graph img

Let's suppose a stocatic word. That's a reppresentation of a conditionally probability in a discrete case. If i have a lot of state this reppresentation is very hard to draw.
The explicit representation of the graph is very inefficient, we need to write for every triplet the possibile outcomes, with their own probability.
$
  p(x_t = x_2 | x_(t-1)=x_4, u_t = y_1)
$
For example: $O=x+1$ is a formula for every possible input $x$, we don't need to write a big taple for every input and output.

If the space is continuos or we have to many variabile we *need a formula*. We need to choose a representation of the probabilty distribution wich is: simple, well behavid (operations need to work), needs to represent well the word.

We can choose a normal distribution. The highest point in the gausian distribution are the expeted value, also even if we operate on the gausian distribution we obtain another gausian distribution. We also only need to parameters to define this distribution
$
  omega = (mu, sigma)
$
mean and standard devation.

== Markov Assumption revised

If we have a state $x_t$ the current state of the robot. We are going to draw the arrow (with is own direction):
$
  A -> B, "A contribute to cause B"\
  B <- A, "B depends on A, A influencezed B"
$
$x_t$ depends on action and current state:
- $u_t -> x_t$ $u_t$ influencezed the final state

we don't need to considere the previous action $u_(t-1)$ if we consider the state current state $x_(t-1)$ the purple path is True only when the state is a completely summary of the past. If the state is missing some part of the histroy, the past state it's not sufficient. Depsite we use markov assumntion so the current state contains all the relevant information to determinate a transiction.

the state $x_t$ influencezed the observation $z_t$ of the word.

I can apply the markov assumntion over and over. Since we adopt the markov assumtion we can reduce the formula:
$
  "Sensor Model": p(z_t | x_(1:t), z_(1:t), u_(1:t)) = p(z_t| x_t) "is model the sensor accuracy /noise with respect to the true state"\
  "Actual Model": p(x_t | x_(0:t-1), z_(0:t), u_(1:t)) = p(x_t | x_(t-1),u_t)
$

Assumption:
- The only change factor in the world is the robot action's. It's an assumption so it's not perfect, for example the robot can move in an intent and not controlled way. This problem in littelature is called the *kidnapped robot problem*, it's like turn on the robot and moving it around the space.

- The noise that is added at any time step is indipendent from the noise of another time step

//capire il grafico con i cerchi e colori
Each point on the plane is dependent on $2$ coordinates and the angle is fixed. The probability of end in the intendet location is very high. The faraway you are it's impossibile (end up in the blue part of the graphic it's impossibile). This chart is a motion model, given the uncernaty.

I also need a prior: $p(x)$ the belief about the world before took every measurements.
The task is to compute the posterior:
$
  "Bel"(x_t) = p(x_t | u_(1:t), z_(1:t))
$
