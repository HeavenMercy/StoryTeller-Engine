# StoryTeller Engine
A Godot plugin helping in building interactive fictions and dialog system.



### Creation of story

This engine can be created entirely in a GDScript or via the editor for the creation of narration (stories, interactive fictions, dialogs...)

1. via GDScript

The useful classes are: **st.StoryLock** (a boolean data), **st.StoryValues** (a float data), **st.StoryChunk** (a chunk of story), **st.StoryCommand** (a command to execute), **st.StoryTeller** (which tells story and executes commands), **StoryListener** (which hold values, locks, command option's values, namespaces to activate or not...). So the basic process is this one:

- Instanciate a **st.StoryListener** with two dictionaries names to values, *one for locks* and *another for values*

- If you need commands, load them (*listener*.load_commands(*[namespace...]*)) using instances of **st.StoryCommandNamespace**. 
in each namespace, it is possible to add **st.StoryCommand** (*namespace*.add_command(*command*)).

- Instanciate a **st.StoryTeller** with that listener and load **st.StoryChunk**s (*teller*.load_story_chunks(*[chunk...]*)

- Set the start point (*teller*.set_start_point(*chunk_id*)) of the story to a chunk id

*There we already have the teller for the next step*

2. via the editor

The two necessary classes are: **st.StoryInterpreter** (which is used to interpret a story file and **st.StoryTeller**.

- Open the editor, by clicking **st.StoryTeller** at the bar where *2d* and *3d* are.

- Make a story in the **Sandbox** and save it as a file. It is obviously possible to modify the file later.

- The steps it requires in GDScript to load the story:
    - get the default interpreter **st.get_default_interpreter()**
    - set a base path to get stories from (***interpreter*.set_base_path(*path*)**)
    - load a story file (***interpreter*.load_story(*story_filename*, *[custom_listener]*)**) [with extension or not]

*Loading the story from a file returns the teller for the next step*



### Execution of story

With the teller (**st.StoryTeller**) got we have the possibilities to tell the story and to execute a command.

1. Telling Story

Each story chunk can have a condition for it to get read/shown. So if a chunk has no condition or verified conditions, it is read by the teller. Delayed chunk are pushed into the stack of delayed chunks waiting for the moment to show.
The method of the teller to show story chunks is **tell( *delta* )**: *delta* is used to calculated elapsed time for delayed chunks. The method returns a string if there is a story chunk to read or else it returns **null**.

2. Executing Commands

Each command is in a particular namespace. if its namespace is activated, the command can be executed. The command can have a default chunk to read (always read or not) and option related to a chunk to read too. When a command is executed a list of chunks is registered for reading.
The method of the teller to execute a command is **execute( *command* )**: *command* is a string like "walk left=5". The method returns a boolean telling if the command has been successfully executed.


To see how the engine works, check the folder **scenes**. It contains a scripted story and the test scene which loads some stories.
The folder **assets/stories** contains the story created via the editor. It is possible to choose which story to load in the script **TestScene.gd** at line **36**.
