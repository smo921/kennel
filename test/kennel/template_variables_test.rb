# frozen_string_literal: true
require_relative "../test_helper"

SingleCov.covered!

describe Kennel::TemplateVariables do
  class TestVariables < Kennel::Models::Base
    include Kennel::TemplateVariables
    attr_accessor :project
  end

  it "adds settings" do
    TestVariables.new(template_variables: -> { ["xxx"] }).template_variables.must_equal ["xxx"]
  end

  describe "#render_template_variables" do
    def var(value)
      TestVariables.new(template_variables: -> { value }).send(:render_template_variables)
    end

    it "leaves empty alone" do
      var([]).must_equal []
    end

    it "expands simple" do
      var(["xxx"]).must_equal [{ default: "*", prefix: "xxx", name: "xxx" }]
    end

    it "leaves complicated" do
      var([{ foo: "bar" }]).must_equal [{ foo: "bar" }]
    end
  end

  describe "#validate_template_variables" do
    def validate(value, list)
      data = {
        template_variables: value.map { |v| { name: v } },
        graphs: list
      }
      v = TestVariables.new(template_variables: -> { value })
      v.project = project
      v.send(:validate_template_variables, data, :graphs)
    end

    let(:project) { TestProject.new }

    it "is valid when empty" do
      validate [], []
    end

    it "is valid when vars are empty" do
      validate [], [{ definition: { requests: [{ q: "x" }] } }]
    end

    it "is valid when vars are used" do
      validate ["a"], [{ definition: { requests: [{ q: "$a" }] } }]
    end

    it "is invalid when vars are not used" do
      assert_raises Kennel::Models::Base::ValidationError do
        validate ["a"], [{ definition: { requests: [{ q: "$b" }] } }]
      end
    end

    it "is invalid when nested vars are not used" do
      assert_raises Kennel::Models::Base::ValidationError do
        validate ["a"], [{ definition: { widgets: [{ definition: { requests: [{ q: "$b" }] } }] } }]
      end
    end
  end
end
