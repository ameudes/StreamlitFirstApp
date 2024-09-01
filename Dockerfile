	FROM debian:testing

 	#PYTHON PART
	WORKDIR /app
	# Copy the requirements file to the working directory
	RUN mkdir /opt/python3.10

	# To avoid .pyc files and save space
	ENV PYTHONDONTWRITEBYTECODE 1
	ENV PYTHONUNBUFFERED 1

	# Install all dependecnies you need to compile Python3.10
	RUN apt update
	RUN apt install -y wget libffi-dev gcc build-essential curl tcl-dev tk-dev uuid-dev lzma-dev liblzma-dev libssl-dev libsqlite3-dev

	# Download Python source code from official site and build it
	RUN wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz
	RUN tar -zxvf Python-3.10.0.tgz
	RUN cd Python-3.10.0 && ./configure --prefix=/opt/python3.10 && make && make install

	# Delete the python source code and temp files
	RUN rm Python-3.10.0.tgz
	RUN rm -r Python-3.10.0/

	# Now link it so that $python works
	RUN ln -s /opt/python3.10/python3.10 /usr/bin/python





	#R PART
	## Set a default user. Available via runtime flag `--user docker`
	## Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
	## User should also have & own a home directory (for rstudio or linked volumes to work properly).
	RUN useradd docker \
		&& mkdir /home/docker \
		&& chown docker:docker /home/docker \
		&& addgroup docker staff
	
	RUN apt-get update \
		&& apt-get install -y --no-install-recommends \
			ed \
			less \
			locales \
			vim-tiny \
			wget \
			ca-certificates \
			fonts-texgyre \
		&& rm -rf /var/lib/apt/lists/*
	
	## Configure default locale, see https://github.com/rocker-org/rocker/issues/19
	RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
		&& locale-gen en_US.utf8 \
		&& /usr/sbin/update-locale LANG=en_US.UTF-8
	
	ENV LC_ALL en_US.UTF-8
	ENV LANG en_US.UTF-8
	
	## Use Debian unstable via pinning -- new style via APT::Default-Release
	RUN echo "deb http://http.debian.net/debian sid main" > /etc/apt/sources.list.d/debian-unstable.list \
			&& echo 'APT::Default-Release "testing";' > /etc/apt/apt.conf.d/default \
			&& echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/90local-no-recommends
	
	ENV R_BASE_VERSION 4.1.0
	
	## During the freeze, new (source) packages are in experimental and we place the binaries in our PPA
	RUN echo "deb http://deb.debian.org/debian experimental main" > /etc/apt/sources.list.d/experimental.list \
		&& echo "deb [trusted=yes] https://eddelbuettel.github.io/ppaR400 ./" > /etc/apt/sources.list.d/edd-r4.list
	
	## Now install R and littler, and create a link for littler in /usr/local/bin
	RUN apt-get update \
			&& apt-get install -y --no-install-recommends \
					libopenblas0-pthread \
			littler \
					r-cran-littler \
			r-base=${R_BASE_VERSION}-* \
			r-base-dev=${R_BASE_VERSION}-* \
					r-base-core=${R_BASE_VERSION}-* \
			r-recommended=${R_BASE_VERSION}-* \
		&& ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r \
		&& ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
		&& ln -s /usr/lib/R/site-library/littler/examples/installBioc.r /usr/local/bin/installBioc.r \
		&& ln -s /usr/lib/R/site-library/littler/examples/installDeps.r /usr/local/bin/installDeps.r \
		&& ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
		&& ln -s /usr/lib/R/site-library/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
		&& install.r docopt \
		&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
		&& rm -rf /var/lib/apt/lists/*
	





#RESTE DE LA CONFIG
# Définir la variable d'environnement R_HOME
ENV R_HOME /usr/lib/R
ENV PATH="${R_HOME}/bin:${PATH}"

# Copier le package source local dans l'image Docker
COPY randomForest_4.7-1.1.tar.gz /tmp/randomForest_4.7-1.1.tar.gz
# Installer le package R à partir du fichier source
RUN R CMD INSTALL /tmp/randomForest_4.7-1.1.tar.gz
# Nettoyer le fichier source pour garder l'image légère
RUN rm /tmp/randomForest_4.7-1.1.tar.gz


COPY ./app .
RUN python -m pip install --upgrade pip
RUN python -m pip install -r requirements.txt
EXPOSE 8501
CMD ["streamlit", "run", "app.py"]
