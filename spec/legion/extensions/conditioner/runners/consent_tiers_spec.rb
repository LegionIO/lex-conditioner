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

require 'legion/extensions/conditioner/runners/consent_tiers'

RSpec.describe Legion::Extensions::Conditioner::Runners::ConsentTiers do
  let(:runner) do
    klass = Class.new do
      include Legion::Extensions::Conditioner::Runners::ConsentTiers

      def task_update(*); end
    end
    klass.new
  end

  def conditions_for(hash)
    Legion::JSON.dump(hash)
  end

  describe '#evaluate' do
    context 'when condition passes and a valid tier is provided' do
      let(:payload) do
        {
          conditions: conditions_for(all: [{ fact: 'role', operator: 'equal', value: 'admin' }]),
          role:       'admin',
          tier:       'tier2'
        }
      end

      it 'returns success: true with valid: true' do
        result = runner.evaluate(**payload)
        expect(result).to include(success: true, valid: true)
      end

      it 'returns the requested tier' do
        result = runner.evaluate(**payload)
        expect(result[:tier]).to eq('tier2')
      end

      it 'calls task_update with task.queued when task_id is present' do
        expect(runner).to receive(:task_update).with(1, 'task.queued', anything)
        runner.evaluate(**payload, task_id: 1)
      end
    end

    context 'when condition passes but tier is nil' do
      let(:payload) do
        {
          conditions: conditions_for(all: [{ fact: 'role', operator: 'equal', value: 'admin' }]),
          role:       'admin'
        }
      end

      it 'returns the first TIERS entry as the granted tier' do
        result = runner.evaluate(**payload)
        expect(result[:tier]).to eq(Legion::Extensions::Conditioner::Runners::ConsentTiers::TIERS.first)
      end

      it 'returns valid: true' do
        result = runner.evaluate(**payload)
        expect(result).to include(valid: true)
      end
    end

    context 'when condition passes but tier is not in TIERS' do
      let(:payload) do
        {
          conditions: conditions_for(all: [{ fact: 'role', operator: 'equal', value: 'admin' }]),
          role:       'admin',
          tier:       'tier99'
        }
      end

      it 'falls back to the first TIERS entry' do
        result = runner.evaluate(**payload)
        expect(result[:tier]).to eq(Legion::Extensions::Conditioner::Runners::ConsentTiers::TIERS.first)
      end
    end

    context 'when condition fails' do
      let(:payload) do
        {
          conditions: conditions_for(all: [{ fact: 'role', operator: 'equal', value: 'admin' }]),
          role:       'guest',
          tier:       'tier1'
        }
      end

      it 'returns valid: false' do
        result = runner.evaluate(**payload)
        expect(result).to include(valid: false)
      end

      it 'returns nil tier' do
        result = runner.evaluate(**payload)
        expect(result[:tier]).to be_nil
      end

      it 'calls task_update with conditioner.failed when task_id is present' do
        expect(runner).to receive(:task_update).with(3, 'conditioner.failed', anything)
        runner.evaluate(**payload, task_id: 3)
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
        runner.evaluate(**payload)
      end
    end

    context 'when an exception is raised during evaluation' do
      it 'logs via log.log_exception and calls task_update with conditioner.exception' do
        allow(Legion::Extensions::Conditioner::Condition).to receive(:new).and_raise(StandardError, 'boom')
        logger = double('Legion::Logging::Methods')
        allow(runner).to receive(:log).and_return(logger)
        expect(logger).to receive(:log_exception).with(instance_of(StandardError), component_type: :runner)
        expect(runner).to receive(:task_update).with(9, 'conditioner.exception', anything)
        runner.evaluate(conditions: '{}', task_id: 9)
      end
    end
  end
end
