# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/conditioner/runners/conditioner'

RSpec.describe Legion::Extensions::Conditioner::Runners::Conditioner do
  let(:runner) { Class.new { include Legion::Extensions::Conditioner::Runners::Conditioner }.new }

  it 'retains policy context, lineage, engine options and business arguments in the downstream message' do
    received = nil
    allow(Legion::Transport::Messages::SubTask).to receive(:new).and_wrap_original do |original, **options|
      original.call(**options).tap do |message|
        allow(message).to receive(:publish!) do
          received = message.message
          { accepted: true, status: :confirmed }
        end
      end
    end
    envelope = {
      task_id: 12, parent_id: 11, master_id: 10, chain_id: 4, relationship_id: 5,
      function: 'run', runner_class: 'Example', runner_routing_key: 'example.run',
      principal_id: 'alice', principal_type: 'user', worker_id: 'worker-1', tenant_id: 'tenant-1',
      originating_principal_id: 'originator', originating_principal_type: 'user',
      correlation_id: 'correlation-1', message_id: 'message-1', source: 'scheduler', depth: 2,
      schedule_id: 8, occurrence_id: 'occurrence-1', definition_version: 3,
      engine: 'erb', engine_options: { trim_mode: '-' }, schema: { type: 'object' },
      transformation: '{}', results: { items: [1, 2] }, args: { customer: 'abc' },
      kwargs: { region: 'west' }, function_args: { limit: 2 }, payload: { request: 'request-1' }
    }

    result = runner.send_task(**envelope)
    expect(result).to include(success: true, status: 'transformer.queued')
    expect(received).to include(envelope)
    expect(received).not_to have_key(:conditions)
  end
end
