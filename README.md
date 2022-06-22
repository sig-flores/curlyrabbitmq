# curlyrabbitmq

This script lets you move messages in RabbitMQ from one queue to another and is configured to use HTTP PUT, GET and DELETE requests.

Currently this script is designed to function within a Jenkins pipeline and reads the set of user specified params for invoking the moves across different queues.cat 