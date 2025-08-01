import sys
import io
import json
import importlib.util

code_path = sys.argv[1]
result_path = sys.argv[2]

sys.stdout = io.StringIO()
result = {"return": None, "stdout": "", "error": None}

try:
    spec = importlib.util.spec_from_file_location("user_code", code_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    if hasattr(module, "main"):
        result["return"] = module.main()
    else:
        result["error"] = "No main() function found"
except Exception as e:
    result["error"] = str(e)

result["stdout"] = sys.stdout.getvalue()

with open(result_path, "w") as f:
    json.dump(result, f)
