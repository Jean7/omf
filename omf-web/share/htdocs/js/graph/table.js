

L.provide('OML.table', ["table2.css", ["/resource/vendor/jquery/jquery.js", "/resource/vendor/jquery/jquery.dataTables.js"]], function () {
  if (typeof(OML) == "undefined") {
    OML = {};
  }

  OML['table'] = Backbone.Model.extend({

    initialize: function(opts) {
      this.opts = opts;
      
      /* create table template */
      var base_el = opts.base_el || '#table'

      this.init_data_source();

      var tid = base_el.substr(1) + "_t";
      var tbid = base_el.substr(1) + "_tb";
      var h = "<table id='" + tid;
      h += "' cellpadding='0' cellspacing='0' border='0' class='oml_table' width='100%'>";
      h += "<thead><tr>";

      var schema = this.schema = this.data_source.schema; //this.process_single_schema(this.data_source);
      if (schema) {
        for (var i = 0; i < schema.length; i++) {
          var col = schema[i];
          h += "<th class='oml_c" + i + " oml_" + col.name + "'>" + col.name + "</th>";
        }
      }
      h += "</tr></thead>";
      h += "<tbody id='" + tbid + "'></tbody>";
      h += "</table>";
      $(base_el).prepend(h);
      this.table_el = $('#' + tid);
      this.tbody_el = $('#' + tbid);

      this.dataTable = this.table_el.dataTable({
        "sPaginationType": "full_numbers"
      });
      
      this.update();
      // var data = opts.data;
      // if (data) this.update(data);
    },

    // Find the appropriate data source and bind to it
    //
    init_data_source: function() {
      var o = this.opts;
      var sources = o.data_sources;
      var self = this;
      
      if (! (sources instanceof Array)) {
        throw "Expected an array"
      }
      if (sources.length != 1) {
        throw "Can only process a SINGLE source"
      }
      var ds = this.data_source = OML.data_sources[sources[0].stream];
      if (o.dynamic == true) {
        ds.on_changed(function(evt) {
          self.update();
        });
      }

    },
    
    
    update: function() {
      var data_source = this.data_source;
      if ((this.data = data_source.events) == null) {
        throw "Missing events array in data source"
      }
      this.render_rows(this.data, false);
    },


    /* Add rows */
    render_rows: function(rows, update) {
      this.dataTable.fnClearTable();
      this.dataTable.fnAddData(rows);
    }

  })
});

/*
  Local Variables:
  mode: Javascript
  tab-width: 2
  indent-tabs-mode: nil
  End:
*/
