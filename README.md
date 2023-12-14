# Puppet Modules for Micro Integrator

This repository contains the Puppet modules for WSO2 Micro Integrator.

## Quick Start Guide
1. Download an updated wso2mi-4.1.0.zip pack and copy it to the `<puppet_environment>/modules/micro_integrator/files` directory in the **Puppetmaster**.

2. Set up the JDK distribution as follows:

   The Puppet modules for WSO2 products use Eclipse Temurin as the JDK distribution. However, you can use any [supported JDK distribution](https://apim.docs.wso2.com/en/4.1.0/install-and-setup/setup/reference/product-compatibility/#tested-dbmss_1).
   1. Download Eclipse Temurin JDK for Linux x64 from [here](https://adoptium.net/en-GB/temurin/releases/?variant=openjdk11&os=linux) and copy .tar into the `<puppet_environment>/modules/micro_integrator/files` directory.
   2. Reassign the *$jdk_name* variable in `<puppet_environment>/modules/micro_integrator/manifests/params.pp` to the name of the downloaded JDK distribution.
3. Run the Micro Integrator on the **Puppet agents**.
    ```bash
    export FACTER_profile=micro_integrator
    puppet agent -vt
    ```

## Manifests in a module
The run stages for Puppet are described in `<puppet_environment>/manifests/site.pp`, and they are of the order Main -> Custom -> Final.

Each Puppet module contains the following .pp files.
* Main
    * params.pp: Contains all the parameters necessary for the main configuration and template
    * init.pp: Contains the main script of the module.
* Custom
    * custom.pp: Used to add custom configurations to the Puppet module.
* Final
    * startserver.pp: Runs at the end and starts the server as a linux service.
    