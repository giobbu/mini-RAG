set -eu

# Check for required commands
if [ $# -lt 2 ]; then
  echo "Usage: rag.sh <path-to-docs> <question> [<top-k>]"
  exit 1
fi

# create venv once, then reuse it
if [ ! -d "venv" ]; then
    echo "----------------------------"
    echo "Creating virtual environment..."
    echo " "
  python3 -m venv venv
fi

echo "----------------------------"
echo "Detecting GPU mode..."
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
  GPU_MODE=cuda
  echo "CUDA GPU detected."
elif python3 -c "import torch; exit(0 if torch.backends.mps.is_available() else 1)" 2>/dev/null; then
  GPU_MODE=mps
  echo "Apple MPS GPU detected."
else
  GPU_MODE=cpu
  echo "No GPU detected. Using CPU mode."
fi

echo "----------------------------"
echo "Activating virtual environment and installing dependencies."
echo " "
. venv/bin/activate
pip install --upgrade pip
pip install -q docling scikit-learn
echo " "

if [ "$GPU_MODE" = "cuda" ]; then
  echo "Ensuring CUDA-enabled torch is installed..."
  pip install -q torch --index-url https://download.pytorch.org/whl/cu121
else
  echo "No NVIDIA GPU: using default torch (CPU or Apple MPS)."
  pip install -q torch
fi
echo " "


echo "----------------------------"
echo "Docling documentation to markdown (tmp/md) and extract context (tmp/ctx) for question:"
echo " "
mkdir -p tmp

if [ "$GPU_MODE" = "cuda" ]; then
  docling "$1" --to md --output tmp/md --device cuda
elif [ "$GPU_MODE" = "mps" ]; then
  docling "$1" --to md --output tmp/md --device mps
else
  docling "$1" --to md --output tmp/md --device auto
fi

python3 - "$2" "${3:-4}" <<'EOF' > tmp/ctx
import sys,glob
from sklearn.feature_extraction.text import TfidfVectorizer as T
ch=[p for f in glob.glob('tmp/md/*.md') for p in open(f).read().split('\n\n') if len(p)>40]
v=T().fit(ch); s=(v.transform(ch)@v.transform([sys.argv[1]]).T).toarray().ravel()
print('\n---\n'.join(ch[i] for i in s.argsort()[-int(sys.argv[2]):][::-1]))
EOF
echo " "
echo "----------------------------"
echo "Ollama Answer based on context:"
echo " "
curl -sN "${OLLAMA_URL:-http://localhost:11434}/api/chat" \
  -d "$(jq -n --arg m "${MODEL:-qwen2.5:7b}" --arg q "$2" --rawfile c tmp/ctx \
    '{model:$m,stream:true,messages:[{role:"user",content:("Answer only from this context:\n"+$c+"\nQ: "+$q)}]}')" \
  | jq --unbuffered -rj '.message.content // empty'
echo