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

class integration_control_plane inherits integration_control_plane::params {
  # 1. Create group and user
  group { $user_group:
    ensure => present,
    gid    => $user_group_id,
    system => true,
  }
  user { $user:
    ensure  => present,
    uid     => $user_id,
    gid     => $user_group_id,
    home    => "/home/${user}",
    system  => true,
    require => Group[$user_group],
  }

  # 2. Ensure directories exist & owned correctly
  file { [
    $products_dir,
    "${products_dir}/${product}",
    $distribution_path,
    "${distribution_path}/backup"
  ]:
    ensure  => directory,
    owner   => $user,
    group   => $user_group,
    recurse => true,
    require => [ User[$user], Group[$user_group] ],
  }

  # 3. Copy the ICP ZIP binary into place
  file { 'binary':
    path   => "${distribution_path}/${product_binary}",
    owner  => $user,
    group  => $user_group,
    mode   => '0644',
    source => "puppet:///modules/${module_name}/${product_binary}",
  }

  # 4. Gracefully stop any running ICP instance
  exec { 'stop-icp':
    command     => "kill -TERM $(cat ${install_path}/runtime.pid)",
    onlyif      => "test -f ${install_path}/runtime.pid",
    path        => '/bin',
    subscribe   => File['binary'],
    refreshonly => true,
  }
  exec { 'wait-for-stop':
    command     => 'sleep 20',
    onlyif      => "test -d ${install_path}",
    path        => '/bin',
    subscribe   => File['binary'],
    refreshonly => true,
  }

  # 5. Backup & remove any prior installation
  exec { 'delete-backup':
    command     => "rm -rf ${distribution_path}/backup/${product}-${product_version}",
    onlyif      => "test -d ${distribution_path}/backup/${product}-${product_version}",
    path        => '/bin',
    subscribe   => File['binary'],
    refreshonly => true,
  }
  exec { 'create-backup':
    command     => "mv ${install_path} ${distribution_path}/backup",
    onlyif      => "test -d ${install_path}",
    path        => '/bin',
    subscribe   => File['binary'],
    refreshonly => true,
  }

  # 6. Install unzip if needed and unpack
  package { 'unzip':
    ensure => installed,
  }
  exec { 'unzip-icp':
    command     => "unzip -qo ${product_binary}",
    cwd         => $distribution_path,
    onlyif      => "test ! -d ${install_path}",
    path        => '/usr/bin',
    subscribe   => File['binary'],
    refreshonly => true,
    require     => Package['unzip'],
  }

  file { $install_path:
    ensure  => directory,
    recurse => true,
    owner   => $user,
    group   => $user_group,
    require => Exec['unzip-icp'],
  }

  # 7. Deploy your startup script & deployment.toml
  file { "${install_path}/${start_script_template}":
    ensure  => file,
    owner   => $user,
    group   => $user_group,
    mode    => '0754',
    content => template("${module_name}/icp-home/${start_script_template}.erb"),
  }
  file { "${install_path}/${deployment_toml_template}":
    ensure  => file,
    owner   => $user,
    group   => $user_group,
    mode    => '0644',
    content => template("${module_name}/icp-home/${deployment_toml_template}.erb"),
  }

  # 8. Place the systemd unit and reload daemon
  file { "/etc/systemd/system/${service_name}.service":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0754',
    content => template("${module_name}/${service_name}.service.erb"),
    notify  => Exec['systemd-daemon-reload'],
  }
  exec { 'systemd-daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    path        => '/bin:/usr/bin',
    refreshonly => true,
  }

  # 9. Ensure the ICP service is enabled and running
  service { $service_name:
    ensure    => running,
    enable    => true,
    provider  => 'systemd',
    subscribe => [
      File["/etc/systemd/system/${service_name}.service"],
      File["${install_path}/${start_script_template}"],
      File["${install_path}/${deployment_toml_template}"],
    ],
  }
}
