# frozen_string_literal: true

module ElasticAPM
  # @api private
  module SpanHelpers
    # @api private
    module ClassMethods
      def span_class_method(method, name, type)
        __span_method_on(singleton_class, method, name, type)
      end

      private

      def __span_method_on(klass, method, name, type)
        klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          alias :"__without_apm_#{method}" :"#{method}"

          def #{method}(*args, &block)
            unless ElasticAPM.current_transaction
              return __without_apm_#{method}(*args, &block)
            end

            ElasticAPM.span "#{name}", "#{type}" do
              __without_apm_#{method}(*args, &block)
            end
          end
        RUBY
      end
    end

    def self.included(kls)
      kls.class_eval do
        extend ClassMethods
      end
    end
  end
end
