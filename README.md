# Local LLM Setup

Configuration, build instructions, and management scripts for running Qwen3.6-35B-A3B with MTP speculative decoding on local hardware using `llama-cpp-turboquant` and Open WebUI.

## Hardware & System Notes
- **CPU:** Ryzen 5 5600X (6c/12t, max 4.6GHz)
- **RAM:** 32GB DDR4 @ 3200MHz *(Note: Tight for this setup. Ensure no heavy background apps.)*
- **GPU:** RTX 3060 12GB
- **Storage:** 500GB WD NVMe (PCIe 3.0 x4)
- **OS:** CachyOS (Linux)
- **Critical:** Close Firefox/browsers before starting. They consume ~166MB VRAM, which pushes the 12GB limit and causes CUDA crashes.

## Stack & Fork Warning
- **Backend:** [QuinsZouls/llama-cpp-turboquant](https://github.com/QuinsZouls/llama-cpp-turboquant) (`llama-next` branch)
- **Interface:** [Open WebUI](https://github.com/open-webui/open-webui) (Docker)
> ⚠️ **Important:** Use **only** the `QuinsZouls` fork. The original `TheTom/llama-cpp-turboquant` has MTP merge conflicts and will not work.

## Build Instructions
```bash
git clone --branch llama-next https://github.com/QuinsZouls/llama-cpp-turboquant.git quins-llama
cd quins-llama
cmake -B build -DGGML_CUDA=ON
cmake --build build --config Release --target llama-server -- -j12
```
Binary will be at `~/quins-llama/build/bin/llama-server`.

## Models
| Model | Quant | Link | VRAM | Context | Tok/s | CPU MoE | Notes |
|---|---|---|---|---|---|---|---|
| Qwen3.6-35B-A3B (MTP) | UD-Q4_K_XL | [HuggingFace](https://huggingface.co/havenoammo/Qwen3.6-35B-A3B-MTP-GGUF) | ~11.6 GB | 65k | ~50 t/s | auto (--fit) | MTP heads grafted. Requires Quins fork. |
| Qwen3.6-35B-A3B (Legacy) | Q4_K_M | [HuggingFace](https://huggingface.co/unsloth/Qwen3-30B-A3B-GGUF) | ~9.4 GB | 32k | ~35 t/s | 26 | Uses TheTom fork with turbo3 KV cache. |

Download MTP model:
```bash
huggingface-cli download havenoammo/Qwen3.6-35B-A3B-MTP-GGUF --include "*UD-Q4_K_XL*" --local-dir ~/models/
```

## Management Script
See [`ai.sh`](./ai.sh). Add to your shell config (`~/.zshrc` or `~/.bashrc`):
```bash
source /path/to/local-llm/ai.sh
```
After that, all `ai` commands handle starting and stopping services automatically.

### Commands
| Command | Description |
|---|---|
| `ai chat` | Starts MTP mode (65k context, ~50 t/s) + Open WebUI + Firefox |
| `ai legacy` | Starts legacy mode (32k context, ~35 t/s) + Open WebUI + Firefox |
| `ai ui` | Toggles Open WebUI container on/off |
| `ai off` | Stops llama-server and Open WebUI |
| `ai status` | Shows running state of both services |
| `ai logs` | Tails `/tmp/llama-server.log` |

## Key Configuration & Flags
The `ai chat` command uses these critical flags for stability on 12GB VRAM:
- `-fitt 1600`: Leaves ~300MB VRAM margin for compute buffers. Prevents mid-generation CUDA crashes. 1536 is too tight.
- `-c 65536`: 65k context. 131k crashes the system due to RAM limits.
- `--spec-type mtp --spec-draft-n-max 2`: Enables MTP speculative decoding (2 draft tokens).
- `--no-mmap --mlock`: Loads model fully into RAM and pins it. Prevents paging during inference. *(Requires `memlock` fix — see Troubleshooting)*
- `-ctk q8_0 -ctv q8_0`: q8_0 KV cache. Required for the Quins fork (`turbo3` is TheTom-only).
- `--chat-template-kwargs '{"preserve_thinking": true}'`: Keeps `<think>` blocks visible in Open WebUI.
- `--host 0.0.0.0 --port 8085`: Exposes server for Docker container access.
- No explicit `-ngl` or `--n-cpu-moe`: Let `--fit` auto-calculate layer offload. Adding these manually breaks loading on this model/fork combo.

## Dependencies
- Docker (for Open WebUI)
- `quins-llama` built from source (see Build Instructions)
- GGUF models placed in `~/models/`
- NVIDIA Driver: 595.71.05
- CUDA Toolkit: 13.2

## Setup

### Open WebUI
Pull and run the container once:
```bash
docker run -d \
  --name open-webui \
  -v open-webui:/app/backend/data \
  -p 3000:8080 \
  --add-host host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:main
```
After that, `ai chat` handles starting and stopping it.

### Connecting Open WebUI to llama-server
1. Open Open WebUI in your browser
2. Go to **Admin Settings → Connections → OpenAI**
3. Click **Add Connection**
4. Set the following:
   - **URL:** `http://172.17.0.1:8085/v1`
   - **API Key:** leave blank
   - **Provider:** llama.cpp

> `172.17.0.1` is the Docker bridge gateway address — this is how the Open WebUI container reaches llama-server running on the host.
> To find yours:
> ```bash
> ip route | grep docker
> ```

## Troubleshooting
- **`mlock: failed to mlock` warning:** System `memlock` limit is too low. Fix:
  ```bash
  sudo sh -c 'echo "* hard memlock unlimited" >> /etc/security/limits.conf'
  sudo sh -c 'echo "* soft memlock unlimited" >> /etc/security/limits.conf'
  ```
  Reboot to apply.
- **CUDA crashes / OOM mid-generation:** Close all browsers before starting. VRAM is maxed at ~11.6GB. If crashes persist, increase `-fitt` in `ai.sh` in increments of 50.
- **Context crashes / system freeze:** Do not exceed 65k context. 131k exceeds RAM limits on 32GB.
- **Legacy mode:** Uses `~/llama-cpp-turboquant` (TheTom fork) with `turbo3` KV cache and Q4_K_M quant. Run with `ai legacy`.
