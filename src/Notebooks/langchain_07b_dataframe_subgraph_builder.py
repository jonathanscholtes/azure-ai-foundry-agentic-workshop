from dotenv import load_dotenv
from os import environ
import pandas as pd
import numpy as np
from langgraph.graph import StateGraph, END
from typing import Literal
from typing_extensions import TypedDict, Literal
from langchain_core.messages import HumanMessage, SystemMessage
from langgraph.graph import MessagesState, StateGraph, END
from langgraph.types import Command

load_dotenv(override=True)

class DataFrameQuerySubgraphBuilder:
    def __init__(self, llm, df: pd.DataFrame):
        self.llm = llm
        self.df = df

    def generate_query(self, state: MessagesState) -> Command[Literal["run_query"]]:
        
        messages = state["messages"]

        schema = "\n".join(f"{col}: {dtype}" for col, dtype in self.df.dtypes.items())
        sample = self.df.head(3).to_markdown()

        messages.append(
            SystemMessage(
                content=(f"You are a Python data assistant.\n\n"
            f"DataFrame schema:\n{schema}\n\nSample rows:\n{sample}\n\n"
            f"Given the user request, return Python code that operates on `panda df` and answers the question."
            "Your code **must** assign the final result to a variable named `result`.\n"
            "Only return code—no explanation or commentary."
            "Do **not** include triple backticks (` ``` `)")))


        response = self.llm.invoke(messages)
        return Command(
            update={"messages": [HumanMessage(content=response.content, name="generate_query")]},
         goto="run_query")


    def run_query(self, state: MessagesState) -> Command[Literal["explain_result"]]:
        user_message = next(
            (msg.content for msg in reversed(state["messages"]) if isinstance(msg, HumanMessage)),
            None,
        )

        if not user_message:
            raise ValueError("No user message found in state.")

        try:

            context = {"df": self.df, "pd": pd}
            exec(user_message, context, context)  # This populates result in context
            result = context.get("result")  
            
            if result is not None:
                content = result.to_markdown() if hasattr(result, "to_markdown") else str(result)
            else:
                content = "Code executed, but no result variable was found."
        except Exception as e:
            content = f"Error running query: {e}"

        return Command(
            update={"messages": [HumanMessage(content=content, name="run_query")]},
            goto="explain_result"
        )


    def explain_result(self, state: MessagesState) -> Command[Literal["__end__"]]:
        messages = state["messages"]

        messages.append(
            SystemMessage(
                content=("You are a helpful assistant that answers the user's question given the returned data")))

        response = self.llm.invoke(messages)

        return Command(
            update={"messages": [HumanMessage(content=response.content, name="explain_result")]},
            goto=END
        )

    def build(self):
        graph = StateGraph(MessagesState)
        graph.add_node("generate_query", self.generate_query)
        graph.add_node("run_query", self.run_query)
        graph.add_node("explain_result", self.explain_result)
        graph.set_entry_point("generate_query")
        return graph.compile()
