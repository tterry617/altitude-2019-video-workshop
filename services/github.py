import json
from pprint import pprint
import requests
import re

headers={'Fastly-Key': 'xZ8F-XZdRWiOBnu7Cy4QuVn5cEECSPOP'}

api_url = "https://api.fastly.com/service"

services = requests.get(api_url, headers=headers)
services_data = json.loads(services.text)

for i in range(len(services_data)):
  service = services_data[i]
  if re.match("^alt2019", service["name"]) is not None:

    domain = requests.get(api_url + "/" + service["id"] + "/version/1/domain", headers=headers)
    domain_data = json.loads(domain.text)

    file = open(domain_data[0]["name"] + ".txt", "w")

    file.write("-----------------------------------------------------------------------------------------\n\n")
    file.write("Domain: https://" + domain_data[0]['name'] + "\n\n")
    file.write("Service ID: " + service["id"] + "\n\n")
    file.write("------------------------------------------------------------------------------------------\n\n")

    file.close()
