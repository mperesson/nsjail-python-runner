# NSJail Python runner

A small FLask service that allow Python code execution in a restricted space using NSJail.

### Requirements:
* Docker
* python 3.12
* uv


### Build and run locally: 
`make build && make run`

### Example:
```shell
curl --request POST \
  --url http://127.0.0.1:5000/execute \
  --header 'content-type: application/json' \
  --data '{
  "script": "def main():\n    import pandas as pd\n    \n    # Create a simple DataFrame\n    data = {\n        \"Name\": [\"Alice\", \"Bob\", \"Charlie\"],\n        \"Age\": [25, 30, 35],\n        \"Score\": [85.5, 90.2, 88.7]\n    }\n    df = pd.DataFrame(data)\n    \n    # Calculate average age and average score\n    avg_age = df[\"Age\"].mean()\n    avg_score = df[\"Score\"].mean()\n    \n    # Filter people with score above 87\n    high_scorers = df[df[\"Score\"] > 87][\"Name\"].tolist()\n    \n    # Return a summary dict\n    return {\n        \"average_age\": avg_age,\n        \"average_score\": avg_score,\n        \"high_scorers\": high_scorers,\n        \"dataframe_preview\": df.head().to_dict()\n    }"
}'
```

Response:
```json
{
  "return": {
    "average_age": 30,
    "average_score": 88.13333333333333,
    "high_scorers": [
      "Bob",
      "Charlie"
    ],
    "dataframe_preview": {
      "Name": {
        "0": "Alice",
        "1": "Bob",
        "2": "Charlie"
      },
      "Age": {
        "0": 25,
        "1": 30,
        "2": 35
      },
      "Score": {
        "0": 85.5,
        "1": 90.2,
        "2": 88.7
      }
    }
  },
  "stdout": "",
  "error": null
}
```

### Add python package to jailed runner:
`uv add --group sandbox <package>`
