#----------------------------------------------------------------------------
#  Copyright (c) 2019 WSO2, Inc. http://www.wso2.org
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#----------------------------------------------------------------------------

class common::params {

  # ----- Master-datasources config params -----
  $carbon_db_url = 'jdbc:h2:./repository/database/WSO2CARBON_DB;DB_CLOSE_ON_EXIT=FALSE;LOCK_TIMEOUT=60000'
  $carbon_db_username = 'wso2carbon'
  $carbon_db_password = 'wso2carbon'
  $carbon_db_driver = 'org.h2.Driver'

  $wso2am_db_url = 'jdbc:h2:repository/database/WSO2AM_DB;DB_CLOSE_ON_EXIT=FALSE'
  $wso2am_db_username = 'wso2carbon'
  $wso2am_db_password = 'wso2carbon'
  $wso2am_db_driver = 'org.h2.Driver'

  $stat_db_url = 'jdbc:h2:../tmpStatDB/WSO2AM_STATS_DB;DB_CLOSE_ON_EXIT=FALSE;LOCK_TIMEOUT=60000;AUTO_SERVER=TRUE'
  $stat_db_username = 'wso2carbon'
  $stat_db_password = 'wso2carbon'
  $stat_db_driver = 'org.h2.Driver'

  $mb_store_db_url = 'jdbc:h2:repository/database/WSO2MB_DB;DB_CLOSE_ON_EXIT=FALSE;LOCK_TIMEOUT=60000'
  $mb_store_db_username = 'wso2carbon'
  $mb_store_db_password = 'wso2carbon'
  $mb_store_driver = 'org.h2.Driver'


  # ----- user-mgt.xml config params -----
  $admin_username = 'admin'
  $admin_password = 'admin'
}
