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

RUN R --version
RUN R -e "print('R is installed and working')"

# Installer le package  directement via R
RUN R -e "install.packages('randomForest', repos='http://cran.rstudio.com/')"



WORKDIR app/



COPY ./app .
RUN python -m pip install --upgrade pip
RUN python -m pip install -r requirements.txt

EXPOSE 8501
CMD ["streamlit", "run", "app.py"]
