FROM python:3.13-slim-bookworm AS build

# Install R runtime & common system libs needed by R packages
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    r-base r-base-dev r-cran-v8 \
    build-essential \
    libcurl4-openssl-dev libssl-dev libxml2-dev \
 && rm -rf /var/lib/apt/lists/*


# Set CRAN mirror and install packages with error checking

# install r package installers
RUN R -e "options(repos = c(CRAN = 'https://cloud.r-project.org/')); \
          install.packages('remotes')" || exit 1
RUN R -e "options(repos = c(CRAN = 'https://cloud.r-project.org/')); \
          install.packages('BiocManager')" || exit 1

COPY DESCRIPTION /build/DESCRIPTION
WORKDIR /build

# manually install dependencies
RUN R -e "remotes::install_deps('.', dependencies = TRUE)" || exit 1
RUN R -e "BiocManager::install('ComplexHeatmap')" || exit 1


COPY . /build

# install local package
RUN R -e "remotes::install_local('.', repos=NULL, build = FALSE, type= 'source', dependencies = FALSE)" || exit 1

FROM python:3.13-slim-bookworm

# Install R runtime & common system libs needed by rpy2 and R packages
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    r-base \
    libcurl4 \
    libssl3 \
    libxml2 \
    build-essential \
    libcurl4-openssl-dev libssl-dev libxml2-dev \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/lib/R/site-library /usr/local/lib/R/site-library
COPY --from=build /usr/lib/R/site-library /usr/lib/R/site-library
COPY --from=build /usr/lib/R/library /usr/lib/R/library
