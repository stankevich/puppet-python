#
# @summary Creates Python virtualenv.
#
# @param ensure
# @param version Python version to use.
# @param requirements Path to pip requirements.txt file
# @param systempkgs Copy system site-packages into virtualenv.
# @param venv_dir  Directory to install virtualenv to
# @param ensure_venv_dir Create $venv_dir
# @param distribute
#   Include distribute in the virtualenv
#   Forced to `false` for Ubuntu 18.04 and 20.04
#   Forced to `false` for RedHat based systems
# @param index Base URL of Python package index
# @param owner The owner of the virtualenv being manipulated
# @param group  The group relating to the virtualenv being manipulated
# @param mode  Optionally specify directory mode
# @param proxy Proxy server to use for outbound connections
# @param environment Additional environment variables required to install the packages
# @param path  Specifies the PATH variable
# @param cwd The directory from which to run the "pip install" command
# @param timeout  The maximum time in seconds the "pip install" command should take
# @param pip_args  Arguments to pass to pip during initialization
# @param extra_pip_args Extra arguments to pass to pip after requirements file
#
# @example install a virtual env at /var/www/project1
#  python::virtualenv { '/var/www/project1':
#    ensure       => present,
#    version      => 'system',
#    requirements => '/var/www/project1/requirements.txt',
#    proxy        => 'http://proxy.domain.com:3128',
#    systempkgs   => true,
#    index        => 'http://www.example.com/simple/',
#  }
#
define python::virtualenv (
  Python::Package::Ensure               $ensure          = 'present',
  Python::Version                       $version         = 'system',
  Variant[Boolean,Stdlib::Absolutepath] $requirements    = false,
  Boolean                               $systempkgs      = false,
  Stdlib::Absolutepath                  $venv_dir        = $name,
  Boolean                               $ensure_venv_dir = true,
  Boolean                               $distribute      = true,
  Variant[Boolean,Stdlib::HTTPUrl]      $index           = false,
  String[1]                             $owner           = 'root',
  String[1]                             $group           = 'root',
  Stdlib::Filemode                      $mode            = '0755',
  Optional[Stdlib::HTTPUrl]             $proxy           = undef,
  Array                                 $environment     = [],
  Array[Stdlib::Absolutepath]           $path            = ['/bin', '/usr/bin', '/usr/sbin', '/usr/local/bin',],
  Optional[Stdlib::Absolutepath]        $cwd             = undef,
  Integer                               $timeout         = 1800,
  String                                $pip_args        = '',
  String                                $extra_pip_args  = '',
  Optional[String[1]]                   $virtualenv      = undef,
) {
  include python

  $python_provider = getparam(Class['python'], 'provider')
  $anaconda_path   = getparam(Class['python'], 'anaconda_install_path')

  if $ensure == 'present' {
    $python = $version ? {
      'system' => 'python',
      'pypy'   => 'pypy',
      default  => "python${version}",
    }

    $_path = $python_provider ? {
      'anaconda' => concat(["${anaconda_path}/bin"], $path),
      default    => $path,
    }

    if $virtualenv == undef {
      $used_virtualenv = 'virtualenv'
    } else {
      $used_virtualenv = $virtualenv
    }

    $proxy_flag = $proxy ? {
      false    => '',
      default  => "--proxy=${proxy}",
    }

    $proxy_hash = $proxy ? {
      undef   => {},
      default => $facts['os']['family'] ? {
        'AIX'   => {
          'http_proxy'  => $proxy,
          'https_proxy' => $proxy,
        },
        default => {
          'HTTP_PROXY'  => $proxy,
          'HTTPS_PROXY' => $proxy,
        },
      }
    }

    $system_pkgs_flag = $systempkgs ? {
      true    => '--system-site-packages',
      default => '',
    }

    # Installing distribute does not work on these operating systems
    if $facts.dig('os','distro','codename') in ['focal', 'bionic', 'buster'] {
      $distribute_pkg = 'setuptools'
    } elsif $facts['os']['family'] == 'RedHat' {
      $distribute_pkg = 'setuptools'
    } else {
      $distribute_pkg = $distribute ? {
        true     => 'distribute',
        default  => 'setuptools',
      }
    }

    $pypi_index = $index ? {
      false   => '',
      default => "-i ${index}",
    }

    # Python 2.6 and older does not support setuptools/distribute > 0.8 which
    # is required for pip wheel support, pip therefor requires --no-use-wheel flag
    # if the # pip version is more recent than 1.4.1 but using an old python or
    # setuputils/distribute version
    # To check for this we test for wheel parameter using help and then using
    # version, this makes sure we only use wheels if they are supported

    if $ensure_venv_dir {
      file { $venv_dir:
        ensure => directory,
        owner  => $owner,
        group  => $group,
        mode   => $mode,
      }
    }

    $virtualenv_cmd = "${python::exec_prefix}${used_virtualenv}"
    $pip_cmd        = "${python::exec_prefix}${venv_dir}/bin/pip"
    $pip_flags      = "${pypi_index} ${proxy_flag} ${pip_args}"

    exec { "python_virtualenv_${venv_dir}":
      command     => "${virtualenv_cmd} ${system_pkgs_flag} -p ${python} ${venv_dir} && ${pip_cmd} --log ${venv_dir}/pip.log install ${pip_flags} --upgrade pip && ${pip_cmd} install ${pip_flags} --upgrade ${distribute_pkg}",
      user        => $owner,
      creates     => "${venv_dir}/bin/activate",
      path        => $_path,
      cwd         => '/tmp',
      environment => (Hash($environment.map |$val| { $val.split(/=|$/) }) + $proxy_hash).map|$key, $val| { "${key}=${val}" },
      unless      => "grep '^[\\t ]*VIRTUAL_ENV=[\\\\'\\\"]*${venv_dir}[\\\"\\\\'][\\t ]*$' ${venv_dir}/bin/activate", #Unless activate exists and VIRTUAL_ENV is correct we re-create the virtualenv
      require     => File[$venv_dir],
    }

    if $requirements {
      exec { "python_requirements_initial_install_${requirements}_${venv_dir}":
        command     => "${pip_cmd} --log ${venv_dir}/pip.log install ${pypi_index} ${proxy_flag} --no-binary :all: -r ${requirements} ${extra_pip_args}",
        refreshonly => true,
        timeout     => $timeout,
        user        => $owner,
        subscribe   => Exec["python_virtualenv_${venv_dir}"],
        environment => $environment,
        cwd         => $cwd,
      }

      python::requirements { "${requirements}_${venv_dir}":
        requirements   => $requirements,
        virtualenv     => $venv_dir,
        proxy          => $proxy,
        owner          => $owner,
        group          => $group,
        cwd            => $cwd,
        require        => Exec["python_virtualenv_${venv_dir}"],
        extra_pip_args => $extra_pip_args,
      }
    }
  } elsif $ensure == 'absent' {
    file { $venv_dir:
      ensure  => absent,
      force   => true,
      recurse => true,
      purge   => true,
    }
  }
}
