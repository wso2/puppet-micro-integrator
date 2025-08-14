#----------------------------------------------------------------------------
#  Copyright (c) 2025, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

# Class micro_integrator::startserver
# Starts the server as a service in the final stage.
class micro_integrator::startserver inherits micro_integrator::params {

  # Derived paths (needed for service subscriptions)
  $distribution_path = "${products_dir}/${product}/${product_version}"
  $install_path      = "${distribution_path}/${product}-${product_version}"

  exec { 'systemd-daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    path        => '/bin:/usr/bin',
    refreshonly => true,
  }

  service { $service_name:
    ensure    => running,
    enable    => true,
    provider  => 'systemd',
    subscribe => [
      File["/etc/systemd/system/${service_name}.service"],
      File["${install_path}/${start_script_template}"],
      File["${install_path}/${deployment_toml_template}"],
    ],
    require   => Exec['systemd-daemon-reload'],
  }
}
