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

*Coordinate vector* $p in R^n$ is an *ordered* list of numbers representing an abstract vector.

#warning()[
  The *coordinates are relative to a frame* of reference, they are not intrinsic to the vector itself. The same vector can have different coordinates in different frames of reference.
]

*Matrix* is a rectangular array of numbers (scalar). Typically a matrix has $m$ rows and $n$ columns, we can write it as:
$
  A in R^(n times m)
$
One of the most important operations is the *matrix multiplication*:
$
  C = A dot B "where"\
  A in R^(m times mr(k)), B in R^(mr(k) times n), C in R^(m times n)
$
The result of the multiplication is a matrix with $m$ rows and $n$ columns:
$
  c_(i,j) = sum_k a_(i,k) b_(k,j)
$
#warning()[
  The inner dimension of the two matrices *must be the same*, otherwise the multiplication is not defined.

  The product of two matrices is *not commutative*, in general $A dot B != B dot A$.
]

Each column of the result matrix can be seen as a *linear combination* of the columns of the first matrix $A$, where the coefficients of the linear combination are given by the corresponding column of the second matrix *B*:
$
  mat(
    mb(a), mb(b);
    c, d;
    e, f;
  ) times mat(
    mr(x), y, z;
    mr(h), k, w;
  ) = mat(
    mb(a) mr(x) + mb(b) mr(h), a y + b k, a z + b w;
    c x + d h, c y + d k, c z + d w;
    e x + f h, e y + f k, e z + f w;
  )
$

The *inverse* of a matrix $A^(-1)$ is the matrix such that:
$
  A dot A^(-1) = I
$
Where $I$ is the identity matrix. The identity matrix is a square matrix with ones on the diagonal and zeros elsewhere.

=== Dot product

*Dot product* or inner product: Is the *product between two vectors* $u$ and $v$. The result is a scalar $p dot q$.

The scalar can be interpreted as the length of the $p$ projection onto $q$, scaled by $q$'s length:
$
  p dot q = ||p|| ||q|| cos(theta)
$
where $theta$ is the angle between the two vectors.

#figure(
  cetz.canvas({
    import cetz.draw: *

    // Axes
    line((0, 0), (5, 0), stroke: black + 1pt) // q axis
    line((4.85, 0), (5, 0), stroke: black + 1pt)
    line((0, 0), (3.4, 2.05), stroke: black + 1pt)
    line((3.2, 1.9), (3.4, 2.05), stroke: black + 1pt)
    line((3.4, 1.9), (3.4, 2.05), stroke: black + 1pt)

    // Right angle at projection
    let px = 3.4
    let py = 2.05
    let offset = 0.2
    line((px - offset, 0), (px - offset, offset), stroke: black)
    line((px - offset, offset), (px, offset), stroke: black)

    // Dashed line from p to q axis
    line((px, py), (px, 0), stroke: (paint: black, dash: "dashed"))

    // Projection line on q axis
    line((0, -0.35), (px, -0.35), stroke: black + 0.8pt)
    line((0, -0.45), (0, -0.25), stroke: black + 0.8pt)
    line((px, -0.45), (px, -0.25), stroke: black + 0.8pt)

    // Labels
    content((3.6, 2.4), $p$, font: ("New Computer Modern", 9pt))
    content((-0.35, 0.2), $q$, font: ("New Computer Modern", 9pt))
    content((0.65, 0.2), $theta$, font: ("New Computer Modern", 8pt))
    content((1.7, -0.7), $||p|| cos(theta)$, font: ("New Computer Modern", 8pt))
    content((5.15, -0.35), $q$, font: ("New Computer Modern", 9pt))
  }),
  caption: "Dot product",
)

The right part *$p$* can be interpreted as the *similarity between the two vectors*, if the angle is small the dot product is large, if the angle is large the dot product is small:
- If $p dot q > 0$ the vectors have same direction ($theta < 90$)
- If $p dot q = 0$ the vectors are orthogonal ($theta = 90$)
- If $p dot q < 0$ the vectors have opposite direction ($theta > 90$)

