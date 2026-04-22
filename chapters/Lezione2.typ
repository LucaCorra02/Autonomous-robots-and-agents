#import "../template.typ": *

= Kinematics

*Kinematics* studies the mechanics of motion without taking into account the forces that produce the motion (focuses on position, velocity, and acceleration, neglects forces).

Robots are physical objects (rigid bodies) that move in 3D spaces, the study of kinematics is necessary. The robots run some algorithms based on what's going on in the environment. Our algorithm needs to *represent and deliberate* about motion.

Most important use of kinematics:
- It can be used for *control the robot*. _For example_, we can move a robot in a specific space by mapping its position into a 3d vector $x,y,z$ called *pose*.

- It can be used for *transpose the coordinates* of a drone (local space) to the coordinates that lives in the real world (global space)

#example[
  Suppose that we have a drone flying in a room. We can use the kinematics to transpose the _local_ coordinates of the drone to the _global_ coordinates in the room.

  This is necessary because the drone needs to know it's position in the room, in order to move around and avoid obstacles.
]

In the robotics field the operation of *transposing the coordinates* is called changing the *frame of reference*. As a consequence, we can represent the same point in different ways.

#note[
  Each component of the robot usually has *its own frame of reference* (the wheels, the sensor, etc.). It's a convention that we choose to use.

  We need to use a specific frame for each components because *a sensor returns data in its own frame of reference*. We need to transpose the data into the global frame of reference, in order to use it for navigation and control.
]


== Algebra of transformations

=== Frames (Frame of Reference)

We assume two frames:
- *Global frame* (the world): we can assume that the *world is fixed*, it doesn't move. We use this frame to represent the position of the robot in the real world;

- *Robot frame*: the robot is a rigid body, a frame is *rigidly attached* to it (it means that the frames move with the robots);
  #warning()[
    A *rigid body* is a solid object that doesn't deform or change shape when subjected to forces. The Euclidean distance between any two points never changes.
  ]

=== Vectors and matrices

We can see a vector as an object $v$ with two properties:
- *Direction*
- *Magnitude or length*
- Addition $v + u "and scaling" alpha v$ still produce a vector in the same space.

#warning()[
  This property *isn't dependent on the frame of reference*, it is intrinsic to the vector itself.
]

*Coordinate vector* $p in R^n$ (real number space, a vector is a tuple of $n$ real numbers) is an *ordered* list of numbers representing an abstract vector.

#warning()[
  The coordinates are relative to a frame of reference, they are not intrinsic to the vector itself. The same vector can have different coordinates in different frames of reference.
]

*Matrix* is a rectangular array of numbers (scalar). Typically a matrix has $n$ rows and $m$ columns, we can write it as $A in R^{n x m}$.

One of the most important operations is the *matrix multiplication* $C = A dot B$ where $A in R^{n x m}$, $B in R^{m x p}$ and $C in R^{n x p}$. The result of the multiplication is a matrix with $n$ rows and $p$ columns:
$
  c_(i,j) = sum_k a_(i,k) b_(k,j)
$
#warning()[
  The inner dimension of the two matrices *must be the same*, otherwise the multiplication is not defined.

  The product of two matrices is not commutative, in general $A dot B != B dot A$.
]
Each column of the result matrix can be seen as a *linear combination* of the columns of the first matrix $A$, where the coefficients of the linear combination are given by the corresponding column of the second matrix *B*.

The inverse of a matrix $A^{-1}$ is the matrix such that $A dot A^{-1} = I$ where $I$ is the identity matrix. The identity matrix is a square matrix with ones on the diagonal and zeros elsewhere.

=== Dot product

Dot product or inner product: the product between two vectors $u$ and $v$. The result is a scalar.

The scalar can be interpreted as the length of the $p'$ projection onto $q$, scaled by $q'$'s length:
$
  p dot q = ||p|| ||q|| cos(theta)
$
where $theta$ is the angle between the two vectors. The right part $p$ can be interpreted as the similarity between the two vectors, if the angle is small the dot product is large, if the angle is large the dot product is small:
- If $p dot q > 0$ the vectors have same direction
- If $p dot q = 0$ the vectors are orthogonal
- If $p dot q < 0$ the vectors have opposite direction

#warning()[
  This definition applies independently from the frame of reference, it is an intrinsic property of the vectors themselves.
]

If we represent $p$ and $q$ in a coordinate system, the dot product can be calculated with a trivial matrix multiplication:
$
  p dot q = p^T dot q =[p_x p_y p_z] dot [q_x q_y q_z]^T = p_x q_x + p_y q_y + p_z q_z
$
Vectors are also themselves a matrix, a column vector is a matrix with one column and $n$ rows, a row vector is a matrix with one row and $n$ columns.

#note()[
  When we introduce a coordinate system, we need to introduce a specific frame of reference. Now we can treat the vector as a mathematical object, we can do operations on it, but we need to be careful about the frame of reference we are using.
]

