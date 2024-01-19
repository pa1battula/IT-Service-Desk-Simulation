breed [users customer]
breed [agents represetative ]


globals [
  issue-counter ; Tracks the total number of issues generated
  total-resolution-time ; Tracks the total time taken to resolve all issues
  avg-resolution-time ; Tracks the average time to resolve an issue
  resolution-time; Tracks each resolution time for each issue
  historical-request-data ; List to store historical request volumes
  current-request-volume;
  future-request-volume;


]

;
agents-own [
  busy? ; Whether the agent is currently assisting a user
  customer-task ; The current task assigned to the agent
]

users-own [
  issue-solved? ; Whether the user's issue is solved
  issue-generation-time ; Time when the user generated the issue

]

to setup
  clear-all
  reset-ticks
  set issue-counter 0
  set total-resolution-time 0
  set avg-resolution-time 0
  set historical-request-data []


  color-patches

  create-agents number_agent [
    set size 1.8
    set shape "die 4"
    set busy? false
    ;;setxy random-xcor random-ycor
     setxy number_agent * (who - count agents / 2) 10
  ]

  create-users number_customers [

    set issue-solved? false
    set size 1.8
    set shape "person student"
    set color 38
    set issue-generation-time ticks
    setxy number_customers * (who - count turtles / 2) -6  ;; Arrange turtles in a line
    ;;setxy random-xcor random-ycor
  ]

end
to color-patches
  ask patches [
    ; Change patch color based on its coordinates
    ifelse pxcor > 0 [
      set pcolor 42
    ] [
      set pcolor 38
    ]
  ]
end

to run-simulation

  while [ticks < number_customers + 5] [

    go
  ]


end

to go
  move-users
  assign-tasks
  process-tasks
  update-performance-metrics;
  tick
end

to move-users
  let available-agents agents with [not busy?]
  let unsolved-customers users with [not issue-solved?]

  while [any? unsolved-customers and any? available-agents] [

    let cust one-of unsolved-customers
    ask users [
      let nearest-agent min-one-of available-agents [distance myself]
      face nearest-agent
      fd 3
    ]
    set available-agents other available-agents
    set unsolved-customers other unsolved-customers with [self != cust]
  ]

end

to assign-tasks
  user-behavior
  agent-behavior

  ask agents [
    if not busy? [
      let user-request one-of users with [not issue-solved?]
      if user-request != nobody [
        ; Introduction stochasticity in agent assignment
        let random-agent one-of agents
        set customer-task user-request
        set busy? true
      ]
    ]
  ]

end

to process-tasks

  ask agents [
    if busy? [
      let user-task customer-task

      if not [issue-solved?] of user-task [

        ; Simulate resolving the issue with stochastic resolution time
        let resolution-times random-normal mean_value standard_deviation ; Mean: 60, Standard Deviation: 20 (default values)

        ; Simulate resolving the issue
        ; For example: [set [issue-solved?] of user-task true]
        ; Calculate resolution time
        set resolution-time ticks - [issue-generation-time] of user-task
        set total-resolution-time total-resolution-time + resolution-time
        set issue-counter issue-counter + 1
        set avg-resolution-time total-resolution-time / issue-counter

        ; If the issue is solved, remove the customer turtle
        ask user-task [
          ifelse issue-solved?[
            die ; Remove the customer turtle
          ] [
            set issue-solved? true ; Simulate the issue being solved
          ]
        ]
      ]

      set busy? false
      set customer-task nobody
    ]
  ]
end



to agent-behavior
  ask agents [
    if not busy? [
      ; Agents select a user's task to work on based on the user's wait time
      let user-request one-of users with [not issue-solved?]
      if user-request != nobody [
        ; Introduce priority based on user wait time
        let wait-time ticks - [issue-generation-time] of user-request
        if wait-time > 20 [ ; Adjust the threshold as needed
          set customer-task user-request
          set busy? true

        ]
      ]
    ]
  ]
end

to user-behavior
  ask users [
    if not issue-solved? [
      ; Simulate users generating issues based on certain conditions or triggers
      ; For example, you can introduce issue generation based on time or user-specific factors
      if random-float 1.0 < 0.1 [ ; Adjust the probability as needed
        generate-issue
      ]

      ; Simulate users' behavior in choosing agents to seek assistance
      if random-float 1.0 < 0.5 [ ; Adjust the probability as needed
        ; Users randomly select an agent to request help
        request-assistance
      ]
    ]
  ]
