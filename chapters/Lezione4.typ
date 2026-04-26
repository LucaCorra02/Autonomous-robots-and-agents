#import "../template.typ": *

A *quaternion* is a mathematical concept that acts as a generalization of a complex number. They are widely used because they have *no singularities* (unlike Euler angles) and are incredibly compact, making them great for storage and transmission.

The Euler theorem states that we can represent *any rotation* with an angle $theta$ and a rotation axis $r$. The rotation can be described as:
$  theta, r = mat(r_x; r_y; r_z) $
where $r$ is an arbitrary axis (represented as a unit vector) and $theta$ is the angle of rotation around that axis.

With *quaternions* the most intuitive way to represent a rotation is mapping the angle of rotation to the real part of the quaternion and the axis of rotation to the imaginary part of the quaternion. So we can represent a rotation with a quaternion, where:
- a = $theta$
- b = $r_x$
- c = $r_y$
- d = $r_z$

But with this representation we are *not enforcing the fact that it is a unit quaternion*, so we need to normalize it. 

#note()[
  Because we enforce the length to be $1$, we are essentially choosing the dimensions on the surface of a $4D$ sphere. Since the length is $1$, we don't even need the square root in the magnitude formula.
]

The final representation of the rotation is:
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
  theta & = 2 "arccos"(a) \
      r & = mat(b / sin(theta/2); c / sin(theta/2); d / sin(theta/2))
$

- The *identity matrix* represents a *non-rotation*. I can express a non-rotation with a quaternion in this way:
  $
    q = mat(1; 0; 0; 0)
  $

- The inverse of a rotation matrix $R$ is its transpose $R^T = R^(-1)$. The *inverse of a quaternion* is just the conjugate (we only invert the sign of the imaginary part, which is analogous to transposing the matrix):
$  q^* => "inverse rotation"$

- *Addition* and *Multiplication* of quaternions. We can treat them as a polynomial with coefficients $a, b, c, d$ and variables $1, i, j, k$. The addition is just the sum of the coefficients. The multiplication combines the rotations, although quaternion algebra can be a bit tedious manually because of the properties of the imaginary units.

=== Rotating a point

Suppose that we have a point $p = mat(p_x; p_y; p_z)$ and a rotation represented by a quaternion $q = a + b i + c j + d k$. To apply the rotation to the point $p$ we need to do the following steps:

- *Conversion*: we need to convert the point $p$ into a quaternion, because the dimensions do not allow us to multiply a 3D point directly. A point is represented with a *pure quaternion*, where only the real part is $0$ (this is not a unit quaternion):
$  p = mr(0) + p_x i + p_y j + p_z k $

- *Rotation*: now that we have converted the point, we can apply the rotation to it. This operation is called the *sandwich product* (the point is surrounded by $q$ and its conjugate):
$  p' = mr(q) p mr(q^*) $

- Finally, we can extract the coordinates of the rotated point $p'$ from the resulting quaternion, because the real part remains $0$:
$  p' = mat(p'_x; p'_y; p'_z) $


=== Composition of rotations

Suppose that we have two rotation matrices $R_1$ and $R_2$ and we want to *compose them*. We can do this by multiplying them.

#warning()[
  When we compose rotations we need to be careful about the *order of composition*, because it is *not commutative*. $R_1 R_2$ is not the same as $R_2 R_1$.

  If $R_2$ describes a rotation in the fixed frame (instead of the moving frame), then I need to pre-multiply it, so $R = R_2 R_1$.
]

In the quaternion world, the *composition* of two rotations is just the multiplication of the two quaternions (pre- and post-multiply rules apply here too):
- $q_"new" = q_2 q_1$ rotation about *fixed axes*

- $q_"new" = q_1 q_2$ rotation about *moving axes*

== Interpolation of rotations

Quaternions are very useful in robotics because they allow us to represent rotations in a compact way and also for sending them over networks. With a rotation matrix we need to send $9$ numbers, while with a quaternion we only need to send $4$ numbers. This is a huge saving of bandwidth, and they are excellent for interpolation.

Suppose that we need to *rotate an object* from an initial position $R_1$ to a final position $R_2$. We know the description of the initial and final rotation, but we still have to go through the intermediate rotations; we have to compute a path.

