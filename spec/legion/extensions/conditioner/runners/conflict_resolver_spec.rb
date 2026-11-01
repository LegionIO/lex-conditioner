# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/conditioner/runners/conflict_resolver'

RSpec.describe Legion::Extensions::Conditioner::Runners::ConflictResolver do
  let(:runner) do
    stub_const('Legion::Extensions::Conditioner::Runners::ConflictResolverHarness', Class.new do
      include Legion::Extensions::Conditioner::Runners::ConflictResolver

      def task_update(**); end
    end).new
  end
  let(:primary) { { all: [{ fact: 'score', operator: 'greater_than', value: 50 }] } }
  let(:secondary) { { all: [{ fact: 'score', operator: 'greater_than', value: 20 }] } }

  it 'prefers primary when both alternatives match' do
    expect(runner.resolve(conditions: primary, competing_conditions: secondary, score: 80)).to include(success: true, resolution: 'primary')
  end

  it 'selects a matching secondary after primary rejection' do
    expect(runner.resolve(conditions: primary, competing_conditions: secondary, score: 30)).to include(success: true, valid: true, resolution: 'secondary')
  end

  it 'returns a failed outcome when neither alternative matches' do
    expect(runner.resolve(conditions: primary, competing_conditions: secondary, score: 10)).to include(success: false, valid: false, resolution: 'none')
  end

  it 'applies configured outcome labels without using labels as decisions' do
    Legion::Settings[:extensions][:conditioner][:resolutions] = { primary: 'preferred', secondary: 'alternate', none: 'rejected' }
    expect(runner.resolve(conditions: primary, score: 80)).to include(valid: true, resolution: 'preferred')
    expect(runner.resolve(conditions: primary, score: 10)).to include(valid: false, resolution: 'rejected')
  end

  it 'rejects malformed competing rules even if primary matches' do
    expect(runner.resolve(conditions: primary, competing_conditions: {}, score: 80, task_id: 8)).to include(success: false, status: 'conditioner.exception')
  end
end
