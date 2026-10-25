# TCL テレビ Android ビューアー 0.1.0（開発版）

[APKのダウンロード](https://github.com/Long0823-1/TCLTV-Android-Viewer/releases) · [画像付きセットアップ](docs/SETUP.md) · [検証結果](docs/validation-v0.1.0.md)

TCLTV-BonDriver v0.4.1 の配信をAndroidスマートフォンで視聴する独立アプリです。LibVLCを内蔵し、外部プレーヤーは不要です。Android 8以降、ARM64向け。Xiaomi 12T Pro実機での確認は未実施です。

## 初回設定

1. TV側のv0.4.1セットアップとチャンネルスキャンを完了します。
2. スマートフォンをTVと通信できる同じ家庭内LANのWi-Fiに接続します。
3. APKをインストールします。
4. PCで生成した自分の `BonDriver_TCLG06.ini` または `BonDriver_TCLG06_1.ini` をスマートフォンへ安全にコピーします。
5. アプリの「接続設定」から設定ファイルを読み込み、接続先とチューナーを確認します。
6. チャンネルを選択して視聴します。番組表の更新は、選択したチューナーで各放送波を順番に受信するため、視聴が一時停止します。

INIには接続キーが含まれます。GitHubなどに公開しないでください。取り込んだ接続情報はアプリ専用領域に保存し、Androidバックアップは無効です。日常の視聴にスマートフォンのroot、PC、USB、ADBは不要です。

## 動作と制限

- 局一覧は読み込んだスキャン結果を使用します。
- 番組表は実際のTSのEITから取得し、最大48時間分を端末内に保存します。受信時間や放送局により空欄になります。
- 番組のタップで詳細を表示し、そのサービスを選局できます。
- 選択した1系統を使用します。同じチューナーをPCなどから同時に選局すると競合します。
- MPEG-2映像をソフトウェア復号します。スマートフォン実機での性能確認が必要です。
- 一部の外字・DRCSは「□」になります。字幕・データ放送表示は未実装です。
- 家庭内LAN用です。インターネット越しの認証中継、VPN、自動画質変換は未実装です。
- TVのIPが変わった場合は接続設定で更新します。LAN内の自動探索は行いません。

## ビルド

Windows PowerShell、JDK、Android SDK platform35 / build-tools36.0.0が必要です。

```powershell
.\mobile\build.ps1 -Abi arm64-v8a -SdkRoot C:\path\to\Android\Sdk -JdkRoot C:\path\to\jdk
```

依存物は `dependencies.json` のURLとSHA256で検証します。署名鍵はリポジトリ直下 `.local/signing.jks`、パスワードは `.local/signing.pass`、別名は `tclbondriver` です。これらは配布物に含みません。自分の署名鍵を用意してください。LibVLC AARを交換する場合は対応するハッシュも更新して再ビルドできます。

`tests/CoreTest.java` は設定ファイルと実TSを引数に、文字デコード・設定検証・EIT CRCと番組取得を検証します。`tests/android/SmokeTest.java` はデバッグ用であり、公開APKには含まれません。

## ライセンス

アプリのソースはリポジトリのMITライセンスです。LibVLCその他のライセンスは `mobile/assets/THIRD_PARTY_NOTICES.txt` と `mobile/assets/LGPL-2.1.txt` を参照してください。依存ライブラリの公式ソースアーカイブはReleasesにも配置します。
### 対応ソース

LibVLC JNIのソースは `0b8dc65`、VLC本体のベースはJNIビルドスクリプトに指定された `84177b2273abc5c4300234e6e18b55a4d2dd5a03` です。AARに記録されたVLCリビジョン `586dd059ac` はビルド時のパッチ適用後の識別子です。JNIアーカイブにはパッチとビルドスクリプト、VLCアーカイブにはcontribのレシピが含まれます。公式ソースアーカイブと各Java依存物のsources.jarをReleasesのsource-bundle ZIPで提供します。

- [LibVLC JNI source archive](https://code.videolan.org/videolan/libvlcjni/-/archive/0b8dc65/libvlcjni-0b8dc65.tar.gz)
- [VLC base source archive](https://code.videolan.org/videolan/vlc/-/archive/84177b2273abc5c4300234e6e18b55a4d2dd5a03/vlc-84177b2273abc5c4300234e6e18b55a4d2dd5a03.tar.gz)