Suppose that we use three angles (*Euler angles*) to represent the rotation. I can describe the transition using *linear interpolation*:
$  v_alpha = v_i + alpha(v_f - v_i), alpha in [0,1] $
where:
- *$v_i$* is the initial vector
- *$v_f$* is the final vector
- *$alpha$* is a parameter that goes from $0$ to $1$. If $alpha = 0$ I'm in the initial position, if $alpha = 1$ I'm in the final position.

#warning()[
  This trajectory seems to be a good solution, but it is not the best one because it does not follow the shortest path between the two rotations.
]

The shortest path between two rotations is a *spherical linear interpolation* (slerp). Each point on the interpolated line is a valid quaternion. The slerp is defined as:

- Unit quaternions form a *$4$-dimensional unit sphere*: $||q|| = sqrt(a^2 + b^2 + c^2 + d^2) = 1$, so each unit quaternion is a point on the surface of a $4$-dimensional sphere.

- *SLERP*: shortest path between two points on a sphere is an arc of a circle. It gives a very smooth interpolation and is super easy to compute.

#note()[
  Robots that move using this interpolation are much more predictable in their physical movements!
]

#example()[
  The shortest trajectory followed by a plane in 2D is not a straight line, but an arc of a circle. This is because on a sphere the shortest path between two points is an arc of a circle, not a straight line.
]

== Homogeneous coordinates

=== The problem of rototranslation

Suppose that we have two reference frames, one attached to the robot $mr(B)$ and one fixed in the environment ($A$). The robot is moving in the environment, so it is translated and also rotated with respect to the reference frame $A$.

We want to express the coordinates of a point $mb(p)$ (robot frame) in a reference frame $A$ ($""^A p$).

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
    content((0.32, 0.67), $mp(""^A O')$, font: ("New Computer Modern", 6pt), fill: purple)

    // Point and coordinate labels
    content((px + 0.35, py + 0.05), $p$, font: ("New Computer Modern", 10pt))
    content((1.8, 0.5), $""^A p$, font: ("New Computer Modern", 9pt), fill: blue)
    content((2.7, 1.95), $""^B p$, font: ("New Computer Modern", 9pt), fill: red)
  }),
  caption: "Rototranslation between frame A and frame B",
)

As we can see in the figure, the robot frame of reference $B$ is translated and rotated  (*rototranslation*) with respect to the reference frame $A$. To achive that we need to perform two operations:

