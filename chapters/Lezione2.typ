#import "../template.typ": *

= Kinematics

A kind of meccanism and linear algebra.

Robotics are physcal objctes, the cinematics is necessary. He want the robots to move in the world and do some smart stuff. We need to run an algorithm base on the what going on in the enviroment.

Our algorithm needs to *represent and deliberate* about motion. A robot needs to move, we can see move the movement as a mathematical problem.

#note[
  Kinematics is the studying the mechanics of motion without considering the forces that cause the motion.
]

It is a branch of mechanics that focuses on describing the motion of objects, including their position, velocity, and acceleration, without taking into account the forces that produce the motion

We need the cinematics to control the robot, for example to move a robot in a specific space. The point in a space are rappresented by a 3d vector $x,y,z$ called pose.

Another use of cinematics is to transpose the coordinates of a drone (local space) to the coordinates of the world (global space)

#example[
  For example if we have a drone that is flying in a room, we can use the cinematics to transpose the coordinates of the drone to the coordinates of the room. This is necessary because the drone needs to know where it is in the room in order to move around and avoid obstacles.
]

In robotics we can change the *frame of reference*. This is useful because we can represent the same point in different ways

#note[
  Each component of the robot usualy has its own frame of reference (the weels, the sensor). It's a rappresentation that we choose to use.
  // inserire immagine.
]

Why do we need to rappresent a component with is own frame of reference? Beacase a sensor returns data in its own frame of reference, and we need to transpose it to the global frame of reference in order to use it for navigation and control.

== Algebra of transformations

=== Frames

Or frame of reference. We assume two frames:
- GLobal frame: thw world, we can assume that the world is fixed it doesn't move. We can use it to represent the position of the robot in the world.

- Robot frame: the robot is a *rigid body*, a frame is rigidly attached to the robot.
  #warning()[
    A rigid body is a solid object that does not deform or change shape when subjected to forces. The Eucliadian distance between any two points never changes.
  ]
  Rigid attach means that the frame move with the robots.

== Vectors and matrix

A vector is a abstract elements wich belongs to a vector space. A vector space is a set of vectors that have some propriety:
- The sum of two vectors is a vectors itself
- The results of the sum is also in the vector space

We can see a vector as an object $v$ with two property: a direction and a magnitude:
- *Direction*
- *Magnitude or lenght*
- $v + u "and" alpha v$ still produce a vector in the same space.

#warning()[
  This propriety are not dipendent to the frame of reference, they are intrinsic to the vector itself.
]

*Coordinatr vector* $p in R^n$ (real number space, a vector is a tuple of $n$ real numbers) is an *ordered* list of numbers representing an abstract vector.

#warning()[
  The coordinates are relative to a frame of reference, they are not intrinsic to the vector itself. The same vector can have different coordinates in different frames of reference.
]

*Matrix* is a rectangular array of numbers (scalar). Typically a matrix as $n$ rows and $m$ columns, we can write it as $A in R^{n x m}$.

One of the most important operation is the *matrix multiplication* $C = A dot B$ where $A in R^{n x m}$, $B in R^{m x p}$ and $C in R^{n x p}$. The result of the multiplication is a matrix with $n$ rows and $p$ columns:
$
  c_(i,j) = sum_k a_(i,k) b_(k,j)
$
#warning()[
  The inner dimension of the two matrices *must be the same*, otherwise the multiplication is not defined.

  The product of two matrices is not commutative, in general $A dot B != B dot A$.
]
Each column of the result matrix can be seen as a *linear combination* of the columns of the first matrix $A$, where the coefficients of the linear combination are given by the corresponding column of the second matrix *B*.

The inverse of a matrix $A^{-1}$ is the matrix such that $A dot A^{-1} = I$ where $I$ is the identity matrix. The identity matrix is a square matrix with ones on the diagonal and zeros elsewhere.

=== Dor product

Dot product or inner product: the product between two vectors $u$ and $v$. The result is a scalar.

The scalar can be interpreted as the lenght of the $p'$ projection onto $q$, scaled by $q'$'s lenght:
$
  p dot q = ||p|| ||q|| cos(theta)
$
where $theta$ is the angle between the two vectors. The right part $p$ can be interpreted as the similarity between the two vectors, if the angle is small the dot product is large, if the angle is large the dot product is small:
- If $p dot q > 0$ the vectors have same direction
- If $p dot q = 0$ the vectors are orthogonal
- If $p dot q < 0$ the vectors have opposite direction

#warning()[
  This defination applies indipendently from the frame of reference, it is an intrinsic property of the vectors themselves.
]

If a rappresents $p$ and $q$ in a coordinate system, the dot product can be calculated with a trivial matrix multiplication:
$
  p dot q = p^T dot q =[p_x p_y p_z] dot [q_x q_y q_z]^T = p_x q_x + p_y q_y + p_z q_z
