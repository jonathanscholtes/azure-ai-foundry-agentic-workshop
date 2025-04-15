> ⚠️  
> **This project is currently in active development and may contain breaking changes.**  
> Updates and modifications are being made frequently, which may impact stability or functionality. This notice will be removed once development is complete and the project reaches a stable release. 

# Azure AI Foundry Workshop: Vector Search, Agentic AI, and LLM Orchestration

## Overview  

An **Azure Ai Foundry** interactive workshop aimed at introducing concepts like **Vector Search**, **Agentic AI**, and **Large Language Model (LLM) orchestration**. This project enables participants to gain practical experience integrating and deploying generative AI models, orchestrating tasks with **LangChain** and **Azure AI Agent Service**, implementing **Vector Search** using **Azure AI Search**, and developing multi-agent systems for collaborative and intelligent task execution.


#### Key Features  

- **Azure AI Foundry Deployment:**  
  - Deploys **AI Hub**, **AI Project**, and **AI Services** with secure access and managed identities for integration with AI models.  

- **Vector Search with Azure AI Search:**  
  - Implements **Vector Search** to enable **Retrieval-Augmented Generation (RAG)** using indexed embeddings from documents.  

- **Agentic AI Framework:**  
  - Leverages **Agentic AI** patterns to enable task orchestration and decision-making workflows.  

- **LLM Orchestration with LangChain:**  
  - Integrates **LangChain** for seamless orchestration of large language models (LLMs).  
  - Enables flexible **multi-agent systems** for complex problem solving, supporting dynamic decision-making and workflow automation.


## 🛠️ **Core Steps for Solution Implementation**

Follow these key steps to successfully implement and deploy the solution:

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
Get hands-on experience with **Agentic AI** through a collection of curated sample notebooks. These examples demonstrate:

- Vector search and semantic retrieval using Azure AI Search  
- Multi-agent orchestration integrating structured data via OpenAPI and GraphQL  
- Real-world Agentic AI patterns implemented with Azure AI Foundry Agents
---


## 📐 Solution Design and Architecture

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

---

This architecture not only supports RAG but also showcases the foundational patterns for building **Agentic AI** systems that are modular, event-driven, and extensible across enterprise-grade workloads using the **Azure AI Agents Service**.


## ♻️ **Clean-Up**

After completing the workshop and testing, ensure you delete any unused Azure resources or remove the entire Resource Group to avoid additional charges.

---

## 📜 License  
This project is licensed under the [MIT License](LICENSE.md), granting permission for commercial and non-commercial use with proper attribution.

---

## Disclaimer  
This workshop and demo application are intended for educational and demonstration purposes. It is provided "as-is" without any warranties, and users assume all responsibility for its use.