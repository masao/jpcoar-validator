<?xml version="1.0" encoding="UTF-8"?>
<sch:schema
    xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    queryBinding="xslt3">
  <sch:title>JPCOAR Schema 2.0 Validation Rules</sch:title>

  <!--
    Namespace declarations used in XPath expressions.

    Add or adjust namespace URIs according to the official
    JPCOAR Schema 2.0 namespace definitions.
  -->
  <sch:ns
      prefix="jpcoar"
      uri="https://github.com/JPCOAR/schema/blob/master/2.0/" />
  <sch:ns
      prefix="dc"
      uri="http://purl.org/dc/elements/1.1/" />
  <sch:ns
      prefix="dcterms"
      uri="http://purl.org/dc/terms/" />
  <sch:ns
      prefix="datacite"
      uri="https://schema.datacite.org/meta/kernel-4/" />
  <sch:ns
      prefix="oaire"
      uri="http://namespace.openaire.eu/schema/oaire/" />
  <sch:ns
      prefix="rdf"
      uri="http://www.w3.org/1999/02/22-rdf-syntax-ns#" />
  <sch:ns
      prefix="dcndl"
      uri="http://ndl.go.jp/dcndl/terms/" />

  <!-- =========================================================
       Abstract patterns
       ========================================================= -->
  <sch:pattern id="unique-xmllang" abstract="true">
    <sch:param name="context"/>
    <sch:param name="langs"/>
    <sch:param name="label"/>

    <sch:rule context="$context">
      <sch:assert
          id="xmllang_duplicated"
          role="error"
          test="count($langs) = count(distinct-values($langs))">
        Element '<sch:value-of select="$label"/>':
        'xml:lang' attributes duplicated:
        <sch:value-of select="string-join($langs, ', ')"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern id="japanese-required-with-yomi" abstract="true">
    <sch:param name="context"/>
    <sch:param name="langs"/>
    <sch:param name="label"/>
    <sch:rule context="$context">
      <sch:assert
          id="xmllang_nojapanese_with_yomi"
          role="error"
          test="
            not(
              $langs = ('ja-Latn', 'ja-Kana')
              and not($langs = 'ja')
            )
          ">
        Element '<sch:value-of select="$label"/>'
        has Yomi attributes, but no 'ja' title:
        <sch:value-of select="string-join($langs, ', ')"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern id="name-identifier-format" abstract="true">
    <sch:param name="scheme"/>
    <sch:param name="regexp"/>
    <sch:rule context="
        jpcoar:nameIdentifier[
          @nameIdentifierScheme = $scheme
        ]">
      <sch:assert
          id="nameIdentifier_mismatch"
          role="warn"
          test="matches(string(.), $regexp)">
        nameIdentifier value is mismatch:
        <sch:value-of select="@nameIdentifierScheme"/>
        -
        <sch:value-of select="string(.)"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern id="name-identifier-uri-format" abstract="true">
    <sch:param name="scheme"/>
    <sch:param name="regexp"/>
    <sch:rule context="
        jpcoar:nameIdentifier[
          @nameIdentifierScheme = $scheme
          and @nameIdentifierURI
        ]">
      <sch:assert
          id="nameIdentifierURI_mismatch"
          role="warn"
          test="matches(string(@nameIdentifierURI), $regexp)">
        nameIdentifierURI value is mismatch:
        <sch:value-of select="@nameIdentifierScheme"/>
        -
        <sch:value-of select="@nameIdentifierURI"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern id="identifier-format" abstract="true">
    <sch:param name="context"/>
    <sch:param name="type"/>
    <sch:param name="regexp"/>
    <sch:rule context="($context)[@identifierType = $type]">
      <sch:assert
          id="identifier_type_mismatch"
          role="error"
          test="matches(string(.), $regexp)">
        Element '<sch:value-of select="name()"/>'
        format mismatch:
        <sch:value-of select="@identifierType"/>
        -
        <sch:value-of select="string(.)"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- =========================================================
       Document-level rules
       ========================================================= -->
  <sch:pattern id="xml-lang-required">
    <sch:rule context="
        jpcoar:jpcoar/dc:title
      | jpcoar:jpcoar/dcterms:alternative
      | jpcoar:jpcoar/jpcoar:creator/jpcoar:creatorName
      | jpcoar:jpcoar/jpcoar:creator/jpcoar:familyName
      | jpcoar:jpcoar/jpcoar:creator/jpcoar:givenName
      | jpcoar:jpcoar/jpcoar:creator/jpcoar:creatorAlternative
      | jpcoar:jpcoar/jpcoar:creator/jpcoar:affiliation/jpcoar:affiliationName
      | jpcoar:jpcoar/jpcoar:contributor/jpcoar:contributorName
      | jpcoar:jpcoar/jpcoar:contributor/jpcoar:familyName
      | jpcoar:jpcoar/jpcoar:contributor/jpcoar:givenName
      | jpcoar:jpcoar/jpcoar:contributor/jpcoar:contributorAlternative
      | jpcoar:jpcoar/jpcoar:contributor/jpcoar:affiliation/jpcoar:affiliationName
      | jpcoar:jpcoar/dc:rights
      | jpcoar:jpcoar/jpcoar:rightsHolder/jpcoar:rightsHolderName
      | jpcoar:jpcoar/datacite:description
      | jpcoar:jpcoar/dc:publisher
      | jpcoar:jpcoar/jpcoar:publisher/jpcoar:publisherName
      | jpcoar:jpcoar/jpcoar:publisher/jpcoar:publisherDescription
      | jpcoar:jpcoar/jpcoar:publisher/dcndl:location
      | jpcoar:jpcoar/dcterms:date
      | jpcoar:jpcoar/jpcoar:relation/jpcoar:relatedTitle
      | jpcoar:jpcoar/jpcoar:fundingReference/jpcoar:funderName
      | jpcoar:jpcoar/jpcoar:fundingReference/jpcoar:fundingStream
      | jpcoar:jpcoar/jpcoar:fundingReference/jpcoar:awardTitle
      | jpcoar:jpcoar/jpcoar:sourceTitle
      | jpcoar:jpcoar/dcndl:degreeName
      | jpcoar:jpcoar/jpcoar:degreeGrantor/jpcoar:degreeGrantorName
      | jpcoar:jpcoar/jpcoar:conference/jpcoar:conferenceName
      | jpcoar:jpcoar/jpcoar:conference/jpcoar:conferenceSponsor
      | jpcoar:jpcoar/jpcoar:conference/jpcoar:conferenceDate
      | jpcoar:jpcoar/jpcoar:conference/jpcoar:conferenceVenue
      | jpcoar:jpcoar/jpcoar:conference/jpcoar:conferencePlace
      | jpcoar:jpcoar/dcndl:edition
      | jpcoar:jpcoar/dcndl:volumeTitle
      | jpcoar:jpcoar/dcterms:extent
      | jpcoar:jpcoar/jpcoar:format
      | jpcoar:jpcoar/jpcoar:holdingAgent/jpcoar:holdingAgentName
      | jpcoar:jpcoar/jpcoar:catalog/jpcoar:contributor/jpcoar:contributorName
      | jpcoar:jpcoar/jpcoar:catalog/jpcoar:license
      | jpcoar:jpcoar/jpcoar:catalog/jpcoar:subject
      | jpcoar:jpcoar/jpcoar:catalog/datacite:description
      | jpcoar:jpcoar/jpcoar:catalog/dc:rights">
      <sch:assert
          id="xmllang_not_found"
          role="error"
          test="@xml:lang and normalize-space(@xml:lang) != ''">
        Element '<sch:value-of select="name()"/>' needs an 'xml:lang' attribute.
      </sch:assert>
    </sch:rule>
  </sch:pattern>


  <!-- dc:title -->
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:jpcoar"/>
    <sch:param name="langs" value="dc:title/@xml:lang"/>
    <sch:param name="label" value="'dc:title'"/>
  </sch:pattern>
  <!-- creator -->
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:creator"/>
    <sch:param name="langs" value="jpcoar:creatorName/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:creator/jpcoar:creatorName'"/>
  </sch:pattern>
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:creator"/>
    <sch:param name="langs" value="jpcoar:familyName/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:creator/jpcoar:familyName'"/>
  </sch:pattern>
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:creator"/>
    <sch:param name="langs" value="jpcoar:givenName/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:creator/jpcoar:givenName'"/>
  </sch:pattern>
  <!-- contributor -->
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:contributor"/>
    <sch:param name="langs" value="jpcoar:contributorName/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:contributor/jpcoar:contributorName'"/>
  </sch:pattern>
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:contributor"/>
    <sch:param name="langs" value="jpcoar:familyName/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:contributor/jpcoar:familyName'"/>
  </sch:pattern>
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:contributor"/>
    <sch:param name="langs" value="jpcoar:givenName/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:contributor/jpcoar:givenName'"/>
  </sch:pattern>
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context"
              value="jpcoar:contributor/jpcoar:affiliation"/>
    <sch:param name="langs"
              value="jpcoar:affiliationName/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:contributor/jpcoar:affiliation/jpcoar:affiliationName'"/>
  </sch:pattern>
  <!-- relation -->
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:relation"/>
    <sch:param name="langs" value="jpcoar:relatedTitle/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:relation/jpcoar:relatedTitle'"/>
  </sch:pattern>
  <!-- fundingReference -->
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:fundingReference"/>
    <sch:param name="langs" value="jpcoar:funderName/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:fundingReference/jpcoar:funderName'"/>
  </sch:pattern>
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:fundingReference"/>
    <sch:param name="langs" value="jpcoar:awardTitle/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:fundingReference/jpcoar:awardTitle'"/>
  </sch:pattern>
  <!-- root-level -->
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:jpcoar"/>
    <sch:param name="langs" value="jpcoar:sourceTitle/@xml:lang"/>
    <sch:param name="label" value="'jpcoar:sourceTitle'"/>
  </sch:pattern>
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:jpcoar"/>
    <sch:param name="langs" value="dcndl:degreeName/@xml:lang"/>
    <sch:param name="label" value="'dcndl:degreeName'"/>
  </sch:pattern>
  <!-- degreeGrantor -->
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:degreeGrantor"/>
    <sch:param name="langs"
              value="jpcoar:degreeGrantorName/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:degreeGrantor/jpcoar:degreeGrantorName'"/>
  </sch:pattern>
  <!-- conference -->
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:conference"/>
    <sch:param name="langs"
              value="jpcoar:conferenceName/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:conference/jpcoar:conferenceName'"/>
  </sch:pattern>
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:conference"/>
    <sch:param name="langs"
              value="jpcoar:conferenceSponsor/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:conference/jpcoar:conferenceSponsor'"/>
  </sch:pattern>
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:conference"/>
    <sch:param name="langs"
              value="jpcoar:conferenceVenue/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:conference/jpcoar:conferenceVenue'"/>
  </sch:pattern>
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:conference"/>
    <sch:param name="langs"
              value="jpcoar:conferencePlace/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:conference/jpcoar:conferencePlace'"/>
  </sch:pattern>
  <!-- holdingAgent -->
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:holdingAgent"/>
    <sch:param name="langs"
              value="jpcoar:holdingAgentName/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:holdingAgent/jpcoar:holdingAgentName'"/>
  </sch:pattern>
  <!-- catalog -->
  <sch:pattern is-a="unique-xmllang">
    <sch:param name="context" value="jpcoar:catalog"/>
    <sch:param name="langs" value="dc:title/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:catalog/dc:title'"/>
  </sch:pattern>

  <!-- dc:title -->
  <sch:pattern is-a="japanese-required-with-yomi">
    <sch:param name="context" value="jpcoar:jpcoar"/>
    <sch:param name="langs" value="dc:title/@xml:lang"/>
    <sch:param name="label" value="'dc:title'"/>
  </sch:pattern>
  <!-- creatorName -->
  <sch:pattern is-a="japanese-required-with-yomi">
    <sch:param name="context" value="jpcoar:creator"/>
    <sch:param name="langs" value="jpcoar:creatorName/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:creator/jpcoar:creatorName'"/>
  </sch:pattern>
  <!-- creatorAlternative -->
  <sch:pattern is-a="japanese-required-with-yomi">
    <sch:param name="context" value="jpcoar:creator"/>
    <sch:param name="langs"
              value="jpcoar:creatorAlternative/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:creator/jpcoar:creatorAlternative'"/>
  </sch:pattern>
  <!-- contributorName -->
  <sch:pattern is-a="japanese-required-with-yomi">
    <sch:param name="context" value="jpcoar:contributor"/>
    <sch:param name="langs"
              value="jpcoar:contributorName/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:contributor/jpcoar:contributorName'"/>
  </sch:pattern>
  <!-- contributorAlternative -->
  <sch:pattern is-a="japanese-required-with-yomi">
    <sch:param name="context" value="jpcoar:contributor"/>
    <sch:param name="langs"
              value="jpcoar:contributorAlternative/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:contributor/jpcoar:contributorAlternative'"/>
  </sch:pattern>
  <!-- rightsHolderName -->
  <sch:pattern is-a="japanese-required-with-yomi">
    <sch:param name="context" value="jpcoar:rightsHolder"/>
    <sch:param name="langs"
              value="jpcoar:rightsHolderName/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:rightsHolder/jpcoar:rightsHolderName'"/>
  </sch:pattern>
  <!-- catalog/dc:title -->
  <sch:pattern is-a="japanese-required-with-yomi">
    <sch:param name="context" value="jpcoar:catalog"/>
    <sch:param name="langs"
              value="dc:title/@xml:lang"/>
    <sch:param name="label"
              value="'jpcoar:catalog/dc:title'"/>
  </sch:pattern>

  <!-- 3. 作成者: Creator required for thesis -->
  <sch:pattern id="creator-required-for-thesis">
    <sch:rule context="jpcoar:jpcoar">
      <sch:let
          name="resource-type"
          value="dc:type/@rdf:resource"/>
      <sch:let
          name="thesis-types"
          value="
            (
              'http://purl.org/coar/resource_type/c_46ec',
              'http://purl.org/coar/resource_type/c_7a1f',
              'http://purl.org/coar/resource_type/c_bdcc',
              'http://purl.org/coar/resource_type/c_db06'
            )
          "/>
      <sch:assert
          id="no_creator_in_thesis"
          role="error"
          test="
            not($resource-type = $thesis-types)
            or exists(jpcoar:creator)
          ">
        Element 'jpcoar:creator' is not available.
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 3.1 作成者識別子: nameIdentifier 共通規則 -->
  <sch:pattern id="name-identifier-common">
    <sch:rule context="jpcoar:nameIdentifier">
      <!--
        ROR 以外では、nameIdentifier の値そのものを
        URI形式にしないことを推奨
      -->
      <sch:assert
          id="nameidentifier_content_is_uri"
          role="warn"
          test="
            @nameIdentifierScheme = 'ROR'
            or not(matches(normalize-space(.), '^https?://'))
          ">
        nameIdentifier content is in the form of URI:
        <sch:value-of select="normalize-space(.)"/>
      </sch:assert>

      <!--
        NRID, kakenhi, GRID は degreeGrantor 以外では obsolete
      -->
      <sch:assert
          id="nameIdentifierScheme_obsolete"
          role="warn"
          test="
            not(@nameIdentifierScheme = ('NRID', 'kakenhi', 'GRID'))
            or parent::jpcoar:degreeGrantor
          ">
        nameIdentifierScheme value is obsolete:
        <sch:value-of select="@nameIdentifierScheme"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- nameIdentifier content format -->
  <sch:pattern is-a="name-identifier-format">
    <sch:param name="scheme" value="'e-Rad_Researcher'"/>
    <sch:param name="regexp"
              value="'^[0-9]{8}$'"/>
  </sch:pattern>
  <sch:pattern is-a="name-identifier-format">
    <sch:param name="scheme" value="'NRID'"/>
    <sch:param name="regexp"
              value="'^[0-9]{13}$'"/>
  </sch:pattern>
  <sch:pattern is-a="name-identifier-format">
    <sch:param name="scheme" value="'ORCID'"/>
    <sch:param name="regexp"
              value="'^[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$'"/>
  </sch:pattern>
  <sch:pattern is-a="name-identifier-format">
    <sch:param name="scheme" value="'ISNI'"/>
    <sch:param name="regexp"
              value="'^[0-9]{15}[0-9X]$'"/>
  </sch:pattern>
  <sch:pattern is-a="name-identifier-format">
    <sch:param name="scheme" value="'VIAF'"/>
    <sch:param name="regexp"
              value="'^[0-9]+$'"/>
  </sch:pattern>
  <sch:pattern is-a="name-identifier-format">
    <sch:param name="scheme" value="'AID'"/>
    <sch:param name="regexp"
              value="'^D[AB][0-9]{7}[0-9X]$'"/>
  </sch:pattern>
  <sch:pattern is-a="name-identifier-format">
    <sch:param name="scheme" value="'kakenhi'"/>
    <sch:param name="regexp"
              value="'^[0-9]{5}$'"/>
  </sch:pattern>

  <sch:pattern is-a="name-identifier-format">
    <sch:param name="scheme" value="'Ringgold'"/>
    <sch:param name="regexp"
              value="'^RIN[0-9]+$'"/>
  </sch:pattern>

  <sch:pattern is-a="name-identifier-format">
    <sch:param name="scheme" value="'GRID'"/>
    <sch:param name="regexp"
              value="'^grid\.[0-9]+\.[0-9a-z]+$'"/>
  </sch:pattern>

  <sch:pattern is-a="name-identifier-format">
    <sch:param name="scheme" value="'ROR'"/>
    <sch:param name="regexp"
              value="'^https://ror\.org/.+$'"/>
  </sch:pattern>

  <sch:pattern is-a="name-identifier-uri-format">
    <sch:param name="scheme" value="'NRID'"/>
    <sch:param name="regexp"
              value="'^https://nrid\.nii\.ac\.jp/nrid/[0-9]{13}$'"/>
  </sch:pattern>
  <sch:pattern is-a="name-identifier-uri-format">
    <sch:param name="scheme" value="'ORCID'"/>
    <sch:param name="regexp"
              value="'^https://orcid\.org/[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$'"/>
  </sch:pattern>
  <sch:pattern is-a="name-identifier-uri-format">
    <sch:param name="scheme" value="'ISNI'"/>
    <sch:param name="regexp"
              value="'^https://isni\.org/isni/[0-9]{15}[0-9X]$'"/>
  </sch:pattern>
  <sch:pattern is-a="name-identifier-uri-format">
    <sch:param name="scheme" value="'VIAF'"/>
    <sch:param name="regexp"
              value="'^https://viaf\.org/viaf/[0-9]+$'"/>
  </sch:pattern>
  <sch:pattern is-a="name-identifier-uri-format">
    <sch:param name="scheme" value="'GRID'"/>
    <sch:param name="regexp"
              value="'^https://www\.grid\.ac/institutes/grid\.[0-9]+\.[0-9a-z]+$'"/>
  </sch:pattern>
  <sch:pattern is-a="name-identifier-uri-format">
    <sch:param name="scheme" value="'ROR'"/>
    <sch:param name="regexp"
              value="'^https://ror\.org/.+$'"/>
  </sch:pattern>

  <!-- 3.2 作成者姓名, 4.2 寄与者姓名, 7.2 権利者名 -->
  <sch:pattern id="personal-name-separator">
    <sch:rule context="
        jpcoar:creatorName
      | jpcoar:contributorName
      | jpcoar:rightsHolderName">
      <sch:assert
          id="no_comma_creator"
          role="warn"
          test="
            @nameType = 'Organizational'
            or
            matches(string(.), '.+, .+')
            or
            string-length(string(.)) &gt;= 20
          ">
        <sch:value-of select="name()"/>:
        '<sch:value-of select="string(.)"/>'
        does not contain any separators between family and given name.
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 3.3 作成者姓, 3.4 作成者名 -->
  <sch:pattern id="no-yomi-in-family-given-name">
    <sch:rule context="
        jpcoar:familyName
      | jpcoar:givenName">
      <sch:assert
          id="yomi_not_needed"
          role="warn"
          test="
            not(@xml:lang)
            or not(starts-with(@xml:lang, 'ja-'))
          ">
        <sch:value-of select="name()"/>
        element should not include any Yomi:
        <sch:value-of select="string(.)"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 4. 寄与者 -->
  <sch:pattern id="contributor-type-required">
    <sch:rule context="jpcoar:contributor">
      <sch:assert
          id="contributor_type_not_found"
          role="warn"
          test="@contributorType">
        contributorType attribute not defined.
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 5. アクセス権 -->
  <sch:pattern id="access-rights">
    <sch:rule context="dcterms:accessRights">
      <!-- rdf:resource 必須 -->
      <sch:assert
          id="access_rights_without_rdf_resource"
          role="error"
          test="@rdf:resource">
        Element 'dcterms:accessRights' needs @rdf:resource attribute:
        <sch:value-of select="string(.)"/>
      </sch:assert>
      <!-- 許可されたURIか -->
      <sch:assert
          id="access_rights_wrong_uri"
          role="error"
          test="
            not(@rdf:resource)
            or @rdf:resource = (
              'http://purl.org/coar/access_right/c_f1cf',
              'http://purl.org/coar/access_right/c_14cb',
              'http://purl.org/coar/access_right/c_abf2',
              'http://purl.org/coar/access_right/c_16ec'
            )
          ">
        Element 'dcterms:accessRights' has an invalid URI:
        <sch:value-of select="@rdf:resource"/>
        -
        <sch:value-of select="string(.)"/>
      </sch:assert>
      <!-- URI とラベルの組み合わせ -->
      <sch:assert
          id="access_rights_mismatch"
          role="error"
          test="
            not(@rdf:resource = (
              'http://purl.org/coar/access_right/c_f1cf',
              'http://purl.org/coar/access_right/c_14cb',
              'http://purl.org/coar/access_right/c_abf2',
              'http://purl.org/coar/access_right/c_16ec'
            ))
            or
            (
              @rdf:resource = 'http://purl.org/coar/access_right/c_f1cf'
              and string(.) = 'embargoed access'
            )
            or
            (
              @rdf:resource = 'http://purl.org/coar/access_right/c_14cb'
              and string(.) = 'metadata only access'
            )
            or
            (
              @rdf:resource = 'http://purl.org/coar/access_right/c_abf2'
              and string(.) = 'open access'
            )
            or
            (
              @rdf:resource = 'http://purl.org/coar/access_right/c_16ec'
              and string(.) = 'restricted access'
            )
          ">
        Element 'dcterms:accessRights' has a mismatched URI and value:
        <sch:value-of select="@rdf:resource"/>
        -
        <sch:value-of select="string(.)"/>
      </sch:assert>
      <!-- embargoed access なら Available date 必須 -->
      <sch:assert
          id="embargoed_access_no_available_date"
          role="error"
          test="
            @rdf:resource != 'http://purl.org/coar/access_right/c_f1cf'
            or
            exists(/jpcoar:jpcoar/datacite:date[@dateType = 'Available'])
          ">
        Element 'dcterms:accessRights' is 'embargoed access',
        but Element 'datacite:date' @dateType='Available' not found.
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 6. 権利情報 -->
  <sch:pattern id="rights-resource-uri">
    <sch:rule context="dc:rights">
      <sch:assert
          id="rights_resource_uri_missing"
          role="warn"
          test="
            @rdf:resource
            or not(matches(string(.), 'creative[\s-]*commons', 'i'))
          ">
        Element 'dc:rights' specifies Creative Commons,
        but resource URI is not found.
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 11. 出版者 -->
  <sch:pattern id="publisher-name-required">
    <sch:rule context="jpcoar:publisher">
      <sch:assert
          id="publisher_name_not_found"
          role="warn"
          test="
            jpcoar:publisherName
            or not(
              jpcoar:publisherDescription
              or dcndl:location
              or dcndl:publicationPlace
            )
          ">
        Element 'jpcoar:publisherName' not found.
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 11-4 出版地（国名コード） -->
  <sch:pattern id="publication-place-format">
    <sch:rule context="dcndl:publicationPlace">
      <sch:assert
          id="format_iso3166_1"
          role="warn"
          test="matches(string(.), '^[A-Za-z]{3}$')">
        Element 'dcndl:publicationPlace' should be in the format of ISO 3166-1 alpha-3:
        <sch:value-of select="string(.)"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 16. バージョン, 43.5 バージョン情報 -->
  <sch:pattern id="datacite-version-format">
    <sch:rule context="datacite:version">
      <sch:assert
          id="format_version"
          role="warn"
          test="matches(string(.), '^[0-9]+(\.[0-9]+)*[-a-z0-9A-Z]*$')">
        Element 'datacite:version' should be in the format like '1.2'
        not in 'version 1.2':
        <sch:value-of select="string(.)"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 17. 出版バージョン -->
  <sch:pattern id="coar-version">
    <sch:rule context="oaire:version">
      <sch:assert
          id="coar_version_type_mismatch"
          role="error"
          test="
            (string(.) = 'AO'
              and @rdf:resource = 'http://purl.org/coar/version/c_b1a7d7d4d402bcce')
            or
            (string(.) = 'SMUR'
              and @rdf:resource = 'http://purl.org/coar/version/c_71e4c1898caa6e32')
            or
            (string(.) = 'AM'
              and @rdf:resource = 'http://purl.org/coar/version/c_ab4af688f83e57aa')
            or
            (string(.) = 'P'
              and @rdf:resource = 'http://purl.org/coar/version/c_fa2ee174bc00049f')
            or
            (string(.) = 'VoR'
              and @rdf:resource = 'http://purl.org/coar/version/c_970fb48d4fbd8a85')
            or
            (string(.) = 'CVoR'
              and @rdf:resource = 'http://purl.org/coar/version/c_e19f295774971610')
            or
            (string(.) = 'EVoR'
              and @rdf:resource = 'http://purl.org/coar/version/c_dc82b40f9837b551')
            or
            (string(.) = 'NA'
              and @rdf:resource = 'http://purl.org/coar/version/c_be7fb7dd8ff6fe43')
          ">
        Element 'oaire:version' should conform to COAR Version Vocab:
        <sch:value-of select="string(.)"/>
        !=
        <sch:value-of select="@rdf:resource"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>
  <sch:pattern id="version-relation">
    <sch:rule context="oaire:version">
      <sch:assert
          id="vor_relation_not_found"
          role="warn"
          test="
            string(.) = ('VoR', 'CVoR', 'EVoR')
            or
            exists(/jpcoar:jpcoar/jpcoar:relation[@relationType = 'isVersionOf'])
          ">
        Element 'oaire:version' is
        '<sch:value-of select="string(.)"/>',
        but 'jpcoar:relation' @relationType='isVersionOf' is not found.
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 18. 識別子, 24. 収録物識別子 -->
  <sch:pattern is-a="identifier-format">
    <sch:param name="type" value="'DOI'"/>
    <sch:param name="context"
              value="jpcoar:identifier | jpcoar:identifierRegistration | jpcoar:sourceIdentifier"/>
    <sch:param name="regexp"
              value="'^https?://doi\.org/10\.'"/>
  </sch:pattern>
  <sch:pattern is-a="identifier-format">
    <sch:param name="type" value="'HDL'"/>
    <sch:param name="context"
              value="jpcoar:identifier | jpcoar:identifierRegistration | jpcoar:sourceIdentifier"/>
    <sch:param name="regexp"
              value="'^https?://hdl\.handle\.net/'"/>
  </sch:pattern>
  <sch:pattern is-a="identifier-format">
    <sch:param name="type" value="'JaLC'"/>
    <sch:param name="context"
              value="jpcoar:identifier | jpcoar:identifierRegistration | jpcoar:sourceIdentifier"/>
    <sch:param name="regexp"
              value="'^10\..+'"/>
  </sch:pattern>
  <sch:pattern is-a="identifier-format">
    <sch:param name="type" value="'Crossref'"/>
    <sch:param name="context"
              value="jpcoar:identifier | jpcoar:identifierRegistration | jpcoar:sourceIdentifier"/>
    <sch:param name="regexp"
              value="'^10\..+'"/>
  </sch:pattern>
  <sch:pattern is-a="identifier-format">
    <sch:param name="type" value="'DataCite'"/>
    <sch:param name="context"
              value="jpcoar:identifier | jpcoar:identifierRegistration | jpcoar:sourceIdentifier"/>
    <sch:param name="regexp"
              value="'^10\..+'"/>
  </sch:pattern>
  <sch:pattern is-a="identifier-format">
    <sch:param name="type" value="'ISSN'"/>
    <sch:param name="context"
              value="jpcoar:identifier | jpcoar:identifierRegistration | jpcoar:sourceIdentifier"/>
    <sch:param name="regexp"
              value="'^[0-9]{4}-?[0-9]{3}[0-9X]$'"/>
  </sch:pattern>
  <sch:pattern is-a="identifier-format">
    <sch:param name="type" value="'PISSN'"/>
    <sch:param name="context"
              value="jpcoar:identifier | jpcoar:identifierRegistration | jpcoar:sourceIdentifier"/>
    <sch:param name="regexp"
              value="'^[0-9]{4}-?[0-9]{3}[0-9X]$'"/>
  </sch:pattern>
  <sch:pattern is-a="identifier-format">
    <sch:param name="type" value="'EISSN'"/>
    <sch:param name="context"
              value="jpcoar:identifier | jpcoar:identifierRegistration | jpcoar:sourceIdentifier"/>
    <sch:param name="regexp"
              value="'^[0-9]{4}-?[0-9]{3}[0-9X]$'"/>
  </sch:pattern>
  <sch:pattern is-a="identifier-format">
    <sch:param name="type" value="'NCID'"/>
    <sch:param name="context"
              value="jpcoar:identifier | jpcoar:identifierRegistration | jpcoar:sourceIdentifier"/>
    <sch:param name="regexp"
              value="'^(AA|AN|BN|BA|BB)[0-9]{7,8}[0-9X]?$'"/>
  </sch:pattern>

  <!-- 18. 識別子, 19. ID登録 -->
  <sch:pattern id="identifier-pmid-not-supported">
    <sch:rule context="
        jpcoar:identifier[@identifierType = 'PMID']
      | jpcoar:identifierRegistration[@identifierType = 'PMID']">
      <sch:assert
          id="identifier_type_pmid"
          role="error"
          test="false()">
        Element '<sch:value-of select="name()"/>'
        @identifierType currently not supported:
        <sch:value-of select="@identifierType"/>
        -
        <sch:value-of select="string(.)"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 19. ID登録 -->
  <sch:pattern id="identifier-registration-doi">
    <sch:rule context="jpcoar:identifierRegistration">
      <sch:assert
          id="identifier_registration_doi_mismatch"
          role="warn"
          test="
            some $doi in ../jpcoar:identifier[@identifierType = 'DOI']
            satisfies
              replace(
                normalize-space(string($doi)),
                '^https://doi\.org/',
                ''
              ) = string(.)
          ">
        Element 'identifierRegistration' is not included in 'identifier':
        <sch:value-of select="string(.)"/>
        -
        <sch:value-of
            select="
              string-join(
                ../jpcoar:identifier[@identifierType = 'DOI']
                ! replace(
                    normalize-space(string(.)),
                    '^https://doi\.org/',
                    ''
                  ),
                ', '
              )
            "/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 20-1. 関連情報識別子-->
  <sch:pattern id="related-identifier-obsolete">
    <sch:rule context="jpcoar:relation/jpcoar:relatedIdentifier">
      <sch:assert
          id="identifier_type_obsolete"
          role="warn"
          test="not(@identifierType = ('ISSN', 'NAID'))">
        Element 'jpcoar:relatedIdentifier'
        @identifierType='<sch:value-of select="@identifierType"/>'
        is not recommended:
        <sch:value-of select="@identifierType"/>
        -
        <sch:value-of select="string(.)"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 23.1 助成機関識別子 -->
  <sch:pattern id="funder-identifier-obsolete">
    <sch:rule context="jpcoar:fundingReference/jpcoar:funderIdentifier">
      <sch:assert
          id="identifier_type_obsolete"
          role="warn"
          test="@funderIdentifierType != 'GRID'">
        Element 'jpcoar:funderIdentifier'
        @funderIdentifierType='GRID' is not recommended:
        <sch:value-of select="@funderIdentifierType"/>
        -
        <sch:value-of select="string(.)"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 23.5 研究課題番号 -->
  <sch:pattern id="award-number">
    <sch:rule context="jpcoar:awardNumber">
      <!-- JGN の場合は JP + 英数字で始まること -->
      <sch:assert
          id="award_number_format_error"
          role="warn"
          test="
            not(@awardNumberType = 'JGN')
            or matches(string(.), '^JP[0-9A-Za-z]+')
          ">
        Element 'jpcoar:awardNumber' format is not supported:
        <sch:value-of select="string(.)"/>
      </sch:assert>

      <!-- awardNumberType が指定されている場合、JGN 以外は未対応 -->
      <sch:assert
          id="award_number_type_not_supported"
          role="warn"
          test="
            not(@awardNumberType)
            or @awardNumberType = 'JGN'
          ">
        Element 'jpcoar:awardNumber' @awardNumberType is not supported:
        <sch:value-of select="@awardNumberType"/>
        -
        <sch:value-of select="string(.)"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 24. 収録物識別子 -->
  <sch:pattern id="source-identifier-obsolete">
    <sch:rule context="jpcoar:sourceIdentifier">
      <sch:assert
          id="identifier_type_obsolete"
          role="warn"
          test="@identifierType != 'ISSN'">
        Element 'jpcoar:sourceIdentifier'
        @identifierType='ISSN' is not recommended:
        <sch:value-of select="@identifierType"/>
        -
        <sch:value-of select="string(.)"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 26. 巻, 27. 号 -->
  <sch:pattern id="volume-issue-unnecessary-chars">
    <sch:rule context="jpcoar:volume | jpcoar:issue">
      <sch:assert
          id="volume_unnecessary_chars"
          role="warn"
          test="not(matches(string(.), '年|vol|巻|号|issue', 'i'))">
        Element '<sch:value-of select="name()"/>'
        includes unnecessary characters:
        <sch:value-of select="string(.)"/>
      </sch:assert>

    </sch:rule>
  </sch:pattern>

  <!-- 28. 学位授与番号 -->
  <sch:pattern id="dissertation-required-elements">
    <sch:rule context="jpcoar:jpcoar">
      <sch:let
          name="is-dissertation"
          value="
            dc:type/@rdf:resource =
            'http://purl.org/coar/resource_type/c_db06'
          "/>
      <sch:assert
          id="dissertation_details_not_found"
          role="error"
          test="
            not($is-dissertation)
            or exists(.//dcndl:dissertationNumber)
          ">
        Element 'dcndl:dissertationNumber' not found.
      </sch:assert>
      <sch:assert
          id="dissertation_details_not_found"
          role="error"
          test="
            not($is-dissertation)
            or exists(.//dcndl:degreeName)
          ">
        Element 'dcndl:degreeName' not found.
      </sch:assert>
      <sch:assert
          id="dissertation_details_not_found"
          role="error"
          test="
            not($is-dissertation)
            or exists(.//dcndl:dateGranted)
          ">
        Element 'dcndl:dateGranted' not found.
      </sch:assert>
      <sch:assert
          id="dissertation_details_not_found"
          role="error"
          test="
            not($is-dissertation)
            or exists(.//jpcoar:degreeGrantor)
          ">
        Element 'jpcoar:degreeGrantor' not found.
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern id="dissertation-number-format">
    <sch:rule context="dcndl:dissertationNumber">
      <sch:assert
          id="dissertation_number_format"
          role="warn"
          test="
            not(
              ancestor::jpcoar:jpcoar/
                dc:type/@rdf:resource =
                'http://purl.org/coar/resource_type/c_db06'
            )
            or matches(string(.), '^[甲乙他]第[0-9]+号')
          ">
        Element 'dcndl:dissertationNumber' format mismatch:
        <sch:value-of select="string(.)"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern id="degree-name-english">
    <sch:rule context="jpcoar:jpcoar">
      <sch:let
          name="is-dissertation"
          value="
            dc:type/@rdf:resource =
            'http://purl.org/coar/resource_type/c_db06'
          "/>
      <sch:let
          name="degree-names"
          value=".//dcndl:degreeName"/>
      <sch:assert
          id="degree_name_english"
          role="warn"
          test="
            not($is-dissertation)
            or empty($degree-names)
            or exists($degree-names[@xml:lang = 'en'])
          ">
        Element 'dcndl:degreeName' does not include English name:
        <sch:value-of
            select="string-join($degree-names/@xml:lang, ', ')"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern id="degree-grantor-kakenhi">
    <sch:rule context="jpcoar:degreeGrantor/jpcoar:nameIdentifier">
      <sch:assert
          id="degree_grantor_kakenhi_missing"
          role="warn"
          test="@nameIdentifierScheme = 'kakenhi'">
        Element 'jpcoar:degreeGrantor/nameIdentifier'
        should have @nameIdentifierScheme attribute with 'kakenhi'.
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 38. 原文の言語 -->
  <sch:pattern id="original-language-format">
    <sch:rule context="dcndl:originalLanguage">
      <sch:assert
          id="original_language_format"
          role="warn"
          test="matches(string(.), '^[a-z]{3}$')">
        Element 'dcndl:originalLanguage' should be in ISO-639-3:
        <sch:value-of select="string(.)"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 43.1 URI -->
  <sch:pattern id="uri-object-type">
    <sch:rule context="jpcoar:URI">
      <sch:assert
          id="objecttype_not_found"
          role="warn"
          test="@objectType">
        Element 'jpcoar:URI' should have an attribute @objectType.
      </sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- 43.2 ファイルフォーマット -->
  <sch:pattern id="mimetype-format">
    <sch:rule context="jpcoar:mimeType">
      <sch:assert
          id="mimetype_format"
          role="warn"
          test="
            matches(
              string(.),
              '^(application|audio|example|font|image|model|text|video)/\w+'
            )
          ">
        Element 'jpcoar:mimeType' format error:
        <sch:value-of select="string(.)"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>
  <!-- 43.3 ファイルサイズ -->
  <sch:pattern id="file-extent-format">
    <sch:rule context="jpcoar:file/jpcoar:extent">
      <sch:assert
          id="extent_format"
          role="warn"
          test="matches(string(.), '\d+')">
        Element 'jpcoar:file/jpcoar:extent' format error:
        <sch:value-of select="string(.)"/>
      </sch:assert>
    </sch:rule>
  </sch:pattern>

</sch:schema>
