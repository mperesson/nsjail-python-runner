from flask import Flask, request
import tempfile
import subprocess
import os
import json
from pydantic import BaseModel, ValidationError, field_validator


app = Flask(__name__)


class ScriptPayload(BaseModel):
    script: str

    @field_validator("script")
    @classmethod
    def check_valid_python(cls, v):
        # probably slow but at least we don't pop a new python interpreter
        try:
            compile(v, "<string>", "exec")
        except SyntaxError as e:
            raise ValueError(f"Invalid Python code: {e}")
        return v


@app.route("/execute", methods=["POST"])
def execute():
    try:
        data = ScriptPayload.model_validate(request.json)
    except ValidationError as e:
        return json.dumps({"error": e.errors()}, default=str), 400

    code = data.script
    if not code or "def main" not in code:
        return json.dumps({"error": "We need a `main()` entrypoint."}), 400

    with tempfile.TemporaryDirectory(dir="/sandbox") as tmpdir:
        code_path = os.path.join(tmpdir, "user_code.py")
        result_path = os.path.join(tmpdir, "result.json")

        with open(code_path, "w") as f:
            f.write(code)

        try:
            subprocess.run(
                [
                    "nsjail",
                    "--config",
                    "nsjail.cfg",
                    "--",
                    "/sandbox/venv/bin/python",
                    "/sandbox/runner.py",
                    code_path,
                    result_path,
                ],
                check=True,
            )
        except subprocess.CalledProcessError:
            return json.dumps({"error": "Execution error or timeout"}), 500

        try:
            with open(result_path) as f:
                output = json.load(f)
        except Exception:
            return json.dumps({"error": "Could not read result"}), 500

    return json.dumps(output)
