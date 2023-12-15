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

# Class micro_integrator::params
# This class includes all the necessary parameters.
class micro_integrator::params {

  $user = 'wso2carbon'
  $user_group = 'wso2'
  $user_id = 902
  $user_group_id = 902

  $product = 'wso2mi'
  $product_version = '4.1.0'
  $service_name = "${product}"

  # Define the template
  $start_script_template = "bin/micro-integrator.sh"
  $deployment_toml_template = "conf/deployment.toml"

  # Directories
  $products_dir = "/usr/local/wso2"
  $java_home = "/usr"

  # Product and installation information
  $product_binary = "${product}-${product_version}.zip"
  $distribution_path = "${products_dir}/${product}/${product_version}"
  $install_path = "${distribution_path}/${product}-${product_version}"

  # ---- Configuration parameters for deployment.toml ---- #
  $hostname = 'localhost'
  $ports_offset = 0

  $keystore_location = '${carbon.home}/repository/resources/security/wso2carbon.jks'
  $keystore_password = 'wso2carbon'
  $keystore_key_alias = 'wso2carbon'
  $keystore_key_password = 'wso2carbon'

  $trust_store_location = '${carbon.home}/repository/resources/security/client-truststore.jks'
  $strust_store_password = 'wso2carbon'
  $trust_store_alias = 'symmetric.key.value'
  $trust_algorithm = 'JKS'
}
