class { 'redis':
  version            => '2.8.12',
}

define redis::instance_conf (
  $redis_port = $redis::params::redis_port,
  $redis_bind_address = $redis::params::redis_bind_address,
  $redis_max_memory = $redis::params::redis_max_memory,
  $redis_max_clients = $redis::params::redis_max_clients,
  $redis_timeout = $redis::params::redis_timeout,
  $redis_loglevel = $redis::params::redis_loglevel,
  $redis_databases = $redis::params::redis_databases,
  $redis_slowlog_log_slower_than = $redis::params::redis_slowlog_log_slower_than,
  $redis_slowlog_max_len = $redis::params::redis_slowlog_max_len,
  $redis_password = $redis::params::redis_password,
  $redis_saves = $redis::params::redis_saves,
  $redis_conf = nil
  ) {

  # Using Exec as a dependency here to avoid dependency cyclying when doing
  # Class['redis'] -> Redis::Instance[$name]
  Exec['install-redis'] -> Redis::Instance[$name]
  include redis

  $real_redis_max_clients = $redis_max_clients

  file { "redis-lib-port-${redis_port}":
    ensure => directory,
    path   => "/var/lib/redis/${redis_port}",
  }

  file { "redis-init-${redis_port}":
    ensure  => present,
    path    => "/etc/init.d/redis_${redis_port}",
    mode    => '0755',
    content => template('redis/redis.init.erb'),
    notify  => Service["redis-${redis_port}"],
  }

  file { "redis_port_${redis_port}.conf":
    ensure  => present,
    path    => "/etc/redis/${redis_port}.conf",
    mode    => '0644',
    content => "${redis_conf}",
  }

  service { "redis-${redis_port}":
    ensure    => running,
    name      => "redis_${redis_port}",
    enable    => true,
    require   => [ File["redis_port_${redis_port}.conf"], File["redis-init-${redis_port}"], File["redis-lib-port-${redis_port}"] ],
    subscribe => File["redis_port_${redis_port}.conf"],
  }
}

#redis::instance { 'redis-6379-master':
#  redis_port         => '6379',
#  redis_conf         => "/vagrant/Redis Configs/master.conf"
#}

redis::instance_conf { 'redis-6380-slave':
  redis_port         => '6380',
  redis_conf         => "/vagrant/Redis Configs/slave.conf"
}

redis::instance_conf { 'redis-6381-secure':
  redis_port         => '6381',
  redis_conf         => "/vagrant/Redis Configs/secure.conf",
}