end

to generate-issue
  ; Simulate the generation of an issue
  set issue-solved? false
  let current-time ticks  ; Get the current time (ticks) in the simulation
  set issue-generation-time current-time ; Set the generation_time for the user

end

; user persistance
to request-assistance
  ; Simulate users choosing an agent to request assistance
  let available-agents agents with [not busy?]
  ifelse any? available-agents [
    ; Users randomly select an available agent to request help
    let selected-agent one-of available-agents
    ask selected-agent [
      if not busy? [
        set customer-task myself ; Assign the user's task to the selected agent
        set busy? true
      ]
    ]
  ] [

  ]
end


to-report logistic-function [x k r]
  report 1 / (1 + exp (-(k) * x + r))
end

to update-performance-metrics
  visualize-and-report
  ; Update global parameters
  set avg-resolution-time (ifelse-value issue-counter = 0 [1] [total-resolution-time / issue-counter])

 ; Example of using the logistic function with a variable x
  let x avg-resolution-time ; You can replace this with any variable you want
  let k 1 ; Adjust the k and r values as needed
  let r 2
  let result logistic-function x k r



  print (word "Logistic transformation of Avearge resolution time: " result)
end

to visualize-and-report

  ask agents [
    ifelse busy? [
      set color red ; Visualize busy agents
    ]
      [
      set color blue ; Visualize available agents
    ]
  ]
  ask users [
    ifelse issue-solved? [
      set color green ; Visualize users with solved issues
    ] [
      set color yellow ; Visualize users with unresolved issues
    ]
  ]


  ; Reporting: Export relevant data to a CSV file for analysis
  let data-file "C:/Users/lenovo/OneDrive/Desktop/simulation_data.csv" ; Choose a file name and location
  ifelse file-exists? data-file [
    file-open data-file
    file-print (word "Ticks, Agent Count, User Count, Total Issues, Average Resolution Time")
    file-print (word ticks ", " count agents ", " count users ", " issue-counter ", " avg-resolution-time)
    file-close
  ] [
    file-open data-file
    file-print (word "Ticks, Agent Count, User Count, Total Issues, Average Resolution Time")
    file-print (word ticks ", " count agents ", " count users ", " issue-counter ", " avg-resolution-time)
    file-close
  ]
 record-historical-data;

end


to record-historical-data
  ; For simplicity, assume you're recording request volume every tick
  set current-request-volume count users with [not issue-solved?]
  set historical-request-data lput current-request-volume historical-request-data
  if ticks > number_customers [
   predict-request-volume pridiction-years
  ]

end

to predict-request-volume [input-years]
  let slope calculate-slope historical-request-data
  set future-request-volume current-request-volume + (slope * input-years)

end

to-report calculate-slope [data]
  let n length data ; Number of data points
  let sum-x reduce + data ; Sum of x-values
  let sum-y reduce + (range 1 n) ; Sum of y-values

  let mean-x mean data ; Mean of x-values
  let mean-y mean (range 1 n) ; Mean of y-values

  let yy-sum reduce + (map * (range 1 n) (range 1 n)) ; Sum of (y * y)
  let xx-sum reduce + (map * data data) ; Sum of (x * x)

  let slope (yy-sum - n * mean-x * mean-y) / (xx-sum - n * mean-x * mean-x)

  report slope
end
@#$#@#$#@
GRAPHICS-WINDOW
568
10
1505
556
-1
-1
16.3
1
10
1
1
1
0
1
1
1
-28
28
-16
16
0
0
1
ticks
30.0

BUTTON
30
62
93
95
SET
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
134
63
197
96
GO
run-simulation
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
24
164
113
209
NIL
issue-counter
17
1
11

MONITOR
136
164
262
209
NIL
total-resolution-time
17
1
11

MONITOR
297
165
418
210
NIL
avg-resolution-time
17
1
11

TEXTBOX
50
138
200
156
Output Monitors
14
0.0
1

TEXTBOX
32
280
182
298
Input Sliders
14
0.0
1

