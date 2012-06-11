require 'omf-web/widget/abstract_widget'

module OMF::Web::Widget

  # Supports widgets which visualize the content of a +Table+
  # which may also dynamically change.
  #
  class DataWidget < AbstractWidget
    #depends_on :css, "/resource/css/graph.css"

    attr_reader :name, :opts #:base_id


    # opts
    #   :data_sources .. Either a single table, or a hash of 'name' => table.
    #   :js_class .. Javascript class used for visualizing data
    #   :wopts .. options sent to the javascript instance
    #   :js_url .. URL where +jsVizClass+ can be loaded from
    #   :dynamic .. update the widget when the data_table is changing
    #     :updateInterval .. if web sockets aren't used, check every :updateInterval sec [3]
    #
    def initialize(opts = {})
      opts = opts.dup # not sure why we may need to this. Is this hash used anywhere wlse?
      unless vizType = opts[:type].split('/')[-1]
        raise "Missing widget option ':viz_type' for widget '#{name}' (#{opts.inspect})"
      end
      name = opts[:name] ||= 'Unknown'
      opts[:js_url] = "graph/#{vizType}.js"
      opts[:js_class] = "OML.#{vizType}"
      opts[:base_el] = "\##{dom_id}"

      # @js_class = @widget_type = opts[:js_class]
      # @js_url = opts[:js_url]
# 
      # @base_id = "w#{object_id.abs}"
      # @base_el = "\##{@base_id}"
      # @wopts['base_el'] = @base_el
# 
      # @js_var_name = "oml_#{object_id.abs}"
      
      super opts      
      
#      @widget_type = vizType
      
#      @wopts = opts.dup
      if (ds = opts.delete(:data_source))
        # single source
        @data_sources = {:default => ds}
      end
      unless @data_sources ||= opts.delete(:data_sources)
        raise "Missing option ':data_sources' for widget '#{name}'"
      end
      unless @data_sources.kind_of? Hash
        @data_sources = {:default => @data_sources}
      end
      opts[:data_sources] = @data_sources.collect do |name, ds_name|
        {:stream => ds_name, :name => name}
      end
    end
    
    # This is the DOM id which should be used by the renderer for this widget. 
    # We need to keep this here as various renderes at various levels may need
    # to get a reference to it to allow for such functionalities as 
    # hiding, stacking, ...
    def dom_id
      "w#{object_id.abs}"
    end

    def content()
      OMF::Web::Theme.require 'data_renderer'
      OMF::Web::Theme::DataRenderer.new(self, @opts)
    end

    # A dynamic widget may open a web socket back to this service. Connect
    # to the respective table and feed back any changes.
    #
    # BUG ALERT: We send the entire content of the data table initially and only
    # start monitoring the table for new stuff when the web socket connects. Any
    # data added in between is not covered.
    #
    def on_ws_open(ws)
      raise "ARE WE STILL NEEDING THIS"
      #puts ">>>> ON_WS_OPEN"
      @ws = ws
      @data_sources.each do |name, table|
        table.on_row_added(self.object_id) do |row|
          begin
            # may want to queue events to group events into larger messages
            msg = [{:stream => name, :events => [row]}]
            ws.send_data msg.to_json
          rescue Exception => ex
            warn ex
          end
        end
      end
    end

    def on_ws_close(ws)
      raise "ARE WE STILL NEEDING THIS"
      @ws = nil
      @data_sources.each do |name, table|
        table.on_row_added(self.object_id)
      end
    end

    def collect_data_sources(ds_set)
      #puts "DATA_SOURCES>>>> #{@data_sources.values.inspect}"
      @data_sources.values.each do |ds|
        ds_set.add(ds.is_a?(Hash) ? ds : {:name => ds})
      end
      ds_set
    end



  end # DataWidget

end
