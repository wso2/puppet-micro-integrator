#----------------------------------------------------------------------------
#  Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
#
#  WSO2 LLC. licenses this file to you under the Apache License,
#  Version 2.0 (the "License"); you may not use this file except
#  in compliance with the License.
#  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#----------------------------------------------------------------------------

# micro_integrator::params — central defaults
class micro_integrator::params {

  # Service account
  $user            = 'wso2carbon'
  $user_group      = 'wso2'
  $user_id         = 802
  $user_group_id   = 802

  # Product basics
  $product         = 'wso2mi'
  $product_version = '4.6.0'
  $service_name    = $product        # systemd unit name

  # Templates inside the ZIP
  $start_script_template    = 'bin/micro-integrator.sh'
  $deployment_toml_template = 'conf/deployment.toml'

  # Directories
  $products_dir  = '/usr/local/wso2'
  $java_home     = '/usr'

  # Derived paths
  $product_binary    = "${product}-${product_version}.zip"
  $distribution_path = "${products_dir}/${product}/${product_version}"
  $install_path      = "${distribution_path}/${product}-${product_version}"

  # ---- Example TOML defaults (override via Hiera)
  $hostname              = 'localhost'
  $ports_offset          = 10
  $keystore_location     = 'repository/resources/security/wso2carbon.jks'
  $keystore_password     = 'wso2carbon'
  $keystore_alias        = 'wso2carbon'
  $keystore_key_password = 'wso2carbon'
  $truststore_location   = 'repository/resources/security/client-truststore.jks'
  $truststore_password   = 'wso2carbon'
  $truststore_alias      = 'symmetric.key.value'
  $truststore_algorithm  = 'JKS'

  # ---- ICP (Integration Control Plane) connectivity ----
  # Disabled by default. Set $icp_enabled = true and fill in $icp_secret
  # (the org secret issued by ICP for this environment/project/integration)
  # to register this MI node with an Integration Control Plane instance.
  #
  # $icp_url is the value MI itself uses for its heartbeat traffic, and MUST
  # point at ICP's runtimeListenerPort (default 9445 - the `/icp` heartbeat
  # service), NOT ICP's main serverPort (default 9446, GraphQL/auth/web UI).
  # These are two different listeners on the ICP side - confirmed by testing
  # against a real instance, where heartbeats sent to serverPort got a plain
  # 405, and only runtimeListenerPort accepted them. This should match
  # integration_control_plane::params::runtime_listener_port on the ICP host.
  $icp_enabled            = false
  $icp_url                = 'https://localhost:9445'
  $icp_environment        = 'Development'
  $icp_project            = 'default'
  $icp_integration        = 'default'
  $icp_secret             = ''
  $icp_heartbeat_interval = 2
  $icp_ssl_verify         = true

  # ---- Automatic org-secret bootstrap (optional) ----
  # Disabled by default - $icp_secret above is normally minted once by hand
  # (files/create-icp-org-secret.sh) and pasted into Hiera.
  # Set $icp_secret_bootstrap = true to instead have this module mint the
  # secret itself and splice it into deployment.toml, both in the same
  # agent run (see init.pp) - the value is read and written locally on
  # this node only, never exposed via a Facter fact or Puppet's compiled
  # catalog content. $icp_environment_id is the environment's UUID (from
  # ICP's `environments` GraphQL query) - not the same as $icp_environment
  # above, which is the handler string MI itself reports in its heartbeat.
  #
  # $icp_api_url is a SEPARATE address from $icp_url above: createOrgSecret
  # and login are GraphQL/auth calls that live on ICP's main serverPort
  # (default 9446), not the runtimeListenerPort $icp_url points at. Only the
  # bootstrap script/exec uses this one.
  $icp_secret_bootstrap = false
  $icp_api_url          = 'https://localhost:9446'
  $icp_admin_username   = 'admin'
  $icp_admin_password   = 'admin'
  $icp_environment_id   = ''
  $icp_component_id     = ''
  $icp_secret_file      = '/etc/wso2/icp-org-secret'
}
