#import "../template.typ": *

The Euler thoerem states that we can represent *any rotation* with an angle $theta$ and a rotation axis $r$. The rotation can be described as:
$
  theta, r = mat(r_x; r_y; r_z)
$
where $r$ is an axis (represented as a vector) and $theta$ is the angle of rotation.

With *quaternions* the most intuitive way to represent a rotation is mapping the angle of rotation to the real part of the quaternion and the axis of rotation to the imaginary part of the quaternion. So we can represent a rotation with a quaternion, where:
- a = theta
- b = $r_x$
- c = $r_y$
- d = $r_z$
But with this representation we are *not enforcing the fact that it is a unit quaternion*, so we need to normalize it. The final representation of the rotation is:
$
  q = mr(a) + mb(b) i + mg(c) j + mp(d) k\
  mr(a) = cos(theta/2), mb(b) = r_x sin(theta/2), mg(c) = r_y sin(theta/2), mp(d) = r_z sin(theta/2)
$

We need to preserve unit quaternions, even when we operate with them, so we need to normalize them.

#informally()[
  This representation gives me $r_x, r_y, r_z$ in terms of quaternions.
]
Our rotation will be represented by the unit quaternion as:
$
  q = mr(cos(theta/2)) + mb(r_x sin(theta/2)) i + mg(r_y sin(theta/2)) j + mp(r_z sin(theta/2)) k \
  mat(mr(cos(theta/2)); mb(r_x sin(theta/2)); mg(r_y sin(theta/2)); mp(r_z sin(theta/2)))
$

#note()[
  The final vector represents an *arbitrary rotation*. It also includes elementary rotations.
]

== Operations with quaternions

Suppose that $q = mat(a; b; c; d)$ is a unit quaternion, then the following properties hold:

- We can represent the same rotation with a *rotation matrix $R$*. There is a relation between the two:
$
  R = mat(
      2(a^2 + b^2) - 1, 2(b c - a d), 2(a c + b d);
      2(a d + b c), 2(a^2 + c^2) - 1, 2(c d - a b);
      2(b d - a c), 2(a b + c d), 2(a^2 + d^2) - 1
  )
$

  #warning()[
    It is *always possible to convert* one parameterization of a rotation into another, but some parameterizations are more compact and easier to use than others.
  ]

- From a quaternion we can also *extract the angle of rotation* and the *axis of rotation*:
$
  theta &= 2 "arccos"(a)\
  r &= mat(b / sin(theta/2); c / sin(theta/2); d / sin(theta/2))
$

- The *identity matrix* represents a *non-rotation*. I can express a non-rotation with a quaternion in this way:
  $
    q = mat(1; 0; 0; 0)
  $

- The inverse of a rotation matrix $R$ is its transpose $R^T = R^(-1)$. The *inverse of a quaternion* is just the conjugate (we only invert the sign of the imaginary part):
$
  q^* => "inverse rotation"
$

- *Addition* and *Multiplication* of quaternions. We can threat them as a polynomial with coefficients $a, b, c, d$ and variables $1, i, j, k$. The addition is just the sum of the coefficients, while the multiplication is more complicated because we need to take into account the properties of the imaginary units.

=== Rotaiting a point

Suppose that we have a point $p = mat(p_x;p_y;p_z)$ and a rotation represented by a quaternion $q = a + b i + c j + d k$. To apply the rotation to the point $p$ we need to do the following steps:

- *Conversion*: we need to convert the point $p$ into a quaternion, because the rotation is represented by a quaternion. A point is represented with a *pure quaternion*, where only the real part is $0$:
$
  p = mr(0) + p_x i + p_y j + p_z k
$

- *Rotation*: now that we have converted the point, we can apply the rotation to it. This operation is called *sandwich product*:
$
  p' = mr(q) p mr(q^*)
$

- Finnaly, we can extract the coordinates of the rotated point $p'$ from the quaternion, because the real part is $0$:
$
  p' = mat(p'_x; p'_y; p'_z)
$


=== Composition of rotations

Suppose that we have two rotation matrices $R_1$ and $R_2$ and we want to *compose them*. We can do this by multiplying them.

#warning()[
  When we compose rotations we need to be careful about the *order of composition*, because it is *not commutative*. $R_1 R_2$ is not the same as $R_2 R_1$.

  If $R_2$ describes a rotation in the fixed frame (instead of the moving frame), then I need to pre-multiply it, so $R = R_2 R_1$.
]

In the quaternion world, the *composition* of two rotations is just the multiplication of the two quaternions:
- $q_"new" = q_2 q_1$ rotation about *fixed axes*

- $q_"new" = q_1 q_2$ rotation about *moving axes*

== Interpolation of rotations

