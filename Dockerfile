# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
FROM jupyter/base-notebook:27ba57364579

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"

USER root

# Install all OS dependencies for fully functional notebook server
RUN apt-get update && apt-get install -yq --no-install-recommends libav-tools\
    build-essential \
    emacs \
    git \
    inkscape \
    jed \
    libsm6 \
    libxext-dev \
    libxrender1 \
    lmodern \
    pandoc \
    python-dev \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-generic-recommended \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-xetex \
    vim \
    unzip \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i /usr/local/bin/start.sh -e 's,# Handle username change,chown 1000:1000 /home/$NB_USER \n # Handle username change,'
RUN cat /usr/local/bin/start.sh

USER $NB_USER

RUN mkdir /home/$NB_USER/tmp
COPY base-env.yml /home/$NB_USER/tmp/base-env.yml
# Install Python 3 packages
# Remove pyqt and qt pulled in for matplotlib since we're only ever going to
# use notebook-friendly backends in these images

RUN conda config --remove channels defaults
RUN conda env update --name root --file /home/$NB_USER/tmp/base-env.yml 

RUN rm -rf /home/$NB_USER/tmp

# Install tutorial environments
RUN git clone https://github.com/oceanhackweek/ohw2018_tutorials.git && \
    cd ohw2018_tutorials && \
    conda env update --name root --file day2/ioos_data_access/environment.yml && \
    conda env update --name root --file day2/ooi_data_access/environment.yml && \
    conda env update --name root --file day3/geospatial_and_mapping_tools/environment.yml && \
    conda env update --name root --file day3/synoptics/environment.yml && \
    conda env update --name root --file day4/data-mining/environment.yml && \
    conda clean -tipsy

RUN rm -rf /home/$NB_USER/ohw2018_tutorials
     
# Activate ipywidgets extension in the environment that runs the notebook server
RUN jupyter nbextension enable --py widgetsnbextension --sys-prefix 
RUN jupyter nbextension enable --py ipyleaflet --sys-prefix
RUN jupyter serverextension enable --py nbgitpuller --sys-prefix
# Also activate ipywidgets extension for JupyterLab
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager@^0.31.0 && \
    npm cache clean && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    fix-permissions $CONDA_DIR

# Install facets which does not have a pip or conda package at the moment
RUN cd /tmp && \
    git clone https://github.com/PAIR-code/facets.git && \
    cd facets && \
    jupyter nbextension install facets-dist/ --sys-prefix && \
    rm -rf facets && \
    fix-permissions $CONDA_DIR

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions /home/$NB_USER

USER $NB_USER
