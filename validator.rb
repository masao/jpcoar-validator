#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require "date"
require "net/http"
require "net/https"
require "optparse"

require "pp"
require "pathname"

require "libxml"
require "faraday"
require "faraday/net_http_persistent"

class URI::HTTP
   def merge_request_uri( query_s )
      if self.query
         request_uri + "&#{ query_s }"
      else
      	 path + "?#{ query_s }"
      end
   end
end

class JPCOARValidator
   XSD = "schema/2.0/jpcoar_scm.xsd"
   JPCOAR_NAMESPACE = "https://github.com/JPCOAR/schema/blob/master/2.0/"
   NAMESPACES = {
      jpcoar: "https://github.com/JPCOAR/schema/blob/master/2.0/",
      dc: "http://purl.org/dc/elements/1.1/",
      dcterms: "http://purl.org/dc/terms/",
      datacite: "https://schema.datacite.org/meta/kernel-4/",
      dcndl: "http://ndl.go.jp/dcndl/terms/",
   }
   COAR_VERSION_TYPE = {
      AO: "http://purl.org/coar/version/c_b1a7d7d4d402bcce",
      SMUR: "http://purl.org/coar/version/c_71e4c1898caa6e32",
      AM: "http://purl.org/coar/version/c_ab4af688f83e57aa",
      P: "http://purl.org/coar/version/c_fa2ee174bc00049f",
      VoR: "http://purl.org/coar/version/c_970fb48d4fbd8a85",
      CVoR: "http://purl.org/coar/version/c_e19f295774971610",
      EVoR: "http://purl.org/coar/version/c_dc82b40f9837b551",
      NA: "http://purl.org/coar/version/c_be7fb7dd8ff6fe43",
   }
   NAME_IDENTIFIER_REGEXP = {
      "e-Rad_Researcher": /\A\d{8}\z/,
      NRID: /\A\d{13}\z/,
      ORCID: /\A[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]\z/,
      ISNI: /\A[0-9]{15}[0-9X]\z/,
      VIAF: /\A\d+\z/,
      AID: /\AD[AB][0-9]{7}[0-9X]\z/,
      kakenhi: /\A\d{5}\z/,
      Ringgold: /\ARIN[0-9]+\z/,
      GRID: /\Agrid\.[0-9]+\.[0-9a-z]+\z/,
      ROR: /\Ahttps:\/\/ror\.org\/.+\z/,
   }
   NAME_IDENTIFIER_URI_REGEXP = {
      #"e-Rad_Researcher": /\A\d{8}\z/,
      NRID: %r|\Ahttps://nrid\.nii\.ac\.jp/nrid/\d{13}\z|,
      ORCID: %r|\Ahttps://orcid\.org/[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]\z|,
      ISNI: %r|\Ahttps://isni\.org/isni/[0-9]{15}[0-9X]\z|,
      VIAF: %r|\Ahttps://viaf\.org/viaf/\d+\z|,
      GRID: %r|\Ahttps://www\.grid\.ac/institutes/grid\.[0-9]+\.[0-9a-z]+\z|,
      ROR: %r|\Ahttps://ror\.org/.+\z|,
   }
   IDENTIFIER_REGEXP = {
      DOI: /\Ahttps?:\/\/doi\.org\/10\./o,
      HDL: /\Ahttps?:\/\/hdl\.handle\.net\//o,
      JaLC: /\A10\..+/,
      Crossref: /\A10\..+/,
      DataCite: /\A10\..+/,
      ISSN: /\A[0-9]{4}-[0-9]{3}[0-9X]\z/o,
      PISSN: /\A[0-9]{4}-[0-9]{3}[0-9X]\z/o,
      EISSN: /\A[0-9]{4}-[0-9]{3}[0-9X]\z/o,
      NCID: /\A(AA|AN|BN|BA|BB)[0-9]{7,8}[0-9X]?/o,
      #:pmid     => /\Ainfo:pmid\/[0-9]+\Z/o,
      #:NAID     => %r|\Ahttp://ci\.nii\.ac\.jp/naid/[0-9]+\Z|o,
      #:ichushi  => %r|\Ahttp://search\.jamas\.or\.jp/link/ui/[0-9]+\Z|o,
   }
   IDENTIFIER_TYPE_REGEXP = {
      :isbn     => /\A[0-9]+[0-9\-]*[0-9X]\Z/oi,
      :NCID     => /\A(AA|AN|BN|BA|BB)[0-9]{7,8}[0-9X]?/o,
   }

   attr_reader :baseurl, :prefix
   def initialize( url )
      @baseurl = URI.parse( url )
      #schema = http(URI.parse XSD).start do |con|
      #  con.get(XSD)
      #end
      schema_doc = LibXML::XML::Document.file(XSD)
      @xml_schema = LibXML::XML::Schema.document(schema_doc)
      @prefix = nil
   end

   def validate( options = {} )
      STDERR.puts @baseurl
      result = {
         :warn => [],
         :error=> [],
         :info => [],
      }
      conn = Faraday.new( @baseurl ) do |f|
         f.adapter :net_http_persistent
      end
      # Identify
      res, = conn.get( @baseurl.merge_request_uri( "verb=Identify" ) )
      #res.value
      xml = res.body
      parser = LibXML::XML::Parser.string( xml )
      doc = parser.parse
      # p doc
      %w[ repositoryName baseURL protocolVersion  ].each do |e|
         element = doc.find( "//oai:#{ e }",
                             "oai:http://www.openarchives.org/OAI/2.0/" )
         if element.size == 1 and not element.first.content.empty?
            result[ :info ] << "#{ e }: #{ element.first.content }"
         else
            result[ :warn ] << "#{ e } is empty."
         end
      end
      STDERR.puts "Identify verified."

      # ListMetadataFormats
      ns = nil
      res = conn.get( @baseurl.merge_request_uri( "verb=ListMetadataFormats" ) )
      xml = res.body
      parser = LibXML::XML::Parser.string( xml )
      doc = parser.parse
      element = doc.find( "//oai:metadataFormat",
                          "oai:http://www.openarchives.org/OAI/2.0/" )
      if element.empty?
         result[ :error ] << {
            :message => "No metadataFormat supported.",
            :error_id => :no_metadataFormat,
         }
      else
         supported_formats = []
         element.each do |e|
            prefix = e.find( "./oai:metadataPrefix",
                             "oai:http://www.openarchives.org/OAI/2.0/" )[0].content
            supported_formats << prefix
            ns = e.find( "./oai:metadataNamespace",
                         "oai:http://www.openarchives.org/OAI/2.0/" )[0].content
            if ns == JPCOAR_NAMESPACE
               @prefix = prefix
            end
         end
         result[ :info ] << "Supported metadataFormat: " + supported_formats.join( ", " )
         if @prefix.nil?
            result[ :error ] << {
               :message => "jpcoar metadata format is not supported.",
               :error_id => :jpcoar_unsupported,
            }
         end
      end
      STDERR.puts "ListMetadataFormat verified."

      # ListRecords
      params = "&metadataPrefix=#{@prefix}"
      options.each do |k, v|
         case k
         when :from, :until, :set
            params << "&#{ k }=#{ URI.encode_www_form_component( v ) }"
         end
      end
      if options[ :resumptionToken ]
	      params = "&resumptionToken=#{ URI.encode_www_form_component( options[ :resumptionToken ] ) }"
	   end
      STDERR.puts "ListRecords: #{params.inspect}"
      res = conn.get( @baseurl.merge_request_uri( "verb=ListRecords&#{ params }" ) )
      if not res.status == 200
         result[ :error ] << {
            :error_id => :not_success_http,
            :message => "The server does not return success code: #{ res.status }",
            :link => :ListRecords,
         }
         return result
      end
      xml = res.body
      doc = nil
      begin
         parser = LibXML::XML::Parser.string( xml )
         doc = parser.parse
      rescue LibXML::XML::Error => err
         result[ :error ] << {
            :error_id => :parse_error,
            :message => "ListRecords returned malformed XML data.",
            :link => :ListRecords,
         }
         return result
      end
      resumption_token = doc.find( "//oai:resumptionToken",
                                   "oai:http://www.openarchives.org/OAI/2.0/" )
      if not resumption_token.nil? and not resumption_token.empty?
         result[ :next_token ] = resumption_token.first.content
      end
      element = doc.find( "//oai:metadata",
                          "oai:http://www.openarchives.org/OAI/2.0/" )
      result[ :info ] << "The size of ListRecords: #{ element.size }"
      if element.empty?
         result[ :warn ] << {
	         :message => "ListRecords returned zero records.",
	         :link => :ListRecords,
	         :error_id => :zero_listrecords,
	      }
	   end
      element.each do |e|
         # metadata = e.inner_xml.strip
         # metadata = LibXML::XML::Document.string( metadata )
         metadata = LibXML::XML::Document.new
         metadata.root = e.child.copy( true )
         if metadata.root.nil? or e.child.empty?	# adhoc for XooNips.
            metadata.root = e.child.next.copy( true )
         end
         identifier = e.parent.find( "./oai:header/oai:identifier",
                                     "oai:http://www.openarchives.org/OAI/2.0/" )[0].content
         validate_jpcoar( metadata, identifier ).each do |k, v|
            result[k] += v
         end
      end
      result
   end

   def validate_jpcoar( metadata, identifier = nil )
      result = {
         :warn => [],
         :error=> [],
         :info => [],
      }
      if metadata.root.namespaces.namespace.nil?
         result[ :error ] << {
            :message => "jpcoar namespace is not specified.",
            :error_id => :no_jpcoar_namespace,
            :link => :ListRecords,
         }
         ns_obj = LibXML::XML::Namespace.new( metadata.root, nil, NAMESPACE )
         metadata.root.namespaces.namespace = ns_obj
         metadata = LibXML::XML::Document.string( metadata.to_s )
         ns = JPCOAR_NAMESPACE
      end
      begin
         metadata.validate_schema( @xml_schema )
      rescue LibXML::XML::Error => err
         error_id =
            case err.message
            when /is not a valid value of the atomic type 'xs:positiveInteger'/
               :positiveInteger
            when /sourceIdentifier', attribute 'identifierType': \[facet 'enumeration'\] The value '(.*?)' is not an element of the set/
               :sourceIdentifierVocab
            when %r|Expected is \( {https://github.com/JPCOAR/schema/blob/master/2.0/}funderName \)|
               :funder_name_not_available
            #when /No matching global declaration available for the validation root/
            #   :wrong_root_element
            #when /This element is not expected. Expected is (one of )?\( .* \)/
            #   :sequence
            #when /is not a valid value of the atomic type \'\{.*\}issnType\'/
            #   :issnType
            #when /is not a valid value of the atomic type \'\{.*\}numberType\'/
            #   :numberType
            #when /is not a valid value of the (union|atomic) type \'\{.*\}languageType\'/
            #   :languageType
            #when /is not a valid value of the atomic type \'xs:anyURI\'/
            #   :anyURI
            #when /is not a valid value of the atomic type \'\{.*?\}versionType\'/
            #   :versionType
            else
               nil
            end
         error = {
            :message => "XML Schema error: #{ err.message }",
            :error_id => error_id,
            :identifier => identifier,
         }
         result[ :error ] << error
      end

      #1. タイトル
      #2. その他のタイトル
      %w[
         dc:title
         dcterms:alternative
         jpcoar:creator/jpcoar:creatorName
         jpcoar:creator/jpcoar:familyName
         jpcoar:creator/jpcoar:givenName
         jpcoar:creator/jpcoar:creatorAlternative
         jpcoar:creator/jpcoar:affiliation/jpcoar:affiliationName
         jpcoar:contributor/jpcoar:contributorName
         jpcoar:contributor/jpcoar:familyName
         jpcoar:contributor/jpcoar:givenName
         jpcoar:contributor/jpcoar:contributorAlternative
         jpcoar:contributor/jpcoar:affiliation/jpcoar:affiliationName
         dc:rights
         jpcoar:rightsHolder/jpcoar:rightsHolderName
         datacite:description
         dc:publisher
         jpcoar:publisher/jpcoar:publisherName
         jpcoar:publisher/jpcoar:publisherDescription
         jpcoar:publisher/dcndl:location
         dcterms:date
         jpcoar:relation/jpcoar:relatedTitle
         jpcoar:fundingReference/jpcoar:funderName
         jpcoar:fundingReference/jpcoar:fundingStream
         jpcoar:fundingReference/jpcoar:awardTitle
         jpcoar:sourceTitle
         dcndl:degreeName
         jpcoar:degreeGrantor/jpcoar:degreeGrantorName
         jpcoar:conference/jpcoar:conferenceName
         jpcoar:conference/jpcoar:conferenceSponsor
         jpcoar:conference/jpcoar:conferenceDate
         jpcoar:conference/jpcoar:conferenceVenue
         jpcoar:conference/jpcoar:conferencePlace
         dcndl:edition
         dcndl:volumeTitle
         dcterms:extent
         jpcoar:format
         jpcoar:holdingAgent/jpcoar:holdingAgentName
         jpcoar:catalog/jpcoar:contributor/jpcoar:contributorName
         jpcoar:catalog/jpcoar:license
         jpcoar:catalog/jpcoar:subject
         jpcoar:catalog/datacite:description
         jpcoar:catalog/dc:rights
      ].each do |elem_name|
         metadata.find("./#{elem_name}", NAMESPACES).each do |e|
            if xml_lang(e).nil?
               result[:error] << {
                  message: "Elements #{elem_name} needs a 'xml:lang' attribute.",
                  error_id: :xmllang_not_found,
                  identifier: identifier,
               }
            end
         end
      end
      [
         "dc:title",
         ["jpcoar:creator", "jpcoar:creatorName"],
         ["jpcoar:creator", "jpcoar:familyName"],
         ["jpcoar:creator", "jpcoar:givenName"],
         ["jpcoar:contributor", "jpcoar:contributorName"],
         ["jpcoar:contributor", "jpcoar:familyName"],
         ["jpcoar:contributor", "jpcoar:givenName"],
         ["jpcoar:contributor/jpcoar:affiliation", "jpcoar:affiliationName"],
         ["jpcoar:relation", "jpcoar:relatedTitle"],
         ["jpcoar:fundingReference", "jpcoar:funderName"],
         ["jpcoar:fundingReference", "jpcoar:awardTitle"],
         "jpcoar:sourceTitle",
         "dcndl:degreeName",
         ["jpcoar:degreeGrantor", "jpcoar:degreeGrantorName"],
         ["jpcoar:conference", "jpcoar:conferenceName"],
         ["jpcoar:conference", "jpcoar:conferenceSponsor"],
         ["jpcoar:conference", "jpcoar:conferenceVenue"],
         ["jpcoar:conference", "jpcoar:conferencePlace"],
         ["jpcoar:holdingAgent", "jpcoar:holdingAgentName"],
         ["jpcoar:catalog", "dc:title"],
      ].each do |e|
         if e.respond_to? :last
            metadata.find("./#{e.first}", NAMESPACES).each do |elem|
               if xml_lang_duplicated?(elem, e.last)
                  langs = xml_langs(elem, e.last)
                  result[:error] << {
                     message: "Element '#{e.join("/")}': 'xml:lang' attributes duplicated: #{langs.join(", ")}",
                     error_id: :xmllang_duplicated,
                     identifier: identifier,
                  }
               end
            end
         else
            if xml_lang_duplicated?(metadata, e)
               langs = xml_langs(metadata, e)
               result[:error] << {
                  message: "Element '#{e}': 'xml:lang' attributes duplicated: #{langs.join(", ")}",
                  error_id: :xmllang_duplicated,
                  identifier: identifier,
               }
            end
         end
      end
      [
         "dc:title",
         ["jpcoar:creator", "jpcoar:creatorName"],
         ["jpcoar:creator", "jpcoar:creatorAlternative"],
         ["jpcoar:contributor", "jpcoar:contributorName"],
         ["jpcoar:contributor", "jpcoar:contributorAlternative"],
         ["jpcoar:rightsHolder", "jpcoar:rightsHolderName"],
         ["jpcoar:catalog", "dc:title"],
      ].each do |e|
         if e.respond_to? :last
            metadata.find("./#{e.first}", NAMESPACES).each do |elem|
               langs = xml_langs(elem, e.last)
               if (langs.include?("ja-Latn") or langs.include?("ja-Kana")) and not langs.include?("ja")
                  result[:error] << {
                     message: "Element '#{e.join("/")}' has Yomi attributes, but no 'ja' title: #{langs.join(", ")}",
                     error_id: :xmllang_nojapanese_with_yomi,
                     identifier: identifier,
                  }
               end
            end
         else
            langs = xml_langs(metadata, e)
            if (langs.include?("ja-Latn") or langs.include?("ja-Kana")) and not langs.include?("ja")
               result[:error] << {
                  message: "Element '#{e}' has Yomi attributes, but no 'ja' title: #{langs.join(", ")}",
                  error_id: :xmllang_nojapanese_with_yomi,
                  identifier: identifier,
               }
            end
         end
      end
      #3. 作成者
      type = metadata.find("./dc:type", "dc:#{NAMESPACES[:dc]}").first
      resource_uri = type.attributes.get_attribute_ns("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "resource").value
      creators = metadata.find("./jpcoar:creator", "jpcoar:#{NAMESPACES[:jpcoar]}")
      if resource_uri =~ %r!http://purl.org/coar/resource_type/(c_46ec|c_7a1f|c_bdcc|c_db06)! and creators.empty?
         result[:error] << {
            error_id: :no_creator_in_thesis,
            message: "Elements 'jpcoar:cerator' is not available.",
            identifier: identifier,
         }
      end
      #3.1 作成者識別子
      metadata.find(".//jpcoar:nameIdentifier", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |name_identifier|
         content = name_identifier.content
         scheme = name_identifier.attributes["nameIdentifierScheme"]
         identifier_uri = name_identifier.attributes["nameIdentifierURI"]
         if content =~ /\Ahttps?:\/\// and scheme != "ROR"
            result[:warn] << {
               message: "nameIdentifier content is in the form of URI: #{content}",
               error_id: :nameidentifier_content_is_uri,
               identifier: identifier,
            }
         end
         case scheme
         when "NRID", "kakenhi", "GRID"
            result[:warn] << {
               message: "nameIdentifierScheme value is obsolete: #{scheme}",
               error_id: :nameIdentifierScheme_obsolete,
               identifier: identifier,
            }
         end
         if NAME_IDENTIFIER_REGEXP[scheme.to_sym]
            if not NAME_IDENTIFIER_REGEXP[scheme.to_sym].match content
               result[:warn] << {
                  message: "nameIdentifierScheme value is mismatch: #{scheme} - #{content}",
                  error_id: :nameIdentifier_mismatch,
                  identifier: identifier,
               }
            end
         end
         if identifier_uri and NAME_IDENTIFIER_URI_REGEXP[scheme.to_sym] and not NAME_IDENTIFIER_URI_REGEXP[scheme.to_sym].match(identifier_uri)
            result[:warn] << {
               error_id: :nameIdentifierURI_mismatch,
               message: "nameIdentifierURI value is mismatch: #{scheme} - #{identifier_uri}",
               identifier: identifier
            }
         end
      end
      #3.2 作成者姓名, 4.2 寄与者姓名, 7.2 権利者名
      ["jpcoar:creatorName", "jpcoar:contributorName", "jpcoar:rightsHolderName"].each do |name|
         metadata.find(".//#{name}", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |name_elem|
            name_type = name_elem.attributes["nameType"]
            if name_type and name_type == "Organizational"
               #skip
            elsif name_elem.content !~ /.+, .+/ and name_elem.content.size < 20
               result[:warn] << {
                  error_id: :no_comma_creator,
                  message: "#{name}: '#{ name_elem.content }' does not contain any separators between family and given name.",
                  identifier: identifier,
               }
            end
         end
      end
      #3.3 作成者姓, 3.4 作成者名
      ["jpcoar:familyName", "jpcoar:givenName"].each do |elem_name|
         metadata.find("./#{elem_name}", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |e|
            if xml_lang(e).nil?
            elsif xml_lang(e) =~ /\Aja-.*/
               result[:warn] << {
                  message: "#{elem_name} element should not include any Yomi: #{e.content}",
                  error_id: :yomi_not_needed,
                  identifier: identifier,
               }
            end
         end
      end
      #4. 寄与者
      metadata.find("./jpcoar:contributor", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |e|
         type = e.attributes["contributorType"]
         if type.nil?
            result[:warn] << {
               error_id: :contributor_type_not_found,
               message: "contributorType attribute not defined.",
               identifier: identifier,
            }
         end
      end
      #5. アクセス権
      metadata.find("./dcterms:accessRights", "dcterms:#{NAMESPACES[:dcterms]}").each do |e|
         resource_uri = e.attributes.get_attribute_ns("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "resource")
         if resource_uri.nil?
            result[:error] << {
               error_id: :access_rights_without_rdf_resouce,
               message: "Element 'dcterms:accessRights' needs @rdf:resource attribute: #{e.content}",
               identifier: identifier,
            }
         elsif resource_uri.value == "http://purl.org/coar/access_right/c_f1cf"
            date_types = metadata.find("./datacite:date", "datacite:#{NAMESPACES[:datacite]}").map do |date_element|
               date_element.attributes["dateType"]
            end
            if not date_types.include? "Available"
               result[:error] << {
                  error_id: :embargoed_access_no_available_date,
                  message: "Element 'dcterms:accessRights' is 'embagoed access', but Element 'datacite:date' @dateType='Available' not found.",
                  identifier: identifier,
               }
            end
         end
      end
      #11. 出版者
      metadata.find("./jpcoar:publisher", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |e|
         name = e.find(".//jpcoar:publisherName", "jpcoar:#{NAMESPACES[:jpcoar]}").first
         description = e.find("./jpcoar:publisherDescription", "jpcoar:#{NAMESPACES[:jpcoar]}").first
         location = e.find("./dcndl:location", "dcndl:#{NAMESPACES[:dcndl]}").first
         publication_place = e.find("./dcndl:publicationPlace", "dcndl:#{NAMESPACES[:dcndl]}").first
         if name.nil? and ( description or location or publication_place )
            result[:warn] << {
               error_id: :publisher_name_not_found,
               message: "Element 'jpcoar:publisherName' not found: #{e.to_s}",
               identifier: identifier,
            }
         end
      end
      #11-4 出版地（国名コード）
      metadata.find("./dcndl:publicationPlace", "dcndl:#{NAMESPACES[:dcndl]}").each do |e|
         if e.content.nil? or e.content !~ /\A[a-zA-Z]{3}\z/
            result[:warn] << {
               message: "Element 'dcndl:publicationPlace' should be in the format of ISO 3166-1 alpha-3: #{e.content}",
               error_id: :format_iso3166_1,
               identifier: identifier,
            }
         end
      end
      #16. バージョン, 43.5 バージョン情報
      metadata.find(".//datacite:version", "datacite:#{NAMESPACES[:datacite]}").each do |e|
         if e.content.nil? or e.content !~ /\A[0-9]+(\.[0-9]+)*[\-a-z0-9A-Z]*\z/
            result[:warn] << {
               message: "Element 'datacite:version' should be in the format like '1.2' not in 'version 1.2': #{e.content}",
               error_id: :format_version,
               identifier: identifier,
            }
         end
      end
      #17. 出版バージョン
      metadata.find("./oaire:version", "oaire:#{NAMESPACES[:oaire]}").each do |e|
         resource_uri = e.attributes.get_attribute_ns("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "resource").value
         if not COAR_VERSION_TYPES[e.content.to_sym] or COAR_VERSION_TYPES[e.content.to_sym] != resource_uri
            result[:error] << {
               error_id: :coar_version_type_mismatch,
               message: "Element 'oaire:version' should comform to COAR Version Vocab: #{e.content} !=  #{resource_uri}"
            }
         end
      end
      #18. 識別子
      metadata.find("./jpcoar:identifier", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |e|
         identifier_type = e.attributes["identifierType"].to_s
         if IDENTIFIER_REGEXP[identifier_type.to_sym] and not IDENTIFIER_REGEXP[identifier_type.to_sym].match(e.content)
            result[:error] << {
               error_id: :identifier_type_mismatch,
               message: "jpcoar:identifier format is mismatched: #{identifier_type} - #{e.content}",
               identifier: identifier,
            }
         end
      end
      #18. 識別子, 19. ID登録
      ["jpcoar:identifier", "jpcoar:identifierRegistration"].each do |identifier_name|
         metadata.find("./#{identifier_name}", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |e|
            identifier_type = e.attributes["identifierType"].to_s
            if identifier == "PMID"
               result[:warn] << {
                  error_id: :identifier_type_pmid,
                  identifier: identifier,
                  message: "Element '#{identifier_name}'@identifierType currently not supported: #{identifier_type} - #{e.content}"
               }
            elsif IDENTIFIER_REGEXP[identifier_type.to_sym] and not IDENTIFIER_REGEXP[identifier_type.to_sym].match(e.content)
               result[:error] << {
                  error_id: :identifier_type_mismatch,
                  identifier: identifier,
                  message: "Element '#{identifier_name}' format mismatch: #{identifier_type.to_s} - #{e.content}"
               }
            end
         end
      end
      #19. ID登録
      metadata.find("./jpcoar:identifierRegistration", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |e|
         registration_id = e.content
         dois = metadata.find("./jpcoar:identifier", "jpcoar:#{NAMESPACES[:jpcoar]}").select do |identifier_elem|
            identifier_elem.attributes["identifierType"].to_s == "DOI"
         end.map do |identifier_elem|
            doi_str = identifier_elem.content.strip.sub(%r|\Ahttps://doi\.org/|, "")
         end
         if not dois.include? registration_id
            result[:warn] << {
               error_id: :identifier_registration_doi_mismatch,
               message: "Elements 'identifierRegistration' does not included in 'identifier': #{registration_id} - #{dois.inspect}",
               identfitier: identifier,
            }
         end
      end
      #20-1. 関連情報識別子
      metadata.find("./jpcoar:relatedIdentifeir", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |e|
         identifier_type = e.attributes["identifierType"]
         case identifier_type
         when "ISSN"
            result[:warn] << {
               error_id: :identifier_type_obsolete,
               identifier: identifier,
               message: "Element 'jpcoar:relatedIdentifier' @identifierType 'ISSN' is not recommended: #{identifier_type} - #{e.content}"
            }
         when "NAID"
            result[:warn] << {
               error_id: :identifier_type_obsolete,
               identifier: :identifier,
               message: "Element 'jpcoar:relatedIdentifier' @identifierType 'NAID' is not recommended: #{identifier_type} - #{e.content}"
            }
         end
      end
      #23.1 助成機関識別子
      metadata.find("./jpcoar:funderIdentifier", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |e|
         identifier_type = e.attributes["identifierType"]
         case identifier_type
         when "GRID"
            result[:warn] << {
               error_id: :identifier_type_obsolete,
               identifier: identifier,
               message: "Element 'jpcoar:funderIdentifier' @identifierType 'GRID' is not recommended: #{identifier_type} - #{e.content}"
            }
         end
      end
      #23.5 研究課題番号
      metadata.find("./jpcoar:awardNumber", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |e|
         award_number_type = e.attributes["awardNumberType"]
         if award_number_type and award_number_type == "JGN" and e.content !~ /\AJP[0-9a-zA-Z]+/
            result[:warn] << {
               error_id: :award_number_format_error,
               identifier: identifier,
               message: "Element 'jpcoar:awardNumber' format is not supported: #{e.content}"
            }
         end
         if award_number_type and award_number_type != "JGN"
            result[:warn] << {
               error_id: :award_number_type_not_supported,
               identifier: identifier,
               message: "Element 'jpcoar:awardNumber' @awardNumberType is not supported: #{award_number_type} - #{e.content}"
            }
         end
      end
      #24. 収録物識別子
      metadata.find("./jpcoar:sourceIdentifeir", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |e|
         identifier_type = e.attributes["identifierType"]
         if identifier_type == "ISSN"
            result[:warn] << {
               error_id: :source_identifier_type_obsolete,
               identifier: identifier,
               message: "Element 'jpcoar:sourceIdentifier' @identifierType 'ISSN' is not recommended: #{identifier_type} - #{e.content}"
            }
         end
         if not IDENTIFIER_REGEXP[identifier_type.to_sym].match(e.content)
            result[:error] << {
               error_id: :identifier_type_mismatch,
               message: "jpcoar:sourceIdentifier format is mismatched: #{identifier_type} - #{e.content}",
               identifier: identifier,
            }
         end
      end
      #26. 巻, 27. 号
      ["jpcoar:volume", "jpcoar:issue"].each do |name|
         metadata.find("./#{name}", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |e|
            if e.content =~ /年|vol|号|年|issue/
               result[:warn] << {
                  error_id: :volume_unnecessary_chars,
                  message: "Element #{name} includes unnecessary characters: #{e.content}",
                  identifier: identifier,
               }
            end
         end
      end
      #28. 学位授与番号
      metadata.find("./dc:type", "dc:#{NAMESPACES[:dc]}").each do |e|
         resource_uri = e.attributes.get_attribute_ns("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "resource").value
         #p resource_uri
         if resource_uri == "http://purl.org/coar/resource_type/c_db06"
            ["dcndl:dissertationNumber", "dcndl:degreeName", "dcndl:dateGranted", "jpcoar:degreeGrantor"].each do |name|
               prefix, = name.split(/:/)
               elements = metadata.find(".//#{name}", "#{prefix}:#{NAMESPACES[prefix.to_sym]}")
               if elements.empty?
                  result[:error] << {
                     error_id: :dissertation_details_not_found,
                     message: "Element '#{name}' not found.",
                     identifier: identifier,
                  }
               end
            end
         end
      end 
      metadata.find("./dcndl:dissertationNumber", "dcndl:#{NAMESPACES[:dcndl]}").each do |e|
         if e.content !~ /\A[甲乙他]第\d+号/
            result[:warn] << {
               error_id: :dissertation_number_format,
               message: "Element 'dcndl:dissertationNumber' format mismatch: #{e.content}",
               identifier: identifier,
            }
         end
      end
      #29. 学位名
      langs = []
      elements = metadata.find("./dcndl:degreeName", "dcndl:#{NAMESPACES[:dcndl]}")
      elements.each do |e|
         lang = xml_lang(e)
         if lang.nil?
         else
            langs << lang
         end
      end
      if not langs.empty? and not langs.include?("en")
         result[:warn] << {
            error_id: :degree_name_english,
            message: "Element 'dcndl:degreename' does not include English name: #{langs.join(", ")}",
            identifier: identifier,
         }
      end
      #34. 学位授与機関
      metadata.find("./jpcoar:degreeGrantor", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |degree_grantor|
         degree_grantor.find("jpcoar:nameIdentifier", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |e|
            if not e.attributes["nameIdentifierScheme"] or e.attributes["nameIdentifierScheme"] != "kakenhi"
               result[:warn] << {
                  error_id: :degree_grantor_kakenhi_missing,
                  message: "Element 'jpcoar:degreeGrantor/nameIdentifier' should have @nameIdentifierScheme attribute with 'kakenhi'",
                  identifier: identifier,
               }
            end
         end
      end
      #38. 原文の言語
      metadata.find("./dcndl:originalLanguage", "dcndl:#{NAMESPACES[:dcndl]}").each do |e|
         if e.content !~ /\A[a-z]{3}\z/
            result[:error] << {
               error_id: :original_language_format,
               message: "Element 'dcndl:originalLanguage' should be in ISO-639-3: #{e.content}",
               identifier: identifier,
            }
         end
      end
      #43.1 URI
      metadata.find(".//jpcoar:URI", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |e|
         if not e.attributes["objectType"]
            result[:warn] << {
               error_id: :objectype_not_found,
               message: "Element 'jpcoar:URI' should have an attribute @objectType.",
               identifier: identifier,
            }
         end
      end
      #43.2 ファイルフォーマット
      metadata.find(".//jpcoar:mimeType", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |e|
         if e.content !~ /\A(application|audio|example|font|image|model|text|video)\/\w+/
            result[:warn] << {
               error_id: :mimetype_format,
               message: "Element 'jpcoar:mimeType' format error: #{e.content}",
               identifier: identifier,
            }
         end
      end
      #43.3 ファイルサイズ
      metadata.find("./jpcoar:file", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |e|
         e.find("./jpcoar:extent", "jpcoar:#{NAMESPACES[:jpcoar]}").each do |extent|
            if extent.content !~ /\d+/
               result[:warn] << {
                  error_id: :extent_format,
                  message: "Element 'jpcoar:file/jpcoar:extent' format error: #{e.content}",
                  identifier: identifier,
               }
            end
         end
      end



      result
   end

   def xml_lang(element)
      lang = element.attributes.get_attribute_ns("http://www.w3.org/XML/1998/namespace", "lang")
      if lang.nil?
         nil
      else
         lang.value
      end
   end
   def xml_langs(metadata, element_name)
      langs = []
      metadata.find("./#{element_name}", NAMESPACES).each do |e|
         langs << xml_lang(e) if xml_lang(e)
      end
      langs
   end
   def xml_lang_duplicated?(metadata, element_name)
      langs = xml_langs(metadata, element_name)
      if langs.uniq.length != langs.length
         true
      else
         false
      end
   end

   private
   def http( uri )
      http_proxy = ENV[ "http_proxy" ]
      proxy, proxy_port = nil
      if http_proxy
         proxy_uri = URI.parse( http_proxy )
         proxy = proxy_uri.host
         proxy_port = proxy_uri.port
      end
      http = Net::HTTP.Proxy( proxy, proxy_port ).new( uri.host, uri.port )
      http.use_ssl = true if uri.scheme == "https"
      http.open_timeout = 30
      http.read_timeout = 30
      http
   end
end

class JPCOARValidatorFromString < JPCOARValidator
   def initialize( xml )
      @xml = xml
      @xml_schema = LibXML::XML::Schema.new( XSD )
   end
   def validate
      parser = LibXML::XML::Parser.string( @xml )
      begin
        doc = parser.parse
        validate_jpcoar( doc )
      rescue LibXML::XML::Error => err
        { :error => [
            :error_id => :parse_error,
            :message => "XML parse error: #{ err.message }",
          ]
        }
      end
   end
end

if $0 == __FILE__
   options = {
      :max => 20
   }
   opt = OptionParser.new
   opt.on( '--max VAL'   ){|v| options[ :max ] = v }
   opt.on( '--from VAL'  ){|v| options[ :from ] = v }
   opt.on( '--until VAL' ){|v| options[ :until ] = v }
   opt.parse!( ARGV )
   ARGV.each do |url|
      p url
      validator = JPCOARValidator.new( url )
      result = validator.validate( options )
      [ :info, :error, :warn ].each do |k|
         puts "Total #{ result[ k ].size } #{ k }:"
         pp result[ k ]
      end
      if result[ :next_token ]
         puts "resumptionToken: #{ result[ :next_token ].inspect }"
      end
   end
end
