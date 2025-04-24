from langchain_core.messages import convert_to_messages
from langchain_core.messages import HumanMessage,SystemMessage,AIMessage,ToolMessage

def pretty_print_messages(update):
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