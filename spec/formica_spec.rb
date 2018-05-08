# frozen_string_literal: true

RSpec.describe Formica do
  let(:config_class) do
    described_class.define_config do
      option attr_name: :first_name,
             default: -> { 'Samuel' },
             depends_on: [],
             validate: ->(name) { name != 'Donald' }

      option attr_name: :last_name,
             default: -> { 'Giddins' },
             depends_on: [],
             validate: ->(name) { name != 'Trump' }

      option attr_name: :full_name,
             default: -> { [first_name, last_name].join(' ') },
             depends_on: %i[first_name last_name],
             coerce: ->(name) { name.to_s },
             validate: ->(name) { !name.strip.empty? }
    end
  end

  let(:args) { {} }
  subject(:config) { config_class.new(args) }

  it 'sets the config values on the class' do
    expect(config_class.options.keys).to contain_exactly(:first_name, :last_name, :full_name)
  end

  it 'initializes without setting any properties' do
    expect(config.to_h).to eq({})
  end

  it 'allows forcing initialization of defaults' do
    expect(config.force!.to_h).to eq(
      first_name: 'Samuel',
      last_name: 'Giddins',
      full_name: 'Samuel Giddins'
    )
  end

  it 'allows creating a new object with changes' do
    changed = config.with_changes(first_name: 'Foo', last_name: 'T')
    expect(config).not_to eq changed
    expect(config.to_h).to eq({})
    expect(changed.to_h).to eq(
      first_name: 'Foo',
      last_name: 'T'
    )
    expect(changed.force!.to_h).to eq(
      first_name: 'Foo',
      last_name: 'T',
      full_name: 'Foo T'
    )
  end

  it 'runs the validation blocks' do
    expect { config.with_changes(last_name: 'Trump') }
      .to raise_error(RuntimeError, %(invalid value "Trump" for option last_name in #{config}))
  end
end
