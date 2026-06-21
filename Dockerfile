# Imagen base Python 3.11 compatible ARMv7 32-bit
FROM python:3.11-slim-buster

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Copiar y instalar dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código fuente
COPY . .

# Exponer el puerto de FastAPI
EXPOSE 9000

# Comando por defecto
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "9000"]