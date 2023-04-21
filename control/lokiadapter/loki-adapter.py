from tornado.ioloop import IOLoop
from tornado.escape import json_decode
from odin.adapters.adapter import ApiAdapter, ApiAdapterResponse, request_types, response_types, wants_metadata
from odin.adapters.async_adapter import AsyncApiAdapter
from odin._version import get_versions
from odin.adapters.parameter_tree import ParameterTreeError

import logging

class LokiAdapter(AsyncApiAdapter):
    def __init__(self, **kwargs):
        super(LokiAdapter, self).__init__(**kwargs)

        self.testvar = 4

        logging.debug("LOKI adapter loaded")

class LokiCarrier():
    # Generic LOKI carrier support class. Lays out the structure that should be used
    # for all child carrier definitions.
    def __init__(self, **kwargs):
        self.testvar2 = 2

class LokiTEBF0808(LokiCarrier):
    def __init__(self, **kwargs):
        super(LokiTEBF0808, self).__init__(**kwargs)

class Loki_TEBF0808_MERCURY(TEBF0808LokiCarrier):
    def __init__(self, **kwargs):
        super(Loki_TEBF0808_MERCURY, self).__init__(**kwargs)

class Loki_1v0(LokiCarrier):
    def __init__(self, **kwargs):
        super(Loki_1v0, self).__init__(**kwargs)
