require 'legion/extensions/transport'

module Legion::Extensions::Conditioner
  module Transport
    module AutoBuild
      extend Legion::Extensions::Transport
      def self.additional_e_to_q
        [
          { from: 'task', to: 'conditioner', routing_key: 'task.subtask' },
          { from: 'task', to: 'conditioner', routing_key: 'task.subtask.conditioner' }
        ]
      end
    end
  end
end