SLIDER
33
307
205
340
number_agent
number_agent
1
50
40.0
1
1
NIL
HORIZONTAL

SLIDER
31
344
203
377
number_customers
number_customers
1
500
201.0
1
1
NIL
HORIZONTAL

PLOT
358
230
558
380
average-resolution-time
Time
avg-resolution-time
0.1
10.0
0.1
10.0
true
false
"" ""
PENS
"default" 1.0 0 -955883 true "" "plot avg-resolution-time"

SLIDER
30
385
202
418
pridiction-years
pridiction-years
1
25
20.0
1
1
NIL
HORIZONTAL

MONITOR
121
227
261
272
future-request-volume
future-request-volume
17
1
11

PLOT
356
399
556
549
T.resol-time and future-reqt-vol
pridition-years
future-request-volume
1.0
25.0
0.0
750.0
false
false
"" ""
PENS
"pridiction-years future-request-volume" 1.0 0 -7500403 false "plot future-request-volume" "plotxy pridiction-years future-request-volume"
"pen-1" 1.0 0 -2674135 true "" "plot total-resolution-time"

SLIDER
30
460
202
493
mean_value
mean_value
10
100
60.0
1
1
NIL
HORIZONTAL

SLIDER
32
500
204
533
standard_deviation
standard_deviation
1
50
10.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This is an IT Service Desk simulation model. It is used to simulate a system involving agents and users interacting to resolve issues. 

## ODD (Overview, Design concepts, Details)

##Overview section
Purpose and Patterns:
The purpose of this model is to simulate an issue resolution system involving agents assisting users with problems, tracking issue resolution times, and monitoring performance metrics. Agents randomly select tasks from unresolved user issues and simulate resolving these issues with stochastic resolution times. Users generate issues randomly and interact with available agents to seek assistance, while the system monitors and updates key performance indicators like average resolution time and issue counts over time. The model showcases basic agent-user interactions, issue resolution dynamics, and performance metric tracking within a simulated support system.

Entities, State Variables, and Scales:
Entities:
Users (Customers):
Attributes: issue-solved?, issue-generation-time
Agents (Representatives):
Attributes: busy?, customer-task

State Variables:
Globals:
issue-counter: Tracks the total number of issues generated.
total-resolution-time: Tracks the cumulative time taken to resolve all issues.
avg-resolution-time: Tracks the average time to resolve an issue.
resolution-time: Tracks individual resolution times for each issue.

Scales:
Agent Scale:
Agents represent individuals assisting users.
User Scale:
Users represent individuals generating issues and seeking assistance.

Relationships:
User-Agent Interaction:
Users request assistance from available agents.
Agents select tasks based on user-generated issues.
Issue Resolution:
Agents attempt to resolve user-generated issues.

Dynamics:
Issue Generation: Users generate issues randomly.
Agent Task Assignment: Agents randomly select tasks from unresolved user issues.
Issue Resolution Dynamics: Agents simulate resolving issues with stochastic resolution times.

Process Overview and Scheduling:
The model's process begins with user-generated issue creation and agent assignment, where agents randomly select tasks from unresolved issues. Subsequently, agents attempt to resolve assigned issues with stochastic resolution times. Performance metrics are updated and visualized at each simulation tick to monitor issue resolution and agent-user interactions.

##Design Concepts section:
Basic Design Principles:
The model adheres to simplicity by focusing on fundamental interactions between agents and users in an issue resolution system. It employs randomness in agent task assignment and issue resolution times, introducing stochastic elements to simulate real-world variability. Additionally, the model integrates a feedback loop by continuously updating and visualizing performance metrics to monitor and analyze the system's efficiency and resolution dynamics.

Emergence:
This model exhibits emergent properties through the interplay of agents and users, leading to observable patterns such as varying agent workload and average resolution times. The emergence of these behaviors stems from the decentralized decision-making of agents and the stochastic interactions between users and agents over time. However, the simplicity of agent behaviors and the absence of environmental complexities might limit the depth of emergent phenomena observed in the system. The emergence of patterns, like changes in agent availability and issue resolution times, highlights the model's ability to showcase emergent properties resulting from the collective actions of individual entities. Overall, while demonstrating emergent behavior to some extent, enriching the model with more intricate agent-user dynamics could enhance the depth and richness of emergent phenomena.

