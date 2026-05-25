# Local LLM Setup

Configuration, build instructions, and management scripts for running Qwen3.6-35B-A3B with MTP speculative decoding on local hardware using `llama.cpp` and Open WebUI.

## Hardware & System Notes

- **CPU:** Ryzen 5 5600X (6c/12t, max 4.6GHz)
- **RAM:** 32GB DDR4 @ 3200MHz *(Note: Tight for this setup. Ensure no heavy background apps.)*
- **GPU:** RTX 3060 12GB
- **Storage:** 500GB WD NVMe (PCIe 3.0 x4)
- **OS:** CachyOS (Linux)
- **Critical:** Be aware of having Firefox/browsers open before starting. They consume VRAM, which could push the 12GB limit and causes CUDA crashes.

## Stack

- **Backend:** [llama.cpp](https://github.com/ggml-org/llama.cpp) (built with CUDA)
- **Interface:** [Open WebUI](https://github.com/open-webui/open-webui) (Docker)
- **pi Agent:** See [`pi/README.md`](./pi/README.md) for model providers, extensions, and sync config.

## Build Instructions

```bash
git clone https://github.com/ggml-org/llama.cpp.git llama-cpp
cd llama-cpp
cmake -B build -DGGML_CUDA=ON
cmake --build build --config Release --target llama-server -- -j12
```

Binary will be at `~/llama-cpp/build/bin/llama-server`.

## Models

| Model                 | Quant      | Link                                                                      | VRAM     | Context | Tok/s   | --fitt      |
| --------------------- | ---------- | ------------------------------------------------------------------------- | -------- | ------- | ------- | ------------ |
| Qwen3.6-35B-A3B (MTP) | UD-Q4_K_XL | [HuggingFace](https://huggingface.co/Qwen/Qwen3.6-35B-A3B) | ~11.6 GB | 32k  | ~60 t/s | 1400 |

Download model:

```bash
hf download unsloth/Qwen3.6-35B-A3B-MTP-GGUF --include "*UD-Q4_K_XL*" --local-dir ~/models/
```


## Management Script

See [`ai.zsh`](./ai.zsh). Add to your shell config (`~/.zshrc` or `~/.bashrc`):

```bash
source /path/to/local-llm-setup/ai.zsh
```

After that, all `ai` commands handle starting and stopping services automatically.

### Commands

| Command     | Description                                                                                    |
| ----------- | ---------------------------------------------------------------------------------------------- |
| `ai chat`   | Chat mode - thinking enabled, general purpose (temp 1.0) + Open WebUI + Firefox |
| `ai code`   | Code mode - thinking enabled, precise (temp 0.6) + server only | 
| `ai fast`   | Fast mode - thinking disabled, general purpose (temp 0.7, higher draft) + Open WebUI + Firefox |
| `ai ui`     | Toggles Open WebUI container on/off |
| `ai off`    | Stops llama-server and Open WebUI |
| `ai status` | Shows running state of both services |
| `ai logs`   | Tails `/tmp/llama-server.log` |
|  `ai bench` | Runs the automated `llama-benchy` suite and appends timestamped results to `BENCHMARKS.md` |

## Key Configuration & Flags

### Shared server flags (all modes)

These flags are passed to every mode and are critical for stability on 12GB VRAM:

- `-fitt 1400`: Leaves VRAM margin for compute buffers. Prevents mid-generation CUDA crashes.
- `-c 32768`: 32k context. 65k doesn't exceed limits but is too close for comfort on 32GB RAM.
- `-n 16384`: Max tokens to generate per response.
- `-fa on`: Enable flash attention.
- `-np 1`: Number of parallel sequences.
- `-ctk q8_0 -ctv q8_0 -ctkd q8_0 -ctvd q8_0`: q8_0 KV cache (key, value, decode, decode-key).
- `-ctxcp 64`: Context chunking size.
- `--no-mmap --mlock`: Loads model fully into RAM and pins it. Prevents paging during inference. *(Requires `memlock` fix — see Troubleshooting)*
- `--threads 6`: CPU threads for non-GPU work.
- `--cont-batching`: Continuous batching for better throughput.
- `--batch-size 2048 --ubatch-size 1024`: Batch size limits.
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
- **CUDA crashes / OOM mid-generation:** VRAM is maxed at ~11.6GB. If crashes persist, increase `-fitt` in `ai.zsh` in increments of 50.
- **Context crashes / system freeze:** Stick to 32k. 65k doesn't exceed limits but is too close for comfort on 32GB RAM.

## Benchmarking

I use [`llama-benchy`](https://github.com/eugr/llama-benchy) to measure prompt processing (prefill) and token generation (decoding) speeds, specifically focusing on how the system handles prefix caching at various context depths. 

Ensure `uv` is installed before running these tests. 

### 1. Start the Server
Run the server in `code` mode to isolate it from Open WebUI and free up maximum VRAM:
```bash
ai code
```

### 2. Standard Performance & Prefix Caching Test

This test measures baseline speeds and verifies that the K-V cache is being utilized correctly for follow-up prompts at depths of 2048 and 4096 tokens.

```bash
uvx llama-benchy \
  --base-url http://localhost:8085/v1 \
  --model Qwen3.6-35B \
  --latency-mode generation \
  --depth 0 2048 4096 \
  --enable-prefix-caching

```

*Note: If `pp2048 @ d4096` speeds crash or show massive variance, verify that `--batch-size 2048` and `--ubatch-size 1024` are set in `ai.zsh` to prevent K-V cache synchronization bottlenecks.*

### 3. Maximum VRAM Stress Test (32k Context)

To verify that the system can handle the full 32,768 context limit without throwing a CUDA Out of Memory (OOM) error, run a deep context test.

By setting the depth to 30,720 and the prompt size to 2,048, we hit exactly 32,768 tokens:

```bash
uvx llama-benchy \
  --base-url http://localhost:8085/v1 \
  --model Qwen3.6-35B \
  --latency-mode generation \
  --pp 2048 \
  --depth 30720 \
  --enable-prefix-caching
```

Monitor `ai logs` during this test. If the server crashes change the parameters in `ai.zsh`. For example, lower the `-c` or reduce `--ubatch-size` or increase `--fitt`.

### 4. Exporting Results

To save the benchmark results for analysis, append the `--save-result` flag. Use `--format json` along with timeseries flags for the most granular data:

```bash
uvx llama-benchy \
  --base-url http://localhost:8085/v1 \
  --model Qwen3.6-35B \
  --latency-mode generation \
  --save-result benchmark_output.json \
  --format json \
  --save-all-throughput-timeseries
```

### 5. Automated Benchmarking & Tracking

To track performance across hardware changes, configuration tweaks, or `llama.cpp` updates, use the automated benchmark built into the management script.

Run the server in code mode, then trigger the benchmark:

```bash
ai code
ai bench
```
