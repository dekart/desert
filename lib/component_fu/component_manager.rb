module ComponentFu
  class ComponentManager
    class << self
      def instance
        @instance ||= new
      end
      attr_writer :instance

      protected
      def method_missing(method_name, *args, &block)
        instance.__send__(method_name, *args, &block)
      end
    end

    attr_reader :loading_plugin
    
    def initialize
      @plugins = []
    end

    def plugins
      @plugins.dup
    end

    def load_paths
      paths = []
      plugin_paths = plugins.collect {|plugin| plugin.path}
      plugin_paths << File.expand_path(RAILS_ROOT)
      plugin_paths.each do |component_root|
        paths << "#{component_root}/app"
        paths << "#{component_root}/app/models"
        paths << "#{component_root}/app/controllers"
        paths << "#{component_root}/app/helpers"
        paths << "#{component_root}/lib"
      end
      paths
    end

    def register_plugin(plugin_path)
      plugin = Plugin.new(plugin_path)

      if existing_plugin = find_plugin(plugin.name)
        return existing_plugin
      end

      @plugins << plugin
      plugin
    end

    def find_plugin(name_or_directory)
      name = File.basename(File.expand_path(name_or_directory))
      plugins.find do |plugin|
        plugin.name == name
      end
    end

    def plugin_exists?(name_or_directory)
      !find_plugin(name_or_directory).nil?
    end

    def plugin_path(name)
      plugin = find_plugin(name)
      return nil unless plugin
      plugin.path
    end

    def files_on_load_path(file)
      component_fu_file_exists = false
      load_paths = []
      ComponentFu::ComponentManager.load_paths.each do |path|
        full_path = File.join(path, file)
        full_path_rb = "#{full_path}.rb"
        load_paths << full_path_rb if File.exists?(full_path_rb)
      end
      load_paths
    end

    def directory_on_load_path?(dir_suffix)
      ComponentFu::ComponentManager.load_paths.each do |path|
        return true if File.directory?(File.join(path, dir_suffix))
      end
      return false
    end
  end
end