Quaternions are very useful in robotics because they allow us to represent rotations in a compact way and also for send them over the network. With a rotation matrix we need to send $9$ numbers, while with a quaternion we only need to send $4$ numbers. This is a huge saving of bandwidth, especially when we need to send many rotations (for example, in a robot with many joints).

The main disadvantage of quaternions is that they are not very intuitive to understand and they have some singularities (for example, when the angle of rotation is $180$ degrees, the quaternion is not well defined). However, they are still widely used in robotics because of their compactness and efficiency.

Suppose that we need to *rotate an object* from a position $R_1$ to a position $R_2$. We know the description of the initial and final rotation, but we need to find a way to do it. We need to find a sequence of rotations (*path*) that will take us from $R_1$ to $R_2$.

Suppose that we use three angles (*Euler angles*) to represent the rotation. I can describe the transition using *linear interpolation*:
$
  v_alpha = v_i + alpha(v_f - v_i), alpha in [0,1]
$
where:
- *$v_i$* is the initial vector
- *$v_f$* is the final vector
- *$alpha$* is a parameter that goes from $0$ to $1$ and represents the progress of the interpolation. If $alpha = 0$ I'm in the initial position, if $alpha = 1$ I'm in the final position.

#warning()[
  This trajectory seems to be a good solution, but it is not the best one because it does not follow the shortest path between the two rotations.
]

The shortest path between two rotations is not a linear interpolation of the angles, but a *spherical linear interpolation* (slerp). The slerp is defined as:

- Unit quaternions form a *$4$-dimensional unit sphere*: $ ||q|| = sqrt(a^2 + b^2 + c^2 + d^2) = 1$, so each unit quaternion is a point on the surface of a $4$-dimensional sphere.

- *SLERP*: shortest path between two points on a sphere is an arc of a circle.

#note()[
  It could happen that the intermediate rotation changes the axis of rotation, but this is not a problem because the slerp always follows the shortest path between the two rotations.
]

#example()[
  The shortest trajectory followed by a plane in 2D is not a straight line, but an arc of a circle. This is because on a sphere the shortest path between two points is an arc of a circle, not a straight line.
]

=== Rototranslation

Suppose that we have two reference frames, one attached to the robot $mr(B)$ and one fixed in the environment ($A$). The robot is moving in the environment, so it is translated and rotated with respect to the reference frame $A$.

We want to express the coordinates of a point $mb(p)$ (robot frame) in a reference frame $A$. 