- The *translation between origins*. A point $mp(""^A 0')$ describes the translation between the origins.

- The *rotation* between the two frames. I can use a rotation matrix $""^A_B R$ to describe the rotation between the two frames (how the red directions are rotated with respect to the black directions). The components of the matrix are:
  $
    ""^A x', ""^A y', ""^A z'
  $

  The final formula is:
  $
    ""^A p = underbrace(""^A 0', "translation") + underbrace(""^A_B R ""^B p, "rotation")
  $

This is a good solution, but it is *not very efficient*. We have one transformation to represent, but we are using 2 distinct mathematical elements (point and rotation matrix). We need to solve two $mr("problems")$:

- In this case, *points and directions are treated differently*, because the translation only applies to points, while the rotation applies to both points and directions. They are built the same way (three components), but act differently.

- We want a way to represent both components of the rototranslation (translation and rotation) in a single mathematical object.

=== Homogeneous coordinates: the solution

The main idea is to add a constant *fourth coordinate* as a flag, so we can represent both the translation and the rotation with a single vector:

- *Points*: The point $p$ is represented now with homogeneous coordinates, where the fourth coordinate is $1$. If I encounter a 4D vector ending in 1, I know it's a point:
  $
    p = mat(p_x; p_y; p_z) => p = mat(p_x; p_y; p_z; mr(1))
  $

- *Directions*: Same story, but we add a $0$ at the bottom:
  $
    x = mat(x_1; x_2; x_3) => x = mat(x_x; x_y; x_z; mr(0))
  $

#note()[
  The fourth component should be $1$ to represent a point; if it is $0$ we represent a direction.
]

The *rototranslation* changes in this way:

- *Translation*: we obtain a $4$-dimensional vector (the coordinates of the new origin):
  $
    ""^A 0' = mat(""Delta_x; ""Delta_y; ""Delta_z; mr(1))\
    ""^A x' = mat(x_1; x_2; x_3; mr(0)), ""^A y' = mat(y_1; y_2; y_3; mr(0)), ""^A z' = mat(z_1; z_2; z_3; mr(0))
  $

- *Rotation*: if we pack the rotation and the translation together, we obtain $4$ four-dimensional vectors. This forms a single *$4 times 4$ general transformation matrix* (a square matrix, which has beautiful mathematical properties):
  $
    mat(x_1, y_1, z_1, ""Delta_x; x_2, y_2, z_2, ""Delta_y; x_3, y_3, z_3, ""Delta_z; 0, 0, 0, 1) = mat(""^A_B R, ""^A 0'; 0, 1) = ""^A_B T
  $


  #note()[
    The *last row is always* $0, 0, 0, 1$ because we need to preserve the homogeneous coordinates.

    The transformation matrix can *represent any rototranslation*, but it can also represent a pure rotation (if the last column is $0, 0, 0, 1$) or a pure translation (if the upper left $3 times 3$ block is the identity matrix).
  ]

=== Rototranslation of points

Assume that we have a point $mr(""^B p)$ and a transformation matrix $""^A_B T$. What happens if we multiply the transformation matrix by the point:
$
  ""^A p = ""^A_B T space mr(""^B p) &= mat(x_1, y_1, z_1, Delta_x; x_2, y_2, z_2, Delta_y; x_3, y_3, z_3, Delta_z; 0, 0, 0, 1) mat(p_x; p_y; p_z; 1)\
  &= mat(x_1 p_x + y_1 p_y + z_1 p_z + Delta_x; x_2 p_x + y_2 p_y + z_2 p_z + Delta_y; x_3 p_x + y_3 p_y + z_3 p_z + Delta_z; p_x * 0 + p_y * 0 + p_z * 0 + 1) = mat(""^A 0 + ""^A_B R space ""^B p '; 1)
$

The result is a *$4 times 1$ vector*, with last coordinate equal to $1$. We just need one single matrix product, and I can rototranslate points.



=== Rotation of directions

Assume that we have a *direction* $""^B x'$ and a transformation matrix $""^A_B T$. What happens if we multiply the transformation matrix by the direction:
$
  ""^A_B T space ""^B x' &= mat(x_1, y_1, z_1, Delta_x; x_2, y_2, z_2, Delta_y; x_3, y_3, z_3, Delta_z; 0, 0, 0, 1) mat(x_x; x_y; x_z; 0)\
  &= mat(x_1 p_x + y_1 p_y + z_1 p_z + Delta_x * 0; x_2 p_x + y_2 p_y + z_2 p_z + Delta_y * 0; x_3 p_x + y_3 p_y + z_3 p_z + Delta_z * 0; 0) = mat(""^A_B R space ""^B x'; 0)
$

#note()[
  The *translation component* ($Delta_x, Delta_y, Delta_z$) *has no effect on the result*. Translating a direction has no meaning. This happens perfectly because the last coordinate of the direction is $0$.
]

=== Transformation multiple point

How do we work with a lot of points instead of 1?

With the previous solution, for each point $p_i$, we need to do a single matrix product to transform it. This is highly inefficient because relying on a `for` loop slows computation down. 

The $mg("solution")$ is to *pack all the points* into a single matrix. Matrix multiplication is extremely optimized ("we can eat it").

- First, we need to pack all the points into a single matrix, where each column is a point in homogeneous coordinates:
  $
    P = mat(p_(1,x), p_(2,x), ..., p_(n,x); p_(1,y), p_(2,y), ..., p_(n,y); p_(1,z), p_(2,z), ..., p_(n,z); 1, 1, ..., 1)
  $
- Then, we can multiply the transformation matrix by the matrix of points. In just one step we have all the conversions:
  $
    ""^A_B T space P = mat(x_1, y_1, z_1, Delta_x; x_2, y_2, z_2, Delta_y; x_3, y_3, z_3, Delta_z; 0, 0, 0, 1) mat(p_(1,x), p_(2,x), ..., p_(n,x); p_(1,y), p_(2,y), ..., p_(n,y); p_(1,z), p_(2,z), ..., p_(n,z); 1, 1, ..., 1) = mat(""^A 0' + ""^A_B R space ""^B p_1, ""^A 0' + ""^A_B R space ""^B p_2, ..., ""^A 0' + ""^A_B R space ""^B p_n; 1, 1, ..., 1)
  $
  We multiply the transformation matrix $4 times 4$ and the matrix of points $4 times N$, and we obtain a *$4 times N$* matrix that represents all the points in the reference frame $A$.

  #note()[
    This method it also works for directions, we just need to pack the directions into a matrix where the last row is $0, 0, 0, 0$ instead of $1, 1, ..., 1$.
  ]

