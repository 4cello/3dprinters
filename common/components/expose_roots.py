import logging
import os

class RootExposer:
    def __init__(self, config):
        logging.info("gleebglorp loaded")
        fm = config.get_server().lookup_component("file_manager")
        fm.register_directory("common_config", os.path.abspath("/opt/printer_data/common"))
        fm.full_access_roots.add("common_config")

def load_component(config):
    return RootExposer(config)