#figure(
  cetz.canvas({
    import cetz.draw: *

    // Origin of frame A
    let oax = 0
    let oay = 0

    // Origin of frame B as seen from A
    let obx = 1.0
    let oby = 1.2

    // Shared point p in space
    let px = 4.4
    let py = 2.2

    // Axes of frame A (black)
    line((oax, oay), (2.1, 0), stroke: black + 1.3pt) // x
    line((oax, oay), (0, 2.3), stroke: black + 1.3pt) // z
    line((oax, oay), (1.4, 1.0), stroke: black + 1.2pt) // y

    // Arrow heads for frame A
    line((2.0, -0.07), (2.1, 0), stroke: black + 1.3pt)
    line((2.0, 0.07), (2.1, 0), stroke: black + 1.3pt)
    line((-0.07, 2.2), (0, 2.3), stroke: black + 1.3pt)
    line((0.07, 2.2), (0, 2.3), stroke: black + 1.3pt)
    line((1.32, 0.92), (1.4, 1.0), stroke: black + 1.2pt)
    line((1.35, 0.88), (1.4, 1.0), stroke: black + 1.2pt)

    // Axes of frame B (red)
    line((obx, oby), (2.4, 0.95), stroke: red + 1.3pt) // x'
    line((obx, oby), (3.1, 1.85), stroke: red + 1.3pt) // y'
    line((obx, oby), (1.65, 2.95), stroke: red + 1.3pt) // z'

    // Arrow heads for frame B
    line((2.28, 0.98), (2.4, 0.95), stroke: red + 1.3pt)
    line((2.31, 0.88), (2.4, 0.95), stroke: red + 1.3pt)
    line((2.98, 1.80), (3.1, 1.85), stroke: red + 1.3pt)
    line((3.01, 1.72), (3.1, 1.85), stroke: red + 1.3pt)
    line((1.60, 2.83), (1.65, 2.95), stroke: red + 1.3pt)
    line((1.74, 2.84), (1.65, 2.95), stroke: red + 1.3pt)

    // Translation from A origin to B origin
    line((oax, oay), (obx, oby), stroke: purple + 1pt)

    // Approximate robot body at O'
    circle((obx, oby), radius: 0.14, fill: luma(170), stroke: luma(120))

    // Point p
    circle((px, py), radius: 0.1, fill: rgb("6f9ec9"), stroke: none)

    // Position vectors
    line((oax, oay), (px, py), stroke: blue + 1.1pt)
    line((obx, oby), (px, py), stroke: red + 1.1pt)

    // Labels frame A
    content((2.2, -0.22), $x$, font: ("New Computer Modern", 10pt))
    content((1.52, 1.08), $y$, font: ("New Computer Modern", 10pt))
    content((-0.25, 2.35), $z$, font: ("New Computer Modern", 10pt))

    // Labels frame B
    content((2.5, 0.75), $x'$, font: ("New Computer Modern", 10pt), fill: red)
    content((1.55, 1.72), $y'$, font: ("New Computer Modern", 10pt), fill: red)
    content((1.62, 3.08), $z'$, font: ("New Computer Modern", 10pt), fill: red)

    // Origin labels and vectors
    content((-0.22, -0.28), $O$, font: ("New Computer Modern", 10pt))
    content((obx - 0.30, oby - 0.0), $O'$, font: ("New Computer Modern", 10pt))
    content((0.32, 0.67), $""^A mp(O')$, font: ("New Computer Modern", 6pt), fill: purple)

    // Point and coordinate labels
    content((px + 0.35, py + 0.05), $p$, font: ("New Computer Modern", 10pt))
    content((1.8, 0.5), $""^A p$, font: ("New Computer Modern", 9pt), fill: blue)
    content((2.7, 1.95), $""^B p$, font: ("New Computer Modern", 9pt), fill: red)
  }),
  caption: "Rototranslation between frame A and frame B",
)

The robot is also translated and rotated. I need to do a rototranslation (translation + rotation). To do this I need these mathematical operations:
- The *translation* between origins. A point $""^A 0'$ describes the position of the origin of the robot frame in the reference frame $A$.

- The *rotation* between the two frames. I can use a rotation matrix $""^A_B R$ to describe the rotation between the two frames (how the red axes are rotated with respect to the black axes). The components of the matrix are:
$
  ""^A x', ""^A y', ""^A z'
$

The translation followed by the rotation is called *forward kinematics*:
$
  ""^A p = ""^A_B R ""^B p + ""^A 0'
$

But with this representation we represent the point $p$ with 3 coordinates, and the translation direction is also a vector (3 coordinates), so we need to represent it with 3 coordinates as well. So we have 9 coordinates to represent the position of the point $p$ in the reference frame $A$. I need to remember the interpretation of the object.

We can do better: we can represent the rototranslation with a single mathematical object.

*Problem*: is there a way to do rototranslation with only one operation and represent it with a single mathematical object? Yes, we can use the *homogeneous transformation*.

== Homogeneous coordinates

The point $p$ is represented with three coordinates:
$
  p = mat(p_x; p_y; p_z)
$
But we can represent the same point with homogeneous coordinates:
$
  p = mat(p_x; p_y; p_z; mr(1))
$
#note()[
  The fourth component should be $1$ to represent a point; if it is $0$ we represent a vector.
]
If we want to represent a direction the $4$ coordinate should be $0$:
$
  x = mat(x_x; x_y; x_z; mr(0))
$

#note()[
  We add a fourth coordinate to distinguish between points and vectors.
]

The rototranslation changes in this way:
- Translation: we obtain a 4-dimensional vector $""^A 0' = mat(""^A 0'_x; ""^A 0'_y; ""^A 0'_z; mr(1))$

- Rotation: if I pack everything together I obtain a square matrix $4 times 4$, which has useful properties:
  $
    mat(x_1, y_1, z_1, 0; y_1, y_2, y_3, 0; z_1, z_2, z_3, 0; t_x, t_y, t_z, 1)
  $
  #note()[
    The last row is always $0, 0, 0, 1$ because we need to preserve the homogeneous coordinates.
  ]
  In the rotation matrix I recognize the pattern: where delta is the translation. I can write the rotation matrix as:
  $
    mat(""^A_B R, ""^A 0'; 0, 1)
  $
//riguardare perchè

The transformation matrix is a single $4 times 4$ matrix expressing both the rotation and the translation (any rototranslation).

=== Rototraslation of points

Assume that we have a point $""B^p$ and a transformation matrix $""^A_B T$. What happens if we multiply the transformation matrix by the point:
$
  ""^A p &= ""^A_B T ""^B p\
  &= mat(x_1, y_1, z_1, 0; y_1, y_2, y_3, 0; z_1, z_2, z_3, 0; t_x, t_y, t_z, 1) mat(p_x; p_y; p_z; 1)\
  &= mat(x_1 p_x + y_1 p_y + z_1 p_z + t_x; x_2 p_x + y_2 p_y + z_2 p_z + t_y; x_3 p_x + y_3 p_y + z_3 p_z + t_z; 1)
$
The result is a $4 times 1$ vector, with last coordinate equal to $1$. I can observe that I can simplify the formula as:
$
  mat(""^A_B R, ""^A 0'; 0, 1) mat(p_x; p_y; p_z; 1) = mat(""^A_B R ""^B p + ""^A 0'; 1)
$
I just need one single matrix product, and I can do it in a very efficient way.

=== Rototraslation of directions
//riguardare
Assume that we have a direction $""B^x$ and a transformation matrix $""^A_B T$. What happens if we multiply the transformation matrix by the direction:
$
  ""^A x & = ""^A_B T ""^B x' \
         & = mat(""^A_B R ""^B x'; 0)
$

=== Transformation multiple point

#example()[
  Point cloud obtained by a range sensor mounted on the robot. The red points are the points provided by the robot (they are in the robot reference frame).
]