Sensing and Adaptive Behavior:
In the given model, sensing manifests through agents and users observing their environment for task assignments, agent availability, and issue statuses. Agents sense user-generated issues and adapt their behavior based on task priorities, considering the wait times of users. Users, on the other hand, adapt by choosing agents probabilistically and generating issues based on certain triggers or conditions. This adaptive behavior drives the dynamic allocation of tasks and influences the resolution times as entities respond to changing conditions. Introducing more sophisticated sensing mechanisms, like user-specific preferences or agent skill levels, and enhancing adaptive behaviors could further refine the model's responsiveness to the changing dynamics within the system, fostering more nuanced and realistic interactions.

objectives:
Simulating Service Resolution: To emulate the process of issue resolution within an IT service desk context, tracking the time taken to resolve issues and the overall efficiency of issue resolution.

Agent Behavior Exploration: To observe how agents (representatives and users) interact in resolving issues, exploring scenarios where users seek assistance and representatives handle tasks based on user priorities.

Performance Metrics Analysis: To compute and visualize key performance indicators like average resolution times, agent utilization, and issue-solving rates, aiding in understanding system efficiency and bottlenecks.

Visualization and Reporting: To provide visual representations of the model's dynamics, such as agent availability, issue resolution, and user satisfaction, alongside generating data for further analysis or reporting.

Understanding Dynamics: To study the impact of various parameters, like agent availability thresholds and user issue generation probabilities, on the overall efficiency and dynamics of the service desk system.

Prediction:
Predicting the outcomes of the model would involve estimating various metrics like average resolution time, total issues addressed, and the status of unresolved issues. By considering the stochastic nature of issue generation and resolution times, predictions could involve probabilistic forecasts of the number of issues resolved within specific timeframes. One might anticipate trends such as increased resolution times when user-generated issues exceed agent capacities or a decrease in unresolved issues as task assignment strategies evolve. However, precise predictions could be challenging due to the randomness embedded in issue generation, agent-task allocation, and resolution times. Fine-tuning these probabilities or introducing more complex patterns could enhance prediction accuracy.

Interaction:
The interaction in this model occurs through several layers. First, users generate issues randomly, mimicking real-world scenarios where problems arise without a fixed pattern. Agents then interact with these issues based on criteria like user wait times, simulating a dynamic allocation of tasks. The interaction intensifies as agents resolve issues, affecting global metrics like average resolution time and total issues resolved. Moreover, the visualization aspect of color changes signifies the interaction between agents and users, representing their status - busy, available, solved, or unresolved. Finally, the file output mechanism encapsulates the interaction by capturing data for external analysis, enabling insights into the model's performance and behavior.

Stochasticity:
The model utilizes stochastic elements primarily for generating and managing task allocation and resolution times. It employs random-float and random-normal functions to introduce various kinds of randomness. The random-float function aids in the probabilistic generation of issues by users and the selection of agents by users seeking assistance. On the other hand, the random-normal function is applied to simulate stochastic resolution times, allowing for a more realistic representation of the time taken to resolve issues. This stochasticity emulates real-world scenarios where task generation, task allocation, and resolution times are inherently uncertain, contributing to a more dynamic and lifelike simulation. By incorporating these random elements, the model mirrors the inherent unpredictability and variability present in issue generation, task assignment, and issue resolution processes, enriching its ability to simulate complex real-world scenarios in customer service or issue management systems.

Collectives:
In the model, the collectives are represented by the breed of agents (representatives) and users (customers). Agents operate collectively as a group of representatives responsible for resolving issues, managing tasks, and providing assistance. Users collectively form the group of customers generating issues and seeking help. The interactions between these collectives drive the dynamics of the simulation, as users trigger issues, request assistance, and agents handle tasks. The behaviors and interactions within each collective impact the overall system dynamics, where agents collectively affect issue resolution and users collectively influence the generation and resolution of issues. The emergent behavior, such as system efficiency or issue resolution rate, stems from the interactions and collective actions of these groups, illustrating the role collectives play in shaping the model's dynamics.
Task Allocation Pattern: Agents select tasks based on user wait times, introducing priority for longer waiting users. This pattern might represent a "First-Come, First-Served" approach or a priority-based task allocation system in real-world scenarios.

