require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

require 'stringio'

module Nokogiri
  module XML
    class TestNode < Nokogiri::TestCase
      def setup
        super
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
      end

      def test_add_namespace
        node = @xml.at('address')
        node.add_namespace('foo', 'http://tenderlovemaking.com')
        assert_equal 'http://tenderlovemaking.com', node.namespaces['xmlns:foo']
      end

      def test_add_child_should_inherit_namespace
        doc = Nokogiri::XML(<<-eoxml)
          <root xmlns="http://tenderlovemaking.com/">
            <first>
            </first>
          </root>
        eoxml
        assert node = doc.at('//xmlns:first')
        child = Nokogiri::XML::Node.new('second', doc)
        node.add_child(child)
        assert doc.at('//xmlns:second')
      end

      def test_write_to
        io = StringIO.new
        @xml.write_to io
        io.rewind
        assert_equal @xml.to_xml, io.read
      end

      def test_attribute_with_symbol
        assert_equal 'Yes', @xml.css('address').first[:domestic]
      end

      def test_write_to_with_block
        called = false
        io = StringIO.new
        conf = nil
        @xml.write_to io do |config|
          called = true
          conf = config
          config.format.as_html.no_empty_tags
        end
        io.rewind
        assert called
        assert_equal @xml.serialize(nil, conf.options), io.read
      end

      %w{ xml html xhtml }.each do |type|
        define_method(:"test_write_#{type}_to") do
          io = StringIO.new
          assert @xml.send(:"write_#{type}_to", io)
          io.rewind
          assert_match @xml.send(:"to_#{type}"), io.read
        end
      end

      def test_serialize_with_block
        called = false
        conf = nil
        string = @xml.serialize do |config|
          called = true
          conf = config
          config.format.as_html.no_empty_tags
        end
        assert called
        assert_equal @xml.serialize(nil, conf.options), string
      end

      def test_hold_refence_to_subnode
        doc = Nokogiri::XML(<<-eoxml)
          <root>
            <a>
              <b />
            </a>
          </root>
        eoxml
        assert node_a = doc.css('a').first
        assert node_b = node_a.css('b').first
        node_a.unlink
        assert_equal 'b', node_b.name
      end

      def test_values
        assert_equal %w{ Yes Yes }, @xml.xpath('//address')[1].values
      end

      def test_keys
        assert_equal %w{ domestic street }, @xml.xpath('//address')[1].keys
      end

      def test_each
        attributes = []
        @xml.xpath('//address')[1].each do |key, value|
          attributes << [key, value]
        end
        assert_equal [['domestic', 'Yes'], ['street', 'Yes']], attributes
      end

      def test_new
        assert node = Nokogiri::XML::Node.new('input', @xml)
        assert_equal 1, node.node_type
      end

      def test_to_str
        name = @xml.xpath('//name').first
        assert_match(/Margaret/, '' + name)
        assert_equal('Margaret Martin', '' + name.children.first)
      end

      def test_ancestors
        address = @xml.xpath('//address').first
        assert_equal 3, address.ancestors.length
        assert_equal ['employee', 'staff', 'document'],
          address.ancestors.map { |x| x.name }
      end

      def test_read_only?
        assert entity_decl = @xml.internal_subset.children.find { |x|
          x.type == Node::ENTITY_DECL
        }
        assert entity_decl.read_only?
      end

      def test_remove_attribute
        address = @xml.xpath('/staff/employee/address').first
        assert_equal 'Yes', address['domestic']
        address.remove_attribute 'domestic'
        assert_nil address['domestic']
      end

      def test_delete
        address = @xml.xpath('/staff/employee/address').first
        assert_equal 'Yes', address['domestic']
        address.delete 'domestic'
        assert_nil address['domestic']
      end

      def test_add_child_in_same_document
        child = @xml.css('employee').first

        assert previous_last_child = child.children.last
        assert new_child = child.children.first

        last = child.children.last

        child.add_child(new_child)
        assert_equal new_child, child.children.last
        assert_equal last, child.children.last
      end

      def test_add_child_from_other_document
        d1 = Nokogiri::XML("<root><item>1</item><item>2</item></root>")
        d2 = Nokogiri::XML("<root><item>3</item><item>4</item></root>")

        d2.at('root').search('item').each do |i|
          d1.at('root').add_child i
        end

        assert_equal 0, d2.search('item').size
        assert_equal 4, d1.search('item').size
      end

      def test_add_child
        xml = Nokogiri::XML(<<-eoxml)
        <root>
          <a>Hello world</a>
        </root>
        eoxml
        text_node = Nokogiri::XML::Text.new('hello', xml)
        assert_equal Nokogiri::XML::Node::TEXT_NODE, text_node.type
        xml.root.add_child text_node
        assert_match 'hello', xml.to_s
      end

      def test_chevron_works_as_add_child
        xml = Nokogiri::XML(<<-eoxml)
        <root>
          <a>Hello world</a>
        </root>
        eoxml
        text_node = Nokogiri::XML::Text.new('hello', xml)
        xml.root << text_node
        assert_match 'hello', xml.to_s
      end

      def test_add_previous_sibling
        xml = Nokogiri::XML(<<-eoxml)
        <root>
          <a>Hello world</a>
        </root>
        eoxml
        b_node = Nokogiri::XML::Node.new('a', xml)
        assert_equal Nokogiri::XML::Node::ELEMENT_NODE, b_node.type
        b_node.content = 'first'
        a_node = xml.xpath('//a').first
        a_node.add_previous_sibling(b_node)
        assert_equal('first', xml.xpath('//a').first.text)
      end

      def test_add_previous_sibling_merge
        xml = Nokogiri::XML(<<-eoxml)
        <root>
          <a>Hello world</a>
        </root>
        eoxml

        assert a_tag = xml.css('a').first

        left_space = a_tag.previous
        right_space = a_tag.next
        assert left_space.text?
        assert right_space.text?

        left_space.add_previous_sibling(right_space)
        assert_equal left_space, right_space
      end

      def test_add_next_sibling_merge
        xml = Nokogiri::XML(<<-eoxml)
        <root>
          <a>Hello world</a>
        </root>
        eoxml

        assert a_tag = xml.css('a').first

        left_space = a_tag.previous
        right_space = a_tag.next
        assert left_space.text?
        assert right_space.text?

        right_space.add_next_sibling(left_space)
        assert_equal left_space, right_space
      end

      def test_find_by_css_with_tilde_eql
        xml = Nokogiri::XML.parse(<<-eoxml)
        <root>
          <a>Hello world</a>
          <a class='foo bar'>Bar</a>
          <a class='bar foo'>Bar</a>
          <a class='bar'>Bar</a>
          <a class='baz bar foo'>Bar</a>
          <a class='bazbarfoo'>Awesome</a>
          <a class='bazbar'>Awesome</a>
        </root>
        eoxml
        set = xml.css('a[@class~="bar"]')
        assert_equal 4, set.length
        assert_equal ['Bar'], set.map { |node| node.content }.uniq
      end

      def test_unlink
        xml = Nokogiri::XML.parse(<<-eoxml)
        <root>
          <a class='foo bar'>Bar</a>
          <a class='bar foo'>Bar</a>
          <a class='bar'>Bar</a>
          <a>Hello world</a>
          <a class='baz bar foo'>Bar</a>
          <a class='bazbarfoo'>Awesome</a>
          <a class='bazbar'>Awesome</a>
        </root>
        eoxml
        node = xml.xpath('//a')[3]
        assert_equal('Hello world', node.text)
        assert_match(/Hello world/, xml.to_s)
        assert node.parent
        assert node.document
        assert node.previous_sibling
        assert node.next_sibling
        node.unlink
        assert !node.parent
        #assert !node.document
        assert !node.previous_sibling
        assert !node.next_sibling
        assert_no_match(/Hello world/, xml.to_s)
      end

      def test_next_sibling
        assert node = @xml.root
        assert sibling = node.child.next_sibling
        assert_equal('employee', sibling.name)
      end

      def test_previous_sibling
        assert node = @xml.root
        assert sibling = node.child.next_sibling
        assert_equal('employee', sibling.name)
        assert_equal(sibling.previous_sibling, node.child)
      end

      def test_name=
        assert node = @xml.root
        node.name = 'awesome'
        assert_equal('awesome', node.name)
      end

      def test_child
        assert node = @xml.root
        assert child = node.child
        assert_equal('text', child.name)
      end

      def test_key?
        assert node = @xml.search('//address').first
        assert(!node.key?('asdfasdf'))
      end

      def test_set_property
        assert node = @xml.search('//address').first
        node['foo'] = 'bar'
        assert_equal('bar', node['foo'])
      end

      def test_attributes
        assert node = @xml.search('//address').first
        assert_nil(node['asdfasdfasdf'])
        assert_equal('Yes', node['domestic'])

        assert node = @xml.search('//address')[2]
        attr = node.attributes
        assert_equal 2, attr.size
        assert_equal 'Yes', attr['domestic'].value
        assert_equal 'Yes', attr['domestic'].to_s
        assert_equal 'No', attr['street'].value
      end

      def test_path
        assert set = @xml.search('//employee')
        assert node = set.first
        assert_equal('/staff/employee[1]', node.path)
      end

      def test_search_by_symbol
        assert set = @xml.search(:employee)
        assert 5, set.length

        assert node = @xml.at(:employee)
        assert node.text =~ /EMP0001/
      end

      def test_new_node
        node = Nokogiri::XML::Node.new('form', @xml)
        assert_equal('form', node.name)
        assert(node.document)
      end

      def test_encode_special_chars
        foo = @xml.css('employee').first.encode_special_chars('&')
        assert_equal '&amp;', foo
      end

      def test_content
        node = Nokogiri::XML::Node.new('form', @xml)
        assert_equal('', node.content)

        node.content = 'hello world!'
        assert_equal('hello world!', node.content)
      end

      def test_whitespace_nodes
        doc = Nokogiri::XML.parse("<root><b>Foo</b>\n<i>Bar</i> <p>Bazz</p></root>")
        children = doc.at('//root').children.collect{|j| j.to_s}
        assert_equal "\n", children[1]
        assert_equal " ", children[3]
      end

      def test_replace
        set = @xml.search('//employee')
        assert 5, set.length
        assert 0, @xml.search('//form').length

        first = set[0]
        second = set[1]

        node = Nokogiri::XML::Node.new('form', @xml)
        first.replace(node)

        assert set = @xml.search('//employee')
        assert_equal 4, set.length
        assert 1, @xml.search('//form').length

        assert_equal set[0].to_xml, second.to_xml
      end

      def test_illegal_replace_of_node_with_doc
        new_node = Nokogiri::XML.parse('<foo>bar</foo>')
        old_node = @xml.at('//employee')
        assert_raises(ArgumentError){ old_node.replace new_node }
      end

      def test_node_equality
        doc1 = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        doc2 = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        
        address1_1 = doc1.xpath('//address').first
        address1_2 = doc1.xpath('//address').first
        
        address2 = doc2.xpath('//address').first
        
        assert_not_equal address1_1, address2 # two references to very, very similar nodes
        assert_equal address1_1, address1_2 # two references to the exact same node
      end

      def test_namespace_as_hash
        xml = Nokogiri::XML.parse(<<-eoxml)
