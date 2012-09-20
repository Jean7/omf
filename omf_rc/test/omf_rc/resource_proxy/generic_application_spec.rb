require 'test_helper'
require 'omf_rc/resource_proxy/generic_application'



describe OmfRc::ResourceProxy::GenericApplication do

  before do
    @app_test = OmfRc::ResourceFactory.new(:generic_application, { hrn: 'an_application' })
    @app_test.comm = MiniTest::Mock.new
    @app_test.comm.expect :publish, nil, [String,OmfCommon::Message]
  end

  describe "when initialised" do
    it "must respond to an 'on_app_event' call back" do
      #OmfRc::ResourceProxy::GenericApplication.method_defined?(:on_app_event).must_equal true
      @app_test.must_respond_to :on_app_event
    end

    it "must have its state property set to 'stop'" do
      @app_test.request_state.to_sym.must_equal :stop
    end

    it "must be able to configure/request its basic properties" do
      basic_prop = %w(binary_path pkg_tarball pkg_ubuntu pkg_fedora force_tarball_install map_err_to_out tarball_install_path)
      basic_prop.each do |p|
        @app_test.method("configure_#{p}".to_sym).call('foo')
        @app_test.method("request_#{p}".to_sym).call.must_equal 'foo'
      end
    end

    it "must be able to tell which platform it is running on (either: unknown | ubuntu | fedora)" do
      @app_test.request_platform.must_match /unknown|ubuntu|fedora/
    end

    it "must be able to configure its environments property" do
      test_environments = { 'foo' => 123, 'bar_bar' => 'bar_123' }
      @app_test.method(:configure_environments).call(test_environments)
      @app_test.property.environments.must_be_kind_of Hash
      @app_test.property.environments['foo'].must_equal 123
      @app_test.property.environments['bar_bar'].must_equal 'bar_123'
    end
  end

  describe "when configuring its parameters property" do
    it "must be able to set its parameters property" do
      test_params = { :p1 => { :cmd => '--foo', :value => 'foo'} }
      @app_test.method(:configure_parameters).call(test_params)
      @app_test.property.parameters.must_be_kind_of Hash
      @app_test.property.parameters[:p1].must_be_kind_of Hash
      @app_test.property.parameters[:p1][:cmd].must_equal '--foo'
      @app_test.property.parameters[:p1][:value].must_equal 'foo'
    end

    it "must be able to merge new parameters into existing ones" do
      old_params = { :p1 => { :cmd => '--foo', :default => 'old_foo'} }
      @app_test.property.parameters = old_params
      new_params = { :p1 => { :default => 'new_foo', :value => 'val_foo'},
                     :p2 => { :cmd => 'bar', :default => 'bar_bar'} }
      @app_test.method(:configure_parameters).call(new_params)
      @app_test.property.parameters[:p1][:cmd].must_equal '--foo'
      @app_test.property.parameters[:p1][:default].must_equal 'new_foo'
      @app_test.property.parameters[:p1][:value].must_equal 'val_foo'
      @app_test.property.parameters[:p2][:cmd].must_equal 'bar'
      @app_test.property.parameters[:p2][:default].must_equal 'bar_bar'
    end

    it "must be able to sanitize its parameters property" do
      test_params = { :p1 => { :mandatory => 'true', :dynamic => false},
                      :p2 => { :type => 'Boolean', :default => true, :value => 'false'},
                      :p3 => { :type => 'Boolean', :default => 'true', :value => false} }
      @app_test.method(:configure_parameters).call(test_params)
      @app_test.property.parameters[:p1][:mandatory].must_be_kind_of TrueClass
      @app_test.property.parameters[:p1][:dynamic].must_be_kind_of FalseClass
      @app_test.property.parameters[:p2][:default].must_be_kind_of TrueClass
      @app_test.property.parameters[:p2][:value].must_be_kind_of FalseClass
      @app_test.property.parameters[:p3][:default].must_be_kind_of TrueClass
      @app_test.property.parameters[:p3][:value].must_be_kind_of FalseClass
    end

    it "must be able to validate the correct type of a defined parameter" do
      test_params = { :p1 => { :type => 'String', :default => 'foo', :value => 'bar'},
                      :p2 => { :type => 'Numeric', :default => 123, :value => 456},
                      :p3 => { :type => 'Boolean', :default => true, :value => true} }
      @app_test.method(:configure_parameters).call(test_params)
      @app_test.property.parameters[:p1][:default].must_be_kind_of String
      @app_test.property.parameters[:p1][:value].must_be_kind_of String
      @app_test.property.parameters[:p2][:default].must_be_kind_of Numeric
      @app_test.property.parameters[:p2][:value].must_be_kind_of Numeric
      @app_test.property.parameters[:p3][:default].must_be_kind_of TrueClass
      @app_test.property.parameters[:p3][:value].must_be_kind_of TrueClass
    end

    it "must be able to detect incorrect type setting for a defined parameter, and DO NOT update the parameter in that case" do
      old_params = { :p1 => { :type => 'String', :value => 'foo'},
                     :p2 => { :type => 'Numeric', :default => 123, :value => 456 },
                     :p3 => { :type => 'Boolean', :default => true, :value => true} }
      @app_test.property.parameters = old_params
      new_params = { :p1 => { :type => 'String', :value => true},
                     :p2 => { :type => 'Numeric', :default => 456, :value => '456' },
                     :p3 => { :type => 'Boolean', :default => 123, :value => false} }
      @app_test.stub :log_inform_error, nil do      
        @app_test.method(:configure_parameters).call(new_params)
      end
      @app_test.property.parameters[:p1][:value].must_equal 'foo'
      @app_test.property.parameters[:p2][:default].must_equal 123
      @app_test.property.parameters[:p2][:value].must_equal 456
      @app_test.property.parameters[:p3][:default].must_be_kind_of TrueClass
      @app_test.property.parameters[:p3][:value].must_be_kind_of TrueClass
    end
  end

  describe "when receiving an event from a running application instance" do
    it "must publish an INFORM message to relay that event" do
      @app_test.on_app_event('STDOUT', 'app_instance_id', 'Some text here').must_be_nil
      assert @app_test.comm.verify
    end

    it "must increments its event_sequence after publishig that INFORM message" do
      i = @app_test.property.event_sequence
      @app_test.on_app_event('STDOUT', 'app_instance_id', 'Some text here')
      @app_test.property.event_sequence.must_equal i+1
    end

    it "must switch its state to 'stop' if the event is of a type 'DONE'" do
      @app_test.on_app_event('DONE.OK', 'app_instance_id', 'Some text here')
      @app_test.request_state.to_sym.must_equal :stop
    end

    it "must set installed property to true if the event is 'DONE.OK' and the app_id's suffix is '_INSTALL'" do
      @app_test.on_app_event('DONE.OK', 'app_instance_id_INSTALL', 'Some text here')
      @app_test.request_state.to_sym.must_equal :stop
      @app_test.request_installed.must_equal "true"
    end
  end

  describe "when configuring its state property to :install" do
    it "must do nothing if its original state is not :stop" do
      @app_test.property.state = :run
      @app_test.method(:configure_state).call(:install)
      @app_test.property.state.must_equal :run
    end

    it "must do nothing if its original state is :stop and it is already installed" do
      @app_test.property.state = :stop
      @app_test.property.installed = true
      @app_test.method(:configure_state).call(:install)
      @app_test.property.state.must_equal :stop
    end

    it "must use the tarball install method if it does not know its OS platform or if force_tarball_install is set" do
      @app_test.property.pkg_tarball = 'foo'
      @app_test.property.tarball_install_path = '/bar/'
      @stub_tarball_tasks = Proc.new do |pkg,path|
        pkg.must_equal 'foo'
        path.must_equal '/bar/'
        @did_call_install_tarball = true
      end
      def call_configure
        @app_test.stub :install_tarball, @stub_tarball_tasks do      
          @app_test.method(:configure_state).call(:install).must_equal :install
          @did_call_install_tarball.must_equal true
        end
      end
      # Unknown Platform...
      @did_call_install_tarball = false
      @app_test.property.state = :stop
      @app_test.property.installed = false
      @app_test.property.platform = :unknown
      call_configure
      # Force Install Tarball...
      @did_call_install_tarball = false
      @app_test.property.state = :stop
      @app_test.property.installed = false
      @app_test.property.platform = :ubuntu
      @app_test.property.force_tarball_install = true
      call_configure
    end

    it "must use the ubuntu install method if its OS platform is ubuntu" do
      @did_call_install_ubuntu = false
      @app_test.property.state = :stop
      @app_test.property.installed = false
      @app_test.property.platform = :ubuntu
      @app_test.property.pkg_ubuntu = 'foo'
      @stub_ubuntu_tasks = Proc.new do |pkg|
        pkg.must_equal 'foo'
        @did_call_install_ubuntu = true
      end
      @app_test.stub :install_ubuntu, @stub_ubuntu_tasks do      
        @app_test.method(:configure_state).call(:install).must_equal :install
        @did_call_install_ubuntu.must_equal true
      end
    end

    it "must use the fedora install method if its OS platform is fedora" do
      @did_call_install_fedora = false
      @app_test.property.state = :stop
      @app_test.property.installed = false
      @app_test.property.platform = :fedora
      @app_test.property.pkg_fedora = 'foo'
      @stub_fedora_tasks = Proc.new do |pkg|
        pkg.must_equal 'foo'
        @did_call_install_fedora = true
      end
      @app_test.stub :install_fedora, @stub_fedora_tasks do      
        @app_test.method(:configure_state).call(:install).must_equal :install
        @did_call_install_fedora.must_equal true
      end
    end
  end

  describe "when configuring its state property to :run" do
  end

  describe "when configuring its state property to :install" do
    it "must do nothing if its original state is not :run or :pause" do
      @app_test.property.state = :stop
      @app_test.method(:configure_state).call(:stop)
      @app_test.property.state.must_equal :stop
      @app_test.property.state = :install
      @app_test.method(:configure_state).call(:stop)
      @app_test.property.state.must_equal :install
    end

    # it "must stop the app instance if its original state is :run or :pause" do
    # end
  end 



end