$
Vector are also itself a matrix, a column vector is a matrix with one column and $n$ rows, a row vector is a matrix with one row and $n$ columns.

#note()[
  When we introduce a coordinate system, we need to introduce a specific frame of reference. Now we can treat the vector as a mathematical object, we can do operations on it, but we need to be careful about the frame of reference we are using.
]

=== cross product

The cross product maps two vectors in $R^3$ to a vector in $p times q R^3$. The result is a vector that is *orthogonal* to both input vectors, and its magnitude is equal to the area of the parallelogram spanned by the two input vectors. The results as:
- Lenght: $||p|| ||q|| sin(theta)$
- Direction: follow the right hand rule (thumb is the direction of the cross product)
- if $p times q = 0$, they are parallel

Now we rappresent $p$ and $q$ as a list of numbers as a list of coordinates. we need to convert $p$ to a specific skew symmetric matrix (matrice antisimmetrica):
$
  [p] = [
    0, -p_z, p_y,
    p_z, 0, -p_x,
    -p_y, p_x, 0
  ]
$

=== Frames

A frame is defined by an origin and a set of basis vectors. The three vectors are not casual, they need to satisfy some propriety:

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
  Two robots in $O^'$ and $O^''$. we use two frames space $A$ and $B$. The same point $p$ in frame $A$ as coordinates $A_p$ = [6 2 2] mentre $B_p = [0 -1.4 ,0]$
]

=== Convertion

In order to convert the coordinates of a point from one frame to another, we need to use a *transformation*.

#warning()[
  I can't do this transformation if i don't know the relative position and orientation of the two frames. I need to know how the two frames are related to each other.
]

Suppose that $A$ is the word frame, and $B$ is the robot frame. Where:
- $A = O -x y z$
- $B = O' - x'y'z'$
We want to rappresent the position of B with respect to A. We need to know:
- The position of the origin of $B$. I can give the coordinates of $O'$ respect to $A$, $A_O'$.
- The orientation of $B$ respect to $A$. I can give the coordinates of the *basis vectors* of $B$ respect to $A$:
$
  (A_x', A_y', A_z')
$

Immagine we can collide the tho frame's origin, so the origin is the same, but the orientation is different. We can use the *end point* concept.

- what are the coordinates of $x'$ in $A$? If we responde to this question, we can draw the x' axes in the $A$ frame.

The dot product is the projection of a vector onto another vector, so we can use it to find the coordinates of $x'$ in $A$:
$
  A_x' = [x' dot x, x' dot y, x' dot z]
$
it's works because the $x'$ is a unit vector, so the dot product is equal to the projection of $x'$ onto $A_x$. Where $A_x'$ is also a unitary vector.

We can pak three coordinates of the basis vectors of $B$ respect to $A$ in a matrix, called *rotation matrix*:
$
  R = [
    A_x' dot x, A_x' dot y, A_x' dot z,
    A_y' dot x, A_y' dot y, A_y' dot z,
    A_z' dot x, A_z' dot y, A_z' dot z
  ]
$
it's describe how the frame $B$ is oriented respect to $A$.

*pose* is the joint rappresentation of the position and orientation of a frame. When we say the pose of a robot, we are talking about the position and orientation of the robot in the world, the frame rigthly attached to the robot.

In the *inverse rappresentation*  we only have swaped the two frame, we ask the inverse of the previous question: what are the coordinates of $x$ axis in $B$?
The rotation matrix are *transpose* of the previous one.
$
  R = R^T
$

#example[
  If we rappresent the pose of the frame $B$ in the frame $A$, we can also rappresent the point $p$ in the frame $A$. In the example there is no rotation between the two frame, so we only need to trasltate the origin of $B$ respect to $A$.

  the non rotation is a rotation itslef, the non rotation is the *identity matrix*: it's describe a $0$ degree rotation.

  So the position of point $p$ respect to $A$ is:
  $
    A_p = A_O' + B_= //aggiungre
  $
  We only sum vectors, it's just a traslation.
]

#example[
  in this example there is not traslation, the two frame have the same origin, but there is a rotation between the two frame.

  - we know that $B_p$ are the coordinates of $p$ in the frame $B$, we use the point of view of the robot:
  $
    B_p = [p_x, p_y, p_x] = p_x x^x'
  $
  the coordinates of $x^'$ are [1 0 0]. Expading the previous equation.

  - Immagine that we know the rotation matrix $R$ that describe the orientation of $B$ respect to $A$.

  $A_x'$ are the first columns of the rotation matrix, so


  in the final result (a column vector, so a point) we can see that each entry is a liner combination of the coordinate of the robot and the rotation matrix.
]


