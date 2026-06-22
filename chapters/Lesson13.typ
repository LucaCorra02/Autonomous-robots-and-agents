#import "../template.typ": *

= Robot Software Architecture (ROS2)

From a computer science perspective, a robot can be thought of as a computer equipped with sensors and actuators that must perform computational tasks while *interacting with the physical environment*. This is significantly more complex than a traditional computer.

A robot's software must be abstracted at different levels of abstraction:
- *Low-level tasks*: managing sensor readings, controlling motor speeds, handling real-time tasks
- *High-level tasks*: SLAM, path planning, decision making

This is why *ROS2* (Robot Operating System 2) exists: it provides a *middleware layer* that abstracts away hardware differences and provides *standardized communication patterns* between software components.

#note()[
  ROS2 is *not an operating system* its a middleware that runs on top of an operating system (Linux, Windows, macOS). It provides a set of tools and libraries to facilitate the development of robotic applications, but it relies on the underlying OS for low level functionalities.
]

== ROS Software Architecture

The fundamental concept in ROS is the *computation graph*, which is a set of computational units (`nodes`) that interact with each other to solve complex robotic tasks.

=== Nodes

A *node* is a computational unit that carries out some task at one or more levels of abstraction. Examples include:
- Running the driver for a sensor (e.g., LIDAR driver)
- Performing SLAM (Simultaneous Localization and Mapping)
- Computing the path the robot should follow

Nodes *run concurrently* and are *language-agnostic*. In resource-constrained robots, some nodes may run locally while others run on a PC.

=== Interfaces

Nodes interact through *interfaces*, which are *formal specifications of communication rules*. An interface is like a contract ensuring that nodes agree on the structure and type of data being exchanged.

#note()[
  Interfaces are defined using a language-agnostic *Interface Definition Language (IDL)*, which allows nodes written in different languages (C++, Python, etc.).
]

== ROS Interfaces Overview

ROS provides three types of interfaces for different communication patterns:

=== Messages (.msg)

Messages define a simple data structure for one-way, *asynchronous* input/output interaction. They follow a *publisher/subscriber* pattern:
- They *specify a list of typed fields*
- Ideal for continuous streams of data (sensor readings, robot state)
- Example topics: `/scan` (LIDAR scans), `/cmd_vel` (velocity commands), `/camera/image_raw` (camera images)

Suppose that we want to exchange the linear velocity $v$ and angular velocity $theta$ of a robot. The comunication follow this pattern:

- We have a $mr("publisher")$ that publishes the velocity commands. It *doesn't know* if there is a node that *receives* these commands. It just publishes them.

- All the nodes that want to receive these commands, *subscribe to the publisher*. When they wake up, they will receive the velocity commands and execute them.

- We also have a $mp("Topic")$: is a *unidirectional channel* over which data are communicated. One topic is *associated with a specific type of message*. A node can publish messages to a topic or subscribe to a topic to receive messages.

This pattern has three key properties:
- *Asynchronous*: the *publisher doesn't have to wait/check* if the other node is ready to receive the message; it just publishes and moves on. The subscriber will receive the message when it is ready.

- *Anonymous*: the *publisher and subscriber don't know each other*; they just know the topic. This allows for decoupling between the nodes, making the system more flexible and scalable.

- *Many to many*: communication can be $1:1$, $1:N$, $N:1$, or $N:N$.

#note()[
  The angular velocity is usually represented by three numbers (one for each axis). It can be represented as a quaternion, but when humans are involved, this representation is better because it is more intuitive. Quaternions are more suitable for computer calculations.
]


#example()[
  *Lidar and odometry*
  - Topic `/scan`: The LIDAR driver publishes range scans at a given frequency (e.g., 5 Hz)
  - Multiple nodes (SLAM, Localization, mapping, visualization) might receive and consume these data

  *Teleoperation*
  - Topic `/cmd_vel`: A teleoperation node publishes velocity commands $(v, theta)$ reading the user's input
  - A controller node computes angular velocities for each wheel and sends control actions to the motors
]

*QoS (Quality of Service)*: It defined that the delivery process by some parametes. The most important are:

- *Reliability*: it can be:
  - *`Best effort`*: the message can be lost
  - *`Reliable`*: the system will try to deliver the message until it is delivered

