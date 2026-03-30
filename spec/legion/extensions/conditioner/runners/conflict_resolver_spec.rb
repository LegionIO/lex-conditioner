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

require 'legion/extensions/conditioner/runners/conflict_resolver'

RSpec.describe Legion::Extensions::Conditioner::Runners::ConflictResolver do
  let(:runner) do
    klass = Class.new do
      include Legion::Extensions::Conditioner::Runners::ConflictResolver

      def task_update(*); end
    end
    klass.new
  end

  def conditions_for(hash)
    Legion::JSON.dump(hash)
  end

  describe '#resolve' do
    context 'when no competing_conditions are provided' do
      context 'and primary condition passes' do
        let(:payload) do
          {
            conditions: conditions_for(all: [{ fact: 'score', operator: 'greater_than', value: 50 }]),
            score:      80
          }
        end

        it 'returns resolution: primary' do
          result = runner.resolve(**payload)
          expect(result[:resolution]).to eq('primary')
        end

        it 'returns valid: true' do
          result = runner.resolve(**payload)
          expect(result).to include(valid: true)
        end

        it 'calls task_update with task.queued when task_id is present' do
          expect(runner).to receive(:task_update).with(1, 'task.queued', anything)
          runner.resolve(**payload, task_id: 1)
        end
      end

      context 'and primary condition fails' do
        let(:payload) do
          {
            conditions: conditions_for(all: [{ fact: 'score', operator: 'greater_than', value: 50 }]),
            score:      10
          }
        end

        it 'returns resolution: none' do
          result = runner.resolve(**payload)
          expect(result[:resolution]).to eq('none')
        end

        it 'returns valid: false' do
          result = runner.resolve(**payload)
          expect(result).to include(valid: false)
        end

        it 'calls task_update with conditioner.failed when task_id is present' do
          expect(runner).to receive(:task_update).with(2, 'conditioner.failed', anything)
          runner.resolve(**payload, task_id: 2)
        end
      end
    end

    context 'when competing_conditions are provided' do
      let(:passing_conditions) do
        conditions_for(all: [{ fact: 'score', operator: 'greater_than', value: 50 }])
      end
      let(:failing_conditions) do
        conditions_for(all: [{ fact: 'score', operator: 'less_than', value: 30 }])
      end

      context 'when both primary and secondary pass' do
        let(:payload) do
          {
            conditions:           passing_conditions,
            competing_conditions: passing_conditions,
            score:                80
          }
        end

        it 'returns resolution: primary (primary wins)' do
          result = runner.resolve(**payload)
          expect(result[:resolution]).to eq('primary')
        end

        it 'returns valid: true' do
          result = runner.resolve(**payload)
          expect(result).to include(valid: true)
        end
      end

      context 'when only primary passes' do
        let(:payload) do
          {
            conditions:           passing_conditions,
            competing_conditions: failing_conditions,
            score:                80
          }
        end

        it 'returns resolution: primary' do
          result = runner.resolve(**payload)
          expect(result[:resolution]).to eq('primary')
        end

        it 'returns valid: true' do
          result = runner.resolve(**payload)
          expect(result).to include(valid: true)
        end
      end

      context 'when only secondary passes' do
        let(:payload) do
          {
            conditions:           failing_conditions,
            competing_conditions: passing_conditions,
            score:                80
          }
        end

        it 'returns resolution: secondary' do
          result = runner.resolve(**payload)
          expect(result[:resolution]).to eq('secondary')
        end

        it 'returns valid: true (resolution is not none)' do
          result = runner.resolve(**payload)
          expect(result).to include(valid: true)
        end

        it 'calls task_update with task.queued when task_id is present' do
          expect(runner).to receive(:task_update).with(5, 'task.queued', anything)
          runner.resolve(**payload, task_id: 5)
        end
      end

      context 'when neither passes' do
        let(:payload) do
          {
            conditions:           failing_conditions,
            competing_conditions: failing_conditions,
            score:                80
          }
        end

        it 'returns resolution: none' do
          result = runner.resolve(**payload)
          expect(result[:resolution]).to eq('none')
        end

        it 'returns valid: false' do
          result = runner.resolve(**payload)
          expect(result).to include(valid: false)
        end

        it 'calls task_update with conditioner.failed when task_id is present' do
          expect(runner).to receive(:task_update).with(6, 'conditioner.failed', anything)
          runner.resolve(**payload, task_id: 6)
        end
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
        runner.resolve(**payload)
      end
    end

    context 'when an exception is raised during evaluation' do
      it 'logs via log.log_exception and calls task_update with conditioner.exception' do
        allow(Legion::Extensions::Conditioner::Condition).to receive(:new).and_raise(StandardError, 'boom')
        logger = double('Legion::Logging::Methods')
        allow(runner).to receive(:log).and_return(logger)
        expect(logger).to receive(:log_exception).with(instance_of(StandardError), component_type: :runner)
        expect(runner).to receive(:task_update).with(8, 'conditioner.exception', anything)
        runner.resolve(conditions: '{}', task_id: 8)
      end
    end
  end
end