== Transformation matrices

Can we exploit the composition? Yes, imagine we have many transformations. Representing a robot in space is basically a *kinematic chain*.

The *composition rule* also works for transformation matrices:
#theorem()[
  $
    ""^0_m T = ""^0_cancel(1) T ""^cancel(1)_2 T ... ""^(m-1)_m T
  $
]

This rule is useful because a robot usually has a *frame of reference for each joint* and a principal frame for movement, so we can use the composition rule to find the transformation matrix between the base of the robot and the end effector.

#note()[
  Usually we know the transformation matrix between one frame and the next one, so I can use the composition rule to find the transformation matrix between the base of the robot and the end effector.
]

#example()[
  Suppose that we have a robot with $7$ joints, and we want to find the transformation matrix between the base of the robot and the final joint (camera).

  The robot tells me the position of a mug in the coordinates of the camera frame, but I need to know the position of the mug in the robot frame to grasp it. I can use the composition rule to find the transformation matrix between the camera frame and the robot frame, so I can transform the position of the mug into the robot frame ($r$):
  $
    w_p_"Mug" = ""^W_r T ""^r_1 T ""^1_2 T ""^2_3 T ""^3_4 T ""^4_5 T ""^5_6 T ""^6_7 T space mb(""^7 p_"Mug") = ""^W_7 T space mb(""^7 p_"Mug")
  $
]

== TF Trees

A real robot typically has many frames of reference put together. Each frame is rigidly attached to the robot.

The problem is being able to calculate the *transformation matrix between any two frames of reference* in the system. One simple solution is to store a transformation matrix for each pair of frames, but this is highly inefficient.

For efficiency, the final $mg("solution")$ is to *store only a minimal subset* of the transformation matrices in transformation trees, and calculate the others via recomposition. In a real system, there is usually a dedicated server that stores the tree and provides the various transformation matrices upon request.

To achieve that we use a *TF tree*, a tree that represents the frames of reference and the transformations between them, where:
- *Nodes* represent the frames of reference
- *Edges* (oriented) represent the relative pose of the child frame with respect to the parent frame (transformation matrix)
  $
    A -> B = ""^A_B T
  $
  the transformation matrix that transforms the coordinates of a point from frame $B$ to frame $A$.

