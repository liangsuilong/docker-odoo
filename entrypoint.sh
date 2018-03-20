#!/bin/bash

set -e

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file

ODOO_CODE="/opt/odoo"
ODOO_CONF_FILE="${ODOO_CODE}/odoo.conf"

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if ! grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        DB_ARGS+=("--${param}")
        DB_ARGS+=("${value}")
   fi;
}
check_config "db_host" "postgresql"
check_config "db_port" "${POSTGRES_PORT}"
check_config "db_user" "${POSTGRES_USER}"
check_config "db_password" "${POSTGRES_PASSWORD}"

case "$1" in
	odoo)
		chown -R odoo:odoo /var/lib/odoo/
		if [[ `ls $ODOO_CODE | wc -l` == 0 ]]; then
			echo "Running Odoo Code In Container......"
        		exec gosu odoo /usr/bin/odoo  "${DB_ARGS[@]}"
		else
			echo "Running Odoo Code In External Volume......"
			if [[ ! -f $ODOO_CONF_FILE ]]; then
				echo "[options]" > $ODOO_CONF_FILE
				echo "db_host=postgresql" >> $ODOO_CONF_FILE
				echo "db_name=${POSTGRES_DB}" >> $ODOO_CONF_FILE
				echo "db_user=${POSTGRES_USER}" >> $ODOO_CONF_FILE
				echo "db_password=${POSTGRES_PASSWORD}" >> $ODOO_CONF_FILE
				echo "db_port=${POSTGRES_PORT}" >> $ODOO_CONF_FILE
				echo "addons_path=${ODOO_CODE}/addons,${ODOO_CODE}/odoo/addons" >> $ODOO_CONF_FILE
				echo "data_dir=/var/lib/odoo"
			fi 
			chown -R odoo:odoo /opt/odoo/
			exec gosu odoo /usr/bin/python3 ${ODOO_CODE}/odoo-bin -c ${ODOO_CODE}/odoo.conf
                fi 
        	;;
    	*)
        	exec "$@"
esac

exit 1
