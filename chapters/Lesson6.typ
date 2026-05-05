#import "../template.typ": *

== Taking a robotic perspective

The pose og the robot $p = ((hat(x),hat(y)), theta)$ it's encode the information into a $2D$ dimension, we have a thirt dimension but we don't use it.

Collectin data form enviroment does not change the enviroment.

*From the enviroment of the robot* -> sensor measurements, we can change the robot but not the enviroment. The robot is a passive observer of the enviroment, so we can change the state of the robot but not the state of the enviroment.

*Control actions* -> from the robot to the enviroment, we can change the enviroment but not the robot. The robot does something phisically in the enviroment, so the state of the enviroment change

How we can formalize this state of estimation ? We use something called *belied* over $X$ (basically a conditional distribution). I have an initial belief, by taking measurement over time i can change my belief:
$
  "Bel"(x_t) = p(x_t | z_1,z_2, dots, z_t, u_1, u_2, dots, u_t) = p(x_t | z_(1:t), u_(1:t))
$
where:
- $u$ are the control actions
- $z$ is the measurements

#warning()[
  The order of the measurements and the control actions does not matter, we can change the order of the measurements and the control actions without changing the belief.
]

a belief is a *probability distribution over the state of the world* at time $t$, it represents our uncertainty about the state of the world:
- if $x$ is a continuos variable is a proper probability distribution
- if $x$ is a discrete variable is a probability mass function
We can update our belief by taking measurements and by taking actions.

it's a *conditional probability*, given all the measurements and actions up to time $t$.

#example()[
  We want to estimaate the state of the plant. We wanto to compute a belife over the state of the plant, so a distribution probability over the state of the plant. We want a probability distribution if the plant is healhy and one if the plant is sick.

  We can't use the mean of the distribution because we don't take into account the proprieties of the sensor (False positivi and false negative rate).

  Also, with the avarege of the observation we don't consider the context of the experiment (*the prior*). It's something i know before taking the measurment.

  We can combine the measurements in a way that take into account of the proprieties of the sensor, this method is called *Bayes filter*. The bayes filter consider:
  - The proproties of the sensor (false positive and false negative rate)
  - The prior (the initial belief about the state of the word)

  The formula with the gorund knowledge is:
  $
    "Bell"(x_t) =p(x|z_1, dots,z_t) = (p(z_t | x, z_1, dots, z_(t-1)) * p(x|z_1, dots, z_(t-1))) / p(z_t | z_1, dots, z_(t-1))
  $
  The probability of $x$ (plant is healhy or sick) given all the measurements up to time $t$.\
  in this example we don't consider the control actions, so we can ignore the $u$ (the measurments don't change the state of thw word).
]

== Markov assumption

A measurment $z$ at time $t$ is independent of all the past measurements and control actions given the current state of the world. This means that the current state of the world is a sufficient statistic for the past measurements and control actions.

#note()[
  This means that the present state $x$ is a complete summary of the past measurements and control actions, so we can ignore the past measurements and control actions when we want to compute the belief at time $t$.
]

if we accept the Markov assumption, the measurment $z_t$ depend on $z_1, dots z_(t-1)$ ? it depends:
- if the state $x$ is known the answer in *NO*. Knowing what we saw a minute ago dosen't help us to understand the current reading of the sensor, because we already know the state of the plant (damage or not)

- if the state $x$ is unknown the answer is *YES*, because the measurment $z_t$ depend on the state $x$ and the state $x$ depend on the past measurements and control actions.

#note()[
  Under markov assumption past and present measurements are *conditionally independent* given the current state of the world.

  if the markov assumption does not hold we can say that:
  $
    p(z_t) != p(z_t | z_1, dots, z_(t-1))
  $
]

== Recursive Bayes filter

The formula $p(x| z_1, dots, z_(t-1))$ is what i had computed at time $t-1$:
$
  p(z_(t-1)| x) mr(p(x | z_1, dots, z_(t-2))) / p(z_(t-1) | z_1, dots, z_(t-2))
$
where the $mr("red")$ part is the belief at time $t-2$. The initional belief is called *prior* and is denoted as $p(x)$, the belief without no measurements.

By substiution we can write the formula of the belief at time $t$ as:
$
  p(x| z_1, dots, z_t) = mu_(1 dots t) product_(t=1)^z mr(p(z_t|x)p(x))
$
where the red part is the prior. If we suppose that $x$ is $1$, in each terms $z_t$ the $x$ will be $1$. The $z_t$ can be $1$ or $0$. If we got $z_t = 1$ the probability is $p(1|1)$ that is a *true positive rate*.\

- $p(0|1)$ it's a *false negative rate*. //riguardare perchè
- $p(0|0)$ it's a *true negative rate*
- $p(1|0)$ it's a *false positive rate*.

If te true state of the plant is $1$ we use the true positive and false negative.:
$
  p(1| z_1, dots, z_t) = mu_(1 dots t) product_(t=1)^z mr(p(z_t|1)p(1))\
  p(0| z_1, dots, z_t) = mu_(1 dots t) product_(t=1)^z mr(p(z_t|0)p(0))
$

#example()[
  Code example:
  - True positive rate is $0.1$ is $10%$ chance to get a true positive, it sucks.

  - False negative rate is $1-"true positivi"$ = $0.9$ is $90%$ chance to get a false negative, it sucks.

  The example generate $100$ measurements, that follow the distribution provided by the sensor proprieties. I assume that the true state is $1$ i generete a $1$ with the probability of $0.1$ and a $0$ with the probability of $0.9$.






]


