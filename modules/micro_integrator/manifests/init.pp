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

# micro_integrator — installs WSO2 Micro Integrator bits & systemd unit
class micro_integrator (
  String  $user               = $micro_integrator::params::user,
  String  $user_group         = $micro_integrator::params::user_group,
  Integer $user_id            = $micro_integrator::params::user_id,
  Integer $user_group_id      = $micro_integrator::params::user_group_id,
  String  $products_dir       = $micro_integrator::params::products_dir,
  String  $product            = $micro_integrator::params::product,
  String  $product_version    = $micro_integrator::params::product_version,
  Boolean $manage_user        = true,
  Boolean $manage_group       = true,
) inherits micro_integrator::params {

  # Derived paths
  $distribution_path        = "${products_dir}/${product}/${product_version}"
  $install_path             = "${distribution_path}/${product}-${product_version}"
  $product_binary           = "${product}-${product_version}.zip"
  $start_script_template    = $micro_integrator::params::start_script_template
  $deployment_toml_template = $micro_integrator::params::deployment_toml_template
  $service_name             = $product

  # Effective ICP org secret: prefer the value bootstrapped locally (once the
  # icp_org_secret fact picks it up - see lib/facter/icp_org_secret.rb and
  # step 5.1 below), otherwise fall back to the statically configured
  # $icp_secret (e.g. from Hiera, minted by hand with files/create-icp-org-secret.sh).
  if $icp_secret_bootstrap and $facts['icp_org_secret'] and $facts['icp_org_secret'] != '' {
    $resolved_icp_secret = $facts['icp_org_secret']
  } else {
    $resolved_icp_secret = $icp_secret
  }

  # 1. Service account --------------------------------------------------------
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

  # 2. Directory skeleton -----------------------------------------------------
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

  # 3. Stage ZIP --------------------------------------------------------------
  file { 'binary':
    path   => "${distribution_path}/${product_binary}",
    owner  => $user,
    group  => $user_group,
    mode   => '0644',
    source => "puppet:///modules/${module_name}/${product_binary}",
  }

  # 4. Graceful stop & backup -------------------------------------------------
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

  # 5. Unzip ------------------------------------------------------------------
  package { 'unzip': ensure => installed }

  exec { 'unzip-update':
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
    require => Exec['unzip-update'],
  }

  # 5.1 ICP org-secret bootstrap (optional) ------------------------------------
  # Mints the secret exactly once per node: the exec's `creates` guard means
  # it never re-runs (and never rotates the secret) once icp_secret_file
  # exists. A failed script run does not leave a partial file behind, so
  # Puppet retries it on the next run.
  if $icp_secret_bootstrap {
    if $icp_component_id == '' {
      $component_id_arg = ''
    } else {
      $component_id_arg = "--component-id ${icp_component_id}"
    }

    if $icp_ssl_verify {
      $icp_bootstrap_insecure_arg = ''
    } else {
      $icp_bootstrap_insecure_arg = '--insecure'
    }

    file { '/etc/wso2':
      ensure => directory,
      mode   => '0700',
    }

    file { '/opt/wso2-puppet-scripts':
      ensure => directory,
      mode   => '0755',
    }

    file { '/opt/wso2-puppet-scripts/create-icp-org-secret.sh':
      ensure  => file,
      mode    => '0700',
      source  => "puppet:///modules/${module_name}/create-icp-org-secret.sh",
      require => File['/opt/wso2-puppet-scripts'],
    }

    exec { 'create-icp-org-secret':
      command     => "/opt/wso2-puppet-scripts/create-icp-org-secret.sh --icp-url ${icp_api_url} --username ${icp_admin_username} --environment-id ${icp_environment_id} ${component_id_arg} ${icp_bootstrap_insecure_arg} > ${icp_secret_file}.tmp && mv ${icp_secret_file}.tmp ${icp_secret_file}",
      environment => ["ICP_PASSWORD=${icp_admin_password}"],
      creates     => $icp_secret_file,
      path        => '/usr/bin:/bin',
      require     => [ File['/opt/wso2-puppet-scripts/create-icp-org-secret.sh'], File['/etc/wso2'] ],
    }

    file { $icp_secret_file:
      ensure  => file,
      mode    => '0600',
      owner   => $user,
      group   => $user_group,
      require => Exec['create-icp-org-secret'],
    }
  }

  # 6. Templates --------------------------------------------------------------
  file { "${install_path}/${start_script_template}":
    ensure  => file,
    owner   => $user,
    group   => $user_group,
    mode    => '0754',
    content => template("${module_name}/mi-home/${start_script_template}.erb"),
    require => File[$install_path],
  }

  file { "${install_path}/${deployment_toml_template}":
    ensure  => file,
    owner   => $user,
    group   => $user_group,
    mode    => '0644',
    content => template("${module_name}/mi-home/${deployment_toml_template}.erb"),
    require => File[$install_path],
  }

  # 7. systemd unit -----------------------------------------------------------
  file { "/etc/systemd/system/${service_name}.service":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0754',
    content => template("${module_name}/${service_name}.service.erb"),
  }
}
