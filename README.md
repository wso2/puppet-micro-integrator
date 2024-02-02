# Puppet Modules for Micro Integrator

This repository contains the Puppet modules for WSO2 Micro Integrator.

## Quick Start Guide

### Setting up the Puppet Server
1. Setup a puppet server with puppet v7.27.0. [Guide](https://www.puppet.com/docs/puppet/7/install_puppet.html)
2. Copy `site.pp` file to `<puppet_environment>/manifests` directory ( Ex:- `/etc/puppetlabs/code/environments/production/manifests` )
3. Copy `micro_integrator` directory to `<puppet_environment>/modules` directory ( Ex:- `/etc/puppetlabs/code/environments/production/modules` )
4. Install `puppetlabs-java` module using the following command
    ```bash
    sudo puppet module install puppetlabs-java
    ```
5. Download and update wso2mi-4.2.0 pack. Then copy it to the `<puppet_environment>/modules/micro_integrator/files` as `wso2mi-4.2.0.zip` directory.
6. [Optional] Download and update wso2mi-dashboard-4.2.0 pack. Then copy it to the `<puppet_environment>/modules/mi_dashboard/files` as `wso2mi-dashboard-4.2.0.zip` directory.

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
4. [Optional] Run the Micro Integrator Dashboard on your **Puppet agents**. (Uncomment `dashboard_config` section in `modules/micro_integrator/templates/mi-home/conf/deployment.toml` to connect MI with Dashboard.)
    ```bash
    export FACTER_profile=mi_dashboard
    sudo -E puppet agent -vt
    ```

## For production deployments
* Change Java destribution in site.pp file according to your requirement. [Refer](https://forge.puppet.com/modules/puppetlabs/java/readme)
* Add any configuration changes required to `/modules/micro_integrator/templates/conf/deployment.toml.erb` file and use puppet config management to manage them. ( Facter, Hiera, etc. )
* You can add any custom code to `/modules/micro_integrator/custom.pp`.