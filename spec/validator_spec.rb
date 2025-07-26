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
      expect(results[:error].map{|e| e[:error_id]}).to include(:access_rights_without_rdf_resource)
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
      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/19_identifierRegistration/identifier_mismatch.xml"))
      results = validator.validate_jpcoar(doc)
      expect(results[:warn].map{|e| e[:error_id]}).to include(:identifier_registration_doi_mismatch)

      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/19_identifierRegistration/identifier_mismatch_without_identifier.xml"))
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
        44_catalog/title_xmllang_duplicated.xml
      ].each do |file|
        #p file
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        expect(results[:error].map{|e| e[:error_id]}).to include(:xmllang_duplicated)
      end
    end
    it "should check yomi without 'ja'" do
      validator = JPCOARValidator.new("")
      %w[
        1_title/xmllang_noja_with_yomi.xml
        3_creator/creator_name_noja_with_yomi.xml
        3_creator/creator_alternative_noja_with_yomi.xml
        4_contributor/contributor_name_noja_with_yomi.xml
        4_contributor/contributor_alternative_noja_with_yomi.xml
        7_rightsHolder/rights_holder_name_noja_with_yomi.xml
        44_catalog/title_noja_with_yomi.xml
      ].each do |file|
        #p file
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        #p results
        expect(results[:error].map{|e| e[:error_id]}).to include(:xmllang_nojapanese_with_yomi)
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
    it "should check no_creator_in_thesis" do
      validator = JPCOARValidator.new("")
      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/3_creator/no_creator_in_thesis.xml"))
      results = validator.validate_jpcoar(doc)
      expect(results[:error].map{|e| e[:error_id]}).to include(:no_creator_in_thesis)
    end
    it "should check nameidentifier_content_is_uri" do
      validator = JPCOARValidator.new("")
      files = %w[
        3_creator/name_identifier_content_is_uri_orcid.xml
        3_creator/affiliation_name_identifier_content_is_uri_isni.xml
        4_contributor/name_identifier_content_is_uri_orcid.xml
        4_contributor/affiliation_name_identifier_content_is_uri_isni.xml
        7_rightsHolder/name_identifier_content_is_uri_isni.xml
        34_degreeGrantor/name_identifier_content_is_uri_kakenhi.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        #p [file, results]
        expect(results[:warn].map{|e| e[:error_id]}).to include(:nameidentifier_content_is_uri)
      end
      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/3_creator/affiliation_name_identifier_content_is_uri_ror.xml"))
      results = validator.validate_jpcoar(doc)
      expect(results[:warn].map{|e| e[:error_id]}).not_to include(:nameidentifier_content_is_uri)
    end
    it "should check nameIdentifierScheme_obsolete" do
      validator = JPCOARValidator.new("")
      files = %w[
        3_creator/name_identifier_scheme_obsolete_nrid.xml
        3_creator/affiliation_name_identifier_scheme_obsolete_kakenhi.xml
        4_contributor/name_identifier_scheme_obsolete_nrid.xml
        4_contributor/affiliation_name_identifier_scheme_obsolete_kakenhi.xml
        7_rightsHolder/name_identifier_scheme_obsolete_grid.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        #p [file, results]
        expect(results[:warn].map{|e| e[:error_id]}).to include(:nameIdentifierScheme_obsolete)
      end

      doc = LibXML::XML::Document.file("schema/2.0/samples/05_doctoral_thesis_oa.xml")
      results = validator.validate_jpcoar(doc)
      #p results
      expect(results[:warn].map{|e| e[:error_id]}).not_to include(:nameIdentifierScheme_obsolete)
    end
    it "should check degree_grantor_kakenhi_missing" do
      validator = JPCOARValidator.new("")
      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/34_degreeGrantor/name_identifier_scheme_kakenhi_missing.xml"))
      results = validator.validate_jpcoar(doc)
      #p results
      expect(results[:warn].map{|e| e[:error_id]}).to include(:degree_grantor_kakenhi_missing)
    end
    it "should check name_identifier_mismatch" do
      validator = JPCOARValidator.new("")
      %w[
        3_creator/name_identifier_mismatch_orcid.xml
        3_creator/name_identifier_mismatch_erad.xml
        3_creator/affiliation_name_identifier_mismatch_isni.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        #p [file, results]
        expect(results[:warn].map{|e| e[:error_id]}).to include(:nameIdentifier_mismatch)
      end
    end
    it "should check yomi_not_needed" do
      validator = JPCOARValidator.new("")
      %w[
        3_creator/family_name_yomi_not_needed.xml
        3_creator/given_name_yomi_not_needed.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        #p [file, results]
        expect(results[:warn].map{|e| e[:error_id]}).to include(:yomi_not_needed)
      end
    end
    it "should check contributor_type_not_found" do
      validator = JPCOARValidator.new("")
      doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example/4_contributor/contributor_type_not_found.xml"))
      results = validator.validate_jpcoar(doc)
      #p results
      expect(results[:warn].map{|e| e[:error_id]}).to include(:contributor_type_not_found)
    end
    it "should check access_rights_without_rdf_resource" do
      validator = JPCOARValidator.new("")
      %w[
        5_accessRights/access_rights_without_rdf_resource.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        #p [file, results]
        expect(results[:error].map{|e| e[:error_id]}).to include(:access_rights_without_rdf_resource)
      end
    end
    it "should check access_rights_wrong_uri" do
      validator = JPCOARValidator.new("")
      %w[
        5_accessRights/access_rights_wrong_url.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        #p [file, results]
        expect(results[:error].map{|e| e[:error_id]}).to include(:access_rights_wrong_uri)
      end
    end
    it "should check access_rights_mismatch" do
      validator = JPCOARValidator.new("")
      %w[
        5_accessRights/access_rights_mismatch.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        #p [file, results]
        expect(results[:error].map{|e| e[:error_id]}).to include(:access_rights_mismatch)
      end
    end
    it "should check publisher_name_not_found" do
      validator = JPCOARValidator.new("")
      %w[
        11_publisher/publisher_name_not_found.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        #p [file, results]
        expect(results[:warn].map{|e| e[:error_id]}).to include(:publisher_name_not_found)
      end
    end
    it "should check format_iso3166_1" do
      validator = JPCOARValidator.new("")
      %w[
        11_publisher/publication_place_format_iso3166_1.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        #p [file, results]
        expect(results[:warn].map{|e| e[:error_id]}).to include(:format_iso3166_1)
      end
    end
    it "should check format_version" do
      validator = JPCOARValidator.new("")
      %w[
        16_version/format.xml
        43_file/version_format.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        #p [file, results]
        expect(results[:warn].map{|e| e[:error_id]}).to include(:format_version)
      end
    end
    it "should check coar_version_type_mismatch" do
      validator = JPCOARValidator.new("")
      %w[
        17_version/coar_version_type_mismatch_wrong_content.xml
        17_version/coar_version_type_mismatch_wrong_uri.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        #p [file, results]
        expect(results[:error].map{|e| e[:error_id]}).to include(:coar_version_type_mismatch)
      end
    end
    it "should check identifier_type_mismatch" do
      validator = JPCOARValidator.new("")
      %w[
        18_identifier/identifier_type_mismatch_doi.xml
        18_identifier/identifier_type_mismatch_hdl.xml
        18_identifier/identifier_type_mismatch_dois.xml
        19_identifierRegistration/identifier_type_mismatch.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        #p [file, results]
        expect(results[:error].map{|e| e[:error_id]}).to include(:identifier_type_mismatch)
      end
    end
    it "should check identifier_type_pmid" do
      validator = JPCOARValidator.new("")
      %w[
        19_identifierRegistration/identifier_type_pmid.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        #p [file, results]
        expect(results[:error].map{|e| e[:error_id]}).to include(:identifier_type_pmid)
      end
    end
    it "should check identifier_type_obsolete" do
      validator = JPCOARValidator.new("")
      %w[
        20_relation/related_identifier_type_obsolete_issn.xml
        20_relation/related_identifier_type_obsolete_naid.xml
        23_fundingReference/funder_identifier_type_obsolete.xml
        24_sourceIdentifier/identifier_type_obsolete.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        #p [file, results]
        expect(results[:warn].map{|e| e[:error_id]}).to include(:identifier_type_obsolete)
      end
    end
    it "should check vor_relation_not_found" do
      validator = JPCOARValidator.new("")
      %w[
        20_relation/vor_relation_not_found.xml
      ].each do |file|
        doc = LibXML::XML::Document.file(File.join(spec_base_dir, "example", file))
        results = validator.validate_jpcoar(doc)
        p [file, results]
        expect(results[:warn].map{|e| e[:error_id]}).to include(:vor_relation_not_found)
      end
    end
  end
end