- *Durability*: Nodes are asynchronous and can join/leave at any time. Suppose we have a late-joining subscriber; should we deliver old messages to it? If the publisher is `volatile`, the message is lost.
  - *`Volatile`*: no attempt is made to persist samples
  - *`Transient local`*: the publisher becomes responsible for persisting samples for late-joining subscriptions

#warning()[
  *QoS Compatibility*: Not all the parameters configuration are compatible.

  The subscriber *should not demand* a higher quality than the one provided by the publisher. If the publisher is `Best Effort` and the subscriber is `Reliable`, they are not compatible. Similarly, if the publisher is `Volatile` and the subscriber is `Transient` Local, they are incompatible.
]

=== Services (.srv)

Services are used for short-running request/response interactions. Unlike pub/sub, *they are synchronous*: the client waits for a response:
- Two message definitions: the request sent by the client and the response returned by the server
- Suitable for simple queries or configuration requests

#example()[
  *Navigation stack's maps*
  - Service `GetCostmap`: retrieves the entire costmap as an occupancy grid, allowing external nodes (e.g., task planners) to do planning on it
  - Service `IsPathValid`: given a path (sequence of poses), evaluates it against the current costmap and returns whether the trajectory is valid or would collide with obstacles. It also returns the index of poses that failed validation (collision points), enabling the path planner to find better paths

  #note()[
    Both services are quick computational geometry operations; they don't require interaction with the physical world.
  ]
]

=== Actions (.action)

Actions are used for *long-running, asynchronous request/response interactions* with intermediate feedback, progress reports, and the possibility of preemption. They are suitable for complex tasks that take time and need monitoring

*Action Workflow*:
- *Sending the goal*: The action client sends a `goal` (e.g., "go to pose $X$") to the action server. The server immediately sends an acknowledgement via a service call.

- *Getting feedback*: The action server executes the task while providing continuous updates (e.g., current position, distance to goal, tracking error). The client can send a `cancel request` or `new goal` to preempt the current one. This is implemented *via pub/subscribe*.

- *Receiving the result*: Upon completion or failure, the action server sends a final one-time message.

#example()[
  *Path following*:
  - Action `FollowPath`: executes a path (sequence of poses) using a specified controller with progress monitoring
  - Feedback includes: `tracking_error`, `current_path_index`, `robot_pose`, `distance_to_goal`, `speed`, `remaining_path_length`
]


== Node Workflow

Nodes can execute in two different ways:

- *Iterative Execution*: The node runs a loop that *periodically checks* for new messages or data. At each iteration (e.g., every 10 Hz), it processes the queue of pending messages and executes its logic.

  #example()[
    A node might read sensor data from the bumper, process it, and publish velocity commands at a fixed rate.
  ]

- *Event-Oriented Execution*: The node is *triggered by events* (message arrivals, service requests, etc.) rather than running on a fixed schedule. This is more efficient for asynchronous, reactive behaviors.

== Managed Lifecycles

In complex robotic systems, simply *launching nodes is not sufficient*. ROS2 introduces managed lifecycles to ensure reliable bringup and shutdown.

Each node transitions through deterministic states:
- *`Unconfigured`*: the node is created but not initialized. It can't do anything.
- *`Inactive`*: the node is configured but not active. It can perform some operations but doesn't process data.
- *`Active`*: the node is active and can do everything (publish/subscribe, execute logic).
- *`Finalized`*: the node is shutting down.

Advantages:
- *Reliable bringup*: Critical dependencies, hardware interfaces, and communication channels are fully initialized before the node starts processing
- *Runtime supervision*: A supervisor can pause, reset, or restart individual nodes without restarting the entire ROS graph
- *Error recovery*: If a node fails, it can safely transition to Inactive or Unconfigured to prevent strange behavior

== TF Subsystem (TF2)

ROS provides a unified approach to *manage all frames of reference* that compose a robot through the *TF (Transform) subsystem*. In ROS2, this is implemented as *TF2*.

A frame is a coordinate system attached to a specific part of the robot or the environment. Transforms describe the spatial relationship (position and orientation) between two frames.

TF2 uses *homogeneous coordinates* and *transformation matrices* to compute relations between frames and points. It:
- Receives updates about transforms and keeps tracks of them
- Maintains a history of transforms (important for timestamped sensor data)
- Follows standard conventions: right-handed, with angles growing counter-clockwise (0 = forward, $pi/2$ = left, $pi$ = backward, $-pi/2$ = right)

TF2 works with two main *topics*:
- *`/tf`*: *dynamic transforms* that change over time (e.g., robot joints, actuators). They have high volatility, they expire if not refreshed after a given time.

