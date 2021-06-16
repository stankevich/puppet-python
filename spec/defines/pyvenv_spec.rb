require 'spec_helper'

describe 'python::pyvenv', type: :define do
  on_supported_os.each do |os, facts|
    next if os == 'gentoo-3-x86_64'
    context "on #{os}" do
      let :facts do
        # python3 is required to use pyvenv
        facts.merge(
          python3_version: '3.5.1'
        )
      end
      let :title do
        '/opt/env'
      end

      context 'with default parameters' do
        it { is_expected.to contain_file('/opt/env') }
        it { is_expected.to contain_exec('python_virtualenv_/opt/env').with_command('pyvenv-3.5 --clear  /opt/env && /opt/env/bin/pip --log /opt/env/pip.log install --upgrade pip && /opt/env/bin/pip --log /opt/env/pip.log install --upgrade setuptools') }

        if %w[xenial cosmic disco stretch].include?(facts[:lsbdistcodename])
          it { is_expected.to contain_package('python3.5-venv').that_comes_before('File[/opt/env]') }
        end

        if %w[bionic buster].include?(facts[:lsbdistcodename])
          it { is_expected.to contain_package('python3-venv').that_comes_before('File[/opt/env]') }
        end
      end

      describe 'when ensure' do
        context 'is absent' do
          let :params do
            {
              ensure: 'absent'
            }
          end

          it {
            is_expected.to contain_file('/opt/env').with_ensure('absent').with_purge(true)
          }
        end
      end
    end # context
  end
end
