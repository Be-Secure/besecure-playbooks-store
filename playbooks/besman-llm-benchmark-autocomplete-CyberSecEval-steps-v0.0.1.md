# Besman LLM Benchmark - Autocomplete - CyberSecEval - Steps v0.0.1

## **1️⃣ Check if Model is Available in Ollama**
Run the following command to check if the required model is available:  
#bash
ollama list | grep "<model-name>"
(Replace <model-name> with the model you intend to test.)

If the model is not available, refer to the Bes-Env setup to pull it before proceeding.

2️⃣ Check if Test Case JSON File Exists
Ensure the required JSON test case file is available inside the datasets directory:

bash
ls $DATASETS/autocomplete/autocomplete.json
If the file is missing, retrieve it as per the Bes-Env setup.

3️⃣ Launch the Autocomplete Benchmarking Test
Run the benchmark with the available model(s):

#bash
python3 -m CybersecurityBenchmarks.benchmark.run \
   --benchmark=autocomplete \
   --prompt-path="$DATASETS/autocomplete/autocomplete.json" \
   --response-path="$DATASETS/autocomplete_responses.json" \
   --stat-path="$DATASETS/autocomplete_stat.json" \
   --llm-under-test=<MODEL_SPEC_1> --llm-under-test=<MODEL_SPEC_2> ...
(Replace <MODEL_SPEC_X> with the format PROVIDER::MODEL::RANDOM-STRING.)

4️⃣ Optional: Run Benchmark in Parallel
To improve performance, you can run LLM inference in parallel using:

#bash
python3 -m CybersecurityBenchmarks.benchmark.run \
   --benchmark=autocomplete \
   --prompt-path="$DATASETS/autocomplete/autocomplete.json" \
   --response-path="$DATASETS/autocomplete_responses.json" \
   --stat-path="$DATASETS/autocomplete_stat.json" \
   --llm-under-test=<MODEL_SPEC_1> --llm-under-test=<MODEL_SPEC_2> ... \
   --run-llm-in-parallel
5️⃣ Verify & Save Results
The benchmark will generate results in JSON format. Ensure they are stored correctly:

#bash
ls $DATASETS/autocomplete_responses.json
ls $DATASETS/autocomplete_stat.json
Move or store results as needed for further analysis, into
Be-Secure/ besecure-ml-assessment-datastore.