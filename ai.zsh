# Add to ~/.bashrc or ~/.zshrc:
# source ~/dev/local-llm-setup/ai.zsh

ai() {
    local MODEL_PATH=~/models/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf
    local SERVER_BIN=~/llama-cpp/build/bin/llama-server
    local PORT=8085

    _ai_start_server() {
        if pgrep -x "llama-server" > /dev/null; then
            pkill -x "llama-server"
            sleep 2
        fi

        nohup $SERVER_BIN \
            -m $MODEL_PATH \
            -fitt 1400 \
            -c 32768 \
            -n 16384 \
            -fa on \
            -np 1 \
            -ctk q8_0 \
            -ctv q8_0 \
            -ctkd q8_0 \
            -ctvd q8_0 \
            -ctxcp 64 \
            --no-mmap \
            --mlock \
            --threads 6 \
            --cont-batching \
            --batch-size 2048 \
            --ubatch-size 1024 \
            --spec-type draft-mtp \
            --host 0.0.0.0 --port $PORT \
            --timeout 300 --metrics \
            "$@" > /tmp/llama-server.log 2>&1 &
    }

    case "$1" in
        chat)
            echo "Initializing Chat Mode (thinking, general)..."
            _ai_start_server \
                --spec-draft-n-max 2 \
                --chat-template-kwargs '{"preserve_thinking": true}' \
                --temp 1.0 \
                --top-p 0.95 \
                --top-k 20 \
                --min-p 0.0 \
                --presence-penalty 1.5 \
                --repeat-penalty 1.0
            docker start open-webui > /dev/null 2>&1
            echo "Starting Open WebUI"
            until curl -sf http://localhost:3000/health; do sleep 1; done
            firefox http://localhost:3000 > /dev/null 2>&1 &
            ;;

        code)
            echo "Initializing Code Mode (thinking, precise)..."
            _ai_start_server \
                --spec-draft-n-max 2 \
                --chat-template-kwargs '{"preserve_thinking": true}' \
                --temp 0.6 \
                --top-p 0.95 \
                --top-k 20 \
                --min-p 0.0 \
                --presence-penalty 0.0 \
                --repeat-penalty 1.0
            echo "Server ready at http://localhost:$PORT"
            ;;

        fast)
            echo "Initializing Fast Mode (non-thinking, general)..."
            _ai_start_server \
                --spec-draft-n-max 3 \
                --chat-template-kwargs '{"enable_thinking": false}' \
                --temp 0.7 \
                --top-p 0.8 \
                --top-k 20 \
                --min-p 0.0 \
                --presence-penalty 1.5 \
                --repeat-penalty 1.0
            docker start open-webui > /dev/null 2>&1
            echo "Starting Open WebUI"
            until curl -sf http://localhost:3000/health; do sleep 1; done
            firefox http://localhost:3000 > /dev/null 2>&1 &
            ;;

        ui)
            if [ "$(docker inspect -f '{{.State.Running}}' open-webui 2>/dev/null)" = "true" ]; then
                docker stop open-webui > /dev/null 2>&1
                echo "Open WebUI stopped."
            else
                docker start open-webui > /dev/null 2>&1
                echo "Open WebUI active at http://localhost:3000"
                firefox http://localhost:3000 > /dev/null 2>&1 &
            fi
            ;;

        off)
            echo "Shutting down..."
            docker stop open-webui > /dev/null 2>&1
            if pgrep -x "llama-server" > /dev/null; then
                pkill -x "llama-server"
                echo "llama-server stopped. VRAM cleared."
            else
                echo "llama-server was not running."
            fi
            ;;

        status)
            if pgrep -x "llama-server" > /dev/null; then
                echo "Llama Server: Active (PID: $(pgrep -x llama-server))"
            else
                echo "Llama Server: Inactive"
            fi
            if [ "$(docker inspect -f '{{.State.Running}}' open-webui 2>/dev/null)" = "true" ]; then
                echo "Open WebUI: Active"
            else
                echo "Open WebUI: Inactive"
            fi
            ;;

        logs)
            echo "Tailing llama-server logs (Ctrl+C to exit)..."
            tail -f /tmp/llama-server.log
            ;;
        bench)
            echo "Starting automated benchmark suite..."
            # Use an absolute path so it always saves to the right place no matter where you run the command
            local BENCH_FILE="$HOME/dev/local-llm-setup/BENCHMARKS.md"
            local LLAMA_DIR="$HOME/llama-cpp"
            
            # Grab the current llama.cpp commit hash if the directory exists
            local LLAMA_HASH="unknown"
            if [ -d "$LLAMA_DIR" ]; then
                LLAMA_HASH=$(cd "$LLAMA_DIR" && git rev-parse --short HEAD 2>/dev/null)
            fi

            # Format the markdown header (appends)
            echo -e "\n## Benchmark Run: $(date '+%Y-%m-%d %H:%M:%S')" >> "$BENCH_FILE"
            echo -e "**Model:** Qwen3.6-35B | **llama.cpp hash:** \`$LLAMA_HASH\`\n" >> "$BENCH_FILE"
            
            echo "Running standard & prefix caching test (Depths: 0, 2048, 4096)..."
            PYTHONWARNINGS="ignore" TRANSFORMERS_VERBOSITY=error uvx llama-benchy \
              --base-url http://localhost:8085/v1 \
              --model Qwen3.6-35B \
              --latency-mode generation \
              --depth 0 2048 4096 \
              --enable-prefix-caching | tee -a "$BENCH_FILE"
            
            echo -e "\n" >> "$BENCH_FILE"

            echo "Running 32k context stress test..."
            PYTHONWARNINGS="ignore" TRANSFORMERS_VERBOSITY=error uvx llama-benchy \
              --base-url http://localhost:8085/v1 \
              --model Qwen3.6-35B \
              --latency-mode generation \
              --pp 2048 \
              --depth 30720 \
              --enable-prefix-caching | tee -a "$BENCH_FILE"

            echo "Benchmarks complete. Results appended to $BENCH_FILE"
            ;;
        *)
            echo "Usage: ai [chat|code|fast|ui|off|status|logs|bench]"
            ;;
    esac
}
