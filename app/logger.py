import logging
import logging.config


def get_logger_name(name=None):
    if not name:
        name = 'default'
    _lw = str(name).lower().strip()
    if not _lw.startswith('api'):
        name = 'api.' + name

    return name


logging.basicConfig(level=logging.DEBUG, filename='app.log', filemode='a',
                    format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(get_logger_name())
