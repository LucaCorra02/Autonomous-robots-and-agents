#import "../template.typ": *

== Rotations

A rotation is just an angle, and the axes about wich we rotate. Any rotation can be decribed as:
$
  theta, r = mat(r_x; r_y; r_z)
$
where $r$ is an axis (rappresented as a vector) and $theta$ is the angle of rotation.

We can rappresent a rotation with a quaternion, where:
- a = theta
- b = $r_x$
- c = $r_y$
- d = $r_z$
but with this rappresentation we are not enforcing the fact that is a unit quaternion.

The $4$ number that we have to choose are:
$
  a = cos(theta/2)
  b = r_x * sin(theta/2)
  c = r_y * sin(theta/2)
  d = r_z * sin(theta/2)
$
we need to preserve unit quaternions, even when we operate with them, so we need to normalize them.
#informally()[
  This rappresentation tell me $r_x,r_y,r_z$ in therms of quaternions.
]
Our rotation will be represented by:
$
  r = cos(theta/2) + r_x * sin(theta/2) * i + r_y * sin(theta/2) * j + r_z * sin(theta/2) * k\
  mat(a; b; c; d) = mat(cos(theta/2); r_x * sin(theta/2); r_y * sin(theta/2); r_z * sin(theta/2))
$
The final vector rappresent an aribitrary rotation. Also include elementary rotations.

=== Operations with quaternions

if $q = mat(a; b; c; d)$ is a unitary quaternion that rappresent a rotation. I can rappresent the same rotation with the rotation matrix $R$. There is a relation between the two:
$//add matrix
$
#warning()[
  It is always possible to convert one parameterization of a rotation into another, but some parameterizations are more compact and easier to use than others.
]

From the quaternion we can extract the angle of rotation and the axis of rotation:
$
  theta = 2* "arcos"(a), r = mat(b / sin(theta/2); c / sin(theta/2); d / sin(theta/2))
$

The identity matrix rappresent a *non-rotation*. I can express non-rotation with a quaternion in this way:
$
  q = mat(1; 0; 0; 0)
$

The inverse of a rotation matrix $R$ is its transpose $R^T = R^(-1)$. The inverse of a quaternion is just the conjugate ( i only invert the sign of the imaginary part):
$
  q^* => "inverse rotation"
$

Suppose that we have a point $p = mat(p_x; p_y; p_z)$ and the quaternion $q$ that rappresent a rotation $q = a + b i + c j + d k$.\
I need to take $p$ and trasform it to a quaternion. A point is rappresent with a *pure quaternion*, only the unit part is $0$:
$
  p' = 0 + p_x i + p_y j + p_z k
$
Now i can rotate the point $p$ wit the rotation $q$ eith an operation called *swandich product*:
$
  p' = q p q^*
$
where p' is the rotated point $p' = mat(p_x'; p_y'; p_z')$

=== composition of rotations

Suppose that we have two rotations matrix $R_1$ and $R_2$ and we want to compose them. We can do it with the composition of the two rotation matrices by multiplying them.

#warning()[
  When we compose rotation we need to be careful about the order of the composition, because it is not commutative. $R_1 R_2$ is not the same as $R_2 R_1$.

  if my meaning is that $R 2$ described a rotation in the fixing frame (anzichè nel moving frame) then i need to pre-multiply it, so $R = R_2 R_1$.
]

In quaternions word the composition of two rotation is just the multiplication of the two quaternions:
- $q_"new" = q_2 q_1$ rotation about fixed axes
- $q_"new"$ = $q_1 q_2$ rotation about moving axes

== Quaternions in robotics

Quaternions are very useful two save computational time, i send $4$ number insted of $9$.

== Interpolation of rotations

Suppose that we need to rotate an object from a position $R_1$ to a position $R_2$. We know the description of the initial and final rotation, but we need to find a way to do it. We need to find a sequence of rotations (*path*) that will take us from $R_1$ to $R_2$.

Suppose that we use tree angles (euler angles) to rappresent the rotation. I can describe the transiction using *linear interpolation*:
$
  v_i = v_i alpha(v_f - v_i), alpha in [0,1]
$
where:
- $v_i$ is the initial vector
- $v_f$ is the final vector
- $alpha$ is a parameter that goes from $0$ to $1$ and rappresent the progress of the interpolation. If $alpha = 0$ i'm in the initial position, if $alpha = 1$ i'm in the final position.
#note()[
  This trajectory is follow the shortest path between the two rotations (euclidian distance).
]

