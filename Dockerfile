FROM python:3.9.7-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
    r-base \
    r-base-dev \
    libffi-dev \
    libssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Définir la variable d'environnement R_HOME
ENV R_HOME /usr/lib/R

WORKDIR app/



COPY ./app .
RUN python -m pip install --upgrade pip
RUN python -m pip install -r requirements.txt

EXPOSE 8501
CMD ["streamlit", "run", "app.py"]
