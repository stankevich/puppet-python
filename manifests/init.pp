# @summary Installs and manages python, python-dev, python-virtualenv and gunicorn.
#
# @param ensure Desired installation state for the Python package.
# @param version Python version to install. Beware that valid values for this differ a) by the provider you choose and b) by the osfamily/operatingsystem you are using.
#  Allowed values:
#   - provider == pip: everything pip allows as a version after the 'python=='
#   - else: 'system', 'pypy', 3/3.3/...
#      - Be aware that 'system' usually means python 2.X.
#      - 'pypy' actually lets us use pypy as python.
#      - 3/3.3/... means you are going to install the python3/python3.3/...
#        package, if available on your osfamily.
# @param pip Desired installation state for the python-pip package.
# @param dev Desired installation state for the python-dev package.
# @param virtualenv Desired installation state for the virtualenv package
# @param venv Desired installation state for the virtualenv package
# @param gunicorn Desired installation state for Gunicorn.
# @param manage_gunicorn Allow Installation / Removal of Gunicorn.
# @param provider What provider to use for installation of the packages, except gunicorn and Python itself.
# @param use_epel to determine if the epel class is used.
# @param manage_scl Whether to manage core SCL packages or not.
# @param umask The default umask for invoked exec calls.
# @param manage_gunicorn manage the state for package gunicorn
# @param manage_python_package manage the state for package python
# @param manage_virtualenv_package manage the state for package virtualenv
# @param manage_venv_package manage the state for package venv
# @param manage_pip_package manage the state for package pip
#
# @example install python from system python
#   class { 'python':
#     version    => 'system',
#     pip        => 'present',
#     dev        => 'present',
#     virtualenv => 'present',
#     gunicorn   => 'present',
#   }
# @example install python3 from scl repo
#   class { 'python' :
#     ensure      => 'present',
#     version     => 'rh-python36-python',
#     dev         => 'present',
#     virtualenv  => 'present',
#   }
#
class python (
  Python::Package::Ensure    $ensure                      = $python::params::ensure,
  Python::Version            $version                     = $python::params::version,
  Python::Package::Ensure    $pip                         = $python::params::pip,
  Python::Package::Ensure    $dev                         = $python::params::dev,
  Python::Package::Ensure    $virtualenv                  = $python::params::virtualenv,
  Python::Package::Ensure    $venv                        = $python::params::venv,
  Python::Package::Ensure    $gunicorn                    = $python::params::gunicorn,
  Boolean                    $manage_gunicorn             = $python::params::manage_gunicorn,
  Boolean                    $manage_python_package       = $python::params::manage_python_package,
  Boolean                    $manage_virtualenv_package   = $python::params::manage_virtualenv_package,
  Boolean                    $manage_venv_package         = $python::params::manage_venv_package,
  Boolean                    $manage_pip_package          = $python::params::manage_pip_package,
  String[1]                  $gunicorn_package_name       = $python::params::gunicorn_package_name,
  Optional[Python::Provider] $provider                    = $python::params::provider,
  Hash                       $python_pips                 = {},
  Hash                       $python_virtualenvs          = {},
  Hash                       $python_pyvenvs              = {},
  Hash                       $python_requirements         = {},
  Hash                       $python_dotfiles             = {},
  Boolean                    $use_epel                    = $python::params::use_epel,
  Boolean                    $rhscl_use_public_repository = $python::params::rhscl_use_public_repository,
  Stdlib::Httpurl            $anaconda_installer_url      = $python::params::anaconda_installer_url,
  Stdlib::Absolutepath       $anaconda_install_path       = $python::params::anaconda_install_path,
  Boolean                    $manage_scl                  = $python::params::manage_scl,
  Optional[Python::Umask]    $umask                       = undef,
) inherits python::params {
  $exec_prefix = $provider ? {
    'scl'   => "/usr/bin/scl enable ${version} -- ",
    'rhscl' => "/usr/bin/scl enable ${version} -- ",
    default => '',
  }

  contain python::install
  contain python::config

  Class['python::install']
  -> Class['python::config']

  # Set default umask.
  exec { default:
    umask => $umask,
  }

  # Allow hiera configuration of python resources
  create_resources('python::pip', $python_pips)
  create_resources('python::pyvenv', $python_pyvenvs)
  create_resources('python::virtualenv', $python_virtualenvs)
  create_resources('python::requirements', $python_requirements)
  create_resources('python::dotfile', $python_dotfiles)
}
