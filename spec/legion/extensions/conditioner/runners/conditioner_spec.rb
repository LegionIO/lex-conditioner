# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/conditioner/runners/conditioner'

RSpec.describe Legion::Extensions::Conditioner::Runners::Conditioner do
  let(:runner) do
    Class.new do
      include Legion::Extensions::Conditioner::Runners::Conditioner

      def task_update(**); end
    end.new
  end
  let(:conditions) { { all: [{ fact: 'allowed', operator: 'is_true' }] } }
  let(:published) { [] }
  let(:published_routes) { [] }

  before do
    allow(Legion::Transport::Messages::SubTask).to receive(:new).and_wrap_original do |original, **options|
      original.call(**options).tap do |message|
        allow(message).to receive(:publish!) do
          published << message.message
          published_routes << message.routing_key
          { accepted: true, status: :confirmed }
        end
      end
    end
  end

  it 'skips rejection without constructing a downstream task' do
    result = runner.check(conditions: conditions, task_id: 7)
    expect(result).to include(success: false, valid: false, status: 'task.skipped', explanation: include(valid: false))
    expect(published).to be_empty
    expect(Legion::Transport::Messages::SubTask).not_to have_received(:new)
  end

  it 'rejects malformed rules rather than dispatching success' do
    result = runner.check(conditions: { all: [{ fact: 'allowed', operator: 'unknown' }] }, allowed: true)
    expect(result).to include(success: false, status: 'conditioner.failed')
    expect(published).to be_empty
  end

  it 'fails when no usable downstream route exists' do
    result = runner.check(conditions: conditions, allowed: true, runner_routing_key: ' ', transformation: '')
    expect(result).to include(success: false, status: 'conditioner.failed')
    expect(result[:error]).to match(/routing key/)
    expect(published).to be_empty
  end

  it 'forwards a passing task without completing or queuing the eventual target early' do
    expect(runner).not_to receive(:task_update)
    result = runner.check(conditions: conditions, allowed: true, function: 'run', runner_routing_key: 'example.run', task_id: 8)
    expect(result).to include(success: true, valid: true, status: 'task.queued')
    expect(published.first).to include(task_id: 8, function: 'run')
  end

  it 'uses canonical transform routing, queued status and metadata' do
    result = runner.check(conditions: conditions, allowed: true, function: 'run', transformation: '{}', correlation_id: 'stage-correlation')
    expect(result).to include(success: true, status: Legion::Transport::Task::Protocol::STATUSES.fetch(:transformer_queued))
    expect(published.first).to include(transformation: '{}', correlation_id: 'stage-correlation')
    expect(published_routes).to eq([Legion::Transport::Task::Protocol::ROUTES.fetch(:transform)])
  end

  it 'persists a rejection with canonical keyword arguments and its explanation' do
    expect(runner).to receive(:task_update).with(task_id: 9, status: 'task.skipped', results: include(success: false, explanation: include(valid: false)))
    runner.check(conditions: conditions, task_id: 9, allowed: false)
  end

  it 'does not turn a rejected publication into a successful stage or terminal task failure' do
    rejection = Legion::Transport::PublishRejected.new(result: { accepted: false, status: :unroutable })
    allow(Legion::Transport::Messages::SubTask).to receive(:new).and_wrap_original do |original, **options|
      original.call(**options).tap { |message| allow(message).to receive(:publish!).and_raise(rejection) }
    end
    expect(runner).not_to receive(:task_update)
    expect do
      runner.check(conditions: conditions, allowed: true, function: 'run', runner_routing_key: 'example.run', task_id: 10)
    end.to raise_error(Legion::Transport::PublishRejected)
  end
end
