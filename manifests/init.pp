class haproxy(
  $version = installed,
  $settings = {},
  $defaults = {}
) {
  include concat::setup
  
  $default_settings = {
    'log'                      => '127.0.0.1 local2',
    'stats socket'             => '/var/lib/haproxy/stats'
  }
  $default_defaults = {
    'balance'                  => 'roundrobin',
    'log'                      => 'global',
    'option dontlognull'       => true,
    'option http-server-close' => true,
    'retries'                  => 3,
    'timeout check'            => '10s',
    'timeout client'           => '10s',
    'timeout connect'          => '10s',
    'timeout http-keep-alive'  => '10s',
    'timeout http-request'     => '10s',
    'timeout queue'            => '1m',
    'timeout server'           => '1m',
  }
  
  package{'haproxy':
    ensure => $version,
  }
  file{'/etc/haproxy':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0755',
  }
  $merged_settings = merge($default_settings, $settings)
  $merged_defaults = merge($default_defaults, $defaults)
  
  concat{'/etc/haproxy/haproxy.cfg':
    notify => Exec['check haproxy.cfg'],
  }
  concat::fragment{'haproxy.cfg':
    order   => '00',
    target  => '/etc/haproxy/haproxy.cfg',
    content => template('haproxy/haproxy.cfg.erb'),
  }
  # This protects against an invalid config change restarting
  # the haproxy service.
  exec{'check haproxy.cfg':
    refreshonly => true,
    command => 'haproxy -c -f /etc/haproxy/haproxy.cfg',
    logoutput => on_failure,
  } ~>
  service{'haproxy':
    ensure  => running,
    enable  => true,
    require => Package['haproxy'],
  }
}
