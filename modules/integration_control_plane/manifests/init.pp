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

class integration_control_plane (
  String  $user               = $integration_control_plane::params::user,
  String  $user_group         = $integration_control_plane::params::user_group,
  Integer $user_id            = $integration_control_plane::params::user_id,
  Integer $user_group_id      = $integration_control_plane::params::user_group_id,
  String  $products_dir       = $integration_control_plane::params::products_dir,
  String  $product            = $integration_control_plane::params::product,
  String  $product_version    = $integration_control_plane::params::product_version,
) inherits integration_control_plane::params {

  # derived paths
  $distribution_path        = "${products_dir}/${product}/${product_version}"
  $install_path             = "${distribution_path}/${product}-${product_version}"
  $product_binary           = "${product}-${product_version}.zip"
  $start_script_template    = $integration_control_plane::params::start_script_template
  $deployment_toml_template = $integration_control_plane::params::deployment_toml_template
  $service_name             = $product

  # 1· account
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

  # 2· dirs
  file { [
    $products_dir,
    "${products_dir}/${product}",
    $distribution_path,
    "${distribution_path}/backup",
  ]:
    ensure  => directory,
    owner   => $user,
    group   => $user_group,
    recurse => true,
    require => [ User[$user], Group[$user_group] ],
  }

  # 3· binary
  file { 'binary':
    path   => "${distribution_path}/${product_binary}",
    owner  => $user,
    group  => $user_group,
    mode   => '0644',
    source => "puppet:///modules/${module_name}/${product_binary}",
  }

  # 4· stop & backup (identical logic)
  exec { 'stop-icp':
    command     => "kill -TERM $(cat ${install_path}/runtime.pid)",
    onlyif      => "test -f ${install_path}/runtime.pid",
    path        => '/bin',
    subscribe   => File['binary'],
    refreshonly => true,
  }
  exec { 'wait-stop':
    command     => 'sleep 20',
    onlyif      => "test -d ${install_path}",
    path        => '/bin',
    subscribe   => Exec['stop-icp'],
    refreshonly => true,
  }
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
    subscribe   => Exec['wait-stop'],
    refreshonly => true,
  }

  # 5· unzip
  package { 'unzip': ensure => installed }
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

  # 6· templates
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

  file { "${install_path}/logs":
    ensure  => directory,
    owner   => $user,
    group   => $user_group,
    mode    => '0755',
    require => File[$install_path],
  }

  # 7· systemd unit + service
  file { "/etc/systemd/system/${service_name}.service":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0754',
    content => template("${module_name}/${service_name}.service.erb"),
    notify  => Exec['daemon-reload'],
  }
  exec { 'daemon-reload':
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
  }
}
