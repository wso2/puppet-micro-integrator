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
# Class: micro_integrator
class micro_integrator (
  String  $user               = 'wso2carbon',
  String  $user_group         = 'wso2',
  Integer $user_id            = 802,
  Integer $user_group_id      = 802,
  String  $products_dir       = '/usr/local/wso2',
  String  $product            = 'wso2mi',
  String  $product_version    = '4.4.0',
  Boolean $manage_user        = true,
  Boolean $manage_group       = true,
) inherits micro_integrator::params {

  $module_name            = 'micro_integrator'
  $distribution_path      = "${products_dir}/${product}/${product_version}"
  $install_path           = "${distribution_path}/${product}-${product_version}"
  $product_binary         = "${product}-${product_version}.zip"
  $start_script_template  = 'micro-integrator.sh'
  $deployment_toml_template = 'deployment.toml'
  $service_name           = 'wso2mi'

  # ---------------------------------------------------------------------------
  # 1. Service account
  # ---------------------------------------------------------------------------
  if $manage_group {
    group { $user_group:
      ensure => present,
      gid    => $user_group_id,
      system => true,
    }
  }

  if $manage_user {
    user { $user:
      ensure  => present,
      uid     => $user_id,
      gid     => $user_group_id,
      home    => "/home/${user}",
      system  => true,
      require => Group[$user_group],
    }
  }

  # ---------------------------------------------------------------------------
  # 2. Directory structure & ownership
  # ---------------------------------------------------------------------------
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

  # ---------------------------------------------------------------------------
  # 3. Staging the product archive
  # ---------------------------------------------------------------------------
  file { 'binary':
    path   => "${distribution_path}/${product_binary}",
    owner  => $user,
    group  => $user_group,
    mode   => '0644',
    source => "puppet:///modules/${module_name}/${product_binary}",
  }

  # ---------------------------------------------------------------------------
  # 4. Graceful stop & backup of any existing instance
  # ---------------------------------------------------------------------------
  exec { 'stop-server':
    command     => "kill -TERM $(cat ${install_path}/wso2carbon.pid)",
    onlyif      => "test -f ${install_path}/wso2carbon.pid",
    path        => '/bin',
    subscribe   => File['binary'],
    refreshonly => true,
  }

  exec { 'wait-for-stop':
    command     => 'sleep 20',
    onlyif      => "test -d ${install_path}",
    path        => '/bin',
    subscribe   => Exec['stop-server'],
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
    subscribe   => Exec['wait-for-stop'],
    refreshonly => true,
  }

  # ---------------------------------------------------------------------------
  # 5. Unzip the new distribution
  # ---------------------------------------------------------------------------
  package { 'unzip':
    ensure => installed,
  }

  exec { 'unzip-update':
    command     => "unzip -qo ${product_binary}",
    cwd         => $distribution_path,
    onlyif      => "test ! -d ${install_path}",
    path        => '/usr/bin',
    subscribe   => File['binary'],
    refreshonly => true,
    require     => Package['unzip'],
  }

  # Ensure extracted dir ownership (recursive to catch child files)
  file { $install_path:
    ensure  => directory,
    recurse => true,
    owner   => $user,
    group   => $user_group,
    require => Exec['unzip-update'],
  }

  # ---------------------------------------------------------------------------
  # 6. Deploy config & startup script templates
  # ---------------------------------------------------------------------------
  file { "${install_path}/${start_script_template}":
    ensure  => file,
    owner   => $user,
    group   => $user_group,
    mode    => '0754',
    content => template("${module_name}/mi-home/${start_script_template}.erb"),
  }

  file { "${install_path}/${deployment_toml_template}":
    ensure  => file,
    owner   => $user,
    group   => $user_group,
    mode    => '0644',
    content => template("${module_name}/mi-home/${deployment_toml_template}.erb"),
  }

  # ---------------------------------------------------------------------------
  # 7. systemd unit + service management
  # ---------------------------------------------------------------------------
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

  service { $service_name:
    ensure    => running,
    enable    => true,
    provider  => 'systemd',
    require   => Exec['systemd-daemon-reload'],
    subscribe => [
      File["/etc/systemd/system/${service_name}.service"],
      File["${install_path}/${start_script_template}"],
      File["${install_path}/${deployment_toml_template}"],
      Exec['unzip-update'],
    ],
  }
}
