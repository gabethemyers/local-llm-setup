# Add to ~/.bashrc or ~/.zshrc:
# source /path/to/local-llm/scripts/ai.sh

ai() {
    local MODEL_PATH=~/models/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf
    local SERVER_BIN=~/llama-cpp-turboquant/build/bin/llama-server
    local PORT=8085

    case "$1" in
        chat)
            echo "Initializing Chat Mode (32k Context)..."
            if pgrep -x "llama-server" > /dev/null; then
                pkill -x "llama-server"
                sleep 2 # Wait for port 8085 to fully release
            fi
            
            nohup $SERVER_BIN \
                -m $MODEL_PATH \
                --host 0.0.0.0 --port $PORT \
                --ctx-size 32768 \
                --n-gpu-layers 999 --n-cpu-moe 26 \
                --cache-type-k turbo3 --cache-type-v turbo3 \
                --flash-attn on --batch-size 1024 --parallel 1 \
                --ubatch-size 512 --threads 6 --cont-batching \
                --timeout 300 --metrics > /tmp/llama-server.log 2>&1 &
            
            docker start open-webui > /dev/null 2>&1
            echo "Open WebUI active at http://localhost:3000"
            firefox http://localhost:3000 > /dev/null 2>&1 &
            ;;

        code)
            echo "Initializing Code Mode (32k Context)..."
            docker stop open-webui > /dev/null 2>&1
            
            if pgrep -x "llama-server" > /dev/null; then
                pkill -x "llama-server"
                sleep 2 
            fi
            
            nohup $SERVER_BIN \
                -m $MODEL_PATH \
                --host 0.0.0.0 --port $PORT \
                --ctx-size 32768 \
                --n-gpu-layers 999 --n-cpu-moe 26 \
                --cache-type-k turbo3 --cache-type-v turbo3 \
                --flash-attn on --batch-size 1024 --parallel 1 \
                --ubatch-size 512 --threads 6 --cont-batching \
                --timeout 300 --metrics > /tmp/llama-server.log 2>&1 &
            echo "Llama backend active for code (logs at /tmp/llama-server.log)."
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

        *)
            echo "Usage: ai [chat|code|off|status|logs]"
            ;;
    esac
}
