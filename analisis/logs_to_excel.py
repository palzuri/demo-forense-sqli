import re
import urllib.parse
import pandas as pd
from openpyxl import Workbook

# Ruta al archivo de logs de Apache
LOG_FILE = '/output/joomla-apache2-logs/access.log'

# Regex para extraer datos del log de Apache
log_pattern = re.compile(
    r'(?P<ip>\S+) \S+ \S+ \[(?P<timestamp>[^\]]+)\] "(?P<method>\S+) (?P<url>\S+)\s*(HTTP/\S+)?" (?P<status>\d{3}) (?P<size>\d+) "(?P<referrer>[^"]*)" "(?P<agent>[^"]*)"'
)

# Inicializar un diccionario para guardar la data de cada paso
data_by_step = {}

# Inicializar la variable current_step
current_step = None

# Leer el archivo de logs
with open(LOG_FILE, 'r') as log_file:
    for line in log_file:
        match = log_pattern.match(line)
        if match:
            log_data = match.groupdict()
            url = log_data['url']
            status = log_data['status']
            size = log_data['size']

            # Identificar el paso basado en la URL
            if 'InicioPaso' in url:
                current_step = url.split('/')[-1]
                data_by_step[current_step] = []
            elif 'FinalizadoPaso' in url:
                current_step = None
            elif current_step:
                # Extraer el punto atacado y el payload de la URL
                payload_match = re.search(r'list%5Bfullordering%5D=([^&]+)', url)
                if payload_match:
                    payload = payload_match.group(1)
                    decoded_payload = urllib.parse.unquote(payload)
                    point_attacked = url.split('?')[0]  # Extracting the URL path before query parameters
                    
                    # Almacenar la información relevante
                    data_by_step[current_step].append({
                        'Punto Atacado': point_attacked,
                        'Payload Decodificado': decoded_payload,
                        'Código de Respuesta': status,
                        'Tamaño de la Respuesta': size
                    })

# Crear un archivo Excel con una hoja por paso
excel_file = '/output/joomla-apache2-logs/sqlmap_analysis.xlsx'
with pd.ExcelWriter(excel_file, engine='openpyxl') as writer:
    for step, data in data_by_step.items():
        if data:
            df = pd.DataFrame(data)
            df.to_excel(writer, sheet_name=step, index=False)

print(f'Análisis completado. Archivo guardado como {excel_file}')