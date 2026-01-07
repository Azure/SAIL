import requests
import json

url = "https://<name>.canadacentral.inference.ml.azure.com/v1/chat/completions"
headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer <token>"
}
data = {
    "model": "microsoft/Phi-3-mini-4k-instruct",
    "messages": [
			{
				"role": "user",
				"content": "What is the capital of France?"
			}
		]
}

response = requests.post(url, headers=headers, json=data)
print(response.json())