<root>
 <car xmlns:part="http://general-motors.com/">
  <part:tire>Michelin Model XGV</part:tire>
 </car>
 <bicycle xmlns:part="http://schwinn.com/">
  <part:tire>I'm a bicycle tire!</part:tire>
 </bicycle>
</root>
        eoxml

        tires = xml.xpath('//bike:tire', {'bike' => 'http://schwinn.com/'})
        assert_equal 1, tires.length
      end

      def test_namespace_search_with_css
        xml = Nokogiri::XML.parse(<<-eoxml)
<root>
 <car xmlns:part="http://general-motors.com/">
  <part:tire>Michelin Model XGV</part:tire>
 </car>
 <bicycle xmlns:part="http://schwinn.com/">
  <part:tire>I'm a bicycle tire!</part:tire>
 </bicycle>
</root>
        eoxml

        tires = xml.css('bike|tire', 'bike' => 'http://schwinn.com/')
        assert_equal 1, tires.length
      end

      def test_namespaces
        xml = Nokogiri::XML.parse(<<-EOF)
<x xmlns:a='http://foo.com/' xmlns:b='http://bar.com/'>
  <y xmlns:c='http://bazz.com/'>
    <a:div>hello a</a:div>
    <b:div>hello b</b:div>
    <c:div>hello c</c:div>
  </y>  
