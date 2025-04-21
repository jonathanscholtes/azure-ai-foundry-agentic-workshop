from dotenv import load_dotenv
from os import environ
from typing_extensions import TypedDict, Literal
from langchain_core.messages import HumanMessage, SystemMessage
from langgraph.graph import MessagesState, StateGraph, END
from langgraph.types import Command

from langchain_community.utilities.requests import RequestsWrapper
from langchain_community.agent_toolkits.openapi.spec import reduce_openapi_spec
from langchain_community.agent_toolkits.openapi.planner import create_openapi_agent

from user_functions import vector_search

import requests

load_dotenv(override=True)


class SubgraphBuilder:
    def __init__(self, llm):
        self.llm = llm
        self.members = ["document_search", "datacenter_energy_usage"]
        self.options = self.members + ["FINISH"]
        self.system_prompt = (
            "You are a supervisor tasked with managing a conversation between the"
            f" following workers: {self.members}. Given the following user request,"
            " respond with the worker to act next. Each worker will perform a"
            " task and respond with their results and status. When finished,"
            " respond with FINISH.\n\nNote: The 'datacenter_energy_usage' worker handles queries related to data center tabular queries on energy, power, or consumption topics."
        )

        self.openapi_agent = self._build_openapi_agent()

    class Router(TypedDict):
        next: Literal["document_search", "datacenter_energy_usage", "FINISH"]

    def _build_openapi_agent(self):
        spec_url = environ["OPENAPI_URL"]
        response = requests.get(spec_url)
        response.raise_for_status()

        json_spec = reduce_openapi_spec(response.json())
        requests_wrapper = RequestsWrapper(
            headers={"Authorization": f"Bearer {environ['AZURE_OPENAI_API_KEY']}"}
        )
        return create_openapi_agent(
            json_spec,
            requests_wrapper,
            self.llm,
            allow_dangerous_requests=True,
        )

    def document_search(self, state: MessagesState) -> Command[Literal["supervisor"]]:
        messages = state["messages"]
        last_user_message = next((msg for msg in reversed(messages)), None)
        if not last_user_message:
            return Command(goto="supervisor")

        query = last_user_message.content
        context = vector_search(query)

        messages.append(
            SystemMessage(
                content=(
                    f"You are a helpful assistant. Use only the information in the context below to answer the user's question. "
                    f"If the context does not contain the answer, respond with \"I don't know.\"\n\nContext:\n{context}"
                )
            )
        )

        response = self.llm.invoke(messages)

        return Command(
            update={"messages": [HumanMessage(content=response.content, name="document_search")]},
            goto="supervisor",
        )

    def datacenter_energy_usage(self, state: MessagesState) -> Command[Literal["supervisor"]]:
        user_message = next(
            (msg.content for msg in reversed(state["messages"]) if isinstance(msg, HumanMessage)),
            None,
        )

        if not user_message:
            raise ValueError("No user message found in state.")

        result = self.openapi_agent.invoke({"input": user_message})
        final_output = result.get("output", result)

        return Command(
            update={"messages": [HumanMessage(content=final_output, name="datacenter_energy_usage")]},
            goto="supervisor",
        )

    def supervisor(self, state: MessagesState) -> Command[Literal["document_search", "datacenter_energy_usage", "__end__"]]:
        messages = [{"role": "system", "content": self.system_prompt}] + state["messages"]
        response = self.llm.with_structured_output(self.Router).invoke(messages)
        goto = response["next"]
        if goto == "FINISH":
            goto = END
        return Command(goto=goto, update={"next": goto})

    def build(self):
        graph = StateGraph(MessagesState)
        graph.add_node("document_search", self.document_search)
        graph.add_node("datacenter_energy_usage", self.datacenter_energy_usage)
        graph.add_node("supervisor", self.supervisor)
        graph.set_entry_point("supervisor")
        return graph.compile()