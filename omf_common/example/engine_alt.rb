# OMF_VERSIONS = 6.0
require 'omf_common'

opts = {
  debug: true,
  communication: {
    type: :mock
  },
  runtime: { type: :local}
}

$stdout.sync = true
Logging.appenders.stdout(
  'my_format',
  :layout => Logging.layouts.pattern(:date_pattern => '%H:%M:%S',
                                     :pattern => '%d %5l %c{2}: %m\n',
                                     :color_scheme => 'none'))
Logging.logger.root.appenders = 'my_format'
Logging.logger.root.level = :debug if opts[:debug]



# Request the garage to create a new engine
#
# def create_engine(garage)
  # garage.create('mp4', type: :engine).on_create_succeeded do |emsg|
    # puts "EEE: #{emsg.inspect}"
    # engine = emsg.resource
    # on_engine_created(engine)
  # end.on_create_failed do |fmsg|
    # logger.error "Resource creation failed ---"
    # logger.error fmsg.read_content("reason")
  # end
# end

# Should be
def create_engine(garage)
  garage.create('mp4', type: :engine) do |msg|
    puts "EEE: #{msg.inspect}"
    if msg.success?
      engine = msg.resource
      on_engine_created(engine)
    else
      logger.error "Resource creation failed ---"
      logger.error msg.read_content("reason")
    end
  end
end


# This is an alternative version of creating a new engine.
# We create teh message first without sending it, then attach various
# response handlers and finally publish it.
#
def create_engine2
  msg = garage.create_message('mp4')
  msg.on_created do |engine, emsg|
    on_engine_created(engine)
  end
  msg.on_created_failed do |fmsg|
    logger.error "Resource creation failed ---"
    logger.error fmsg.read_content("reason")
  end
  msg.publish
end

# This method is called whenever a new engine has been created by the garage.
#
# @param [Topic] engine Topic representing the created engine
# 
def on_engine_created(engine)
  # Monitor all status information from teh engine
  engine.on_inform_status do |msg|
    msg.each_property do |name, value|
      logger.info "#{name} => #{value}"
    end
    # The above is rather cryptic, why couldn't it be like:
    # msg.each_property do |key, value|
    #   logger.info "#{key} => #{value}"
    # end
  end

  engine.on_inform_failed do |msg|
    logger.error msg.read_content("reason")
  end

  # Send a request for specific properties
  engine.request([:max_rpm, {:provider => {country: 'japan'}}, :max_power])

  # Now we will apply 50% throttle to the engine
  engine.configure(throttle: 50)

  # Some time later, we want to reduce the throttle to 0, to avoid blowing up the engine
  engine.after(5) do
    engine.configure(throttle: 0)
    
    # While we are at it, also test error handling
    engine.request([:error]) do |msg|
      if msg.success?
        logger.error "Expected unsuccessful reply"
      else
        logger.info "Received expected fail message - #{msg[:reason]}"
      end
    end
  end

  # 10 seconds later, we will 'release' this engine, i.e. shut it down
  engine.after(10) do
    logger.info "Time to release engine #{engine}"
    engine.release  # Could also be 'garage.release(engine)'
  end
end

# Environment setup
OmfCommon.init(opts) do 

  # Create garage proxy
  load File.join(File.dirname(__FILE__), '..', '..', 'omf_rc', 'example', 'garage_controller.rb')
  garage_inst = OmfRc::ResourceFactory.create(:garage, hrn: :garage_1)
  
  # Get handle on existing entity
  OmfCommon.comm.subscribe('garage_1') do |garage|
  
    garage.on_inform_failed do |msg|
      logger.error msg
    end
    create_engine(garage)
  end
end

OmfCommon.eventloop.join
puts "DONE"

