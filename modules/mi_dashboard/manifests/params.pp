#----------------------------------------------------------------------------
#  Copyright (c) 2024, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

# Class mi_dashboard::params
# This class includes all the necessary parameters.
class mi_dashboard::params {

  $user = 'wso2carbon'
  $user_group = 'wso2'
  $user_id = 802
  $user_group_id = 802

  $product = 'wso2mi-dashboard'
  $product_version = '4.2.0'
  $service_name = "${product}"

  # Define the template
  $start_script_template = "bin/dashboard.sh"
  $deployment_toml_template = "conf/deployment.toml"

  # Directories
  $products_dir = "/usr/local/wso2"
  $java_home = "/usr"

  # Product and installation information
  $product_binary = "${product}-${product_version}.zip"
  $distribution_path = "${products_dir}/${product}/${product_version}"
  $install_path = "${distribution_path}/${product}-${product_version}"

  # ---- Configuration parameters for deployment.toml ---- #
  $server_config_port = 9743
  
  $heartbeat_config_pool_size = 15

  $mi_user_store_username = 'admin'
  $mi_user_store_password = 'admin'
  
  $keystore_file_name = 'conf/security/dashboard.jks'
  $keystore_password = 'wso2carbon'
  $keystore_key_password = 'wso2carbon'
}
