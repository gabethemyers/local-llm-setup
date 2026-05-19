# Local LLM Setup

Configuration, build instructions, and management scripts for running Qwen3.6-35B-A3B with MTP speculative decoding on local hardware using `llama.cpp` and Open WebUI.

## Hardware & System Notes

- **CPU:** Ryzen 5 5600X (6c/12t, max 4.6GHz)
- **RAM:** 32GB DDR4 @ 3200MHz *(Note: Tight for this setup. Ensure no heavy background apps.)*
- **GPU:** RTX 3060 12GB
- **Storage:** 500GB WD NVMe (PCIe 3.0 x4)
- **OS:** CachyOS (Linux)
- **Critical:** Close Firefox/browsers before starting. They consume ~166MB VRAM, which pushes the 12GB limit and causes CUDA crashes.

## Stack

- **Backend:** [llama.cpp](https://github.com/ggml-org/llama.cpp) (built with CUDA)
- **Interface:** [Open WebUI](https://github.com/open-webui/open-webui) (Docker)

## Build Instructions

```bash
git clone https://github.com/ggml-org/llama.cpp.git llama-cpp
cd llama-cpp
cmake -B build -DGGML_CUDA=ON
cmake --build build --config Release --target llama-server -- -j12
```

Binary will be at `~/llama-cpp/build/bin/llama-server`.

## Models

| Model                 | Quant      | Link                                                                      | VRAM     | Context | Tok/s   | CPU MoE      |
| --------------------- | ---------- | ------------------------------------------------------------------------- | -------- | ------- | ------- | ------------ |
| Qwen3.6-35B-A3B (MTP) | UD-Q4_K_XL | [HuggingFace](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-MTP-GGUF) | ~11.6 GB | 65k     | ~40 t/s | auto (--fit) |

Download model:

```bash
hf download unsloth/Qwen3.6-35B-A3B-MTP-GGUF --include "*UD-Q4_K_XL*" --local-dir ~/models/
```



## Management Script

See [`ai.zsh`](./ai.zsh). Add to your shell config (`~/.zshrc` or `~/.bashrc`):

```bash
source /path/to/local-llm/ai.zsh
```

After that, all `ai` commands handle starting and stopping services automatically.

### Commands

| Command     | Description                                                                                    |
| ----------- | ---------------------------------------------------------------------------------------------- |
| `ai chat`   | Chat mode — thinking enabled, general purpose (temp 1.0) + Open WebUI + Firefox                |
| `ai code`   | Code mode — thinking enabled, precise (temp 0.6) + server only                                 |
| `ai fast`   | Fast mode — thinking disabled, general purpose (temp 0.7, higher draft) + Open WebUI + Firefox |
| `ai ui`     | Toggles Open WebUI container on/off                                                            |
| `ai off`    | Stops llama-server and Open WebUI                                                              |
| `ai status` | Shows running state of both services                                                           |
| `ai logs`   | Tails `/tmp/llama-server.log`                                                                  |

## Key Configuration & Flags

### Shared server flags (all modes)

These flags are passed to every mode and are critical for stability on 12GB VRAM:

- `-fitt 1600`: Leaves ~300MB VRAM margin for compute buffers. Prevents mid-generation CUDA crashes.
- `-c 65536`: 65k context. 131k crashes the system due to RAM limits.
- `-n 16384`: Max tokens to generate per response.
- `-fa on`: Enable flash attention.
- `-np 1`: Number of parallel sequences.
- `-ctk q8_0 -ctv q8_0 -ctkd q8_0 -ctvd q8_0`: q8_0 KV cache (key, value, decode, decode-key).
- `-ctxcp 64`: Context chunking size.
- `--no-mmap --mlock`: Loads model fully into RAM and pins it. Prevents paging during inference. *(Requires `memlock` fix — see Troubleshooting)*
- `--threads 6`: CPU threads for non-GPU work.
- `--cont-batching`: Continuous batching for better throughput.
- `--batch-size 1024 --ubatch-size 512`: Batch size limits.
- `--spec-type draft-mtp`: Enables MTP speculative decoding (enabled in all modes).
- `--host 0.0.0.0 --port 8085`: Exposes server for Docker container access.
- `--timeout 300 --metrics`: 5-minute idle timeout and Prometheus metrics.

### Mode-specific sampling parameters

| Flag                     | chat                          | code                          | fast                         |
| ------------------------ | ----------------------------- | ----------------------------- | ---------------------------- |
| `--spec-draft-n-max`     | 2                             | 2                             | 3                            |
| `--chat-template-kwargs` | `{"preserve_thinking": true}` | `{"preserve_thinking": true}` | `{"enable_thinking": false}` |
| `--temp`                 | 1.0                           | 0.6                           | 0.7                          |
| `--top-p`                | 0.95                          | 0.95                          | 0.8                          |
| `--top-k`                | 20                            | 20                            | 20                           |
| `--min-p`                | 0.0                           | 0.0                           | 0.0                          |
| `--presence-penalty`     | 1.5                           | 0.0                           | 1.5                          |
| `--repeat-penalty`       | 1.0                           | 1.0                           | 1.0                          |

## Dependencies

- Docker (for Open WebUI)
- `llama.cpp` built from source (see Build Instructions)
- GGUF models placed in `~/models/`
- NVIDIA Driver: 595.71.05
- CUDA Toolkit: 13.2

## Setup

### Open WebUI

Run once to create the container (uses `network_mode: host` + auto-restart):

```bash
cd ~/dev/local-llm-setup
docker compose up -d
```

After that, `ai chat`, `ai fast`, or `ai ui` handle starting and stopping it.

### Connecting Open WebUI to llama-server

1. Open Open WebUI in your browser
2. Go to **Admin Settings → Connections → OpenAI**
3. Click **Add Connection**
4. Set the following:
   - **URL:** `http://localhost:8085/v1`
   - **API Key:** leave blank
   - **Provider:** llama.cpp

> The container uses `network_mode: host`, so `localhost` from inside the container refers to the host machine where llama-server is running.

## Troubleshooting

- **`mlock: failed to mlock` warning:** System `memlock` limit is too low. Fix:
  
  ```bash
  sudo sh -c 'echo "* hard memlock unlimited" >> /etc/security/limits.conf'
  sudo sh -c 'echo "* soft memlock unlimited" >> /etc/security/limits.conf'
  ```
  
  Reboot to apply.
- **CUDA crashes / OOM mid-generation:** Close all browsers before starting. VRAM is maxed at ~11.6GB. If crashes persist, increase `-fitt` in `ai.zsh` in increments of 50.
- **Context crashes / system freeze:** Do not exceed 65k context. 131k exceeds RAM limits on 32GB.
