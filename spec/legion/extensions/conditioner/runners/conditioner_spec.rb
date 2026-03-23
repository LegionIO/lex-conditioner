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

  module Transport
    module Messages
      unless defined?(Legion::Transport::Messages::SubTask)
        class SubTask
          def initialize(**); end
          def publish; end
        end
      end
    end
  end

  module Exception
    class MissingArgument < StandardError; end unless defined?(Legion::Exception::MissingArgument)
  end
end

require 'legion/extensions/conditioner/runners/conditioner'

RSpec.describe Legion::Extensions::Conditioner::Runners::Conditioner do
  let(:runner) do
    klass = Class.new do
      include Legion::Extensions::Conditioner::Runners::Conditioner

      # No-op stubs for helpers mixed in by the runner
      def send_task(**); end
      def task_update(*); end
      def generate_task_log(**); end
    end
    klass.new
  end

  def conditions_for(hash)
    Legion::JSON.dump(hash)
  end

  describe '#check' do
    context 'when condition passes and transformation is present' do
      let(:payload) do
        {
          conditions:     conditions_for(all: [{ fact: 'status', operator: 'equal', value: 200 }]),
          status:         200,
          transformation: '{"key":"value"}'
        }
      end

      it 'returns success: true' do
        result = runner.check(**payload)
        expect(result).to include(success: true, valid: true)
      end

      it 'calls send_task' do
        expect(runner).to receive(:send_task)
        runner.check(**payload)
      end
    end

    context 'when condition passes and runner_routing_key is present' do
      let(:payload) do
        {
          conditions:         conditions_for(all: [{ fact: 'status', operator: 'equal', value: 200 }]),
          status:             200,
          runner_routing_key: 'ext.runner.func'
        }
      end

      it 'returns success: true with valid true' do
        result = runner.check(**payload)
        expect(result).to include(success: true, valid: true)
      end

      it 'calls send_task' do
        expect(runner).to receive(:send_task)
        runner.check(**payload)
      end
    end

    context 'when condition passes but no routing info' do
      let(:payload) do
        {
          conditions: conditions_for(all: [{ fact: 'status', operator: 'equal', value: 200 }]),
          status:     200
        }
      end

      it 'returns success: true' do
        result = runner.check(**payload)
        expect(result).to include(success: true, valid: true)
      end

      it 'still calls send_task (task.exception path)' do
        expect(runner).to receive(:send_task)
        runner.check(**payload)
      end
    end

    context 'when condition fails' do
      let(:payload) do
        {
          conditions: conditions_for(all: [{ fact: 'status', operator: 'equal', value: 404 }]),
          status:     200
        }
      end

      it 'returns success: true with valid false' do
        result = runner.check(**payload)
        expect(result).to include(success: true, valid: false)
      end

      it 'does not call send_task' do
        expect(runner).not_to receive(:send_task)
        runner.check(**payload)
      end
    end

    context 'when task_id is present' do
      let(:payload) do
        {
          conditions:         conditions_for(all: [{ fact: 'x', operator: 'equal', value: 1 }]),
          x:                  1,
          task_id:            42,
          runner_routing_key: 'ext.runner.func'
        }
      end

      it 'calls task_update with the task_id' do
        expect(runner).to receive(:task_update).with(42, 'task.queued', hash_including(task_id: 42))
        runner.check(**payload)
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
        runner.check(**payload)
      end
    end

    context 'when debug is true and task_id is present' do
      let(:payload) do
        {
          conditions:         conditions_for(all: [{ fact: 'x', operator: 'equal', value: 1 }]),
          x:                  1,
          task_id:            7,
          runner_routing_key: 'ext.runner.func',
          debug:              true
        }
      end

      it 'calls generate_task_log' do
        expect(runner).to receive(:generate_task_log).with(hash_including(task_id: 7, function: 'check'))
        runner.check(**payload)
      end
    end

    context 'when an exception is raised during evaluation' do
      it 'logs the error and calls task_update with conditioner.exception' do
        allow(Legion::Extensions::Conditioner::Condition).to receive(:new).and_raise(StandardError, 'boom')
        expect(runner).to receive(:task_update).with(5, 'conditioner.exception', anything)
        runner.check(conditions: '{}', task_id: 5)
      end
    end
  end

  # A separate runner class that does NOT stub send_task, so the real implementation is exercised.
  let(:send_task_runner) do
    klass = Class.new do
      include Legion::Extensions::Conditioner::Runners::Conditioner
    end
    klass.new
  end

  describe '#send_task' do
    it 'calls SubTask with routing_key: nil when no routing info is present' do
      msg = instance_double(Legion::Transport::Messages::SubTask)
      allow(msg).to receive(:publish)
      allow(Legion::Transport::Messages::SubTask).to receive(:new).and_return(msg)

      send_task_runner.send_task(function: 'test')
      expect(Legion::Transport::Messages::SubTask).to have_received(:new).with(hash_including(routing_key: nil))
    end

    it 'uses runner_routing_key as routing_key' do
      msg = instance_double(Legion::Transport::Messages::SubTask)
      allow(msg).to receive(:publish)
      allow(Legion::Transport::Messages::SubTask).to receive(:new).and_return(msg)

      send_task_runner.send_task(runner_routing_key: 'ext.runner.func')
      expect(Legion::Transport::Messages::SubTask).to have_received(:new).with(hash_including(routing_key: 'ext.runner.func'))
    end

    it 'uses task.subtask.transform as routing_key when transformation present' do
      msg = instance_double(Legion::Transport::Messages::SubTask)
      allow(msg).to receive(:publish)
      allow(Legion::Transport::Messages::SubTask).to receive(:new).and_return(msg)

      send_task_runner.send_task(transformation: '{"key":"val"}', runner_routing_key: 'ext.runner.func')
      expect(Legion::Transport::Messages::SubTask).to have_received(:new).with(hash_including(routing_key: 'task.subtask.transform'))
    end

    it 'only passes known columns to SubTask' do
      msg = instance_double(Legion::Transport::Messages::SubTask)
      allow(msg).to receive(:publish)
      allow(Legion::Transport::Messages::SubTask).to receive(:new).and_return(msg)

      send_task_runner.send_task(runner_routing_key: 'ext.runner.func', unknown_extra: 'ignored')
      expect(Legion::Transport::Messages::SubTask).to have_received(:new).with(
        hash_not_including(unknown_extra: 'ignored')
      )
    end
  end
end