For each point $p_i$ I only need to do a single matrix product to transform it into the reference frame $A$ (I suppose I have the transformation matrix $""^A_B R$). But with this solution I need to do $N$ matrix products, where $N$ is the number of points.

The solution is to pack all the points into a single matrix, so I can do a single matrix product to transform all the points together:
/*
$
  mat(p_1, p_2, ..., p_N) = mat(p_{1x}, p_{2x}, ..., p_{Nx}; p_{1y}, p_{2y}, ..., p_{Ny}; p_{1z}, p_{2z}, ..., p_{Nz}; 1, 1, ..., 1)
$*/
I multiply the transformation matrix $4 times 4$ and the matrix of points $4 times N$, and I obtain a $4 times N$ matrix that represents all the points in the reference frame $A$.

== Transformation of matrix

I also have the composition rule:
$
  ""^0_M T = ""0_1T ""^1_2 T ... ""^{m-1}_m T
$

This is useful because in a robot I usually have a frame of reference for each joint and a principal frame for movement, so I can use the composition rule to find the transformation matrix between the base of the robot and the end effector.

Usually I know the transformation matrix between one frame and the next one, so I can use the composition rule to find the transformation matrix between the base of the robot and the end effector.

#example()[
  If I have a camera, the robot tells me the position of a mug in the coordinates of the camera frame, but I need to know the position of the mug in the robot frame to grasp it. I can use the composition rule to find the transformation matrix between the camera frame and the robot frame, so I can transform the position of the mug into the robot frame.

  Using the cancellation rule:
  $
    w_p_"Mug" = ""^W_7 ""^7 p_"Mug" = ""^W_0 ""^0_1 T ... ""^6_7 T ""^7 p_"Mug" = ""^W T dot ""^7 p_"Mug"
  $
]

== TF Trees

A robot typically has many frames of reference, one for each joint and one for the end effector. Each frame is rigidly attached to the robot.

The problem is being able to calculate the transformation matrix between any two frames of reference. One simple solution is to store a transformation matrix for each pair of frames, but this solution is not scalable because the number of pairs grows quadratically with the number of frames.

The solution is to store only a subset of the transformation matrices, and obtain the others by composition. _For example_, if I have a robot with $n$ joints, I can store the transformation matrix between the base of the robot and each joint, and then use the composition rule to find the transformation matrix between any two joints.

To achieve that we use a *tf tree*, a tree that represents the frames of reference and the transformations between them, where:
- *Nodes* represent the frames of reference
- *Edges* (oriented) represent the relative pose of the child frame with respect to the parent frame (transformation matrix)
  $
    A -> B = ""^A_B T
  $
the transformation matrix that transforms the coordinates of a point from frame $B$ to frame $A$.

//aggiungere immagine tf tree

In this image, what is the transformation of $G$ with respect to $H$?
- I need to check if there is a path between $G$ and $H$ (reverse paths are also OK)
#warning()[
  I always need a *connecting tree* (spanning tree) to be able to find the transformation between any two frames. If there is a frame that is not connected to the rest of the tree, I will not be able to find the transformation between that frame and the other frames.
]

- During the check I need to keep track of the direction of the edges.

- I need a way to represent the inverse transformation, because if I have an edge $A -> B$ I can use it to find the transformation between $B$ and $A$ by inverting the transformation matrix.

  Given $""^A_B T$, how do I obtain $""^B_A T$? I can use the inverse of the transformation matrix:
  $
    ""^B_A T = (""^A_B T)^(-1) = mat(""^A_B R^T, -""^A_B R^T ""^A 0'; 0, 1)
  $

- If the arc is traversed upwards (from child to parent) I need to invert the transformation matrix; if the arc is traversed downwards (from parent to child) I can use the transformation matrix as it is.

$
  ""H_G T = ""^H_F T ""^F_C T ""^C_A T ""^A_B T ""^B_G T
$