</x>
EOF
        assert namespaces = xml.root.namespaces
        assert namespaces.key?('xmlns:a')
        assert_equal 'http://foo.com/', namespaces['xmlns:a']
        assert namespaces.key?('xmlns:b')
        assert_equal 'http://bar.com/', namespaces['xmlns:b']
        assert ! namespaces.key?('xmlns:c')

        assert namespaces = xml.namespaces
        assert namespaces.key?('xmlns:a')
        assert_equal 'http://foo.com/', namespaces['xmlns:a']
        assert namespaces.key?('xmlns:b')
        assert_equal 'http://bar.com/', namespaces['xmlns:b']
        assert namespaces.key?('xmlns:c')
        assert_equal 'http://bazz.com/', namespaces['xmlns:c']

        assert_equal "hello a", xml.search("//a:div", xml.namespaces).first.inner_text
        assert_equal "hello b", xml.search("//b:div", xml.namespaces).first.inner_text
        assert_equal "hello c", xml.search("//c:div", xml.namespaces).first.inner_text
      end

      def test_namespace
        xml = Nokogiri::XML.parse(<<-EOF)
<x xmlns:a='http://foo.com/' xmlns:b='http://bar.com/'>
  <y xmlns:c='http://bazz.com/'>
    <a:div>hello a</a:div>
    <b:div>hello b</b:div>
    <c:div>hello c</c:div>
    <div>hello moon</div>
  </y>  
</x>
EOF
        set = xml.search("//y/*")
        assert_equal "a", set[0].namespace
        assert_equal "b", set[1].namespace
        assert_equal "c", set[2].namespace
        assert_equal nil, set[3].namespace
      end

      def test_line
        xml = Nokogiri::XML(<<-eoxml)
        <root>
          <a>
            Hello world
          </a>
        </root>
        eoxml

        set = xml.search("//a")
        node = set.first
        assert_equal 2, node.line
      end

    end
  end
end
