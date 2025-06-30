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

# Class: integration_control_plane
# Init class for Integration Control Plane (ICP) 1.1.0
class integration_control_plane
  inherits integration_control_plane::params
{

  ## (The micro_integrator module manages /usr/local/wso2 and its top-level dirs.)

  # Copy ICP ZIP
  file { 'binary':
    ensure => file,
    path   => "${distribution_path}/${product_binary}",
    source => "puppet:///modules/integration_control_plane/${product_binary}",
    owner  => $user,
    group  => $user_group,
    mode   => '0644',
  }

  # Ensure unzip is installed
  package { 'unzip':
    ensure => installed,
  }

  # Unzip into versioned dir
  exec { 'unzip-icp':
    command     => "unzip -qo ${distribution_path}/${product_binary}",
    cwd         => $distribution_path,
    creates     => $install_path,
    require     => Package['unzip'],
    subscribe   => File['binary'],
    refreshonly => true,
    path        => ['/usr/bin','/bin'],
  }

  # Ensure bin & conf subdirs
  file { "${install_path}/bin":
    ensure  => directory,
    owner   => $user,
    group   => $user_group,
    require => Exec['unzip-icp'],
  }
  file { "${install_path}/conf":
    ensure  => directory,
    owner   => $user,
    group   => $user_group,
    require => Exec['unzip-icp'],
  }

  # Copy dashboard.sh
  file { 'start-script':
    ensure  => file,
    path    => "${install_path}/${start_script_template}",
    content => template('integration_control_plane/icp-home/bin/dashboard.sh.erb'),
    owner   => $user,
    group   => $user_group,
    mode    => '0755',
    require => File["${install_path}/bin"],
  }

  # Copy deployment.toml
  file { 'deployment-config':
    ensure  => file,
    path    => "${install_path}/${deployment_toml_template}",
    content => template('integration_control_plane/icp-home/conf/deployment.toml.erb'),
    owner   => $user,
    group   => $user_group,
    mode    => '0644',
    require => File["${install_path}/conf"],
  }

  # Systemd unit
  file { "/etc/systemd/system/${service_name}.service":
    ensure  => file,
    content => template('integration_control_plane/icp.service.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service[$service_name],
  }
  service { $service_name:
    ensure    => running,
    enable    => true,
    subscribe => File["/etc/systemd/system/${service_name}.service"],
  }
}
