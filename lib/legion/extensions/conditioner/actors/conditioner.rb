module Legion::Extensions::Conditioner
  module Actor
    class Conditioner < Legion::Extensions::Actors::Subscription
      def runner_function
        'check'
      end

      def use_runner
        false
      end
    end
  end
end
