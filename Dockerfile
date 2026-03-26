# ============================================================
# Dockerfile for apawlik/MH_netAnaR
# Network Analysis tutorial for GESIS Methods Hub
#
# Based on:
#   runtime.txt  → R 4.4.1 (2024-06-14 CRAN snapshot)
#   apt.txt      → system libraries
#   install.R    → R packages
#   postBuild    → Quarto 1.7.29 + jupyterlab-quarto
# ============================================================

FROM rocker/r-ver:4.4.1

LABEL maintainer="apawlik/MH_netAnaR" \
      description="Network Analysis in R – GESIS Methods Hub tutorial" \
      org.opencontainers.image.source="https://github.com/apawlik/MH_netAnaR"

# ── 1. System dependencies (from apt.txt) ──────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        git \
        python3 \
        python3-pip \
        python3-venv \
        libfontconfig1-dev \
        libfreetype6-dev \
        libglpk-dev \
        libicu-dev \
        libxml2-dev \
        make \
        pandoc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── 2. R packages (from install.R) ─────────────────────────
#    Pin the CRAN snapshot that matches runtime.txt (2024-06-14)
RUN Rscript -e "\
    options(repos = c(CRAN = 'https://packagemanager.posit.co/cran/2024-06-14')); \
    install.packages(c( \
        'igraph', 'netrankr', 'remotes', \
        'ggraph', 'graphlayouts', 'ggrepel', \
        'centiserve', 'knitr', 'ggforce', \
        'stringr', 'Matrix', 'signnet', \
        'emo', 'rmarkdown', 'concaveman' \
    )); \
    remotes::install_github('schochastics/networkdata'); \
    remotes::install_github('hadley/emo')"

# ── 3. Quarto 1.7.29 (from postBuild) ──────────────────────
ENV QUARTO_VERSION=1.7.29

RUN curl -LO "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb" \
    && dpkg -x "quarto-${QUARTO_VERSION}-linux-amd64.deb" /opt/quarto \
    && rm -f "quarto-${QUARTO_VERSION}-linux-amd64.deb" \
    && ln -s /opt/quarto/opt/quarto/bin/quarto /usr/local/bin/quarto \
    # pandoc symlink needed by Quarto visual editor
    && ln -s /opt/quarto/opt/quarto/bin/tools/x86_64/pandoc \
             /opt/quarto/opt/quarto/bin/tools/pandoc

# ── 4. Python / JupyterLab (from postBuild) ────────────────
RUN pip3 install --no-cache-dir \
        jupyterlab \
        jupyterlab-quarto \
        IRkernel

# Register the R kernel for Jupyter
RUN Rscript -e "IRkernel::installspec(user = FALSE)"

# ── 5. Clone the tutorial content ──────────────────────────
WORKDIR /home/rstudio/MH_netAnaR
RUN git clone --depth 1 https://github.com/apawlik/MH_netAnaR.git .

# ── 6. Expose JupyterLab port & default command ────────────
EXPOSE 8888

CMD ["jupyter", "lab", \
     "--ip=0.0.0.0", \
     "--port=8888", \
     "--no-browser", \
     "--allow-root", \
     "--NotebookApp.token=''", \
     "--NotebookApp.password=''"]
