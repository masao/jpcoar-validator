# JPCOAR Validator

機関リポジトリ等に搭載されたメタデータが、[JPCOARメタデータスキーマ Version 2.0](https://schema.irdb.nii.ac.jp/ja)にしたがっているかを検証します。

検証ツールは主に、以下の3つの情報源を参考に開発しました：

* [XMLスキーマ](https://github.com/JPCOAR/schema)
* [JPCOARスキーマガイドライン](https://schema.irdb.nii.ac.jp/ja)
* [IRDB JPCOARスキーマ エラーチェック・正規化仕様](https://support.irdb.nii.ac.jp/ja/harvest/jpcoar/mapping)

## 検証方式

JPCOARメタデータスキーマに基づく XML Schema 検証に加え、メタデータの記述内容や項目間の整合性に関する追加的な検証を行います。
追加的な検証ルールについては、[Schematron](https://schematron.com/) を用いて実装しています。

## 開発

ソースコードは [GitHub](https://github.com/masao/jpcoar-validator) で公開しています。

開発環境の構築、検証ルールの更新、テスト・ビルド方法については、[開発者向け Wiki](https://github.com/masao/jpcoar-validator/wiki) を参照してください。

## TODO

* JPCOAR 1.0対応
* ResourceSync対応
* データ連携仕様: [NDL](https://support.irdb.nii.ac.jp/ja/harvest/jpcoar/dataprovide_ndl), [JaLC](https://support.irdb.nii.ac.jp/ja/harvest/jpcoar/dataprovide_jalc), [CiNii Research](https://support.irdb.nii.ac.jp/ja/harvest/jpcoar/dataprovide_ciniir)

## 免責事項 (Disclaimer)

本ツールは個人によって開発されたものであり、JPCOARコミュニティおよびIRDB運営元の国立情報学研究所（NII）とは一切関係がありません。

本ツールに関するご質問やお問い合わせは、[GitHub Issue](https://github.com/masao/jpcoar-validator/issues) または高久個人宛（下記連絡先）にお願いいたします。

なお、開発者自身は、JPCOARスキーマを用いるリポジトリやメタデータ作成の実務に携わった経験が無いため、本ツールの正確性を十分に保証することができません。
したがって、本ツールの検証結果はあくまで参考情報として扱い、利用に際しては十分ご注意ください。

## 連絡先

高久 雅生 (Masao Takaku)
Email: masao@slis.tsukuba.ac.jp