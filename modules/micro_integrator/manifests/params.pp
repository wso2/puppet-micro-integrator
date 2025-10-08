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
  $product_version = '4.5.0'
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
}
