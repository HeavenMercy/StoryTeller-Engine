�
     
         last_node_id         
   namespaces                    id               name      default       ini_val             locks                values               scroll_offset      �?�@�6B      links                     from   	   StartNode      	   from_port                to        StoryChunkNode        to_port                    from      CommandNode    	   from_port                to        StoryChunkNode2       to_port                    from      CommandNode2   	   from_port                to        StoryChunkNode3       to_port                    from      StoryChunkNode3    	   from_port                to        EndNode       to_port                    from      StoryChunkNode2    	   from_port                to        EndNode       to_port              start_offset      A  *C   
   end_offset       *D  �C      story_chunks               	   node_name         StoryChunkNode3       data            id        ignored       content    �   [color=gray]You ignore the storyteller[/color]
His eyes start to shine with a strange feeling of malice.
"Welcome to my new world", he says       delay                inverse_condition                condition_only            
   conditions                     updates              offset       �C  �C         	   node_name         StoryChunkNode2       data            id        said_hi       content    �   [color=gray]You reply to the storyteller.[/color]
He smiles to  the ears like a freaking maniac.
"Welcome to my new world", he says       delay                inverse_condition                condition_only            
   conditions                     updates              offset       �C  pC         	   node_name         StoryChunkNode        data            id        intro         content    �   The story teller says "Hello" to you!
[color=gray]you can answer [color=aqua]hi[/color] or [color=aqua]ignore[/color] him[/color]         delay                inverse_condition                condition_only            
   conditions                     updates              offset        C  �B      commands               	   node_name         CommandNode2      data            namespace_id             name      ignore        default_always               options              offset        A  �C         	   node_name         CommandNode       data            namespace_id             name      hi        default_always               options              offset        A  �C