=== Cross product

The cross product maps two vectors in $R^3$ to a vector in $R^3$. The result is a vector that is *orthogonal* to both input vectors, and its magnitude is equal to the area of the parallelogram spanned by the two input vectors. The result is:
- Length: $||p|| ||q|| sin(theta)$
- Direction: follow the right hand rule (thumb is the direction of the cross product)
- if $p times q = 0$, they are parallel

Now we represent $p$ and $q$ as a list of numbers as a list of coordinates. We need to convert $p$ to a specific skew symmetric matrix (matrice antisimmetrica):
$
  [p] = [
    0, -p_z, p_y,
    p_z, 0, -p_x,
    -p_y, p_x, 0
  ]
$

=== Frames

A frame is defined by an origin and a set of basis vectors. The three vectors are not arbitrary, they need to satisfy some property:

- *orthonormality*:
  - $x dot x = 1, y dot y = 1, z dot z = 1$. $x$, $y$ and $z$, they are *unit vectors*. The frame is orthonormal if the basis vectors are orthonormal.

  - $x dot y = 0, x dot z = 0, y dot z = 0$ their norm is $90$ degrees, they are orthogonal to each other.

- *right hand rule*:
  - $x times y = z$
  - $y times z = x$
  - $z times x = y$

  The frame is right-handed if the basis vectors satisfy the right-hand rule.

//aggiungere immagine.

=== Coordinates

$A_p$ $p$ is a vector of coordinates expressed in the frame $A$.

//aggiungere immagine.

#example()[
  Two robots in $O^'$ and $O^''$. We use two frames space $A$ and $B$. The same point $p$ in frame $A$ has coordinates $A_p$ = [6 2 2] while $B_p = [0 -1.4 ,0]$
]

=== Conversion

In order to convert the coordinates of a point from one frame to another, we need to use a *transformation*.

#warning()[
  I can't do this transformation if I don't know the relative position and orientation of the two frames. I need to know how the two frames are related to each other.
]

Suppose that $A$ is the world frame, and $B$ is the robot frame. Where:
- $A = O -x y z$
- $B = O' - x'y'z'$
We want to represent the position of B with respect to A. We need to know:
- The position of the origin of $B$. I can give the coordinates of $O'$ respect to $A$, $A_O'$.
- The orientation of $B$ respect to $A$. I can give the coordinates of the *basis vectors* of $B$ respect to $A$:
$
  (A_x', A_y', A_z')
$

Imagine we can collide the two frame's origin, so the origin is the same, but the orientation is different. We can use the *end point* concept.

- What are the coordinates of $x'$ in $A$? If we respond to this question, we can draw the x' axes in the $A$ frame.

The dot product is the projection of a vector onto another vector, so we can use it to find the coordinates of $x'$ in $A$:
$
  A_x' = [x' dot x, x' dot y, x' dot z]
$
it works because the $x'$ is a unit vector, so the dot product is equal to the projection of $x'$ onto $A_x$. Where $A_x'$ is also a unitary vector.

We can pack three coordinates of the basis vectors of $B$ respect to $A$ in a matrix, called *rotation matrix*:
$
  R = [
    A_x' dot x, A_x' dot y, A_x' dot z,
    A_y' dot x, A_y' dot y, A_y' dot z,
    A_z' dot x, A_z' dot y, A_z' dot z
  ]
$
it describes how the frame $B$ is oriented respect to $A$.

*pose* is the joint representation of the position and orientation of a frame. When we say the pose of a robot, we are talking about the position and orientation of the robot in the world, the frame rigidly attached to the robot.

In the *inverse representation*  we only have swapped the two frame, we ask the inverse of the previous question: what are the coordinates of $x$ axis in $B$?
The rotation matrix is *transpose* of the previous one.
$
  R = R^T
$

#example[
  If we represent the pose of the frame $B$ in the frame $A$, we can also represent the point $p$ in the frame $A$. In the example there is no rotation between the two frame, so we only need to translate the origin of $B$ respect to $A$.

  the non rotation is a rotation itself, the non rotation is the *identity matrix*: it describes a $0$ degree rotation.

  So the position of point $p$ respect to $A$ is:
  $
    A_p = A_O' + B_= //aggiungre
  $
  We only sum vectors, it's just a translation.
]

#example[
  in this example there is no translation, the two frame have the same origin, but there is a rotation between the two frame.

  - We know that $B_p$ are the coordinates of $p$ in the frame $B$, we use the point of view of the robot:
  $
    B_p = [p_x, p_y, p_x] = p_x x^x'
  $
  the coordinates of $x^'$ are [1 0 0]. Expanding the previous equation.

  - Imagine that we know the rotation matrix $R$ that describes the orientation of $B$ respect to $A$.

  $A_x'$ are the first columns of the rotation matrix, so


  in the final result (a column vector, so a point) we can see that each entry is a linear combination of the coordinate of the robot and the rotation matrix.
]


