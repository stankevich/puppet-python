require 'spec_helper'

describe 'python::pip', type: :define do # rubocop:disable RSpec/MultipleDescribes
  let(:title) { 'rpyc' }

  context 'on Debian OS' do
    let :facts do
      {
        id: 'root',
        kernel: 'Linux',
        lsbdistcodename: 'squeeze',
        os: {
          family: 'Debian'
        },
        osfamily: 'Debian',
        operatingsystem: 'Debian',
        operatingsystemrelease: '6',
        path: '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
        concat_basedir: '/dne'
      }
    end

    describe 'virtualenv as' do
      context 'fails with non qualified path' do
        let(:params) { { virtualenv: 'venv' } }

        it { is_expected.to raise_error(%r{"venv" is not an absolute path.}) }
      end
      context 'suceeds with qualified path' do
        let(:params) { { virtualenv: '/opt/venv' } }

        it { is_expected.to contain_exec('pip_install_rpyc').with_cwd('/opt/venv') }
      end
      context 'defaults to system' do
        let(:params) { {} }

        it { is_expected.to contain_exec('pip_install_rpyc').with_cwd('/') }
      end
    end
    
    describe 'pip_provide as' do
      context 'defaults to pip' do
        let(:params) { {} }
        it { is_expected.to contain_exec('pip_install_rpyc').with_command(%r{pip}) }
        it { is_expected.not_to contain_exec('pip_install_rpyc').with_command(%r{pip3}) }
      end
      context 'use pip instead of pip3 when specified' do
        let(:params) { { pip_provider: 'pip' } }
        it { is_expected.to contain_exec('pip_install_rpyc').with_command(%r{pip}) }
        it { is_expected.not_to contain_exec('pip_install_rpyc').with_command(%r{pip3}) }
      end
      context 'use pip3 instead of pip when specified' do
        let(:params) { { pip_provider: 'pip3' } }
        it { is_expected.to contain_exec('pip_install_rpyc').with_command(%r{pip3}) }
      end
    end

    describe 'proxy as' do
      context 'defaults to empty' do
        let(:params) { {} }

        it { is_expected.not_to contain_exec('pip_install_rpyc').with_command(%r{--proxy}) }
      end
      context 'does not add proxy to search command if set to latest and proxy is unset' do
        let(:params) { { ensure: 'latest' } }

        it { is_expected.not_to contain_exec('pip_install_rpyc').with_command(%r{--proxy}) }
        it { is_expected.to contain_exec('pip_install_rpyc').without_unless(%r{--proxy}) }
      end
      context 'adds proxy to install command if proxy set' do
        let(:params) { { proxy: 'http://my.proxy:3128' } }

        it { is_expected.to contain_exec('pip_install_rpyc').with_command("pip wheel --help > /dev/null 2>&1 && { pip show wheel > /dev/null 2>&1 || wheel_support_flag='--no-binary :all:'; } ; { pip --log /tmp/pip.log install $wheel_support_flag  --proxy=http://my.proxy:3128   rpyc || pip --log /tmp/pip.log install  --proxy=http://my.proxy:3128   rpyc ;}") }
      end
      context 'adds proxy to search command if set to latest' do
        let(:params) { { proxy: 'http://my.proxy:3128', ensure: 'latest' } }

        it { is_expected.to contain_exec('pip_install_rpyc').with_command("pip wheel --help > /dev/null 2>&1 && { pip show wheel > /dev/null 2>&1 || wheel_support_flag='--no-binary :all:'; } ; { pip --log /tmp/pip.log install --upgrade $wheel_support_flag  --proxy=http://my.proxy:3128   rpyc || pip --log /tmp/pip.log install --upgrade  --proxy=http://my.proxy:3128   rpyc ;}") }
        it { is_expected.to contain_exec('pip_install_rpyc').with_unless('pip search  --proxy=http://my.proxy:3128 rpyc | grep -i INSTALLED.*latest') }
      end
    end

    describe 'index as' do
      context 'defaults to empty' do
        let(:params) { {} }

        it { is_expected.not_to contain_exec('pip_install_rpyc').with_command(%r{--index-url}) }
      end
      context 'adds index to install command if index set' do
        let(:params) { { index: 'http://www.example.com/simple/' } }

        it { is_expected.to contain_exec('pip_install_rpyc').with_command("pip wheel --help > /dev/null 2>&1 && { pip show wheel > /dev/null 2>&1 || wheel_support_flag='--no-binary :all:'; } ; { pip --log /tmp/pip.log install $wheel_support_flag --index-url=http://www.example.com/simple/    rpyc || pip --log /tmp/pip.log install --index-url=http://www.example.com/simple/    rpyc ;}") }
      end
      context 'adds index to search command if set to latest' do
        let(:params) { { index: 'http://www.example.com/simple/', ensure: 'latest' } }

        it { is_expected.to contain_exec('pip_install_rpyc').with_command("pip wheel --help > /dev/null 2>&1 && { pip show wheel > /dev/null 2>&1 || wheel_support_flag='--no-binary :all:'; } ; { pip --log /tmp/pip.log install --upgrade $wheel_support_flag --index-url=http://www.example.com/simple/    rpyc || pip --log /tmp/pip.log install --upgrade --index-url=http://www.example.com/simple/    rpyc ;}") }
      end
    end

    describe 'path as' do
      context 'adds anaconda path to pip invocation if provider is anaconda' do
        let(:params) { {} }
        let(:pre_condition) { 'class {"::python": provider => "anaconda", anaconda_install_path => "/opt/python3"}' }

        it { is_expected.to contain_exec('pip_install_rpyc').with_path(['/opt/python3/bin', '/usr/local/bin', '/usr/bin', '/bin', '/usr/sbin']) }
      end
    end
  end
end

describe 'python::pip', type: :define do
  let(:title) { 'requests' }

  context 'on Debian OS' do
    let :facts do
      {
        id: 'root',
        kernel: 'Linux',
        lsbdistcodename: 'squeeze',
        os: {
          family: 'Debian'
        },
        osfamily: 'Debian',
        operatingsystem: 'Debian',
        operatingsystemrelease: '6',
        path: '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
        concat_basedir: '/dne'
      }
    end

    describe 'extras as' do
      context 'suceeds with no extras' do
        let(:params) { {} }

        it { is_expected.to contain_exec('pip_install_requests').with_command("pip wheel --help > /dev/null 2>&1 && { pip show wheel > /dev/null 2>&1 || wheel_support_flag='--no-binary :all:'; } ; { pip --log /tmp/pip.log install $wheel_support_flag     requests || pip --log /tmp/pip.log install     requests ;}") }
      end
      context 'succeeds with extras' do
        let(:params) { { extras: ['security'] } }

        it { is_expected.to contain_exec('pip_install_requests').with_command("pip wheel --help > /dev/null 2>&1 && { pip show wheel > /dev/null 2>&1 || wheel_support_flag='--no-binary :all:'; } ; { pip --log /tmp/pip.log install $wheel_support_flag     requests[security] || pip --log /tmp/pip.log install     requests[security] ;}") }
      end
    end
  end
end