But the linear Euler is not the best way to do it, because the shortest path between two rotations is not a linear interpolation of the angles, but a *spherical linear interpolation* (slerp). The slerp is defined as:
$
  "slerp"(q_1, q_2, alpha) = (q_1 sin((1-alpha) theta) + q_2 sin(alpha theta)) / sin(theta)
$
Unit quaternions are on the surface of a 4d shpere, so te shortest path between two quaternions is an arc of circle on the surface of the sphere, not a straight line.

#note()[
  It could happend that the intermediate rotation change the axis of rotation, but it is not a problem because the slerp will always follow the shortest path between the two rotations.
]

#example()[
  The shortest trajectory followed by a plane in a 2d is not a straight line, but an arc of circle. That because in a sphere the shortest path between two points is an arc of circle, not a straight line.
]

== Change of reference frame

We want express the coordinates of a point $p$ (robot frame) in a reference frame $A$.

The robot is also trasleted and rotated. I need to do a rototraslation (translation + rotation). To do this i need this mathematical operation:
- The *traslation* between origin. A point $""^A 0'$ to describe the position of the origin of the robot frame in the reference frame $A$.

- The *rotation* between the two frames. I cane use a rotation matrix $""^A_B R$ to describe the rotation between the two frames ( how the red axes are rotated with respect to the black axes). Where the components of the matrix are:
$
  ""^A x', ""^A y', ""^A z'
$

The translation followed by the rotation is called *forward kinematics*:
$
  ""^A p = ""^A_B R ""^B p + ""^A 0'
$

But with rappresentation we represent the point $p$ with 3 coordinate, but even the direction of the translation is a vector ($3$ coordinate), so we need to rappresent it with 3 coordinate. So we have 9 coordinate to rappresent the position of the point $p$ in the reference frame $A$. I need to rember the interpretation of the object

We can do better, we can rappresent the rototraslation with a single mathematical object.

*Problem*: is there a way to do the rototraslation with only one operation and represent it with a single mathematical object? Yes, we can use the *homogeneous transformation*.

== Homogeneous coordinates

The point $p$ are represented with tree coordinates:
$
  p = mat(p_x; p_y; p_z)
$
But we can rappresent the same point with homogeneous coordinates:
$
  p = mat(p_x; p_y; p_z; mr(1))
$
#note()[
  The firth componet should be $1$ to rappresent a point, if it is $0$ we rappresent a vector.
]
If we want to represent a direction the $4$ coordinate should be $0$:
$
  x = mat(x_x; x_y; x_z; mr(0))
$

#note()[
  We add a fourth coordinate to distinguish between points and vectors.
]

The rototraslation change in this way:
- Translation: we obtein $4$ four dimensional vector $""^A 0' = mat(""^A 0'_x; ""^A 0'_y; ""^A 0'_z; mr(1))$

- Rotation: if i pack all togheter i obtein a sqaure matrix $4 times 4$ wich is a useful properties:
  $
    mat(x_1, y_1, z_1, 0; y_1, y_2, y_3, 0; z_1, z_2, z_3, 0; t_x, t_y, t_z, 1)
  $
  #note()[
    The last row is always $0, 0, 0, 1$ because we need to preserve the homogeneous coordinates.
  ]
  In the rotation matrix i recognize the pattern: where delta are the translation. I can write the rotation matrix as:
  $
    mat(""^A_B R, ""^A 0'; 0, 1)
  $
//riguardare perchè

Transformation matrix is a single $4 times 4$ matrix espressing both the rotation and the translation (any rototraslation).

=== Rototraslation of points

Assume that we have a point $""B^p$ and a transformation matrix $""^A_B T$. What appens if we multiply the transformation matrix with the point:
$
  ""^A p &= ""^A_B T ""^B p\
  &= mat(x_1, y_1, z_1, 0; y_1, y_2, y_3, 0; z_1, z_2, z_3, 0; t_x, t_y, t_z, 1) mat(p_x; p_y; p_z; 1)\
  &= mat(x_1 p_x + y_1 p_y + z_1 p_z + t_x; x_2 p_x + y_2 p_y + z_2 p_z + t_y; x_3 p_x + y_3 p_y + z_3 p_z + t_z; 1)
$
the result is a $4 times 1$, is a direction because the last coordinate is $1$. I can observe that i can simplfy the formula as:
$
  mat(""^A_B R, ""^A 0'; 0, 1) mat(p_x; p_y; p_z; 1) = mat(""^A_B R ""^B p + ""^A 0'; 1)
$
I just need one single matrix products and i can do it in a very efficient way.

=== rototraslation of directions
//riguardare
Assume that we have a direction $""B^x$ and a transformation matrix $""^A_B T$. What appens if we multiply the transformation matrix with the direction:
$
  ""^A x & = ""^A_B T ""^B x' \
         & = mat(""^A_B R ""^B x'; 0)
