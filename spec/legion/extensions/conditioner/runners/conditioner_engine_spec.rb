# frozen_string_literal: true

require 'spec_helper'

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
  let(:test_class) do
    Class.new do
      include Legion::Extensions::Conditioner::Runners::Conditioner
    end
  end

  subject { test_class.new }

  describe '#send_task' do
    it 'includes engine in the forwarded payload' do
      message_double = double('SubTask', publish: true)
      allow(Legion::Transport::Messages::SubTask).to receive(:new).and_return(message_double)

      payload = {
        runner_routing_key: 'lex.transformer.runners.transform.transform',
        transformation:     '{"prompt":"summarize"}',
        engine:             'llm',
        relationship_id:    1,
        function_id:        2,
        function:           'transform',
        runner_id:          3,
        runner_class:       'Transform',
        results:            { data: 'test' }
      }

      subject.send_task(**payload)

      expect(Legion::Transport::Messages::SubTask).to have_received(:new) do |**args|
        expect(args[:engine]).to eq('llm')
      end
    end

    it 'does not include engine when not present in payload' do
      message_double = double('SubTask', publish: true)
      allow(Legion::Transport::Messages::SubTask).to receive(:new).and_return(message_double)

      payload = {
        runner_routing_key: 'lex.transformer.runners.transform.transform',
        transformation:     '{"prompt":"summarize"}',
        relationship_id:    1,
        function_id:        2,
        function:           'transform',
        runner_id:          3,
        runner_class:       'Transform',
        results:            { data: 'test' }
      }

      subject.send_task(**payload)

      expect(Legion::Transport::Messages::SubTask).to have_received(:new) do |**args|
        expect(args).not_to have_key(:engine)
      end
    end
  end
end