Pattern-Oriented Modeling:
Issue Resolution Time Pattern: The stochastic resolution time simulation introduces variability in resolving issues, following a normal distribution. This pattern mirrors the uncertainty often seen in real-life problem-solving scenarios, where resolution times may vary due to complexity or other factors.

Agent-User Interaction Pattern: Users randomly generate issues and choose agents for assistance based on certain probabilities. This pattern could represent user behavior, where issue generation and agent selection are somewhat probabilistic or based on user-specific factors.

Agent Movement and Task Handling Pattern: Agents move towards users needing assistance and handle tasks when available. This behavior might represent the real-world scenario of agents attending to users' needs, moving to assist and resolving issues.

Visualization and Metrics Tracking Pattern: The model keeps track of various metrics such as resolution times, agent and user states, and issues solved. Additionally, the model visualizes the system's state by coloring agents and users based on their status. This pattern reflects the need for monitoring and visual representation in real systems to track performance and status.

Heuristics:
Priority-Based Task Assignment: Agents prioritize tasks based on user wait times, allocating resources to users who have been waiting longer. This heuristic mimics a common real-world strategy of addressing urgent or long-pending issues first, optimizing overall satisfaction by reducing wait times for users.

Stochastic Issue Resolution: The model introduces stochasticity in issue resolution times using a normal distribution. This heuristic reflects the variability in real-world problem-solving scenarios, where issue resolution times can vary due to complexities or unforeseen challenges, leading to more accurate representations of realistic scenarios.

Randomness in User Behavior: Users generate issues and select agents for assistance based on random probabilities. This heuristic replicates the unpredictability often found in user behaviors or requests, which isn't entirely deterministic. By incorporating randomness, the model captures the diverse and unpredictable nature of real users seeking assistance.

##Sensitivity Analysis Parameters:
Agent Count and User Count: Vary the initial count of agents and users to observe how changing these numbers affect overall performance metrics.

Issue Generation Probability: Alter the probability in the user-behavior procedure (random-float 1.0 < 0.01) to generate issues more or less frequently and observe the impact on issue resolution time.

Resolution Time Parameters: Change the mean and standard deviation values in the process-tasks procedure (let resolution-times random-normal 50 10) to simulate different resolution times for issues.

Wait Time Threshold: Adjust the threshold value in the agent-behavior procedure (if wait-time > 50) to change when agents decide to take tasks based on user wait times.

Logistic Function Parameters: Modify the parameters k and r in the logistic-function procedure to adjust the shape and curve of the logistic transformation of average resolution time.

Steps for Sensitivity Analysis:
Parameter Variation: Change one parameter at a time while keeping others constant.

Observation: Run simulations with varied parameters and observe how changes affect the following metrics:

Average Resolution Time: How does it change with different issue frequencies, agent counts, or resolution time variability?
Agent Utilization: How busy are the agents with varying issue generation rates or user counts?
Logistic Transformation: How does the logistic transformation change concerning different values of k and r?
Data Collection: Record the outcomes of each simulation run, noting the impact of parameter changes on the performance metrics.

Visualization and Analysis: Plot graphs or charts to visualize the relationship between the parameters and performance metrics.

Initialization:
The model begins by initializing global variables such as issue counters and time trackers to zero, establishing a clean slate for tracking performance metrics. It creates two breeds, 'agents' and 'users,' allocating specific attributes to each. Agents are positioned with defined shapes and initial states, whereas users are set up with unresolved issues, specific shapes, and issue generation times. Patch colors are adjusted based on coordinates, distinguishing different spatial areas. The setup creates an environment where agents and users are ready to interact, addressing issues and evolving their states over time.

Input Data:
Number of agents: Determines the quantity of agents created within the simulation.

Number of customers/users: Specifies the count of users generated in the simulation, each with its own unresolved issue and associated characteristics.

Attributes of agents and users: These include properties such as 'busy?' to track agent availability, 'issue-solved?' to denote the resolution status of user issues, 'issue-generation-time' to mark when the user issue was generated, among others.

