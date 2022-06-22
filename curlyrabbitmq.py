import requests
import os

VHOST = os.environ['VHOST']
INSTANCE_NAME = os.environ['INSTANCE_NAME']
CREDENTIALS = os.environ['CREDENTIALS']
uName, pWord = CREDENTIALS.split(":")
SRC_QUEUE = os.environ['SRC_QUEUE']
DEST_QUEUE = os.environ['DEST_QUEUE']

headers = {
    # Already added when you pass json= but not when you pass data=
    # 'content-type': 'application/json',
}

json_data = {
    'component': 'shovel',
    'vhost': VHOST,
    'name': 'Move from '+SRC_QUEUE,
    'value': {
        'src-uri': 'amqp:///'+VHOST,
        'src-queue': SRC_QUEUE,
        'src-protocol': 'amqp091',
        'src-prefetch-count': 1,
        'src-delete-after': 'queue-length',
        'dest-protocol': 'amqp091',
        'dest-uri': 'amqp:///'+VHOST,
        'dest-add-forward-headers': False,
        'ack-mode': 'on-confirm',
        'dest-queue': DEST_QUEUE,
    },
}

## Adding try / excepts for improved capturing of exceptions..
try:
    ## Token-based auth for this MOVE action doensn't appear to function at this time. 
    ## U:P can be used in the place of the API token for the time being. 
    response = requests.put('https://'+INSTANCE_NAME+'/api/parameters/shovel/'+VHOST+'/Move%20from%20'+SRC_QUEUE, headers=headers, json=json_data, auth=(uName, pWord), timeout=30)
except requests.exceptions.Timeout:
    ## A loop could be configured here to retry if the initial move fails. Future improvement. 
    print("Request Timeout. Please try again...")
except requests.exceptions.TooManyRedirects:
    print("Bad URL. Please try a different one...")
except requests.exceptions.RequestException as e:
    ## Exceptions thrown when catastrophic errors occurs. Will abort process..
    print("Something else went wrong...")
    raise SystemExit(e)
else:
    print("Message has been moved successfully. Check RabbitMQ Management portal to confirm.")