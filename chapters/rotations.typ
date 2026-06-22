#import "../template.typ": *


== Properties of Rotation Matrices

We have seen that a rotation matrix is basically a way to represent a rotation. So, if we have an object in a 3D space and we want to tell someone how the object is rotated with respect to an origin, we can use the rotation matrix.

In particular, a rotation matrix needs to satisfy three constraints:
1. Each column is a *unit vector* (it has length 1).
2. Each column is *orthogonal* to each of the other columns (their dot product is 0).
3. Its *determinant is 1* (follows the right-hand rule).

#note[
  All the infinite possible rotation matrices belong to the *_Special Orthogonal Group_*, which we indicate with $S O(3)$.
]

#note[
  The transpose of a rotation matrix is equal to its inverse:
  $ R^T = R^(-1) $

  This means that:
  $ ""^B_A R = (""^A_B R)^T = (""^A_B R)^(-1) $
]

=== Elementary Rotation Matrices

*Elementary rotation matrices* describe simple rotations, basically rotations we can easily visualize, like by an angle $alpha$ on a common axis:

#align(center)[
  #image("/assets/elementary_rotation.png", width: 250pt)
]

The standard elementary matrices are:
$ R_x(alpha) = mat(1, 0, 0; 0, cos(alpha), -sin(alpha); 0, sin(alpha), cos(alpha)) $
$ R_y(beta) = mat(cos(beta), 0, sin(beta); 0, 1, 0; -sin(beta), 0, cos(beta)) $
$ R_z(gamma) = mat(cos(gamma), -sin(gamma), 0; sin(gamma), cos(gamma), 0; 0, 0, 1) $

The cool feature is that we can obtain generic rotations about arbitrary axes by *composing* (multiplying) elementary rotations.

#example[
  Imagine we pick an initial state, and we rotate it by an angle of $90$ degrees around the $z$ axis, and then $90$ degrees around the $y$ axis.

  The first transformation is banal and we can easily visualize it:

  #align(center)[
    #image("/assets/complex_rotation.png", width: 350pt)
  ]

  The problem now is: the second rotation, would be around *which* $y$ axis? The new moving $y$ axis obtained after the first rotation, or the original fixed $y$ axis of the starting point?
]

We can mathematically calculate these composite rotations depending on the context:
- *fixed axes*
- *moving axes*

==== Fixed axes

In this case, we have a fixed frame and we want to rotate considering *only the starting axes*. Applying to $B$ a sequence of $n$ rotations $R_1, R_2, ..., R_n$ with respect to the fixed frame $A$ means *pre-multiplying*:

$ ""^A_B R = R_n ... R_2 R_1 $

We are multiplying in reverse order.

#note[
  The order must always be specified, because order matters! Matrix multiplication is *not* commutative.
]

==== Moving axes

Here, each rotation $R_i$ is meant to happen _with respect to the current moving frame_. Rotating about the moving axis means to *post-multiply*:

$ ""^A_B R = R_1 R_2 ... R_n $

#theorem()[
  *Cancellation Rule:*
  - Let $""^A_B R$ be the orientation of $B$ with respect to $A$
  - Let $""^B_C R$ be the orientation of $C$ with respect to $B$

  Then:
  $ ""^A_cancel(mr(B)) R times ""^cancel(mr(B))_C R = ""^A_C R $
]

== Rotation Parametrization

Parametrization means representing a space with a *fixed number of parameters*. With rotation matrices, we are representing rotations with *9 numbers* (a $3 times 3$ matrix):
$
  R = mat(r_(11), r_(12), r_(13); r_(21), r_(22), r_(23); r_(31), r_(32), r_(33))
$

But these cannot be casual numbers, because they have to *respect the $S O(3)$ constraints*. In practice, we can freely choose only a few numbers, and the others are determined by the constraint equations.

#note[
  Rotations are fully determined by *3 parameters* (an object in space has 3 degrees of freedom for orientation). So why use 9? Rotation matrices are redundant (implicit), but they have the huge advantage of never encountering singularities.
]

If we want maximum efficiency, we can parameterize with just three numbers (minimal or explicit representation), for example: *_Roll-Pitch-Yaw_* and *_Euler Angles_*.

=== Roll, Pitch and Yaw

In this system an arbitrary rotation is described by 3 rotations specified with respect to the *fixed global frame*:

