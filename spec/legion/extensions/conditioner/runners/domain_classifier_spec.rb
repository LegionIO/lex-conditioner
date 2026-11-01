# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/conditioner/runners/domain_classifier'

RSpec.describe Legion::Extensions::Conditioner::Runners::DomainClassifier do
  let(:runner) do
    stub_const('Legion::Extensions::Conditioner::Runners::DomainClassifierHarness', Class.new do
      include Legion::Extensions::Conditioner::Runners::DomainClassifier

      def task_update(**); end
    end).new
  end
  let(:conditions) { { all: [{ fact: 'allowed', operator: 'is_true' }] } }

  it 'classifies passing facts under the requested domain' do
    expect(runner.classify(conditions: conditions, allowed: true, domain: 'billing')).to include(success: true, valid: true, domain: 'billing')
  end

  it 'uses configured default and rejection domain labels' do
    settings = Legion::Settings[:extensions][:conditioner]
    settings[:default_domain] = 'general'
    settings[:unclassified_domain] = 'rejected'
    expect(runner.classify(conditions: conditions, allowed: true)).to include(domain: 'general')
    expect(runner.classify(conditions: conditions, allowed: false)).to include(success: false, valid: false, domain: 'rejected')
  end

  it 'returns a failed Hash for malformed conditions' do
    expect(runner.classify(conditions: {}, task_id: 5)).to include(success: false, valid: false, status: 'conditioner.exception')
  end
end
