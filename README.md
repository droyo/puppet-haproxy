Module `haproxy` installs and configures [HAProxy][0], a software
load balancer.  The `haproxy` class manages installation and global
configuration, and the `haproxy::backend` define can be used to
specify haproxy ports and their respective backends.

# Usage

The base `haproxy` class manages the HAProxy service and default
configuration. The `haproxy::listen` defined type can be used to
create HAProxy endpoints and destination. It may be used in two
ways: as a self-contained service description, or as a target for
haproxy::server resources. The latter method can be used with 
exported resources.

Here is a simple example that balances HTTP requests across two
known IP addresses.

	node load_bal01 {
	  include haproxy

	  haproxy::listen{'www':
	    address => '*:80',
	    servers => [
	      'apache01 172.16.34.21:80 check',
	      'apache02 172.16.34.22:80 check',
	    ],
	  }
	}

Here is a more complex example that uses a custom HTTP request to
check server health, and uses exported resources to coordinate
services. Note how both methods of describing backends can be used
interchangably. It is the user's responsibility not to define a
backend server twice.

	node loadbal01 {
	  class{'haproxy':
	    settings => {'log'     => 'syslog01.example.com local2'
	                 'maxconn' => 5000 },
	    defaults => {'timeout http-request' => '5s'},
	  }
	  haproxy::listen{'www':
	    address => '*:80',
	    options => { httpchk => 'HEAD /healthcheck.php' }
	  }
	  
	  haproxy::listen{'rabbitmq':
	    mode => tcp,
	    address => '*:5672',
	    options => { balance => leastconn },
	    servers => [
	      'p2-rmq01   10.29.3.14:5672 check maxconn 200',
	      'p2-rmq02   10.29.3.14:5672 check maxconn 200',
	      'sca1-rmq01 10.72.42.14:5672 backup',
	    ],
	    Haproxy::Server<<|tag == 'loadbal01'|>>
	  }
	}
	class web_server($lb_name) {
	  include apache
	  @@haproxy::server{"www/${::hostname}":
	    tag     => $lb_name,
	    address => "${::ipaddress}:80",
	    options => 'slowstart 500',
	  }
	}
	node apache01 {
	  class{'web_server':
	    lb_name => 'p2-loadbal01',
	  }
	}
	node apache02 {
	  class{'web_server':
	    lb_name => 'p2-loadbal01',
	  }
	}

Check the [haproxy documentation][2] for the full list of available
options. The base `haproxy` class manages the `global` and `default`
stanzas of `haproxy.cfg`, and the `haproxy::listen` resource manages
`listen` stanzas.

# Notes

- HAProxy has an enormous amount of options. Read the [manual][2]
  thoroughly to implement optimal load balancing for your service.
- This module currently does not support `backend` or `frontend`
  stanzas. The `listen` stanza is a superset of these, but there is
  no technical reason a `haproxy::backend` and `haproxy::frontend`
  define cannot be added.

HAProxy is useful when testing load-balancing in multi-VM vagrant
setups; in production, we tend to use an F5 pool for load balancing.
Traditionally, `haproxy` is combined with a tool like [keepalived][1]
to share the virtual IP between multiple load balancers.

[0]: http://haproxy.1wt.eu/
[1]: http://www.keepalived.org/
[2]: http://cbonte.github.io/haproxy-dconv/configuration-1.4.html
