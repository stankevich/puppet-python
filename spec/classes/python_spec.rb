require 'spec_helper'

describe 'python', type: :class do
  on_supported_os.each do |os, facts|
    next if os == 'gentoo-3-x86_64'
    context "on #{os}" do
      let :facts do
        facts
      end

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('python::install') }
        it { is_expected.to contain_class('python::params') }
        it { is_expected.to contain_class('python::config') }
        it { is_expected.to contain_package('python') }
        it { is_expected.to contain_package('virtualenv') }
        it { is_expected.to contain_package('pip') }
        it { is_expected.to contain_package('python-venv') }
      end

      context 'without managing things' do
        let :params do
          {
            manage_python_package: false,
            manage_virtualenv_package: false,
            manage_pip_package: false,
            manage_venv_package: false
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_package('python') }
        it { is_expected.not_to contain_package('virtualenv') }
        it { is_expected.not_to contain_package('pip') }
        it { is_expected.not_to contain_package('python-venv') }
      end

      context 'with packages present' do
        let :params do
          {
            manage_virtualenv_package: true,
            manage_pip_package: true,
            manage_venv_package: true,
            pip: 'present',
            virtualenv: 'present',
            venv: 'present'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('virtualenv').with(ensure: 'present') }
        it { is_expected.to contain_package('pip').with(ensure: 'present') }
        it { is_expected.to contain_package('python-venv').with(ensure: 'present') }
      end

      case facts[:os]['family']
      when 'Debian'

        # tests were written for Debian 6
        context 'on Debian OS' do
          it { is_expected.to contain_class('python::install') }
          # Base debian packages.
          it { is_expected.to contain_package('python') }
          it { is_expected.to contain_package('python-dev') }
          it { is_expected.to contain_package('pip') }
          # Basic python packages (from pip)
          it { is_expected.to contain_package('virtualenv') }

          describe 'with python::version' do
            context 'python3.7' do
              let(:params) { { version: 'python3.7' } }

              it { is_expected.to compile.with_all_deps }
              it { is_expected.to contain_package('pip').with_name('python3.7-pip') }
              it { is_expected.to contain_package('python').with_name('python3.7') }
              it { is_expected.to contain_package('python-dev').with_name('python3.7-dev') }
              it { is_expected.to contain_package('virtualenv').with_name('virtualenv') }
            end
          end

          describe 'with python::dev' do
            context 'true' do
              let(:params) { { dev: 'present' } }

              it { is_expected.to compile.with_all_deps }
              it { is_expected.to contain_package('python-dev').with_ensure('present') }
            end
            context 'empty/default' do
              it { is_expected.to compile.with_all_deps }
              it { is_expected.to contain_package('python-dev').with_ensure('absent') }
            end
          end

          describe 'with python::virtualenv, without python::dev' do
            context 'true' do
              let(:params) { { dev: 'absent', virtualenv: 'present' } }

              it { is_expected.to contain_package('python-dev').with_ensure('present') }
            end
            context 'empty/default' do
              it { is_expected.to contain_package('python-dev').with_ensure('absent') }
            end
          end

          describe 'with python::python_virtualenvs' do
            context 'when `proxy` set' do
              let(:params) do
                {
                  python_virtualenvs: {
                    '/opt/env1' => {
                      proxy: 'http://example.com:3128'
                    }
                  }
                }
              end

              it { is_expected.to contain_exec('python_virtualenv_/opt/env1').with_environment(['HTTP_PROXY=http://example.com:3128', 'HTTPS_PROXY=http://example.com:3128']) }
            end
            context 'when `proxy` and `environment` have conflicting parameters' do
              let(:params) do
                {
                  python_virtualenvs: {
                    '/opt/env1' => {
                      proxy: 'http://example.com:3128',
                      environment: ['HTTP_PROXY=http://example.com:8080']
                    }
                  }
                }
              end

              it { is_expected.to contain_exec('python_virtualenv_/opt/env1').with_environment(['HTTP_PROXY=http://example.com:3128', 'HTTPS_PROXY=http://example.com:3128']) }
            end
          end

          describe 'with python::python_pyvenvs' do
            context 'with two pyenvs' do
              let(:params) do
                {
                  python_pyvenvs: {
                    '/opt/env1' => {
                      version: '3.8'
                    },
                    '/opt/env2' => {
                      version: '3.8'
                    }
                  }
                }
              end

              it { is_expected.to compile }

              it { is_expected.to contain_python__pyvenv('/opt/env1').with_ensure('present') }
              it { is_expected.to contain_python__pyvenv('/opt/env2').with_ensure('present') }
            end
          end

          describe 'with manage_gunicorn' do
            context 'true' do
              let(:params) { { manage_gunicorn: true } }

              it { is_expected.to contain_package('gunicorn') }
            end
            context 'empty args' do
              # let(:params) {{ :manage_gunicorn => '' }}
              it { is_expected.to contain_package('gunicorn') }
            end
            context 'false' do
              let(:params) { { manage_gunicorn: false } }

              it { is_expected.not_to contain_package('gunicorn') }
            end
          end

          describe 'with python::provider' do
            context 'pip' do
              let(:params) { { pip: 'present', provider: 'pip' } }

              it {
                is_expected.to contain_package('virtualenv').with(
                  'provider' => 'pip'
                )
              }
              it {
                is_expected.to contain_package('pip').with(
                  'provider' => 'pip'
                )
              }
            end

            # python::provider
            context 'default' do
              let(:params) { { provider: '' } }

              it { is_expected.to contain_package('virtualenv') }
              it { is_expected.to contain_package('pip') }

              describe 'with python::virtualenv' do
                context 'true' do
                  let(:params) { { provider: '', virtualenv: 'present' } }

                  it { is_expected.to contain_package('virtualenv').with_ensure('present') }
                end
              end

              describe 'without python::virtualenv' do
                context 'default/empty' do
                  let(:params) { { provider: '' } }

                  it { is_expected.to contain_package('virtualenv').with_ensure('absent') }
                end
              end
            end
          end

          describe 'with python::dev' do
            context 'true' do
              let(:params) { { dev: 'present' } }

              it { is_expected.to contain_package('python-dev').with_ensure('present') }
            end
            context 'default/empty' do
              it { is_expected.to contain_package('python-dev').with_ensure('absent') }
            end
          end

          describe 'EPEL does not exist for Debian' do
            context 'default/empty' do
              it { is_expected.not_to contain_class('epel') }
            end
          end
        end
      when 'RedHat'
        case facts[:os]['name']
        when 'Fedora'

          # written for Fedora 22
          context 'on a Fedora OS' do
            describe 'EPEL does not exist for Fedora' do
              context 'default/empty' do
                it { is_expected.not_to contain_class('epel') }
              end
            end
          end
        when 'RedHat', 'CentOS'
          case facts[:os]['release']['major']
          when '7'

            context 'on a Redhat 7 OS' do
              it { is_expected.to contain_class('python::install') }
              it { is_expected.to contain_package('pip').with_name('python2-pip') }

              describe 'with python::version' do
                context 'python36' do
                  let(:params) { { version: 'python36' } }

                  it { is_expected.to compile.with_all_deps }
                  it { is_expected.to contain_package('pip').with_name('python36-pip') }
                  it { is_expected.to contain_package('python').with_name('python36') }
                  it { is_expected.to contain_package('python-dev').with_name('python36-devel') }
                  it { is_expected.to contain_package('virtualenv').with_name('python36-virtualenv') }
                end
              end
              describe 'with python::provider' do
                context 'scl' do
                  describe 'with version' do
                    context '3.6 SCL meta package' do
                      let(:params) { { version: 'rh-python36' } }

                      it { is_expected.to compile.with_all_deps }
                    end
                    context '3.6 SCL python package' do
                      let(:params) { { version: 'rh-python36-python' } }

                      it { is_expected.to compile.with_all_deps }
                    end
                  end
                  describe 'with manage_scl' do
                    context 'true' do
                      let(:params) { { provider: 'scl', manage_scl: true } }

                      it { is_expected.to contain_package('centos-release-scl') }
                      it { is_expected.to contain_package('scl-utils') }
                    end
                    context 'false' do
                      let(:params) { { provider: 'scl', manage_scl: false } }

                      it { is_expected.not_to contain_package('centos-release-scl') }
                      it { is_expected.not_to contain_package('scl-utils') }
                    end
                  end
                end
              end
            end
          end
        end
      when 'Suse'
        # written for SLES 11 SP3

        context 'on a SLES 11 SP3' do
          it { is_expected.to contain_class('python::install') }
          # Base Suse packages.
          it { is_expected.to contain_package('python') }
          it { is_expected.to contain_package('python-dev').with_name('python-devel') }
          it { is_expected.to contain_package('python-dev').with_alias('python-devel') }
          it { is_expected.to contain_package('pip') }
          # Basic python packages (from pip)
          it { is_expected.to contain_package('virtualenv') }

          describe 'with python::dev' do
            context 'true' do
              let(:params) { { dev: 'present' } }

              it { is_expected.to contain_package('python-dev').with_ensure('present') }
            end
            context 'empty/default' do
              it { is_expected.to contain_package('python-dev').with_ensure('absent') }
            end
          end

          describe 'with manage_gunicorn' do
            context 'true' do
              let(:params) { { manage_gunicorn: true } }

              it { is_expected.to contain_package('gunicorn') }
            end
            context 'empty args' do
              # let(:params) {{ :manage_gunicorn => '' }}
              it { is_expected.to contain_package('gunicorn') }
            end
            context 'false' do
              let(:params) { { manage_gunicorn: false } }

              it { is_expected.not_to contain_package('gunicorn') }
            end
          end

          describe 'with python::provider' do
            context 'pip' do
              let(:params) { { provider: 'pip' } }

              it {
                is_expected.to contain_package('virtualenv').with(
                  'provider' => 'pip'
                )
              }
              it {
                is_expected.to contain_package('pip').with(
                  'provider' => 'pip'
                )
              }
            end

            # python::provider
            context 'default' do
              let(:params) { { provider: '' } }

              it { is_expected.to contain_package('virtualenv') }
              it { is_expected.to contain_package('pip') }

              describe 'with python::virtualenv' do
                context 'true' do
                  let(:params) { { provider: '', virtualenv: 'present' } }

                  it { is_expected.to contain_package('virtualenv').with_ensure('present') }
                end
              end

              describe 'with python::virtualenv' do
                context 'default/empty' do
                  let(:params) { { provider: '' } }

                  it { is_expected.to contain_package('virtualenv').with_ensure('absent') }
                end
              end
            end
          end

          describe 'with python::dev' do
            context 'true' do
              let(:params) { { dev: 'present' } }

              it { is_expected.to contain_package('python-dev').with_ensure('present') }
            end
            context 'default/empty' do
              it { is_expected.to contain_package('python-dev').with_ensure('absent') }
            end
          end

          describe 'EPEL does not exist on Suse' do
            context 'default/empty' do
              it { is_expected.not_to contain_class('epel') }
            end
          end
        end
      when 'Gentoo'

        context 'on a Gentoo OS' do
          it { is_expected.to contain_class('python::install') }
          # Base debian packages.
          it { is_expected.to contain_package('python') }
          it { is_expected.to contain_package('pip').with('category' => 'dev-python') }
          # Basic python packages (from pip)
          it { is_expected.to contain_package('virtualenv') }
          # Python::Dev
          it { is_expected.not_to contain_package('python-dev') }

          describe 'with manage_gunicorn' do
            context 'true' do
              let(:params) { { manage_gunicorn: true } }

              it { is_expected.to contain_package('gunicorn') }
            end
            context 'empty args' do
              # let(:params) {{ :manage_gunicorn => '' }}
              it { is_expected.to contain_package('gunicorn') }
            end
            context 'false' do
              let(:params) { { manage_gunicorn: false } }

              it { is_expected.not_to contain_package('gunicorn') }
            end
          end

          describe 'with python::provider' do
            context 'pip' do
              let(:params) { { pip: 'present', provider: 'pip' } }

              it {
                is_expected.to contain_package('virtualenv').with(
                  'provider' => 'pip'
                )
              }
              it {
                is_expected.to contain_package('pip').with(
                  'provider' => 'pip'
                )
              }
            end

            # python::provider
            context 'default' do
              let(:params) { { provider: '' } }

              it { is_expected.to contain_package('virtualenv') }
              it { is_expected.to contain_package('pip') }

              describe 'with python::virtualenv' do
                context 'true' do
                  let(:params) { { provider: '', virtualenv: 'present' } }

                  it { is_expected.to contain_package('virtualenv').with_ensure('present') }
                end
              end

              describe 'with python::virtualenv' do
                context 'default/empty' do
                  let(:params) { { provider: '' } }

                  it { is_expected.to contain_package('virtualenv').with_ensure('absent') }
                end
              end
            end
          end
        end
      end
    end
  end
end