- *`/tf_static`*: *transforms* that stay *fixed over time* (e.g., rigidly attached components like the laser relative to the robot's base). They don't expire and are published under a transient local QoS.

All known transforms are organized in a *TF tree* structure.

#figure(
  image("/assets/Tf-tree.png", width: 80%),
  caption: [TF tree structure for a differential drive robot with a LIDAR and an IMU],
)
The image shows this tree scructure:
- `odom` (root): odometry frame
  - `base_footprint`: base of the robot
    - `base_link`: main body of the robot
      - `wheel_left_link`, `wheel_right_link`, `caster_back_link`: wheel frames
      - `base_scan`: LIDAR frame
      - `imu_link`: IMU frame

#example()[
  A node subscribes to laser readings and detects an obstacle at distance `Threshold`. It wants to mark that spot on the global map.

  1. The node receives a scan message with timestamp $t$ and obstacle position $p$
  2. It calls TF2 to get the transform from the laser frame to the global frame at time $t$
  3. TF2 must process it with the transform of time $t$, not $t + epsilon$, ensuring proper alignment

  This *temporal accuracy is crucial* for SLAM and localization algorithms.
]

== Behavior Trees

How should robot behaviors be programmed? One approach is using *Finite State Machines (FSM)*, where states represent conditions and transitions represent actions.

A more powerful alternative is *Behavior Trees (BTs)*: a richer formalism that enables the implementation of complex, reactive behaviors. BTs are particularly *useful for autonomous agents and robots* that need to handle multiple, interdependent tasks.

A BT is composed of *nodes*, each encoding specific *behavioral logic*. The tree structure represents a hierarchy of tasks and conditions.

#figure(
  image("/assets/behaivor-tree.png", width: 50%),
  caption: [Behavior tree for cleaning a room.]
)

=== Node Execution

The *root* node is *ticked periodically*. Ticks propagate through the tree recursively following specific patterns determined by the node types. Each node can respond in three ways:
- *$mg("Success")$*: the node successfully completed its task or a condition was met
- *$mr("Failure")$*: the node failed to execute its task or a condition was not met
- *$mo("Running")$*: the node is busy executing its task (used for long-running actions)

There are four types of nodes in a behavior tree:
- *`Control nodes`*: have one or more children and forward the tick according to specific logic patterns.
- *`Decorator nodes`*: control nodes with just one child that modify the child's behavior or return value.
- *`Action nodes`*: leaf nodes that trigger the execution of tasks (e.g., navigate to a goal, grasp an object). They can return $mg("Success")$, $mr("Failure")$, or $mo("Running")$.
- *`Condition nodes`*: action nodes that *inspect the environment* or system state *and immediately return* $mg("Success")$, $mr("Failure")$, *never* $mo("Running")$. They check the validity of given conditions.

*Control nodes* determine *how ticks are propagated to their children*. The most common control nodes are:

- *SEQUENCE*: executes children from *left to right* (like an AND gate)
  - If a child returns $mg("Success")$, immediately tick the next child
  - If a child returns $mr("Failure")$, stop and return $mr("Failure")$ to parent (canceling subsequent steps)
  - If a child returns $mo("Running")$, return $mo("Running")$ and stay on that node

- *FALLBACK*: executes children from *left to right until one succeeds* (like an OR gate)
  - If a child returns $mr("Failure")$, immediately move to the next child
  - If a child returns $mg("Success")$, stop and return $mg("Success")$ to parent
  - If a child returns $mo("Running")$, return $mo("Running")$ and stay on that node

- *PARALLEL*: executes all children concurrently
  - Returns $mg("Success")$ or $mr("Failure")$ depending on whether a specific threshold of children complete successfully

- *REPEAT*: retries a child node on failure
  - If the child returns $mr("Failure")$, tick it again, repeating up to $N$ times before passing the failure to the parent

=== Representation and Generation

Behavior trees are *represented in structured text formats*: XML, JSON, or YAML.

BTs are a viable formalism because they can be easily verified from a syntactic point of view (we can only use the compilaer and see if it compile). However, the main challenge is *semantic correctness*: generated trees (e.g., from LLM prompts) might compile syntactically but have incorrect logic with respect to the original specification.

The advantage of using *LLMs to generate behavior trees* is that users can specify high-level goals/tasks in natural language, and the system generates the corresponding XML/JSON tree structure.






