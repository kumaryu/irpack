
require 'pathname'

module IRPack
  class Specification
    # Generated exe file path (default is entry_file replaced extention by '.exe').
    attr_accessor :output_file
    # Path of entry script.
    attr_accessor :entry_file
    # Array of files to embed, or Hash maps runtime paths to real files.
    attr_accessor :files
    # Base paths stripped from files and entry_file.
    attr_accessor :base_paths
    # Type of generated executable. :exe for console app, :winexe for window app (default is :exe).
    attr_accessor :target
    # True if compress embeded files (default is false).
    attr_accessor :compress
    # True if embed IronRuby assemblies (default is true).
    attr_accessor :embed_assemblies
    # True if embed standard libraries (default is true).
    attr_accessor :embed_stdlibs
    alias complete  embed_stdlibs
    alias complete= embed_stdlibs=
    # Namespace of entry point. 
    attr_accessor :module_name
    # RuntimeOptions passed to script engine.
    attr_reader :runtime_options

    # Options to script engine passed in runtime.
    class RuntimeOptions
      # True if emit debugging information (PDBs) for Visual Studio debugger (default is false).
      attr_accessor :debug_mode
      # True if disable adaptive compilation (default is false).
      attr_accessor :no_adaptive_compilation
      # The number of iterations before the interpreter starts compiling (default is 32).
      attr_accessor :compilation_threshold
      # True if enable ExceptionDetail mode (default is false).
      attr_accessor :exception_detail
      # True if display CLS Exception information (default is false).
      attr_accessor :show_clr_exceptions
      # Warning level; 0=silence, 1=medium (default), 2=verbose.
      attr_accessor :warning_level
      # Debugging flags ($DEBUG) (default is false).
      attr_accessor :debug_variable
      # True if enable support for IronRuby::Clr.profile (default is false).
      attr_accessor :profile
      # True if enable support for set_trace_func (default is false).
      attr_accessor :trace
      # Required libraries before executing entry_file.
      attr_accessor :required_paths
      # $LOAD_PATH directories.
      attr_accessor :search_paths
      # True if do not catch exceptions that are unhandled by script code.
      attr_accessor :pass_exceptions
      # True if enable binding to private members.
      attr_accessor :private_binding
      alias d  debug_variable
      alias d= debug_variable=
      alias r  required_paths
      alias r= required_paths=
      alias I  search_paths
      alias I= search_paths=
      alias D  debug_mode
      alias D= debug_mode=
      alias W  warning_level
      alias W= warning_level=
      def initialize
        @debug_mode = false
        @no_adaptive_compilation = false
        @compilation_threshold = -1
        @exception_detail = false
        @show_clr_exceptions = false
        @warning_level = 1
        @debug_variable = false
        @profile = false
        @trace = false
        @required_paths = []
        @search_paths = []
        @pass_exceptions = false
        @private_binding = false
      end

      def to_hash
        {
          DebugMode:             @debug_mode,
          PrivateBinding:        @private_binding,
          NoAdaptiveCompilation: @no_adaptive_compilation,
          CompilationThreshold:  @compilation_threshold,
          ExceptionDetail:       @exception_detail,
          ShowClrExceptions:     @show_clr_exceptions,
          PassExceptions:        @pass_exceptions,
          Profile:               @profile,
          Verbosity:             @warning_level,
          DebugVariable:         @debug_variable,
          EnableTracing:         @trace,
          RequiredPaths:         @required_paths,
          SearchPaths:           @search_paths,
        }
      end
    end

    def initialize
      @output_file = nil
      @entry_file  = nil
      @module_name = nil
      @files       = []
      @base_paths  = []
      @compress    = false
      @target      = :exe
      @embed_assemblies = true
      @embed_stdlibs    = false
      @runtime_options = RuntimeOptions.new
      yield self if block_given?
    end

    # Return entry file path at runtime.
    def map_entry
      raise ArgumentError, "No entry file specified" unless @entry_file
      base_paths = @base_paths.collect {|path| Pathname.new(path).expand_path }
      (strip_path(base_paths, @entry_file) || @entry_file).to_s
    end
    
    # Map runtime file path to real files.  
    def map_files
      file_map = {}
      entry_file = Pathname.new(map_entry)
      entry_found = false
      case @files
      when Hash
        @files.each do |path, file|
          file_map[path.to_s] = File.expand_path(file.to_s)
          entry_found = true if path.to_s==entry_file.to_s
        end
      else
        base_paths = @base_paths.collect {|path| Pathname.new(path).expand_path }
        @files.each do |fn|
          next unless fn
          relpath = strip_path(base_paths, fn) || fn
          file_map[relpath.to_s] = File.expand_path(fn.to_s)
          entry_found = true if relpath==entry_file
        end
      end
      file_map[entry_file.to_s] = File.expand_path(@entry_file.to_s) unless entry_found
      file_map
    end

    def strip_path(base_paths, path)
      fullpath = Pathname.new(path).expand_path
      base_paths.collect {|base|
        if /\A#{Regexp.escape(base.to_s)}/=~fullpath.to_s then
          fullpath.relative_path_from(base)
        else
          nil
        end
      }.compact.sort_by {|path| path.to_s.size }.first
    end
    private :strip_path
  end
end

