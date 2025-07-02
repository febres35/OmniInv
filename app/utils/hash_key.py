
import json
import hashlib


def get_hash_key(_filter):
    ret_key = ''
    if _filter:
        text = json.dumps(_filter, sort_keys=True)  # Convertir el filtro a una cadena JSON ordenada
        ret_key = hashlib.sha256(text.encode('utf-8')).hexdigest()  # Crear el hash SHA-256
    return 'CACHE_' + ret_key
