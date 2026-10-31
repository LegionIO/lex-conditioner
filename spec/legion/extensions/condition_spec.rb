# frozen_string_literal: true

require 'spec_helper'
require 'legion/json'
require 'legion/extensions/conditioner/helpers/condition'

RSpec.describe Legion::Extensions::Conditioner::Condition do
  describe '#valid? with all conditions' do
    it 'returns true when all conditions pass' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [
                                        { fact: 'status', operator: 'equal', value: 200 },
                                        { fact: 'name', operator: 'equal', value: 'test' }
                                      ] }),
        values:     { status: 200, name: 'test' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'returns false when any condition in all fails' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [
                                        { fact: 'status', operator: 'equal', value: 200 },
                                        { fact: 'name', operator: 'equal', value: 'wrong' }
                                      ] }),
        values:     { status: 200, name: 'test' }
      )
      expect(cond.valid?).to eq(false)
    end
  end

  describe '#valid? with any conditions' do
    it 'returns true when at least one condition passes' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ any: [
                                        { fact: 'status', operator: 'equal', value: 404 },
                                        { fact: 'name', operator: 'equal', value: 'test' }
                                      ] }),
        values:     { status: 200, name: 'test' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'returns false when no conditions pass' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ any: [
                                        { fact: 'status', operator: 'equal', value: 404 },
                                        { fact: 'name', operator: 'equal', value: 'wrong' }
                                      ] }),
        values:     { status: 200, name: 'test' }
      )
      expect(cond.valid?).to eq(false)
    end
  end

  describe '#valid? with not_equal operator' do
    it 'returns true when values differ' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [
                                        { fact: 'status', operator: 'not_equal', value: 404 }
                                      ] }),
        values:     { status: 200 }
      )
      expect(cond.valid?).to eq(true)
    end
  end

  describe '#valid? with unary operators' do
    it 'handles nil operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'missing', operator: 'nil' }] }),
        values:     { other: 'value' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles not_nil operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'name', operator: 'not_nil' }] }),
        values:     { name: 'present' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles is_string operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'name', operator: 'is_string' }] }),
        values:     { name: 'hello' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles is_integer operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'count', operator: 'is_integer' }] }),
        values:     { count: 42 }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'preserves arrays as facts' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'items', operator: 'is_array' }] }),
        values:     { items: [1, 2, 3] }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles is_true operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'flag', operator: 'is_true' }] }),
        values:     { flag: true }
      )
      expect(cond.valid?).to be_truthy
    end

    it 'handles is_false operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'flag', operator: 'is_false' }] }),
        values:     { flag: nil }
      )
      expect(cond.valid?).to eq(true)
    end
  end

  describe '#valid? with nested conditions' do
    it 'handles nested all within any' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ any: [
                                        { all: [
                                          { fact: 'a', operator: 'equal', value: 1 },
                                          { fact: 'b', operator: 'equal', value: 2 }
                                        ] }
                                      ] }),
        values:     { a: 1, b: 2 }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'returns false when nested all fails' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ any: [
                                        { all: [
                                          { fact: 'a', operator: 'equal', value: 1 },
                                          { fact: 'b', operator: 'equal', value: 99 }
                                        ] }
                                      ] }),
        values:     { a: 1, b: 2 }
      )
      expect(cond.valid?).to eq(false)
    end

    it 'handles nested any within all' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [
                                        { any: [
                                          { fact: 'x', operator: 'equal', value: 10 },
                                          { fact: 'y', operator: 'equal', value: 20 }
                                        ] }
                                      ] }),
        values:     { x: 99, y: 20 }
      )
      expect(cond.valid?).to eq(true)
    end
  end

  describe '#valid? with dotted fact paths' do
    it 'evaluates against flattened nested values' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [
                                        { fact: 'response.code', operator: 'equal', value: 200 }
                                      ] }),
        values:     { response: { code: 200 } }
      )
      expect(cond.valid?).to eq(true)
    end
  end

  describe '#valid? with numeric operators' do
    it 'handles greater_than operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'score', operator: 'greater_than', value: 50 }] }),
        values:     { score: 75 }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'returns false for greater_than when equal' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'score', operator: 'greater_than', value: 75 }] }),
        values:     { score: 75 }
      )
      expect(cond.valid?).to eq(false)
    end

    it 'handles less_than operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'count', operator: 'less_than', value: 10 }] }),
        values:     { count: 3 }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles greater_or_equal operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'status', operator: 'greater_or_equal', value: 200 }] }),
        values:     { status: 200 }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles less_or_equal operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'count', operator: 'less_or_equal', value: 5 }] }),
        values:     { count: 5 }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles between operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'status', operator: 'between', value: [200, 299] }] }),
        values:     { status: 201 }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'returns false for between when out of range' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'status', operator: 'between', value: [200, 299] }] }),
        values:     { status: 404 }
      )
      expect(cond.valid?).to eq(false)
    end
  end

  describe '#valid? with string operators' do
    it 'handles contains operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'message', operator: 'contains', value: 'error' }] }),
        values:     { message: 'critical error occurred' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'returns false for contains when substring absent' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'message', operator: 'contains', value: 'success' }] }),
        values:     { message: 'critical error occurred' }
      )
      expect(cond.valid?).to eq(false)
    end

    it 'handles starts_with operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'path', operator: 'starts_with', value: '/api' }] }),
        values:     { path: '/api/v1/users' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles ends_with operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'filename', operator: 'ends_with', value: '.rb' }] }),
        values:     { filename: 'comparator.rb' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles matches operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'email', operator: 'matches', value: '.+@.+\..+' }] }),
        values:     { email: 'user@example.com' }
      )
      expect(cond.valid?).to eq(true)
    end
  end

  describe '#explain' do
    it 'returns structured explanation for passing all condition' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'status', operator: 'equal', value: 200 }] }),
        values:     { status: 200 }
      )
      result = cond.explain
      expect(result[:valid]).to eq(true)
      expect(result[:group]).to eq(:all)
      expect(result[:rules]).to be_an(Array)
      rule = result[:rules].first
      expect(rule[:fact]).to eq('status')
      expect(rule[:operator]).to eq('equal')
      expect(rule[:value]).to eq(200)
      expect(rule[:actual]).to eq(200)
      expect(rule[:result]).to eq(true)
    end

    it 'returns structured explanation for failing condition' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'status', operator: 'equal', value: 404 }] }),
        values:     { status: 200 }
      )
      result = cond.explain
      expect(result[:valid]).to eq(false)
      rule = result[:rules].first
      expect(rule[:result]).to eq(false)
      expect(rule[:actual]).to eq(200)
    end

    it 'includes all rules even when short-circuiting would stop early' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [
                                        { fact: 'a', operator: 'equal', value: 1 },
                                        { fact: 'b', operator: 'equal', value: 99 },
                                        { fact: 'c', operator: 'equal', value: 3 }
                                      ] }),
        values:     { a: 1, b: 2, c: 3 }
      )
      result = cond.explain
      expect(result[:valid]).to eq(false)
      expect(result[:rules].length).to eq(3)
      expect(result[:rules][0][:result]).to eq(true)
      expect(result[:rules][1][:result]).to eq(false)
      expect(result[:rules][2][:result]).to eq(true)
    end

    it 'handles nested groups with any containing all' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ any: [
                                        { all: [
                                          { fact: 'x', operator: 'equal', value: 1 },
                                          { fact: 'y', operator: 'equal', value: 2 }
                                        ] }
                                      ] }),
        values:     { x: 1, y: 2 }
      )
      result = cond.explain
      expect(result[:valid]).to eq(true)
      expect(result[:group]).to eq(:any)
      nested = result[:rules].first
      expect(nested[:group]).to eq(:all)
      expect(nested[:rules]).to be_an(Array)
      expect(nested[:result]).to eq(true)
    end

    it 'explains unary operators without a value key' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'name', operator: 'not_nil' }] }),
        values:     { name: 'present' }
      )
      result = cond.explain
      rule = result[:rules].first
      expect(rule[:fact]).to eq('name')
      expect(rule[:operator]).to eq('not_nil')
      expect(rule[:result]).to eq(true)
      expect(rule).not_to have_key(:value)
    end

    it 'explains greater_than operator with actual value' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'score', operator: 'greater_than', value: 50 }] }),
        values:     { score: 75 }
      )
      result = cond.explain
      rule = result[:rules].first
      expect(rule[:operator]).to eq('greater_than')
      expect(rule[:actual]).to eq(75)
      expect(rule[:result]).to eq(true)
    end
  end

  describe '#valid? with collection operators' do
    it 'handles in_set operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'env', operator: 'in_set', value: %w[staging production] }] }),
        values:     { env: 'production' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'returns false for in_set when value absent' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'env', operator: 'in_set', value: %w[staging production] }] }),
        values:     { env: 'development' }
      )
      expect(cond.valid?).to eq(false)
    end

    it 'handles not_in_set operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'env', operator: 'not_in_set', value: %w[staging production] }] }),
        values:     { env: 'development' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles empty operator for nil fact' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'missing', operator: 'empty' }] }),
        values:     { other: 'value' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles not_empty operator for present fact' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'name', operator: 'not_empty' }] }),
        values:     { name: 'legion' }
      )
      expect(cond.valid?).to eq(true)
    end

    it 'handles size_equal operator' do
      cond = described_class.new(
        conditions: Legion::JSON.dump({ all: [{ fact: 'label', operator: 'size_equal', value: 4 }] }),
        values:     { label: 'test' }
      )
      expect(cond.valid?).to eq(true)
    end
  end

  describe 'fail-closed evaluation' do
    it 'rejects unknown operators even after an any branch passes' do
      expect do
        described_class.new(conditions: { any: [
                              { fact: 'enabled', operator: 'is_true' },
                              { fact: 'enabled', operator: 'truish' }
                            ] }, values: { enabled: true })
      end.to raise_error(Legion::Extensions::Conditioner::ConfigurationError, /operator/)
    end

    it 'rejects groups with mixed all and any rules' do
      expect do
        described_class.new(conditions: { all: [], any: [] }, values: {})
      end.to raise_error(Legion::Extensions::Conditioner::ConfigurationError, /exactly one/)
    end

    it 'rejects rules without a binary operand' do
      expect do
        described_class.new(conditions: { all: [{ fact: 'enabled', operator: 'equal' }] }, values: { enabled: nil })
      end.to raise_error(Legion::Extensions::Conditioner::ConfigurationError, /requires value/)
    end

    it 'rejects malformed JSON rather than allowing execution' do
      expect do
        described_class.new(conditions: '{invalid', values: {})
      end.to raise_error(Legion::Extensions::Conditioner::ConfigurationError)
    end

    it 'rejects malformed nested rules even after a failed all branch' do
      expect do
        described_class.new(conditions: { all: [{ fact: 'flag', operator: 'is_true' }, nil] }, values: { flag: false })
      end.to raise_error(Legion::Extensions::Conditioner::ConfigurationError, /rule must be a Hash/)
    end

    it 'honors configured operator restrictions' do
      Legion::Settings.loader.settings[:extensions][:conditioner][:allowed_operators][:is_true] = false
      expect do
        described_class.new(conditions: { all: [{ fact: 'flag', operator: 'is_true' }] }, values: { flag: true })
      end.to raise_error(Legion::Extensions::Conditioner::ConfigurationError, /disabled/)
    end

    it 'retains explicit operator denials when defaults are merged again' do
      Legion::Settings.loader.settings[:extensions][:conditioner][:allowed_operators][:matches] = false
      Legion::Settings.merge_settings(:extensions, conditioner: Legion::Extensions::Conditioner.default_settings)
      expect do
        described_class.new(conditions: { all: [{ fact: 'text', operator: 'matches', value: '.*' }] }, values: { text: 'abc' })
      end.to raise_error(Legion::Extensions::Conditioner::ConfigurationError, /disabled/)
    end

    it 'rejects nonboolean permission values instead of treating them as grants' do
      Legion::Settings.loader.settings[:extensions][:conditioner][:allowed_operators][:is_true] = 'false'
      expect do
        described_class.new(conditions: { all: [{ fact: 'flag', operator: 'is_true' }] }, values: { flag: true })
      end.to raise_error(Legion::Extensions::Conditioner::ConfigurationError, /true or false/)
    end

    it 'reports missing truthy facts as false in all groups' do
      condition = described_class.new(conditions: { all: [{ fact: 'missing', operator: 'is_true' }] }, values: {})
      expect(condition.valid?).to be(false)
      expect(condition.explain).to include(valid: false, rules: [include(actual: nil, result: false)])
    end

    it 'uses Ruby truthiness consistently in any groups and explanations' do
      condition = described_class.new(conditions: { any: [{ fact: 'value', operator: 'is_true' }] }, values: { value: 0 })
      expect(condition.valid?).to be(true)
      expect(condition.explain).to include(valid: true, rules: [include(actual: 0, result: true)])
    end

    it 'supports collection facts and indexed children without flattening containers' do
      condition = described_class.new(conditions: { all: [
                                        { fact: 'items', operator: 'is_array' },
                                        { fact: 'items', operator: 'size_equal', value: 2 },
                                        { fact: 'items.0.active', operator: 'is_true' },
                                        { fact: 'options', operator: 'equal', value: {} },
                                        { fact: 'options', operator: 'empty' }
                                      ] }, values: { items: [{ active: true }, { active: false }], options: {} })
      expect(condition.valid?).to be(true)
      expect(condition.explain[:rules].map { |rule| rule[:actual] }).to eq(
        [[{ active: true }, { active: false }], [{ active: true }, { active: false }], true, {}, {}]
      )
    end

    it 'uses empty-group boolean identities consistently' do
      all = described_class.new(conditions: { all: [] }, values: {})
      any = described_class.new(conditions: { any: [] }, values: {})
      expect([all.valid?, all.explain[:valid], any.valid?, any.explain[:valid]]).to eq([true, true, false, false])
    end
  end
end
