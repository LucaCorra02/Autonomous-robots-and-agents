#import "../template.typ": *

= Messages

$v$ is a linear velocity while $theta$ is a angular velocity. By specifing this parameters we can comand the robot to move in a certain way.

We a pub/sub system. In this teleop node also has to puclish the velocity commands (it dosen't know that there isa a node who recive this comands). The recive subscribe to the publosher and consume the messages.

The reciver when i woke ups subscribe to velocity commands. So if there is someone who publish a velocity command, the reciver will recive it and execute it.

*Topic*: topic is a unidirectional channel over wich data are communicated. One topic is associated to a specific type of message. A node can publish messages to a topic or subscribe to a topic to receive messages.

This pattern is:
- *Asyncronous*: the publisher dosent' have to wait/check if the other node is ready or recive the message, it just publish and move on. The subscriber will recive the message when it is ready.

- *Anonymous*: the publisher and subscriber don't know each other, they just know the topic. This allows for a decoupling between the nodes, making the system more flexible and scalable.

- *Many to meny*: i can have multuple type of comunication $1:1,1:N,N:1,N:N$

#note()[
  The angular velocity usually his represents by three number (one for each axis). It can be represent as a quaternion but when the humans are involved is better this representation because is more intuitive. The quaternion once is more suitable for computer calculus.
]

*QoS (Quality of Service)*: It defined that the delivery process by some parametes. The most important are:

- *Reliability*: it can be "best effort" (the message can be lost) or "reliable" (the system will try to deliver the message until it is delivered).
  #note()[
    We *can't chose any combination of these parameters*. If the publisher are BestEffort and Subscriber are Reliable, they are not compatible.
  ]

- *Durability*: Nods are asyncronous, join can join/leave at any time. Suppose that we have a lete subriber, should we deliver the old messages to it? If the publisher is "volatile" the message is lost .

  it can be *"volatile"* (no attemp is made to persist sample) or *"transient local"* (the publisher becomes responsable for persisting sample for late-joining subscription).

== Services

#example()[
  Suppose that we have a robot that navigates in an environment. We can use the `GetCostMap` navigation service.

  In the image the green point are particles (they represent the belif of the robot about its position). The blue circle are the obstacles. In each cell we have a value taht tells how risk it's for the robot to be there (the wrost is the purple cell). Beacuse the robot are not very precise it's better to *inflate the obstacles* (create much larger obstacles) to be sure that the robot will not collide with them.

  In this case the robot should go in the blue area only if is necessary, because it's a risky area. The robot should prefer the grey area, because it's safer.

  The path planner should take into account the cost map to find the best path for the robot.

  #note()[
    The tipicall function of path planner is to minimaze the distance to the goal, but we also wanto to avoid the obstacles, so we can minimaze the cost of the path.
  ]

  The service `is valide path` evaluate a sequence of poses (the trajectory) againt the current cost map and return if the trajectory is valide or colide with some obstacle. It aslo return where the collision is planned to happen, so the path planner can use this information to find a better path.

  #note()[
    In both case this service are quick, they are only computational geometry. They don't need interaction with the phisic world.
  ]
]

`FollowPath`: it takes time, it requires to move the robot because i need the navigatizon stack. During this action we should not keep wainting, we can do other actions (like checking sensors).

During the following of the path we can also cjeck the *feedbecks*. An example are:
- *Tracking error*: teels how much the robot is far from the planned trajectory. If the error is too high we can stop the action and replanning a new path.

- *current_phose_index*: the current pose in the trajectory or the pose that the robot believe to be.

- *ditance to goal*: the distance from the current pose to the goal pose. If the distance is too high we can stop the action and replanning a new path.

== Node workflow

It can be works in two ways:
- *Iterative execution*: the image. The node talks with the bumper, when the robots collide whit an obstalce comunicate sensor metrics. Our node wakes up evey 10 second anche check at the qeue of the messages.

- *Event-oriented execution*:

== Managed Lifecycle

Each noode as a lifecycle, it can be in different states:
- *Unconfigured*: the node is created but not configured. It can't do anything.
- *Inactive*: the node is configured but not active. It can do some things but not all.
- *Active*: the node is active and can do everything.
- *Finalized*: the node is finalized and can't do anything.

We can controll the state, we can check their health and control the transition between states. We can also use them to manage a correct startup and shutdown of the system.

#example()[
  See the computational graph. and see the demo
]

== TF Subsystem

Transformational matrix and TF tree are implemented in Ros. Ros should be able to handle trasformation, it should describe the position of the robot in a 3d space.

We need to interact when we want to ask: the position of the robot, the position of the sensors, the position of the obstacles, etc.

In order to change the frame of reference we need to work witrh TF system. We have for example a node that tell us the coordinates and want to change them frame of reference.

- `TF`: is a topic that give precise information about the dynamic transform that change in time. It's a *volatile topic*.

- `Static TF`: is a topic that give precise information about the static transform that don't change in time (for example the position of the sensors on the robot) like where the wheels are ecc. Tells the geometric configuration of the robot. it's a *transient local topic*, because the information is static and we want to deliver it to late joining subscriber.

If we recive a message about the transform we will find:
- The header: containg the timestamp (it's important because the transform can change in time) and the frame id (the name of the frame of reference of the message).

- The child frame id: the name of the frame of reference of the message

- The transform: the transformation between the two frame of reference (the one in the header and the child frame id). The translation is represented by a 3d vector, while the rotation is represented by a quaternion.

== Behavior

In the immage there is a behavior that describe the cleaning by an area. The robot execute a sequence of operation called `clean_room_sequence`.

The behavior is telling me the sequence of operation that i need to do, the order and the condition to perform then. A behavior tree is a formalism to describe the behavior of a robot. It's an alternative to final state machine (the state are action while the transiction are condition).

The root node sending the command to peridocly, this tick is propagated to the children accoarding to some logic (like DFS, BFS, ecc..).

Condition is something to be check, it can be verify or falsified. THe condition always return true or false. while acrion can retunr RUNNING (when the action is still executing), SUCCESS (when the action is completed successfully) or FAILURE (when the action is completed with failure).

In the image there is a behaivor tree that code a patroning robot:
- The root node is duing a fall back, we try to execute the children untill the first one return success.

- The first child is a battery check. If the battery is low the robot need to go to the charging station, so we execute the second child. If the battery is okay we move to the right root node.

When a child return a failure the check is repeted $N$ times. Before passing the failure to the parent node.

The tree es represented like a text format (XML, JSON, ecc..)
Behavior tree are cool but hard to use, the user use them to specify a goal/task for the robot. The solution is to use an LLM to generate the XML file that represent the mission.

Th behavior tree are a firebale solution, they can be esaly verified from a sintatic point of view. But the main problem is that the generated tree are not always correct from a semantic point of view. Maybe the robot can compile the tree but the logic is incorrect in respect of the specitication.444






