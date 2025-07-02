import hashlib


def password_encrypter(password):
    h = hashlib.sha1()
    h.update(bytes(password, 'utf-8'))
    return h.hexdigest()
