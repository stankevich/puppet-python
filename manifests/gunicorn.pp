# == Define: python::gunicorn
#
# Manages Gunicorn virtual hosts.
#
# === Parameters
#
# [*ensure*]
#  present|absent. Default: present
#
# [*virtualenv*]
#  Run in virtualenv, specify directory. Default: disabled
#
# [*mode*]
#  Gunicorn mode.
#  wsgi|django. Default: wsgi
#
# [*dir*]
#  Application directory.
#
# [*bind*]
#  Bind on: 'HOST', 'HOST:PORT', 'unix:PATH'.
#  Default: system-wide: unix:/tmp/gunicorn-$name.socket
#           virtualenv:  unix:${virtualenv}/${name}.socket
#
# [*environment*]
#  Set ENVIRONMENT variable. Default: none
#
# === Examples
#
# python::gunicorn { 'vhost':
#   ensure      => present,
#   virtualenv  => '/var/www/project1',
#   mode        => 'wsgi',
#   dir         => '/var/www/project1/current',
#   bind        => 'unix:/tmp/gunicorn.socket',
#   environment => 'prod',
# }
#
# === Authors
#
# Sergey Stankevich
#
define python::gunicorn (
  $ensure        = present,
  $virtualenv    = false,
  $mode          = 'wsgi',
  $dir           = false,
  $bind          = false,
  $app_interface = 'wsgi',
  $environment   = false,
) {

  # Parameter validation
  if ! $dir {
    fail('python::gunicorn: dir parameter must not be empty')
  }

  file { "/etc/gunicorn.d/${name}":
    ensure  => $ensure,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('python/gunicorn.erb'),
  }

}