#warning()[
  This definition applies independently from the frame of reference, it is an intrinsic property of the vectors themselves.
]

If we represent $p$ and $q$ in a coordinate system, the dot product can be calculated with a trivial matrix multiplication:
$
  p dot q = p^T dot q =[p_x p_y p_z] dot mat(q_x; q_y; q_z;) = p_x q_x + p_y q_y + p_z q_z
$
Vectors are also themselves a matrix, a column vector is a matrix with one column and $n$ rows, a row vector is a matrix with one row and $n$ columns.

#note()[
  *$ "Coordinate system" -> "Frame of reference" $*
  When we introduce a coordinate system, we need to introduce a specific frame of reference. Once we have introduced it, the vector can be threat as a mathematical object (we can do operations on it).
]

=== Cross product

#informally()[
  The cross product follow the *right hand rule*: if you point your index finger in the direction of $p$ and your middle finger in the direction of $q$, your thumb will point in the direction of $p times q$.
]

The cross product maps two vectors $p,q in R^3$ to a vector $p times q in R^3$. The result is a vector that is *orthogonal* to both input vectors, and its magnitude is equal to the area of the parallelogram spanned by the two input vectors.


#figure(
  cetz.canvas({
    import cetz.draw: *

    let qx = 1.2
    let qy = 0.8
    let px = 3.5
    let py = 0
    let offset = 0.2

    // Axes
    line((0, 0), (0, 3), stroke: black + 1pt)
    line((0, 0), (4.5, 0), stroke: black + 1pt)

    // Arrow heads
    line((0, 2.9), (0, 3), stroke: black + 1pt)
    line((-0.08, 3), (0.08, 3), stroke: black + 1pt)
    line((4.4, 0), (4.5, 0), stroke: black + 1pt)

    // Parallelogram outline with fill effect
    line((0, 0), (px, py), stroke: black + 1pt)
    line((px, py), (qx + px, qy + py), stroke: black + 1pt)
    line((qx + px, qy + py), (qx, qy), stroke: black + 1pt)
    line((qx, qy), (0, 0), stroke: black + 1pt)

    // Vector q
    line((0, 0), (qx, qy), stroke: black + 1.2pt)

    // Vector p
    line((0, 0), (px, py), stroke: black + 1.2pt)
    // Labels
    content((0.5, 2.5), $p times q$, font: ("New Computer Modern", 9pt))
    content((0.6, 0.8), $q$, font: ("New Computer Modern", 9pt))
    content((3.5, -0.35), $p$, font: ("New Computer Modern", 9pt))
    content((2.2, 0.5), $||p times q||$, font: ("New Computer Modern", 9pt))
  }),
  caption: "Cross product magnitude as parallelogram area",
)


The result is:
- Length: $||p|| ||q|| sin(theta)$ (tje area of the parallelogram formed by $p$ and $q$)

- Direction: follow the right hand rule

- if $p times q = 0$, they are *parallel*

Now we represent $p$ and $q$ as a list of numbers (coordinates).  The cross product can be calculated with a specific formula:
$
  p times q = [p]q
$
where $[p]$ is a skew symmetric matrix (matrice antisimmetrica):
$
  [p] = mat(
    0, -p_z, p_y;
    p_z, 0, -p_x;
    -p_y, p_x, 0;
  )
$

=== Frames

A frame is defined by an *origin* and a set of *basis vectors*. The three vectors (bases) are not arbitrary, they need to satisfy some property:

- *orthonormality*:
  - $x dot x = 1, y dot y = 1, z dot z = 1$. This property means that the basis vectors have a length of 1, they are *unit vectors*

  - $x dot y = 0, x dot z = 0, y dot z = 0$. Their norm is $90$ degrees. The basis vectors are *orthogonal* to each other, they are perpendicular to each other

