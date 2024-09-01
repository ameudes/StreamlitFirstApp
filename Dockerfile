FROM python:3.9.7-bullseye

# Ajouter le dépôt CRAN pour installer une version plus récente de R
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    && add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian bullseye-cran40/' \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 'E298A3A825C0D65DFD57CBB651716619E084DAB9'

# Installer la version mise à jour de R
RUN apt-get update && apt-get install -y --no-install-recommends \
    r-base=4.1.0-* \
    r-base-dev=4.1.0-* \
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