Stochastic elements: Utilized for simulating resolution times ('resolution-times') based on a normal distribution to introduce variability in resolving issues.

Probabilistic behaviors: Dictate the likelihood of events like issue generation and agent selection by users for assistance, allowing for varying user-agent interactions.

Distinct Submodels:
Agent Behavior Submodel: This submodel encompasses the behavior of agents, including their task assignment logic, prioritization based on user wait times, and their availability status ('busy?').

User Behavior Submodel: It defines the behavior of users, including issue generation, agent selection for assistance, and the conditions triggering issue generation or assistance requests.

Task Processing Submodel: Handles the process of resolving issues by agents, tracking resolution times, updating global metrics, and managing the state of issues ('issue-solved?') for users.

Visualization and Reporting Submodel: Responsible for visualizing the agents and users in different colors based on their status (busy, unresolved issues, etc.), and generating reports or exporting data for analysis.

Initialization Submodel: Governs the initial setup of the simulation environment, creating agents and users, assigning initial properties, and setting up the simulation parameters.

## HOW IT WORKS
The agents in the model follow a set of rules that dictate their behavior within the simulated environment. These rules govern how agents interact with users, select tasks, and manage their workload. Here are the key rules that drive the behavior of the agents:

1. Task Assignment:
Agent Availability: Agents assess their availability by checking if they are busy.
User's Wait Time: Agents prioritize tasks based on the wait time of users. The longer a user has been waiting, the higher the likelihood of an agent selecting that user's task.
2. Interaction with Users:
Request Handling: Agents select a user's task if they are available and the user has an unresolved issue.
Agent-User Pairing: When available, an agent takes on the task of a user who meets the criteria of wait time and unresolved issue.
3. Task Processing:
Issue Resolution: Agents simulate resolving the user's issue, incorporating stochastic resolution times (using random-normal distribution) to reflect varying resolution durations.
Updating Metrics: After resolving an issue, agents update performance metrics such as total resolution time, issue counter, and average resolution time.
4. Visualization and Reporting:
Status Visualization: Agents change their color based on their availability (red for busy, blue for available) to provide a visual representation of their status within the simulation.
Data Reporting: Agents contribute to reporting by adding relevant data to a CSV file, including the number of resolved issues and average resolution time at each tick.
5. Loop Control:
Loop Participation: Agents participate in the main simulation loop, performing their designated tasks iteratively at each simulation tick.
Overall Behavior:
Agents act as service providers, managing their workload by prioritizing tasks based on user wait times. They attempt to resolve issues efficiently while keeping track of system metrics. The behavior aims to reflect a service-oriented approach, where agents dynamically select tasks based on criteria that optimize issue resolution and user satisfaction.

These rules collectively create a system where agents interact with users, manage their workload, and contribute to the overall performance evaluation by resolving issues and updating metrics in the simulation.

## HOW TO USE IT

Interface Tab Components:

Setup Button:
Description: Clicking this button initializes the simulation by creating agents and users at random positions.

Usage: Click once at the start of the simulation to set up the environment.
Run Simulation Button:

Description: Executes the main loop for a specified number of ticks.
Usage: Click after the setup to start the simulation. It iterates through the ticks, simulating agent-user interactions.

Interface Control:
Max Ticks Input Field:
Description: Allows you to set the maximum number of ticks for the simulation.
Usage: Enter the desired number of ticks before starting the simulation.
Visualization:
Agents:

Representation: Dots or shapes (can be customized in the code).
Color Indication: Blue (available) or red (busy).
Behavior: Move around and change color based on availability.
Users:

Representation: Dots or shapes (can be customized in the code).
Color Indication: Yellow (unresolved issue) or green (resolved issue).
Behavior: Move around until their issue is resolved, then change color.

Metrics Display:
Logistic Transformation of Average Resolution Time:
Description: Displays the result of a logistic function applied to the average resolution time.
Usage: Provides a transformed value of the average resolution time using a logistic function.

Data Export:
Simulation Data Export to CSV:
Description: Saves simulation data (ticks, agent count, user count, total issues, average resolution time) to a CSV file for analysis.
Usage: Automatically exports data to a specified file path for further analysis.

