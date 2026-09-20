# mini-RAG

Ask questions about your documents using Docling, TF-IDF retrieval and a local LLM via Ollama.

## Requirements
- Python 3, `jq`, Homebrew (`brew install jq`)

## 1. Start the LLM server (terminal 1)
```bash
sh server.sh
```
Skip this if the Ollama app is already running.

## 2. Chat with your docs (terminal 2)
```bash
sh rag.sh ./docs "What is missingness?" 8  # top 8 chunks (default value is 4)

# RAG Answer
Missingness refers to the absence of data for certain variables in a dataset. This can occur for various reasons and can be categorized into different types, such as missing completely at random (MCAR), missing at random (MAR), or missing not at random (MNAR). Understanding the type of missingness is crucial because it influences how the data should be handled. For instance, the handling of missing data in response variables versus predictor variables can differ, and the nature of the variable (quantitative or categorical) and the extent of missingness also play significant roles in determining the appropriate methods for addressing missing data.
```

> ⚠️ **First launch is slow.** 

> Dependencies are installed, Docling downloads its
> models, and Ollama pulls the LLM (~4.7 GB for `qwen2.5:7b`).