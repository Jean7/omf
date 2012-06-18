module Blather
  class Stream
    # @private
    class Features
      def next!
        @idx = @idx ? @idx+1 : 0
        if stanza = @features.children[@idx]
          if stanza.namespaces['xmlns'] && (klass = self.class.from_namespace(stanza.namespaces['xmlns']))
            @feature = klass.new(
              @stream,
              proc {
              if (klass == Blather::Stream::Register && @features && !@features.children.find { |v| v.element_name == "mechanisms" }.nil?)
                stanza = @features.children.find { |v| v.element_name == "mechanisms" }
                @idx = @features.children.index(stanza)
                klass = self.class.from_namespace(stanza.namespaces['xmlns'])
                @feature = klass.new @stream, proc { next! }, @fail
                @feature.receive_data stanza
              else
                next!
              end
            },
              (klass == Blather::Stream::SASL && @features && !@features.children.find { |v| v.element_name == "register" }.nil?) ? proc { next! } : @fail
            )
            @feature.receive_data stanza
          else
            next!
          end
        else
          succeed!
        end
      end
    end
  end #Stream
end #Blather