$

=== Transformation multiple point

#example()[
  Point cloud obtained by a range sensor mounted on the robot. THe red points are the point that the robot are providing (they are in the frame of reference of the robot).
]

For each point $p_i$ i only need to do a single matrix product to trasform it in the reference frame $A$ ( i suppose i have the transformation matrix $""^A_B R$). But with this solution i need to do $N$ matrix product, where $N$ is the number of points.

The solution is to pack all the points in a single matrix, so i can do a single matrix product to trasform all the points togheter:
/*
$
  mat(p_1, p_2, ..., p_N) = mat(p_{1x}, p_{2x}, ..., p_{Nx}; p_{1y}, p_{2y}, ..., p_{Ny}; p_{1z}, p_{2z}, ..., p_{Nz}; 1, 1, ..., 1)
$*/
I multiply the transformation matrix $4 times 4$ and the matrix of the points $4 times N$ and i obtein a $4 times N$ matrix that rappresent all the points in the reference frame $A$.

== Transformation of matrix

I also have the composition rule:
$
  ""^0_M T = ""0_1T ""^1_2 T ... ""^{m-1}_m T
$

This is usefule because in a robot i usually have a frame of reference for each joint and a principally frame for the movement, so i can use the composition rule to find the transformation matrix between the base of the robot and the end effector.

Usually i know the transformation mattrix between one frame and the next one, so i can use the composition rule to find the transformation matrix between the base of the robot and the end effector.

#example()[
  If i have a camera the robot teells me the position of a mug in the coordinate of the frame of the camera, but i need to know the position of the mug in the frame of the robot to be able to grasp it. I can use the composition rule to find the transformation matrix between the frame of the camera and the frame of the robot, so i can trasform the position of the mug in the frame of the robot.

  Using the cancellation rule:
  $
    w_p_"Mug" = ""^W_7 ""^7 p_"Mug" = ""^W_0 ""^0_1 T ... ""^6_7 T ""^7 p_"Mug" = ""^W T dot ""^7 p_"Mug"
  $
]

== Tf Trees

A robot typically has many frames of reference, one for each joint and one for the end effector. Each frame is rigidly attached to the robot.

THe problem is to being able to calculate the transformation matrix between any two frames of reference. One simple solution is to store a transformation matrix for each pair of frames, but this solution is not scalable because the number of pairs grows quadratically with the number of frames.

The solution is to store only a subsect of the transfromation matrix, and obtein the other transfromation matrix by composition. _For example_, if i have a robot with $n$ joints, i can store the transformation matrix between the base of the robot and each joint, and then use the composition rule to find the transformation matrix between any two joints.

To achive that we use a *tf tree*, a tree that rappresent the frames of reference and the transformation between them. Where:
- *Nodes* rappresent the frames of reference
- *Edges* (oriented) rappresent the relative pose of the child frame with respect to the parent frame (transformation matrix)
  $
    A -> B = ""^A_B T
  $
the transformation matrix that trasform the coordinates of a point from the frame $B$ to the frame $A$.

//aggiungere immagine tf tree

In this image what is the transformation of $G$ with respect to $H$?
- I need to check if there is a path between $G$ and $H$ (also reverse path are ok)
#warning()[
  I always need a *connecting tree* (spanning tree) to be able to find the transformation between any two frames. If there is a frame that is not connected to the rest of the tree, i will not be able to find the transformation between that frame and the other frames.
]

- During the check i need to keep track of the direction of the edges.

- I need to way to represent the inverse transformation, because if i have an edge $A -> B$ i can use it to find the transformation between $B$ and $A$ by inverting the transformation matrix.

  Given $""^A_B T$ come ottengo $""^B_A T$? I can use the inverse of the transformation matrix:
  $
    ""^B_A T = (""^A_B T)^(-1) = mat(""^A_B R^T, -""^A_B R^T ""^A 0'; 0, 1)
  $

- If the arc is traveled upwards (from child to parent) i need to invert the transformation matrix, if the arc is traveled downwards (from parent to child) i can use the transformation matrix as it is.

$
  ""H_G T = ""^H_F T ""^F_C T ""^C_A T ""^A_B T ""^B_G T
$

