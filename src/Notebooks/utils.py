import base64
import re
import requests
from langchain_core.messages import convert_to_messages
from langchain_core.messages import HumanMessage,SystemMessage,AIMessage,ToolMessage
from typing import Optional

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


def _kernel_process_to_mermaid(kernel_process) -> str:
    lines = ["graph TD;"]

    # Assign letter aliases to step IDs (e.g., A, B, C, ...)
    step_id_to_alias = {}
    step_id_to_name = {}
    alias_iter = (chr(i) for i in range(ord("B"), ord("Z") + 1))  # Start from B, reserve A for Start
    for step in kernel_process.steps:
        step_id = step.state.id
        step_name = step.state.name
        alias = next(alias_iter)
        step_id_to_alias[step_id] = alias
        step_id_to_name[step_id] = step_name

    # Add Start node
    lines.append('    A([Start])')

    # Connect Start to initial steps
    for output_name, targets in kernel_process.output_edges.items():
        for edge in targets:
            target_id = edge.output_target.step_id
            target_alias = step_id_to_alias[target_id]
            target_name = step_id_to_name[target_id]
            lines.append(f'    A--> {target_alias}[{target_name}]')

    # Draw all internal edges
    for step in kernel_process.steps:
        source_id = step.state.id
        source_alias = step_id_to_alias[source_id]
        for edges in step.output_edges.values():
            for edge in edges:
                target_id = edge.output_target.step_id
                target_alias = step_id_to_alias[target_id]
                target_name = step_id_to_name[target_id]
                lines.append(f'    {source_alias}--> {target_alias}[{target_name}]')

    # Identify all source steps
    all_sources = {step.state.id for step in kernel_process.steps}

    # Identify all source steps (steps that produce outputs)
    all_sources_outputs = {
    step.state.id
    for step in kernel_process.steps
    for edges in step.output_edges.values()
    for edge in edges  # These are the edges produced by the step
}
    
    #for src in all_sources:
    #    print(step_id_to_name[src])
    #    print(step_id_to_alias[src])

    # Identify all target steps (steps that consume outputs)
    #all_targets = {
    #    edge.output_target.step_id
    ##    for step in kernel_process.steps
    #    for edges in step.output_edges.values()
    #    for edge in edges  # These are the steps that consume the outputs of other steps
    #}

    # Find terminal steps: steps that are sources but not targets
    terminal_ids = all_sources - all_sources_outputs


    # Ensure the last step (terminal step) connects to End
    for term_id in terminal_ids:
        source_alias = step_id_to_alias[term_id]
        lines.append(f'    {source_alias}--> Z([End])')  # Connect terminal step to End


    return "\n".join(lines)


def _render_mermaid_using_api(
    mermaid_syntax: str,
    output_file_path: Optional[str] = None,
    background_color: Optional[str] = "white",
) -> bytes:
    """Renders Mermaid graph using the Mermaid.INK API."""


    graphbytes = mermaid_syntax.encode("utf8")
    base64_bytes = base64.urlsafe_b64encode(graphbytes)
    base64_string = base64_bytes.decode("ascii")


    # Check if the background color is a hexadecimal color code using regex
    if background_color is not None:
        hex_color_pattern = re.compile(r"^#(?:[0-9a-fA-F]{3}){1,2}$")
        if not hex_color_pattern.match(background_color):
            background_color = f"!{background_color}"

    image_url = (
        f"https://mermaid.ink/svg/{base64_string}?bgColor={background_color}"
    )
    response = requests.get(image_url)
    if response.status_code == 200:
        img_bytes = response.content
        if output_file_path is not None:
            with open(output_file_path, "wb") as file:
                file.write(response.content)

        return img_bytes
    else:
        raise ValueError(
            f"Failed to render the graph using the Mermaid.INK API. "
            f"Status code: {response.status_code}."
        )

def draw_kernel_process_mermaid(kernel_process, debug: Optional[bool] = False, output_file_path: Optional[str] = None,
    background_color: Optional[str] = "white",
    padding: int = 10,
) -> bytes:
    mermaid_syntax = _kernel_process_to_mermaid(kernel_process)
    
    
    if debug: print(mermaid_syntax)

    img_bytes = _render_mermaid_using_api(
        mermaid_syntax, output_file_path, background_color
    )

    return img_bytes