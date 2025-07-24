RSpec.describe JPCOARValidator do
  spec_base_dir = File.dirname(__FILE__)
  context "#validate_jpcoar" do
    it "should load a XML file and validate it." do
      validator = JPCOARValidator.new("")
      Dir.glob("schema/2.0/samples/*.xml").each do |file|
        results = nil
        doc = LibXML::XML::Document.file(file)
        if file =~ /08_conference_object.xml\z/
          # skip
          #pending("Fix PR JPCOAR/schema#3")
          #expect {
          #  results = validator.validate_jpcoar(doc)
          #  p [file, results]
          #  expect(results[:error]).to be_empty
          #}.not_to raise_error
        else
          expect {
            results = validator.validate_jpcoar(doc)
          }.not_to raise_error
          p [file, results]
          expect(results[:error]).to be_empty
        end
      end
    end
    it "should load a XML file and validate it.", pending: "Fix PR JPCOAR/schema#3" do
      validator = JPCOARValidator.new("")
      file = "schema/2.0/samples/08_conference_object.xml"
      doc = LibXML::XML::Document.file(file)
      results = nil
      expect {
        results = validator.validate_jpcoar(doc)
      }.not_to raise_error
      p [file, results]
      expect(results[:error]).to be_empty
    end
    it "should validate the presence of accessRights@rdf:resource." do
      validator = JPCOARValidator.new("")
      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/05_accessRights/rdf_resource.xml"))
      results = validator.validate_jpcoar(doc)
      expect(results[:error].map{|e| e[:error_id]}).to include(:access_rights_without_rdf_resouce)
    end
    it "should validate embagoed access without Available date." do
      validator = JPCOARValidator.new("")
      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/05_accessRights/embergoed.xml"))
      results = validator.validate_jpcoar(doc)
      expect(results[:error].map{|e| e[:error_id]}).to include(:embargoed_access_no_available_date)
    end
    it "should validate name comma" do
      validator = JPCOARValidator.new("")
      doc = LibXML::XML::Document.file("schema/2.0/samples/14_common_metadata_elements_cao.xml")
      results = validator.validate_jpcoar(doc)
      expect(results[:warn].map{|e| e[:error_id]}).not_to include(:no_comma_creator)
    end
    it "should validate identifier & identifierRegistration" do
      validator = JPCOARValidator.new("")
      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/18_identifierRegistration/identifier_mismatch.xml"))
      results = validator.validate_jpcoar(doc)
      expect(results[:warn].map{|e| e[:error_id]}).to include(:identifier_registration_doi_mismatch)
    end
    it "should validate funderName availability" do
      validator = JPCOARValidator.new("")
      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/23_fundingReference/funder_name_not_available.xml"))
      results = validator.validate_jpcoar(doc)
      expect(results[:error].map{|e| e[:error_id]}).to include(:funder_name_not_available)
    end
  end
end