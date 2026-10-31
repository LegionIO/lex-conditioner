# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/conditioner/runners/consent_tiers'

RSpec.describe Legion::Extensions::Conditioner::Runners::ConsentTiers do
  let(:runner) do
    stub_const('Legion::Extensions::Conditioner::Runners::ConsentTiersHarness', Class.new do
      include Legion::Extensions::Conditioner::Runners::ConsentTiers

      def task_update(**); end
    end).new
  end
  let(:conditions) { { all: [{ fact: 'role', operator: 'equal', value: 'admin' }] } }

  it 'grants a requested configured tier only for passing facts' do
    Legion::Settings.loader.settings[:extensions][:conditioner][:consent_tiers] = %w[read write]
    expect(runner.evaluate(conditions: conditions, role: 'admin', tier: 'write')).to include(success: true, valid: true, tier: 'write')
    expect(runner.evaluate(conditions: conditions, role: 'guest', tier: 'write')).to include(success: false, valid: false, tier: nil)
  end

  it 'uses the lowest configured tier when a requested tier is unavailable' do
    Legion::Settings.loader.settings[:extensions][:conditioner][:consent_tiers] = %w[read write]
    expect(runner.evaluate(conditions: conditions, role: 'admin', tier: 'root')).to include(tier: 'read')
  end

  it 'fails closed for an invalid tier policy' do
    Legion::Settings.loader.settings[:extensions][:conditioner][:consent_tiers] = []
    expect(runner.evaluate(conditions: conditions, role: 'admin', task_id: 9)).to include(success: false, status: 'conditioner.exception')
  end
end
