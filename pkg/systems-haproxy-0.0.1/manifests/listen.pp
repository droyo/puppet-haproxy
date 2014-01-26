define haproxy::listen(
  $address,
  $mode     = 'http',
  $servers  = [],
  $options  = {}
) {
  $default_options_tcp = {}
  $default_options_http = {
    'option http-server-close' => true,
    'option httplog'           => true,
    'option forwardfor'        => 'except 127.0.0.0/8',
  }
  $merged_options = $mode ? {
    'tcp'   => merge($default_options_tcp, $options),
    'http'  => merge($default_options_http, $options),
  }
  concat::fragment{"haproxy listen ${name}":
    order => "${name}_00",
    target => "/etc/haproxy/haproxy.cfg",
    content => template('haproxy/listen.cfg.erb'),
  }
}