- *right hand rule*: the frame is right-handed if the basis vectors satisfy the right-hand rule:
  - $x times y = z$ (the cross product of $x$ and $y$ gives $z$, the perpendicular vector to the plane formed by $x$ and $y$)
  - $y times z = x$
  - $z times x = y$

  #note()[
    The right hand rule is a convention, we can also have left-handed frames (the direction of the $z$ axis change). In robotics we usually use right-handed frames, but it's not a strict rule.
  ]

=== Coordinates

A point $p$ is represented by its $n$ coordinates in a specific frame of reference.

#warning()[
  The coordinates of a point are *relative to the frame of reference*, they are not intrinsic to the point itself. The same point can have different coordinates in different frames of reference.
]

We wirte *$""^A p$* to indicate the vector whose components are the coordinates of the point $p$ in the frame $A$.

#example()[
  Suppose that we have two robots, wich one is in the frame $O^'$ and the other is in the frame $O^''$. We use two frames space $A$ and $B$.

  The same point $p$ in frame $A$ has coordinates $A_p$ = [6 2 2] while $B_p = [0 -1.4 ,0]$.

  #figure(
    cetz.canvas({
      import cetz.draw: *
      // ===== FRAME A (Left) =====
      let ox_a = 0
      let oy_a = 0.5

      // Axes for Frame A
      line((ox_a, oy_a), (ox_a + 2, oy_a), stroke: black + 1pt) // x' axis
      line((ox_a, oy_a), (ox_a, oy_a + 2.5), stroke: black + 1pt) // z' axis
      line((ox_a, oy_a), (ox_a + 1.5, oy_a - 0.8), stroke: black + 1pt) // y' axis

      // Arrow heads for Frame A
      line((ox_a + 1.95, oy_a), (ox_a + 2, oy_a), stroke: black + 1pt)
      line((ox_a + 2, oy_a - 0.08), (ox_a + 2, oy_a + 0.08), stroke: black + 1pt)
      line((ox_a, oy_a + 2.45), (ox_a, oy_a + 2.5), stroke: black + 1pt)
      line((ox_a - 0.08, oy_a + 2.5), (ox_a + 0.08, oy_a + 2.5), stroke: black + 1pt)

      // Point p in Frame A
      let px_a = ox_a + 1.3
      let py_a = oy_a + 1.7
      circle((px_a, py_a), radius: 0.1, fill: red, stroke: none)

      // Vector from O to p (A_p)
      line((ox_a, oy_a), (px_a, py_a), stroke: black + 1.5pt)

      // Labels for Frame A
      content((ox_a - 0.25, oy_a - 0.25), $O$, font: ("New Computer Modern", 10pt))
      content((ox_a + 2.15, oy_a - 0.25), $x'$, font: ("New Computer Modern", 10pt))
      content((ox_a - 0.35, oy_a + 2.6), $z'$, font: ("New Computer Modern", 10pt))
      content((ox_a + 1.6, oy_a - 1), $y'$, font: ("New Computer Modern", 10pt))
      content((px_a - 0.15, py_a + 0.25), $p$, font: ("New Computer Modern", 10pt))
      content((ox_a + 1, oy_a + 0.8), $A_p$, font: ("New Computer Modern", 9pt))

      // ===== FRAME B (Right) =====
      let ox_b = 3.2
      let oy_b = 2.2

      // Axes for Frame B
      line((ox_b, oy_b), (ox_b + 2, oy_b), stroke: black + 1pt) // x' axis
      line((ox_b, oy_b), (ox_b, oy_b + 2.5), stroke: black + 1pt) // z' axis
      line((ox_b, oy_b), (ox_b + 1.5, oy_b - 0.8), stroke: black + 1pt) // y' axis

      // Arrow heads for Frame B
      line((ox_b + 1.95, oy_b), (ox_b + 2, oy_b), stroke: black + 1pt)
      line((ox_b + 2, oy_b - 0.08), (ox_b + 2, oy_b + 0.08), stroke: black + 1pt)
      line((ox_b, oy_b + 2.45), (ox_b, oy_b + 2.5), stroke: black + 1pt)
      line((ox_b - 0.08, oy_b + 2.5), (ox_b + 0.08, oy_b + 2.5), stroke: black + 1pt)

      // Point p in Frame B (same point, closer to origin)
      let px_b = ox_b + -1.9
      let py_b = oy_b + 0.0
      circle((px_b, py_b), radius: 0.1, fill: black, stroke: none)

      // Vector from O'' to p (B_p)
      line((ox_b, oy_b), (px_b, py_b), stroke: black + 1.5pt)

      // Dashed line connecting the two points
      line((px_a, py_a), (px_b, py_b), stroke: (paint: black, dash: "dashed"))

      // Labels for Frame B
      content((ox_b - 0.35, oy_b - 0.25), $O''$, font: ("New Computer Modern", 10pt))
      content((ox_b + 2.15, oy_b - 0.25), $y'$, font: ("New Computer Modern", 10pt))
      content((ox_b - 0.35, oy_b + 2.6), $z''$, font: ("New Computer Modern", 10pt))
      content((ox_b + 1.6, oy_b - 1), $x''$, font: ("New Computer Modern", 10pt))
      content((ox_b - 0.3, oy_b + 0.3), $B_p$, font: ("New Computer Modern", 9pt))
    }),
    caption: "Coordinate transformation between two frames",
  )
]

In order to convert the coordinates of a point from one frame to another, we need to use a *transformation*.

#warning()[
  The transformation can't be performed if we don't know the relative position and orientation of the two frames: we need to *know how the two frames are related to each other*.
]

Suppose that we have two frames, where: $A$ is the world frame, and $B$ is the robot frame. Where:
- $A = O -x y z$
- $B = O' - x'y'z'$

We want to represent the position of $B$ with respect to $A$. To achive this goal, we need to know:
- The *position of the origin* of $B$: coordinates of $O'$ respect to $A$, $""^A O'$.

- The *orientation* of $B$ respect to $A$: coordinates of the *basis vectors* of $B$ respect to $A$:
$
  (""^A x', ""^A y', ""^A z')
$

Imagine that we can *collide the two frame's origin*, so the origin is the same, but the orientation is different. We can use the *end point* concept. The end point of a vector $v$ is the point that we get by starting from the origin and following the direction and magnitude of $v$. If we know the coordinates of the end point of $x'$ in $A$, we can draw the $x'$ axis in the $A$ frame.\
The dot product is the projection of a vector onto another vector, so we can use it to find the coordinates of $x'$ in $A$:
$
  ""^A x' = mat(x' dot x; x' dot y; x' dot z;)
$
#note()[
  This formula *works because the $x'$ is a unit vector*, so the dot product is equal to the projection of $x'$ onto $""^A x$. Where $""^A x'$ is also a unitary vector.
]

We can pack the three coordinates of the basis vectors of $B$ respect to $A$ in a matrix, called *rotation matrix*:
$
  ""^A_B R = mat(
    x' dot x, y' dot x, z' dot x;
    x' dot y, y' dot y, z' dot y;
    x' dot z, y' dot z, z' dot z;
  )
$
it describes how the frame $B$ is oriented respect to $A$.

The *pose* is the joint representation of the *position and orientation of a frame*. When we say _the pose of a robot_, we are talking about the position and orientation of the robot in the frame rigidly attached to the robot.

In the *inverse representation* we only have swapped the two frame name; is the inverse of the previous question: what are the coordinates of $x$ axis in $B$?
The rotation matrix is *transpose* of the previous one.
$
  R = R^T
$

During this conversion, two case can happen:
- *No rotation*: the two frame have the same orientation, but different origin.
- *Rotation*: the two frame have the same origin, but different orientation.

==== No rotation (End point)



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