Simulation Flow:
Setup:
Click "Setup" to create agents and users.
Enter the desired number of ticks.
Run Simulation:
Click "Run Simulation" to start the simulation.
Agents will interact with users, resolve issues, and update metrics.
Visualize the movement of agents and users.
Observation:
Watch as agents change color based on their availability.
Observe users changing color when their issues are resolved.

Data Analysis:
Access the exported CSV file for detailed analysis of simulation metrics.
Usage Tips:
Adjust parameters in the code (e.g., probabilities, thresholds) for different simulation behaviors.
Observe changes in agent behavior based on modifications in the code.
Review the exported CSV file for detailed simulation metrics.

Running the Model:
Open NetLogo and copy-paste the provided code into the code editor.
Navigate to the "Interface" tab.
Click "Setup" and then enter the number of ticks.
Click "Run Simulation" to start the simulation.
Ensure you have NetLogo installed and are running the model within its environment to execute and observe the simulation.

## THINGS TO NOTICE
 Running the simulation provides a chance to observe various dynamics within the modeled system. Here are some aspects and behaviors you can focus on to better understand the simulation:

Agent-User Interaction:
Task Assignment Dynamics: Notice how agents choose tasks based on user wait times. Observe if longer-waiting users are prioritized.
User Selection by Agents: See which users are selected by agents and how often. Observe if certain users tend to be picked more frequently.

Agent Behavior:
Agent Availability: Track how often agents are busy versus available. See if there are patterns or periods of high or low availability.
Task Completion Time: Observe the range of resolution times for issues. Note how fast or slow agents resolve problems.

User Behavior:
Issue Generation Rate: Monitor how frequently users generate issues. Observe if there are spikes or consistent rates of issue generation.
Agent Selection by Users: See if users tend to select specific agents more often than others when requesting assistance.

System Performance:
Average Resolution Time: Watch how this metric changes over time. Note if there are trends or fluctuations.
Impact of Parameters: Experiment with adjusting parameters (e.g., probabilities, thresholds) and observe how it affects system performance.

Visual Observations:
Agent Movement Patterns: Notice if agents follow certain movement patterns or if their movements seem random.
Color Changes: Observe how colors change for agents and users based on their status (availability and issue resolution).

CSV Data Analysis:
Trends Over Time: Analyze the exported CSV file to see how metrics change over ticks.
Correlations: Look for correlations between different metrics (e.g., agent availability and average resolution time).

Overall Observations:
Emergent Behavior: Identify any emergent patterns or behaviors that arise from interactions between agents and users.
System Efficiency: Assess the overall efficiency of issue resolution and agent utilization.
By focusing on these aspects while running the simulation and analyzing the data generated, you can gain insights into the dynamics, behaviors, and efficiency of the simulated agent-user interaction system.

## THINGS TO TRY
Absolutely! Experimenting with different settings and controls can offer valuable insights into how changes impact the simulation. Here are some suggested actions for users to try within the model's interface:

Adjusting Parameters:
Max Ticks:
Usage: Increase or decrease the maximum number of simulation ticks.
Effect: Observe how longer or shorter simulation durations impact overall metrics and system behavior.
Probabilities:

Usage: Modify the probabilities in the code (e.g., probability of issue generation, agent selection).
Effect: See how altering these probabilities changes the frequency of events such as issue generation or agent-user interactions.
Interacting with Controls:
Clicking Setup and Run:

Usage: Click "Setup" multiple times or run the simulation without setting up initially.
Effect: Observe how the environment initializes or changes during runtime.
Pause and Resume:

Usage: Implement a pause feature by adding a toggle switch for simulation pausing.
Effect: Control the simulation flow to observe specific states or events without progressing through all ticks.
Visualizations:
Agent/User Count:

Usage: Add counters or plots to visualize the count of agents, users, or resolved issues over time.
Effect: Track how counts change throughout the simulation.
Color Coding:

Usage: Modify color assignments for agents or users based on different criteria (e.g., issue severity, resolution time).
Effect: Visualize different attributes through color changes, aiding in observing specific states or conditions.
Dynamic Changes:
Dynamic Parameter Adjustment:

Usage: Implement sliders or buttons to dynamically change parameters during the simulation.
Effect: Observe real-time effects of parameter adjustments on system behavior.
Introducing New Metrics:

