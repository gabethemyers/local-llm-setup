# Local LLM Setup

Configuration and notes for my local LLM setup using llama.cpp and Open WebUI.

## Hardware

- CPU: Ryzen 5 5600X 6 cores 12 threads max speed: 4.6GHz
- RAM: 32GB DDR4 @ 3200MHz
- GPU: RTX 3060 12gb
- SSD: 500GB Western Digital NVMe (PCIe 3.0 x4)
- OS: CachyOS (Linux)

## Stack

- [**llama-cpp-turboquant**](https://github.com/TheTom/llama-cpp-turboquant) — backend inference server
- [**Open WebUI**](https://github.com/open-webui/open-webui) — chat interface, running via Docker

## Models

| Model | Quant | Link | VRAM | ctx | Tok/s | CPU MoE | Notes |
|---|---|---|---|---|---|---|---|
| Qwen3-30B-A3B | Q4_K_M | [huggingface](https://huggingface.co/unsloth/Qwen3-30B-A3B-GGUF) | 9400 MiB | 32k | ~35 t/s | 26 | |

## Script

See [`ai.sh`](./ai.sh). Add to your shell config to source it:

```bash
source /path/to/ai.sh
```

### Usage
| Command | Description |
|---|---|
| `ai chat` | Starts llama-server and Open WebUI, opens Firefox |
| `ai code` | Starts llama-server only, stops Open WebUI |
| `ai off` | Stops llama-server and Open WebUI |
| `ai status` | Shows running state of both services |
| `ai logs` | Tails `/tmp/llama-server.log` |

## Dependencies

- Docker (for Open WebUI)
- llama-cpp-turboquant built from source - see repo for build instructions
- A GGUF model placed a the path defined in `ai.sh`

## Setup

### Open WebUI

Pull and run the container:

```bash
docker run -d \
  --name open-webui \
  -v open-webui:/app/backend/data \
  -p 3000:8080 \
  --add-host host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:main
```

After that, `ai chat` handles starting and stopping it.

### CUDA

- NVIDIA Driver: 595.71.05 
- CUDA Toolkit: 13.2
