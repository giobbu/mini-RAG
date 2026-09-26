# mini-RAG

Ask questions about your documents with mini-RAG.
Built in few lines of shell on top of this open source stack:
**Stack:** [Docling](https://github.com/docling-project/docling) (parsing) → TF-IDF (retrieval) → [Ollama](https://ollama.com) (local LLM)

```
docs/ ──docling──▶ tmp/*.md ──TF-IDF top-k──▶ tmp/ctx ──Ollama──▶ answer
```

## Requirements

- macOS or Linux with [Homebrew](https://brew.sh)
- Python 3
- `jq`: `brew install jq`

## Quick start

**1. Start the LLM server** (terminal 1). Skip this if the Ollama app is already running.

```bash
sh server.sh
```

**2. Ask a question** (terminal 2)

```bash
sh rag.sh ./docs "What are geospatial foundation models?"
```

## Usage

```bash
sh rag.sh <docs_path> "<question>" [top_k] [model] [ollama_url]
```

Arguments are **positional** (there are no `--flags`), so they must be given in this order:

| Position | Argument     | Description                      | Default                                   |
|----------|--------------|----------------------------------|-------------------------------------------|
| 1        | `docs_path`  | File or folder of documents      | required                                  |
| 2        | `question`   | Your question, in quotes         | required                                  |
| 3        | `top_k`      | Number of chunks sent to the LLM | `4`                                       |
| 4        | `model`      | Ollama model name                | `$MODEL` or `qwen2.5:7b`                  |
| 5        | `ollama_url` | Ollama server address            | `$OLLAMA_URL` or `http://localhost:11434` |

Example with 8 chunks:

```bash
sh rag.sh ./docs "What are geospatial foundation models?" 8
```

**Environment variables** (optional):

```bash
MODEL=llama3.1:8b sh rag.sh ./docs "Question?"      # use another model
OLLAMA_URL=http://gpu-box:11434 sh rag.sh ...       # remote Ollama server
```

## Debugging

Intermediate files are saved in `./tmp/`:

| File        | Content                                              |
|-------------|------------------------------------------------------|
| `tmp/*.md`  | Markdown produced by Docling, one file per document  |
| `tmp/ctx`   | The retrieved chunks sent to the LLM (last run only) |

If an answer looks wrong, run `cat tmp/ctx` to check whether the right chunks were retrieved. To force a clean re-parse, run `rm -rf tmp`.

> ⚠️ **The first launch is slow.** Dependencies are installed, Docling downloads
> its models, and Ollama pulls the LLM (~4.7 GB for `qwen2.5:7b`).
