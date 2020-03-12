module Legion::Extensions::Conditioner
  module Actor
    class Conditioner < Legion::Extensions::Actors::Subscription
      def runner_function
        'check'
      end

      def check_subtask?
        false
      end

      def generate_task?
        false
      end
    end
  end
end
