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
ENV PATH="${R_HOME}/bin:${PATH}"

# Copier le package source local dans l'image Docker
COPY randomForest_4.7-1.1.tar.gz /tmp/randomForest_4.7-1.1.tar.gz

# Installer le package R à partir du fichier source
RUN R CMD INSTALL /tmp/randomForest_4.7-1.1.tar.gz

# Nettoyer le fichier source pour garder l'image légère
RUN rm /tmp/randomForest_4.7-1.1.tar.gz


WORKDIR app/


COPY ./app .
RUN python -m pip install --upgrade pip
RUN python -m pip install -r requirements.txt
EXPOSE 8501
CMD ["streamlit", "run", "app.py"]
