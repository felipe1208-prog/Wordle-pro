import json
import os
import unicodedata
import urllib.request

# Enlaces espejo garantizados al corpus completo de palabras en español (~636.000 términos)
URLS = [
    "https://cdn.jsdelivr.net/gh/words/an-array-of-spanish-words@master/index.json",
    "https://raw.githubusercontent.com/words/an-array-of-spanish-words/master/index.json",
    "https://unpkg.com/an-array-of-spanish-words@2.0.0/index.json"
]

def limpiar(palabra: str) -> str:
    # Remueve tildes y diéresis (Á->A, É->E, etc.) y convierte a mayúsculas
    palabra = unicodedata.normalize('NFD', palabra)
    palabra = ''.join(c for c in palabra if unicodedata.category(c) != 'Mn')
    return palabra.strip().upper()

def main():
    print("Descargando corpus completo de palabras en español...")
    datos_raw = None

    for url in URLS:
        try:
            print(f"Conectando a fuente: {url}")
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=20) as resp:
                datos_raw = resp.read().decode('utf-8', errors='ignore')
                print("¡Descarga exitosa!")
                break
        except Exception as e:
            print(f"Fallo en este enlace ({e}), intentando el siguiente...")

    if not datos_raw:
        print("Error: No se pudo descargar desde ninguna fuente.")
        return

    print("Procesando y filtrando palabras de 5 letras...")
    lista_total = json.loads(datos_raw)

    palabras_5 = set()
    for item in lista_total:
        limpia = limpiar(item)
        # Filtrar exactamente 5 letras y solo caracteres alfabéticos
        if len(limpia) == 5 and limpia.isalpha():
            palabras_5.add(limpia)

    # Asegurar que todas las palabras de la materia siempre estén incluidas
    ruta_secretas = "palabras_secretas.json"
    if os.path.exists(ruta_secretas):
        try:
            with open(ruta_secretas, "r", encoding="utf-8") as f:
                secretas = json.load(f)
                for w in secretas:
                    palabras_5.add(limpiar(w))
            print("Palabras de la materia integradas al diccionario.")
        except Exception as e:
            print(f"Nota: No se pudo leer {ruta_secretas}: {e}")

    resultado_ordenado = sorted(list(palabras_5))
    print(f"\n==========================================")
    print(f"Total de palabras en el nuevo diccionario: {len(resultado_ordenado)}")
    print(f"==========================================")

    # Sobreescribir diccionario.json
    with open("diccionario.json", "w", encoding="utf-8") as f:
        json.dump(resultado_ordenado, f, ensure_ascii=False, indent=2)

    print("¡Archivo diccionario.json actualizado exitosamente!")

if __name__ == "__main__":
    main()