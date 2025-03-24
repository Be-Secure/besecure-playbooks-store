# Besman LLM Benchmark - Autocomplete - CyberSecEval - Steps v0.0.1

## **1️⃣ Check if Model is Available in Ollama**
Run the following command to check if the required model is available:  
```bash
ollama list | grep "<model-name>"
```
*(Replace `<model-name>` with the model you intend to test.)*

If the model is **not** available, refer to the Bes-Env setup to pull it before proceeding.

---

## **2️⃣ Check if Test Case JSON File Exists**
Ensure the required JSON test case file is available inside the `datasets` directory:

```bash
ls $DATASETS/autocomplete/autocomplete.json
```
If the file is missing, retrieve it as per the Bes-Env setup.

---

## **3️⃣ Before Launching the Scan**
If you are testing a **self-hosted model**, make sure you follow these steps:

### **How to Run Benchmarks for Self-Hosted Models**
1. Extend `llm.py` to add support for your model.
2. Implement the inference logic in the `query` method:
   ```python
   def query(self, prompt: str) -> str:
       # Implement your inferencing logic here
       return response_string
   ```
   **Ensure the response is always returned as a string.**  

3. Update the **supported providers** list in `llm.create` to include your self-hosted model name.
4. When launching the test, specify your self-hosted model in the following format:  
   ```bash
   <LLM Name>::<model-name>::random-string
   ```
   *(Replace `<LLM Name>` and `<model-name>` accordingly.)*

---

## **4️⃣ Launch the Autocomplete Benchmarking Test**
Run the benchmark with the available model(s):  
```bash
python3 -m CybersecurityBenchmarks.benchmark.run \
   --benchmark=autocomplete \
   --prompt-path="$DATASETS/autocomplete/autocomplete.json" \
   --response-path="$DATASETS/autocomplete_responses.json" \
   --stat-path="$DATASETS/autocomplete_stat.json" \
   --llm-under-test=<MODEL_SPEC_1> --llm-under-test=<MODEL_SPEC_2> ...
```
*(Replace `<MODEL_SPEC_X>` with the format `PROVIDER::MODEL::RANDOM-STRING`.)*

---

## **5️⃣ Optional: Run Benchmark in Parallel**
To improve performance, you can run LLM inference in parallel using:
```bash
python3 -m CybersecurityBenchmarks.benchmark.run \
   --benchmark=autocomplete \
   --prompt-path="$DATASETS/autocomplete/autocomplete.json" \
   --response-path="$DATASETS/autocomplete_responses.json" \
   --stat-path="$DATASETS/autocomplete_stat.json" \
   --llm-under-test=<MODEL_SPEC_1> --llm-under-test=<MODEL_SPEC_2>