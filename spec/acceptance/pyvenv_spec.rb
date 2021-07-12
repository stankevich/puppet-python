require 'spec_helper_acceptance'

describe 'python::pyvenv defined resource with python 3' do
  context 'minimal parameters' do
    # Using puppet_apply as a helper
    it 'works with no errors' do
      pp = <<-PUPPET
      class { 'python':
        version => '3',
        dev     => 'present',
      }
      user { 'agent':
        ensure         => 'present',
        managehome     => true,
        home           => '/opt/agent',
      }
      group { 'agent':
        ensure => 'present',
        system => true,
      }
      python::pyvenv { '/opt/agent/venv':
        ensure      => 'present',
        systempkgs  => true,
        owner       => 'agent',
        group       => 'agent',
        mode        => '0755',
        pip_version => '<= 20.3.4',
      }
      PUPPET

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe command('/opt/agent/venv/bin/pip list') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{agent} }
    end
  end

  context 'with python::pip' do
    it 'works with no errors' do
      pp = <<-PUPPET
      class { 'python':
        version => '3',
        dev     => 'present',
      }
      user { 'agent':
        ensure         => 'present',
        managehome     => true,
        home           => '/opt/agent',
      }
      group { 'agent':
        ensure => 'present',
        system => true,
      }
      python::pyvenv { '/opt/agent/venv':
        ensure      => 'present',
        systempkgs  => true,
        owner       => 'agent',
        group       => 'agent',
        mode        => '0755',
        pip_version => '<= 20.3.4',
      }
      python::pip { 'agent' :
        ensure       => 'latest',
        pkgname      => 'agent',
        pip_provider => 'pip',
        virtualenv   => '/opt/agent/venv',
        owner        => 'agent',
        group        => 'agent',
      }
      PUPPET

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe command('/opt/agent/venv/bin/pip list') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{agent} }
    end
  end

  context 'with minimal python::pip' do
    it 'works with no errors' do
      pp = <<-PUPPET
      class { 'python':
        version => '3',
        dev     => 'present',
      }
      user { 'agent':
        ensure         => 'present',
        managehome     => true,
        home           => '/opt/agent',
      }
      group { 'agent':
        ensure => 'present',
        system => true,
      }
      python::pyvenv { '/opt/agent/venv':
        ensure      => 'present',
        systempkgs  => true,
        owner       => 'agent',
        group       => 'agent',
        mode        => '0755',
        pip_version => '<= 20.3.4',
      }
      python::pip { 'agent' :
        virtualenv => '/opt/agent/venv',
        owner      => 'agent',
        group      => 'agent',
      }
      PUPPET

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe command('/opt/agent/venv/bin/pip list') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{agent} }
    end
  end

  context 'with minimal python::pip and without systempkgs' do
    it 'works with no errors' do
      pp = <<-PUPPET
      class { 'python':
        version => '3',
        dev     => 'present',
      }
      user { 'agent':
        ensure         => 'present',
        managehome     => true,
        home           => '/opt/agent',
      }
      group { 'agent':
        ensure => 'present',
        system => true,
      }
      python::pyvenv { '/opt/agent/venv':
        ensure      => 'present',
        systempkgs  => false,
        owner       => 'agent',
        group       => 'agent',
        mode        => '0755',
        pip_version => '<= 20.3.4',
      }
      python::pip { 'agent' :
        virtualenv => '/opt/agent/venv',
        owner      => 'agent',
        group      => 'agent',
      }
      PUPPET

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe command('/opt/agent/venv/bin/pip list') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{agent} }
    end
  end

  context 'with versioned minimal python::pip and without systempkgs' do
    it 'works with no errors' do
      pp = <<-PUPPET
      class { 'python':
        version => '3',
        dev     => 'present',
      }
      user { 'agent':
        ensure         => 'present',
        managehome     => true,
        home           => '/opt/agent',
      }
      group { 'agent':
        ensure => 'present',
        system => true,
      }
      python::pyvenv { '/opt/agent/venv':
        ensure      => 'present',
        systempkgs  => false,
        owner       => 'agent',
        group       => 'agent',
        mode        => '0755',
        pip_version => '<= 20.3.4',
      }
      python::pip { 'agent' :
        ensure     => '0.1.2',
        virtualenv => '/opt/agent/venv',
        owner      => 'agent',
        group      => 'agent',
      }
      PUPPET

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe command('/opt/agent/venv/bin/pip list') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{agent.* 0\.1\.2} }
    end
  end
end
