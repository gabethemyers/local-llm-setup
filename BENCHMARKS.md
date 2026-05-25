
## Benchmark Run: 2026-05-24 23:19:52
**Model:** Qwen3.6-35B | **llama.cpp hash:** `1867a0c69`

llama-benchy (0.3.7)
Date: 2026-05-24 23:19:53
Benchmarking model: Qwen3.6-35B at http://localhost:8085/v1
Concurrency levels: [1]
Error loading tokenizer: Qwen3.6-35B is not a local folder and is not a valid model identifier listed on 'https://huggingface.co/models'
If this is a private repository, make sure to pass a token having permission to this repo either by logging in with `hf auth login` or by passing `token=<your_token>`
Falling back to 'gpt2' tokenizer as approximation.
Loading text from cache: /home/gabe/.cache/llama-benchy/cc6a0b5782734ee3b9069aa3b64cc62c.txt
Total tokens available in text corpus: 159385
Warming up...
Warmup (User only) complete. Delta: 8 tokens (Server: 30, Local: 22)
Warmup (System+Empty) complete. Delta: 13 tokens (Server: 35, Local: 22)

Running coherence test...
Coherence test PASSED.
Measuring latency using mode: generation...
Average latency (generation): 74.76 ms
Running test: pp=2048, tg=32, depth=0, concurrency=1
  Run 1/3 (batch size 1)...
  No token_ids in response, using local tokenization
  Run 2/3 (batch size 1)...
  Run 3/3 (batch size 1)...
Running test: pp=2048, tg=32, depth=2048, concurrency=1
  Run 1/3 (Context Load, batch size 1)...
  Run 1/3 (Inference, batch size 1)...
  Run 2/3 (Context Load, batch size 1)...
  Run 2/3 (Inference, batch size 1)...
  Run 3/3 (Context Load, batch size 1)...
  Run 3/3 (Inference, batch size 1)...
Running test: pp=2048, tg=32, depth=4096, concurrency=1
  Run 1/3 (Context Load, batch size 1)...
  Run 1/3 (Inference, batch size 1)...
  Run 2/3 (Context Load, batch size 1)...
  Run 2/3 (Inference, batch size 1)...
  Run 3/3 (Context Load, batch size 1)...
  Run 3/3 (Inference, batch size 1)...
Printing results in MD format:



| model       |           test |            t/s |     peak t/s |       ttfr (ms) |    est_ppt (ms) |   e2e_ttft (ms) |
|:------------|---------------:|---------------:|-------------:|----------------:|----------------:|----------------:|
| Qwen3.6-35B |         pp2048 | 938.51 ± 14.16 |              | 2042.91 ± 41.54 | 1968.15 ± 41.54 | 2042.91 ± 41.54 |
| Qwen3.6-35B |           tg32 |   66.36 ± 3.63 | 68.24 ± 3.68 |                 |                 |                 |
| Qwen3.6-35B | ctx_pp @ d2048 | 931.55 ± 28.54 |              | 2005.75 ± 53.60 | 1930.99 ± 53.60 | 2005.75 ± 53.60 |
| Qwen3.6-35B | ctx_tg @ d2048 |   60.17 ± 1.87 | 61.97 ± 1.93 |                 |                 |                 |
| Qwen3.6-35B | pp2048 @ d2048 |  691.30 ± 7.84 |              | 3037.67 ± 33.87 | 2962.91 ± 33.87 | 3037.67 ± 33.87 |
| Qwen3.6-35B |   tg32 @ d2048 |   59.86 ± 3.56 | 61.65 ± 3.67 |                 |                 |                 |
| Qwen3.6-35B | ctx_pp @ d4096 | 933.31 ± 15.74 |              | 4043.86 ± 77.59 | 3969.10 ± 77.59 | 4043.86 ± 77.59 |
| Qwen3.6-35B | ctx_tg @ d4096 |   60.92 ± 5.80 | 62.75 ± 5.98 |                 |                 |                 |
| Qwen3.6-35B | pp2048 @ d4096 | 669.67 ± 12.49 |              | 3134.05 ± 56.74 | 3059.29 ± 56.74 | 3134.05 ± 56.74 |
| Qwen3.6-35B |   tg32 @ d4096 |   59.17 ± 0.40 | 60.95 ± 0.41 |                 |                 |                 |

llama-benchy (0.3.7)
date: 2026-05-24 23:19:53 | latency mode: generation


llama-benchy (0.3.7)
Date: 2026-05-24 23:20:50
Benchmarking model: Qwen3.6-35B at http://localhost:8085/v1
Concurrency levels: [1]
Error loading tokenizer: Qwen3.6-35B is not a local folder and is not a valid model identifier listed on 'https://huggingface.co/models'
If this is a private repository, make sure to pass a token having permission to this repo either by logging in with `hf auth login` or by passing `token=<your_token>`
Falling back to 'gpt2' tokenizer as approximation.
Loading text from cache: /home/gabe/.cache/llama-benchy/cc6a0b5782734ee3b9069aa3b64cc62c.txt
Total tokens available in text corpus: 159385
Warming up...
Warmup (User only) complete. Delta: 8 tokens (Server: 30, Local: 22)
Warmup (System+Empty) complete. Delta: 13 tokens (Server: 35, Local: 22)

Running coherence test...
Coherence test PASSED.
Measuring latency using mode: generation...
Average latency (generation): 71.72 ms
Running test: pp=2048, tg=32, depth=30720, concurrency=1
  Run 1/3 (Context Load, batch size 1)...
  No token_ids in response, using local tokenization
  Run 1/3 (Inference, batch size 1)...
  Run 2/3 (Context Load, batch size 1)...
  Run 2/3 (Inference, batch size 1)...
  Run 3/3 (Context Load, batch size 1)...
  Run 3/3 (Inference, batch size 1)...
Printing results in MD format:



| model       |            test |           t/s |     peak t/s |        ttfr (ms) |     est_ppt (ms) |    e2e_ttft (ms) |
|:------------|----------------:|--------------:|-------------:|-----------------:|-----------------:|-----------------:|
| Qwen3.6-35B | ctx_pp @ d30720 | 914.68 ± 2.01 |              | 30574.68 ± 46.07 | 30502.96 ± 46.07 | 30574.68 ± 46.07 |
| Qwen3.6-35B | ctx_tg @ d30720 |  57.61 ± 1.95 | 59.40 ± 2.01 |                  |                  |                  |
| Qwen3.6-35B | pp2048 @ d30720 | 578.99 ± 9.00 |              |  3609.78 ± 55.50 |  3538.06 ± 55.50 |  3609.78 ± 55.50 |
| Qwen3.6-35B |   tg32 @ d30720 |  58.87 ± 0.32 | 60.70 ± 0.33 |                  |                  |                  |

llama-benchy (0.3.7)
date: 2026-05-24 23:20:50 | latency mode: generation

