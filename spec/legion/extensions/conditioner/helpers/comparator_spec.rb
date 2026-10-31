# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/conditioner/helpers/comparator'

RSpec.describe Legion::Extensions::Conditioner::Comparator do
  let(:values) do
    {
      'status'   => 200,
      'count'    => 5,
      'zero'     => 0,
      'name'     => 'test',
      'greeting' => 'hello world',
      'blank'    => '',
      'items'    => [1, 2],
      'tags'     => %w[bug feature],
      'flag'     => true,
      'empty'    => nil
    }
  end

  # ── Existing operators ────────────────────────────────────────────────────

  describe '.equal?' do
    it 'returns true when fact matches value' do
      expect(described_class.equal?(fact: 'status', value: 200, values: values)).to eq(true)
    end

    it 'returns false when fact does not match' do
      expect(described_class.equal?(fact: 'status', value: 404, values: values)).to eq(false)
    end

    it 'handles string comparison' do
      expect(described_class.equal?(fact: 'name', value: 'test', values: values)).to eq(true)
    end
  end

  describe '.not_equal?' do
    it 'returns true when fact does not match value' do
      expect(described_class.not_equal?(fact: 'status', value: 404, values: values)).to eq(true)
    end

    it 'returns false when fact matches' do
      expect(described_class.not_equal?(fact: 'status', value: 200, values: values)).to eq(false)
    end
  end

  describe '.nil?' do
    it 'returns true when fact is nil' do
      expect(described_class.nil?(fact: 'empty', values: values)).to eq(true)
    end

    it 'returns true when fact does not exist' do
      expect(described_class.nil?(fact: 'nonexistent', values: values)).to eq(true)
    end

    it 'returns false when fact has a value' do
      expect(described_class.nil?(fact: 'name', values: values)).to eq(false)
    end
  end

  describe '.not_nil?' do
    it 'returns true when fact has a value' do
      expect(described_class.not_nil?(fact: 'name', values: values)).to eq(true)
    end

    it 'returns false when fact is nil' do
      expect(described_class.not_nil?(fact: 'empty', values: values)).to eq(false)
    end
  end

  describe '.true?' do
    it 'returns truthy when fact is true' do
      expect(described_class.true?(fact: 'flag', values: values)).to be_truthy
    end

    it 'returns falsey when fact is nil' do
      expect(described_class.true?(fact: 'empty', values: values)).to be_falsey
    end
  end

  describe '.false?' do
    it 'returns true when fact is falsey' do
      expect(described_class.false?(fact: 'empty', values: values)).to eq(true)
    end

    it 'returns false when fact is truthy' do
      expect(described_class.false?(fact: 'flag', values: values)).to eq(false)
    end
  end

  describe '.array?' do
    it 'returns true when fact is an array' do
      expect(described_class.array?(fact: 'items', values: values)).to eq(true)
    end

    it 'returns false when fact is not an array' do
      expect(described_class.array?(fact: 'name', values: values)).to eq(false)
    end
  end

  describe '.string?' do
    it 'returns true when fact is a string' do
      expect(described_class.string?(fact: 'name', values: values)).to eq(true)
    end

    it 'returns false when fact is not a string' do
      expect(described_class.string?(fact: 'status', values: values)).to eq(false)
    end
  end

  describe '.integer?' do
    it 'returns true when fact is an integer' do
      expect(described_class.integer?(fact: 'count', values: values)).to eq(true)
    end

    it 'returns false when fact is not an integer' do
      expect(described_class.integer?(fact: 'name', values: values)).to eq(false)
    end
  end

  # ── Numeric operators ─────────────────────────────────────────────────────

  describe '.greater_than?' do
    it 'returns true when fact is greater than value' do
      expect(described_class.greater_than?(fact: 'status', value: 100, values: values)).to eq(true)
    end

    it 'returns false when fact equals value' do
      expect(described_class.greater_than?(fact: 'status', value: 200, values: values)).to eq(false)
    end

    it 'returns false when fact is less than value' do
      expect(described_class.greater_than?(fact: 'count', value: 10, values: values)).to eq(false)
    end
  end

  describe '.less_than?' do
    it 'returns true when fact is less than value' do
      expect(described_class.less_than?(fact: 'count', value: 10, values: values)).to eq(true)
    end

    it 'returns false when fact equals value' do
      expect(described_class.less_than?(fact: 'count', value: 5, values: values)).to eq(false)
    end

    it 'returns false when fact is greater than value' do
      expect(described_class.less_than?(fact: 'status', value: 100, values: values)).to eq(false)
    end
  end

  describe '.greater_or_equal?' do
    it 'returns true when fact equals value' do
      expect(described_class.greater_or_equal?(fact: 'status', value: 200, values: values)).to eq(true)
    end

    it 'returns true when fact is greater than value' do
      expect(described_class.greater_or_equal?(fact: 'status', value: 100, values: values)).to eq(true)
    end

    it 'returns false when fact is less than value' do
      expect(described_class.greater_or_equal?(fact: 'count', value: 10, values: values)).to eq(false)
    end
  end

  describe '.less_or_equal?' do
    it 'returns true when fact equals value' do
      expect(described_class.less_or_equal?(fact: 'count', value: 5, values: values)).to eq(true)
    end

    it 'returns true when fact is less than value' do
      expect(described_class.less_or_equal?(fact: 'count', value: 10, values: values)).to eq(true)
    end

    it 'returns false when fact is greater than value' do
      expect(described_class.less_or_equal?(fact: 'status', value: 100, values: values)).to eq(false)
    end
  end

  describe '.between?' do
    it 'returns true when fact is within inclusive range' do
      expect(described_class.between?(fact: 'status', value: [100, 300], values: values)).to eq(true)
    end

    it 'returns true when fact equals lower bound' do
      expect(described_class.between?(fact: 'status', value: [200, 300], values: values)).to eq(true)
    end

    it 'returns true when fact equals upper bound' do
      expect(described_class.between?(fact: 'status', value: [100, 200], values: values)).to eq(true)
    end

    it 'returns false when fact is below range' do
      expect(described_class.between?(fact: 'count', value: [10, 20], values: values)).to eq(false)
    end

    it 'returns false when fact is above range' do
      expect(described_class.between?(fact: 'count', value: [0, 4], values: values)).to eq(false)
    end
  end

  # ── String operators ──────────────────────────────────────────────────────

  describe '.contains?' do
    it 'returns true when string contains substring' do
      expect(described_class.contains?(fact: 'greeting', value: 'hello', values: values)).to eq(true)
    end

    it 'returns false when string does not contain substring' do
      expect(described_class.contains?(fact: 'greeting', value: 'bye', values: values)).to eq(false)
    end

    it 'coerces fact to string' do
      expect(described_class.contains?(fact: 'status', value: '20', values: values)).to eq(true)
    end
  end

  describe '.starts_with?' do
    it 'returns true when string starts with prefix' do
      expect(described_class.starts_with?(fact: 'greeting', value: 'hello', values: values)).to eq(true)
    end

    it 'returns false when string does not start with prefix' do
      expect(described_class.starts_with?(fact: 'greeting', value: 'world', values: values)).to eq(false)
    end

    it 'coerces fact to string' do
      expect(described_class.starts_with?(fact: 'status', value: '2', values: values)).to eq(true)
    end
  end

  describe '.ends_with?' do
    it 'returns true when string ends with suffix' do
      expect(described_class.ends_with?(fact: 'greeting', value: 'world', values: values)).to eq(true)
    end

    it 'returns false when string does not end with suffix' do
      expect(described_class.ends_with?(fact: 'greeting', value: 'hello', values: values)).to eq(false)
    end

    it 'coerces fact to string' do
      expect(described_class.ends_with?(fact: 'status', value: '00', values: values)).to eq(true)
    end
  end

  describe '.matches?' do
    it 'returns true when fact matches regex pattern' do
      expect(described_class.matches?(fact: 'greeting', value: 'hello.*world', values: values)).to eq(true)
    end

    it 'returns false when fact does not match regex pattern' do
      expect(described_class.matches?(fact: 'greeting', value: '^world', values: values)).to eq(false)
    end

    it 'handles digit patterns' do
      expect(described_class.matches?(fact: 'status', value: '^\d+$', values: values)).to eq(true)
    end
  end

  # ── Collection operators ──────────────────────────────────────────────────

  describe '.in_set?' do
    it 'returns true when fact is in the array value' do
      expect(described_class.in_set?(fact: 'status', value: [200, 201, 204], values: values)).to eq(true)
    end

    it 'returns false when fact is not in the array value' do
      expect(described_class.in_set?(fact: 'status', value: [400, 404, 500], values: values)).to eq(false)
    end

    it 'wraps scalar value in array' do
      expect(described_class.in_set?(fact: 'status', value: 200, values: values)).to eq(true)
    end
  end

  describe '.not_in_set?' do
    it 'returns true when fact is not in the array value' do
      expect(described_class.not_in_set?(fact: 'status', value: [400, 404, 500], values: values)).to eq(true)
    end

    it 'returns false when fact is in the array value' do
      expect(described_class.not_in_set?(fact: 'status', value: [200, 201], values: values)).to eq(false)
    end

    it 'wraps scalar value in array' do
      expect(described_class.not_in_set?(fact: 'status', value: 404, values: values)).to eq(true)
    end
  end

  describe '.empty?' do
    it 'returns true when fact is nil' do
      expect(described_class.empty?(fact: 'empty', values: values)).to eq(true)
    end

    it 'returns true when fact is a blank string' do
      expect(described_class.empty?(fact: 'blank', values: values)).to eq(true)
    end

    it 'returns false when fact is a non-empty string' do
      expect(described_class.empty?(fact: 'name', values: values)).to eq(false)
    end

    it 'returns false when fact is a non-empty array' do
      expect(described_class.empty?(fact: 'items', values: values)).to eq(false)
    end

    it 'returns true when fact is an empty array' do
      vals = values.merge('arr' => [])
      expect(described_class.empty?(fact: 'arr', values: vals)).to eq(true)
    end
  end

  describe '.not_empty?' do
    it 'returns true when fact is a non-empty string' do
      expect(described_class.not_empty?(fact: 'name', values: values)).to eq(true)
    end

    it 'returns true when fact is a non-empty array' do
      expect(described_class.not_empty?(fact: 'items', values: values)).to eq(true)
    end

    it 'returns false when fact is nil' do
      expect(described_class.not_empty?(fact: 'empty', values: values)).to eq(false)
    end

    it 'returns false when fact is a blank string' do
      expect(described_class.not_empty?(fact: 'blank', values: values)).to eq(false)
    end
  end

  describe '.size_equal?' do
    it 'returns true when array size matches value' do
      expect(described_class.size_equal?(fact: 'items', value: 2, values: values)).to eq(true)
    end

    it 'returns false when array size does not match' do
      expect(described_class.size_equal?(fact: 'items', value: 5, values: values)).to eq(false)
    end

    it 'returns true when string length matches value' do
      expect(described_class.size_equal?(fact: 'name', value: 4, values: values)).to eq(true)
    end

    it 'returns false when object does not respond to size' do
      expect(described_class.size_equal?(fact: 'status', value: 3, values: values)).to eq(false)
    end
  end
end
