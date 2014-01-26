define haproxy::server(
  $address,
  $options = 'check'
) {
  $target = regsubst($name, '/.*', '')
  $nick   = regsubst($name, '[^/]+/', '')
  
  concat::fragment{"haproxy server ${name}":
    target  => '/etc/haproxy/haproxy.cfg',
    order   => "${target}_01",
    require => Concat::Fragment["haproxy listen ${target}"],
    content => "    server ${nick} ${address} ${options}\n",
  }
}
