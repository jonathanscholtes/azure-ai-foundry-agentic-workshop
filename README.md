> ⚠️  
> **This project is currently in active development and may contain breaking changes.**  
> Updates and modifications are being made frequently, which may impact stability or functionality. This notice will be removed once development is complete and the project reaches a stable release. 

# Azure AI Foundry Workshop: Vector Search, Agentic AI, and LLM Orchestration  

## Overview  

This **Azure AI Foundry Workshop** provides participants with practical, hands-on experience in building and deploying **Retrieval-Augmented Generation (RAG)** and **Agentic AI** solutions using **Azure AI Foundry**, **Azure AI Search**, **Azure AI Agent Service**, and **LangGraph**.

Participants will learn how to create intelligent agents that not only respond, but also take action. Through integrating OpenAPI endpoints and orchestrating workflows across multiple agents, you’ll build solutions that are dynamic, context-aware, and production-ready.


By the end of the workshop, you'll have:

- Deploy a fully functional AI workshop environment using **Azure AI Foundry**.
- Built RAG pipelines using **Azure AI Search** and **document embeddings**.
- Explored **agentic patterns** using **LangGraph**: single-agent, supervisor-agent, and networked agents.
- Integrated structured external data via OpenAPI and GraphQL endpoints—giving agents the ability to query real-time data and take action through external systems.
- Built intelligent agents using Python code, while also exploring low-code tools for LLM orchestration and agent implementation.

---

## 🔧 What You’ll Build

- **Vector Search & RAG with Azure AI Search**  
  Learn to index documents, generate embeddings, and implement semantic retrieval to support LLM-based answers grounded in your data.

- **Agentic AI with LangGraph & Azure AI Agent Service**  
  Use prebuilt and custom agents to delegate tasks, make decisions, and interact with APIs. Experiment with orchestration patterns including single-agent flows, supervisor models, and decentralized networks.

- **Real-World Integrations with OpenAPI & GraphQL**  
  Connect your agents to external services, enabling them to perform real-world actions like retrieving live data, triggering workflows, or interacting with apps and systems.

---


## 🛠️ **Workshop Steps**

Follow these key steps to successfully implement and deploy the workshop:

### 1️⃣ [**Workshop Setup and Solution Deployment**](docs/deployment.md)  
Step-by-step instructions to deploy **Azure AI Foundry** and all required services for the workshop environment, including:

- **Azure AI Foundry** components: AI Service, AI Hub, Projects, and Compute  
- **Azure AI Search** for knowledge retrieval and vector-based search  
- **Azure Storage Account** for document storage and data ingestion  
- **Azure Functions** for event-driven document chunking, embedding generation, and indexing  
- **Azure Web App** to enable agent interactions via OpenAPI and GraphQL integrations

### 2️⃣ [**Vector Search and RAG Setup**](docs/vector-search.md)  
Instructions for processing documents and creating embeddings using **Ada-002**, indexing them into **Azure AI Search**, and configuring **RAG** for semantic retrieval.


### 3️⃣ [**Explore Sample Notebooks**](docs/notebooks.md)  
Get hands-on experience with Agentic AI through a collection of curated sample notebooks. These examples demonstrate:

- **Vector search** and semantic retrieval using Azure AI Search  
-  Multi-agent orchestration with **LangGraph**, integrating structured data via OpenAPI and GraphQL 
-  Real-world Agentic AI patterns implemented with Azure AI Foundry Agents 
-  **Tracing** for in-depth insights into agent execution and decision-making

---


## 📐 Workshop Design and Architecture

![design](/media/diagram.png)

This solution combines the power of **Azure AI Foundry**, **LangGraph**, and the **Azure AI Agents Service** to build an advanced, modular AI orchestration framework. It demonstrates a production-ready architecture designed for scalable, intelligent applications that require real-time reasoning, search, and structured data integration.

At a high level, the architecture consists of the following key components:

### Azure AI Foundry Core Services
The deployment includes Azure AI Foundry’s full stack—**AI Hub**, **AI Services**, **AI Projects**, and **Compute Instances**—providing a secure and managed environment for developing and running generative AI applications. Compute Instances are pre-configured to support **Visual Studio Code (web)**, enabling a browser-based development experience for running and modifying sample notebooks directly within the Foundry environment.

### Vector Search and RAG Implementation
Unstructured data, such as PDFs, are preprocessed through an **Azure Function** that chunks documents, generates vector embeddings using **OpenAI’s Ada-002 model**, and indexes them into **Azure AI Search**. This enables **Retrieval-Augmented Generation (RAG)** capabilities by grounding responses in your custom knowledge base.

### Multi-Agent System with LangGraph
Agents are orchestrated using **LangGraph**, a framework that enables complex workflows through node-based logic. A **Supervisor Agent** coordinates multiple specialized agents, allowing for role-based delegation, context-aware task execution, and adaptive reasoning.

### Tool Integration with OpenAPI and GraphQL
To enable agents to interact with structured external data sources, the solution integrates tools via **OpenAPI** (for RESTful APIs) and **GraphQL** (for schema-based query interfaces). These tools extend agent capabilities, allowing them to fetch, query, or write to external systems dynamically during conversation.

### Event-Driven Data Ingestion
Document processing is fully event-driven. When a PDF is uploaded to the designated storage container, an Azure Function is triggered to process the document end-to-end—from chunking to indexing—ensuring the search index remains up-to-date.


## ♻️ **Clean-Up**

After completing the workshop and testing, ensure you delete any unused Azure resources or remove the entire Resource Group to avoid additional charges.

---

## 📜 License  
This project is licensed under the [MIT License](LICENSE.md), granting permission for commercial and non-commercial use with proper attribution.

---

## Disclaimer  
This workshop and demo application are intended for educational and demonstration purposes. It is provided "as-is" without any warranties, and users assume all responsibility for its use.