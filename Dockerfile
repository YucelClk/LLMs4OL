FROM jupyter/minimal-notebook:latest

# Install build tools in case specific pip packages need to compile
USER root
RUN apt-get update && \
    apt-get install -y git build-essential cmake pkg-config && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER $NB_UID
WORKDIR /home/jovyan

# Clone the repo
# RUN git clone https://github.com/HamedBabaei/LLMs4OL.git
# Temporary until repo is merged
Run git clone https://github.com/YucelClk/LLMs4OL.git

WORKDIR /home/jovyan/LLMs4OL

# Optimized Installation

# # CPU Only
# RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu

# GPU Support
RUN pip install --no-cache-dir torch

# Install Sentencepiece separately to preventbuild errors
RUN pip install --no-cache-dir --only-binary=sentencepiece sentencepiece

# Install the rest
RUN pip install --no-cache-dir -r requirements.txt

# Fix permissions & Setup
USER root
RUN fix-permissions /home/jovyan/LLMs4OL && \
    fix-permissions $CONDA_DIR

USER $NB_UID
WORKDIR /home/jovyan/LLMs4OL

CMD ["start-notebook.sh"]