#figure(
  cetz.canvas({
    import cetz.draw: *

    let node-r = 0.52
    let edge-stroke = black + 1pt

    // Draw a directed segment with a compact arrow head.
    let arrow(from, to, stroke: edge-stroke, head: 0.18, spread: 0.10) = {
      let fx = from.at(0)
      let fy = from.at(1)
      let tx = to.at(0)
      let ty = to.at(1)
      let dx = tx - fx
      let dy = ty - fy
      let len = calc.sqrt(dx * dx + dy * dy)
      let ux = dx / len
      let uy = dy / len
      let px = -uy
      let py = ux
      let bx = tx - head * ux
      let by = ty - head * uy

      line((fx, fy), (tx, ty), stroke: stroke)
      line((bx + spread * px, by + spread * py), (tx, ty), stroke: stroke)
      line((bx - spread * px, by - spread * py), (tx, ty), stroke: stroke)
    }

    let A = (0, 6.0)
    let B = (-3.2, 4.2)
    let C = (0, 4.2)
    let D = (3.2, 4.2)
    let E = (-3.2, 2.2)
    let F = (0, 2.2)
    let G = (3.2, 2.2)
    let H = (-1.2, 0.3)
    let I = (1.2, 0.3)

    // Tree edges
    arrow((A.at(0) - 0.35, A.at(1) - 0.35), (B.at(0) + 0.35, B.at(1) + 0.30))
    arrow((B.at(0), B.at(1) - node-r), (E.at(0), E.at(1) + node-r))
    arrow((A.at(0), A.at(1) - node-r), (C.at(0), C.at(1) + node-r))
    arrow((C.at(0), C.at(1) - node-r), (F.at(0), F.at(1) + node-r))
    arrow((F.at(0) - 0.25, F.at(1) - 0.40), (H.at(0) + 0.25, H.at(1) + 0.37))
    arrow((F.at(0) + 0.25, F.at(1) - 0.40), (I.at(0) - 0.25, I.at(1) + 0.37))
    arrow((A.at(0) + 0.35, A.at(1) - 0.35), (D.at(0) - 0.35, D.at(1) + 0.30))
    arrow((D.at(0), D.at(1) - node-r), (G.at(0), G.at(1) + node-r))

    // Highlighted paths
    let p-red = red + 2.2pt
    let p-green = rgb("1ca85f") + 2.2pt
    arrow((H.at(0) + 0.05, H.at(1) + 0.30), (F.at(0) - 0.30, F.at(1) - 0.05), stroke: p-red, head: 0.22, spread: 0.12)
    arrow((F.at(0), F.at(1) + 0.55), (C.at(0), C.at(1) - 0.28), stroke: p-red, head: 0.22, spread: 0.12)
    arrow((C.at(0), C.at(1) + 0.55), (A.at(0), A.at(1) - 0.28), stroke: p-red, head: 0.22, spread: 0.12)

    arrow((A.at(0) + 0.35, A.at(1) - 0.30), (D.at(0) - 0.35, D.at(1) + 0.05), stroke: p-green, head: 0.22, spread: 0.12)
    arrow((D.at(0), D.at(1) + 0.35), (G.at(0), G.at(1) + 0.10), stroke: p-green, head: 0.22, spread: 0.12)

    // Nodes
    for (name, p) in (("A", A), ("B", B), ("C", C), ("D", D), ("E", E), ("F", F), ("G", G), ("H", H), ("I", I)) {
      circle(p, radius: node-r, stroke: black + 1pt, fill: white)
      content((p.at(0) - 0.09, p.at(1) - 0.11), text(size: 11pt, style: "italic")[#name])
    }

    // Edge labels
    content((-1.90, 5.10), $""^A_B T$, font: ("New Computer Modern", 10pt))
    content((-3.90, 3.20), $""^B_E T$, font: ("New Computer Modern", 10pt))
    content((-0.60, 5.08), $""^A_C T$, font: ("New Computer Modern", 10pt))
    content((-0.60, 3.18), $""^C_F T$, font: ("New Computer Modern", 10pt))
    content((-1.2, 1.42), $""^F_H T$, font: ("New Computer Modern", 10pt))
    content((0.95, 1.42), $""^F_I T$, font: ("New Computer Modern", 10pt))
    content((1.35, 5.50), $""^A_D T$, font: ("New Computer Modern", 10pt))
    content((2.55, 3.18), $""^D_G T$, font: ("New Computer Modern", 10pt))
  }),
  caption: "Example of TF tree with highlighted paths",
)

In this image, what is the transformation of $G$ with respect to $H$?

- First we need to *check if there is a path* between $G$ and $H$ (reverse paths are also OK).
#warning()[
  We always need a *connecting tree* (spanning tree) to be able to find the transformation between any two frames. If there is a frame that is not connected to the rest of the tree, I will not be able to find the transformation between that frame and the other frames.
]

- If there is a path, compute the transformation by multiplying the matrices through the arcs. During the check I need to keep track of the *direction of the edges*.

- I need a way to represent the inverse transformation for opposite directions, because if I have an edge $A -> B$ I can use it to find the transformation between $B$ and $A$ by inverting the transformation matrix. I can't just transpose it like a pure rotation matrix.

  *Inverse problem*: given $""^A_B T$ how we can obtain $""^B_A T$, where $""^B_A T$ is such that $""^A_B T space ""^B_A T = I$? We can use the inverse of the transformation matrix:
$
  ""B_A T = mat(
    ""^B_A R^T, -""^B_A R^T space ""^A 0';
    0, 1;
  )
$

- If the arc is $mr("traversed upwards")$ (from child to parent) we need to invert the transformation matrix; if the arc is $mg("traversed downwards")$ (from parent to child) we can use the transformation matrix as it is.

$  ""^H_G T = mr(""^H_F T) space mr(""^F_C T) space mr(""^C_A T) space mg(""^A_D T) mg(""^D_G T) $