- *Roll*: A first rotation of an angle $alpha$ about the $x$ axis
- *Pitch*: A second rotation of angle $beta$ about the $y$ axis
- *Yaw*: A third rotation of angle $gamma$ about the $z$ axis

#align(center)[
  #image("/assets/Roll_Pitch_Yaw.png", width: 120pt)
]

Since it uses *fixed axes*, we pre-multiply (reverse order):
$
  R = R_z(gamma) R_y(beta) R_x(alpha)
$

=== Euler Angles

In this system (ZYZ convention) an arbitrary rotation is described by 3 rotations specified with respect to the *moving frames*:

- A first rotation of an angle $alpha$ about the $z$ axis
- A second rotation of angle $beta$ about the $y$ axis
- A third rotation of angle $gamma$ about the $z$ axis

#align(center)[
  #image("/assets/Euler.png", width: 170pt)
]

Since it uses *moving axes*, we post-multiply:
$ R = R_z(alpha) R_y(beta) R_z(gamma) $

*The Inverse Problem:* Given a desired rotation matrix $R$, we can find the Euler angles $alpha, beta, gamma$ with the following formulas:

$
  alpha & = "atan2"(r_(23), r_(13)) \
   beta & = "atan2"(sqrt(r^2_(31)+ r^2_(32)), r_(33)) \
  gamma & = "atan2"(r_(32), -r_(31))
$

#note[
  *`atan2`* is an implementation of arctangent that considers the quadrant of the angle, returning a value in $[-pi, pi]$)
]

== Singularities (Gimbal Lock)

A singularity is a point in our space where our parameterization starts behaving like crazy (loses a degree of freedom). If I choose a system that is too efficient (like 3 angles), I will encounter problems.

#example[
  Imagine being on the Earth and representing your position with 2 numbers: Latitude and Longitude.

  #align(center)[
    #image("/assets/north_pole.png", width: 180pt)
  ]

  If you go to the exact North Pole, the coordinate system collapses. Moving from one point to another nearby could require infinite speed for the longitude, because you are crossing meridians instantly.
]

#warning()[
  Singularity happens when we don't have *enough parameters* to make the PC understand a *continuous movement*.
]


For example, using the ZYZ Euler parameterization, if we consider the rotation $alpha=0, beta=180° (pi), gamma=0$, the two $z$ axes become aligned (anti-parallel). The rotation matrix collapses and one of the coordinates loses meaning, making the inverse problem unsolvable. This specific event is called *Gimbal Lock*.

#example()[
  An example of Gimbal Lock is when a pilot is flying an airplane and the pitch angle reaches $90°$ (impossible). The plane can *no longer roll, because the roll axis is aligned with the yaw axis*. The pilot loses one degree of freedom in controlling the plane's orientation.
]

*Summary of the trade-off:*
- *Rotation matrices*: inefficient (9 numbers), but *no singularities*.
- *3-angles*: efficient (3 numbers), but *presence of singularities*.

Is there a middle ground? Yes: *Quaternions*.

== Quaternions

A quaternion is a generalization of a *complex number*. It can be thought of as a complex number with 3 imaginary components: $i, j, k$.

$ 
  q = a + b i + c j + d k 
$

The imaginary components satisfy *Hamilton's equalities*:
$ i^2 = j^2 = k^2 = i j k = -1 $

- *Length*: $||q|| = sqrt(a^2 + b^2 + c^2 + d^2)$
- *Unit Quaternion*: a quaternion with length 1.
- *Conjugate*: $q^* = a - b i - c j - d k$

#informally()[
  A quaternion is a four-slot mathematical container with algebraic convenience. We *represent a rotation with $4$ numbers* and put them inside a unit quaternion.
]

Why use them:
- *No singularities*: great for storage (only 4 numbers instead of 9).
- *Combining rotations*: can be done easily with quaternion multiplication.
- *Smooth interpolation*: going from one rotation to another follows the shortest path on a 4D sphere.

We trade one extra slot of data (4 instead of 3) for mathematical reliability and smooth motion, completely avoiding Gimbal Lock.

== Euler's Theorem

Instead of relying on sequencing elementary rotations, we can exploit Euler's Theorem:

#theorem()[
  *Euler's Theorem:*
  In 3 dimensions, any orientation can be obtained by a *single rotation* of some angle about a *single axis* that passes through the origin.
]

This is the underlying concept that makes Quaternions (and Axis-Angle representations) possible!
