module Legion::Extensions::Conditioner
  module Transport
    module AutoBuild
      extend Legion::Extensions::Transport::AutoBuild
      def self.additional_e_to_q
        [{ from: 'task', to: 'conditioner', routing_key: 'task.subtask' }]
      end
    end
  end
end
