#!/usr/bin/env bash

# Checks if the specified user exists
user_exists() {
  user_name="${1}"
  getent passwd "${user_name}" > /dev/null
}

# Print the Linux distribution
get_linux_distribution() {

  if user_exists vyos; then

    echo "vyos"

  # RedHat-based distributions
  elif [[ ( -f '/etc/redhat-release' ) && ! ( -f '/etc/oracle-release' ) ]]; then

    cut --fields=1 --delimiter=' ' '/etc/redhat-release' \
      | tr "[:upper:]" "[:lower:]"

  # Oracle-based distributions
  elif [ -f '/etc/oracle-release' ]; then

    cut --fields=1 --delimiter=' ' '/etc/oracle-release' \
      | tr "[:upper:]" "[:lower:]"

  # Debian-based distributions
  elif [ -f '/etc/lsb-release' ]; then

    grep DISTRIB_ID '/etc/lsb-release' \
      | cut --delimiter='=' --fields=2 \
      | tr "[:upper:]" "[:lower:]"

  elif [ -f '/etc/debian_version' ]; then
    cat /etc/issue | tr "[:upper:]" "[:lower:]"
  elif [ -f '/etc/alpine-release' ]; then
    echo alpine
  fi
}

run_debian() {
	# Check for .cer certs that need to be converted to .crt
	# Copy to local certificate store
	ca_cert_dir=/usr/local/share/ca-certificates
	ls "${certs_dir}"/*.cer 2>/dev/null | while read cert_der;do 
		cert_crt_file=${cert_der%.*}.crt
		echo "Converting ${cert_der} to openssl format"
		openssl x509 -in $cert_der -inform DER -out ${cert_crt_file}
		echo "Done"
		echo "Copying ${cert_crt_file} to ${ca_cert_dir}"
		if ! test -f ${ca_cert_dir}/${cert_crt_file##*/};then
			cp "${cert_crt_file}" ${ca_cert_dir}
			touch ~/.updatecerts
		fi
		echo "Done"
	done
	if [[ -n $(find $HOME/.updatecerts -cmin -5 2> /dev/null) ]];then
		echo "Updating trusted certs"
		update-ca-certificates
		rm -f "${certs_dir}"/*.cer 
		rm -f ~/.updatecerts
	else
		echo "No further certs need to be trusted"
	fi 	
}

run_rhel() {
	# Check for .cer certs that need to be converted to .crt
	# Copy to local certificate store
	# References:
	# https://support.ssl.com/Knowledgebase/Article/View/19/0/der-vs-crt-vs-cer-vs-pem-certificates-and-how-to-convert-them
	# http://manuals.gfi.com/en/kerio/connect/content/server-configuration/ssl-certificates/adding-trusted-root-certificates-to-the-server-1605.html

	ls "${certs_dir}"/*.cer 2>/dev/null | while read cert_der;do 
		cert_der_file=${cert_der%.*}.crt
		echo "Converting ${cert_der_file} to openssl format"
		openssl x509 -in $cert_der -inform DER -out ${cert_der_file}
		if ! test -f /etc/pki/ca-trust/source/anchors/${cert_der_file##*/};then
			cp "${cert_der_file}" /etc/pki/ca-trust/source/anchors/
			touch ~/.updatecerts
		fi
	done
	echo "Importing "
	wget --no-check-certificate https://packages.microsoft.com/keys/microsoft.asc
	rpm --import microsoft.asc
	if ! rpm -q ca-certificates 2>&1 > /dev/null ;then 
		yum -y install ca-certificates
	fi
	if test -f /etc/redhat-release && ! rpm -q libselinux-python 2>&1 > /dev/null ;then
	    yum -y install libselinux-python
	fi
	if [[ -n $(find ~/.updatecerts -cmin -5) ]];then
		echo "Updating trusted certs"
		update-ca-trust force-enable
		update-ca-trust extract
		rm -f "${certs_dir}"/*.cer 
		rm -f ~/.updatecerts
	else
		echo "No further certs need to be trusted"
	fi

}

distro=$(get_linux_distribution)
certs_dir=${1-/tmp}

# CLI
while (( "$#" )); do
	if [[ "$1" =~ ^--certs-dir$|^-c$ ]]; then certs_dir="${2}";shift;fi
	if [[ "$1" =~ ^--debug-mode$|^-D$ ]]; then debug_arg="DEBUG_MODE_ON=true";fi
	if [[ "$1" =~ ^--dry$ ]]; then exec_action=echo;fi
	shift
done

if [[ "$distro" =~ oracle|rhel|redhat|centos|fedora|alpine ]];then
  run_rhel ${certs_dir}
elif [[ "$distro" =~ debian|ubuntu ]];then
  run_debian ${certs_dir}
else
  echo "Detected ${distro}, but no distro matched" 
fi