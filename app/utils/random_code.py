import string
import random


def random_code(longitud: int = 8) -> str:
    if longitud < 1:
        raise ValueError("La longitud debe ser al menos 1")

    caracteres = string.ascii_letters + string.digits + "@#$%&*_"
    codigo = ''.join(random.choice(caracteres) for _ in range(longitud))

    mitad = longitud // 2
    codigo = codigo[:mitad] + "-" + codigo[mitad:]

    return codigo
