# Puppet Modules for Micro Integrator

This repository contains the Puppet modules for WSO2 Micro Integrator.

## Quick Start Guide

### Setting up the Puppet Server
1. Setup a puppet server with puppet v8.x. [Guide](https://help.puppet.com/core/8.13/Content/PuppetCore/installing_and_upgrading.htm)
2. Copy `site.pp` file to `<puppet_environment>/manifests` directory ( Ex:- `/etc/puppetlabs/code/environments/production/manifests` )
3. Copy `micro_integrator` directory to `<puppet_environment>/modules` directory ( Ex:- `/etc/puppetlabs/code/environments/production/modules` )
4. Install `puppetlabs-java` module using the following command
    ```bash
    sudo puppet module install puppetlabs-java
    ```
5. Download and update wso2mi-4.6.0 pack. Then copy it to the `<puppet_environment>/modules/micro_integrator/files` as `wso2mi-4.6.0.zip` directory.
6. [Optional] Download and update wso2-integration-control-plane-2.0.0 pack. Then copy it to the `<puppet_environment>/modules/integration_control_plane/files` as `integration-control-plane-2.0.0.zip` directory.

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
4. [Optional] Run the Integration Control Plane (ICP) on your **Puppet agents**.
    ```bash
    export FACTER_profile=integration_control_plane
    sudo -E puppet agent -vt
    ```
5. [Optional] To connect a Micro Integrator instance to ICP, first mint an org secret - either by hand, or have Puppet mint it automatically on first run.

    ICP exposes two separate listeners, and it matters which one you use where: `server_port` (default 9446) serves GraphQL/auth/the web UI, while `runtime_listener_port` (default 9445) is the dedicated heartbeat listener. **`$icp_url` (MI's own heartbeat target) must point at `runtime_listener_port`; the bootstrap script/`$icp_api_url` (login + `createOrgSecret`) must point at `server_port`.** Sending heartbeats to `server_port` gets a plain HTTP 405 - confirmed against a real instance.

    **Option A - mint it yourself** (requires `curl`/`jq`; see the script header - `createOrgSecret` is **not** idempotent, so run it only once per environment/integration and keep the printed value safe):
    ```bash
    ICP_PASSWORD=<icp-admin-password> ./modules/micro_integrator/files/create-icp-org-secret.sh \
      --icp-url https://<icp-host>:9446 \
      --username admin \
      --environment-id <environment-id>
    ```
    Set `$icp_enabled = true`, `$icp_secret = '<value printed above>'`, and `$icp_url = 'https://<icp-host>:9445'` (plus `$icp_environment`/`$icp_project`/`$icp_integration` as needed) in `modules/micro_integrator/manifests/params.pp` (or override via Hiera), then re-run the agent with `FACTER_profile=micro_integrator`.

    **Option B - let Puppet mint it** by setting `$icp_enabled = true`, `$icp_secret_bootstrap = true`, `$icp_api_url` (server_port, e.g. `https://<icp-host>:9446`), `$icp_url` (runtime_listener_port, e.g. `https://<icp-host>:9445`), `$icp_admin_username`/`$icp_admin_password`, and `$icp_environment_id` in `modules/micro_integrator/manifests/params.pp`. On the **first** agent run it copies `create-icp-org-secret.sh` to the node, runs it once against `$icp_api_url`, and caches the result at `/etc/wso2/icp-org-secret` (the `icp_org_secret` fact then reports it back). Because facts are gathered before the catalog compiles, `deployment.toml` only picks up the secret starting from the **second** agent run onward - run the agent twice:
    ```bash
    export FACTER_profile=micro_integrator
    sudo -E puppet agent -vt   # mints the secret
    sudo -E puppet agent -vt   # wires it into deployment.toml
    ```

## For production deployments
* Change Java distribution in site.pp file according to your requirement. [Refer](https://forge.puppet.com/modules/puppetlabs/java/readme)
* Add any configuration changes required to `/modules/micro_integrator/templates/mi-home/conf/deployment.toml.erb` (or the equivalent `integration_control_plane` template) and use puppet config management to manage them. ( Facter, Hiera, etc. )
* You can add any custom code to `/modules/micro_integrator/custom.pp`.
