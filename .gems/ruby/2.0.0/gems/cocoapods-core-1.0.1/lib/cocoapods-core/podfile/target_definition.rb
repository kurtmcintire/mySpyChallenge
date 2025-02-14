module Pod
  class Podfile
    # The TargetDefinition stores the information of a CocoaPods static
    # library. The target definition can be linked with one or more targets of
    # the user project.
    #
    # Target definitions can be nested and by default inherit the dependencies
    # of the parent.
    #
    class TargetDefinition
      # @return [TargetDefinition, Podfile] the parent target definition or the
      #         Podfile if the receiver is root.
      #
      attr_reader :parent

      # @param  [String, Symbol]
      #         name @see name
      #
      # @param  [TargetDefinition] parent
      #         @see parent
      #
      def initialize(name, parent, internal_hash = nil)
        @internal_hash = internal_hash || {}
        @parent = parent
        @children = []
        self.name ||= name
        if parent.is_a?(TargetDefinition)
          parent.children << self
        end
      end

      # @return [Array<TargetDefinition>] the children target definitions.
      #
      attr_reader :children

      # @return [Array<TargetDefinition>] the targets definition descending
      #         from this one.
      #
      def recursive_children
        (children + children.map(&:recursive_children)).flatten
      end

      # @return [Bool] Whether the target definition is root.
      #
      def root?
        parent.is_a?(Podfile) || parent.nil?
      end

      # @return [TargetDefinition] The root target definition.
      #
      def root
        if root?
          self
        else
          parent.root
        end
      end

      # @return [Podfile] The podfile that contains the specification for this
      #         target definition.
      #
      def podfile
        root.parent
      end

      # @return [Array<Dependency>] The list of the dependencies of the target
      #         definition including the inherited ones.
      #
      def dependencies
        if exclusive?
          non_inherited_dependencies
        else
          non_inherited_dependencies + parent.dependencies
        end
      end

      # @return [Array<TargetDefinition>] the targets from which this target
      #         definition should inherit only search paths.
      #
      def targets_to_inherit_search_paths
        can_inherit = !root? && matches_platform?(parent)
        if inheritance == 'search_paths' # && can_inherit
          parent.targets_to_inherit_search_paths << parent
        elsif can_inherit
          parent.targets_to_inherit_search_paths
        else
          []
        end
      end

      # @return [Array] The list of the dependencies of the target definition,
      #         excluding inherited ones.
      #
      def non_inherited_dependencies
        pod_dependencies.concat(podspec_dependencies)
      end

      # @return [Bool] Whether the target definition has at least one
      #         dependency, excluding inherited ones.
      #
      def empty?
        non_inherited_dependencies.empty?
      end

      # @return [String] The label of the target definition according to its
      #         name.
      #
      def label
        if root? && name == 'Pods'
          'Pods'
        elsif exclusive? || parent.nil?
          "Pods-#{name}"
        else
          "#{parent.label}-#{name}"
        end
      end

      alias_method :to_s, :label

      # @return [String] A string representation suitable for debug.
      #
      def inspect
        "#<#{self.class} label=#{label}>"
      end

      #-----------------------------------------------------------------------#

      public

      # @!group Attributes

      # @return [String] the path of the project this target definition should
      #         link with.
      #
      def name
        get_hash_value('name')
      end

      # Sets the path of the user project this target definition should link
      # with.
      #
      # @param  [String] path
      #         The path of the project.
      #
      # @return [void]
      #
      def name=(name)
        set_hash_value('name', name)
      end

      #--------------------------------------#

      # @return [Boolean] whether this target definition is abstract.
      #
      def abstract?
        get_hash_value('abstract', root?)
      end

      # Sets whether this target definition is abstract.
      #
      # @param  [Boolean] abstract
      #         whether this target definition is abstract.
      #
      # @return [void]
      #
      def abstract=(abstract)
        set_hash_value('abstract', abstract)
      end

      #--------------------------------------#

      # @return [String] the inheritance mode for this target definition.
      #
      def inheritance
        get_hash_value('inheritance', 'complete')
      end

      # Sets the inheritance mode for this target definition.
      #
      # @param  [#to_s] inheritance
      #         the inheritance mode for this target definition.
      #
      # @raise  [Informative] if this target definition is a root target
      #         definition or if the `inheritance` value is unknown.
      #
      # @return [void]
      #
      def inheritance=(inheritance)
        inheritance = inheritance.to_s
        unless %w(none search_paths complete).include?(inheritance)
          raise Informative, "Unrecognized inheritance option `#{inheritance}` specified for target `#{name}`."
        end
        if root?
          raise Informative, 'Cannot set inheritance for the root target definition.'
        end
        set_hash_value('inheritance', inheritance)
      end

      #--------------------------------------#

      # Returns whether the target definition should inherit the dependencies
      # of the parent.
      #
      # @note   A target is always `exclusive` if it is root.
      #
      # @note   A target is always `exclusive` if the `platform` does
      #         not match the parent's `platform`.
      #
      # @return [Bool] whether is exclusive.
      #
      def exclusive?
        if root?
          true
        else
          !matches_platform?(parent) || (inheritance != 'complete')
        end
      end

      # @param  [TargetDefinition, Nil] target_definition
      #         the target definition to check for platform compatibility.
      #
      # @return [Boolean]
      #         whether this target definition matches the platform of
      #         `target_definition`.
      #
      def matches_platform?(target_definition)
        return false unless target_definition
        return true if target_definition.platform == platform
        !target_definition.platform && target_definition.abstract?
      end

      #--------------------------------------#

      # @return [String] the path of the project this target definition should
      #         link with.
      #
      def user_project_path
        path = get_hash_value('user_project_path')
        if path
          Pathname(path).sub_ext('.xcodeproj').to_path
        else
          parent.user_project_path unless root?
        end
      end

      # Sets the path of the user project this target definition should link
      # with.
      #
      # @param  [String] path
      #         The path of the project.
      #
      # @return [void]
      #
      def user_project_path=(path)
        set_hash_value('user_project_path', path)
      end

      #--------------------------------------#

      # @return [Hash{String => symbol}] A hash where the keys are the name of
      #         the build configurations and the values a symbol that
      #         represents their type (`:debug` or `:release`).
      #
      def build_configurations
        if root?
          get_hash_value('build_configurations')
        else
          get_hash_value('build_configurations') || parent.build_configurations
        end
      end

      # Sets the build configurations for this target.
      #
      # @return [Hash{String => Symbol}] hash
      #         A hash where the keys are the name of the build configurations
      #         and the values the type.
      #
      # @return [void]
      #
      def build_configurations=(hash)
        set_hash_value('build_configurations', hash) unless hash.empty?
      end

      #--------------------------------------#

      # @return [Bool] whether the target definition should inhibit warnings
      #         for a single pod. If inhibit_all_warnings is true, it will
      #         return true for any asked pod.
      #
      def inhibits_warnings_for_pod?(pod_name)
        if Array(inhibit_warnings_hash['not_for_pods']).include?(pod_name)
          false
        elsif inhibit_warnings_hash['all']
          true
        elsif !root? && parent.inhibits_warnings_for_pod?(pod_name)
          true
        else
          Array(inhibit_warnings_hash['for_pods']).include? pod_name
        end
      end

      # Sets whether the target definition should inhibit the warnings during
      # compilation for all pods.
      #
      # @param  [Bool] flag
      #         Whether the warnings should be suppressed.
      #
      # @return [void]
      #
      def inhibit_all_warnings=(flag)
        raw_inhibit_warnings_hash['all'] = flag
      end

      # Inhibits warnings for a specific pod during compilation.
      #
      # @param  [String] pod_name
      #         Name of the pod for which the warnings will be inhibited or not.
      #
      # @param  [Bool] should_inhibit
      #         Whether the warnings should be inhibited or not for given pod.
      #
      # @return [void]
      #
      def set_inhibit_warnings_for_pod(pod_name, should_inhibit)
        hash_key = case should_inhibit
                   when true
                     'for_pods'
                   when false
                     'not_for_pods'
                   when nil
                     return
                   else
                     raise ArgumentError, "Got `#{should_inhibit.inspect}`, should be a boolean"
                   end
        raw_inhibit_warnings_hash[hash_key] ||= []
        raw_inhibit_warnings_hash[hash_key] << pod_name
      end

      #--------------------------------------#

      # Sets whether the target definition should build a framework.
      #
      # @param  [Bool] flag
      #         Whether a framework should be built.
      #
      # @return [void]
      #
      def use_frameworks!(flag = true)
        set_hash_value('uses_frameworks', flag)
      end

      # @return [Bool] whether the target definition should build
      #         a framework.
      #
      def uses_frameworks?
        if internal_hash['uses_frameworks'].nil?
          root? ? false : parent.uses_frameworks?
        else
          get_hash_value('uses_frameworks')
        end
      end

      #--------------------------------------#

      # Whether a specific pod should be linked to the target when building for
      # a specific configuration. If a pod has not been explicitly whitelisted
      # for any configuration, it is implicitly whitelisted.
      #
      # @param  [String] pod_name
      #         The pod that we're querying about inclusion for in the given
      #         configuration.
      #
      # @param  [String] configuration_name
      #         The configuration that we're querying about inclusion of the
      #         pod in.
      #
      # @note   Build configurations are case compared case-insensitively in
      #         CocoaPods.
      #
      # @return [Bool] flag
      #         Whether the pod should be linked with the target
      #
      def pod_whitelisted_for_configuration?(pod_name, configuration_name)
        found = false
        configuration_pod_whitelist.each do |configuration, pods|
          if pods.include?(pod_name)
            found = true
            if configuration.downcase == configuration_name.to_s.downcase
              return true
            end
          end
        end
        !found && (root? || (inheritance != 'none' && parent.pod_whitelisted_for_configuration?(pod_name, configuration_name)))
      end

      # Whitelists a pod for a specific configuration. If a pod is whitelisted
      # for any configuration, it will only be linked with the target in the
      # configuration(s) specified. If it is not whitelisted for any
      # configuration, it is implicitly included in all configurations.
      #
      # @param  [String] pod_name
      #         The pod that should be included in the given configuration.
      #
      # @param  [String, Symbol] configuration_name
      #         The configuration that the pod should be included in
      #
      # @note   Build configurations are stored as a String.
      #
      # @return [void]
      #
      def whitelist_pod_for_configuration(pod_name, configuration_name)
        configuration_name = configuration_name.to_s
        list = raw_configuration_pod_whitelist[configuration_name] ||= []
        list << pod_name
      end

      # @return [Array<String>] unique list of all configurations for which
      #         pods have been whitelisted.
      #
      def all_whitelisted_configurations
        parent_configurations = (root? || inheritance == 'none') ? [] : parent.all_whitelisted_configurations
        (configuration_pod_whitelist.keys + parent_configurations).uniq
      end

      #--------------------------------------#

      PLATFORM_DEFAULTS = { :ios => '4.3', :osx => '10.6', :tvos => '9.0', :watchos => '2.0' }.freeze

      # @return [Platform] the platform of the target definition.
      #
      # @note   If no deployment target has been specified a default value is
      #         provided.
      #
      def platform
        name_or_hash = get_hash_value('platform')
        if name_or_hash
          if name_or_hash.is_a?(Hash)
            name = name_or_hash.keys.first.to_sym
            target = name_or_hash.values.first
          else
            name = name_or_hash.to_sym
          end
          target ||= PLATFORM_DEFAULTS[name]
          Platform.new(name, target)
        else
          parent.platform unless root?
        end
      end

      # Sets the platform of the target definition.
      #
      # @param  [Symbol] name
      #         The name of the platform.
      #
      # @param  [String] target
      #         The deployment target of the platform.
      #
      # @raise  When the name of the platform is unsupported.
      #
      # @return [void]
      #
      def set_platform(name, target = nil)
        unless [:ios, :osx, :tvos, :watchos].include?(name)
          raise StandardError, "Unsupported platform `#{name}`. Platform " \
            'must be `:ios`, `:osx`, `:tvos`, or `:watchos`.'
        end

        if target
          value = { name.to_s => target }
        else
          value = name.to_s
        end
        set_hash_value('platform', value)
      end

      #--------------------------------------#

      # Stores the dependency for a Pod with the given name.
      #
      # @param  [String] name
      #         The name of the Pod
      #
      # @param  [Array<String, Hash>] requirements
      #         The requirements and the options of the dependency.
      #
      # @note   The dependencies are stored as an array. To simplify the YAML
      #         representation if they have requirements they are represented
      #         as a Hash, otherwise only the String of the name is added to
      #         the array.
      #
      # @todo   This needs urgently a rename.
      #
      # @return [void]
      #
      def store_pod(name, *requirements)
        return if parse_subspecs(name, requirements) # This parse method must be called first
        parse_inhibit_warnings(name, requirements)
        parse_configuration_whitelist(name, requirements)

        if requirements && !requirements.empty?
          pod = { name => requirements }
        else
          pod = name
        end

        get_hash_value('dependencies', []) << pod
        nil
      end

      #--------------------------------------#

      # Stores the podspec whose dependencies should be included by the
      # target.
      #
      # @param  [Hash] options
      #         The options used to find the podspec (either by name or by
      #         path). If nil the podspec is auto-detected (i.e. the first one
      #         in the folder of the Podfile)
      #
      # @note   The storage of this information is optimized for YAML
      #         readability.
      #
      # @todo   This urgently needs a rename.
      #
      # @return [void]
      #
      def store_podspec(options = nil)
        if options
          unless options.keys.all? { |key| [:name, :path].include?(key) }
            raise StandardError, 'Unrecognized options for the podspec ' \
              "method `#{options}`"
          end
          get_hash_value('podspecs', []) << options
        else
          get_hash_value('podspecs', []) << { :autodetect => true }
        end
      end

      #-----------------------------------------------------------------------#

      public

      # @!group Representations

      # @return [Array] The keys used by the hash representation of the
      #         target definition.
      #
      HASH_KEYS = %w(
        name
        platform
        podspecs
        exclusive
        link_with
        link_with_first_target
        inhibit_warnings
        user_project_path
        build_configurations
        dependencies
        children
        configuration_pod_whitelist
        uses_frameworks
        inheritance
        abstract
      ).freeze

      # @return [Hash] The hash representation of the target definition.
      #
      def to_hash
        hash = internal_hash.dup
        unless children.empty?
          hash['children'] = children.map(&:to_hash)
        end
        hash
      end

      # Configures a new target definition from the given hash.
      #
      # @param  [Hash] the hash which contains the information of the
      #         Podfile.
      #
      # @return [TargetDefinition] the new target definition
      #
      def self.from_hash(hash, parent)
        internal_hash = hash.dup
        children_hashes = internal_hash.delete('children') || []
        definition = TargetDefinition.new(nil, parent, internal_hash)
        children_hashes.each do |child_hash|
          TargetDefinition.from_hash(child_hash, definition)
        end
        definition
      end

      #-----------------------------------------------------------------------#

      private

      # @!group Private helpers

      # @return [Array<TargetDefinition>]
      #
      attr_writer :children

      # @return [Hash] The hash which store the attributes of the target
      #         definition.
      #
      attr_accessor :internal_hash

      # Set a value in the internal hash of the target definition for the given
      # key.
      #
      # @param  [String] key
      #         The key for which to store the value.
      #
      # @param  [Object] value
      #         The value to store.
      #
      # @raise  [StandardError] If the key is not recognized.
      #
      # @return [void]
      #
      def set_hash_value(key, value)
        unless HASH_KEYS.include?(key)
          raise StandardError, "Unsupported hash key `#{key}`"
        end
        internal_hash[key] = value
      end

      # Returns the value for the given key in the internal hash of the target
      # definition.
      #
      # @param  [String] key
      #         The key for which the value is needed.
      #
      # @param  [Object] base_value
      #         The value to set if they key is nil. Useful for collections.
      #
      # @raise  [StandardError] If the key is not recognized.
      #
      # @return [Object] The value for the key.
      #
      def get_hash_value(key, base_value = nil)
        unless HASH_KEYS.include?(key)
          raise StandardError, "Unsupported hash key `#{key}`"
        end
        internal_hash[key] = base_value if internal_hash[key].nil?
        internal_hash[key]
      end

      def raw_inhibit_warnings_hash
        get_hash_value('inhibit_warnings', {})
      end
      private :raw_inhibit_warnings_hash

      # Returns the inhibit_warnings hash pre-populated with default values.
      #
      # @return [Hash<String, Array>] Hash with :all key for inhibiting all
      #         warnings, :for_pods key for inhibiting warnings per Pod,
      #         and :not_for_pods key for not inhibiting warnings per Pod.
      #
      def inhibit_warnings_hash
        inhibit_hash = raw_inhibit_warnings_hash
        if exclusive?
          inhibit_hash
        else
          parent_hash = parent.send(:inhibit_warnings_hash).dup
          if parent_hash['not_for_pods']
            # Remove pods that are set to not inhibit inside parent if they are set to inhibit inside current target.
            parent_hash['not_for_pods'] -= Array(inhibit_hash['for_pods'])
          end
          if parent_hash['for_pods']
            # Remove pods that are set to inhibit inside parent if they are set to not inhibit inside current target.
            parent_hash['for_pods'] -= Array(inhibit_hash['for_pods'])
          end
          if inhibit_hash['all']
            # Clean pods that are set to not inhibit inside parent if inhibit_all_warnings! was set.
            parent_hash['not_for_pods'] = nil
          end
          parent_hash.merge(inhibit_hash) do |_, l, r|
            Array(l).concat(r).uniq
          end
        end
      end

      def raw_configuration_pod_whitelist
        get_hash_value('configuration_pod_whitelist', {})
      end
      private :raw_configuration_pod_whitelist

      # Returns the configuration_pod_whitelist hash
      #
      # @return [Hash<String, Array>] Hash with configuration name as key,
      #         array of pod names to be linked in builds with that configuration
      #         as value.
      #
      def configuration_pod_whitelist
        whitelist_hash = raw_configuration_pod_whitelist
        if exclusive?
          whitelist_hash
        else
          parent.send(:configuration_pod_whitelist).merge(whitelist_hash) { |l, r| (l + r).uniq }
        end
      end

      # @return [Array<Dependency>] The dependencies specified by the user for
      #         this target definition.
      #
      def pod_dependencies
        pods = get_hash_value('dependencies') || []
        pods.map do |name_or_hash|
          if name_or_hash.is_a?(Hash)
            name = name_or_hash.keys.first
            requirements = name_or_hash.values.first
            Dependency.new(name, *requirements)
          else
            Dependency.new(name_or_hash)
          end
        end
      end

      # @return [Array<Dependency>] The dependencies inherited by the podspecs.
      #
      # @note   The podspec directive is intended to include the dependencies of
      #         a spec in the project where it is developed. For this reason the
      #         spec, or any of it subspecs, cannot be included in the
      #         dependencies. Otherwise it would generate a chicken-and-egg
      #         problem.
      #
      def podspec_dependencies
        podspecs = get_hash_value('podspecs') || []
        podspecs.map do |options|
          file = podspec_path_from_options(options)
          spec = Specification.from_file(file)
          all_specs = [spec, *spec.recursive_subspecs]
          all_deps = all_specs.map { |s| s.dependencies(platform) }.flatten
          all_deps.reject { |dep| dep.root_name == spec.root.name }
        end.flatten.uniq
      end

      # The path of the podspec with the given options.
      #
      # @param  [Hash] options
      #         The options to use for finding the podspec. The supported keys
      #         are: `:name`, `:path`, `:autodetect`.
      #
      # @return [Pathname] The path.
      #
      def podspec_path_from_options(options)
        if path = options[:path]
          if File.basename(path).include?('.podspec')
            path_with_ext = path
          else
            path_with_ext = "#{path}.podspec"
          end
          path_without_tilde = path_with_ext.gsub('~', ENV['HOME'])
          podfile.defined_in_file.dirname + path_without_tilde
        elsif name = options[:name]
          name = File.basename(name).include?('.podspec') ? name : "#{name}.podspec"
          podfile.defined_in_file.dirname + name
        elsif options[:autodetect]
          glob_pattern = podfile.defined_in_file.dirname + '*.podspec{,.json}'
          path = Pathname.glob(glob_pattern).first
          unless path
            raise Informative, 'Could not locate a podspec in the current directory. '\
              'You can specify the path via the path option.'
          end

          path
        end
      end

      # Removes :inhibit_warnings from the requirements list, and adds
      # the pod's name into internal hash for disabling warnings.
      #
      # @param [String] pod name
      #
      # @param [Array] requirements
      #        If :inhibit_warnings is the only key in the hash, the hash
      #        should be destroyed because it confuses Gem::Dependency.
      #
      # @return [void]
      #
      def parse_inhibit_warnings(name, requirements)
        options = requirements.last
        return requirements unless options.is_a?(Hash)

        should_inhibit = options.delete(:inhibit_warnings)
        pod_name = Specification.root_name(name)
        set_inhibit_warnings_for_pod(pod_name, should_inhibit)

        requirements.pop if options.empty?
      end

      # Removes :configurations or :configuration from the requirements list,
      # and adds the pod's name into the internal hash for which pods should be
      # linked in which configuration only.
      #
      # @param [String] pod name
      #
      # @param [Array] requirements
      #        If :configurations is the only key in the hash, the hash
      #        should be destroyed because it confuses Gem::Dependency.
      #
      # @return [void]
      #
      def parse_configuration_whitelist(name, requirements)
        options = requirements.last
        return requirements unless options.is_a?(Hash)

        configurations = options.delete(:configurations)
        configurations ||= options.delete(:configuration)
        Array(configurations).each do |configuration|
          whitelist_pod_for_configuration(name, configuration)
        end
        requirements.pop if options.empty?
      end

      # Removes :subspecs from the requirements list, and stores the pods
      # with the given subspecs as dependencies.
      #
      # @param  [String] name
      #
      # @param  [Array] requirements
      #         If :subspecs is the only key in the hash, the hash
      #         should be destroyed because it confuses Gem::Dependency.
      #
      # @return [Boolean] Whether new subspecs were added
      #
      def parse_subspecs(name, requirements)
        options = requirements.last
        return false unless options.is_a?(Hash)

        subspecs = options.delete(:subspecs)
        subspecs.each do |ss|
          store_pod("#{name}/#{ss}", *requirements.dup)
        end if subspecs
        requirements.pop if options.empty?
        !subspecs.nil?
      end

      #-----------------------------------------------------------------------#
    end
  end
end
