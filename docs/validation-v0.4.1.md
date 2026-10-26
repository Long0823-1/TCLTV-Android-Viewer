# 0.4.1 XMLTV連携の検証（2026-10-26）

- ARM64配布APKをビルドし、署名を検証。
- Android 11 / API30 x86_64エミュレーター上でM3U URLとXMLTV URLのコピー操作が両方成功。
- URLに従来のネイティブ認証キーが含まれないことを確認。
- 旧INI互換、XMLTV対応フラグの保存・再読込、M3U/XMLTV URL生成、不正ポート拒否をJVMで検証。
- 公開画像はテスト用IPとダミーキーで、実際の放送映像・局ロゴ・接続キーを含みません。

![XMLTVのコピー](images/mobile-xmltv-v0.4.1.png)

今回の変更は接続設定とURLコピーです。映像・音声・番組表の既存の試験は[0.4.0](validation-v0.4.0.md)を参照してください。0.4.1の実スマホ試験と任意の外部IPTVアプリの番組表画面は未確認です。TV側のXMLは実放送から収集し、[TV側検証](https://github.com/Long0823-1/TCLTV-Bondriver/blob/main/validation/v0.6.0.md)で構造を確認しています。
