from flask import Flask, request, jsonify
import logging
import json
import base64

app = Flask(__name__)

gunicorn_logger = logging.getLogger('gunicorn.error')
app.logger.handlers = gunicorn_logger.handlers
app.logger.setLevel(gunicorn_logger.level)
log = app.logger

@app.post("/mutate")
def mutate():
    log.debug("Mutate: processing request")
    log.debug("Mutate: request headers: {}".format(request.headers))
    if request.is_json:
        log.debug("Mutate: request json: %s" % json.dumps(request.get_json(), indent=4, sort_keys=True ))
        uid = request.get_json()['request']['uid']
        log.debug("Mutate: Request UID: %s" % uid)

        # Add additional label
        patch = [
            { "op": "add", "path": "/metadata/labels/mutated", "value": "yes"}
        ]

        res_object = {
            "apiVersion": "admission.k8s.io/v1",
            "kind": "AdmissionReview",
            "response": {
                "uid": uid,
                "allowed": True,
                "patchType": "JSONPatch",
                "patch": base64.b64encode(bytes(json.dumps(patch),"UTF-8")).decode("utf-8")
            }
        }

        log.debug("Mutate: response json: %s" % json.dumps(res_object, indent=4, sort_keys=True))
        return jsonify(res_object), 200
    return {"error": "Request must be JSON"}, 415


@app.route('/', defaults={'path': ''}, methods=[
    'GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'CONNECT', 'OPTIONS', 'TRACE', 'PATCH'])
@app.route('/<path:path>', methods=[
    'GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'CONNECT', 'OPTIONS', 'TRACE', 'PATCH'])
def catch_all(path):
    log.debug("Catch-all: unhandled request")
    log.debug("Catch-all: request object: {}".format(request))
    log.debug("Catch-all: request headers: {}".format(request.headers))
    if request.is_json:
        log.debug("Catch-all: request json: %s" % json.dumps(request.get_json(), indent=4, sort_keys=True ))
    else:
        log.debug("Catch-all: request data: {}".format(request.get_data()))
    return "Path '%s' is not configured on the server" % path, 404

if __name__ == '__main__':
    app.run()
