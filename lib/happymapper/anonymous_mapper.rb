# frozen_string_literal: true

module HappyMapper
  module AnonymousMapper
    def parse(xml_content)
      # TODO: this should be able to handle all the types of functionality that parse is able
      #   to handle which includes the text, xml document, node, fragment, etc.
      xml = Nokogiri::XML(xml_content)

      happymapper_class = create_happymapper_class_with_element(xml.root)

      # With all the elements and attributes defined on the class it is time
      # for the class to actually use the normal HappyMapper powers to parse
      # the content. At this point this code is utilizing all of the existing
      # code implemented for parsing.
      happymapper_class.parse(xml_content, single: true)
    end

    private

    #
    # Borrowed from Active Support to convert unruly element names into a format
    # known and loved by Rubyists.
    #
    def underscore(camel_cased_word)
      word = camel_cased_word.to_s.dup
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr!('-', '_')
      word.downcase!
      word
    end

    #
    # Used internally when parsing to create a class that is capable of
    # parsing the content. The name of the class is of course not likely
    # going to match the content it will be able to parse so the tag
    # value is set to the one provided.
    #
    def create_happymapper_class_with_tag(tag_name)
      happymapper_class = Class.new
      happymapper_class.class_eval do
        include HappyMapper
        tag tag_name
      end
      happymapper_class
    end

    #
    # Used internally to create and define the necessary happymapper
    # elements.
    #
    def create_happymapper_class_with_element(element)
      happymapper_class = create_happymapper_class_with_tag(element.name)

      happymapper_class.namespace element.namespace.prefix if element.namespace

      element.namespaces.each do |prefix, namespace|
        happymapper_class.register_namespace prefix, namespace
      end

      element.attributes.each_value do |attribute|
        define_attribute_on_class(happymapper_class, attribute)
      end

      element.children.each do |child|
        define_element_on_class(happymapper_class, child)
      end

      happymapper_class
    end

    #
    # Define a HappyMapper element on the provided class based on
    # the element provided.
    #
    def define_element_on_class(class_instance, element)
      # When a text element has been provided create the necessary
      # HappyMapper content attribute if the text happens to contain
      # some content.

      class_instance.content :content, String if element.text? && (element.content.strip != '')

      # When the element has children elements, that are not text
      # elements, then we want to recursively define a new HappyMapper
      # class that will have elements and attributes.

      element_type = if !element.elements.reject(&:text?).empty? || !element.attributes.empty?
                       create_happymapper_class_with_element(element)
                     else
                       String
                     end

      method = class_instance.elements.find { |e| e.name == element.name } ? :has_many : :has_one

      options = {}
      options[:tag] = element.name
      namespace = element.namespace
      options[:namespace] = namespace.prefix if namespace

      class_instance.send(method, underscore(element.name), element_type, options)
    end

    #
    # Define a HappyMapper attribute on the provided class based on
    # the attribute provided.
    #
    def define_attribute_on_class(class_instance, attribute)
      class_instance.attribute underscore(attribute.name), String, tag: attribute.name
    end
  end
end
