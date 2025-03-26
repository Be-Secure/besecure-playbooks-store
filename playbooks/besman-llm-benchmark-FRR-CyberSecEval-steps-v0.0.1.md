# Besman LLM Benchmark - False Refusal Rate (FRR) - CyberSecEval - Steps v0.0.1

## **1️⃣ Check if Model is Available in Ollama**
Run the following command to check if the required model is available:  
```bash
ollama list | grep "<model-name>"
```
(Replace `<model-name>` with the model you intend to test. Example: `ollama list | grep "gemma3:1b"` to check for the Gemma3:1b model.)

If the model is not available, refer to the Bes-Env setup to pull it before proceeding.

## **2️⃣ Check if Test Case JSON File Exists**
Ensure the required JSON test case file is available inside the datasets directory:

```bash
ls $DATASETS/frr/frr.json
```

If the file is missing, retrieve it as per the Bes-Env setup.

## **3️⃣ Before Launching the Scan**
If you are testing a self-hosted model, make sure you follow these steps:

### **How to Run Benchmarks for Self-Hosted Models**
Navigate to the cloned **PurpleLlama** project directory and update the `llm.py` file inside:
```
PurpleLlama/CybersecurityBenchmarks/benchmark/
```

Extend `llm.py` to add support for your model.

Implement the inference logic in the `query` method:

```python
def query(self, prompt: str) -> str:
    # Implement your inferencing logic here
    return response_string
```

Ensure the response is always returned as a string.

Update the supported providers list in `llm.create` to include your self-hosted model name:

```python
def create(identifier: str) -> LLM:
    if provider.upper() == "GEMMA3":
        return OllamaLLM(name)  # 'name' is the model name
```

Define a class for your Ollama-based model:

```python
class OllamaLLM(LLM):
    def __init__(self, model_name):
        super().__init__(model_name, api_key=None)  # API key is None for local
        self.model_name = model_name
        self.ollama_url = "http://localhost:11434/api/generate"

    @override
    def query(self, prompt: str, guided_decode_json_schema: Optional[str] = None) -> str:
        data = {
            "model": self.model_name,
            "prompt": prompt,
            "stream": False,
        }
        try:
            response = requests.post(self.ollama_url, json=data)
            response.raise_for_status()
            return response.json()["response"]
        except requests.exceptions.RequestException as e:
            print(f"Error querying Ollama: {e}")
            return ""
```

## **4️⃣ Launch the False Refusal Rate (FRR) Benchmarking Test**
Navigate to the **PurpleLlama** project directory and run the benchmark with the available model(s):

```bash
cd PurpleLlama
python3 -m CybersecurityBenchmarks.benchmark.run \
   --benchmark=frr \
   --prompt-path="$DATASETS/frr/frr.json" \
   --response-path="$DATASETS/frr/frr_responses.json" \
   --stat-path="$DATASETS/frr/frr_stat.json" \
   --llm-under-test="OLLAMA::gemma3:1b::dummy_value"
```

### **Optional: Run LLM in Parallel**
To speed up execution, enable parallel processing by adding the `--run-llm-in-parallel` flag:

```bash
python3 -m CybersecurityBenchmarks.benchmark.run \
   --benchmark=frr \
   --prompt-path="$DATASETS/frr/frr.json" \
   --response-path="$DATASETS/frr/frr_responses.json" \
   --stat-path="$DATASETS/frr/frr_stat.json" \
   --llm-under-test="OLLAMA::gemma3:1b::dummy_value" \
   --run-llm-in-parallel
```

## ** Benchmarking Steps**
The FRR benchmark is run in two steps:

1. **Processing prompts** - The LLM is called (in parallel, if specified) to render the LLM output for each prompt. Once the response is received, a keyword-based judgment is conducted, and the judged result is attached.
2. **Gathering statistics** - The benchmark extracts all models' judged results from the response path and outputs them to the statistics path.

## **5️⃣ Verify & Save Results**
The benchmark will generate results in JSON format. Ensure they are stored correctly:

```bash
ls $DATASETS/frr_responses.json
ls $DATASETS/frr_stat.json
```

Move or store results as needed for further analysis.

