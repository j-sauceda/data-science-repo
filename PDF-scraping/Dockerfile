FROM rocker/r-ubuntu:latest

WORKDIR /code

# Install required linux packages
RUN add-apt-repository -y ppa:cran/poppler \
    && apt install -y libpoppler-cpp-dev libcurl4-openssl-dev libxml2-dev libssl-dev

# Install stable packages from CRAN
RUN install2.r --error ggExtra shiny curl qpdf pdftools openssl httr dplyr tidyr plotly stringr remotes

# Install development packages from GitHub
RUN installGithub.r \
    rstudio/bslib \
    rstudio/httpuv

COPY . .

CMD ["R", "--quiet", "-e", "shiny::runApp(host='0.0.0.0', port=7860)"]
