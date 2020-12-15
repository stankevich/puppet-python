require 'spec_helper_acceptance'

describe 'python class' do
  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'works with no errors' do
      pp = <<-EOS
      class { 'python': }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end
  end

  context 'installing python 3' do
    # Using puppet_apply as a helper
    it 'works with no errors' do
      pp = <<-EOS
      class { 'python':
        ensure     => 'present',
        version    => '3',
        pip        => 'present',
        dev        => 'present',
        virtualenv => 'present',
        venv       => 'present',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end
    fact_notices = <<-EOS
      notify{"pip_version: ${facts['pip3_version']}":}
      notify{"python_version: ${facts['python3_version']}":}
      EOS
    it 'outputs python facts when not installed' do
      apply_manifest(fact_notices, catch_failures: true) do |r|
        expect(r.stdout).to match(%r{python_version: 3\.\S+})
        expect(r.stdout).to match(%r{pip_version: \S+})
      end
    end
  end
end