Usage: Add new metrics for tracking additional aspects (e.g., agent-user interaction frequency, average wait time).
Effect: Gain a deeper understanding of specific dynamics by monitoring newly introduced metrics.
Scenario Testing:
Extreme Scenarios:

Usage: Test extreme scenarios (e.g., very high issue generation rates, low agent availability).
Effect: Understand how the system behaves under stress or unique circumstances.
Threshold Adjustments:

Usage: Modify thresholds (e.g., wait time threshold for agent task assignment).
Effect: Observe changes in agent behavior based on altered thresholds.
By experimenting with these controls and adjustments, users can gain a better understanding of the model's sensitivity to parameters, explore various scenarios, and observe how changes affect the simulated agent-user interaction dynamics.

## EXTENDING THE MODEL

To augment the complexity and accuracy of the model, consider integrating the following elements and improvements:

1. Enhanced Agent Behavior:
Agent Attributes: Assign specific skills or expertise levels to agents, impacting their efficiency in resolving certain issue types.
Agent Communication: Allow agents to share information or collaborate on complex issues, affecting resolution time and accuracy.
Task Queues: Implement a queue system for agents to manage multiple tasks, prioritizing based on urgency or complexity.
2. Refined User Behavior:
Issue Types: Introduce different types of issues with varying difficulties or urgency levels, influencing user behavior and agent task allocation.
User Preferences: Define user preferences for specific agents or issue types, impacting their choices when seeking assistance.
3. Dynamic Environment Modeling:
Environmental Factors: Incorporate environmental factors affecting issue resolution (e.g., resource availability, external disruptions).
Temporal Patterns: Introduce time-related patterns in issue generation or agent availability, reflecting real-world fluctuations.
4. Advanced Metrics and Reporting:
Comprehensive Metrics: Calculate additional metrics like agent utilization, issue backlog, average wait time for users, and user-agent matching efficiency.
Real-time Visualization: Create dynamic visualizations showcasing metrics' changes during the simulation.
5. Simulation Controls and Interaction:
User Intervention: Allow user intervention to assign tasks, influence agent behavior, or generate specific issues during the simulation.
Scenario Testing: Implement preset scenarios or testing modes to observe specific system behaviors or stress-testing.
6. Model Validation and Sensitivity Analysis:
Validation Measures: Introduce mechanisms to validate the model against empirical data or known system behaviors.
Sensitivity Testing: Perform systematic sensitivity analyses for various parameters, observing their impact on the system's behavior.
7. Advanced Modeling Techniques:
Agent Learning: Implement learning algorithms for agents to adapt their strategies based on experience or observed patterns.
Multi-level Interactions: Model interactions at multiple levels, including organizational hierarchies or customer-agent relations.
Code Improvement Suggestions:
Modularization: Refactor code into reusable functions or procedures for better readability and maintenance.
Comments and Documentation: Add comprehensive comments and documentation to explain complex functions or sections of the code.
By incorporating these enhancements and refining the existing code structure, the model can simulate more realistic agent-user interactions, capture nuanced system dynamics, and provide deeper insights into issue resolution processes within a simulated environment.

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)
Monitors for globals, patches, and Turtles.
Switch to 3D view from 2D(Default 2D).
Turtle shape Editors.
Link shape editors.


## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)
Random Basic.
Stochastic Patchwork.
Wolf Sheep Predation.
Scattering.
etc... (i took different from different models)


## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)

https://www.valpo.edu/computing-information-sciences/faculty/sonja-streuber/
https://ccl.northwestern.edu/netlogo/models/
Lerning Models
Angent based modeling Text book
https://ccl.northwestern.edu/netlogo/docs/dictionary.html
https://ccl.northwestern.edu/netlogo/docs/programming.html#agents
https://ccl.northwestern.edu/netlogo/models/
etc...
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

die 4
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 69 189 42
Circle -16777216 true false 189 69 42
Circle -16777216 true false 189 189 42

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person student
false
12
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true false 195 90 240 195 210 210 165 105
Circle -7500403 true false 110 5 80
Rectangle -7500403 true false 127 79 172 94
Polygon -7500403 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true false 105 90 60 195 90 210 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
