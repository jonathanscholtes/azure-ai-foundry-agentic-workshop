from langchain_core.messages import convert_to_messages
from langchain_core.messages import HumanMessage,SystemMessage,AIMessage,ToolMessage

def pretty_print_messages(update):
    """
    Prints updates from a graph or subgraph, displaying node-specific messages.

    If the update comes from a subgraph, the subgraph ID is printed. Then, for each node in the update, 
    the messages are printed using `pretty_print`.

    Args:
        update (tuple or dict): 
            - If a tuple, the first element is the namespace (`ns`), and the second is the update.
            - If a dict, it directly contains node updates.

    The function prints:
        - Subgraph ID (if applicable).
        - Messages for each node in the update.
    """
    if isinstance(update, tuple):
        ns, update = update
        # skip parent graph updates in the printouts
        if len(ns) == 0:
            return

        graph_id = ns[-1].split(":")[0]
        print(f"Update from subgraph {graph_id}:")
        print("\n")

    for node_name, node_update in update.items():
        print(f"Update from node {node_name}:")
        print("\n")

        if node_update:
            for m in convert_to_messages(node_update["messages"]):
                m.pretty_print()
        print("\n")


def extract_graph_response(query, graph):
    """
    Function to stream the graph and extract the final human response.
    
    Args:
    - query: The user query to send to the graph.
    - graph: The graph object to stream from.
    
    Returns:
    - final_response: The content of the last human message if found, otherwise None.
    """
    final_response = None  
    
    # Start streaming the graph with the provided query
    for step in graph.stream(
        {"messages": [{"role": "user", "content": query}]}
    ):

        for key in step:
            if step[key] and 'messages' in step[key]:
                human_messages = [msg for msg in step[key]['messages'] if isinstance(msg, HumanMessage)]
                if human_messages:
                    final_response = human_messages[-1].content

    return final_response


def pretty_print_response(conversation):
    """
    Prints a conversation in a human-readable format, distinguishing between 
    human, AI, and tool messages.

    Args:
        conversation (dict): A dictionary containing a 'messages' key with a list 
                              of message objects (HumanMessage, AIMessage, ToolMessage).
    
    Message formats:
        - "Human: " for human messages.
        - "AI: " for AI messages, with tool calls logged.
        - "Tool `<tool_name>` Response: " for tool responses.
        - "Unknown Message Type: " for unrecognized messages.
    """
    for message in conversation['messages']:
        if isinstance(message, HumanMessage):
            print(f"Human: {message.content}")
        elif isinstance(message, AIMessage):
            tool_calls = message.additional_kwargs.get("tool_calls", [])
            if tool_calls:
                print(f"AI: (Tool Call Triggered)")
                for tool in tool_calls:
                    func_name = tool.get("function", {}).get("name")
                    args = tool.get("function", {}).get("arguments")
                    print(f"   Calling `{func_name}` with args: {args}")
            else:
                print(f"AI: {message.content}")
        elif isinstance(message, ToolMessage):
            print(f"Tool `{message.name}` Response: {message.content}")
        else:
            print(f"Unknown Message Type: {message}")
        print("\n")