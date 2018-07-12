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

# Install Python 3 packages
# Remove pyqt and qt pulled in for matplotlib since we're only ever going to
# use notebook-friendly backends in these images

RUN conda install -c bokeh --yes \
    datashader

RUN conda install -c conda-forge --yes \
    altair \
    basemap \
    basemap-data-hires \
    boto \
    boto3 \
    bokeh \ 
    cloudpickle \
    dill \
    h5py \ 
    hdf5 \
    ipyleaflet \
    ipywidgets \
    matplotlib \ 
    netcdf4 \
    networkx \
    numba \
    numpy \
    owslib \
    obspy \ 
    pandas \
    pillow \
    plotly \
    requests \
    scikit-learn \
    seaborn \
    vega \
    vega_datasets \
    xarray && \
    conda remove --quiet --yes --force qt pyqt && \
    conda clean -tipsy


# Activate ipywidgets extension in the environment that runs the notebook server
RUN jupyter nbextension enable --py widgetsnbextension --sys-prefix 
RUN jupyter nbextension enable --py ipyleaflet --sys-prefix

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

# PIP Packages
RUN pip install python-cmr

RUN pip install dash==0.20.0 \
    dash-renderer==0.11.3 \
    dash-html-components==0.8.0 \
    dash-core-components==0.18.1

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions /home/$NB_USER

USER $NB_USER
