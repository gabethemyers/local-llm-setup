# Add to ~/.bashrc or ~/.zshrc:
# source /path/to/local-llm/scripts/ai.sh

ai() {
    local MTP_MODEL_PATH=~/models/Qwen3.6-35B-A3B-MTP-UD-Q4_K_XL.gguf
    local MTP_SERVER_BIN=~/quins-llama/build/bin/llama-server
    local LEGACY_MODEL_PATH=~/models/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf
    local LEGACY_SERVER_BIN=~/llama-cpp-turboquant/build/bin/llama-server
    local PORT=8085

    case "$1" in
        chat)
            echo "Initializing Chat Mode (MTP, 65k Context)..."
            if pgrep -x "llama-server" > /dev/null; then
                pkill -x "llama-server"
                sleep 2
            fi

            nohup $MTP_SERVER_BIN \
                -m $MTP_MODEL_PATH \
                -fitt 1600 \
                -c 65536 \
                -n 32768 \
                -fa on \
                -np 1 \
                -ctk q8_0 \
                -ctv q8_0 \
                -ctkd q8_0 \
                -ctvd q8_0 \
                -ctxcp 64 \
                --no-mmap \
                --mlock \
                --no-warmup \
                --threads 6 \
                --cont-batching \
                --batch-size 1024 \
                --ubatch-size 512 \
                --spec-type mtp \
                --spec-draft-n-max 2 \
                --chat-template-kwargs '{"preserve_thinking": true}' \
                --temp 0.6 \
                --top-p 0.95 \
                --top-k 20 \
                --min-p 0.0 \
                --presence-penalty 0.0 \
                --repeat-penalty 1.0 \
                --host 0.0.0.0 --port $PORT \
                --timeout 300 --metrics > /tmp/llama-server.log 2>&1 &

            docker start open-webui > /dev/null 2>&1
            echo "Open WebUI active at http://localhost:3000"
            firefox http://localhost:3000 > /dev/null 2>&1 &
            ;;

        legacy)
            echo "Initializing Legacy Chat Mode (32k Context)..."
            if pgrep -x "llama-server" > /dev/null; then
                pkill -x "llama-server"
                sleep 2
            fi

            nohup $LEGACY_SERVER_BIN \
                -m $LEGACY_MODEL_PATH \
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

        *)
            echo "Usage: ai [chat|legacy|off|ui|status|logs]"
            ;;
    esac
}
