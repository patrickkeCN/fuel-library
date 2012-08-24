# these parameters need to be accessed from several locations and
# should be considered to be constant
class galera::params {

  $mysql_user     = "wsrep_sst"
  $mysql_password = "password"

  case $::osfamily {
    'RedHat': {
      $pkg_provider         = 'rpm'
      $libssl_package       = 'openssl098e'
      $mysql_client_package = 'mysql'
      $mysql_version        = '5.1/5.1.62-23.4'
      $mysql_server_package = 'MySQL-server-wsrep-5.1.62_23.4-1.rhel5.x86_64.rpm'
      $galera_package       = 'galera-23.2.1-1.rhel5.x86_64.rpm'
    }
    'Debian': {
      $pkg_provider         = 'dpkg'
      $libssl_package       = 'libssl0.9.8'
      $mysql_client_package = 'mysql-client'
      $mysql_version        = '5.5/5.5.23-23.6'
      $mysql_server_package = 'mysql-server-wsrep-5.5.23-23.6-amd64.deb'
      $galera_package       = 'galera-23.2.1-amd64.deb'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }

}
