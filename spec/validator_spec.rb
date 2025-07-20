RSpec.describe JPCOARValidator do
  spec_base_dir = File.dirname(__FILE__)
  context "#validate_jpcoar" do
    it "should load a XML file and validate it." do
      validator = JPCOARValidator.new("")
      Dir.glob("schema/2.0/samples/*.xml").each do |file|
        doc = LibXML::XML::Document.file(file)
        expect {
          results = validator.validate_jpcoar(doc)
          p [file, results]
          expect(results[:error]).to be_empty
        }.not_to raise_error
      end
    end
    it "should validate creator/affiliation/nameIdentifier" do
      validator = JPCOARValidator.new("")
      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/0361-nameIdentifier.xml"))
    end
    it "should validate name comma" do
      validator = JPCOARValidator.new("")
      doc = LibXML::XML::Document.file("schema/2.0/samples/14_common_metadata_elements_cao.xml")
      results = validator.validate_jpcoar(doc)
      expect(results[:warn].map{|e| e[:error_id]}).not_to include(:no_comma_creator)
    end
  end
end