
# Use CentOS 8 as the base image
FROM centos:8

# Update the system and install necessary dependencies
RUN dnf -y --disablerepo '*' --enablerepo extras swap centos-linux-repos centos-stream-repos && \
    dnf -y distro-sync && \
    dnf install -y \
    gcc \
    make \
    readline \
    readline-devel \
    zlib \
    zlib-devel \
    flex \
    bison \
    git \
    wget

# Download and extract PostgreSQL 10.10 source code
WORKDIR /usr/src
RUN wget --no-check-certificate https://ftp.postgresql.org/pub/source/v10.10/postgresql-10.10.tar.gz && \
    tar -xzf postgresql-10.10.tar.gz

# Build and install PostgreSQL
WORKDIR /usr/src/postgresql-10.10
RUN ./configure && make && make install

# Clean up unnecessary packages and files
RUN dnf remove -y \
    gcc \
    make \
    readline-devel \
    zlib-devel \
    flex \
    bison \
    git \
    wget && \
    dnf clean all && \
    rm -rf /usr/src/postgresql-10.10*
    
# Create a dedicated user for running PostgreSQL
RUN useradd postgres

# Create directory for data
RUN mkdir -p /usr/local/pgsql/data && \
    chown postgres /usr/local/pgsql && \
    chown postgres /usr/local/pgsql/data && \
    mkdir -p /var/lib/postgresql/data && \
    chown postgres /var/lib/postgresql/data

# Switch to the postgres user
USER postgres

# Set the PATH environment variable
ENV PATH $PATH:/usr/local/pgsql/bin

# Initialize the database
RUN /usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data && \
    chmod 777 /usr/local/pgsql/data/postgresql.conf && \
    chown postgres /usr/local/pgsql/data/postgresql.conf

# Expose PostgreSQL port
EXPOSE 5432

# Run PostgreSQL
CMD ["/usr/local/pgsql/bin/postgres", "-D", "/usr/local/pgsql/data", "-c", "config_file=/usr/local/pgsql/data/postgresql.conf"]
