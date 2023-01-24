# Examples
example_app_name=busybox
example_environment_name=local.net
example_machine_name=aio-vm.${example_environment_name}
example_machine_group_name=aio
example_kubeconfig=/home/myuser/kubeconfig
# Global Paths
global_infrastructure_dir=${my_work_dir}/infrastructure
global_infrastructure_apps_dir=${global_infrastructure_dir}
global_infrastructure_apps_playbook="${global_infrastructure_apps_dir}/apps/setup.yaml"
# Docker Apps
docker_apps_dir=apps/docker
docker_apps_catalog_dir=${docker_apps_dir}/catalog
docker_app_definition_name=docker-compose.yml
# K8s Apps
k8s_apps_dir=apps/kubernetes
k8s_apps_catalog_dir=${k8s_apps_dir}/catalog
# ANSI Colors
RESTORE=$(echo -en '\033[0m')
RED=$(echo -en '\033[00;31m')
GREEN=$(echo -en '\033[00;32m')
YELLOW=$(echo -en '\033[00;33m')
BLUE=$(echo -en '\033[00;34m')
MAGENTA=$(echo -en '\033[00;35m')
PURPLE=$(echo -en '\033[00;35m')
CYAN=$(echo -en '\033[00;36m')
LIGHTGRAY=$(echo -en '\033[00;37m')
LRED=$(echo -en '\033[01;31m')
LGREEN=$(echo -en '\033[01;32m')
LYELLOW=$(echo -en '\033[01;33m')
LBLUE=$(echo -en '\033[01;34m')
LMAGENTA=$(echo -en '\033[01;35m')
LPURPLE=$(echo -en '\033[01;35m')
LCYAN=$(echo -en '\033[01;36m')
WHITE=$(echo -en '\033[01;37m')

USAGE_SHORT="""
Usage:

${GREEN}Note:${RESTORE} Any examples herein use the below sample values:
- Environment with a path of ${WHITE}${my_work_dir}/examples/environments/${example_environment_name}${RESTORE}
- App Name of ${WHITE}${example_app_name}${RESTORE}
- Machine Name of ${WHITE}${example_machine_name}${RESTORE}
- Machine Group Name of ${WHITE}aio${RESTORE}
- Kubeconfig path of ${WHITE}${example_kubeconfig}${RESTORE}

* ${LYELLOW}Initialize bash tab completion shortcut functions for specified enviornment path${RESTORE}
	${YELLOW}${my_script_path} ${my_work_dir}/examples/environments/${example_environment_name} init${RESTORE}
* ${LYELLOW}Run specified machine definition playbook${RESTORE}
	${YELLOW}${my_script_path}  --environment_dir {{ environment_dir }} {{ machine_definition_playbook }}${RESTORE}
* ${LYELLOW}Run specified machine definition playbook using tab-completed shortcut functions${RESTORE}
	${YELLOW}run.${example_environment_name}.${example_machine_name%%.*}${RESTORE}
* ${LYELLOW}Run specified machine group playbook${RESTORE}
	${YELLOW}${my_script_path}  --environment_dir {{ environment_dir }} {{ machine_group_playbook }}${RESTORE}
* ${LYELLOW}Run specified machine group playbook (using tab completion)${RESTORE}
	${YELLOW}run.${example_environment_name}.${example_machine_group_name}
* ${LYELLOW}Install/Remove specified app${RESTORE}
	${YELLOW}${my_script_path} [--kubeconfig|-k {{ kubeconfig_path }}] \\
	[--namespace|-n namespace] [--filter-by-kind|-f kind] \\
	[--replicas|-r replica_count] [--app-version|-v app_version] [--debug-mode|-D] \\ 
	[--ingress-url|-I ingress_url] \\
	[--rancher-api-host|-Rh rancher_api_fqdn] \\
	[--rancher-username|-Ru rancher_username] \\
	[--rancher-password|-Rp rancher_password] \\
	[--kubeconfig-from-rancher|-Rc] \\
	[--render-app-files] \\
	[--cluster|-cl clustername] --environment_dir {{ environment_dir }} \\
	install/uninstall {{ app_type }} {{ object_type }} {{ object_name }}${RESTORE}
* ${LYELLOW}Install/Remove specified docker app using tab-completed shortcut functions${RESTORE}
	${YELLOW}run.${example_environment_name}.install.docker.app.${example_app_name}${RESTORE}
	${YELLOW}run.${example_environment_name}.remove.docker.app.${example_app_name}${RESTORE}
* ${LYELLOW}Install/Remove specified k8s app using tab-completed shortcut functions${RESTORE}
	${YELLOW}run.${example_environment_name}.install.k8s.app.${example_app_name} -cl my-cluster -k ${example_kubeconfig}${RESTORE}
	${YELLOW}run.${example_environment_name}.remove.k8s.app.${example_app_name} -cl my-cluster -k ${example_kubeconfig}${RESTORE}
"""

