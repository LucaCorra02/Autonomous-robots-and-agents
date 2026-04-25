#import "../template.typ": *

== Rotations

A rotation is just an angle and the axis about which we rotate. Any rotation can be described as:
$
  theta, r = mat(r_x; r_y; r_z)
$
where $r$ is an axis (represented as a vector) and $theta$ is the angle of rotation.

We can represent a rotation with a quaternion, where:
- a = theta
- b = $r_x$
- c = $r_y$
- d = $r_z$
but with this representation we are not enforcing the fact that it is a unit quaternion.

The $4$ numbers that we have to choose are:
$
  a = cos(theta/2)
  b = r_x * sin(theta/2)
  c = r_y * sin(theta/2)
  d = r_z * sin(theta/2)
$
We need to preserve unit quaternions, even when we operate with them, so we need to normalize them.
#informally()[
  This representation gives me $r_x, r_y, r_z$ in terms of quaternions.
]
Our rotation will be represented by:
$
  r = cos(theta/2) + r_x * sin(theta/2) * i + r_y * sin(theta/2) * j + r_z * sin(theta/2) * k\
  mat(a; b; c; d) = mat(cos(theta/2); r_x * sin(theta/2); r_y * sin(theta/2); r_z * sin(theta/2))
$
The final vector represents an arbitrary rotation. It also includes elementary rotations.

=== Operations with quaternions

If $q = mat(a; b; c; d)$ is a unit quaternion that represents a rotation, I can represent the same rotation with the rotation matrix $R$. There is a relation between the two:
$//add matrix
$
#warning()[
  It is always possible to convert one parameterization of a rotation into another, but some parameterizations are more compact and easier to use than others.
]

From the quaternion we can extract the angle of rotation and the axis of rotation:
$
  theta = 2* "arccos"(a), r = mat(b / sin(theta/2); c / sin(theta/2); d / sin(theta/2))
$

The identity matrix represents a *non-rotation*. I can express a non-rotation with a quaternion in this way:
$
  q = mat(1; 0; 0; 0)
$

The inverse of a rotation matrix $R$ is its transpose $R^T = R^(-1)$. The inverse of a quaternion is just the conjugate (I only invert the sign of the imaginary part):
$
  q^* => "inverse rotation"
$

Suppose that we have a point $p = mat(p_x; p_y; p_z)$ and the quaternion $q$ that represents a rotation, $q = a + b i + c j + d k$.\
I need to take $p$ and transform it into a quaternion. A point is represented with a *pure quaternion*, where only the real part is $0$:
$
  p' = 0 + p_x i + p_y j + p_z k
$
Now I can rotate the point $p$ with the rotation $q$ with an operation called *sandwich product*:
$
  p' = q p q^*
$
where $p'$ is the rotated point, $p' = mat(p_x'; p_y'; p_z')$

=== Composition of rotations

Suppose that we have two rotation matrices $R_1$ and $R_2$ and we want to compose them. We can do this by multiplying them.

#warning()[
  When we compose rotations we need to be careful about the order of composition, because it is not commutative. $R_1 R_2$ is not the same as $R_2 R_1$.

  If I mean that $R_2$ describes a rotation in the fixed frame (instead of the moving frame), then I need to pre-multiply it, so $R = R_2 R_1$.
]

In the quaternion world, the composition of two rotations is just the multiplication of the two quaternions:
- $q_"new" = q_2 q_1$ rotation about fixed axes
- $q_"new"$ = $q_1 q_2$ rotation about moving axes

== Quaternions in robotics

Quaternions are very useful to save computational time: I send $4$ numbers instead of $9$.

== Interpolation of rotations

Suppose that we need to rotate an object from a position $R_1$ to a position $R_2$. We know the description of the initial and final rotation, but we need to find a way to do it. We need to find a sequence of rotations (*path*) that will take us from $R_1$ to $R_2$.

Suppose that we use three angles (Euler angles) to represent the rotation. I can describe the transition using *linear interpolation*:
$
  v_i = v_i alpha(v_f - v_i), alpha in [0,1]
$
where:
- $v_i$ is the initial vector
- $v_f$ is the final vector
- $alpha$ is a parameter that goes from $0$ to $1$ and represents the progress of the interpolation. If $alpha = 0$ I'm in the initial position, if $alpha = 1$ I'm in the final position.
#note()[
  This trajectory follows the shortest path between the two rotations (Euclidean distance).
]

But the linear Euler is not the best way to do it, because the shortest path between two rotations is not a linear interpolation of the angles, but a *spherical linear interpolation* (slerp). The slerp is defined as:
$
  "slerp"(q_1, q_2, alpha) = (q_1 sin((1-alpha) theta) + q_2 sin(alpha theta)) / sin(theta)
$
Unit quaternions are on the surface of a 4D sphere, so the shortest path between two quaternions is an arc of a circle on the surface of the sphere, not a straight line.

#note()[
  It could happen that the intermediate rotation changes the axis of rotation, but this is not a problem because the slerp always follows the shortest path between the two rotations.
]

#example()[
  The shortest trajectory followed by a plane in 2D is not a straight line, but an arc of a circle. This is because on a sphere the shortest path between two points is an arc of a circle, not a straight line.
]

== Change of reference frame

We want to express the coordinates of a point $p$ (robot frame) in a reference frame $A$.

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

