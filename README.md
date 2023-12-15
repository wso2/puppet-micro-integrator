# Puppet Modules for Micro Integrator

This repository contains the Puppet modules for WSO2 Micro Integrator.

# Quick Start Guide

### Setting up the Puppet Server
1. Setup a puppet server with puppet v7.27.0. [Guide](https://www.puppet.com/docs/puppet/7/install_puppet.html)
2. Copy `site.pp` file to `<puppet_environment>/manifests` directory ( Ex:- `/etc/puppetlabs/code/environments/production/manifests` )
3. Copy `micro_integrator` directory to `<puppet_environment>/modules` directory ( Ex:- `/etc/puppetlabs/code/environments/production/modules` )
4. Install `puppetlabs-java` module using the following command
    ```bash
    sudo puppet module install puppetlabs-java
    ```
5. Download and update wso2mi-4.1.0 pack. Then copy it to the `<puppet_environment>/modules/micro_integrator/files` as `wso2mi-4.1.0.zip` directory.

### Setting up the Puppet Agents
1. Install and configure your puppet agents with your puppet server. [Guide](https://www.puppet.com/docs/puppet/7/install_agents#install_agents)
2. Do a dry run to check if everything is working properly.
    ```bash
    export FACTER_profile=micro_integrator
    sudo -E puppet agent -t --noop
    ```
3. Run the Micro Integrator on your **Puppet agents**.
    ```bash
    export FACTER_profile=micro_integrator
    sudo -E puppet agent -vt
    ```

## Manifest
The run stages for Puppet are described in `/manifests/site.pp`, and they are of the order Main -> Custom -> Final.

* Main
    * params.pp: Contains all the parameters necessary for the main configuration and template
    * init.pp: Contains the main script of the module.
* Custom
    * custom.pp: Used to add custom configurations to the Puppet module.
* Final
    * startserver.pp: Runs at the end and starts the server as a linux service.
    