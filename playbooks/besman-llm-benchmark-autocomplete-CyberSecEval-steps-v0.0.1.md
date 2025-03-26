# Besman LLM Benchmark - Autocomplete - CyberSecEval - Steps v0.0.1

## **1️⃣ Check if Model is Available in Ollama**
Run the following command to check if the required model is available:  
```bash
ollama list | grep "<model-name>"
```
(Replace `<model-name>` with the model you intend to test.)

If the model is not available, refer to the Bes-Env setup to pull it before proceeding.

## **2️⃣ Check if Test Case JSON File Exists**
Ensure the required JSON test case file is available inside the datasets directory:

```bash
ls $DATASETS/autocomplete/autocomplete.json
```

If the file is missing, retrieve it as per the Bes-Env setup.

## **3️⃣ Before Launching the Scan**
If you are testing a self-hosted model, make sure you follow these steps:

### **How to Run Benchmarks for Self-Hosted Models**
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

    @override
    def chat(self, prompt_with_history: List[str], guided_decode_json_schema: Optional[str] = None) -> str:
        full_prompt = "".join(prompt_with_history)
        return self.query(full_prompt, guided_decode_json_schema)

    @override
    def chat_with_system_prompt(self, system_prompt: str, prompt_with_history: List[str], guided_decode_json_schema: Optional[str] = None) -> str:
        full_prompt = system_prompt + "".join(prompt_with_history)
        return self.query(full_prompt, guided_decode_json_schema)

    @override
    def valid_models(self) -> list[str]:
        return ["gemma3:1b"]  # Add your model name here.
```

When launching the test, specify your self-hosted model in the following format:

```bash
OLLAMA::gemma3:1b::dummy_value
```

## **4️⃣ Launch the Autocomplete Benchmarking Test**
Run the benchmark with the available model(s):

```bash
python3 -m CybersecurityBenchmarks.benchmark.run \
   --benchmark=autocomplete \
   --prompt-path="$DATASETS/autocomplete/autocomplete.json" \
   --response-path="$DATASETS/autocomplete_responses.json" \
   --stat-path="$DATASETS/autocomplete_stat.json" \
   --llm-under-test="OLLAMA::gemma3:1b::dummy_value"
```

## **5️⃣ Optional: Run Benchmark in Parallel**
To improve performance, you can run LLM inference in parallel using:

```bash
python3 -m CybersecurityBenchmarks.benchmark.run \
   --benchmark=autocomplete \
   --prompt-path="$DATASETS/autocomplete/autocomplete.json" \
   --response-path="$DATASETS/autocomplete_responses.json" \
   --stat-path="$DATASETS/autocomplete_stat.json" \
   --llm-under-test="OLLAMA::gemma3:1b::dummy_value" \
   --run-llm-in-parallel
```

## **6️⃣ Verify & Save Results**
The benchmark will generate results in JSON format. Ensure they are stored correctly:

```bash
ls $DATASETS/autocomplete_responses.json
ls $DATASETS/autocomplete_stat.json
```

Move or store results as needed for further analysis.

