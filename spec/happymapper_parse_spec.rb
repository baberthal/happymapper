# frozen_string_literal: true

require 'spec_helper'

describe HappyMapper do
  context '.parse' do
    context 'on a single root node' do
      subject { described_class.parse fixture_file('address.xml') }

      it 'should parse child elements' do
        expect(subject.street).to eq('Milchstrasse')
        expect(subject.housenumber).to eq('23')
        expect(subject.postcode).to eq('26131')
        expect(subject.city).to eq('Oldenburg')
      end

      it 'should not create a content entry when the xml contents no text content' do
        expect(subject).not_to respond_to :content
      end

      context 'child elements with attributes' do
        it 'should parse the attributes' do
          expect(subject.country.code).to eq('de')
        end

        it 'should parse the content' do
          expect(subject.country.content).to eq('Germany')
        end
      end
    end

    context 'element names with special characters' do
      subject { described_class.parse fixture_file('ambigous_items.xml') }

      it 'should create accessor methods with similar names' do
        expect(subject.my_items.item).to be_kind_of Array
      end
    end

    context 'element names with camelCased elements and Capital Letters' do
      subject { described_class.parse fixture_file('subclass_namespace.xml') }

      it 'parses camel-cased child elements correctly' do
        expect(subject.photo.publish_options.author).to eq('Stephanie')
        expect(subject.gallery.photo.title).to eq('photo title')
      end

      it 'parses camel-cased child properties correctly' do
        expect(subject.publish_options.created_day).to eq('2011-01-14')
      end
    end

    context 'with elements with camelCased attribute names' do
      subject { described_class.parse '<foo barBaz="quuz"/>' }

      it 'parses attributes correctly' do
        expect(subject.bar_baz).to eq('quuz')
      end
    end

    context 'several elements nested deep' do
      subject { described_class.parse fixture_file('ambigous_items.xml') }

      it 'should parse the entire relationship' do
        expect(subject.my_items.item.first.item.name).to eq('My first internal item')
      end
    end

    context 'xml that contains multiple entries' do
      subject { described_class.parse fixture_file('multiple_primitives.xml') }

      it "should parse the elements as it would a 'has_many'" do
        expect(subject.name).to eq('value')
        expect(subject.image).to eq(%w(image1 image2))
      end
    end

    context 'xml with multiple namespaces' do
      subject { described_class.parse fixture_file('subclass_namespace.xml') }

      it 'should parse the elements an values correctly' do
        expect(subject.title).to eq('article title')
      end

      it 'parses attribute names correctly' do
        expect(subject.name).to eq 'title'
      end
    end

    context 'with value elements with different namespace' do
      let(:xml) do
        <<~XML
          <a:foo xmlns:a="http://foo.org/a" xmlns:b="http://foo.org/b">
            <b:bar>Hello</b:bar>
          </a:foo>
        XML
      end
      let(:result) { described_class.parse xml }

      it 'parses the value elements correctly' do
        expect(result.bar).to eq 'Hello'
      end
    end

    context 'after_parse callbacks' do
      module AfterParseSpec
        class Address
          include HappyMapper
          element :street, String
        end
      end

      after do
        AfterParseSpec::Address.after_parse_callbacks.clear
      end

      it 'should callback with the newly created object' do
        from_cb = nil
        called = false
        cb1 = proc { |object| from_cb = object }
        cb2 = proc { called = true }
        AfterParseSpec::Address.after_parse(&cb1)
        AfterParseSpec::Address.after_parse(&cb2)

        object = AfterParseSpec::Address.parse fixture_file('address.xml')
        expect(from_cb).to eq(object)
        expect(called).to eq(true)
      end
    end
  end
end