USAGE_DOCKER_APP="""${USAGE_SHORT}
${LPURPLE}Installing Docker Apps:${RESTORE}

* ${LYELLOW}Install a Docker app named '${example_app_name}' for environment named '${example_environment_name}'${RESTORE}
	${YELLOW}${my_script_path} \\
	--environment_dir ${my_work_dir}/examples/environments/${example_environment_name} \\
	install docker app ${example_app_name}${RESTORE}
* ${LYELLOW}Remove app${RESTORE}
	${YELLOW}${my_script_path} \\
	--environment_dir ${my_work_dir}/examples/environments/${example_environment_name} \\
	remove docker app ${example_app_name}${RESTORE}
"""

USAGE_K8S_APP="""${USAGE_SHORT}
${LPURPLE}Installing Kubernetes/K8s Apps:${RESTORE}

* ${LYELLOW}Install Kubernetes app named '${example_app_name}' to cluster named "my-cluster" in, specifying your KUBECONFIG as ${example_kubeconfig}${RESTORE}
	${YELLOW}${my_script_path} --environment_dir ${my_work_dir}/examples/environments/${example_environment_name} -cl my-cluster -k ${example_kubeconfig} install k8s app ${example_app_name}${RESTORE}
* ${LYELLOW}Install Kubernetes app named '${example_app_name}' to cluster named "my-cluster", overriding Ingress URL to ${example_app_name}.${example_environment_name}${RESTORE}
	${YELLOW}${my_script_path} --environment_dir ${my_work_dir}/examples/environments/${example_environment_name} -cl my-cluster -I ${example_app_name}.${example_environment_name} install k8s app ${example_app_name}${RESTORE}
* ${LYELLOW}Install Kubernetes app named '${example_app_name}' to cluster named "my-cluster" in namespace my-namespace${RESTORE}
	${YELLOW}${my_script_path} --environment_dir ${my_work_dir}/examples/environments/${example_environment_name} -cl my-cluster -n my-namespace install k8s app ${example_app_name}${RESTORE}
* ${LYELLOW}Install Kubernetes app named '${example_app_name}' to cluster named "my-cluster" in namespace my-namespace, specifying app version 3.2.0${RESTORE}
	${YELLOW}${my_script_path} --environment_dir ${my_work_dir}/examples/environments/${example_environment_name} -cl my-cluster -n my-namespace -v 3.2.0 install k8s app ${example_app_name}${RESTORE}
* ${LYELLOW}Install Kubernetes app named '${example_app_name}' to cluster named "my-cluster" in namespace my-namespace, limiting actions to K8s deployments${RESTORE}
	${YELLOW}${my_script_path} --environment_dir ${my_work_dir}/examples/environments/${example_environment_name} -cl my-cluster -n my-namespace -f deploymets install k8s app ${example_app_name}${RESTORE}
* ${LYELLOW}Install Kubernetes app named '${example_app_name}' to cluster named "my-cluster" in namespace my-namespace, overriding the deployment name (default == app_name)${RESTORE}
	${YELLOW}${my_script_path} --environment_dir ${my_work_dir}/examples/environments/${example_environment_name} -cl my-cluster -n my-namespace -O my_deployment_name install k8s app ${example_app_name}${RESTORE}
* ${LYELLOW}Remove app${RESTORE}
	Same as examples above, except instead of calling with 'install' action,
	call with 'remove' action, e.g.
	${YELLOW}${my_script_path} --environment_dir ${my_work_dir}/examples/environments/${example_environment_name} -cl my-cluster -k ${example_kubeconfig} remove k8s app ${example_app_name}${RESTORE}
"""