RSpec.describe JPCOARValidator do
  spec_base_dir = File.dirname(__FILE__)
  context "#validate_jpcoar" do
    it "should load a XML file and validate it." do
      validator = JPCOARValidator.new("")
      Dir.glob("schema/2.0/samples/*.xml").each do |file|
        results = nil
        #p file
        doc = LibXML::XML::Document.file(file)
        case file
        when /07_dataset\.xml\z/, /08_conference_object\.xml\z/, /11_dataset_external_link\.xml\z/, /12_digital_archive\.xml/
          # skip
        else
          expect {
            results = validator.validate_jpcoar(doc)
          }.not_to raise_error
          p [file, results]
          expect(results[:error]).to be_empty
          results[:warn].each do |warn|
            expect(warn).to have_key :identifier
            expect(warn).to have_key :message
            expect(warn).to have_key :error_id
          end
        end
      end
    end
    it "should load a XML file and validate it on 08_conference_object.", pending: "Fix PR JPCOAR/schema#3" do
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
    it "should load a XML file and validate it on 07, 11, 12.", pending: "Fix datacite:description on xmllang_not_found" do
      validator = JPCOARValidator.new("")
      files = %w[
        07_dataset.xml
        11_dataset_external_link.xml
        12_digital_archive.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join("schema/2.0/samples", file))
        results = nil
        expect {
          results = validator.validate_jpcoar(doc)
        }.not_to raise_error
        p [file, results]
        expect(results[:error]).to be_empty
      end
    end
    it "should validate the presence of accessRights@rdf:resource." do
      validator = JPCOARValidator.new("")
      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/5_accessRights/rdf_resource.xml"))
      results = validator.validate_jpcoar(doc)
      expect(results[:error].map{|e| e[:error_id]}).to include(:access_rights_without_rdf_resouce)
    end
    it "should validate embagoed access without Available date." do
      validator = JPCOARValidator.new("")
      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/5_accessRights/embergoed.xml"))
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

      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/18_identifierRegistration/identifier_mismatch_without_identifier.xml"))
      results = validator.validate_jpcoar(doc)
      expect(results[:warn].map{|e| e[:error_id]}).to include(:identifier_registration_doi_mismatch)
    end
    it "should validate funderName availability" do
      validator = JPCOARValidator.new("")
      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/23_fundingReference/funder_name_not_available.xml"))
      results = validator.validate_jpcoar(doc)
      expect(results[:error].map{|e| e[:error_id]}).to include(:funder_name_not_available)
    end
    it "should validate existence of xml:lang" do
      validator = JPCOARValidator.new("")
      %w[
        1_title/xmllang_not_found.xml
        2_alternative/xmllang_not_found.xml
        3_creator/creator_name_xmllang_not_found.xml
        3_creator/family_name_xmllang_not_found.xml
        3_creator/given_name_xmllang_not_found.xml
        3_creator/creator_alternative_xmllang_not_found.xml
        3_creator/affiliation_name_xmllang_not_found.xml
        4_contributor/contributor_name_xmllang_not_found.xml
        4_contributor/family_name_xmllang_not_found.xml
        4_contributor/given_name_xmllang_not_found.xml
        4_contributor/contributor_alternative_xmllang_not_found.xml
        4_contributor/affiliation_name_xmllang_not_found.xml
        6_rights/xmllang_not_found.xml
        7_rightsHolder/xmllang_not_found.xml
        9_description/xmllang_not_found.xml
        10_publisher/xmllang_not_found.xml
        11_publisher/publisher_name_xmllang_not_found.xml
        11_publisher/publisher_description_xmllang_not_found.xml
        11_publisher/location_xmllang_not_found.xml
        13_date/xmllang_not_found.xml
        20_relation/related_title_xmllang_not_found.xml
        21_date/xmllang_not_found.xml
        23_fundingReference/funder_name_xmllang_not_found.xml
        23_fundingReference/funding_stream_xmllang_not_found.xml
        23_fundingReference/award_title_xmllang_not_found.xml
        25_sourceTitle/xmllang_not_found.xml
        32_degreeName/xmllang_not_found.xml
        34_degreeGrantor/degree_name_xmllang_not_found.xml
        35_conference/conference_name_xmllang_not_found.xml
        35_conference/conference_date_xmllang_not_found.xml
        35_conference/conference_place_xmllang_not_found.xml
        35_conference/conference_venue_xmllang_not_found.xml
        35_conference/conference_sponsor_xmllang_not_found.xml
        36_edition/xmllang_not_found.xml
        37_volumeTitle/xmllang_not_found.xml
        39_extent/xmllang_not_found.xml
        40_format/xmllang_not_found.xml
        41_holdingAgent/holding_agent_name_xmllang_not_found.xml
        44_catalog/contributor_name_xmllang_not_found.xml
        44_catalog/license_xmllang_not_found.xml
        44_catalog/subject_xmllang_not_found.xml
        44_catalog/description_xmllang_not_found.xml
        44_catalog/rights_xmllang_not_found.xml
        44_catalog/title_xmllang_not_found.xml
      ].each do |file|
        #p file
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        expect(results[:error].map{|e| e[:error_id]}).to include(:xmllang_not_found)
        results.each do |error_type, data|
          data.each do |e|
            expect(e).to have_key :identifier
            expect(e).to have_key :message
            expect(e).to have_key :error_id
          end
        end
        #p results
      end
    end
    it "check duplicated xml:lang values" do
      validator = JPCOARValidator.new("")
      %w[
        1_title/xmllang_duplicated.xml
        3_creator/family_name_xmllang_duplicated.xml
        3_creator/given_name_xmllang_duplicated.xml
        4_contributor/contributor_name_xmllang_duplicated.xml
        4_contributor/family_name_xmllang_duplicated.xml
        4_contributor/given_name_xmllang_duplicated.xml
        4_contributor/affiliation_name_xmllang_duplicated.xml
        20_relation/related_title_xmllang_duplicated.xml
        23_fundingReference/funder_name_xmllang_duplicated.xml
        23_fundingReference/award_title_xmllang_duplicated.xml
        25_sourceTitle/xmllang_duplicated.xml
        32_degreeName/xmllang_duplicated.xml
        34_degreeGrantor/degree_grantor_name_xmllang_duplicated.xml
        35_conference/conference_name_xmllang_duplicated.xml
        35_conference/conference_sponsor_xmllang_duplicated.xml
        35_conference/conference_venue_xmllang_duplicated.xml
        35_conference/conference_place_xmllang_duplicated.xml
        41_holdingAgent/holding_agent_name_xmllang_duplicated.xml
      ].each do |file|
        p file
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        expect(results[:error].map{|e| e[:error_id]}).to include(:xmllang_duplicated)
      end
    end
    it "should check positiveInteger errors" do
      validator = JPCOARValidator.new("")
      files = %w[
        28_numPages/positive_integer.xml
        29_pageStart/positive_integer.xml
        30_pageEnd/positive_integer.xml
        35_conference/conference_sequence_positive_integer.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        expect(results[:error].map{|e| e[:error_id]}).to include(:positiveInteger)
      end
    end
    it "should check sourceIdentifierVocab" do
      validator = JPCOARValidator.new("")
      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/24_sourceIdentifier/01_departmental_bulletin_paper_oa.xml"))
      results = validator.validate_jpcoar(doc)
      expect(results[:error].map{|e| e[:error_id]}).to include(:sourceIdentifierVocab)
    end
  end
end