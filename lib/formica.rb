# frozen_string_literal: true

module Formica
  VERSION = File.read(File.expand_path('../VERSION', __dir__)).strip

  Option = Struct.new(:attr_name, :default, :depends_on, :validate, :coerce) do
    def define_on(config_class)
      name = attr_name
      config_class.send :define_method, name do
        option = @options[name]
        if option.defined
          option.value
        else
          # evaluate all dependencies first, to help ensure we don't have to write default
          # blocks that clean up after themselves
          option.option.depends_on.each do |attr_name|
            public_send(attr_name)
          end
          option.defined = true
          default = instance_exec(&option.option.default)
          default = option.validate!(default, self)
          option.value = default
        end
      end
    end
  end

  class Config
    Option = Struct.new(:option, :defined, :value) do
      def validate!(value, config)
        value = option.coerce[value] if option.coerce
        return value unless option.validate
        unless instance_exec(value, &option.validate)
          raise("invalid value #{value.inspect} for option #{option.attr_name} in #{config}")
        end
        value
      end
    end

    def initialize(values = {})
      @options = self.class.options.map { |n, o| [n, Option.new(o, false)] }.to_h
      update!(values)
    end

    def to_s
      "<#{self.class} #{to_h}>"
    end

    def to_h
      Hash[@options.map { |_, o| [o.option.attr_name, o.value] if o.defined }.compact]
    end

    def force!
      @options.each { |_, o| public_send(o.option.attr_name) }
      self
    end

    def self.validate_dependencies!
      require 'tsort'

      each_node = ->(&b) { options.each_key(&b) }
      each_child = ->(n, &b) { options[n].depends_on.each(&b) }
      TSort.tsort each_node, each_child
    rescue TSort::Cyclic => e
      raise "Some options have a circular dependency: #{e}"
    end

    def with_changes(changes)
      self.class.new(**to_h.merge(changes))
    end

    def update!(values)
      values.each do |k, v|
        option = @options[k] || raise(KeyError, "No option `#{k}` in #{self}")
        v = option.validate!(v, self)
        option.defined = true
        option.value = v
      end
    end
  end

  def self.define_config(&blk)
    dsl = DSL.new
    dsl.instance_exec(&blk)
    Class.new(Config) do
      class << self; attr_reader :options; end
      @options = dsl.options.each_with_object({}) { |o, h| h[o.attr_name] = o.freeze }.freeze

      options.each { |_, o| o.define_on(self) }

      validate_dependencies!
    end
  end

  class DSL
    attr_reader :options

    def initialize
      @options = []
    end

    def option(**kwargs)
      @options << ::Formica::Option.new(*kwargs.values_at(*::Formica::Option.members))
    end
  end
end
