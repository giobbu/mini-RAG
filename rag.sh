pip install -q docling scikit-learn
echo " "
echo "----------------------------"
echo "Docling documentation to markdown (tmp/md) and extract context (tmp/ctx) for question:"
echo " "
mkdir -p tmp && docling "$1" --to md --output tmp/md
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
curl -s "${OLLAMA_URL:-http://localhost:11434}/api/chat" -d "$(jq -n --arg m "${MODEL:-qwen2.5:7b}" --arg q "$2" --rawfile c tmp/ctx '{model:$m,stream:false,messages:[{role:"user",content:("Answer only from this context:\n"+$c+"\nQ: "+$q)}]}')" | jq -r '.message.content'