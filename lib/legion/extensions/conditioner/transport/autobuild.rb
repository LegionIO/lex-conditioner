require 'legion/extensions/transport/autobuild'

module Legion
  module Extensions
    module Conditioner
      module Transport
        module AutoBuild
          extend Legion::Extensions::Transport::AutoBuild

          def self.e_to_q
            [{
              from:        Legion::Transport::Exchanges::Task,
              to:          'conditioner',
              routing_key: 'task.subtask'
            }]
          end
        end
      end
    end
  end
end
