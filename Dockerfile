
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
    
# Create a group and a dedicated user for running PostgreSQL and create directory for data
#RUN groupadd postgres && \
#    useradd -u 1001 postgres -g postgres && \
#    id postgres
RUN groupadd -r postgres --gid=999 &&\
    useradd -r -g postgres --uid=999 --home-dir=/var/lib/postgresql --shell=/bin/bash postgres &&\
    mkdir -p /var/lib/postgresql && \
	chown -R postgres:postgres /var/lib/postgresql

# Set an environment variable with the PostgreSQL user ID
#ENV POSTGRES_UID=$(id -u postgres)
ENV POSTGRE_USER=postgres && \
   POSTGRES_PASSWORD
#    PG_HOME=/var/lib/postgresql \
    
# Create directory for data
#RUN mkdir -p /usr/local/pgsql/data && \
#    chmod 775 -R /usr/local/pgsql/data && \
#    chown postgres:postgres -R /usr/local/pgsql/data && \
#    echo $(whoami) 
#    chown postgres:postgres -R /usr/local/pgsql/bin/postgres
RUN mkdir -p /var/lib/postgresql/data && chown -R postgres:postgres /var/lib/postgresql/data && chmod 777 /var/lib/postgresql/data
VOLUME /var/lib/postgresql/data

# Set the PATH environment variable
ENV PATH $PATH:/usr/local/pgsql/bin

# Switch to the postgres user
USER postgres

# Initialize the database
RUN /usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data && \
    chown $(whoami) /usr/local/pgsql/data/postgresql.conf && \
    echo $(whoami) && \
    id postgres && \
    chmod +r /usr/local/pgsql/data/postgresql.conf
    

# Expose PostgreSQL port
EXPOSE 5432

# Run PostgreSQL
#CMD ["/usr/local/pgsql/bin/postgres", "-D", "/usr/local/pgsql/data", "-c", "config_file=/usr/local/pgsql/data/postgresql.conf"]
#You can now start the database server using: /usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data -l logfile start
CMD ["pg_ctl", "start", "-D", "/usr/local/pgsql/data", "-l", "logfile"]
# init execution https://stackoverflow.com/questions/26201274/postgres-on-docker-how-can-i-create-a-database-and-a-user
ENTRYPOINT ["/usr/local/sbin/initpostgres.sh"]
