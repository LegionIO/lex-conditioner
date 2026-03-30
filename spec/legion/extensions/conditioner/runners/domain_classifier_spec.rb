# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/conditioner/helpers/comparator'
require 'legion/extensions/conditioner/helpers/condition'

module Legion
  module Extensions
    module Helpers
      module Task; end unless defined?(Legion::Extensions::Helpers::Task)
    end
  end
end

require 'legion/extensions/conditioner/runners/domain_classifier'

RSpec.describe Legion::Extensions::Conditioner::Runners::DomainClassifier do
  let(:runner) do
    klass = Class.new do
      include Legion::Extensions::Conditioner::Runners::DomainClassifier

      def task_update(*); end
    end
    klass.new
  end

  def conditions_for(hash)
    Legion::JSON.dump(hash)
  end

  describe '#classify' do
    context 'when condition passes and domain is provided' do
      let(:payload) do
        {
          conditions: conditions_for(all: [{ fact: 'status', operator: 'equal', value: 200 }]),
          status:     200,
          domain:     'billing'
        }
      end

      it 'returns success: true with valid: true' do
        result = runner.classify(**payload)
        expect(result).to include(success: true, valid: true)
      end

      it 'returns the domain as classification' do
        result = runner.classify(**payload)
        expect(result[:domain]).to eq('billing')
      end

      it 'calls task_update with task.queued when task_id is present' do
        expect(runner).to receive(:task_update).with(1, 'task.queued', anything)
        runner.classify(**payload, task_id: 1)
      end
    end

    context 'when condition passes and domain is nil' do
      let(:payload) do
        {
          conditions: conditions_for(all: [{ fact: 'status', operator: 'equal', value: 200 }]),
          status:     200
        }
      end

      it 'returns classification as default' do
        result = runner.classify(**payload)
        expect(result[:domain]).to eq('default')
      end

      it 'returns valid: true' do
        result = runner.classify(**payload)
        expect(result).to include(valid: true)
      end
    end

    context 'when condition fails' do
      let(:payload) do
        {
          conditions: conditions_for(all: [{ fact: 'status', operator: 'equal', value: 404 }]),
          status:     200,
          domain:     'billing'
        }
      end

      it 'returns valid: false' do
        result = runner.classify(**payload)
        expect(result).to include(valid: false)
      end

      it 'returns classification as unclassified' do
        result = runner.classify(**payload)
        expect(result[:domain]).to eq('unclassified')
      end

      it 'calls task_update with conditioner.failed when task_id is present' do
        expect(runner).to receive(:task_update).with(7, 'conditioner.failed', anything)
        runner.classify(**payload, task_id: 7)
      end
    end

    context 'when condition fails and domain is nil' do
      let(:payload) do
        {
          conditions: conditions_for(all: [{ fact: 'status', operator: 'equal', value: 404 }]),
          status:     200
        }
      end

      it 'returns classification as unclassified' do
        result = runner.classify(**payload)
        expect(result[:domain]).to eq('unclassified')
      end
    end

    context 'when task_id is nil' do
      let(:payload) do
        {
          conditions: conditions_for(all: [{ fact: 'x', operator: 'equal', value: 1 }]),
          x:          1
        }
      end

      it 'does not call task_update' do
        expect(runner).not_to receive(:task_update)
        runner.classify(**payload)
      end
    end

    context 'when an exception is raised during evaluation' do
      it 'logs via log.log_exception and calls task_update with conditioner.exception' do
        allow(Legion::Extensions::Conditioner::Condition).to receive(:new).and_raise(StandardError, 'boom')
        logger = double('Legion::Logging::Methods')
        allow(runner).to receive(:log).and_return(logger)
        expect(logger).to receive(:log_exception).with(instance_of(StandardError), component_type: :runner)
        expect(runner).to receive(:task_update).with(5, 'conditioner.exception', anything)
        runner.classify(conditions: '{}', task_id: 5)
      end
    end
  end
end
