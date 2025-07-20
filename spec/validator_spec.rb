RSpec.describe JPCOARValidator do
  context "#validate_jpcoar" do
    it "should load a XML" do
      validator = JPCOARValidator.new("")
      files = %w[
        01_departmental_bulletin_paper_oa.xml
        02_journal_article_embargoed.xml
        03_journal_article_oa.xml
        04_journal_article_accepted_embargoed.xml
        05_doctoral_thesis_oa.xml
        06_doctoral_thesis_published.xml
        07_dataset.xml
        08_conference_object.xml
        09_departmental_bulletin_paper_restricted_access.xml
        10_journal_article_metadata_only_external_link.xml
        11_dataset_external_link.xml
        12_digital_archive.xml
        13_digital_archive_dataset_series.xml
        14_common_metadata_elements_cao.xml
      ]
      files.each do |file|
        doc = LibXML::XML::Document.file(File.join("schema/2.0/samples", file))
        expect {
          results = validator.validate_jpcoar(doc)
          p [file, results]
        }.not_to raise_error
      end
    end
  end
end