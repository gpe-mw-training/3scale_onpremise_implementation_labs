#!/bin/bash

# Data directory where MySQL database files live. The data subdirectory is here
# because .bashrc and my.cnf both live in /var/lib/mysql/ and we don't want a
# volume to override it.
export MYSQL_DATADIR=/var/lib/mysql

export MYSQL_DEFAULTS_FILE=/etc/my.cnf
export MYSQL_LOWER_CASE_TABLE_NAMES=${MYSQL_LOWER_CASE_TABLE_NAMES:-0}
export MYSQL_BINLOG_FORMAT=${MYSQL_BINLOG_FORMAT:-STATEMENT}
export MYSQL_MAX_CONNECTIONS=${MYSQL_MAX_CONNECTIONS:-151}
export MYSQL_FT_MIN_WORD_LEN=${MYSQL_FT_MIN_WORD_LEN:-4}
export MYSQL_FT_MAX_WORD_LEN=${MYSQL_FT_MAX_WORD_LEN:-20}
export MYSQL_AIO=${MYSQL_AIO:-1}
export MYSQL_MAX_ALLOWED_PACKET=${MYSQL_MAX_ALLOWED_PACKET:-200M}
export MYSQL_TABLE_OPEN_CACHE=${MYSQL_TABLE_OPEN_CACHE:-400}
export MYSQL_SORT_BUFFER_SIZE=${MYSQL_SORT_BUFFER_SIZE:-256K}
export MYSQL_KEY_BUFFER_SIZE=${MYSQL_KEY_BUFFER_SIZE:-32M}
export MYSQL_READ_BUFFER_SIZE=${MYSQL_READ_BUFFER_SIZE:-8M}
export MYSQL_INNODB_BUFFER_POOL_SIZE=${MYSQL_INNODB_BUFFER_POOL_SIZE:-32M}
export MYSQL_INNODB_LOG_FILE_SIZE=${MYSQL_INNODB_LOG_FILE_SIZE:-8M}
export MYSQL_INNODB_LOG_BUFFER_SIZE=${MYSQL_INNODB_LOG_BUFFER_SIZE:-8M} 

# Variables that are used to connect to local mysql during initialization
mysql_flags="-u root --socket=/tmp/mysql.sock"
admin_flags="--defaults-file=$MYSQL_DEFAULTS_FILE $mysql_flags"

# Initialize the MySQL database (create user accounts and the initial database)
function initialize_database() {
  echo 'Initializing database ...'
  echo 'Running mysql_install_db ...'
  mysql_install_db --datadir=$MYSQL_DATADIR
  
  start_local_mysql "$@"

  if [ -v MYSQL_ROOT_PASSWORD ]; then
    echo "Setting password for MySQL root user ..."
    mysql $mysql_flags <<EOSQL
      GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;
EOSQL
  else
  # We do GRANT and DROP USER to emulate a DROP USER IF EXISTS statement
  # http://bugs.mysql.com/bug.php?id=19166
    mysql $mysql_flags <<EOSQL
      GRANT USAGE ON *.* TO 'root'@'%';
      DROP USER 'root'@'%';
      FLUSH PRIVILEGES;
EOSQL
  fi
  echo 'Initialization finished'
}

function start_local_mysql() {
  # Now start mysqld and add appropriate users.
  echo 'Starting MySQL server with disabled networking ...'
  /usr/bin/mysqld_safe \
    --defaults-file=$MYSQL_DEFAULTS_FILE \
    --skip-networking --socket=/tmp/mysql.sock "$@" &
  mysql_pid=$!
  wait_for_mysql $mysql_pid
}

# Poll until MySQL responds to our ping.
function wait_for_mysql() {
  pid=$1 ; shift

  while [ true ]; do
    if [ -d "/proc/$pid" ]; then
      mysqladmin --socket=/tmp/mysql.sock ping &>/dev/null && return 0
    else
      return 1
    fi
    echo "Waiting for MySQL to start ..."
    sleep 1
  done
}

# Shutdown mysql flushing privileges
function shutdown_local_mysql() {
  echo 'Shutting down MySQL ...'
  mysqladmin $admin_flags flush-privileges shutdown
}

function unset_env_vars() {
  echo 'Cleaning up environment variables MYSQL_ROOT_PASSWORD ...'
  unset MYSQL_ROOT_PASSWORD
}
