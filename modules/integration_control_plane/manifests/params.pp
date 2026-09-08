#----------------------------------------------------------------------------
# Copyright (c) 2024, WSO2 LLC.
# All Rights Reserved.
#
# WSO2 LLC. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.
#----------------------------------------------------------------------------
class integration_control_plane::params (
  # Signs ICP's frontend session/auth JWTs. No default on purpose: every
  # deployment must supply its own value (e.g. via Hiera key
  # integration_control_plane::params::frontend_jwt_hmac_secret) so
  # installations don't share a signing key baked into this public repo.
  # Puppet fails catalog compilation - before any resource, including
  # integration_control_plane::startserver's service, is applied - if this
  # isn't provided.
  String $frontend_jwt_hmac_secret,
) {

  # Service account
  $user            = 'wso2carbon'
  $user_group      = 'wso2'
  $user_id         = 802
  $user_group_id   = 802

  # Product basics
  $product         = 'wso2-integration-control-plane'
  $product_version = '2.0.0'
  $service_name    = $product        # systemd unit name

  # bin/icp.sh ships inside the distribution ZIP and is only permission-managed
  # by this module (see init.pp) - its content is never overwritten by a
  # Puppet template, since it is the product's own Ballerina launcher script.
  $start_script_template    = 'bin/icp.sh'
  $deployment_toml_template = 'conf/deployment.toml'

  # Directories
  $products_dir  = '/usr/local/wso2'
  $java_home     = '/usr'

  # Derived paths
  $product_binary    = "${product}-${product_version}.zip"
  $distribution_path = "${products_dir}/${product}/${product_version}"
  $install_path      = "${distribution_path}/${product}-${product_version}"

  # ---- conf/deployment.toml defaults (override via Hiera/edit here) ----
  # $server_port serves GraphQL/auth/the web UI. $runtime_listener_port is a
  # SEPARATE listener for runtime heartbeats (the `/icp` service) - a runtime
  # (e.g. Micro Integrator's icp_config.icp_url) must point at this port, not
  # $server_port - confirmed against a real instance, where heartbeats sent
  # to server_port got a plain 405.
  $server_port                = 9446
  $runtime_listener_port      = 9445
  $auth_backend_url           = 'https://localhost:9447'
  $log_level                  = 'INFO'
  $enable_audit_logging       = true
  $enable_metrics             = true
  $scheduler_interval_seconds = 60

  # Database - disabled by default so the server falls back to the embedded
  # H2 store. Set $db_enabled = true and fill in the connection details
  # below for a production (MySQL/PostgreSQL/MSSQL/Oracle) deployment.
  $db_enabled  = false
  $db_type     = 'mysql'
  $db_host     = 'localhost'
  $db_port     = 3306
  $db_name     = 'icp_database'
  $db_user     = 'root'
  $db_password = 'root'
}
